/* ================================================================= */
/* Object:         HMONHA          *PGM CLP                          */
/*                 Monitor HA Suite/iCluster.                        */
/*                                                                   */
/* Synopsis:       See command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20041216 FK  Initial delivery (copy from HMONEVL)                 */
/* 20041220 FK  Add SUSTIM parameter                                 */
/* 20050105 FK  Log event log date-time from last entry initially    */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20060403 FK  Monitor for group status                             */
/* 20070724 FK  Only groups for first node were monitored            */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&CTLSYS &CTLHOST &EVTLOG &SUSOBJ +
                          &GRPSTS &CLNEVTLOG &CHKITV &SUSTIM +
                          &GRPTIM &PORT)

/*           Declare parameter variables                             */
             DCL        VAR(&CTLSYS) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CTLHOST) TYPE(*CHAR) LEN(100)
             DCL        VAR(&EVTLOG) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SUSOBJ) TYPE(*CHAR) LEN(4)
             DCL        VAR(&GRPSTS) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CLNEVTLOG) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKITV) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&SUSTIM) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&GRPTIM) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&PORT) TYPE(*CHAR) LEN(30)

/*           Environment-specific variables                          */

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&CHKITV@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKITVS) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&STSKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MSGKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENDSTS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&QDATE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&ISODATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&QTIME) TYPE(*CHAR) LEN(6)
             DCL        VAR(&CURDTS) TYPE(*CHAR) LEN(19)

             DCL        VAR(&EVTDTS) TYPE(*CHAR) LEN(19)
             DCL        VAR(&SUSDTS) TYPE(*CHAR) LEN(19)
             DCL        VAR(&CLNDAT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GRPDTS) TYPE(*CHAR) LEN(19)

             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&TYPE)
             CHGVAR     VAR(%BIN(&CHKITV@)) VALUE(&CHKITV)
             CHGVAR     VAR(&CHKITVS) VALUE(&CHKITV * 60)

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)
/*           iCluster must be in the library list                    */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0014) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

             HRTVNETA   SYSNAME(&SYSNAME)

/*           Utilities library must be in library list for SBMJOB    */
             ADDLIBLE   LIB(&UTLLIB)
             MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))

/*           If executed interactively --> submit to batch           */
             IF         COND(&TYPE *EQ '1') THEN(DO)
              SBMJOB     CMD(HMONHA CTLSYS(&CTLSYS) CTLHOST(&CTLHOST) +
                          EVTLOG(&EVTLOG) SUSOBJ(&SUSOBJ) +
                          GRPSTS(&GRPSTS) CLNEVTLOG(&CLNEVTLOG) +
                          CHKITV(&CHKITV) SUSTIM(&SUSTIM) +
                          GRPTIM(&GRPTIM) PORT(&PORT)) JOBD(HMONHA) +
                          USER(*JOBD) INLLIBL(*JOBD)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Replace special value for CTLSYS / CTLHOST              */
             IF         COND(&CTLSYS *EQ '*CURRENT') THEN(CHGVAR +
                          VAR(&CTLSYS) VALUE(&SYSNAME))
             IF         COND(&CTLHOST *EQ '*CTLSYS') THEN(CHGVAR +
                          VAR(&CTLHOST) VALUE(&CTLSYS))

/*           Determine iCluster product lib and add to libl          */
             IF         COND(&ICLIB *NE '*NONE') THEN(DO)
              CHGVAR     VAR(&PRD) VALUE('*iC')
              ADDLIBLE   LIB(&ICLIB)
              MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))
             ENDDO

/*           If current system controlling --> submit listener       */
             IF         COND(&CTLSYS *EQ &SYSNAME) THEN(DO)
              SBMJOB     CMD(CALL PGM(HMONHAL) PARM(&PRD &PORT)) +
                          JOB(HMONHAL) JOBD(HMONHA) INLLIBL(*JOBD)
             ENDDO

