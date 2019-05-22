/*CP: LOG(*NO)                                                       */
/* ================================================================= */
/* Object:         HCHGUSRSTS      *PGM CLP                          */
/*                 Command processing program for HCHGUSRSTS.        */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000321 FK  Initial delivery                                     */
/* 20001204 FK  Allow reset of password for non-Q user profiles      */
/* 20010322 FK  Do not fail if disable of system user profile fails  */
/* 20010328 FK  Allow for input file                                 */
/* 20010527 FK  If user does not exist --> remove error              */
/* 20010527 FK  Do not try to change user profiles with attribute    */
/*              *IBM                                                 */
/* 20011128 FK  Exclude Q* user profiles by default                  */
/*              Exclude HASUITE and DMCLUSTER user profiles          */
/* 20020508 FK  Allow selection by user class                        */
/* 20031209 FK  No logging of CL commands                            */
/* ================================================================= */
             PGM        PARM(&USRPRF &USRCLS &EXCQPRF &STATUS +
                          &RSTPWD &FILEQ)

/*           Declare parameter variables                             */
             DCL        VAR(&USRPRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USRCLS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&EXCQPRF) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RSTPWD) TYPE(*CHAR) LEN(4)
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&PRDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBRUSR) TYPE(*DEC) LEN(5 0) VALUE(0)
             DCL        VAR(&NBRUSR@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRCHG) TYPE(*DEC) LEN(5 0) VALUE(0)
             DCL        VAR(&NBRCHG@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRPWD) TYPE(*DEC) LEN(5 0) VALUE(0)
             DCL        VAR(&NBRPWD@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&OBJATR) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */
             DCLF       FILE(HCHGUSRSTS)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVOBJD    OBJ(HCHGUSRSTS) OBJTYPE(*PGM) RTNLIB(&PRDLIB)
             CHGVAR     VAR(&NBRUSR) VALUE(0)
             CHGVAR     VAR(&NBRCHG) VALUE(0)
             CHGVAR     VAR(&NBRPWD) VALUE(0)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&FILE) VALUE(%SST(&FILEQ 1 10))
             CHGVAR     VAR(&FILEL) VALUE(%SST(&FILEQ 11 10))

/*           If file specified, check existence                      */
             IF         COND(&USRPRF *EQ '*FILE') THEN(CHKOBJ +
                          OBJ(&FILEL/&FILE) OBJTYPE(*FILE))

/*           Retrieve user profiles into other temp file             */
             IF         COND(&USRPRF *NE '*FILE') THEN(DO)
              SNDPGMMSG  MSGID(CUS0001) MSGF(HAUMSG) MSGDTA(&USRPRF) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(CUS0001) MSGF(HAUMSG) MSGDTA(&USRPRF) +
                          TOPGMQ(*SAME)
              DSPUSRPRF  USRPRF(&USRPRF) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HCHGUSRTMP)
             ENDDO

/*           Create file in QTEMP that holds user profiles           */
             DLTF       FILE(QTEMP/HCHGUSRSTS)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HCHGUSRSTS) FROMLIB(&PRDLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP)

/*           Make sure that the QTEMP file is used in the program    */
             OVRDBF     FILE(HCHGUSRSTS) TOFILE(QTEMP/HCHGUSRSTS)

/*           Copy all the records to HCHGUSRSTS to avoid incompat.   */
             IF         COND(&USRPRF *NE '*FILE') THEN(DO)
              CPYF       FROMFILE(QTEMP/HCHGUSRTMP) +
                          TOFILE(QTEMP/HCHGUSRSTS) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
              MONMSG     MSGID(CPF0000)
              DLTF       FILE(QTEMP/HCHGUSRTMP)
             ENDDO
             IF         COND(&USRPRF *EQ '*FILE') THEN(DO)
              CPYF       FROMFILE(&FILEL/&FILE) +
                          TOFILE(QTEMP/HCHGUSRSTS) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           Send status message "User profiles being processed"     */
             SNDPGMMSG  MSGID(CUS0002) MSGF(HAUMSG) MSGDTA(&USRPRF +
                          || &STATUS) TOPGMQ(*EXT) MSGTYPE(*STATUS)

/*           Read all records in the temporary file                  */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              GOTO       CMDLBL(ELOOP)
             ENDDO

/*           Skip non-existing user profile                          */
             RTVOBJD    OBJ(&UPUPRF) OBJTYPE(*USRPRF) OBJATR(&OBJATR)
             MONMSG     MSGID(CPF0000) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              GOTO       CMDLBL(LOOP)
             ENDDO

/*           Skip Q* user profiles if specified                      */
             IF         COND(&EXCQPRF *EQ '*YES' *AND %SST(&UPUPRF 1 +
                          1) *EQ 'Q') THEN(GOTO CMDLBL(LOOP))

/*           If user class specified --> check if matching           */
             IF         COND(&USRCLS *NE '*ALL' *AND &UPUSCL *NE +
                          &USRCLS) THEN(GOTO CMDLBL(LOOP))

/*           Only change non-system and non-iCluster user profiles */
             IF         COND(&UPUPRF *NE 'QSECOFR' *AND &UPUPRF *NE +
                          'QSYSOPR' *AND &UPUPRF *NE 'QSYS' *AND +
                          &UPUPRF *NE 'HASUITE' *AND &UPUPRF *NE +
                          'DMCLUSTER' *AND %SST(&OBJATR 1 4) *NE +
                          '*IBM') THEN(DO)
              CHGVAR     VAR(&NBRUSR) VALUE(&NBRUSR + 1)
              IF         COND(&USRPRF *NE '*FILE') THEN(DO)
               CHGUSRPRF  USRPRF(&UPUPRF) STATUS(&STATUS)
               MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ECHG))
               CHGVAR     VAR(&NBRCHG) VALUE(&NBRCHG + 1)
              ENDDO
              IF         COND(&USRPRF *EQ '*FILE') THEN(DO)
               CHGUSRPRF  USRPRF(&UPUPRF) STATUS(&UPSTAT)
               MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ECHG))
               CHGVAR     VAR(&NBRCHG) VALUE(&NBRCHG + 1)
 ECHG:        ENDDO
/*            Optionally reset password                              */
              IF         COND(&RSTPWD *EQ '*YES' *AND %SST(&UPUPRF 1 +
                          1) *NE 'Q') THEN(DO)
               CHGUSRPRF  USRPRF(&UPUPRF) PASSWORD(&UPUPRF) PWDEXP(*YES)
               MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(EPWD))
               CHGVAR     VAR(&NBRPWD) VALUE(&NBRPWD + 1)
 EPWD:        ENDDO
             ENDDO

             GOTO       CMDLBL(LOOP)

/*           Send completion message                                 */
 ELOOP:      CHGVAR     VAR(%BIN(&NBRUSR@)) VALUE(&NBRUSR)
             CHGVAR     VAR(%BIN(&NBRCHG@)) VALUE(&NBRCHG)
             CHGVAR     VAR(%BIN(&NBRPWD@)) VALUE(&NBRPWD)
             SNDPGMMSG  MSGID(CUS0003) MSGF(HAUMSG) MSGDTA(&USRPRF +
                          || &STATUS || &NBRUSR@ || &NBRCHG@ || +
                          &NBRPWD@) MSGTYPE(*COMP)

/*           Clean-up                                                */
             DLTF       FILE(QTEMP/HCHGUSRSTS)

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
