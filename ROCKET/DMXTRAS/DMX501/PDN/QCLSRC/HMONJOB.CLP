/* ================================================================= */
/* Object:         HMONJOB         *PGM CLP                          */
/*                 Command processing program for HMONJOB.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050707 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&FILEQ &DTAQQ &PRGAGE &SYSDTAQ)

/*           Declare parameter variables                             */
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DTAQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&PRGAGE) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&SYSDTAQ) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DTAQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DTAQL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&SYSDTAQJOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&ENDSTS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&QDATE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&QDATESV) TYPE(*CHAR) LEN(6)

             DCL        VAR(&PRGAGE@) TYPE(*CHAR) LEN(5)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    JOB(&JOB) USER(&JOBUSR) NBR(&JOBNBR) +
                          TYPE(&JOBTYPE)
             RTVNETA    SYSNAME(&SYSNAM)
             CHGVAR     VAR(&PRGAGE@) VALUE(&PRGAGE)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&FILE) VALUE(%SST(&FILEQ 1 10))
             CHGVAR     VAR(&FILEL) VALUE(%SST(&FILEQ 11 10))
             CHGVAR     VAR(&DTAQ) VALUE(%SST(&DTAQQ 1 10))
             CHGVAR     VAR(&DTAQL) VALUE(%SST(&DTAQQ 11 10))

/*           Check for existence of libraries                        */
             CHKOBJ     OBJ(&FILEL) OBJTYPE(*LIB)
             CHKOBJ     OBJ(&DTAQL) OBJTYPE(*LIB)

/*           Retrieve product library                                */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Create monitor file if not existing                     */
             CHKOBJ     OBJ(&FILEL/&FILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDUPOBJ  OBJ(HMONJOB) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(&FILEL) NEWOBJ(&FILE) DATA(*NO)
             ENDDO

/*           Create data queue if not existing                       */
             CHKOBJ     OBJ(&DTAQL/&DTAQ) OBJTYPE(*DTAQ)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDTAQ    DTAQ(&DTAQL/&DTAQ) TYPE(*STD) MAXLEN(144) +
                          SEQ(*KEYED) KEYLEN(4) AUTORCL(*YES) +
                          TEXT('HMONJOB - Monitored jobs status +
                          changes')
             ENDDO

/*           Create system data queue if not existing                */
             IF         COND(&SYSDTAQ *EQ '*YES') THEN(DO)
              CHKOBJ     OBJ(QSYS/QSYSDTAQ) OBJTYPE(*DTAQ)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CRTDTAQ    DTAQ(QSYS/QSYSDTAQ) TYPE(*STD) MAXLEN(144) +
                          SEQ(*KEYED) KEYLEN(4) AUTORCL(*YES) +
                          TEXT('HMONJOB - Jobs in unallocated job +
                          queues')
              ENDDO
             ENDDO

/*           Submit job to batch if interactive                      */
             IF         COND(&JOBTYPE *EQ '1') THEN(DO)
              SBMJOB     CMD(HMONJOB FILE(&FILEL/&FILE) +
                          DTAQ(&DTAQL/&DTAQ) PRGAGE(&PRGAGE) +
                          SYSDTAQ(&SYSDTAQ)) JOB(HMONJOB) +
                          JOBD(HMONJOB) JOBQ(*JOBD) USER(*JOBD) +
                          INLLIBL(*JOBD)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Try to reorganise physical file                         */
             IF         COND(&DTAQQ *NE 'QSYSDTAQ  QSYS') THEN(DO)
              RGZPFM     FILE(&FILEL/&FILE)
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           Submit job for reading system data queue                */
             IF         COND(&SYSDTAQ *EQ '*YES' *AND &DTAQQ *NE +
                          'QSYSDTAQ  QSYS') THEN(DO)
              CHGVAR     VAR(&SYSDTAQJOB) VALUE(%SST(&JOB 1 9) |< 'Q')
              SBMJOB     CMD(HMONJOB FILE(&FILEL/&FILE) +
                          DTAQ(QSYS/QSYSDTAQ) PRGAGE(*NONE)) +
                          JOB(&SYSDTAQJOB) JOBD(HMONJOB) +
                          JOBQ(*JOBD) USER(*JOBD) INLLIBL(*JOBD)
             ENDDO

/*           Call program that receives data queue entries           */
             OVRDBF     FILE(HMONJOB) TOFILE(&FILEL/&FILE)
 LOOP:       CALL       PGM(HMONJOB1) PARM(&SYSNAM &JOB &JOBUSR +
                          &JOBNBR &DTAQ &DTAQL)
/*           If no end requested, optionally purge and loop          */
             RTVJOBA    ENDSTS(&ENDSTS)
             IF         COND(&ENDSTS *NE '1' *AND &PRGAGE *NE 0) +
                          THEN(DO)
/*            If new date, start purge job                           */
              RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&QDATE)
              IF         COND(&QDATE *NE &QDATESV) THEN(DO)
               SBMJOB     CMD(CALL PGM(HMONJOBPRG) PARM(&FILEQ +
                          &PRGAGE@)) JOB(HMONJOBPRG) JOBD(HMONJOB)
               CHGVAR     VAR(&QDATESV) VALUE(&QDATE)
              ENDDO
              GOTO       CMDLBL(LOOP)
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
