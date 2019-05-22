/* ================================================================= */
/* Object:         HSNDCMD2        *PGM CLP                          */
/*                 Issues the command that was passed using the      */
/*                 HSNDCMD command on the source machine.            */
/*                                                                   */
/* Create remarks: CHGPGM USEADPAUT(*NO)                             */
/*                 The program will not be executed by HA Suite      */
/*                 or iCluster if it adopts authority.               */
/*                                                                   */
/* Synopsis:       This program is invoked as part of a user exit    */
/*                 in one of the following three processes:          */
/*                 1. Data journal scrape                            */
/*                 2. Apply                                          */
/*                                                                   */
/*                 The user data that is passed to this program      */
/*                 is of the following format:                       */
/*                 001-010 Name of HA Utilities library              */
/*                 011-013 Product (*HA/*IC)                         */
/*                 014-017 Stop mirroring process (0=No 1=Yes)       */
/*                 018-025 Name of originating system                */
/*                 026-042 Key of synchronisation point (iCluster)   */
/*                 043-047 Number of groups for sync (iCluster)      */
/*                 048-051 Submit to batch (*YES/*NO)                */
/*                 052-071 Job description for submit                */
/*                 072-081 Job user for submit                       */
/*                 082-091 Job name for submit                       */
/*                 092-101 Initial library list for job              */
/*                 102-105 Wait for completion of batch job          */
/*                 106-109 Restart apply jobs after completion       */
/*                 110-365 Command to execute                        */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990727 FK  Initial delivery                                     */
/* 20020506 FK  Allow submit to batch                                */
/* 20040207 FK  Run only once for iCluster                           */
/* 20050422 FK  Rename from HEXTCMD                                  */
/* 20071024 FK  Allow command to choose initial library list         */
/* 20080509 FK  Allow groups to await completion of submitted job    */
/*              Optionally restart apply processes                   */
/*              Groups should wait for all checkpoints to be reached */
/*              Mixed-up checkpoints if more than 1 subsequent       */
/*              commands await completion                            */
/* 20110718 FK  Groups stall if command submitted through HSNDCMD    */
/*              fails                                                */
/* 20120510 JMW Groups stall if command submitted through HSNDCMD    */
/*              using Group(*ALL)                                    */
/* ================================================================= */
             PGM        PARM(&EXTPNT &TGTNAM &GRPNAM &USRDTA)

/*           Declare parameter variables                              */
             DCL        VAR(&EXTPNT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TGTNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GRPNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USRDTA) TYPE(*CHAR) LEN(400)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)
             DCL        VAR(&ENDMIR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&KEY) TYPE(*CHAR) LEN(17)
             DCL        VAR(&NBRGRP@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JOBDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&USER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&INLLIBL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&WAITCOMP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RESTART) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(512)

             DCL        VAR(&INZDTA) TYPE(*CHAR) LEN(1000)
             DCL        VAR(&CURDTA) TYPE(*CHAR) LEN(1000)
             DCL        VAR(&DTAARA) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURKEY) TYPE(*CHAR) LEN(17)
             DCL        VAR(&CURNBRGRP@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CURNBRSYN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&CURNBRSYN@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CURCMDCMP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CURCMDJOB) TYPE(*CHAR) LEN(28)
             DCL        VAR(&CURGRPSYN) TYPE(*CHAR) LEN(500)
             DCL        VAR(&NBRGRP) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&PRVNBRSYN@) TYPE(*CHAR) LEN(5)

             DCL        VAR(&USRLIBL) TYPE(*CHAR) LEN(275)
             DCL        VAR(&CURLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&EXIT) TYPE(*CHAR) LEN(1)

             DCL        VAR(&MSGID) TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGDTA) TYPE(*CHAR) LEN(256)
             DCL        VAR(&SBMJOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBMUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBMNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&SBMSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGSNT) TYPE(*LGL)

             DCL        VAR(&JOBD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBDL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&RUNCMD) TYPE(*LGL)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&RUNCMD) VALUE('0')
