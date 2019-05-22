/* ================================================================= */
/* Object:         HRTVNETTFC      *PGM CLP                          */
/*                 Command processing program for HRTVNETTFC         */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20060216 FK  Initial delivery                                     */
/* 20060424 FK  Member name same as file name                        */
/* ================================================================= */
             PGM        PARM(&TFCFILEQ &SUMOUTFQ &SUMUNIT &NBRUNIT +
                          &RELDATE &CLNHST &PORT &LCLADR &RMTADR +
                          &SYSNAM)

/*           Declare parameter variables                             */
             DCL        VAR(&TFCFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&SUMOUTFQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&SUMUNIT) TYPE(*CHAR) LEN(5)
             DCL        VAR(&NBRUNIT) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&RELDATE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CLNHST) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&PORT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&LCLADR) TYPE(*CHAR) LEN(15)
             DCL        VAR(&RMTADR) TYPE(*CHAR) LEN(15)
             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL)

             DCL        VAR(&TFCFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TFCFILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SUMOUTF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SUMOUTFL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ISODATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRINT) TYPE(*CHAR) LEN(4)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&PRINT) VALUE('*NO')

/*           Split qualifiers                                        */
             CHGVAR     VAR(&TFCFILE) VALUE(%SST(&TFCFILEQ 1 10))
             CHGVAR     VAR(&TFCFILEL) VALUE(%SST(&TFCFILEQ 11 10))
             CHGVAR     VAR(&SUMOUTF) VALUE(%SST(&SUMOUTFQ 1 10))
             CHGVAR     VAR(&SUMOUTFL) VALUE(%SST(&SUMOUTFQ 11 10))
             IF         COND(&SUMOUTF *EQ '*PRINT') THEN(DO)
              CHGVAR     VAR(&PRINT) VALUE('*YES')
              CHGVAR     VAR(&SUMOUTF) VALUE('HNETTFCSUM')
              CHGVAR     VAR(&SUMOUTFL) VALUE('QTEMP')
             ENDDO

/*           Check date                                              */
             CVTDAT     DATE(&RELDATE) TOVAR(&ISODATE) +
                          FROMFMT(*YYMD) TOFMT(*ISO) TOSEP(*NONE)

/*           Check existence of input file                           */
             CHKOBJ     OBJ(&TFCFILEL/&TFCFILE) OBJTYPE(*FILE)

/*           Create output file                                      */
             CHKOBJ     OBJ(&SUMOUTFL/&SUMOUTF) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CPYF       FROMFILE(HNETTFCSUM) +
                          TOFILE(&SUMOUTFL/&SUMOUTF) +
                          TOMBR(&SUMOUTF) CRTFILE(*YES)
             ENDDO
             CLRPFM     FILE(&SUMOUTFL/&SUMOUTF)

/*           Determine default number of units                       */
             IF         COND(&NBRUNIT *EQ 0 *AND &SUMUNIT *EQ +
                          '*DAY') THEN(CHGVAR VAR(&NBRUNIT) VALUE(31))
             IF         COND(&NBRUNIT *EQ 0 *AND &SUMUNIT *EQ +
                          '*HOUR') THEN(CHGVAR VAR(&NBRUNIT) +
                          VALUE(31 * 24))

/*           Retrieve system name if current                         */
             IF         COND(&SYSNAM *EQ '*CURRENT') THEN(RTVNETA +
                          SYSNAME(&SYSNAM))

/*           Ensure that the specified files are use                 */
             OVRDBF     FILE(HNETTFC) TOFILE(&TFCFILEL/&TFCFILE)
             OVRDBF     FILE(HNETTFCSUM) TOFILE(&SUMOUTFL/&SUMOUTF) +
                          MBR(*FIRST)

/*           Summarise the appropriate records and clean up          */
             CALL       PGM(HRTVTFC1) PARM(&SUMUNIT &NBRUNIT +
                          &RELDATE &CLNHST &PORT &LCLADR &RMTADR +
                          &SYSNAM &PRINT)

/*           Delete overrides                                        */
             DLTOVR     FILE(HNETTFC)
             DLTOVR     FILE(HNETTFCSUM)

/*           Send completion message                                 */
             IF         COND(&PRINT *EQ '*NO') THEN(SNDPGMMSG +
                          MSGID(RNT0001) MSGF(HAUMSG) +
                          MSGDTA(&SUMOUTFQ) MSGTYPE(*COMP))
             IF         COND(&PRINT *EQ '*YES') THEN(SNDPGMMSG +
                          MSGID(RNT0002) MSGF(HAUMSG) MSGTYPE(*COMP))

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
