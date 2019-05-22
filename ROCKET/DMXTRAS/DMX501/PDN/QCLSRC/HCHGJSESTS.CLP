/*CP: LOG(*NO)                                                       */
/* ================================================================= */
/* Object:         HCHGJSESTS      *PGM CLP                          */
/*                 Command processing program for HCHGJSESTS.        */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030704 FK  Initial delivery                                     */
/* 20031209 FK  No logging of CL commands                            */
/* ================================================================= */
             PGM        PARM(&ACTION &USRSPCQ)

/*           Parameter variables                                     */
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&USRSPCQ) TYPE(*CHAR) LEN(20)

/*           Program variables                                       */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)

             DCL        VAR(&USRSPC) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USRSPCL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)

             DCL        VAR(&TEXT) TYPE(*CHAR) LEN(50)

             DCL        VAR(&NBRPRC) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRPRC@) TYPE(*CHAR) LEN(4)

/* ----------------------------------------------------------------- */
/*           Global monitoring (if any)                              */
/* ----------------------------------------------------------------- */
             MONMSG     MSGID(CPF0000 JRT0000) EXEC(GOTO CMDLBL(ERROR))

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

/*           If action *RST --> Check existence of user space        */
             IF         COND(&ACTION *EQ '*RST') THEN(CHKOBJ +
                          OBJ(&USRSPCL/&USRSPC) OBJTYPE(*USRSPC))

/*           If action *HLD --> Retrieve job schedule entries        */
             IF         COND(&ACTION *EQ '*HLD') THEN(DO)
/*            Determine text description                             */
              CHGVAR     VAR(&TEXT) VALUE('HCHGJSESTS job schedule +
                          entries:' |> &SYSNAME)
              HRTVJSE    USRSPC(&USRSPCL/&USRSPC) TEXT(&TEXT)
             ENDDO

/*           Call program that holds/restores the job schedule ent.  */
             CALL       PGM(HCHGJSE1) PARM(&ACTION &USRSPCQ &NBRPRC)

/*           Send completion message                                 */
             CHGVAR     VAR(%BIN(&NBRPRC@)) VALUE(&NBRPRC)
             IF         COND(&ACTION *EQ '*HLD') THEN(SNDPGMMSG +
                          MSGID(JCH0001) MSGF(HAUMSG) +
                          MSGDTA(&USRSPCQ || &NBRPRC@) MSGTYPE(*COMP))
             IF         COND(&ACTION *EQ '*RST') THEN(SNDPGMMSG +
                          MSGID(JCH0002) MSGF(HAUMSG) +
                          MSGDTA(&USRSPCQ || &NBRPRC@) MSGTYPE(*COMP))

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
