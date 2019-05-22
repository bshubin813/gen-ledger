/* ================================================================= */
/* Object:         HSNDCMD         *PGM CLP                          */
/*                 Sends command through HA Suite.                   */
/*                                                                   */
/* Create remarks:                                                   */
/*                                                                   */
/* Synopsis:       Allows to send a command through the iCluster     */
/*                 processes. Supported exit points:                 */
/*                 1. Data journal scrape                            */
/*                 2. Apply                                          */
/*                                                                   */
/*                 The program executes the ADDHACHK command which   */
/*                 sends the user data to the processes associated   */
/*                 with the specified target/group.                  */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990729 FK  Initial delivery                                     */
/* 20020111 FK  Make HA Suite current library                        */
/* 20020506 FK  Allow submit to batch with jobd/user                 */
/*              Enable for iCluster                                  */
/* 20030114 FK  Remove PRD parameter and let TARGET/ICGROUP control  */
/*              application to add sync point                        */
/* 20040119 FK  For iCluster, only set sync point for local groups   */
/* 20040207 FK  Run remote command only once                         */
/*              Remove parameter for utilities library on target     */
/* 20050210 FK  Specify backup node (iCluster)                       */
/*              Allow to specify submitted job's name                */
/* 20050422 FK  Skip non-active groups                               */
/* 20050429 FK  Delete LFs in QTEMP in the end                       */
/* 20050714 FK  Run HSNDCMD2 instead of HEXTCMD                      */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20071024 FK  Allow to choose library list for submitted job       */
/* 20080509 FK  Allow groups to await completion of submitted job    */
/*              Optionally restart apply processes                   */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&CMD &ICGROUP &BCKNOD &SCRAPE &APPLY +
                          &ENDMIR &BATCH &JOBDQ &JOB &USER &INLLIBL +
                          &WAITCOMP &RESTART)

/*           Declare parameter variables                              */
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(256)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&SCRAPE) TYPE(*CHAR) LEN(4)
             DCL        VAR(&APPLY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENDMIR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JOBDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&INLLIBL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&WAITCOMP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RESTART) TYPE(*CHAR) LEN(4)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USRDTA) TYPE(*CHAR) LEN(400)

             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)
             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)
             DCL        VAR(&QDATE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&QTIME) TYPE(*CHAR) LEN(6)
             DCL        VAR(&ISODATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&KEY) TYPE(*CHAR) LEN(17)
             DCL        VAR(&NBRGRP@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&GRPBCKNOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */
             DCLF       FILE(HIGRPGN)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */

/*           Convert variables to usable format                      */
             IF         COND(&USER *EQ '*CURRENT') THEN(RTVJOBA +
                          CURUSER(&USER))

/*           Determine the product to use for adding checkpoint      */
             CHGVAR     VAR(&PRD) VALUE('*IC')

/*           Retrieve HA Suite/iCluster library                      */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

             HRTVNETA   SYSNAME(&SYSNAME)

/*           Make up the key for iCluster                            */
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&QDATE)
             RTVSYSVAL  SYSVAL(QTIME) RTNVAR(&QTIME)
             CVTDAT     DATE(&QDATE) TOVAR(&ISODATE) +
                          FROMFMT(*SYSVAL) TOFMT(*ISO)
             CHGVAR     VAR(&KEY) VALUE(&ISODATE || '.' || &QTIME)

/*           If all groups for iCluster --> determine number         */
             IF         COND(&PRD *EQ '*IC' *AND &ICGROUP *EQ +
                          '*ALL') THEN(DO)
              CALL       PGM(HSNDCMD1) PARM(&SYSNAME &NBRGRP@ &BCKNOD)
              IF         COND(&NBRGRP@ *EQ '00000') THEN(DO)
               SNDPGMMSG  MSGID(SCM0011) MSGF(HAUMSG) MSGTYPE(*DIAG)
               GOTO       CMDLBL(END)
              ENDDO
             ENDDO
             ELSE       CMD(CHGVAR VAR(&NBRGRP@) VALUE('00001'))

