/* ================================================================= */
/* Object:         HLSTTRG1        *PGM CLP                          */
/*                 List triggers for files in target/group.          */
/*                                                                   */
/* Synopsis:       Builds HLSTCFGO file for target/group specified   */
/*                 and lists triggers.                               */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020708 FK  Initial delivery                                     */
/* 20020916 FK  List triggers according to object specifiers         */
/* 20030114 FK  Consider excludes                                    */
/* 20030506 FK  Add iCluster support                                 */
/* 20030521 FK  Clear temporary file before adding new triggers      */
/* 20111217 FK  REMOVE HA                                            */
/* ================================================================= */
             PGM        PARM(&UTLLIB &TRGFILEQ &ICGROUP &NBRTRG)

/*           Declare parameter variables                             */
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRGFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBRTRG) TYPE(*DEC) LEN(7 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&TRGFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TRGFILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&NBRCURRCD) TYPE(*DEC) LEN(10 0)

/*           Declare file                                            */
             DCLF       FILE(HLSTCFGO)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRTRG) VALUE(0)

/*           Create configuration file and override                  */
             HLSTCFG    OUTLIB(QTEMP) ICGROUP(&ICGROUP)
             OVRDBF     FILE(HLSTCFGO) TOFILE(QTEMP/HLSTCFGO)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&TRGFILE) VALUE(%SST(&TRGFILEQ 1 10))
             CHGVAR     VAR(&TRGFILEL) VALUE(%SST(&TRGFILEQ 11 10))

/*           Create triggers file                                    */
             DLTF       FILE(&TRGFILEL/&TRGFILE)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CPYF       FROMFILE(&UTLLIB/HLSTTRG) +
                          TOFILE(&TRGFILEL/&TRGFILE) CRTFILE(*YES)
             CLRPFM     FILE(&TRGFILEL/&TRGFILE)

/*           Delete temp file in QTEMP if still exists               */
             DLTF       FILE(QTEMP/HLSTTRGTMP)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Ensure that proper triggers file is used                */
             OVRDBF     FILE(HLSTTRG) TOFILE(&TRGFILEL/&TRGFILE)

 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Only process object specifiers with *INCLUDE and        */
/*             object type *ALL or *FILE                             */
             IF         COND(&LOINCF *EQ 'Y' *AND (&LOOBJT *EQ +
                          '*ALL' *OR &LOOBJT *EQ '*FILE')) THEN(DO)
/*            Display triggers to temporary output file              */
              DSPFD      FILE(&LOLIB/&LOOBJ) TYPE(*TRG) +
                          OUTPUT(*OUTFILE) FILEATR(*PF) +
                          OUTFILE(QTEMP/HLSTTRGTMP)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            Copy contents into final trigger file                   */
              CPYF       FROMFILE(QTEMP/HLSTTRGTMP) +
                          TOFILE(&TRGFILEL/&TRGFILE) MBROPT(*ADD) +
                          FMTOPT(*MAP *DROP)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            Fill target/group in trigger file and match objects     */
              CALL       PGM(HLSTTRG3) PARM(&LOGRPN)
             ENDDO

             GOTO       CMDLBL(LOOP)

/*           Delete temporary file                                   */
 ELOOP:      DLTF       FILE(QTEMP/HLSTTRGTMP)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Produce listing                                         */
             OVRPRTF    FILE(QPQUPRFIL) SPLFNAME(HLSTTRG)
             RUNQRY     QRY(HLSTTRG) QRYFILE((&TRGFILEL/&TRGFILE)) +
                          OUTTYPE(*PRINTER)
             DLTOVR     FILE(QPQUPRFIL)

/*           Determine number of triggers                            */
             RTVMBRD    FILE(&TRGFILEL/&TRGFILE) NBRCURRCD(&NBRCURRCD)
             CHGVAR     VAR(&NBRTRG) VALUE(&NBRCURRCD)

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