/*           Split user data variable to retrieve parts              */
             CHGVAR     VAR(&UTLLIB) VALUE(%SST(&USRDTA 1 10))
             CHGVAR     VAR(&PRD) VALUE(%SST(&USRDTA 11 3))
             CHGVAR     VAR(&ENDMIR) VALUE(%SST(&USRDTA 14 4))
             CHGVAR     VAR(&SYSNAM) VALUE(%SST(&USRDTA 18 8))
             CHGVAR     VAR(&KEY) VALUE(%SST(&USRDTA 26 17))
             CHGVAR     VAR(&NBRGRP@) VALUE(%SST(&USRDTA 43 5))
             CHGVAR     VAR(&BATCH) VALUE(%SST(&USRDTA 48 4))
             CHGVAR     VAR(&JOBDQ) VALUE(%SST(&USRDTA 52 20))
             CHGVAR     VAR(&USER) VALUE(%SST(&USRDTA 72 10))
             CHGVAR     VAR(&JOB) VALUE(%SST(&USRDTA 82 10))
             CHGVAR     VAR(&INLLIBL) VALUE(%SST(&USRDTA 92 10))
             CHGVAR     VAR(&WAITCOMP) VALUE(%SST(&USRDTA 102 4))
             CHGVAR     VAR(&RESTART) VALUE(%SST(&USRDTA 106 4))
             CHGVAR     VAR(&CMD) VALUE(%SST(&USRDTA 110 256))

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JOBD) VALUE(%SST(&JOBDQ 1 10))
             CHGVAR     VAR(&JOBDL) VALUE(%SST(&JOBDQ 11 10))
             IF         COND(&JOBDL *EQ '*UTLLIB') THEN(CHGVAR +
                          VAR(&JOBDL) VALUE(&UTLLIB))
             CHGVAR     VAR(&NBRGRP) VALUE(&NBRGRP@)
             CHGVAR     VAR(&DTAARA) VALUE('HC' || &SYSNAM)

/*           Make sure that the utilities library is in the list     */
             ADDLIBLE   LIB(&UTLLIB)
             MONMSG     MSGID(CPF2103)
             RCVMSG     MSGTYPE(*LAST)

/*           Make sure that library list is retained                 */
             RTVJOBA    CURLIB(&CURLIB)
             IF         COND(&CURLIB *EQ '*NONE') THEN(CHGVAR +
                          VAR(&CURLIB) VALUE('*CRTDFT'))

/*           Save exit point                                         */
             CHGVAR     VAR(&EXIT) VALUE(&EXTPNT)

/*           Ensure mirroring process is ended after running command */
             IF         COND(&ENDMIR *EQ '*YES') THEN(CHGVAR +
                          VAR(&EXTPNT) VALUE('9'))

/*           Determine if command must be run already                */
             IF         COND(&EXIT *EQ 'S' *OR &EXIT *EQ 'A') THEN(DO)
/*            If HA --> Run command immediately                      */
              IF         COND(&PRD *EQ '*HA') THEN(CHGVAR +
                          VAR(&RUNCMD) VALUE('1'))
/*            If iCluster --> Check/update sync point data area      */
              IF         COND(&PRD *EQ '*IC') THEN(DO)
               CHGVAR     VAR(&MSGSNT) VALUE('0')
 RTVKEY:       RTVDTAARA  DTAARA(&UTLLIB/&DTAARA) RTNVAR(&CURDTA)
               MONMSG     MSGID(CPF1015) EXEC(DO)
                RCVMSG     MSGTYPE(*LAST)
                GOTO       CMDLBL(CRT)
               ENDDO
               CHGVAR     VAR(&CURKEY) VALUE(%SST(&CURDTA 23 17))
               CHGVAR     VAR(&CURCMDCMP) VALUE(%SST(&CURDTA 173 4))
/*             If same key, checkpoint                               */
               IF         COND(&KEY *EQ &CURKEY) THEN(GOTO +
                          CMDLBL(CHKPNT))
/*             If newer key and previous completed, checkpoint       */
               IF         COND(&KEY *GT &CURKEY *AND &CURCMDCMP *EQ +
                          '*YES') THEN(GOTO CMDLBL(CHKPNT))
