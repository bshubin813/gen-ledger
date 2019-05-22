/* ================================================================= */
/* Object:         HCHGJSE1        *PGM CLP                          */
/*                 Holds or restores the status of job schedule      */
/*                 entries according to user space.                  */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030711 FK  Initial delivery                                     */
/* 20030904 FK  Status was not taken into account when resetting     */
/* ================================================================= */
             PGM        PARM(&ACTION &USRSPCQ &NBRPRC)

/*           Parameter variables                                     */
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&USRSPCQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&NBRPRC) TYPE(*DEC) LEN(7 0)

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
             DCL        VAR(&JSESTS) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JOBD0100) TYPE(*CHAR) LEN(1024)

/* ----------------------------------------------------------------- */
/*           Global monitoring (if any)                              */
/* ----------------------------------------------------------------- */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRPRC) VALUE(0)

/*           Retrieve user space header information                  */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QUSRTVUS) PARM(&USRSPCQ X'00000001' +
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
              CALL       PGM(QUSRTVUS) PARM(&USRSPCQ &STRPOS@ &ENTSIZ@ +
                          &LSTENT &APIERR)

/*            Extract variables                                      */
              CHGVAR     VAR(&JSEJOB) VALUE(%SST(&LSTENT 2 10))
              CHGVAR     VAR(&JSENBR) VALUE(%SST(&LSTENT 12 10))
              CHGVAR     VAR(&JSESTS) VALUE(%SST(&LSTENT 188 10))

              IF         COND(&ACTION *EQ '*HLD') THEN(DO)
               HLDJOBSCDE JOB(&JSEJOB) ENTRYNBR(&JSENBR)
               MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXT))
               CHGVAR     VAR(&NBRPRC) VALUE(&NBRPRC + 1)
              ENDDO
              IF         COND(&ACTION *EQ '*RST' *AND &JSESTS *NE +
                          'HLD') THEN(DO)
               RLSJOBSCDE JOB(&JSEJOB) ENTRYNBR(&JSENBR)
               MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXT))
               CHGVAR     VAR(&NBRPRC) VALUE(&NBRPRC + 1)
              ENDDO

 NEXT:        CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOP)
             ENDDO

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
