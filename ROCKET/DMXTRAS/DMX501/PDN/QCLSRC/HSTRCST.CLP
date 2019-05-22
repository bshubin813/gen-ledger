/*CP: USRPRF(*OWNER)                                                 */
/* ================================================================= */
/* Object:         HSTRCST         *PGM CLP                          */
/*                 This program can be used in the IPL startup       */
/*                 program to automatically start the current node   */
/*                 and if all nodes are active, start the groups.    */
/*                                                                   */
/* Create:         CRTCLPGM USRPRF(*OWNER)                           */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040429 FK  Initial delivery                                     */
/* 20040507 FK  Parameter to start apply jobs                        */
/* 20040524 FK  Start groups that deal with active nodes             */
/* 20040920 FK  Parameter for delay before starting groups           */
/* 20050209 FK  Submit as DMCLUSTER, user profile *OWNER             */
/* 20051114 FK  Start of apply parameter ignored                     */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20070504 FK  Allow for different iCluster user and subsystem      */
/* 20080212 FK  Await activation of TCP/IP before starting           */
/* ================================================================= */
             PGM        PARM(&STRGRP &STRAPY &STSMSGQQ &NBRATM +
                          &MAXWAITNOD &DLYSTRGRP &MAXWAITTCP)

/*           Declare parameter variables                              */
             DCL        VAR(&STRGRP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRAPY) TYPE(*CHAR) LEN(6)
             DCL        VAR(&STSMSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&NBRATM) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&MAXWAITNOD) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&DLYSTRGRP) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&MAXWAITTCP) TYPE(*DEC) LEN(3 0)

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

             DCL        VAR(&CURNODACT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&NODSTR) TYPE(*CHAR) LEN(1)
             DCL        VAR(&CURUSER) TYPE(*CHAR) LEN(10)

             DCL        VAR(&MAXWAITT@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&I) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MAXWAIT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&IPSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IPDTS) TYPE(*CHAR) LEN(26)

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

/*           First wait for TCP/IP to become active                  */
             IF         COND(&MAXWAITTCP *NE 0) THEN(DO)
              CHGVAR     VAR(&I) VALUE(0)
              CHGVAR     VAR(&MAXWAIT) VALUE(&MAXWAITTCP * 60)
 LOOPIP:      CALL       PGM(HCHKIP) PARM(&IPSTS &IPDTS)
/*            If TCP/IP not active, wait for another round           */
              IF         COND(&IPSTS *NE '*ACTIVE' *AND &I *LT +
                          &MAXWAIT) THEN(DO)
/*             Only on first check, issue message                    */
               IF         COND(&I *EQ 0) THEN(DO)
                CHGVAR     VAR(%BIN(&MAXWAITT@)) VALUE(&MAXWAITTCP)
                SNDPGMMSG  MSGID(CST0017) MSGF(HAUMSG) +
                          MSGDTA(&MAXWAITT@) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)
                SNDPGMMSG  MSGID(CST0017) MSGF(HAUMSG) +
                          MSGDTA(&MAXWAITT@) TOPGMQ(*SAME) +
                          MSGTYPE(*INFO)
               ENDDO
               DLYJOB     DLY(15)
               CHGVAR     VAR(&I) VALUE(&I + 15)
               GOTO       CMDLBL(LOOPIP)
              ENDDO
/*            Stop if TCP/IP still not active, else send message     */
              IF         COND(&IPSTS *NE '*ACTIVE') THEN(DO)
               SNDPGMMSG  MSGID(CST0018) MSGF(HAUMSG) MSGDTA(&IPSTS) +
                          MSGTYPE(*DIAG)
               GOTO       CMDLBL(END)
              ENDDO
              ELSE       CMD(SNDPGMMSG MSGID(CST0019) MSGF(HAUMSG) +
                          MSGDTA(&IPSTS || &IPDTS) TOPGMQ(*SAME) +
                          MSGTYPE(*INFO))
             ENDDO

/*           First start iCluster subsystem if not yet started       */
             STRSBS     SBSD(&ICLIB/&ICSBSD)
             MONMSG     MSGID(CPF1010) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              GOTO       CMDLBL(SBSSTR)
             ENDDO
             SNDPGMMSG  MSGID(SCS0001) MSGF(HAUMSG) MSGDTA(&ICSBSD) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
             DLYJOB     DLY(5)

/*           If the job is interactive --> submit                    */
 SBSSTR:     IF         COND(&JOBTYPE *EQ '1' *OR &CURUSER *NE +
                          &ICUSER) THEN(DO)
              SBMJOB     CMD(HSTRCST STRGRP(&STRGRP) STRAPY(&STRAPY) +
                          STSMSGQ(&STSMSGQL/&STSMSGQ) +
                          NBRATM(&NBRATM) MAXWAITNOD(&MAXWAITNOD) +
                          DLYSTRGRP(&DLYSTRGRP) +
                          MAXWAITTCP(&MAXWAITTCP)) JOB(HSTRCST) +
                          JOBD(HAUTILS) USER(&ICUSER) INLLIBL(*JOBD)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Set current library for iCluster commands               */
             CHGCURLIB  CURLIB(&ICLIB)
             HRTVNETA   SYSNAME(&SYSNAME)

/*           Start current node and check if it became active        */
             CALL       PGM(HSTRCST1) PARM(&SYSNAME &STSMSGQ +
                          &STSMSGQL &NBRATM &MAXWAITNOD &CURNODACT +
                          &NODSTR)

/*           If any nodes started, wait a bit (DLYSTRGRP)            */
             IF         COND(&CURNODACT *EQ '1' *AND &NODSTR *EQ '1' +
                          *AND &DLYSTRGRP > 0) THEN(DLYJOB +
                          DLY(&DLYSTRGRP))

/*           If current node active and start groups                 */
             IF         COND(&CURNODACT *EQ '1' *AND &STRGRP *EQ +
                          '*YES') THEN(DO)
/*            If any nodes started, wait a bit (DLYSTRGRP)           */
              IF         COND(&NODSTR *EQ '1' *AND &DLYSTRGRP > 0) +
                          THEN(DLYJOB DLY(&DLYSTRGRP))
/*            Start groups                                           */
              CALL       PGM(HSTRCST2) PARM(&STRAPY &STSMSGQ &STSMSGQL)
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
