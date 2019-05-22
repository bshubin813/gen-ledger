/* ================================================================= */
/* Object:         HSTRCST1        *PGM CLP                          */
/*                 Starts the current node if not already active,    */
/*                 all other nodes if master node and waits until    */
/*                 all nodes in the cluster are active.              */
/*                                                                   */
/* Create:         CRTCLPGM                                          */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040429 FK  Initial delivery                                     */
/* 20040505 FK  Start remaining nodes if current is master           */
/* 20040519 FK  Respect the MAXWAITNOD paramater                     */
/* 20040524 FK  Also wait for starting nodes                         */
/* 20040920 FK  Indicate if any nodes started                        */
/* 20050209 FK  Do not fail if status message queue is full          */
/* 20050309 FK  Use DMSTRNODE in stead of DMREJOIN if decoupled      */
/* ================================================================= */
             PGM        PARM(&SYSNAM &STSMSGQ &STSMSGQL &NBRATM +
                          &MAXWAITNOD &CURNODACT &P_NODSTR)

/*           Declare parameter variables                              */
             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&STSMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STSMSGQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBRATM) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&MAXWAITNOD) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&CURNODACT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&P_NODSTR) TYPE(*CHAR) LEN(1)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LSTSTS) TYPE(*CHAR) LEN(10)

             DCL        VAR(&MASTER) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CURWAIT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MAXITV) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MAXWAITN@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&NODSTRTNG) TYPE(*LGL)

             DCL        VAR(&LSNACT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NODSTR) TYPE(*LGL)
             DCL        VAR(&CSTSRV) TYPE(*CHAR) LEN(1)

/*           Declare files                                            */
             DCLF       FILE(HINODNN)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&CURNODACT) VALUE('0')
             CHGVAR     VAR(&P_NODSTR) VALUE('0')

/*           Use OS/400 cluster services?                            */
             RTVDTAARA  DTAARA(DM_SYSVALS (199 1)) RTNVAR(&CSTSRV)
             IF         COND(&CSTSRV *NE 'N') THEN(CHGVAR +
                          VAR(&CSTSRV) VALUE('Y'))

/*           First check status of current node                      */
             HRTVNODSTS NODE(&SYSNAM) STATUS(&STATUS) LSTSTS(&LSTSTS)

/*           Node should not be started if previous error            */
             IF         COND(&STATUS *EQ '*UNKNOWN' *AND (&LSTSTS +
                          *EQ '*RMV_PEND' *OR &LSTSTS *EQ '*FAILED' +
                          *OR &LSTSTS *EQ '*PARTITION')) THEN(DO)
              SNDPGMMSG  MSGID(SCS0010) MSGF(HAUMSG) MSGDTA(&NODE || +
                          &STATUS || &LSTSTS) MSGTYPE(*DIAG)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0010) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ) MSGTYPE(*DIAG)
               MONMSG     MSGID(CPF0000)
              ENDDO
              GOTO       CMDLBL(END)
             ENDDO

/*           Node should not be started if currently invalid         */
             IF         COND(&STATUS *EQ '*RMV_PEND' *OR &STATUS *EQ +
                          '*FAILED' *OR &STATUS *EQ '*PARTITION' +
                          *OR STATUS *EQ '*INACT_PND') THEN(DO)
              SNDPGMMSG  MSGID(SCS0010) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS) MSGTYPE(*DIAG)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0010) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ) MSGTYPE(*DIAG)
               MONMSG     MSGID(CPF0000)
              ENDDO
              GOTO       CMDLBL(END)
             ENDDO

/*           Start current node, if necessary                        */
             IF         COND(&STATUS *NE '*ACTIVE' *AND &STATUS *NE +
                          '*ACT_PEND') THEN(DO)
              SNDPGMMSG  MSGID(SCS0012) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0012) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
               MONMSG     MSGID(CPF0000)
              ENDDO
              IF         COND(&CSTSRV *EQ 'N') THEN(DMSTRNODE +
                          NODE(&SYSNAM))
              IF         COND(&CSTSRV *EQ 'Y') THEN(DMREJOIN +
                          NUMTRIES(&NBRATM) STARTNEW(*YES))
              CHGVAR     VAR(&P_NODSTR) VALUE('1')
             ENDDO

/*           Re-retrieve status of node                              */
             HRTVNODSTS NODE(&SYSNAM) STATUS(&STATUS) LSTSTS(&LSTSTS)

/*           Wait until the current node is active (max. MAXWAITNOD) */
             IF         COND(&STATUS *NE '*ACTIVE') THEN(DO)
              CHGVAR     VAR(&CURWAIT) VALUE(1)
              CHGVAR     VAR(&MAXITV) VALUE(&MAXWAITNOD * 4)
 WAITCUR:     IF         COND(&STATUS *NE '*ACTIVE' *AND &CURWAIT *LE +
                          &MAXITV) THEN(DO)
/*             Send message in job log to indicate wait              */
               SNDPGMMSG  MSGID(SCS0013) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS) TOPGMQ(*SAME)
/*             Wait for specified number of minutes                  */
               DLYJOB     DLY(15)
