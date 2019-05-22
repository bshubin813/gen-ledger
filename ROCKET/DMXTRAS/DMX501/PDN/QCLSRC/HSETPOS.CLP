/* ================================================================= */
/* Object:         HSETPOS         *PGM CLP                          */
/*                 Sets the iCluster group position to               */
/*                 last position + 1.                                */
/*                                                                   */
/* Synopsis:       This program reads the HAPID file on the remote   */
/*                 (target) computer and determines the journal      */
/*                 position(s) that was/were last applied.           */
/*                 Subsequently it sets the position to the last     */
/*                 applied journal entry + 1.                        */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030106 FK  Initial delivery                                     */
/* 20030710 FK  Enable for iCluster                                  */
/*              Role of target definition is no longer checked       */
/* 20050429 FK  Delete used LFs at end and RCLDDMCNV                 */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &RMTHOST &PASSWORD &ACTION &JRNQ)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RMTHOST) TYPE(*CHAR) LEN(100)
             DCL        VAR(&PASSWORD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&HAVER) TYPE(*CHAR) LEN(6)
             DCL        VAR(&ICVER) TYPE(*CHAR) LEN(6)

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(512)
             DCL        VAR(&GRPCHK) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)

             DCL        VAR(&QRETSVRSEC) TYPE(*CHAR) LEN(1)

             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Get utilities and product library                       */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           iClsuter must be in the library list                    */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Group must exist and must not be active                 */
             HRTVSTS    ICGROUP(&ICGROUP) PRCTYP(*SND) STATUS(&STATUS)
/*           Send error message if target/group not found            */
             IF         COND(&STATUS *EQ '*ERROR') THEN(SNDPGMMSG +
                          MSGID(SPS0003) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP) MSGTYPE(*ESCAPE))
             ELSE       CMD(DO)
              IF         COND(&STATUS *NE '*INACTIVE') THEN(SNDPGMMSG +
                          MSGID(SPS0004) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP || &STATUS) MSGTYPE(*ESCAPE))
             ENDDO

/*           Check if security data is kept with server entry        */
             RTVSYSVAL  SYSVAL(QRETSVRSEC) RTNVAR(&QRETSVRSEC)
             IF         COND(&QRETSVRSEC *NE '1' *AND &PASSWORD *NE +
                          '*NONE') THEN(SNDPGMMSG MSGID(SPS0006) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Change the current user's server authorisation for DDM  */
             IF         COND(&PASSWORD *NE '*NONE') THEN(DO)
              CHGSVRAUTE USRPRF(*CURRENT) SERVER(QDDMSERVER) +
                          PASSWORD(&PASSWORD)
              MONMSG     MSGID(CPF225E) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               ADDSVRAUTE USRPRF(*CURRENT) SERVER(QDDMSERVER) +
                          PASSWORD(&PASSWORD)
              ENDDO
             ENDDO

/*           Create DDM file for remote commands                     */
             DLTF       FILE(QTEMP/HUPIDTGJ)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDDMF    FILE(QTEMP/HUPIDTGJ) RMTFILE(QTEMP/HUPIDTGJ) +
                          RMTLOCNAME(&RMTHOST *IP) TEXT('HSETPOS - +
                          DDM file retrieving remote HAPID records')

/*           Create remote HUPIDTGJ file                             */
             CHGVAR     VAR(&CMD) VALUE('CALL PGM(' || &UTLLIB |< +
                          '/HSETPOS2) PARM(' |< &UTLLIB |> &ICLIB +
                          |< ')')
             SBMRMTCMD  CMD(&CMD) DDMFILE(QTEMP/HUPIDTGJ)
             MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(SPS0007) +
                          MSGF(HAUMSG) MSGDTA(&RMTHOST) +
                          MSGTYPE(*ESCAPE))

/*           Call program that displays/sets the positions           */
             CHGCURLIB  CURLIB(&ICLIB)
             OVRDBF     FILE(HUPIDTGJ) TOFILE(QTEMP/HUPIDTGJ)
             CALL       PGM(HSETPOS1) PARM(&ICGROUP &ACTION &JRNQ +
                          &RTNCDE)
             DLTOVR     FILE(HUPIDTGJ)

/*           Clean-up file in QTEMP                                  */
             RCLDDMCNV
             DLTF       FILE(QTEMP/HUPIDTGJ)
             MONMSG     MSGID(CPF0000)

/*           Clean-up remaining files in QTEMP                       */
             CALL       PGM(HCRTLFDLT) PARM('*ALL' '*ALL')

/*           If some positions could not be retrieved --> error      */
             IF         COND(&RTNCDE *NE ' ') THEN(SNDPGMMSG +
                          MSGID(SPS0015) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP || &JRNQ || &ACTION) +
                          MSGTYPE(*ESCAPE))

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