/*           Check existence of HMONHA data area (pointers)          */
             CHKOBJ     OBJ(&UTLLIB/HMONHA) OBJTYPE(*DTAARA)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDTAARA  DTAARA(&UTLLIB/HMONHA) TYPE(*CHAR) LEN(1000) +
                          TEXT('HA/iC Monitor --> Starting positions')
              CHGDTAARA  DTAARA(&UTLLIB/HMONHA (1 5)) VALUE('*EVT:')
              CHGDTAARA  DTAARA(&UTLLIB/HMONHA (51 5)) VALUE('*SUS:')
              CHGDTAARA  DTAARA(&UTLLIB/HMONHA (101 5)) VALUE('*CLN:')
              CHGDTAARA  DTAARA(&UTLLIB/HMONHA (107 10)) VALUE(' ')
              CHGDTAARA  DTAARA(&UTLLIB/HMONHA (151 5)) VALUE('*GRP:')
              SNDPGMMSG  MSGID(MHA0004) MSGF(HAUMSG) TOPGMQ(*SAME)
             ENDDO

/*           Ensure that the monitor only runs once                  */
             ALCOBJ     OBJ((&UTLLIB/HMONHA *DTAARA *EXCLRD)) WAIT(1)
             MONMSG     MSGID(CPF0000) EXEC(DO)
              SNDPGMMSG  MSGID(MHA0005) MSGF(HAUMSG) MSGTYPE(*DIAG)
              GOTO       CMDLBL(END)
             ENDDO
/*           If lock could be obtained, replace by *SHRNUP          */
             ALCOBJ     OBJ((&UTLLIB/HMONHA *DTAARA *SHRNUP))
             DLCOBJ     OBJ((&UTLLIB/HMONHA *DTAARA *EXCLRD))

/*           Create assisting files in QTEMP                         */
             IF         COND(&EVTLOG *EQ '*YES') THEN(DO)
              CALL       PGM(HCRTLF) PARM(HUEVNL0)
              OVRDBF     FILE(HUEVNL0) TOFILE(QTEMP/HUEVNL0)
             ENDDO
             IF         COND(&SUSOBJ *EQ '*YES') THEN(DO)
              CALL       PGM(HCRTLF) PARM(HUMOBSO)
              CALL       PGM(HCRTLF) PARM(HUSOBSO)
              CALL       PGM(HCRTLF) PARM(HUTMOBSO)
              CALL       PGM(HCRTLF) PARM(HUBTIDSO)
              CALL       PGM(HCRTLF) PARM(HUTGTTI)
              CALL       PGM(HCRTLF) PARM(HUGRPGI)
              OVRDBF     FILE(HUMOBSO) TOFILE(QTEMP/HUMOBSO)
              OVRDBF     FILE(HUTMOBSO) TOFILE(QTEMP/HUTMOBSO)
              OVRDBF     FILE(HUBTIDSO) TOFILE(QTEMP/HUBTIDSO)
              OVRDBF     FILE(HUTGTTI) TOFILE(QTEMP/HUTGTTI)
              OVRDBF     FILE(HUGRPGI) TOFILE(QTEMP/HUGRPGI)
              OVRDBF     FILE(HUSOBSO) TOFILE(QTEMP/HUSOBSO)
             ENDDO
             IF         COND(&GRPSTS *EQ '*YES') THEN(DO)
              IF         COND(&PRD *EQ '*iC') THEN(HLSTCFG +
                          ICGROUP(*ALL) BCKNOD(*ALL))
              OVRDBF     FILE(HLSTCFGG) TOFILE(QTEMP/HLSTCFGG)
              CRTDUPOBJ  OBJ(HMONHAG) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(QTEMP) DATA(*NO)
              OVRDBF     FILE(HMONHAG) TOFILE(QTEMP/HMONHAG)
             ENDDO

/*           First time, wait for specified interval                 */
             GOTO       CMDLBL(WAITLOOP)

/*           Loop until job ended                                    */
/*           Retrieve current date                                   */
 LOOP:       RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&QDATE)
             RTVSYSVAL  SYSVAL(QTIME) RTNVAR(&QTIME)
             CVTDAT     DATE(&QDATE) TOVAR(&ISODATE) TOFMT(*ISO)
             CHGVAR     VAR(&CURDTS) VALUE(&ISODATE || '-' || +
                          %SST(&QTIME 1 2) || '.' || %SST(&QTIME 3 +
                          2) || '.' || %SST(&QTIME 5 2))

