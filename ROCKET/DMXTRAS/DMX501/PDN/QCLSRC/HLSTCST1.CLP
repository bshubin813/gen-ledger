/* ================================================================= */
/* Object:         HLSTCST1        *PGM CLP                          */
/*                 List constraints for files in target/group.       */
/*                                                                   */
/* Synopsis:       Builds HLSTCFGO file for target/group specified   */
/*                 and lists constraints.                            */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020708 FK  Initial delivery                                     */
/* 20020916 FK  List constraints according to object specifiers      */
/* 20030114 FK  Consider excludes                                    */
/* 20030506 FK  Add iCluster support                                 */
/* 20030521 FK  Clear output file before adding new constraints      */
/* 20111217 FK  REMOVE HA                                            */
/* ================================================================= */
             PGM        PARM(&UTLLIB &CSTFILEQ &ICGROUP &NBRCST)

/*           Declare parameter variables                             */
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CSTFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBRCST) TYPE(*DEC) LEN(7 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&CSTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CSTFILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&NBRCURRCD) TYPE(*DEC) LEN(10 0)

/*           Declare file                                            */
             DCLF       FILE(HLSTCFGO)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO +
                          CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRCST) VALUE(0)

/*           Create configuration file and override                  */
             HLSTCFG    OUTLIB(QTEMP) ICGROUP(&ICGROUP)
             OVRDBF     FILE(HLSTCFGO) TOFILE(QTEMP/HLSTCFGO)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&CSTFILE) VALUE(%SST(&CSTFILEQ 1 10))
             CHGVAR     VAR(&CSTFILEL) VALUE(%SST(&CSTFILEQ 11 10))

/*           Create constraints file                                 */
             DLTF       FILE(&CSTFILEL/&CSTFILE)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CPYF       FROMFILE(&UTLLIB/HLSTCST) +
                          TOFILE(&CSTFILEL/&CSTFILE) CRTFILE(*YES)
             CLRPFM     FILE(&CSTFILEL/&CSTFILE)

/*           Delete temp file in QTEMP if still exists               */
             DLTF       FILE(QTEMP/HLSTCSTTMP)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Ensure that proper constraints file is used             */
             OVRDBF     FILE(HLSTCST) TOFILE(&CSTFILEL/&CSTFILE)

 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Only process object specifiers with *INCLUDE and        */
/*             object type *ALL or *FILE                             */
             IF         COND(&LOINCF *EQ 'Y' *AND (&LOOBJT *EQ +
                          '*ALL' *OR &LOOBJT *EQ '*FILE')) THEN(DO)
/*            Display constraints to temporary output file            */
              DSPFD      FILE(&LOLIB/&LOOBJ) TYPE(*CST) +
                          OUTPUT(*OUTFILE) FILEATR(*PF) +
                          OUTFILE(QTEMP/HLSTCSTTMP)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            Copy contents into final constraints file               */
              CPYF       FROMFILE(QTEMP/HLSTCSTTMP) +
                          TOFILE(&CSTFILEL/&CSTFILE) MBROPT(*ADD) +
                          FMTOPT(*MAP *DROP)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            Fill target/group in constraints file and match objects */
              CALL       PGM(HLSTCST3) PARM(&LOGRPN)
             ENDDO

             GOTO       CMDLBL(LOOP)

/*           Delete temporary file                                   */
 ELOOP:      DLTF       FILE(QTEMP/HLSTCSTTMP)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Produce listing                                         */
             OVRPRTF    FILE(QPQUPRFIL) SPLFNAME(HLSTCST)
             RUNQRY     QRY(HLSTCST) QRYFILE((&CSTFILEL/&CSTFILE)) +
                          OUTTYPE(*PRINTER)
             DLTOVR     FILE(QPQUPRFIL)

/*           Determine number of constraints                         */
             RTVMBRD    FILE(&CSTFILEL/&CSTFILE) NBRCURRCD(&NBRCURRCD)
             CHGVAR     VAR(&NBRCST) VALUE(&NBRCURRCD)

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
