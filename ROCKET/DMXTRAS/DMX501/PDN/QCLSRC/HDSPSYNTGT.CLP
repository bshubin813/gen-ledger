/* ================================================================= */
/* Object:         HDSPSYNTGT      *PGM CLP                          */
/*                 Show results of synchronisation check.            */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020508 FK  Initial delivery                                     */
/* 20040405 FK  Enable for iCluster                                  */
/* 20111217 FK  REMOVE HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &SYNID)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYNID) TYPE(*CHAR) LEN(5)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)
             DCL        VAR(&JOBNAM) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Determine product that sync check runs for              */
             CHGVAR     VAR(&PRD) VALUE('*IC')

/*           Determine synchronisation ID                            */
             IF         COND(&SYNID *EQ '*TGT' *AND &PRD *EQ '*IC' +
                          *AND &ICGROUP *EQ '*ALL') THEN(CHGVAR +
                          VAR(&SYNID) VALUE('CLUST'))
             IF         COND(&SYNID *EQ '*TGT' *AND &PRD *EQ '*IC' +
                          *AND &ICGROUP *NE '*ALL') THEN(CHGVAR +
                          VAR(&SYNID) VALUE(%SST(&ICGROUP 1 5)))
             CHGVAR     VAR(&JOBNAM) VALUE('HS' |< &SYNID)

/*           Work with job's spooled files                           */
             DSPJOB     JOB(&JOBNAM) OPTION(*SPLF) DUPJOBOPT(*SELECT)

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
