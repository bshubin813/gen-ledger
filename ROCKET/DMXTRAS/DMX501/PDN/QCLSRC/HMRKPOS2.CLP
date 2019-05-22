/* ================================================================= */
/* Object:         HMRKPOS2        *PGM CLP                          */
/*                 Submits the MRKHAPOS/DMMRKPOS and returns the     */
/*                 job parameters to the calling program.            */
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
/* 20031111 FK  Jobs not submitted when job queue *JOBD              */
/* 20050104 FK  Always use MRKHAPOS                                  */
/* 20111222 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &JOBQQ &JOBNAM &JOBUSR &JOBNBR)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JOBNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBNBR) TYPE(*CHAR) LEN(6)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JOBQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGID) TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGDTA) TYPE(*CHAR) LEN(128)

             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&JOBQ) VALUE(%SST(&JOBQQ 1 10))
             CHGVAR     VAR(&JOBQL) VALUE(%SST(&JOBQQ 11 10))
             IF         COND(&JOBQ *EQ '*JOBD') THEN(CHGVAR +
                          VAR(&JOBQL) VALUE('*N'))
             CHGVAR     VAR(&JOBNAM) VALUE(' ')
             CHGVAR     VAR(&JOBUSR) VALUE(' ')
             CHGVAR     VAR(&JOBNBR) VALUE(' ')

/*           Submit job for iCluster                                 */
             HRTVCRG    CRG(&ICGROUP) BCKNOD(&BCKNOD)
             SBMJOB     CMD(MRKHAPOS TARGET(&BCKNOD) +
                          GROUP(&ICGROUP)) JOB(&ICGROUP) +
                          JOBD(HAUTILS) JOBQ(&JOBQL/&JOBQ) +
                          CURLIB(*CURRENT)

/*           Return submitted job info                               */
             RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGDTA(&MSGDTA) +
                          MSGID(&MSGID)
             IF         COND(&MSGID *EQ 'CPC1221') THEN(DO)
              CHGVAR     VAR(&JOBNAM) VALUE(%SST(&MSGDTA 1 10))
              CHGVAR     VAR(&JOBUSR) VALUE(%SST(&MSGDTA 11 10))
              CHGVAR     VAR(&JOBNBR) VALUE(%SST(&MSGDTA 21 60))
             ENDDO

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
