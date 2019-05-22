/*CP: LOG(*NO)                                                       */
/* ================================================================= */
/* Object:         HAPYJSE         *PGM CLP                          */
/*                 Command processing program for HAPYJSE.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990809 FK  Initial delivery                                     */
/* 19991017 FK  Allow expired entries to be skipped                  */
/* 19991028 FK  Sets library list before adding job schedule entry   */
/* 19991101 FK  Expire entry less often                              */
/* 19991203 FK  Check for apopstrophes in TEXT variable              */
/* 20010504 FK  Remove messages for changing library list            */
/* 20010907 FK  Do not change job description value if *USRPRF       */
/* 20031209 FK  No logging of CL commands                            */
/* ================================================================= */
             PGM        PARM(&USRSPC &JSEID &HOLD &SKPEXP)

/*           Parameter variables                                     */
             DCL        VAR(&USRSPC) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JSEID) TYPE(*CHAR) LEN(10)
             DCL        VAR(&HOLD) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SKPEXP) TYPE(*CHAR) LEN(4)

/*           Program variables                                       */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)

             DCL        VAR(&LSTHDR) TYPE(*CHAR) LEN(140)
             DCL        VAR(&I) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&STRLST) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRENT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&STRPOS@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LSTENT) TYPE(*CHAR) LEN(1157)

             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SCDDATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SCDDAY) TYPE(*CHAR) LEN(70)
             DCL        VAR(&SCDTIME) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FRQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RELDAYMON) TYPE(*CHAR) LEN(50)
             DCL        VAR(&RCYACN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NXTDATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TEXT) TYPE(*CHAR) LEN(75)
             DCL        VAR(&JOBD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBDL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBCMD) TYPE(*CHAR) LEN(512)

             DCL        VAR(&SKPENT) TYPE(*LGL)
             DCL        VAR(&HLDENT) TYPE(*LGL)
             DCL        VAR(&SCDDATTIM) TYPE(*CHAR) LEN(16)
             DCL        VAR(&NXTDATTIM) TYPE(*CHAR) LEN(16)
             DCL        VAR(&CURDATTIM) TYPE(*CHAR) LEN(16)
             DCL        VAR(&QDATE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&SCDDATE@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURDATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OMTDATE) TYPE(*CHAR) LEN(10)

             DCL        VAR(&RJOBD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RJOBDL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RJOBDQ) TYPE(*CHAR) LEN(20)

             DCL        VAR(&JOBDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JOBD0100) TYPE(*CHAR) LEN(1024)
             DCL        VAR(&OFSILL) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRILL) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&LIBLLEN) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&INLLIBL) TYPE(*CHAR) LEN(275)
             DCL        VAR(&QUSRLIBL) TYPE(*CHAR) LEN(250)

             DCL        VAR(&SAVLIBL) TYPE(*CHAR) LEN(275)
             DCL        VAR(&PRDLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(4096)
             DCL        VAR(&MSGDTA) TYPE(*CHAR) LEN(256)
             DCL        VAR(&ENTRYNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&J) TYPE(*DEC) LEN(5 0)

             DCL        VAR(&NBROK) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRERR) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRHLD) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRSKP) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBREXP) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBROK@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRERR@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRHLD@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRSKP@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBREXP@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&PRSTXT) TYPE(*CHAR) LEN(2500)

/* ----------------------------------------------------------------- */
/*           Global monitoring (if any)                              */
/* ----------------------------------------------------------------- */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVOBJD    OBJ(HAPYJSE) OBJTYPE(*PGM) RTNLIB(&PRDLIB)

/*           Retrieve current date and convert to CYYMMDD format     */
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&QDATE)
             CVTDAT     DATE(&QDATE) TOVAR(&CURDATE) TOFMT(*CYMD) +
                          TOSEP(*NONE)

/*           Determine identification if *USRSPC                     */
             IF         COND(&JSEID *EQ '*USRSPC') THEN(CHGVAR VAR(&JSEID) +
                          VALUE(%SST(&USRSPC 1 10)))

/*           Retrieve user space header information                  */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QUSRTVUS) PARM(&USRSPC X'00000001' +
                          X'0000008C' &LSTHDR &APIERR)
             CHGVAR     VAR(&STRLST) VALUE(%BIN(&LSTHDR 125 4) + 1)
             CHGVAR     VAR(&NBRENT) VALUE(%BIN(&LSTHDR 133 4))
             CHGVAR     VAR(&ENTSIZ) VALUE(%BIN(&LSTHDR 137 4))
             CHGVAR     VAR(&ENTSIZ@) VALUE(%SST(&LSTHDR 137 4))