/*             Retrieve status again                                 */
               HRTVNODSTS NODE(&SYSNAM) STATUS(&STATUS) LSTSTS(&LSTSTS)
               CHGVAR     VAR(&CURWAIT) VALUE(&CURWAIT + 1)
               GOTO       CMDLBL(WAITCUR)
              ENDDO
             ENDDO

/*           If node still not active --> end                        */
             IF         COND(&STATUS *NE '*ACTIVE') THEN(DO)
              CHGVAR     VAR(%BIN(&MAXWAITN@)) VALUE(&MAXWAITNOD)
              SNDPGMMSG  MSGID(SCS0014) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS || &MAXWAITN@) +
                          MSGTYPE(*DIAG)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0014) MSGF(HAUMSG) MSGDTA(&SYSNAM +
                          || &STATUS || &LSTSTS || &MAXWAITN@) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ) MSGTYPE(*DIAG)
               MONMSG     MSGID(CPF0000)
              ENDDO
              GOTO       CMDLBL(END)
             ENDDO

/*           If program gets here, current node is active            */
             CHGVAR     VAR(&CURNODACT) VALUE('1')

/*           Determine the master node                               */
             CALL       PGM(MASTERNODE) PARM(&MASTER)

/*           If master node, start all other nodes in cluster        */
             IF         COND(&MASTER *EQ &SYSNAM) THEN(DO)
              CHGVAR     VAR(&NODSTR) VALUE('0')
/*            Create LF to nodes file                                */
              CALL       PGM(HCRTLF) PARM('HINODNN')
              OVRDBF     FILE(HINODNN) TOFILE(QTEMP/HINODNN)
/*            Start all other nodes in the cluster                   */
 LOOPNODE:    RCVF
              MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOPNODE))
/*            Skip current node                                      */
              IF         COND(&NODE *EQ &SYSNAM) THEN(GOTO +
                          CMDLBL(LOOPNODE))
              HRTVNODSTS NODE(&NODE) STATUS(&STATUS) LSTSTS(&LSTSTS) +
                          LSNACT(&LSNACT)
/*            Node should not be started if currently invalid        */
              IF         COND(&STATUS *EQ '*RMV_PEND' *OR &STATUS *EQ +
                          '*FAILED' *OR &STATUS *EQ '*PARTITION' +
                          *OR STATUS *EQ '*INACT_PND') THEN(DO)
               SNDPGMMSG  MSGID(SCS0011) MSGF(HAUMSG) MSGDTA(&NODE || +
                          &STATUS || &LSTSTS) MSGTYPE(*DIAG)
               IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
                SNDPGMMSG  MSGID(SCS0011) MSGF(HAUMSG) MSGDTA(&NODE || +
                          &STATUS || &LSTSTS) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ) MSGTYPE(*DIAG)
                MONMSG     MSGID(CPF0000)
               ENDDO
               GOTO       CMDLBL(LOOPNODE)
              ENDDO
/*            If inactive --> only start if listener active           */
              IF         COND(&STATUS *NE '*ACTIVE' *AND &STATUS *NE +
                          '*ACT_PEND' *AND &STATUS *NE '*PENDING') +
                          THEN(DO)
               IF         COND(&LSNACT *EQ '*NO') THEN(SNDPGMMSG +
                          MSGID(SCS0022) MSGF(HAUMSG) MSGDTA(&NODE +
                          || &LOCNAME))
               IF         COND(&LSNACT *EQ '*YES') THEN(DO)
                SNDPGMMSG  MSGID(SCS0015) MSGF(HAUMSG) MSGDTA(&NODE || +
                          &STATUS || &LSTSTS)
                IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
                 SNDPGMMSG  MSGID(SCS0015) MSGF(HAUMSG) MSGDTA(&NODE || +
                          &STATUS || &LSTSTS) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
                 MONMSG     MSGID(CPF0000)
                ENDDO
                DMSTRNODE  NODE(&NODE)
                CHGVAR     VAR(&NODSTR) VALUE('1')
                CHGVAR     VAR(&P_NODSTR) VALUE('1')
               ENDDO
              ENDDO
              GOTO       CMDLBL(LOOPNODE)
/*            If any nodes started --> wait until active              */
 ELOOPNODE:   IF         COND(&NODSTR) THEN(DO)
/*             Send message in job log to indicate wait               */
               CHGVAR     VAR(%BIN(&MAXWAITN@)) VALUE(&MAXWAITNOD)
               SNDPGMMSG  MSGID(SCS0021) MSGF(HAUMSG) +
                          MSGDTA(&MAXWAITN@) TOPGMQ(*SAME)
               CHGVAR     VAR(&CURWAIT) VALUE(1)
               CHGVAR     VAR(&MAXITV) VALUE(&MAXWAITNOD * 4)
               CHGVAR     VAR(&NODSTRTNG) VALUE('1')
 LOOPSLAVE:    IF         COND(&NODSTRTNG *AND &CURWAIT *LE &MAXITV) +
                          THEN(DO)
                DLYJOB     DLY(10)
                CALL       PGM(HSTRCST1A) PARM(&NODSTRTNG)
                CHGVAR     VAR(&CURWAIT) VALUE(&CURWAIT + 1)
                GOTO       CMDLBL(LOOPSLAVE)
               ENDDO
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
