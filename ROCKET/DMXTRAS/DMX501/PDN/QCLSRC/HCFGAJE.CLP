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
/* 20020515 FK  Initial delivery                                     */
/* 20030116 FK  Allow start of AJE                                   */
/* ================================================================= */
             PGM        PARM(&JOBDQ &JOB &SBSDQ &STRAJE)

/*           Declare parameter variables                              */
             DCL        VAR(&JOBDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBSDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&STRAJE) TYPE(*CHAR) LEN(4)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JOBD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBDL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBSD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBSDL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JOBD0100) TYPE(*CHAR) LEN(1024)
             DCL        VAR(&RQSDTA) TYPE(*CHAR) LEN(256)
             DCL        VAR(&RQSDTAL) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&RQSDTAO) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&RCVLEN) TYPE(*CHAR) LEN(4)

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(512)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JOBD) VALUE(%SST(&JOBDQ 1 10))
             CHGVAR     VAR(&JOBDL) VALUE(%SST(&JOBDQ 11 10))
             CHGVAR     VAR(&SBSD) VALUE(%SST(&SBSDQ 1 10))
             CHGVAR     VAR(&SBSDL) VALUE(%SST(&SBSDQ 11 10))

/*           Check existence of job description and subsystem        */
             RTVOBJD    OBJ(&JOBDL/&JOBD) OBJTYPE(*JOBD) RTNLIB(&JOBDL)
             IF         COND(&JOB *NE '*NONE') THEN(RTVOBJD +
                          OBJ(&SBSDL/&SBSD) OBJTYPE(*SBSD) +
                          RTNLIB(&SBSDL))

/*           Translate special value                                 */
             IF         COND(&JOB *EQ '*JOBD') THEN(CHGVAR VAR(&JOB) +
                          VALUE(&JOBD))

/*           Retrieve job description request data                    */
             CHGVAR     VAR(&JOBDQ) VALUE(&JOBD || &JOBDL)
             CHGVAR     VAR(%BIN(&RCVLEN)) VALUE(1024)
             CALL       PGM(QWDRJOBD) PARM(&JOBD0100 &RCVLEN +
                          'JOBD0100' &JOBDQ &APIERR)
             CHGVAR     VAR(&RQSDTAO) VALUE(%BIN(&JOBD0100 369 4) + 1)
             CHGVAR     VAR(&RQSDTAL) VALUE(%BIN(&JOBD0100 373 4))
             CHGVAR     VAR(&RQSDTA) VALUE(%SST(&JOBD0100 &RQSDTAO +
                          &RQSDTAL))

/*           If request data not a command --> error                  */
             IF         COND(%SST(&RQSDTA 1 1) *EQ '*') +
                          THEN(SNDPGMMSG MSGID(CAJ0001) +
                          MSGF(HAUMSG) MSGDTA(&JOBDQ) MSGTYPE(*ESCAPE))

/*           Make up promptable command                               */
             CHGVAR     VAR(&CMD) VALUE('?' |> &RQSDTA)
             CALL       PGM(QCMDCHK) PARM(&CMD 512)

/*           Change job description                                   */
             CHGJOBD    JOBD(&JOBDL/&JOBD) RQSDTA(&CMD)

/*           Change subsystem AJE if required                         */
             IF         COND(&JOB *NE '*NONE') THEN(DO)
              RMVAJE     SBSD(&SBSDL/&SBSD) JOB(&JOB)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ADDAJE     SBSD(&SBSDL/&SBSD) JOB(&JOB) JOBD(&JOBDL/&JOBD)
             ENDDO

/*           Start job if specified                                   */
             IF         COND(&STRAJE *EQ '*YES') THEN(DO)
              SBMJOB     JOB(&JOB) JOBD(&JOBDL/&JOBD) USER(*JOBD) +
                          RQSDTA(*JOBD) CURLIB(*USRPRF) INLLIBL(*JOBD)
             ENDDO

/*           Send completion message                                 */
             IF         COND(&JOB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(CAJ0002) MSGF(HAUMSG) MSGDTA(&JOBDQ))
             IF         COND(&JOB *NE '*NONE') THEN(SNDPGMMSG +
                          MSGID(CAJ0003) MSGF(HAUMSG) MSGDTA(&JOBDQ +
                          || &JOB || &SBSD || &SBSDL))
             IF         COND(&STRAJE *EQ '*YES') THEN(SNDPGMMSG +
                          MSGID(CAJ0004) MSGF(HAUMSG) MSGDTA(&JOBDQ +
                          || &JOB || &SBSD || &SBSDL))

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