/*           Process new event log entries                           */
             IF         COND(&EVTLOG *EQ '*YES') THEN(DO)
              RTVDTAARA  DTAARA(HMONHA (7 19)) RTNVAR(&EVTDTS)
              CALL       PGM(HMONHA1) PARM(&CTLSYS &CTLHOST &SYSNAME +
                          &PORT '*EVT' &EVTDTS &SUSTIM &GRPTIM &RTNCDE)
/*            Record next start date-time if successful              */
              IF         COND(&RTNCDE *EQ ' ') THEN(DO)
               CHGDTAARA  DTAARA(&UTLLIB/HMONHA (7 19)) VALUE(&EVTDTS)
               MONMSG     MSGID(CPF1063)
              ENDDO
             ENDDO

/*           Process new suspended objects                           */
             IF         COND(&SUSOBJ *EQ '*YES') THEN(DO)
              RTVDTAARA  DTAARA(HMONHA (57 19)) RTNVAR(&SUSDTS)
              IF         COND(&SUSDTS *EQ ' ') THEN(CHGVAR +
                          VAR(&SUSDTS) VALUE(&CURDTS))
              CALL       PGM(HMONHA1) PARM(&CTLSYS &CTLHOST &SYSNAME +
                          &PORT '*SUS' &SUSDTS &SUSTIM &GRPTIM &RTNCDE)
/*            Record next start date-time if successful              */
              IF         COND(&RTNCDE *EQ ' ') THEN(DO)
               CHGDTAARA  DTAARA(&UTLLIB/HMONHA (57 19)) VALUE(&SUSDTS)
               MONMSG     MSGID(CPF1063)
              ENDDO
             ENDDO

/*           Process new event log entries                           */
             IF         COND(&GRPSTS *EQ '*YES') THEN(DO)
              RTVDTAARA  DTAARA(HMONHA (157 19)) RTNVAR(&GRPDTS)
              CALL       PGM(HMONHA1) PARM(&CTLSYS &CTLHOST &SYSNAME +
                          &PORT '*GRP' &GRPDTS &SUSTIM &GRPTIM &RTNCDE)
/*            Record next start date-time if successful              */
              IF         COND(&RTNCDE *EQ ' ') THEN(DO)
               CHGDTAARA  DTAARA(&UTLLIB/HMONHA (157 19)) VALUE(&GRPDTS)
               MONMSG     MSGID(CPF1063)
              ENDDO
             ENDDO

/*           Must source- and target event logs be cleaned?          */
             IF         COND(&CLNEVTLOG *EQ '*YES') THEN(DO)
              RTVDTAARA  DTAARA(HMONHA (107 10)) RTNVAR(&CLNDAT)
              IF         COND(&ISODATE *NE &CLNDAT) THEN(CALL +
                          PGM(HMONHA2))
              CHGDTAARA  DTAARA(HMONHA (107 10)) VALUE(&ISODATE)
              MONMSG     MSGID(CPF1063)
             ENDDO

/*           Wait for next interval or when job ended                */
 WAITLOOP:   SNDPGMMSG  MSGID(MHA0003) MSGF(HAUMSG) MSGDTA(&CHKITV@) +
                          KEYVAR(&STSKEY)
             RCVMSG     MSGTYPE(*NEXT) MSGKEY(&STSKEY) +
                          WAIT(&CHKITVS) KEYVAR(&MSGKEY)
/*           If message received, first wait 1 second                */
             DLYJOB     DLY(1)
/*           Remove status message to not confuse operator           */
             RMVMSG     MSGKEY(&STSKEY)
             MONMSG     MSGID(CPF0000)
/*           If job/subsystem or system ended --> quit, else loop    */
             RTVJOBA    ENDSTS(&ENDSTS)
             IF         COND(&ENDSTS *EQ '0') THEN(GOTO CMDLBL(LOOP))

/*           If controlling system --> end listener job              */
             IF         COND(&CTLSYS *EQ &SYSNAME) THEN(DO)
/*            Send end request                                       */
              CALL       PGM(HMONHA1) PARM(&CTLSYS &CTLHOST &SYSNAME +
                          &PORT '*END' ' ' &SUSTIM &GRPTIM &RTNCDE)
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
