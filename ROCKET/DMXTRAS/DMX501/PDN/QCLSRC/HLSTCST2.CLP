/* ================================================================= */
/* Object:         HLSTCST2        *PGM CLP                          */
/*                 Removes or restores constraints for files in the  */
/*                 specified HLSTCST file                            */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020708 FK  Initial delivery                                     */
/* 20020923 FK  When adding *REFCST, variables FKEY and PKEY swap    */
/* 20050203 FK  Allow change of constraint                           */
/*              Indicate actual number of constraints                */
/* 20080208 FK  Allow change of constraint to value in file          */
/* ================================================================= */
             PGM        PARM(&UTLLIB &ACTION &CSTFILEQ &STATE &LIB +
                          &NBRFIL &NBRCST)

/*           Declare parameter variables                             */
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CSTFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&STATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBRFIL) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRCST) TYPE(*DEC) LEN(7 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&CSTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CSTFILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CSFILESV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CSLIBSV) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(5000)
             DCL        VAR(&PHCSTT@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PHDLTR@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PHULTR@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PHCKXP@) TYPE(*CHAR) LEN(2500)
             DCL        VAR(&PHCSTN@) TYPE(*CHAR) LEN(258)

             DCL        VAR(&STATE@) TYPE(*CHAR) LEN(10)

             DCL        VAR(&LEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRKEY) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&POS) TYPE(*DEC) LEN(5 0)

             DCL        VAR(&LEN155) TYPE(*DEC) LEN(15 5)
             DCL        VAR(&MSGID) TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGDTA) TYPE(*CHAR) LEN(255)
             DCL        VAR(&NBRMSGCST) TYPE(*DEC) LEN(5 0)

/*           Declare file                                            */
             DCLF       FILE(HLSTCST) ALWVARLEN(*YES)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRFIL) VALUE(0)
             CHGVAR     VAR(&NBRCST) VALUE(0)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&CSTFILE) VALUE(%SST(&CSTFILEQ 1 10))
             CHGVAR     VAR(&CSTFILEL) VALUE(%SST(&CSTFILEQ 11 10))

/*           Ensure that proper constraints file is used             */
             OVRDBF     FILE(HLSTCST) TOFILE(&CSTFILEL/&CSTFILE)

 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           If library specified --> Skip non-selected libraries    */
             IF         COND(&LIB *NE '*ALL' *AND &CSLIB *NE &LIB) +
                          THEN(GOTO CMDLBL(LOOP))

/*           Count number of files                                   */
             IF         COND(&CSFILE *NE &CSFILESV *OR &CSLIB *NE +
                          &CSLIBSV) THEN(CHGVAR VAR(&NBRFIL) +
                          VALUE(&NBRFIL + 1))

/*           If action *RMV --> Skip duplicates for file             */
             IF         COND(&ACTION *EQ '*RMV' *AND &CSFILE *EQ +
                          &CSFILESV *AND &CSLIB *EQ &CSLIBSV) +
                          THEN(GOTO CMDLBL(LOOP))

/*           Update save variables                                   */
             CHGVAR     VAR(&CSFILESV) VALUE(&CSFILE)
             CHGVAR     VAR(&CSLIBSV) VALUE(&CSLIB)

/*           Check if file exists                                    */
             CHKOBJ     OBJ(&CSLIB/&CSFILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))

/*           Extract name of constraint                              */
             CHGVAR     VAR(&PHCSTN@) VALUE(' ')
             CHGVAR     VAR(&LEN) VALUE(%BIN(&PHCSTN 1 2))
             IF         COND(&LEN *NE 0) THEN(CHGVAR VAR(&PHCSTN@) +
                          VALUE(%SST(&PHCSTN 3 &LEN)))

/*           Remove referential-integrity constraints                */
             IF         COND(&ACTION *EQ '*RMV') THEN(DO)
              SNDPGMMSG  MSGID(LCS0001) MSGF(HAUMSG) MSGDTA(&CSFILE +
                          || &CSLIB || &ACTION || '*ALL') +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(LCS0001) MSGF(HAUMSG) MSGDTA(&CSFILE +
                          || &CSLIB || &ACTION || '*ALL') TOPGMQ(*SAME)
              RMVPFCST   FILE(&CSLIB/&CSFILE) CST(*ALL) TYPE(*REFCST)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            Increase number of constraints removed                 */
              RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGDTA(&MSGDTA) +
                          MSGID(&MSGID)
              IF         COND(&MSGID *EQ 'CPC32B1') THEN(DO)
               CHGVAR     VAR(&NBRMSGCST) VALUE(%BIN(&MSGDTA 21 2))
               MONMSG     MSGID(CPF0000 MCH0000) EXEC(CHGVAR +
                          VAR(&NBRMSGCST) VALUE(0))
               CHGVAR     VAR(&NBRCST) VALUE(&NBRCST + &NBRMSGCST)
              ENDDO
             ENDDO

