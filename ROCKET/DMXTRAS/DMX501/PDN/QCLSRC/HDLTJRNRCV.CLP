/* ================================================================= */
/* Object:         HDLTJRNRCV      *PGM CLP                          */
/*                 Command processing program for HDLTJRNRCV.        */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990721 FK  Initial delivery                                     */
/* 19990801 FK  Let role of target determine if receiver may be      */
/*              deleted or not                                       */
/* 19991220 FK  Include TS support                                   */
/* 20000305 FK  Alert when size/# exceeds maximum                    */
/*              Allow check of journal receivers every # of hours    */
/*              Exit program for checking if receiver delete allowed */
/* 20000317 FK  Await check interval in first cycle                  */
/* 20000323 FK  Make HA Suite/TS current library before RTVxxPOS     */
/* 20000523 FK  Exit program to retrieve external position           */
/* 20001123 FK  Override error when interval processing as AJE       */
/* 20001217 FK  Process list of journals separately                  */
/* 20010822 FK  Check for library if not *LIBL                       */
/* 20020116 FK  Check for RJP journals                               */
/* 20020222 FK  Allow processing for (generic) journals in a library */
/*              or user library list                                 */
/* 20020116 FK  Check for iCluster journals                          */
/* 20031107 FK  Create LF for TS (5.1)                               */
/* 20040526 FK  Also process HADSAVJRN                               */
/* 20050429 FK  Delete LFs when finished                             */
/* 20050510 FK  Remove CHKRJP parameter                              */
/* 20070108 FK  Allow instrumental mode                              */
/* 20070112 FK  Allow checking of multiple TS libraries              */
/* 20111220 FK  Remove HA/CDC                                        */
/* ================================================================= */
             PGM        PARM(&JRNQ &DAYS &KEEPRCV &DLTUNSRCV &CHKIC +
                          &MAXRCVJRN &MAXSIZ &ALRMSGQQ &CHKITV +
                          &LOGDLT &RPYSEQ &RCVEXITQ &POSEXITQ &DLTRCV)

/*           Declare parameter variables                             */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DAYS) TYPE(*DEC) LEN(3)
             DCL        VAR(&KEEPRCV) TYPE(*DEC) LEN(3)
             DCL        VAR(&DLTUNSRCV) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKIC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MAXRCVJRN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MAXSIZ) TYPE(*DEC) LEN(6 0)
             DCL        VAR(&ALRMSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&CHKITV) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&RPYSEQ) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&LOGDLT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RCVEXITQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&POSEXITQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DLTRCV) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&JRNN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ALRMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ALRMSGQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVEXIT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVEXITL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&POSEXIT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&POSEXITL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CHKITV@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&DLY) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&STSKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MSGKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENDSTS) TYPE(*CHAR) LEN(1)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&STRLEN) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&PTNLEN) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&RSLPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&GENJRN) TYPE(*LGL) VALUE('0')

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRNN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))
             CHGVAR     VAR(&ALRMSGQ) VALUE(%SST(&ALRMSGQQ 1 10))
             CHGVAR     VAR(&ALRMSGQL) VALUE(%SST(&ALRMSGQQ 11 10))
             CHGVAR     VAR(&RCVEXIT) VALUE(%SST(&RCVEXITQ 1 10))
             CHGVAR     VAR(&RCVEXITL) VALUE(%SST(&RCVEXITQ 11 10))
             CHGVAR     VAR(&POSEXIT) VALUE(%SST(&POSEXITQ 1 10))
             CHGVAR     VAR(&POSEXITL) VALUE(%SST(&POSEXITQ 11 10))

/*           Replace library value if journal QAUDJRN                */
             IF         COND(&JRNN *EQ 'QAUDJRN' *AND &JRNL *EQ +
                          '*PRD') THEN(DO)
              CHGVAR     VAR(&JRNL) VALUE('QSYS')
              CHGVAR     VAR(&JRNQ) VALUE(&JRNN *CAT &JRNL)
             ENDDO