/*           Read entries until end reached                          */
             CHGVAR     VAR(&I) VALUE(1)
 LOOP:       IF         COND(&I *LE &NBRENT) THEN(DO)
/*            Initialise loop                                        */
              CHGVAR     VAR(&SKPENT) VALUE('0')
              CHGVAR     VAR(&HLDENT) VALUE('0')
              CHGVAR     VAR(&OMTDATE) VALUE('*NONE')
/*            Retrieve entry                                         */
              CHGVAR     VAR(&STRPOS) VALUE(&STRLST + ((&I - 1) * +
                          &ENTSIZ))
              CHGVAR     VAR(%BIN(&STRPOS@)) VALUE(&STRPOS)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&USRSPC &STRPOS@ &ENTSIZ@ +
                          &LSTENT &APIERR)

/*            Extract variables                                      */
              CHGVAR     VAR(&JOB) VALUE(%SST(&LSTENT 2 10))
              CHGVAR     VAR(&SCDDATE) VALUE(%SST(&LSTENT 22 10))
              CHGVAR     VAR(&SCDDAY) VALUE(%SST(&LSTENT 32 70))
              CHGVAR     VAR(&SCDTIME) VALUE(%SST(&LSTENT 102 6))
              CHGVAR     VAR(&FRQ) VALUE(%SST(&LSTENT 108 10))
              CHGVAR     VAR(&RELDAYMON) VALUE(%SST(&LSTENT 118 50))
              CHGVAR     VAR(&RCYACN) VALUE(%SST(&LSTENT 168 10))
              CHGVAR     VAR(&NXTDATE) VALUE(%SST(&LSTENT 178 10))
              CHGVAR     VAR(&STATUS) VALUE(%SST(&LSTENT 188 10))
              CHGVAR     VAR(&JOBQ) VALUE(%SST(&LSTENT 198 10))
              CHGVAR     VAR(&JOBQL) VALUE(%SST(&LSTENT 208 10))
              CHGVAR     VAR(&TEXT) VALUE(%SST(&LSTENT 244 50))
              CHGVAR     VAR(&JOBDQ) VALUE(%SST(&LSTENT 527 20))
              CHGVAR     VAR(&JOBD) VALUE(%SST(&LSTENT 527 10))
              CHGVAR     VAR(&JOBDL) VALUE(%SST(&LSTENT 537 10))
              CHGVAR     VAR(&USER) VALUE(%SST(&LSTENT 547 10))
              CHGVAR     VAR(&MSGQ) VALUE(%SST(&LSTENT 557 10))
              CHGVAR     VAR(&MSGQL) VALUE(%SST(&LSTENT 567 10))
              CHGVAR     VAR(&SAVE) VALUE(%SST(&LSTENT 577 10))
              CHGVAR     VAR(&JOBCMD) VALUE(%SST(&LSTENT 645 512))

/*            Retrieve user profile's job description if *USRPRF     */
              CHGVAR     VAR(&RJOBD) VALUE(&JOBD)
              CHGVAR     VAR(&RJOBDL) VALUE(&JOBDL)
              CHGVAR     VAR(&RJOBDQ) VALUE(&JOBDQ)
              IF         COND(&JOBD *EQ '*USRPRF') THEN(DO)
               RTVUSRPRF  USRPRF(&USER) JOBD(&RJOBD) JOBDLIB(&RJOBDL)
               MONMSG     MSGID(CPF0000)
               CHGVAR     VAR(&RJOBDQ) VALUE(&RJOBD *CAT &RJOBDL)
              ENDDO

/*            Retrieve job description for library list              */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QWDRJOBD) PARM(&JOBD0100 X'00010000' +
                          'JOBD0100' &RJOBDQ &APIERR)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(CVTVAL))
              CHGVAR     VAR(&OFSILL) VALUE(%BIN(&JOBD0100 361 4) +1)
              CHGVAR     VAR(&NBRILL) VALUE(%BIN(&JOBD0100 365 4))
              CHGVAR     VAR(&LIBLLEN) VALUE(&NBRILL * 11)
              CHGVAR     VAR(&INLLIBL) VALUE(%SST(&JOBD0100 &OFSILL +
                          &LIBLLEN))

