/* ================================================================= */
/* Object:         HMONHAL         *PGM CLP                          */
/*                 Controlling system listener.                      */
/*                                                                   */
/* Synopsis:       This program runs on the controlling system and   */
/*                 listens for messages sent by other systems.       */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20041216 FK  Initial delivery (copy from HMONEVL)                 */
/* 20041108 FK  Multiple message queues, e-mail                      */
/* ================================================================= */
             PGM        PARM(&PRD &PORT)

/*           Declare parameter variables                             */
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)
             DCL        VAR(&PORT) TYPE(*CHAR) LEN(30)

/*           Environment-specific variables                          */

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&CURUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SDRADDR) TYPE(*CHAR) LEN(256)
             DCL        VAR(&SDRNAME) TYPE(*CHAR) LEN(50)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    USER(&CURUSR)

/*           Clear the member from any left-over messages/suspends   */
             CLRPFM     FILE(HMONHAE)
             CLRPFM     FILE(HMONHAS)

/*           Start listener                                          */
             CALL       PGM(HMONHAL1) PARM(&PRD &CURUSR &PORT &RTNCDE)
             IF         COND(&RTNCDE *NE ' ') THEN(SNDPGMMSG +
                          MSGID(MHA0007) MSGF(HAUMSG) +
                          MSGDTA(&RTNCDE) MSGTYPE(*ESCAPE))

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
