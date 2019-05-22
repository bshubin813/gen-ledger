/* ================================================================= */
/* Object:         HLSTCFG         *PGM CLP                          */
/*                 Command processing program for HLSTCFG.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020916 FK  Initial delivery                                     */
/* 20021104 FK  Allow for IFS configuration list                     */
/* 20030424 FK  Add support for iCluster                             */
/* 20040119 FK  Only process local groups for iCluster               */
/* 20050201 FK  Allow to specify backup node                         */
/* 20050210 FK  List groups in HLSTCFGG                              */
/* 20050224 FK  Backup node *FirST                                   */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20060206 FK  Allow generic groups and marked by string            */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&OUTLIB &ICGROUP &BCKNOD &CFGTYP &MRKSTR)

/*           Declare parameter variables                             */
             DCL        VAR(&OUTLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CFGTYP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MRKSTR) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ICVER) TYPE(*CHAR) LEN(6)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */

/*           Check for existence of outfile library                  */
             CHKOBJ     OBJ(&OUTLIB) OBJTYPE(*LIB)

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

             HRTVNETA   SYSNAME(&SYSNAME)

/*           Create files for iCluster                               */
             CALL       PGM(HCRTLF) PARM('HUTGTTN')
             CALL       PGM(HCRTLF) PARM('HUGRPGI')
             CALL       PGM(HCRTLF) PARM('HUFGTTG')
             CALL       PGM(HCRTLF) PARM('HIGRPGN21')
             OVRDBF     FILE(HUTGTTN) TOFILE(QTEMP/HUTGTTN)
             OVRDBF     FILE(HUGRPGI) TOFILE(QTEMP/HUGRPGI)
             OVRDBF     FILE(HUFGTTG) TOFILE(QTEMP/HUFGTTG)
             OVRDBF     FILE(HIGRPGN21) TOFILE(QTEMP/HIGRPGN21)

/*           Create files if *OBJ or *ALL configuration requested    */
             IF         COND(&CFGTYP *EQ '*OBJ' *OR &CFGTYP *EQ +
                          '*ALL') THEN(DO)
/*            Create files for iCluster                              */
              RTVDTAARA  DTAARA(&ICLIB/HAPACKID (1 6)) RTNVAR(&ICVER)
              IF         COND(&ICVER *LT 'iC 5.0') THEN(DO)
               CALL       PGM(HCRTLF) PARM('HIOBJGL')
               OVRDBF     FILE(HIOBJGL) TOFILE(QTEMP/HIOBJGL)
              ENDDO
              ELSE       CMD(DO)
               CALL       PGM(HCRTLF) PARM('HIOBJGL50')
               OVRDBF     FILE(HIOBJGL50) TOFILE(QTEMP/HIOBJGL50)
              ENDDO
             ENDDO

/*           Create files if *IFS or *ALL configuration requested    */
             IF         COND(&CFGTYP *EQ '*IFS' *OR &CFGTYP *EQ +
                          '*ALL') THEN(DO)
/*            Create files for iCluster                              */
              CALL       PGM(HCRTLF) PARM('HIBSFGN')
              OVRDBF     FILE(HIBSFGN) TOFILE(QTEMP/HIBSFGN)
             ENDDO

/*           Check/create output file for groups                     */
             CHKOBJ     OBJ(&OUTLIB/HLSTCFGG) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CPYF       FROMFILE(&UTLLIB/HLSTCFGG) +
                          TOFILE(&OUTLIB/HLSTCFGG) CRTFILE(*YES)
             ENDDO
             CLRPFM     FILE(&OUTLIB/HLSTCFGG)
             RCVMSG     MSGTYPE(*LAST)
             OVRDBF     FILE(HLSTCFGG) TOFILE(&OUTLIB/HLSTCFGG)

/*           Check/create output file if *OBJ                        */
             IF         COND(&CFGTYP *EQ '*OBJ' *OR &CFGTYP *EQ +
                          '*ALL') THEN(DO)
              CHKOBJ     OBJ(&OUTLIB/HLSTCFGO) OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CPYF       FROMFILE(&UTLLIB/HLSTCFGO) +
                          TOFILE(&OUTLIB/HLSTCFGO) CRTFILE(*YES)
              ENDDO
              CLRPFM     FILE(&OUTLIB/HLSTCFGO)
              RCVMSG     MSGTYPE(*LAST)
              OVRDBF     FILE(HLSTCFGO) TOFILE(&OUTLIB/HLSTCFGO)
             ENDDO

/*           Check/create output file if *IFS                        */
             IF         COND(&CFGTYP *EQ '*IFS' *OR &CFGTYP *EQ +
                          '*ALL') THEN(DO)
              CHKOBJ     OBJ(&OUTLIB/HLSTCFGI) OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CPYF       FROMFILE(&UTLLIB/HLSTCFGI) +
                          TOFILE(&OUTLIB/HLSTCFGI) CRTFILE(*YES)
              ENDDO
              CLRPFM     FILE(&OUTLIB/HLSTCFGI)
              RCVMSG     MSGTYPE(*LAST)
              OVRDBF     FILE(HLSTCFGI) TOFILE(&OUTLIB/HLSTCFGI)
             ENDDO

/*           Fill file with object specifiers                        */
             CALL       PGM(HLSTCFG1) PARM(&ICGROUP &CFGTYP &SYSNAME +
                          &BCKNOD &MRKSTR &ICVER)

             DLTOVR     FILE(HLSTCFGG)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTOVR     FILE(HLSTCFGO)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTOVR     FILE(HLSTCFGI)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Send completion message                                 */
             SNDPGMMSG  MSGID(LCF0004) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &OUTLIB || &CFGTYP) MSGTYPE(*COMP)

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
