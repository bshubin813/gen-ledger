/* ================================================================= */
/* Object:         HMRKPOS3        *PGM CLP                          */
/*                 Reads the HMRKPOS file and returns the number     */
/*                 of jobs active and on job queue                   */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030604 FK  Initial delivery                                     */
/* 20051006 FK  Active job status not checked properly               */
/* ================================================================= */
             PGM        PARM(&NBRACT &NBRJOBQ)

/*           Declare parameter variables                             */
             DCL        VAR(&NBRACT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRJOBQ) TYPE(*DEC) LEN(5 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&QJOB) TYPE(*CHAR) LEN(26)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */
             DCLF       FILE(HMRKPOS)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRACT) VALUE(0)
             CHGVAR     VAR(&NBRJOBQ) VALUE(0)

 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

             CHGVAR     VAR(&QJOB) VALUE(&MPJNAM || &MPJUSR || &MPJNBR)
             CALL       PGM(HRTVJOBSTS) PARM(&QJOB &STATUS)
             IF         COND(&STATUS *EQ '*JOBQ') THEN(CHGVAR +
                          VAR(&NBRJOBQ) VALUE(&NBRJOBQ + 1))
             IF         COND(&STATUS *EQ '*ACTIVE') THEN(CHGVAR +
                          VAR(&NBRACT) VALUE(&NBRACT + 1))

             GOTO       CMDLBL(LOOP)

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
