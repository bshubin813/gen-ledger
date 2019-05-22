/* ================================================================= */
/* Object:         HSTRCST2        *PGM CLP                          */
/*                 Starts all groups that have *A in description.    */
/*                                                                   */
/* Create:         CRTCLPGM                                          */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040505 FK  Initial delivery                                     */
/* 20040507 FK  Parameterise start of apply jobs                     */
/* 20040524 FK  Start groups of active nodes                         */
/* 20040604 FK  Issue message of invalid-state group first           */
/* 20050209 FK  Do not fail if status message queue is full          */
/* ================================================================= */
             PGM        PARM(&STRAPY &STSMSGQ &STSMSGQL)

/*           Declare parameter variables                              */
             DCL        VAR(&STRAPY) TYPE(*CHAR) LEN(6)
             DCL        VAR(&STSMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STSMSGQL) TYPE(*CHAR) LEN(10)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&POS) TYPE(*DEC) LEN(3 0)

             DCL        VAR(&INFVLD) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CRGSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CRGPRI) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CRGBCK) TYPE(*CHAR) LEN(8)

             DCL        VAR(&PRISTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKSTS) TYPE(*CHAR) LEN(10)

/*           Declare files                                            */
             DCLF       FILE(HIGRPGN)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Create LF to group file                                 */
             CALL       PGM(HCRTLF) PARM('HIGRPGN')
             OVRDBF     FILE(HIGRPGN) TOFILE(QTEMP/HIGRPGN)

/*           Process all groups and determine autostart              */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Skip groups that don't have "*A" in description         */
             CALL       PGM(QCLSCAN) PARM(&DESC X'050F' X'001F' '*A' +
                          X'002F' '1' '0' ' ' &POS)
             IF         COND(&POS *EQ 0) THEN(GOTO CMDLBL(LOOP))

/*           Retrieve attributes of CRG (skip non-existing)          */
             HRTVCRG    CRG(&GROUP) INFVLD(&INFVLD) CRGSTS(&CRGSTS) +
                          PRINOD(&CRGPRI) BCKNOD(&CRGBCK)
             MONMSG     MSGID(CPF0000 RCR0000) EXEC(GOTO CMDLBL(LOOP))

/*           Skip groups which are already active                    */
             IF         COND(&CRGSTS *EQ '*ACTIVE') THEN(GOTO +
                          CMDLBL(LOOP))

/*           Skip groups for which metadata status doesn't match     */
             IF         COND(&CURRPRIM *NE &CRGPRI) THEN(DO)
              SNDPGMMSG  MSGID(SCS0019) MSGF(HAUMSG) MSGDTA(&GROUP || +
                          &CURRPRIM || &CRGPRI) MSGTYPE(*DIAG)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0019) MSGF(HAUMSG) MSGDTA(&GROUP || +
                          &CURRPRIM || &CRGPRI) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ) MSGTYPE(*DIAG)
               MONMSG     MSGID(CPF0000)
              ENDDO
              GOTO       CMDLBL(LOOP)
             ENDDO

/*           Skip groups which nodes are not active                  */
             HRTVNODSTS NODE(&CRGPRI) STATUS(&PRISTS)
             HRTVNODSTS NODE(&CRGBCK) STATUS(&BCKSTS)
             IF         COND(&PRISTS *NE '*ACTIVE' *OR &BCKSTS *NE +
                          '*ACTIVE') THEN(DO)
              SNDPGMMSG  MSGID(SCS0020) MSGF(HAUMSG) MSGDTA(&GROUP || +
                          &CRGPRI || &PRISTS || &CRGBCK || &BCKSTS)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0020) MSGF(HAUMSG) MSGDTA(&GROUP || +
                          &CRGPRI || &PRISTS || &CRGBCK || &BCKSTS) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
               MONMSG     MSGID(CPF0000)
              ENDDO
              GOTO       CMDLBL(LOOP)
             ENDDO

/*           Start group or resilient application                    */
             IF         COND(&APPNAME *EQ ' ' *OR &APPNAME *EQ +
                          '*NONE') THEN(DO)
              SNDPGMMSG  MSGID(SCS0016) MSGF(HAUMSG) MSGDTA(&GROUP)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0016) MSGF(HAUMSG) MSGDTA(&GROUP) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
               MONMSG     MSGID(CPF0000)
              ENDDO
              DMSTRGRP   GROUP(&GROUP) STRAPY(&STRAPY)
             ENDDO
             ELSE       CMD(DO)
              SNDPGMMSG  MSGID(SCS0017) MSGF(HAUMSG) MSGDTA(&APPNAME)
              IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(SCS0017) MSGF(HAUMSG) MSGDTA(&APPNAME) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
               MONMSG     MSGID(CPF0000)
              ENDDO
              DMSTRAPP   APPNAME(&APPNAME) STRAPY(&STRAPY)
             ENDDO

             GOTO       CMDLBL(LOOP)

 ELOOP:      GOTO       CMDLBL(END)

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
