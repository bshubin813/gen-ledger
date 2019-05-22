/* ================================================================= */
/* Object:         TPUTDTS         *PGM CLP                          */
/*                 This program puts the current date-time into a    */
/*                 file on a periodic basis. Command is useful for   */
/*                 verifying the status of replication of TS.        */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010531 FK  Initial delivery                                     */
/* 20051115 FK  Allow to specify file name                           */
/*              Automatically create file if it doesn't exist        */
/* 20070122 FK  Allow to specify journal                             */
/* ================================================================= */
             PGM        PARM(&LIB &PUTITV &KEY &FILE &JRNQ)

/*           Declare parameter variables                              */
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PUTITV) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&KEY) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&PUTITV@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENDSTS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&MSGKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STSKEY) TYPE(*CHAR) LEN(4)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNSTS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&CURJRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURJRNL) TYPE(*CHAR) LEN(10)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000 SJP0000) EXEC(GOTO +
                          CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))

/*           Check existence of journal, if specified                */
             IF         COND(&JRN *NE '*NOCHG') THEN(DO)
              RTVOBJD    OBJ(&JRNL/&JRN) OBJTYPE(*JRN) RTNLIB(&JRNL)
             ENDDO

/*           Check existence of physical file                        */
             RTVOBJD    OBJ(&LIB/&FILE) OBJTYPE(*FILE) +
                          JRNSTS(&JRNSTS) JRN(&CURJRN) JRNLIB(&CURJRNL)
             MONMSG     MSGID(CPF9800) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDUPOBJ  OBJ(TPUTDTS) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(QTEMP) NEWOBJ(&FILE) DATA(*NO)
/*            Start journaling for file in question                  */
              IF         COND(&JRN *NE '*NOCHG') THEN(DO)
               HSTRJRNPF  FILE(QTEMP/&FILE) JRN(&JRNL/&JRN) +
                          IMAGES(*BOTH) RESTART(*YES) BATCH(*NO)
               CHGVAR     VAR(&JRNSTS) VALUE('1')
               CHGVAR     VAR(&CURJRN) VALUE(&JRN)
               CHGVAR     VAR(&CURJRNL) VALUE(&JRNL)
              ENDDO
/*            Move file to final destination                         */
              MOVOBJ     OBJ(QTEMP/&FILE) OBJTYPE(*FILE) TOLIB(&LIB)
             ENDDO

/*           If journal not same as specified, re-journal            */
             IF         COND(&JRN *NE '*NOCHG' *AND (&JRNSTS *EQ '0' +
                          *OR &CURJRN *NE &JRN *OR &CURJRNL *NE +
                          &JRNL)) THEN(DO)
              SNDPGMMSG  MSGID(PDT0002) MSGF(HAUMSG) MSGDTA(&FILE || +
                          &LIB || &JRN || &JRNL) MSGTYPE(*DIAG)
              HSTRJRNPF  FILE(&LIB/&FILE) JRN(&JRNL/&JRN) +
                          IMAGES(*BOTH) RESTART(*YES) BATCH(*NO)
             ENDDO

/*           If the job is interactive --> submit the job            */
             IF         COND(&JOBTYPE *EQ '1' *AND &PUTITV *NE 0) +
                          THEN(DO)
              SBMJOB     CMD(TPUTDTS FILE(&FILE) LIB(&LIB) +
                          PUTITV(&PUTITV) KEY(&KEY) +
                          JRN(&JRNL/&JRN)) JOB(&FILE) JOBD(TPUTDTS) +
                          JOBQ(*JOBD) INLLIBL(*JOBD)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Initialise date format                                  */
             CHGJOB     DATFMT(*YMD)

/*           Override file                                           */
             OVRDBF     FILE(TPUTDTS) TOFILE(&LIB/&FILE)

/*           Write/update record in file                             */
 LOOPITV:    CALL       PGM(TPUTDTS1) PARM(&KEY)

/*           If interval set --> wait until next interval            */
             IF         COND(&PUTITV *NE 0) THEN(DO)
              CHGVAR     VAR(%BIN(&PUTITV@)) VALUE(&PUTITV)
              SNDPGMMSG  MSGID(PDT0001) MSGF(HAUMSG) MSGDTA(&PUTITV@) +
                          TOPGMQ(*SAME) KEYVAR(&STSKEY)
              RCVMSG     MSGTYPE(*NEXT) MSGKEY(&STSKEY) WAIT(&PUTITV) +
                          KEYVAR(&MSGKEY)
/*            Delay the job 1 second to update status                */
              DLYJOB     DLY(1)
/*            Remove status message to not confuse operator          */
              RMVMSG     MSGKEY(&STSKEY)
              MONMSG     MSGID(CPF0000)
/*            If job/subsystem or system ended --> quit, else loop   */
              RTVJOBA    ENDSTS(&ENDSTS)
              IF         COND(&ENDSTS *EQ '0') THEN(GOTO CMDLBL(LOOPITV))
             ENDDO

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
