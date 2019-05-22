/*CP: USRPRF(*OWNER)                                                 */
/* ================================================================= */
/* Object:         HENDCST         *PGM CLP                          */
/*                 This program can be used to stop iCluster on the  */
/*                 current node. It will end all groups and when     */
/*                 finished, end the node and optionally the sub-    */
/*                 system.                                           */
/*                                                                   */
/* Create:         CRTCLPGM                                          */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040514 FK  Initial delivery                                     */
/* 20050209 FK  Submit as DMCLUSTER, user profile *OWNER             */
/*              Do not fail if status message queue is full          */
/* 20051006 FK  Optionally wait until subsystem ended                */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20070504 FK  Allow for different iCluster user and subsystem      */
/* 20080212 FK  Allow ending groups without ending node              */
/* 20080212 FK  Allow ending groups without ending node              */
/* 20110718 FK  Handle error messages while waiting for end of       */
/*              subsystem                                            */
/* ================================================================= */
             PGM        PARM(&OPTION &DELAY &STSMSGQQ &MAXWAITGRP +
                          &ENDNOD &MAXWAITNOD &ENDSBS &WAITSBS)

/*           Declare parameter variables                              */
             DCL        VAR(&OPTION) TYPE(*CHAR) LEN(7)
             DCL        VAR(&DELAY) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&STSMSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&MAXWAITGRP) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&ENDNOD) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MAXWAITNOD) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&ENDSBS) TYPE(*CHAR) LEN(4)
             DCL        VAR(&WAITSBS) TYPE(*CHAR) LEN(4)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICUSER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICSBSD) TYPE(*CHAR) LEN(10)

             DCL        VAR(&STSMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STSMSGQL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&SBSI0100) TYPE(*CHAR) LEN(80)
             DCL        VAR(&SBSSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBSDQ) TYPE(*CHAR) LEN(20)

             DCL        VAR(&MAXWAITG@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MAXWAITN@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MAXWAIT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&CURWAIT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&CURUSER) TYPE(*CHAR) LEN(10)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE) CURUSER(&CURUSER)

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB) +
                          ICUSER(&ICUSER) ICSBSD(&ICSBSD)
/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

             HRTVNETA   SYSNAME(&SYSNAME)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&STSMSGQ) VALUE(%SST(&STSMSGQQ 1 10))
             CHGVAR     VAR(&STSMSGQL) VALUE(%SST(&STSMSGQQ 11 10))

/*           Translate special value                                 */
             IF         COND(&STSMSGQ *EQ '*CURRENT') THEN(CHGVAR +
                          VAR(&STSMSGQ) VALUE(&CURUSER))

/*           Check existence of message queue if not *NONE           */
             IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
              CHKOBJ     OBJ(&STSMSGQL/&STSMSGQ) OBJTYPE(*MSGQ)
             ENDDO

/*           If iCluster subsystem is not active, do not run         */
             CHGVAR     VAR(&SBSDQ) VALUE(&ICSBSD || &ICLIB)
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QWDRSBSD) PARM(&SBSI0100 X'00000050' +
                          'SBSI0100' &SBSDQ &APIERR)
             CHGVAR     VAR(&SBSSTS) VALUE(%SST(&SBSI0100 29 10))
             IF         COND(&SBSSTS *NE '*ACTIVE') THEN(DO)
              SNDPGMMSG  MSGID(ECS0001) MSGF(HAUMSG) MSGDTA(&SBSDQ) +
                          MSGTYPE(*INFO)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(ECS0001) MSGF(HAUMSG) MSGDTA(&SBSDQ) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
               MONMSG     MSGID(CPF0000)
              ENDDO
              GOTO       CMDLBL(END)
             ENDDO

/*           If the job is interactive --> submit                    */
             IF         COND(&JOBTYPE *EQ '1' *OR &CURUSER *NE +
                          &ICUSER) THEN(DO)
              SBMJOB     CMD(HENDCST OPTION(&OPTION) DELAY(&DELAY) +
                          STSMSGQ(&STSMSGQL/&STSMSGQ) +
                          MAXWAITGRP(&MAXWAITGRP) ENDNOD(&ENDNOD) +
                          MAXWAITNOD(&MAXWAITNOD) ENDSBS(&ENDSBS) +
                          WAITSBS(*NO)) JOB(HENDCST) JOBD(HAUTILS) +
                          USER(&ICUSER) INLLIBL(*JOBD)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(WAITSBS)
             ENDDO

/*           Set current library for iCluster commands               */
             CHGCURLIB  CURLIB(&ICLIB)

/*           End all active groups                                   */
             CALL       PGM(HENDCST1) PARM(&OPTION &DELAY &STSMSGQ +
                          &STSMSGQL)