/*             If newer key and previous pending, wait               */
               IF         COND(&KEY *GT &CURKEY *AND &CURCMDCMP *NE +
                          '*YES') THEN(DO)
                IF         COND(*NOT &MSGSNT) THEN(SNDPGMMSG +
                          MSGID(SCM0012) MSGF(HAUMSG) +
                          MSGDTA(&DTAARA || &UTLLIB || &CURKEY || +
                          &KEY) TOPGMQ(*SAME))
                CHGVAR     VAR(&MSGSNT) VALUE('1')
                DLYJOB     DLY(5)
                GOTO       CMDLBL(RTVKEY)
               ENDDO
/*             If older key, skip checkpoint processing              */
               IF         COND(&KEY *LT &CURKEY) THEN(DO)
                SNDPGMMSG  MSGID(SCM0013) MSGF(HAUMSG) MSGDTA(&DTAARA +
                          || &UTLLIB || &CURKEY || &KEY) +
                          TOPGMQ(*SAME) MSGTYPE(*DIAG)
                GOTO       CMDLBL(END)
               ENDDO

/*             Create data area with default values                  */
 CRT:          CHGVAR     VAR(&INZDTA) VALUE(' ')
               CHGVAR     VAR(%SST(&INZDTA 1 20)) VALUE('Key value +
                          (time)   :')
               CHGVAR     VAR(%SST(&INZDTA 51 20)) VALUE('Total nbr of +
                          groups:')
               CHGVAR     VAR(%SST(&INZDTA 101 20)) VALUE('Groups +
                          synchronised:')
               CHGVAR     VAR(%SST(&INZDTA 151 20)) VALUE('Command +
                          completed  :')
               CHGVAR     VAR(%SST(&INZDTA 201 20)) VALUE('Job running +
                          command:')
               CHGVAR     VAR(%SST(&INZDTA 251 20)) +
                          VALUE('Checkpointed groups:')
               CRTDTAARA  DTAARA(&UTLLIB/&DTAARA) TYPE(*CHAR) +
                          LEN(1000) VALUE(&INZDTA) TEXT('HSNDCMD - +
                          Sync point for system' |> &SYSNAM)

/*             Checkpoint processing, handle checkpoint for iCluster */
/*             Now, allocate the data area exclusively               */
 CHKPNT:       ALCOBJ     OBJ((&UTLLIB/&DTAARA *DTAARA *EXCL *N))
               RTVDTAARA  DTAARA(&UTLLIB/&DTAARA) RTNVAR(&CURDTA)
               CHGVAR     VAR(&CURKEY) VALUE(%SST(&CURDTA 23 17))
               CHGVAR     VAR(&CURNBRGRP@) VALUE(%SST(&CURDTA 73 5))
               CHGVAR     VAR(&CURNBRSYN@) VALUE(%SST(&CURDTA 123 5))
               CHGVAR     VAR(&CURCMDCMP) VALUE(%SST(&CURDTA 173 4))
               CHGVAR     VAR(&CURCMDJOB) VALUE(%SST(&CURDTA 223 28))
               CHGVAR     VAR(&CURGRPSYN) VALUE(%SST(&CURDTA 273 500))
/*             Check if key is the same, if not --> initialize       */
               RTVDTAARA  DTAARA(&UTLLIB/&DTAARA (23 17)) RTNVAR(&CURKEY)
               IF         COND(&CURKEY *NE &KEY) THEN(DO)
                CHGVAR     VAR(&CURKEY) VALUE(&KEY)
                CHGVAR     VAR(&CURNBRGRP@) VALUE(&NBRGRP@)
                CHGVAR     VAR(&CURNBRSYN@) VALUE('00000')
                CHGVAR     VAR(&CURCMDCMP) VALUE('*NO')
                CHGVAR     VAR(&CURCMDJOB) VALUE('*NONE')
                CHGVAR     VAR(&CURGRPSYN) VALUE(' ')
               ENDDO
/*             Increment number of checkpoints and show group        */
               CHGVAR     VAR(&CURNBRSYN) VALUE(&CURNBRSYN@)
               CHGVAR     VAR(&CURNBRSYN) VALUE(&CURNBRSYN + 1)
               CHGVAR     VAR(&CURNBRSYN@) VALUE(&CURNBRSYN)
               IF         COND(&CURGRPSYN *EQ ' ') THEN(CHGVAR +
                          VAR(&CURGRPSYN) VALUE(&GRPNAM))
               ELSE       CMD(CHGVAR VAR(&CURGRPSYN) VALUE(&CURGRPSYN +
                          |< ',' |< &GRPNAM))
                          CHGVAR VAR(%SST(&CURDTA 23 17)) VALUE(&CURKEY)
               CHGVAR     VAR(%SST(&CURDTA 73 5)) VALUE(&CURNBRGRP@)
               CHGVAR     VAR(%SST(&CURDTA 123 5)) VALUE(&CURNBRSYN@)
               CHGVAR     VAR(%SST(&CURDTA 173 4)) VALUE(&CURCMDCMP)
               CHGVAR     VAR(%SST(&CURDTA 223 28)) VALUE(&CURCMDJOB)
               CHGVAR     VAR(%SST(&CURDTA 273 500)) VALUE(&CURGRPSYN)
               CHGDTAARA  DTAARA(&UTLLIB/&DTAARA) VALUE(&CURDTA)
/*             Now, deallocate the data area                         */
               DLCOBJ     OBJ((&UTLLIB/&DTAARA *DTAARA *EXCL *N))
/*             If number of groups reached checkpoint --> run        */
               IF         COND(&CURNBRSYN@ *GE &CURNBRGRP@) THEN(DO)
                CHGVAR     VAR(&RUNCMD) VALUE('1')
                GOTO       CMDLBL(RUNCMD)
               ENDDO

/*             If not last group, wait for other groups to reach cp  */
               CHGVAR     VAR(&PRVNBRSYN@) VALUE(' ')
/*             If number of groups not reached --> message           */
 WAITGRP:      IF         COND(&CURNBRSYN@ *NE &PRVNBRSYN@) THEN(DO)
                SNDPGMMSG  MSGID(SCM0007) MSGF(HAUMSG) MSGDTA(&DTAARA +
                          || &UTLLIB || &KEY || &CURNBRGRP@ || +
                          &CURNBRSYN@) TOPGMQ(*SAME) MSGTYPE(*INFO)
                CHGVAR     VAR(&PRVNBRSYN@) VALUE(&CURNBRSYN@)
               ENDDO
               RTVDTAARA  DTAARA(&UTLLIB/&DTAARA) RTNVAR(&CURDTA)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                SNDPGMMSG  MSGID(SCM0014) MSGF(HAUMSG) MSGDTA(&DTAARA +
                          || &UTLLIB || &KEY) MSGTYPE(*DIAG)
                GOTO       CMDLBL(END)
               ENDDO
               CHGVAR     VAR(&CURNBRGRP@) VALUE(%SST(&CURDTA 73 5))
               CHGVAR     VAR(&CURNBRSYN@) VALUE(%SST(&CURDTA 123 5))
               IF         COND(&CURNBRSYN@ *LT &CURNBRGRP@) THEN(DO)
                CALL       PGM(HDLYJOBMS) PARM(X'0000500F')
                GOTO       CMDLBL(WAITGRP)
               ENDDO
               SNDPGMMSG  MSGID(SCM0024) MSGF(HAUMSG) MSGDTA(&DTAARA +
                          || &UTLLIB || &KEY) TOPGMQ(*SAME) +
                          MSGTYPE(*INFO)
              ENDDO
             ENDDO

/*           Run command indicated in HSNDCMD                        */
 RUNCMD:     IF         COND(&RUNCMD) THEN(DO)
/*            Send message to job log indicating command executed    */
              SNDPGMMSG  MSGID(SCM0001) MSGF(HAUMSG) MSGDTA(&KEY || +
                          &PRD || &TGTNAM || &GRPNAM || &ENDMIR || +
                          &BATCH || &CMD) TOPGMQ(*SAME)
/*            Optionally make up to submit to batch                  */
              IF         COND(&BATCH *EQ '*YES') THEN(DO)
               CHGVAR     VAR(&CMD) VALUE('SBMJOB CMD(' |< &CMD |< ') +
                          JOB(' |< &JOB |< ') JOBD(' |< &JOBDL |< +
                          '/' |< &JOBD |< ') USER(' |< &USER |< ')')
/*             Add INLLIBL parameter component                       */
               IF         COND(&INLLIBL *EQ '*APPLYJOB') THEN(CHGVAR +
                          VAR(&CMD) VALUE(&CMD |> 'INLLIBL(*CURRENT)'))
               IF         COND(&INLLIBL *EQ '*JOBD') THEN(CHGVAR +
                          VAR(&CMD) VALUE(&CMD |> 'INLLIBL(*JOBD)'))
              ENDDO
/*            Run command                                            */
              SNDPGMMSG  MSGID(SCM0025) MSGF(HAUMSG) MSGDTA(&CMD) +
                          TOPGMQ(*SAME)
              CALL       PGM(QCMDEXC) PARM(&CMD 512)
              MONMSG     MSGID(CPF0000 MCH0000) EXEC(DO)
               CHGVAR     VAR(&CURCMDCMP) VALUE('*YES')
               CHGDTAARA  DTAARA(&UTLLIB/&DTAARA (173 4)) +
                          VALUE(&CURCMDCMP)
               RTVJOBA    JOB(&SBMJOB) USER(&SBMUSR) NBR(&SBMNBR)
               GOTO       CMDLBL(CHGJOBDTA)
              ENDDO
/*            If command not submitted to batch, mark completed      */
              IF         COND(&BATCH *EQ '*NO') THEN(DO)
               CHGVAR     VAR(&CURCMDCMP) VALUE('*YES')
               CHGDTAARA  DTAARA(&UTLLIB/&DTAARA (173 4)) +
                          VALUE(&CURCMDCMP)
               RTVJOBA    JOB(&SBMJOB) USER(&SBMUSR) NBR(&SBMNBR)
              ENDDO
/*            If command submitted to batch, store job info          */
              IF         COND(&BATCH *EQ '*YES') THEN(DO)
               RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGDTA(&MSGDTA) +
                          MSGID(&MSGID)
               IF         COND(&MSGID *EQ 'CPC1221') THEN(DO)
                CHGVAR     VAR(&SBMJOB) VALUE(%SST(&MSGDTA 1 10))
                CHGVAR     VAR(&SBMUSR) VALUE(%SST(&MSGDTA 11 10))
                CHGVAR     VAR(&SBMNBR) VALUE(%SST(&MSGDTA 21 60))
               ENDDO
              ENDDO
 CHGJOBDTA:   CHGVAR     VAR(&CURCMDJOB) VALUE(&SBMNBR |< '/' |< +
                          &SBMUSR |< '/' |< &SBMJOB)
              CHGDTAARA  DTAARA(&UTLLIB/&DTAARA (223 28)) +
                          VALUE(&CURCMDJOB)
             ENDDO

/*           Wait for completion of job                              */
             CHGVAR     VAR(&MSGSNT) VALUE('0')
 WAITCOMP:   IF         COND(&WAITCOMP *EQ '*YES' *AND &ENDMIR *NE +
                          '*YES') THEN(DO)
              IF         COND(&RUNCMD *AND &BATCH *EQ '*NO') +
                          THEN(GOTO CMDLBL(EWAITCOMP))
/*            If batch job, wait for completion                      */
              IF         COND(&RUNCMD *AND &BATCH *EQ '*YES') THEN(DO)
               IF         COND(*NOT &MSGSNT) THEN(SNDPGMMSG +
                          MSGID(SCM0015) MSGF(HAUMSG) MSGDTA(&KEY +
                          || &SBMJOB || &SBMUSR || &SBMNBR) +
                          TOPGMQ(*SAME))
               CHGVAR     VAR(&MSGSNT) VALUE('1')
               HRTVJOBSTS JOB(&SBMNBR/&SBMUSR/&SBMJOB) STATUS(&SBMSTS)
               IF         COND(&SBMSTS *EQ '*OUTQ' *OR &SBMSTS *EQ +
                          '*ERROR') THEN(DO)
                SNDPGMMSG  MSGID(SCM0017) MSGF(HAUMSG) MSGDTA(&KEY || +
                          &SBMJOB || &SBMUSR || &SBMNBR) +
                          TOPGMQ(*SAME) MSGTYPE(*COMP)
                CHGVAR     VAR(&CURCMDCMP) VALUE('*YES')
                CHGDTAARA  DTAARA(&UTLLIB/&DTAARA (173 4)) +
                          VALUE(&CURCMDCMP)
                MONMSG     MSGID(CPF0000)
                GOTO       CMDLBL(EWAITCOMP)
               ENDDO
              ENDDO
/*            If the current job does not run the command, wait      */
              IF         COND(*NOT &RUNCMD) THEN(DO)
               RTVDTAARA  DTAARA(&UTLLIB/&DTAARA) RTNVAR(&CURDTA)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                SNDPGMMSG  MSGID(SCM0022) MSGF(HAUMSG) MSGDTA(&DTAARA +
                          || &UTLLIB || &KEY) TOPGMQ(*SAME) +
                          MSGTYPE(*DIAG)
                GOTO       CMDLBL(EWAITCOMP)
               ENDDO
               CHGVAR     VAR(&CURKEY) VALUE(%SST(&CURDTA 23 17))
               CHGVAR     VAR(&CURCMDCMP) VALUE(%SST(&CURDTA 173 4))
               IF         COND(&CURCMDCMP *EQ '*NO' *AND &KEY *EQ +
                          &CURKEY) THEN(DO)
                IF         COND(*NOT &MSGSNT) THEN(SNDPGMMSG +
                          MSGID(SCM0016) MSGF(HAUMSG) +
                          MSGDTA(&DTAARA || &UTLLIB || &KEY) +
                          TOPGMQ(*SAME))
                CHGVAR     VAR(&MSGSNT) VALUE('1')
               ENDDO
/*             If running of the command was skipped, continue       */
               IF         COND(&CURCMDCMP *EQ '*YES' *OR &KEY *NE +
                          &CURKEY) THEN(DO)
                SNDPGMMSG  MSGID(SCM0018) MSGF(HAUMSG) MSGDTA(&DTAARA +
                          || &UTLLIB || &KEY) TOPGMQ(*SAME)
                GOTO       CMDLBL(EWAITCOMP)
               ENDDO
              ENDDO
/*            Wait for 1/2 second and loop                           */
              CALL       PGM(HDLYJOBMS) PARM(X'0000500F')
              GOTO       CMDLBL(WAITCOMP)
 EWAITCOMP:  ENDDO

/*           Restart apply jobs?                                     */
             IF         COND(&RUNCMD *AND &RESTART *EQ '*YES' *AND +
                          &BATCH *EQ '*YES' *AND &ENDMIR *EQ +
                          '*YES') THEN(DO)
              SNDPGMMSG  MSGID(SCM0023) MSGF(HAUMSG) MSGDTA(&DTAARA +
                          || &UTLLIB || &KEY || &SBMJOB || &SBMUSR +
                          || &SBMNBR) TOPGMQ(*SAME)
              SBMJOB     CMD(CALL PGM(HSNDCMD3) PARM(&DTAARA &UTLLIB +
                          &KEY &SBMJOB &SBMUSR &SBMNBR)) +
                          JOB(HSNDCMDAPY) JOBD(HAUTILS)
              GOTO       CMDLBL(RSTLIBL)
             ENDDO

/*           Mark command as completed                               */
             IF         COND(&RUNCMD) THEN(DO)
              CHGDTAARA  DTAARA(&UTLLIB/&DTAARA (173 4)) VALUE('*YES')
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           Restore library list                                    */
 RSTLIBL:    CHGVAR     VAR(&CMD) VALUE('CHGLIBL LIBL(' |< &USRLIBL +
                          |< ') CURLIB(' |< &CURLIB |< ')')
             CALL       PGM(QCMDEXC) PARM(&CMD 512)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Restore library list                                    */
             CHGVAR     VAR(&CMD) VALUE('CHGLIBL LIBL(' |< &USRLIBL +
                          |< ') CURLIB(' |< &CURLIB |< ')')
             CALL       PGM(QCMDEXC) PARM(&CMD 512)

/*           Move all *DIAG and *ESCAPE messages to previous queue   */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
