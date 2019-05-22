/* ================================================================= */
/* Object:         HSNDFTP         *PGM CLP                          */
/*                 Sends save file to remote computer through FTP.   */
/*                                                                   */
/* Create remarks:                                                   */
/*                                                                   */
/* Synopsis:       Generates an FTP script based on the input        */
/*                 parameters and executes it.                       */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010624 FK  Initial delivery                                     */
/* 20020307 FK  Create save file with description                    */
/* 20030616 FK  Log errors and report if any errors                  */
/* 20030710 FK  Be more specific on type of error encountered        */
/* ================================================================= */
             PGM        PARM(&SAVFQ &RMTHOST &PASSWORD &USRPRF &BATCH)

/*           Declare parameter variables                              */
             DCL        VAR(&SAVFQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RMTHOST) TYPE(*CHAR) LEN(100)
             DCL        VAR(&PASSWORD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USRPRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&SAVF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TEXT) TYPE(*CHAR) LEN(50)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)
             DCL        VAR(&REASON) TYPE(*CHAR) LEN(80)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)

/*           Convert *CURRENT user profile                           */
             IF         COND(&USRPRF *EQ '*CURRENT') THEN(RTVUSRPRF +
                          USRPRF(*CURRENT) RTNUSRPRF(&USRPRF))

/*           Split qualifiers                                        */
             CHGVAR     VAR(&SAVF) VALUE(%SST(&SAVFQ 1 10))
             CHGVAR     VAR(&SAVFL) VALUE(%SST(&SAVFQ 11 10))

/*           Retrieve save file library                              */
             RTVOBJD    OBJ(&SAVFL/&SAVF) OBJTYPE(*FILE) +
                          RTNLIB(&SAVFL) TEXT(&TEXT)
             CHGVAR     VAR(&SAVFQ) VALUE(&SAVF || &SAVFL)

/*           Submit job to batch if specified                        */
             IF         COND(&BATCH *EQ '*YES' *AND &JOBTYPE *EQ +
                          '1') THEN(DO)
              SBMJOB     CMD(HSNDFTP SAVF(&SAVFL/&SAVF) +
                          RMTHOST(&RMTHOST) USRPRF(&USRPRF) +
                          PASSWORD(&PASSWORD)) JOB(&SAVF) +
                          JOBD(HAUTILS) INLLIBL(*JOBD)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Copy temporary file into QTEMP                          */
             DLTF       FILE(QTEMP/HFTPSRC)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             CPYF       FROMFILE(HFTPSRC) TOFILE(QTEMP/HFTPSRC) +
                          CRTFILE(*YES)
             ADDPFM     FILE(QTEMP/HFTPSRC) MBR(HSNDFTP) +
                          TEXT('Temporary FTP script for sending +
                          save file')
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             CLRPFM     FILE(QTEMP/HFTPSRC) MBR(HSNDFTP)
             OVRDBF     FILE(HFTPSRC) TOFILE(QTEMP/HFTPSRC) +
                          MBR(HSNDFTP)

/*           Call program to generate FTP script                     */
             CALL       PGM(HSNDFTP1) PARM(&SAVFQ &TEXT &RMTHOST +
                          &USRPRF &PASSWORD)
             DLTOVR     FILE(HFTPSRC)

/*           Execute the FTP script                                  */
             OVRDBF     FILE(INPUT) TOFILE(QTEMP/HFTPSRC) MBR(HSNDFTP)
             OVRDBF     FILE(OUTPUT) TOFILE(QTEMP/HFTPSRC) MBR(HSNDFTPLOG)
             FTP        RMTSYS(&RMTHOST)
             DLTOVR     FILE(INPUT)
             DLTOVR     FILE(OUTPUT)

/*           Remove the ftp script for security reasons              */
             RMVM       FILE(QTEMP/HFTPSRC) MBR(HSNDFTP)

/*           Check if any errors were report                         */
             OVRDBF     FILE(HFTPSRC) TOFILE(QTEMP/HFTPSRC) +
                          MBR(HSNDFTPLOG)
             CALL       PGM(HSNDFTP2) PARM(&RTNCDE &REASON)
             DLTOVR     FILE(HFTPSRC)
             IF         COND(&RTNCDE *NE ' ') THEN(DO)
/*            Print ftp log                                          */
              OVRPRTF    FILE(QSYSPRT) SPLFNAME(HSNDFTP)
              CPYSRCF    FROMFILE(QTEMP/HFTPSRC) TOFILE(*PRINT) +
                          FROMMBR(HSNDFTPLOG)
              MONMSG     MSGID(CPF0000)
              DLTOVR     FILE(QSYSPRT)
              SNDPGMMSG  MSGID(SFT0002) MSGF(HAUMSG) MSGDTA(&SAVFQ || +
                          &RMTHOST || &REASON) MSGTYPE(*ESCAPE)
             ENDDO

/*           Delete the temporary file                               */
             DLTF       FILE(QTEMP/HFTPSRC)

/*           Send completion message                                 */
             SNDPGMMSG  MSGID(SFT0001) MSGF(HAUMSG) MSGDTA(&SAVFQ || +
                          &RMTHOST)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     ' +
                          X'00000001' '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