/*           Change referential-integrity constraints only           */
             IF         COND(&ACTION *EQ '*CHG' *AND &PHCSTT *EQ +
                          'R') THEN(DO)
              CHGVAR     VAR(&STATE@) VALUE(&STATE)
              IF         COND(&STATE@ *EQ '*FILESTATE' *AND +
                          %SST(&PHCSTS 2 1) *EQ 'E') THEN(CHGVAR +
                          VAR(&STATE@) VALUE('*ENABLED'))
              IF         COND(&STATE@ *EQ '*FILESTATE' *AND +
                          %SST(&PHCSTS 2 1) *EQ 'D') THEN(CHGVAR +
                          VAR(&STATE@) VALUE('*DISABLED'))
              SNDPGMMSG  MSGID(LCS0001) MSGF(HAUMSG) MSGDTA(&CSFILE +
                          || &CSLIB || &ACTION || &PHCSTN@) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(LCS0001) MSGF(HAUMSG) MSGDTA(&CSFILE +
                          || &CSLIB || &ACTION || &PHCSTN@) +
                          TOPGMQ(*SAME)
              CHGPFCST   FILE(&CSLIB/&CSFILE) CST(&PHCSTN@) +
                          STATE(&STATE@)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            Increase number of constraints changed                 */
              RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGDTA(&MSGDTA) +
                          MSGID(&MSGID)
              IF         COND(&MSGID *EQ 'CPC32B2') THEN(DO)
               CHGVAR     VAR(&NBRMSGCST) VALUE(%BIN(&MSGDTA 21 2))
               MONMSG     MSGID(CPF0000 MCH0000) EXEC(CHGVAR +
                          VAR(&NBRMSGCST) VALUE(0))
               CHGVAR     VAR(&NBRCST) VALUE(&NBRCST + &NBRMSGCST)
              ENDDO
             ENDDO

/*           Restore constraint                                      */
             IF         COND(&ACTION *EQ '*RST') THEN(DO)
              SNDPGMMSG  MSGID(LCS0001) MSGF(HAUMSG) MSGDTA(&CSFILE +
                          || &CSLIB || &ACTION || &PHCSTN@) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(LCS0001) MSGF(HAUMSG) MSGDTA(&CSFILE +
                          || &CSLIB || &ACTION || &PHCSTN@) +
                          TOPGMQ(*SAME)
/*            Determine constraint type                              */
              CHGVAR     VAR(&PHCSTT@) VALUE('*CHKCST')
              IF         COND(&PHCSTT = 'P') THEN(CHGVAR +
                          VAR(&PHCSTT@) VALUE('*PRIKEY'))
              IF         COND(&PHCSTT = 'U') THEN(CHGVAR +
                          VAR(&PHCSTT@) VALUE('*UNQCST'))
              IF         COND(&PHCSTT = 'R') THEN(CHGVAR +
                          VAR(&PHCSTT@) VALUE('*REFCST'))
/*            Make up command for ADDPFCST                           */
              CHGVAR     VAR(&CMD) VALUE('ADDPFCST FILE(' || &CSLIB +
                          |< '/' |< &CSFILE |< ') TYPE(' |< +
                          &PHCSTT@ |< ')')
/*            Add Constraint name                                    */
              CHGVAR     VAR(&CMD) VALUE(&CMD |> 'CST("' |< &PHCSTN@ +
                          |< '")')
/*            Finish command for *CHKCST constraint                  */
              IF         COND(&PHCSTT@ *EQ '*CHKCST') THEN(DO)
               CHGVAR     VAR(&LEN) VALUE(%BIN(&PHCKXP 1 2))
               IF         COND(&LEN *NE 0) THEN(DO)
                CHGVAR     VAR(&PHCKXP@) VALUE(%SST(&PHCKXP 3 &LEN))
                CHGVAR     VAR(&LEN155) VALUE(&LEN)
                CALL       PGM(HPRSAPS) PARM(&PHCKXP@ &LEN155)
                CHGVAR     VAR(&CMD) VALUE(&CMD |> 'CHKCST(' |< +
                          &PHCKXP@ |< ')')
               ENDDO
              ENDDO
