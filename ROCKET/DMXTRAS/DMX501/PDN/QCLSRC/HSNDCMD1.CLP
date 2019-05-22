/* ================================================================= */
/* Object:         HSNDCMD1        *PGM CLP                          */
/*                 Determines the number of groups to be synced      */
/*                                                                   */
/* Create remarks:                                                   */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040207 FK  Initial delivery                                     */
/* 20050422 FK  Only process active groups                           */
/* ================================================================= */
             PGM        PARM(&SYSNAM &NBRGRP@ &BCKNOD)

/*           Declare parameter variables                              */
             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&NBRGRP@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&NBRGRP) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&GRPBCKNOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */
             DCLF       FILE(HIGRPGN)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NBRGRP) VALUE(0)

/*           Create file to access iCluster groups                   */
             CALL       PGM(HCRTLF) PARM('HIGRPGN')
             OVRDBF     FILE(HIGRPGN) TOFILE(QTEMP/HIGRPGN)

 LOOPGRP:    RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOPGRP))
             IF         COND(&GRPTYPE *NE 'R' *OR &CURRPRIM *NE +
                          &SYSNAM) THEN(GOTO CMDLBL(LOOPGRP))
             HRTVCRG    CRG(&GROUP) BCKNOD(&GRPBCKNOD)
/*           If backup node *FIRST --> determine backup node select  */
             IF         COND(&BCKNOD *EQ '*FIRST') THEN(DO)
              CHGVAR     VAR(&BCKNOD) VALUE(&GRPBCKNOD)
              SNDPGMMSG  MSGID(SCM0008) MSGF(HAUMSG) +
                          MSGDTA(&GRPBCKNOD || &GROUP) TOPGMQ(*SAME)
             ENDDO
/*           Skip groups not belonging to backup node selected       */
             IF         COND(&GRPBCKNOD *NE &BCKNOD) THEN(GOTO +
                          CMDLBL(LOOPGRP))
/*           Skip non-active groups                                  */
             HRTVSTS    ICGROUP(&GROUP) PRCTYP(*SND) STATUS(&STATUS)
             IF         COND(&STATUS *NE '*ACTIVE') THEN(DO)
              SNDPGMMSG  MSGID(SCM0009) MSGF(HAUMSG) MSGDTA(&GROUP) +
                          TOPGMQ(*SAME)
              GOTO       CMDLBL(LOOPGRP)
             ENDDO
             CHGVAR     VAR(&NBRGRP) VALUE(&NBRGRP + 1)
             GOTO       CMDLBL(LOOPGRP)

 ELOOPGRP:   CHGVAR     VAR(&NBRGRP@) VALUE(&NBRGRP)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
