/* ================================================================= */
/* Object:         HRMVALR         *PGM CLP                          */
/*                 Remove alert destination                          */
/*                                                                   */
/* Synopsis:       See command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050126 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&UTLID &UTLALR &DSTTYP &MSGQQ &EMAIL)

/*           Declare parameter variables                             */
             DCL        VAR(&UTLID) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLALR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&DSTTYP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&EMAIL) TYPE(*CHAR) LEN(102)

/*           Environment-specific variables                          */

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&MSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGQL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split variables                                         */
             CHGVAR     VAR(&MSGQ) VALUE(%SST(&MSGQQ 1 10))
             CHGVAR     VAR(&MSGQL) VALUE(%SST(&MSGQQ 11 10))

/*           Call program that removes record                        */
             CALL       PGM(HRMVALR1) PARM(&UTLID &UTLALR &DSTTYP +
                          &MSGQQ &EMAIL &RTNCDE)
             IF         COND(&RTNCDE *EQ ' ') THEN(SNDPGMMSG +
                          MSGID(ADR0001) MSGF(HAUMSG) MSGTYPE(*COMP))
             IF         COND(&RTNCDE *NE ' ') THEN(SNDPGMMSG +
                          MSGID(&RTNCDE) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

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
