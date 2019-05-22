/* ================================================================= */
/* Object:         HLSTTRG2        *PGM CLP                          */
/*                 Removes or restores triggers for files in the     */
/*                 specified HLSTTRG file                            */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020711 FK  Initial delivery                                     */
/* 20030414 FK  Trigger update condition invalid for Ins/Dlt trigger */
/* 20031107 FK  Wrong value for Allow Repeated Change                */
/* 20061110 FK  Allow change of triggers                             */
/*              Indicate actual number of triggers                   */
/* 20080208 FK  Allow change of trigger to value in file             */
/* ================================================================= */
             PGM        PARM(&UTLLIB &ACTION &TRGFILEQ &STATE &LIB +
                          &NBRFIL &NBRTRG)

/*           Declare parameter variables                             */
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&TRGFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&STATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBRFIL) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRTRG) TYPE(*DEC) LEN(7 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&TRGFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRGFILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&TRFILESV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRLIBSV) TYPE(*CHAR) LEN(10)

             DCL        VAR(&TRTRTM@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRTREV@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRTRCN@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRTARC@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRTTSF@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRTMJA@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRNAM@) TYPE(*CHAR) LEN(258)

             DCL        VAR(&STATE@) TYPE(*CHAR) LEN(10)

             DCL        VAR(&LEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MSGID) TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGDTA) TYPE(*CHAR) LEN(255)
             DCL        VAR(&NBRMSGTRG) TYPE(*DEC) LEN(5 0)

/*           Declare file                                            */
             DCLF       FILE(HLSTTRG) ALWVARLEN(*YES)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRFIL) VALUE(0)
             CHGVAR     VAR(&NBRTRG) VALUE(0)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&TRGFILE) VALUE(%SST(&TRGFILEQ 1 10))
             CHGVAR     VAR(&TRGFILEL) VALUE(%SST(&TRGFILEQ 11 10))

/*           Ensure that proper constraints file is used             */
             OVRDBF     FILE(HLSTTRG) TOFILE(&TRGFILEL/&TRGFILE)

 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           If library specified --> Skip non-selected libraries    */
             IF         COND(&LIB *NE '*ALL' *AND &TRLIB *NE &LIB) +
                          THEN(GOTO CMDLBL(LOOP))

/*           Count number of files                                   */
             IF         COND(&TRFILE *NE &TRFILESV *OR &TRLIB *NE +
                          &TRLIBSV) THEN(CHGVAR VAR(&NBRFIL) +
                          VALUE(&NBRFIL + 1))

/*           If action *RMV --> Skip duplicates for file             */
             IF         COND(&ACTION *EQ '*RMV' *AND &TRFILE *EQ +
                          &TRFILESV *AND &TRLIB *EQ &TRLIBSV) +
                          THEN(GOTO CMDLBL(LOOP))

/*           Update save variables                                   */
             CHGVAR     VAR(&TRFILESV) VALUE(&TRFILE)
             CHGVAR     VAR(&TRLIBSV) VALUE(&TRLIB)

/*           Check if file exists                                    */
             CHKOBJ     OBJ(&TRLIB/&TRFILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))

/*           Extract name of constraint                              */
             CHGVAR     VAR(&TRNAM@) VALUE(' ')
             CHGVAR     VAR(&LEN) VALUE(%BIN(&TRNAM 1 2))
             IF         COND(&LEN *NE 0) THEN(CHGVAR VAR(&TRNAM@) +
                          VALUE(%SST(&TRNAM 3 &LEN)))

/*           Remove triggers                                         */
             IF         COND(&ACTION *EQ '*RMV') THEN(DO)
              SNDPGMMSG  MSGID(LTR0001) MSGF(HAUMSG) MSGDTA(&TRFILE +
                          || &TRLIB || &ACTION || '*ALL') +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(LTR0001) MSGF(HAUMSG) MSGDTA(&TRFILE +
                          || &TRLIB || &ACTION || '*ALL') TOPGMQ(*SAME)
              RMVPFTRG   FILE(&TRLIB/&TRFILE)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            If success --> increment number of triggers            */
              CHGVAR     VAR(&NBRTRG) VALUE(&NBRTRG + 1)
             ENDDO

