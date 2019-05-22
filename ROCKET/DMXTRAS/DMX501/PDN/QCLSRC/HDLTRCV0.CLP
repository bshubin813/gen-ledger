/* ================================================================= */
/* Object:         HDLTRCV0        *PGM CLP                          */
/*                 Processes list of journals to perform deletion    */
/*                 upon.                                             */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20001217 FK  Initial delivery                                     */
/* 20010822 FK  Skip journal if not in specified library             */
/* 20020116 FK  Add support for RJP journal                          */
/* 20020222 FK  Allow processing all or generic journals             */
/* 20020424 FK  Use HADGT and HAPID to determine journals, possible  */
/* 20020515 FK  Add support for iCluster                             */
/* 20030612 FK  Remote journal support (use of API)                  */
/* 20030710 FK  Use HDLTRCV* files in QTEMP                          */
/* 20030714 FK  Maximum number of receivers is 255                   */
/* 20040526 FK  Include HADSAVJRN for processing of journals         */
/* 20050510 FK  Remove CHKRJP parameter                              */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20070108 FK  Allow instrumental mode                              */
/* 20070112 FK  Allow checking of multiple TS libraries              */
/* 20070507 FK  Use HLSTJRN command to list journals & receivers     */
/* 20111220 FK  Remove HA/CDC                                        */
/* ================================================================= */
             PGM        PARM(&JRNQ &DAYS &KEEPRCV &DLTUNSRCV &CHKIC +
                          &MAXRCVJRN &MAXSIZ &ALRMSGQQ &LOGDLT +
                          &RPYSEQ &RCVEXITQ &POSEXITQ &DLTRCV)

/*           Declare parameter variables                             */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DAYS) TYPE(*DEC) LEN(3)
             DCL        VAR(&KEEPRCV) TYPE(*DEC) LEN(3)
             DCL        VAR(&DLTUNSRCV) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKIC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MAXRCVJRN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MAXSIZ) TYPE(*DEC) LEN(6 0)
             DCL        VAR(&ALRMSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RPYSEQ) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&LOGDLT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RCVEXITQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&POSEXITQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DLTRCV) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ALRMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ALRMSGQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVEXIT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVEXITL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&POSEXIT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&POSEXITL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&INQMSGRPY) TYPE(*CHAR) LEN(10)

             DCL        VAR(&NBRDLT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRDLT@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RMNNBR) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&RMNNBR@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RMNSIZ) TYPE(*DEC) LEN(12 0)
             DCL        VAR(&SIZDLT) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&SIZDLT@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&MAXRCVJRN@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MAXSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MAXSIZKB) TYPE(*DEC) LEN(15 0)
             DCL        VAR(&RMNSIZTOT) TYPE(*DEC) LEN(15 0)
             DCL        VAR(&RMNSIZTOT@) TYPE(*CHAR) LEN(15)
             DCL        VAR(&LJNBRRCV@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */
             DCLF       FILE(HLSTJRN)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))
             CHGVAR     VAR(&ALRMSGQ) VALUE(%SST(&ALRMSGQQ 1 10))
             CHGVAR     VAR(&ALRMSGQL) VALUE(%SST(&ALRMSGQQ 11 10))
             CHGVAR     VAR(&RCVEXIT) VALUE(%SST(&RCVEXITQ 1 10))
             CHGVAR     VAR(&RCVEXITL) VALUE(%SST(&RCVEXITQ 11 10))
             CHGVAR     VAR(&POSEXIT) VALUE(%SST(&POSEXITQ 1 10))
             CHGVAR     VAR(&POSEXITL) VALUE(%SST(&POSEXITQ 11 10))
             CHGVAR     VAR(%BIN(&MAXRCVJRN@)) VALUE(&MAXRCVJRN)
             CHGVAR     VAR(%BIN(&MAXSIZ@)) VALUE(&MAXSIZ)
             CHGVAR     VAR(&MAXSIZKB) VALUE(&MAXSIZ * 1024)

/*           Initialisation                                          */
             RTVJOBA    INQMSGRPY(&INQMSGRPY)

/*           Change the job so that it will autoreply to CPA7025     */
             IF         COND(&DLTUNSRCV *EQ '*YES') THEN(DO)
              CHGJOB     INQMSGRPY(*SYSRPYL)
             ENDDO

/*           Retrieve utilities library                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Initialise                                              */
             CHGVAR     VAR(&RMNSIZTOT) VALUE(0)

/*           Generate list of journals & receivers                   */
             HLSTJRN    JRN(&JRNL/&JRN) CHKIC(&CHKIC) LSTRCV(*YES) +
                          OUTFILE(HDLTJRN)

/*           Make sure that proper HDLTJRN* files are used           */
             OVRDBF     FILE(HLSTJRN) TOFILE(QTEMP/HDLTJRN)
             OVRDBF     FILE(HLSTJRNR) TOFILE(QTEMP/HDLTJRNR)

/*           Now, process all journals generated                     */
 LOOPJRN:    RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOPJRN))

