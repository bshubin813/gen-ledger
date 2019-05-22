/* ================================================================= */
/* Object:         HCMPCKS         *PGM CLP                          */
/*                 Compares the output files for the HRTVCKS command */
/*                 and reports discrepancies.                        */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050503 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&OUTF01Q &OUTF02Q &RECORDS &OUTPUT)

/*           Declare parameter variables                              */
             DCL        VAR(&OUTF01Q) TYPE(*CHAR) LEN(20)
             DCL        VAR(&OUTF02Q) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RECORDS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTPUT) TYPE(*CHAR) LEN(6)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&OUTF01) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTF01L) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTF02) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTF02L) TYPE(*CHAR) LEN(10)

             DCL        VAR(&DIFFFOUND) TYPE(*CHAR) LEN(4)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&OUTF01) VALUE(%SST(&OUTF01Q 1 10))
             CHGVAR     VAR(&OUTF01L) VALUE(%SST(&OUTF01Q 11 10))
             CHGVAR     VAR(&OUTF02) VALUE(%SST(&OUTF02Q 1 10))
             CHGVAR     VAR(&OUTF02L) VALUE(%SST(&OUTF02Q 11 10))

/*           Check existence of HRTVCKS output files                 */
             CHKOBJ     OBJ(&OUTF01L/&OUTF01) OBJTYPE(*FILE)
             CHKOBJ     OBJ(&OUTF02L/&OUTF02) OBJTYPE(*FILE)

/*           Override the input files                                */
             OVRDBF     FILE(HRTVCKS) TOFILE(&OUTF01L/&OUTF01)
             OVRDBF     FILE(HRTVCKST) TOFILE(&OUTF02L/&OUTF02)

/*           Call program that reports checksum differences          */
             CALL       PGM(HCMPCKS1) PARM(&OUTF01L &OUTF01 &OUTF02L +
                          &OUTF02 &RECORDS &DIFFFOUND)

             DLTOVR     FILE(HRTVCKS HRTVCKST)
             MONMSG     MSGID(CPF0000)

             IF         COND(&DIFFFOUND *EQ '*YES') THEN(DO)
              CHGSPLFA   FILE(HCMPCKS1P) SPLNBR(*LAST) +
                          USRDTA('*MISMATCH*')
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           If OUTPUT(*) display and delete spooled file            */
             IF         COND(&OUTPUT *EQ '*') THEN(DO)
              DSPSPLF    FILE(HCMPCKS1P) SPLNBR(*LAST)
              DLTSPLF    FILE(HCMPCHKS1P) SPLNBR(*LAST)
              MONMSG     MSGID(CPF0000)
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
