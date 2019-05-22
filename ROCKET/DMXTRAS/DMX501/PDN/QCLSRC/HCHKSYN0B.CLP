/* ================================================================= */
/* Object:         HCHKSYN0B       *PGM CLP                          */
/*                 Retrieves number of submitted sync check jobs.    */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050214 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&SBMFRM &NBRJOB)

/*           Declare parameter variables                              */
             DCL        VAR(&SBMFRM) TYPE(*CHAR) LEN(6)
             DCL        VAR(&NBRJOB) TYPE(*DEC) LEN(5 0)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JOBSTS) TYPE(*CHAR) LEN(10)

/*           Declare file                                             */
             DCLF       FILE(HCHKSYNJOB)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRJOB) VALUE(0)

/*           Process all records for specified From-job              */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              GOTO       CMDLBL(ELOOP)
             ENDDO

/*           Process all records for specified From-job              */
             IF         COND(&SJSFRM *EQ &SBMFRM) THEN(DO)
              HRTVJOBSTS JOB(&SJJNBR/&SJJUSR/&SJJNAM) STATUS(&JOBSTS)
              IF         COND(&JOBSTS *EQ '*ACTIVE' *OR &JOBSTS *EQ +
                          '*JOBQ') THEN(CHGVAR VAR(&NBRJOB) +
                          VALUE(&NBRJOB + 1))
             ENDDO
             GOTO       CMDLBL(LOOP)

 ELOOP:      GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG/*ESCAPE messages                         */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
