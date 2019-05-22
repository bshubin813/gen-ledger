/* ================================================================= */
/* Object:         HMONJOBPRG      *PGM CLP                          */
/*                 Purge old entries from monitor jobs file          */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050708 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&FILEQ &PRGAGE_P)

/*           Declare parameter variables                             */
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&PRGAGE_P) TYPE(*CHAR) LEN(5)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&PRGAGE) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&PRGAGE@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRDLT) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&NBRDLT@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEL) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVNETA    SYSNAME(&SYSNAM)
             CHGVAR     VAR(&PRGAGE) VALUE(&PRGAGE_P)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&FILE) VALUE(%SST(&FILEQ 1 10))
             CHGVAR     VAR(&FILEL) VALUE(%SST(&FILEQ 11 10))

/*           Call program that purges old entries                    */
             OVRDBF     FILE(HMONJOB) TOFILE(&FILEL/&FILE)
             CALL       PGM(HMONJOBP1) PARM(&SYSNAM &PRGAGE &NBRDLT)
             DLTOVR     FILE(HMONJOB)

/*           Send completion message                                 */
             CHGVAR     VAR(%BIN(&PRGAGE@)) VALUE(&PRGAGE)
             CHGVAR     VAR(%BIN(&NBRDLT@)) VALUE(&NBRDLT)
             SNDPGMMSG  MSGID(MJO0002) MSGF(HAUMSG) MSGDTA(&FILE || +
                          &FILEL || &PRGAGE@ || &NBRDLT@) +
                          MSGTYPE(*COMP)

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