/*            Add keys to command for *UNQCST, *PRIKEY or *REFCST    */
              IF         COND(&PHCSTT@ *NE '*CHKCST') THEN(DO)
               CHGVAR     VAR(&CMD) VALUE(&CMD |> 'KEY(')
               CHGVAR     VAR(&I) VALUE(1)
 LOOPFKY:      IF         COND(&I *LE &PHNMKY) THEN(DO)
                CHGVAR     VAR(&POS) VALUE((&I - 1) * 10 + 3)
                IF         COND(&PHCSTT@ *EQ '*REFCST') THEN(CHGVAR +
                          VAR(&CMD) VALUE(&CMD |> %SST(&PHFRKY &POS +
                          10)))
                ELSE       CMD(CHGVAR VAR(&CMD) VALUE(&CMD |> +
                          %SST(&PHPRKY &POS 10)))
                CHGVAR     VAR(&I) VALUE(&I + 1)
                GOTO       CMDLBL(LOOPFKY)
               ENDDO
               CHGVAR     VAR(&CMD) VALUE(&CMD |> ')')
              ENDDO
/*            Add parent file, key and delete/upd rule for *REFCST   */
              IF         COND(&PHCSTT@ *EQ '*REFCST') THEN(DO)
               CHGVAR     VAR(&CMD) VALUE(&CMD |> 'PRNFILE(' |< +
                          &PHCPLN |< '/' |< &PHCPFN |< ')')
               CHGVAR     VAR(&CMD) VALUE(&CMD |> 'PRNKEY(')
               CHGVAR     VAR(&I) VALUE(1)
 LOOPPKY:      IF         COND(&I *LE &PHNMKY) THEN(DO)
                CHGVAR     VAR(&POS) VALUE((&I - 1) * 10 + 3)
                CHGVAR     VAR(&CMD) VALUE(&CMD |> %SST(&PHPRKY &POS 10))
                CHGVAR     VAR(&I) VALUE(&I + 1)
                GOTO       CMDLBL(LOOPPKY)
               ENDDO
               CHGVAR     VAR(&CMD) VALUE(&CMD |> ')')
/*             Determine value for Delete rule                       */
               IF         COND(&PHDLTR *EQ 'RS') THEN(CHGVAR +
                          VAR(&PHDLTR@) VALUE('*RESTRICT'))
               IF         COND(&PHDLTR *EQ 'NA') THEN(CHGVAR +
                          VAR(&PHDLTR@) VALUE('*NOACTION'))
               IF         COND(&PHDLTR *EQ 'CC') THEN(CHGVAR +
                          VAR(&PHDLTR@) VALUE('*CASCADE'))
               IF         COND(&PHDLTR *EQ 'SN') THEN(CHGVAR +
                          VAR(&PHDLTR@) VALUE('*SETNULL'))
               IF         COND(&PHDLTR *EQ 'SD') THEN(CHGVAR +
                          VAR(&PHDLTR@) VALUE('*SETDFT'))
               CHGVAR     VAR(&CMD) VALUE(&CMD |> 'DLTRULE(' |< +
                          &PHDLTR@ |< ')')
/*             Determine value for Update rule                       */
               IF         COND(&PHULTR *EQ 'NA') THEN(CHGVAR +
                          VAR(&PHULTR@) VALUE('*NOACTION'))
               IF         COND(&PHULTR *EQ 'RS') THEN(CHGVAR +
                          VAR(&PHULTR@) VALUE('*RESTRICT'))
               CHGVAR     VAR(&CMD) VALUE(&CMD |> 'UPDRULE(' |< +
                          &PHULTR@ |< ')')
              ENDDO
/*            Execute ADDPFCST command                               */
              CALL       PGM(QCMDEXC) PARM(&CMD 5000)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*            Increase number of constraints restored                */
              RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGDTA(&MSGDTA) +
                          MSGID(&MSGID)
              IF         COND(&MSGID *EQ 'CPC32B0') THEN(DO)
               CHGVAR     VAR(&NBRMSGCST) VALUE(%BIN(&MSGDTA 21 2))
               MONMSG     MSGID(CPF0000 MCH0000) EXEC(CHGVAR +
                          VAR(&NBRMSGCST) VALUE(0))
               CHGVAR     VAR(&NBRCST) VALUE(&NBRCST + &NBRMSGCST)
              ENDDO
             ENDDO   /* *RST */

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