/*           One must specify library if not *ALL/*ALLDTA            */
             IF         COND(&JRNN *NE '*ALL' *AND &JRNN *NE +
                          '*ALLDTA' *AND &JRNL *EQ '*PRD') +
                          THEN(SNDPGMMSG MSGID(DJR0026) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Check if the journal is a generic name                  */
             CHGVAR     VAR(&STRLEN) VALUE(10)
             CHGVAR     VAR(&STRPOS) VALUE(2)
             CHGVAR     VAR(&PTNLEN) VALUE(1)
             CALL       PGM(QCLSCAN) PARM(&JRNN &STRLEN &STRPOS '*' +
                          &PTNLEN '0' '0' ' ' &RSLPOS)
             IF         COND(&RSLPOS *GT 0) THEN(CHGVAR VAR(&GENJRN) +
                          VALUE('1'))

/*           Verify that the specified journal exists                */
             IF         COND(&JRNN *NE '*ALL' *AND &JRNN *NE +
                          '*ALLDTA' *AND *NOT &GENJRN) THEN(RTVOBJD +
                          OBJ(&JRNL/&JRNN) OBJTYPE(*JRN) RTNLIB(&JRNL))

/*           Retrieve product libraries                              */
             HRTVPRDLIB  ICPRODLIB(&ICLIB)

/*           At least one of the products must be checked           */
             IF         COND(&JRNL *EQ '*PRD' *AND CHKIC *EQ '*NO') +
                          THEN(SNDPGMMSG MSGID(DJR0006) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))
/*           If CHKIC(*YES) --> iCluster library must be known       */
             IF         COND(&CHKIC *EQ '*YES' *AND &ICLIB *EQ +
                          '*NONE') THEN(SNDPGMMSG MSGID(DMX0012) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           If RPYSEQ specified --> RPYLE verification              */
             IF         COND(&RPYSEQ > 0) THEN(DO)
/*            Verify that reply list entry can be added              */
              ADDRPYLE   SEQNBR(&RPYSEQ) MSGID(CPA7025) +
                          CMPDTA(99999999999999999999) RPY(I)
              RMVRPYLE   SEQNBR(&RPYSEQ)
             ENDDO

/*           Check existence of message queue                        */
             CHKOBJ     OBJ(&ALRMSGQL/&ALRMSGQ) OBJTYPE(*MSGQ)

/*           If exit program specified --> check existence           */
             IF         COND(&RCVEXIT *NE '*NONE') THEN(CHKOBJ +
                          OBJ(&RCVEXITL/&RCVEXIT) OBJTYPE(*PGM))

/*           If position exit specified --> check existence          */
             IF         COND(&POSEXIT *NE '*NONE') THEN(CHKOBJ +
                          OBJ(&POSEXITL/&POSEXIT) OBJTYPE(*PGM))

/*           If CHKITV not *ONCE --> must be executed in batch       */
             RTVJOBA    TYPE(&JOBTYPE)
             IF         COND(&JOBTYPE *EQ '1' *AND &CHKITV *NE 0) +
                          THEN(SNDPGMMSG MSGID(DJR0014) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Create necessary files in QTEMP for iCluster            */
/*           If CHKITV not *ONCE and first cycle, wait               */
             IF         COND(&CHKITV *NE 0) THEN(GOTO CMDLBL(WAITITV))

/*           Initialise loop                                         */
/*           Call program that processes journal(s)                  */
 LOOPITV:    IF         COND(&DLTRCV *EQ '*NO') THEN(SNDPGMMSG +
                          MSGID(DJR0040) MSGF(HAUMSG) MSGTYPE(*INFO))
             CALL       PGM(HDLTRCV0) PARM(&JRNQ &DAYS &KEEPRCV +
                          &DLTUNSRCV &CHKIC &MAXRCVJRN &MAXSIZ +
                          &ALRMSGQQ &LOGDLT &RPYSEQ &RCVEXITQ +
                          &POSEXITQ &DLTRCV)

/*           If interval set --> wait until next interval            */
 WAITITV:    IF         COND(&CHKITV *NE 0) THEN(DO)
              CHGVAR     VAR(%BIN(&CHKITV@)) VALUE(&CHKITV)
              CHGVAR     VAR(&DLY) VALUE(&CHKITV * 3600)
              SNDPGMMSG  MSGID(DJR0017) MSGF(HAUMSG) MSGDTA(&CHKITV@) +
                          KEYVAR(&STSKEY)
              RCVMSG     MSGTYPE(*NEXT) MSGKEY(&STSKEY) WAIT(&DLY) +
                          KEYVAR(&MSGKEY)
/*            Delay the job 1 second to update status                */
              DLYJOB     DLY(1)
/*            Remove status message to not confuse operator          */
              RMVMSG     MSGKEY(&STSKEY)
              MONMSG     MSGID(CPF0000)
/*            If job/subsystem or system ended --> quit, else loop   */
              RTVJOBA    ENDSTS(&ENDSTS)
              IF         COND(&ENDSTS *EQ '0') THEN(GOTO CMDLBL(LOOPITV))
             ENDDO

/*           Reclaim resources                                       */
             RCLRSC     LVL(*CALLER)

/*           Delete H* files in QTEMP                                */
             CALL       PGM(HCRTLFDLT) PARM('*ALL' '*ALL')

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
