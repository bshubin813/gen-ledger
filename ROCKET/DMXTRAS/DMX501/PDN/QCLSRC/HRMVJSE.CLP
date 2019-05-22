/* ================================================================= */
/* Object:         HRMVJSE         *PGM CLP                          */
/*                 Command processing program for HRMVJSE.           */
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
/* ================================================================= */
             PGM        PARM(&JSEID &JOB)

/*           Parameter variables                                     */
             DCL        VAR(&JSEID) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)

/*           Constants                                               */
             DCL        VAR(&USRSPC) TYPE(*CHAR) LEN(20) +
                          VALUE('HRMVJSE   QTEMP     ')

/*           Program variables                                       */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)

             DCL        VAR(&LSTHDR) TYPE(*CHAR) LEN(140)
             DCL        VAR(&I) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&STRLST) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRENT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&STRPOS@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LSTENT) TYPE(*CHAR) LEN(1157)

             DCL        VAR(&JSEJOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JSENBR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JSETXT) TYPE(*CHAR) LEN(50)

             DCL        VAR(&NBRRMV) TYPE(*DEC) LEN(5 0) VALUE(0)
             DCL        VAR(&NBRRMV@) TYPE(*CHAR) LEN(4)

/* ----------------------------------------------------------------- */
/*           Global monitoring (if any)                              */
/* ----------------------------------------------------------------- */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve job schedule entries into QTEMP user space     */
             HRTVJSE    JOB(&JOB) USRSPC(QTEMP/HRMVJSE) +
                          TEXT('HRMVJSE - Job schedule entries')

/*           Retrieve user space header information                  */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QUSRTVUS) PARM(&USRSPC X'00000001' +
                          X'0000008C' &LSTHDR &APIERR)
             CHGVAR     VAR(&STRLST) VALUE(%BIN(&LSTHDR 125 4) + 1)
             CHGVAR     VAR(&NBRENT) VALUE(%BIN(&LSTHDR 133 4))
             CHGVAR     VAR(&ENTSIZ) VALUE(%BIN(&LSTHDR 137 4))
             CHGVAR     VAR(&ENTSIZ@) VALUE(%SST(&LSTHDR 137 4))

/*           Read entries until end reached                          */
             CHGVAR     VAR(&I) VALUE(1)
 LOOP:       IF         COND(&I *LE &NBRENT) THEN(DO)
/*            Retrieve entry                                         */
              CHGVAR     VAR(&STRPOS) VALUE(&STRLST + ((&I - 1) * +
                          &ENTSIZ))
              CHGVAR     VAR(%BIN(&STRPOS@)) VALUE(&STRPOS)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&USRSPC &STRPOS@ &ENTSIZ@ +
                          &LSTENT &APIERR)

/*            Extract variables                                      */
              CHGVAR     VAR(&JSEJOB) VALUE(%SST(&LSTENT 2 10))
              CHGVAR     VAR(&JSENBR) VALUE(%SST(&LSTENT 12 10))
              CHGVAR     VAR(&JSETXT) VALUE(%SST(&LSTENT 244 50))

/*            If entry matches, remove                               */
              IF         COND(%SST(&JSETXT 1 10) *EQ &JSEID) THEN(DO)
/*             Remove entry                                          */
               RMVJOBSCDE JOB(&JSEJOB) ENTRYNBR(&JSENBR)
               MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXT))
               CHGVAR     VAR(&NBRRMV) VALUE(&NBRRMV + 1)
              ENDDO

 NEXT:        CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOP)
             ENDDO

/*           Remove user space from QTEMP                            */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QUSDLTUS) PARM(&USRSPC &APIERR)

/*           Send completion message                                 */
             CHGVAR     VAR(%BIN(&NBRRMV@)) VALUE(&NBRRMV)
             SNDPGMMSG  MSGID(JRM0001) MSGF(HAUMSG) MSGDTA(&JSEID || +
                          &JOB || &NBRRMV@) MSGTYPE(*COMP)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Move all *DIAG messages to the previous queue           */
 ERROR:      CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)
             MONMSG     MSGID(CPF0000)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)
             MONMSG     MSGID(CPF0000)

 END:        ENDPGM
