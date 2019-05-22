/* ================================================================= */
/* Object:         HMONJRN5        *PGM CLP                          */
/*                 Retrieves the date-time stamp for the specified   */
/*                 journal entry.                                    */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20031002 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&JRN &JRNLIB &RCV &RCVLIB &JRNSEQ &JRNDTS)

/*           Declare parameter variables                             */
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNSEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JRNDTS) TYPE(*CHAR) LEN(26)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JRNE) TYPE(*CHAR) LEN(625)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

             HRTVJRNE   JRN(&JRNLIB/&JRN) JRNRCV(&RCVLIB/&RCV) +
                          FROMENTLRG(&JRNSEQ) RTNENTDTS(&JRNDTS)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Clear return variable                                   */
             CHGVAR     VAR(&JRNDTS) VALUE(' ')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