/*            If job description library list *SYSVAL make up value  */
              IF         COND(&INLLIBL *EQ '*SYSVAL') THEN(DO)
               CHGVAR     VAR(&INLLIBL) VALUE(' ')
               RTVSYSVAL  SYSVAL(QUSRLIBL) RTNVAR(&QUSRLIBL)
               CHGVAR     VAR(&OFSILL) VALUE(1)
 LOOPLIBL:     IF         COND(&OFSILL *LE 241) THEN(DO)
                IF         COND(&INLLIBL *EQ ' ') THEN(CHGVAR +
                          VAR(&INLLIBL) VALUE(%SST(&QUSRLIBL +
                          &OFSILL 10)))
                ELSE       CMD(CHGVAR VAR(&INLLIBL) VALUE(&INLLIBL |> +
                          %SST(&QUSRLIBL &OFSILL 10)))
                CHGVAR     VAR(&OFSILL) VALUE(&OFSILL + 10)
                GOTO       CMDLBL(LOOPLIBL)
               ENDDO
              ENDDO

/*            Convert special values to acceptable ones              */
 CVTVAL:      IF         COND(&RELDAYMON *EQ ' ') THEN(CHGVAR +
                          VAR(&RELDAYMON) VALUE('*N'))
              IF         COND(&JOBDL *EQ ' ') THEN(CHGVAR VAR(&JOBDL) +
                          VALUE('*N'))
              IF         COND(&JOBQL *EQ ' ') THEN(CHGVAR VAR(&JOBQL) +
                          VALUE('*N'))
              IF         COND(&MSGQL *EQ ' ') THEN(CHGVAR VAR(&MSGQL) +
                          VALUE('*N'))
              CHGVAR     VAR(&TEXT) VALUE(&JSEID || '-' || &TEXT)

/*            Parse apopstrophes in TEXT parameter                   */
              CHGVAR     VAR(&PRSTXT) VALUE(&TEXT)
              CALL       PGM(HPRSAPS) PARM(&PRSTXT 50)
              CHGVAR     VAR(&TEXT) VALUE(%SST(&PRSTXT 1 75))

/*            If next submission later than schedule -> use that one */
              IF         COND(%SST(&SCDDATE 1 1) *NE '*' *AND +
                          &NXTDATE *GT &SCDDATE) THEN(CHGVAR +
                          VAR(&SCDDATE) VALUE(&NXTDATE))

/*            Make up dates for comparison                           */
              CHGVAR     VAR(&SCDDATTIM) VALUE(&SCDDATE || &SCDTIME)
              CHGVAR     VAR(&NXTDATTIM) VALUE(&NXTDATE || &SCDTIME)
              CHGVAR     VAR(&CURDATTIM) VALUE(&CURDATE || &SCDTIME)

/*            Determine if entry has expired                         */
              IF         COND(%SST(&SCDDATE 1 1) *NE '*' *AND +
                          &SCDDATTIM *LE &CURDATTIM) THEN(DO)
               CHGVAR     VAR(&NBREXP) VALUE(&NBREXP + 1)
/*             If expired and no skip -> schedule for today and hold */
               IF         COND(&SKPEXP *EQ '*NO') THEN(DO)
                CHGVAR     VAR(&SCDDATE) VALUE('*CURRENT')
                CHGVAR     VAR(&SCDTIME) VALUE('235959')
                CVTDAT     DATE(&CURDATE) TOVAR(&OMTDATE) FROMFMT(*CYMD)
                CHGVAR     VAR(&HLDENT) VALUE('1')
                SNDPGMMSG  MSGID(JAP0001) MSGF(HAUMSG) MSGDTA(&JOB || +
                          &JOBCMD) MSGTYPE(*DIAG)
               ENDDO
/*             If expired and skip --> skip entry                    */
               IF         COND(&SKPEXP *EQ '*YES') THEN(DO)
                CHGVAR     VAR(&SKPENT) VALUE('1')
                SNDPGMMSG  MSGID(JAP0002) MSGF(HAUMSG) MSGDTA(&JOB || +
                          &JOBCMD) MSGTYPE(*DIAG)
                CHGVAR     VAR(&NBRSKP) VALUE(&NBRSKP + 1)
               ENDDO
              ENDDO

/*            Convert schedule date to job format                    */
              CHGVAR     VAR(&SCDDATE@) VALUE(&SCDDATE)
              IF         COND(%SST(&SCDDATE 1 1) *NE '*') THEN(CVTDAT +
                          DATE(&SCDDATE) TOVAR(&SCDDATE@) +
                          FROMFMT(*CYMD) TOFMT(*JOB))

/*            If not skipped --> add job schedule entry              */
              IF         COND(*NOT &SKPENT) THEN(DO)
/*             Save current library list                             */
               RTVJOBA    USRLIBL(&SAVLIBL)
