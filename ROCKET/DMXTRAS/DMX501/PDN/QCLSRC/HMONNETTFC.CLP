/* ================================================================= */
/* Object:         HMONNETTFC      *PGM CLP                          */
/*                 Monitors the traffic of incoming and outgoing     */
/*                 traffic over the specified port.                  */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20051216 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&FILEQ &PORT &PORTLOC &RMTADR &CHKITV)

/*           Declare parameter variables                              */
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&PORT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&PORTLOC) TYPE(*CHAR) LEN(7)
             DCL        VAR(&RMTADR) TYPE(*CHAR) LEN(15)
             DCL        VAR(&CHKITV) TYPE(*DEC) LEN(5 0)

/*           Constants                                               */

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CHKITV@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENDSTS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&JOBTYP) TYPE(*CHAR) LEN(1)

             DCL        VAR(&MSGKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STSKEY) TYPE(*CHAR) LEN(4)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initalisation                                           */
             RTVNETA    SYSNAME(&SYSNAM)
             RTVJOBA    TYPE(&JOBTYP)

/*           Retrieve product library                                */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&FILE) VALUE(%SST(&FILEQ 1 10))
             CHGVAR     VAR(&FILEL) VALUE(%SST(&FILEQ 11 10))

/*           Create output file if it doesn't exist yet              */
             CHKOBJ     OBJ(&FILEL/&FILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDUPOBJ  OBJ(HNETTFC) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(&FILEL) NEWOBJ(&FILE) DATA(*NO)
             ENDDO

/*           If the job is run interactively --> submit              */
             IF         COND(&JOBTYP *EQ '1') THEN(DO)
              SBMJOB     CMD(HMONNETTFC FILE(&FILEL/&FILE) +
                          PORT(&PORT) PORTLOC(&PORTLOC) +
                          RMTADR(&RMTADR) CHKITV(&CHKITV)) +
                          JOB(HMONNETTFC) JOBD(HAUTILS)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Make sure proper output file is used                    */
             OVRDBF     FILE(HNETTFC) TOFILE(&FILEL/&FILE) SHARE(*NO)

/*           Create user space to contain netstat entries            */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QUSCRTUS) PARM('HMONNETTFCQTEMP     ' +
                          'HMONNETTFC' X'00FFF000' X'00' '*ALL' +
                          'HMONNETTFC - Netstat output' '*YES' &APIERR)

 LOOP:       CALL       PGM(HMONNET1) PARM(&SYSNAM &PORT &PORTLOC +
                          &RMTADR)

/*           Now wait for specified interval (if required)           */
             CHGVAR     VAR(%BIN(&CHKITV@)) VALUE(&CHKITV)
             SNDPGMMSG  MSGID(MNT0001) MSGF(HAUMSG) MSGDTA(&CHKITV@) +
                          TOPGMQ(*SAME) KEYVAR(&STSKEY)
             RCVMSG     MSGTYPE(*NEXT) MSGKEY(&STSKEY) WAIT(&CHKITV) +
                          KEYVAR(&MSGKEY)
/*           Delay the job 1 second to update status                 */
             DLYJOB     DLY(1)
/*           Remove status message to not confuse operator           */
             RMVMSG     MSGKEY(&STSKEY)
             MONMSG     MSGID(CPF0000)
/*           If job/subsystem or system ended --> quit, else loop    */
             RTVJOBA    ENDSTS(&ENDSTS)
             IF         COND(&ENDSTS *EQ '0') THEN(GOTO CMDLBL(LOOP))

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
