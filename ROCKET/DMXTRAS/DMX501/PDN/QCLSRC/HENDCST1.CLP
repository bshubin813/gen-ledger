/* ================================================================= */
/* Object:         HENDCST1        *PGM CLP                          */
/*                 Processes all groups and ends them if they are    */
/*                 active on the current node.                       */
/*                                                                   */
/* Create:         CRTCLPGM                                          */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040514 FK  Initial delivery                                     */
/* 20040604 FK  Skip non-existing CRGs                               */
/* 20050209 FK  Do not fail if status message queue is full          */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* ================================================================= */
             PGM        PARM(&OPTION &DELAY &STSMSGQ &STSMSGQL)

/*           Declare parameter variables                              */
             DCL        VAR(&OPTION) TYPE(*CHAR) LEN(7)
             DCL        VAR(&DELAY) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&STSMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STSMSGQL) TYPE(*CHAR) LEN(10)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)

             DCL        VAR(&CRGSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CRGPRI) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CRGBCK) TYPE(*CHAR) LEN(8)

/*           Declare files                                            */
             DCLF       FILE(HIGRPGN)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             HRTVNETA   SYSNAME(&SYSNAME)

/*           Create LF to group file                                 */
             CALL       PGM(HCRTLF) PARM('HIGRPGN')
             OVRDBF     FILE(HINODNN) TOFILE(QTEMP/HIGRPGN)

/*           Process all groups and end if CRG is active             */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Retrieve CRG (skip non-existing)                        */
             HRTVCRG    CRG(&GROUP) CRGSTS(&CRGSTS) PRINOD(&CRGPRI) +
                          BCKNOD(&CRGBCK)
             MONMSG     MSGID(RCR0000 CPF0000) EXEC(GOTO CMDLBL(LOOP))
/*           Only process groups for current node                    */
             IF         COND(&CRGPRI *NE &SYSNAME *AND &CRGBCK *NE +
                          &SYSNAME) THEN(GOTO CMDLBL(LOOP))

/*           If group is active --> end                              */
             IF         COND(&CRGSTS *EQ '*ACTIVE') THEN(DO)
              IF         COND(&APPNAME *EQ ' ' *OR &APPNAME *EQ +
                          '*NONE') THEN(DO)
               SNDPGMMSG  MSGID(ECS0010) MSGF(HAUMSG) MSGDTA(&GROUP)
               IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
                SNDPGMMSG  MSGID(ECS0010) MSGF(HAUMSG) MSGDTA(&GROUP) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
                MONMSG     MSGID(CPF0000)
               ENDDO
               DMENDGRP   GROUP(&GROUP) OPTION(&OPTION) DELAY(&DELAY)
              ENDDO
              ELSE       CMD(DO)
               SNDPGMMSG  MSGID(ECS0016) MSGF(HAUMSG) MSGDTA(&APPNAME)
               IF         COND(&STSMSGQ *NE '*NONE') THEN(DO)
                SNDPGMMSG  MSGID(ECS0016) MSGF(HAUMSG) MSGDTA(&APPNAME) +
                          TOMSGQ(&STSMSGQL/&STSMSGQ)
                MONMSG     MSGID(CPF0000)
               ENDDO
               DMENDAPP   APPNAME(&APPNAME) OPTION(&OPTION) DELAY(&DELAY)
              ENDDO
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
