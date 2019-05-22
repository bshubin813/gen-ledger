/* ================================================================= */
/* Object:         HRTVJSE         *PGM CLP                          */
/*                 Command processing program for HRTVJSE.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990809 FK  Initial delivery                                     */
/* 19991201 FK  Allow immediate sending to target using SNDHAOBJ.    */
/* ================================================================= */
             PGM        PARM(&USRSPCQ &JOB &TEXT &TARGET)

/*           Parameter variables                                     */
             DCL        VAR(&USRSPCQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TEXT) TYPE(*CHAR) LEN(50)
             DCL        VAR(&TARGET) TYPE(*CHAR) LEN(10)

/*           Program variables                                       */
             DCL        VAR(&USRSPC) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USRSPCL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CONHDL) TYPE(*CHAR) LEN(16) VALUE(' ')

             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)

/* ----------------------------------------------------------------- */
/*           Global monitoring (if any)                              */
/* ----------------------------------------------------------------- */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVNETA    SYSNAME(&SYSNAME)

/*           Convert special values for USRSPC                       */
             IF         COND(%SST(&USRSPCQ 1 10) *EQ '*SYSNAME') +
                          THEN(CHGVAR VAR(%SST(&USRSPCQ 1 10)) +
                          VALUE(&SYSNAME))

/*           Split &USRSPCQ variable into name and library           */
             CHGVAR     VAR(&USRSPC) VALUE(%SST(&USRSPCQ 1 10))
             CHGVAR     VAR(&USRSPCL) VALUE(%SST(&USRSPCQ 11 10))

/*           Determine text if *DFTTXT                               */
             IF         COND(&TEXT *EQ '*DFT') THEN(RTVMSG +
                          MSGID(JRT0001) MSGF(HAUMSG) MSGDTA(&JOB +
                          || &SYSNAME) MSG(&TEXT))

/*           Create user space in specified library                  */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QUSCRTUS) PARM(&USRSPCQ 'HRTVJSE' +
                          X'000003F8' ' ' '*ALL' &TEXT '*YES' &APIERR)

/*           Retrieve job schedule entries into user space           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QWCLSCDE) PARM(&USRSPCQ 'SCDL0200' &JOB +
                          &CONHDL &APIERR)

/*           Send user space to target immediately, if specified     */
             IF         COND(&TARGET *NE '*NONE') THEN(DO)
              SNDHAOBJ   TARGET(&TARGET) OBJ(&USRSPCL/&USRSPC) +
                          OBJTYPE(*USRSPC)
             ENDDO

/*           Send completion message                                 */
             SNDPGMMSG  MSGID(JRT0002) MSGF(HAUMSG) MSGDTA(&USRSPCQ +
                          || &JOB) MSGTYPE(*COMP)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Move all *DIAG messages to the previous queue           */
 ERROR:      CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