/*           If number of receivers > 500, send warning              */
             IF         COND(&LJNBRRCV *GT 500) THEN(DO)
              CHGVAR     VAR(%BIN(&LJNBRRCV@)) VALUE(&LJNBRRCV)
              SNDPGMMSG  MSGID(DJR0032) MSGF(HAUMSG) MSGDTA(&LJJRN || +
                          &LJJRNL || &LJNBRRCV@) TOPGMQ(*PRV +
                          (HDLTJRNRCV)) MSGTYPE(*DIAG)
              SNDPGMMSG  MSGID(DJR0032) MSGF(HAUMSG) MSGDTA(&LJJRN || +
                          &LJJRNL || &LJNBRRCV@) +
                          TOMSGQ(&ALRMSGQL/&ALRMSGQ) MSGTYPE(*DIAG)
             ENDDO

/*           Indicate which journal is processed                     */
             SNDPGMMSG  MSGID(DJR0007) MSGF(HAUMSG) MSGDTA(&LJJRN || +
                          &LJJRNL) TOPGMQ(*EXT) MSGTYPE(*STATUS)
             SNDPGMMSG  MSGID(DJR0007) MSGF(HAUMSG) MSGDTA(&LJJRN || +
                          &LJJRNL) TOPGMQ(*SAME) MSGTYPE(*INFO)

/*           Delete the receivers that have been listed              */
             CALL       PGM(HDLTRCV2) PARM(&LJJRN &LJJRNL &DAYS +
                          &KEEPRCV &LJNBRRCV &DLTUNSRCV &RPYSEQ +
                          &LOGDLT &CHKIC &NBRDLT &RMNNBR &SIZDLT +
                          &RMNSIZ &ALRMSGQQ &RCVEXITQ &POSEXITQ +
                          &DLTRCV)

/*           Update total size of remaining receivers                */
             CHGVAR     VAR(&RMNSIZTOT) VALUE(&RMNSIZTOT + &RMNSIZ)

/*           If remaining number exceeds maximum --> alert           */
             IF         COND(&MAXRCVJRN *NE 0 *AND &RMNNBR *GT +
                          &MAXRCVJRN) THEN(DO)
              CHGVAR     VAR(%BIN(&RMNNBR@)) VALUE(&RMNNBR)
              SNDPGMMSG  MSGID(DJR0015) MSGF(HAUMSG) MSGDTA(&LJJRN || +
                          &LJJRNL || &RMNNBR@ || &MAXRCVJRN@) +
                          TOPGMQ(*PRV (HDLTJRNRCV)) MSGTYPE(*DIAG)
              SNDPGMMSG  MSGID(DJR0015) MSGF(HAUMSG) MSGDTA(&LJJRN || +
                          &LJJRNL || &RMNNBR@ || &MAXRCVJRN@) +
                          TOMSGQ(&ALRMSGQL/&ALRMSGQ) MSGTYPE(*DIAG)
             ENDDO

/*           Send completion message how many receivers were deleted */
             CHGVAR     VAR(%BIN(&NBRDLT@)) VALUE(&NBRDLT)
             CHGVAR     VAR(%BIN(&RMNNBR@)) VALUE(&RMNNBR)
             CHGVAR     VAR(%BIN(&SIZDLT@)) VALUE(&SIZDLT)
             IF         COND(&DLTRCV *EQ '*YES') THEN(SNDPGMMSG +
                          MSGID(DJR0003) MSGF(HAUMSG) +
                          MSGDTA(&NBRDLT@ || &LJJRN || &LJJRNL || +
                          &RMNNBR@ || &SIZDLT@) TOPGMQ(*PRV +
                          (HDLTJRNRCV)) MSGTYPE(*COMP))
             IF         COND(&DLTRCV *EQ '*NO') THEN(SNDPGMMSG +
                          MSGID(DJR0041) MSGF(HAUMSG) +
                          MSGDTA(&NBRDLT@ || &LJJRN || &LJJRNL || +
                          &RMNNBR@ || &SIZDLT@) TOPGMQ(*PRV +
                          (HDLTJRNRCV)) MSGTYPE(*COMP))

             GOTO       CMDLBL(LOOPJRN)

/*           Unsaved receivers deleted --> change back job status    */
 ELOOPJRN:   IF         COND(&DLTUNSRCV *EQ '*YES') THEN(CHGJOB +
                          INQMSGRPY(&INQMSGRPY))

/*           Check if total size of receivers does not exceed limit  */
             IF         COND(&MAXSIZ *NE 0) THEN(DO)
              CHGVAR     VAR(&RMNSIZTOT@) VALUE(&RMNSIZTOT)
              IF         COND(&RMNSIZTOT > &MAXSIZKB) THEN(DO)
               SNDPGMMSG  MSGID(DJR0016) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RMNSIZTOT@ || &MAXSIZ@) +
                          TOPGMQ(*PRV (HDLTJRNRCV)) MSGTYPE(*DIAG)
               SNDPGMMSG  MSGID(DJR0016) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RMNSIZTOT@ || &MAXSIZ@) +
                          TOMSGQ(&ALRMSGQL/&ALRMSGQ) MSGTYPE(*DIAG)
              ENDDO
             ENDDO

/*           Delete override for next activities                     */
             DLTOVR     FILE(HLSTJRN)
/*           MONMSG     MSGID(CPF9841) EXEC(RCVMSG MSGTYPE(*LAST)) */
             DLTOVR     FILE(HLSTJRNR)
/*           MONMSG     MSGID(CPF9841) EXEC(RCVMSG MSGTYPE(*LAST)) */

/*           Make sure that all resources are reclaimed              */
             RCLRSC     LVL(*CALLER)

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
