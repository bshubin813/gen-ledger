/* ================================================================= */
/* Object:         HSUSACTF        *PGM CLP                          */
/*                 Command processing program for HSUSACTF.          */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000410 FK  Initial delivery                                     */
/* 20020625 FK  Allow generic names for file                         */
/* 20030605 FK  Enable for iCluster                                  */
/* 20050429 FK  Delete LFs in the end                                */
/* 20111222 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&FILEQ &ACTION &RFSH &ICGROUP)

/*           Declare parameter variables                             */
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RFSH) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USRLIBL) TYPE(*CHAR) LEN(275)
             DCL        VAR(&CURLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(512)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifier variables                               */
             CHGVAR     VAR(&FILE) VALUE(%SST(&FILEQ 1 10))
             CHGVAR     VAR(&FILEL) VALUE(%SST(&FILEQ 11 10))

/*           If not *ALLSUS --> library is mandatory                 */
             IF         COND(&FILE *NE '*ALLSUS' *AND &FILEL *EQ ' +
                          ') THEN(SNDPGMMSG MSGID(SAF0008) +
                          MSGF(HAUMSG) MSGDTA(&FILE) MSGTYPE(*ESCAPE))

/*           Does the file library exist?                            */
             IF         COND(&FILEL *NE ' ') THEN(CHKOBJ OBJ(&FILEL) +
                          OBJTYPE(*LIB))

/*           Make sure that library list is retained                 */
             RTVJOBA    USRLIBL(&USRLIBL) CURLIB(&CURLIB)
             IF         COND(&CURLIB *EQ '*NONE') THEN(CHGVAR +
                          VAR(&CURLIB) VALUE('*CRTDFT'))

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0014) MSGF(HAUMSG) MSGTYPE(*ESCAPE))
             ADDLIBLE   LIB(&ICLIB)
             MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))
             ADDLIBLE   LIB(&UTLLIB)
             MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Create necessary files in QTEMP in case of *SEARCH      */
             IF         COND(&ICGROUP *EQ '*SEARCH') THEN(DO)
              CALL       PGM(HCRTLF) PARM('HUMOBOL')
              CALL       PGM(HCRTLF) PARM('HUTGTTI')
              CALL       PGM(HCRTLF) PARM('HUGRPGI')
              OVRDBF     FILE(HUMOBOL) TOFILE(QTEMP/HUMOBOL)
              OVRDBF     FILE(HUTGTTI) TOFILE(QTEMP/HUTGTTI)
              OVRDBF     FILE(HUGRPGI) TOFILE(QTEMP/HUGRPGI)
             ENDDO
             ELSE       CMD(DO)
/*            Create file in QTEMP to hold file descriptions         */
              CLRPFM     FILE(QTEMP/HSUSACTF)
              MONMSG     MSGID(CPF3142) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CPYF       FROMFILE(HSUSACTF) TOFILE(QTEMP/HSUSACTF) +
                          CRTFILE(*YES)
              ENDDO
             ENDDO

/*           Call program that processes HAMOBJ                      */
             IF         COND(&ICGROUP *EQ '*SEARCH') THEN(DO)
              CALL       PGM(HSUSACT1) PARM(&FILEQ &ACTION &RFSH +
                          &ICGROUP &ICLIB &RTNCDE)
             ENDDO
/*           Call program that activates/suspends objects by fd      */
             IF         COND(&ICGROUP *NE '*SEARCH') THEN(DO)
              CALL       PGM(HSUSACT3) PARM(&ICGROUP &FILE &FILEL +
                          &ACTION &RFSH &ICLIB &RTNCDE)
             ENDDO

/*           Delete H* files in QTEMP when interactive               */
             CALL       PGM(HCRTLFDLT) PARM('*ALL' '*INT')

/*           Error handling of subprogram                            */
             IF         COND(&RTNCDE *NE ' ') THEN(DO)
/*            Move all *DIAG messages to the previous queue          */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)
              SNDPGMMSG  MSGID(&RTNCDE) MSGF(HAUMSG) MSGDTA(&FILEQ) +
                          MSGTYPE(*ESCAPE)
             ENDDO

/*           Restore library list                                    */
             CHGVAR     VAR(&CMD) VALUE('CHGLIBL LIBL(' |< &USRLIBL +
                          |< ') CURLIB(' |< &CURLIB |< ')')
             CALL       PGM(QCMDEXC) PARM(&CMD 512)

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
