/* ================================================================= */
/* Object:         HRTVJRNANZ      *PGM CLP                          */
/*                 Command processing program for HRTVJRNANZ         */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010731 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&OUTFILEQ &MONTHS &RELDATE &CLNHST)

/*           Declare parameter variables                             */
             DCL        VAR(&OUTFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&MONTHS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&RELDATE) TYPE(*CHAR) LEN(7)
             DCL        VAR(&CLNHST) TYPE(*DEC) LEN(3 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL)

             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILEL) TYPE(*CHAR) LEN(10)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&OUTFILE) VALUE(%SST(&OUTFILEQ 1 10))
             CHGVAR     VAR(&OUTFILEL) VALUE(%SST(&OUTFILEQ 11 10))

/*           Create output file                                      */
             CHKOBJ     OBJ(&OUTFILEL/&OUTFILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CPYF       FROMFILE(ANZTOT1) TOFILE(&OUTFILEL/&OUTFILE) +
                          CRTFILE(*YES)
             ENDDO
             CLRPFM     FILE(&OUTFILEL/&OUTFILE)

/*           Ensure that the proper output file is used              */
             OVRDBF     FILE(ANZTOTO) TOFILE(&OUTFILEL/&OUTFILE)

/*           Copy the appropriate records and clean-up               */
             CALL       PGM(HRTVANZ1) PARM(&MONTHS &RELDATE &CLNHST)

/*           Delete overrides                                        */
             DLTOVR     FILE(ANZTOTO)

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
