/* ================================================================= */
/* Object:         HRTVJOBSTS      *PGM CLP                          */
/*                 Returns the status of the passed OS/400 job.      */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020930 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&JOBQ &STATUS)

/*           Declare parameter variables                              */
             DCL        VAR(&JOBQ) TYPE(*CHAR) LEN(26)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&RCVVAR) TYPE(*CHAR) LEN(50)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Call program that retrieves status                      */
             CHGVAR     VAR(&APIERR) VALUE(X'00080000')
             CALL       PGM(QWCRJBST) PARM(&RCVVAR X'00000032' &JOBQ +
                          'JOBS0300' &APIERR)

/*           Extract status from receiver variable                   */
             CHGVAR     VAR(&STATUS) VALUE(%SST(&RCVVAR 9 10))

 ELOOP:      GOTO       CMDLBL(END)

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