/*           Change trigger status                                   */
             IF         COND(&ACTION *EQ '*CHG') THEN(DO)
              CHGVAR     VAR(&STATE@) VALUE(&STATE)
              IF         COND(&STATE@ *EQ '*FILESTATE' *AND &TRST *EQ +
                          'E') THEN(CHGVAR VAR(&STATE@) +
                          VALUE('*ENABLED'))
              IF         COND(&STATE@ *EQ '*FILESTATE' *AND &TRST *EQ +
                          'D') THEN(CHGVAR VAR(&STATE@) +
                          VALUE('*DISABLED'))
              SNDPGMMSG  MSGID(LTR0001) MSGF(HAUMSG) MSGDTA(&TRFILE +
                          || &TRLIB || &ACTION || &TRNAM@) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(LTR0001) MSGF(HAUMSG) MSGDTA(&TRFILE +
                          || &TRLIB || &ACTION || &TRNAM@) +
                          TOPGMQ(*SAME)
              CHGPFTRG   FILE(&TRLIB/&TRFILE) TRG(&TRNAM@) +
                          TRGLIB(&TRLB) STATE(&STATE@)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            If success --> increment number of triggers            */
              CHGVAR     VAR(&NBRTRG) VALUE(&NBRTRG + 1)
             ENDDO

/*           Restore trigger                                         */
             IF         COND(&ACTION *EQ '*RST') THEN(DO)
/*            Convert value for Trigger Time                         */
              IF         COND(&TRTRTM *EQ 'B') THEN(CHGVAR +
                          VAR(&TRTRTM@) VALUE('*BEFORE'))
              IF         COND(&TRTRTM *EQ 'A') THEN(CHGVAR +
                          VAR(&TRTRTM@) VALUE('*AFTER'))
/*            Convert value for Trigger Event                        */
              IF         COND(&TRTREV *EQ 'I') THEN(CHGVAR +
                          VAR(&TRTREV@) VALUE('*INSERT'))
              IF         COND(&TRTREV *EQ 'D') THEN(CHGVAR +
                          VAR(&TRTREV@) VALUE('*DELETE'))
              IF         COND(&TRTREV *EQ 'U') THEN(CHGVAR +
                          VAR(&TRTREV@) VALUE('*UPDATE'))
/*            Convert value for Trigger Update Condition             */
              IF         COND(&TRTRCN *EQ 'A') THEN(CHGVAR +
                          VAR(&TRTRCN@) VALUE('*ALWAYS'))
              IF         COND(&TRTRCN *EQ 'C') THEN(CHGVAR +
                          VAR(&TRTRCN@) VALUE('*CHANGE'))
              IF         COND(&TRTRCN *EQ ' ') THEN(CHGVAR +
                          VAR(&TRTRCN@) VALUE('*N'))
/*            Convert value for Trigger Allow Repeated Change        */
              IF         COND(&TRTARC *EQ 'Y') THEN(CHGVAR +
                          VAR(&TRTARC@) VALUE('*YES'))
              IF         COND(&TRTARC *EQ 'N') THEN(CHGVAR +
                          VAR(&TRTARC@) VALUE('*NO'))
/*            Convert value for Threadsafe                           */
              IF         COND(&TRTTSF *EQ 'U') THEN(CHGVAR +
                          VAR(&TRTTSF@) VALUE('*UNKNOWN'))
              IF         COND(&TRTTSF *EQ 'Y') THEN(CHGVAR +
                          VAR(&TRTTSF@) VALUE('*YES'))
              IF         COND(&TRTTSF *EQ 'N') THEN(CHGVAR +
                          VAR(&TRTTSF@) VALUE('*NO'))
/*            Convert value for Multithreaded Job Action             */
              IF         COND(&TRTMJA *EQ 'S') THEN(CHGVAR +
                          VAR(&TRTMJA@) VALUE('*SYSVAL'))
              IF         COND(&TRTMJA *EQ 'M') THEN(CHGVAR +
                          VAR(&TRTMJA@) VALUE('*MSG'))
              IF         COND(&TRTMJA *EQ 'N') THEN(CHGVAR +
                          VAR(&TRTMJA@) VALUE('*NORUN'))
              IF         COND(&TRTMJA *EQ 'R') THEN(CHGVAR +
                          VAR(&TRTMJA@) VALUE('*RUN'))
/*            Add trigger                                            */
              ADDPFTRG   FILE(&TRLIB/&TRFILE) TRGTIME(&TRTRTM@) +
                          TRGEVENT(&TRTREV@) PGM(&TRTRLB/&TRTRIG) +
                          RPLTRG(*YES) TRG(&TRNAM@) +
                          ALWREPCHG(&TRTARC@) THDSAFE(&TRTTSF@) +
                          MLTTHDACN(&TRTMJA@) TRGUPDCND(&TRTRCN@)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            If success --> increment number of triggers            */
              CHGVAR     VAR(&NBRTRG) VALUE(&NBRTRG + 1)
             ENDDO

             GOTO       CMDLBL(LOOP)

 ELOOP:      GOTO       CMDLBL(END)

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