/*           Make up the user data variable                          */
             CHGVAR     VAR(&USRDTA) VALUE(' ')
             CHGVAR     VAR(%SST(&USRDTA 1 10)) VALUE(&UTLLIB)
             CHGVAR     VAR(%SST(&USRDTA 11 3)) VALUE(&PRD)
             CHGVAR     VAR(%SST(&USRDTA 14 4)) VALUE(&ENDMIR)
             CHGVAR     VAR(%SST(&USRDTA 18 8)) VALUE(&SYSNAME)
             CHGVAR     VAR(%SST(&USRDTA 26 17)) VALUE(&KEY)
             CHGVAR     VAR(%SST(&USRDTA 43 5)) VALUE(&NBRGRP@)
             CHGVAR     VAR(%SST(&USRDTA 48 4)) VALUE(&BATCH)
             CHGVAR     VAR(%SST(&USRDTA 52 20)) VALUE(&JOBDQ)
             CHGVAR     VAR(%SST(&USRDTA 72 10)) VALUE(&USER)
             CHGVAR     VAR(%SST(&USRDTA 82 10)) VALUE(&JOB)
             CHGVAR     VAR(%SST(&USRDTA 92 10)) VALUE(&INLLIBL)
             CHGVAR     VAR(%SST(&USRDTA 102 4)) VALUE(&WAITCOMP)
             CHGVAR     VAR(%SST(&USRDTA 106 4)) VALUE(&RESTART)
             CHGVAR     VAR(%SST(&USRDTA 110 256)) VALUE(&CMD)

/*           Execute the command for iCluster                        */
             IF         COND(&PRD *EQ '*IC') THEN(DO)
              CHGCURLIB  CURLIB(&ICLIB)
/*            Create file to access iCluster groups                  */
              CALL       PGM(HCRTLF) PARM('HIGRPGN')
              OVRDBF     FILE(HIGRPGN) TOFILE(QTEMP/HIGRPGN)
/*            Set the synchronisation point for all groups?          */
              IF         COND(&ICGROUP *EQ '*ALL') THEN(DO)
 LOOPGRP:      RCVF
               MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOPGRP))
               IF         COND(&GRPTYPE *NE 'R' *OR &CURRPRIM *NE +
                          &SYSNAME) THEN(GOTO CMDLBL(LOOPGRP))
/*             If group's backup node not selected --> skip          */
               HRTVCRG    CRG(&GROUP) BCKNOD(&GRPBCKNOD)
               IF         COND(&GRPBCKNOD *NE &BCKNOD) THEN(GOTO +
                          CMDLBL(LOOPGRP))
/*             Skip non-active groups                                */
               HRTVSTS    ICGROUP(&GROUP) PRCTYP(*SND) STATUS(&STATUS)
               IF         COND(&STATUS *NE '*ACTIVE') THEN(DO)
                SNDPGMMSG  MSGID(SCM0010) MSGF(HAUMSG) MSGDTA(&GROUP) +
                          TOPGMQ(*SAME)
                GOTO       CMDLBL(LOOPGRP)
               ENDDO
              ENDDO
              ELSE       CMD(CHGVAR VAR(&GROUP) VALUE(&ICGROUP))
              DMSETSYNC  GROUP(&GROUP) USREXIT(&UTLLIB/HSNDCMD2) +
                          SCRAPE(&SCRAPE) APPLY(&APPLY) +
                          USRDATA(&USRDTA)
              SNDPGMMSG  MSGID(SCM0005) MSGF(HAUMSG) MSGDTA(&GROUP || +
                          &CMD)
              IF         COND(&ICGROUP *EQ '*ALL') THEN(GOTO +
                          CMDLBL(LOOPGRP))
 ELOOPGRP:    IF         COND(&ICGROUP *EQ '*ALL') THEN(DO)
               SNDPGMMSG  MSGID(SCM0006) MSGF(HAUMSG) MSGDTA(&UTLLIB +
                          || &SYSNAME || &KEY || &NBRGRP@) +
                          MSGTYPE(*COMP)
              ENDDO
             ENDDO

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
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