/*           Wait until all groups have ended (max wait time)        */
             CHGVAR     VAR(%BIN(&MAXWAITG@)) VALUE(&MAXWAITGRP)
             SNDPGMMSG  MSGID(ECS0011) MSGF(HAUMSG) MSGDTA(&MAXWAITG@)
             CHGVAR     VAR(&MAXWAIT) VALUE(&MAXWAITGRP * 4)
             CHGVAR     VAR(&CURWAIT) VALUE(1)
 WAITGRP:    HRTVSTS    ICGROUP(*ANY) STATUS(&STATUS)
             IF         COND(&STATUS *EQ '*ACTIVE' *AND &CURWAIT *LE +
                          &MAXWAIT) THEN(DO)
              DLYJOB     DLY(15)
              CHGVAR     VAR(&CURWAIT) VALUE(&CURWAIT + 1)
              GOTO       CMDLBL(WAITGRP)
             ENDDO

/*           If any groups still active, send diagnostic             */
             IF         COND(&STATUS *EQ '*ACTIVE') THEN(DO)
              SNDPGMMSG  MSGID(ECS0012) MSGF(HAUMSG) +
                          MSGDTA(&MAXWAITG@) MSGTYPE(*DIAG)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(ECS0012) MSGF(HAUMSG) +
                          MSGDTA(&MAXWAITG@) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ) MSGTYPE(*DIAG)
               MONMSG     MSGID(CPF0000)
              ENDDO
             ENDDO

/*           End the node now                                        */
             IF         COND(&ENDNOD *EQ '*YES') THEN(DO)
              SNDPGMMSG  MSGID(ECS0013) MSGF(HAUMSG) MSGDTA(&SYSNAME)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(ECS0013) MSGF(HAUMSG) MSGDTA(&SYSNAME) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
               MONMSG     MSGID(CPF0000)
              ENDDO
              DMENDNODE  NODE(&SYSNAME)

/*            Wait the specified maximum time until node ended       */
              CHGVAR     VAR(%BIN(&MAXWAITN@)) VALUE(&MAXWAITNOD)
              SNDPGMMSG  MSGID(ECS0015) MSGF(HAUMSG) MSGDTA(&MAXWAITN@)
              CHGVAR     VAR(&MAXWAIT) VALUE(&MAXWAITNOD * 4)
              CHGVAR     VAR(&CURWAIT) VALUE(1)
 WAITNODE:    HRTVNODSTS STATUS(&STATUS)
              IF         COND(&STATUS *NE '*UNKNOWN' *AND &STATUS *NE +
                          '*INACTIVE' *AND &CURWAIT *LE &MAXWAIT) +
                          THEN(DO)
               DLYJOB     DLY(15)
               CHGVAR     VAR(&CURWAIT) VALUE(&CURWAIT + 1)
               GOTO       CMDLBL(WAITNODE)
              ENDDO

/*            If node was not inactive, send error message           */
              IF         COND(&STATUS *NE '*UNKNOWN' *AND &STATUS *NE +
                          '*INACTIVE') THEN(DO)
               SNDPGMMSG  MSGID(ECS0014) MSGF(HAUMSG) MSGDTA(&SYSNAME +
                          || &MAXWAITN@) MSGTYPE(*DIAG)
               IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
                SNDPGMMSG  MSGID(ECS0014) MSGF(HAUMSG) MSGDTA(&SYSNAME +
                          || &MAXWAITN@) TOMSGQ(&STSMSGQL/&STSMSGQ) +
                          MSGTYPE(*DIAG)
                MONMSG     MSGID(CPF0000)
               ENDDO
              ENDDO
             ENDDO

/*           End the subsystem controlled with 10 seconds delay      */
             IF         COND(&ENDNOD *EQ '*YES' *AND &ENDSBS *EQ +
                          '*YES') THEN(ENDSBS SBS(&ICSBSD) +
                          OPTION(*CNTRLD) DELAY(10))

             GOTO       CMDLBL(END)

/*           Wait for the end of the subsystem, if requested         */
 WAITSBS:    IF         COND(&ENDNOD *EQ '*YES' *AND &ENDSBS *EQ +
                          '*YES' *AND &WAITSBS *EQ '*YES') THEN(DO)
              SNDPGMMSG  MSGID(ECS0017) MSGF(HAUMSG) MSGDTA(&ICSBSD) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(ECS0017) MSGF(HAUMSG) MSGDTA(&ICSBSD) +
                          TOPGMQ(*SAME) MSGTYPE(*INFO)
              CHGVAR     VAR(&SBSDQ) VALUE(&ICSBSD || &ICLIB)
 LOOPSBS:     CHGVAR     VAR(&APIERR) VALUE(X'00080000')
              CALL       PGM(QWDRSBSD) PARM(&SBSI0100 X'00000100' +
                          'SBSI0100' &SBSDQ &APIERR)
              CHGVAR     VAR(&SBSSTS) VALUE(%SST(&SBSI0100 29 10))
              IF         COND(&SBSSTS *EQ '*ACTIVE') THEN(DO)
               DLYJOB     DLY(1)
               GOTO       CMDLBL(LOOPSBS)
              ENDDO
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
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
