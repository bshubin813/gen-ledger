/* ================================================================= */
/* Object:         HPRTANZ         *PGM CLP                          */
/*                 Command processing program for HPRTANZ.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020507 FK  Initial delivery                                     */
/* 20060127 FK  Allow to recalculate totals                          */
/* ================================================================= */
             PGM        PARM(&RECALC)

/*           Declare parameter variables                             */
             DCL        VAR(&RECALC) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

             IF         COND(&RECALC *EQ '*YES') THEN(DO)
              SNDPGMMSG  MSGID(PAN0003) MSGF(HAUMSG) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(PAN0003) MSGF(HAUMSG) TOPGMQ(*SAME)
              ALCOBJ     OBJ((ANZTOT1 *FILE *SHRNUP *FIRST)) WAIT(32767)
              ALCOBJ     OBJ((ANZTOT2 *FILE *SHRNUP *FIRST)) WAIT(32767)
              ALCOBJ     OBJ((ANZTOT3 *FILE *SHRNUP *FIRST)) WAIT(32767)
              ALCOBJ     OBJ((ANZTOT4 *FILE *SHRNUP *FIRST)) WAIT(32767)
              ALCOBJ     OBJ((ANZTOT5 *FILE *SHRNUP *FIRST)) WAIT(32767)
              CLRPFM     FILE(ANZTOT1)
              MONMSG     MSGID(CPF0000)
              CLRPFM     FILE(ANZTOT2)
              MONMSG     MSGID(CPF0000)
              CLRPFM     FILE(ANZTOT3)
              MONMSG     MSGID(CPF0000)
              CLRPFM     FILE(ANZTOT4)
              MONMSG     MSGID(CPF0000)
              CLRPFM     FILE(ANZTOT5)
              MONMSG     MSGID(CPF0000)
/*            Now calculate totals                                   */
              SNDPGMMSG  MSGID(PAN0002) MSGF(HAUMSG) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)
              CALL       PGM(ANZJRNSUM)
             ENDDO

             IF         COND(&RECALC *EQ '*YES') THEN(DO)
              DLCOBJ     OBJ((ANZTOT1 *FILE *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000)
              DLCOBJ     OBJ((ANZTOT2 *FILE *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000)
              DLCOBJ     OBJ((ANZTOT3 *FILE *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000)
              DLCOBJ     OBJ((ANZTOT4 *FILE *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000)
              DLCOBJ     OBJ((ANZTOT5 *FILE *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           Print reports                                           */
             CALL       PGM(ANZTOT1)
             CALL       PGM(ANZTOT2)
             CALL       PGM(ANZTOT3)
             CALL       PGM(ANZTOT4)

/*           Send completion message                                 */
             SNDPGMMSG  MSGID(PAN0001) MSGF(HAUMSG) MSGTYPE(*COMP)

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
