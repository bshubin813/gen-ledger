/* ================================================================= */
/* Object:         ANZJRN03        *PGM CLP                          */
/*                 Processes all entries from 1 receiver             */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20060126 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&JRNNME &JRNLIB &JRNRCV &JRNRLB)

/*           Declare parameter variables                              */
             DCL        VAR(&JRNLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNNME) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRLB) TYPE(*CHAR) LEN(10)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Reclaim resources if exit program called more than once */
             RCLRSC     LVL(*CALLER)

/*           Process all entries in passed receiver                  */
             RCVJRNE    JRN(&JRNLIB/&JRNNME) EXITPGM(ANZJRN05) +
                          RCVRNG(&JRNRLB/&JRNRCV &JRNRLB/&JRNRCV) +
                          FROMENT(*FIRST) TOENT(*LAST) ENTFMT(*TYPE3)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG and *ESCAPE messages                     */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