/*             First set library list                                */
               CHGVAR     VAR(&CMD) VALUE('CHGLIBL LIBL(' |< &INLLIBL +
                          |< ')')
               CALL       PGM(QCMDEXC) PARM(&CMD 512)
               MONMSG     MSGID(CPF0000)
               RCVMSG     MSGTYPE(*LAST)
/*             Make up command to add job schedule entry             */
               CHGVAR     VAR(&CMD) VALUE('ADDJOBSCDE JOB(' || &JOB |< +
                          ') CMD(' || &JOBCMD |< ') FRQ(' || &FRQ +
                          |< ') SCDDATE(''' || &SCDDATE@ |< ''') +
                          SCDDAY(' || &SCDDAY |< ') SCDTIME(''' || +
                          &SCDTIME |< ''') RELDAYMON(' || +
                          &RELDAYMON |< ')  SAVE(' || &SAVE |< ') +
                          RCYACN(' || &RCYACN |< ') JOBD(' |< +
                          &JOBDL |< '/' || &JOBD |< ') JOBQ(' || +
                          &JOBQL |< '/' || &JOBQ |< ') USER(' || +
                          &USER |< ') MSGQ(' || &MSGQL |< '/' || +
                          &MSGQ |< ') TEXT(''' || &TEXT |< ''')')
               CALL       PGM(QCMDEXC) PARM(&CMD 4096)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                SNDPGMMSG  MSGID(JAP0003) MSGF(&PRDLIB/HAUMSG) +
                          MSGDTA(&CMD) TOPGMQ(*SAME) MSGTYPE(*DIAG)
                CHGVAR     VAR(&NBRERR) VALUE(&NBRERR + 1)
                GOTO       CMDLBL(NEXT)
               ENDDO
/*             HOLD(*YES) specified or held or saved on source       */
/*             system or held due to expiration --> hold             */
               IF         COND(&HOLD *EQ '*YES' *OR &STATUS *EQ 'HLD' +
                          *OR &STATUS *EQ 'SAV' *OR &HLDENT) THEN(DO)
                RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGDTA(&MSGDTA)
                CHGVAR     VAR(&ENTRYNBR) VALUE(%SST(&MSGDTA 31 6))
                HLDJOBSCDE JOB(&JOB) ENTRYNBR(&ENTRYNBR)
                CHGVAR     VAR(&NBRHLD) VALUE(&NBRHLD + 1)
/*              If job was held on scheduler -> current time         */
                IF         COND(&HLDENT) THEN(CHGJOBSCDE JOB(&JOB) +
                          ENTRYNBR(&ENTRYNBR) SCDTIME(*CURRENT))
               ENDDO
/*             Increase Number of successful entries counter         */
               CHGVAR     VAR(&NBROK) VALUE(&NBROK + 1)
              ENDDO

 NEXT:        CHGVAR     VAR(&I) VALUE(&I + 1)
/*            Always reset the library list to original value        */
              CHGVAR     VAR(&CMD) VALUE('CHGLIBL LIBL(' |< &SAVLIBL +
                          |< ')')
              CALL       PGM(QCMDEXC) PARM(&CMD 512)
              MONMSG     MSGID(CPF0000)
              RCVMSG     MSGTYPE(*LAST)
              GOTO       CMDLBL(LOOP)
             ENDDO

/*           Convert variables to binary                             */
             CHGVAR     VAR(%BIN(&NBROK@)) VALUE(&NBROK)
             CHGVAR     VAR(%BIN(&NBRERR@)) VALUE(&NBRERR)
             CHGVAR     VAR(%BIN(&NBRHLD@)) VALUE(&NBRHLD)
             CHGVAR     VAR(%BIN(&NBRSKP@)) VALUE(&NBRSKP)
             CHGVAR     VAR(%BIN(&NBREXP@)) VALUE(&NBREXP)

/*           Send completion message, dependent on number ok         */
             IF         COND(&NBRERR *EQ 0) THEN(SNDPGMMSG +
                          MSGID(JAP0004) MSGF(HAUMSG) +
                          MSGDTA(&USRSPC || &NBROK@ || &NBRHLD@ || +
                          &NBRSKP@ || &NBREXP@) MSGTYPE(*COMP))
             IF         COND(&NBRERR *NE 0) THEN(SNDPGMMSG +
                          MSGID(JAP0005) MSGF(HAUMSG) +
                          MSGDTA(&USRSPC || &NBROK@ || &NBRHLD@ || +
                          &NBRSKP@ || &NBREXP@ || &NBRERR@) +
                          MSGTYPE(*ESCAPE))

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Move all *DIAG messages to the previous queue           */
 ERROR:      CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
