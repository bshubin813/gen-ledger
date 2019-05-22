/* ================================================================= */
/* Object:         HMONJOBADD      *PGM CLP                          */
/*                 Command processing program for HMONJOBADD         */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050707 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&SBSDQ &DTAQQ)

/*           Declare parameter variables                             */
             DCL        VAR(&SBSDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DTAQQ) TYPE(*CHAR) LEN(20)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&SBSD) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBSDL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DTAQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DTAQL) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&SBSD) VALUE(%SST(&SBSDQ 1 10))
             CHGVAR     VAR(&SBSDL) VALUE(%SST(&SBSDQ 11 10))
             CHGVAR     VAR(&DTAQ) VALUE(%SST(&DTAQQ 1 10))
             CHGVAR     VAR(&DTAQL) VALUE(%SST(&DTAQQ 11 10))

/*           Check for existence of the data queue library           */
             CHKOBJ     OBJ(&DTAQL) OBJTYPE(*LIB)

/*           Retrieve product library                                */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Create data queue if not existing                       */
             CHKOBJ     OBJ(&DTAQL/&DTAQ) OBJTYPE(*DTAQ)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDTAQ    DTAQ(&DTAQL/&DTAQ) TYPE(*STD) MAXLEN(144) +
                          SEQ(*KEYED) KEYLEN(4) AUTORCL(*YES) +
                          TEXT('HMONJOB - Monitored jobs status +
                          changes')
             ENDDO

/*           Add exit program                                        */
             ADDEXITPGM EXITPNT(QIBM_QWT_JOBNOTIFY) FORMAT(NTFY0100) +
                          PGMNBR(*LOW) PGM(&DTAQL/&DTAQ) +
                          TEXT('DMXtras HMONJOB - Monitor active +
                          jobs') PGMDTA(*JOB 24 ('0007' || &SBSD || +
                          &SBSDL))
             SNDPGMMSG  MSGID(MJO0001) MSGF(HAUMSG) MSGDTA(&SBSDQ || +
                          &DTAQQ) MSGTYPE(*COMP)

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
