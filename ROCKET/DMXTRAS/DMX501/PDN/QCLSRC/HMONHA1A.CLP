/* ================================================================= */
/* Object:         HMONHA1A        *PGM CLP                          */
/*                 Retrieve group status                             */
/*                                                                   */
/* Synopsis:       This program is run from the HMONHA1 program and  */
/*                 returns the current status of the passed group.   */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20060419 FK  Initial delivery                                     */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &GRPSTS)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GRPSTS) TYPE(*CHAR) LEN(10)

/*           Declare program variables                               */
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

             HRTVSTS    ICGROUP(&ICGROUP) STATUS(&GRPSTS)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
