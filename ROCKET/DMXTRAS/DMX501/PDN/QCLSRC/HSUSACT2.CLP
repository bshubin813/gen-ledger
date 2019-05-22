/* ================================================================= */
/* Object:         HSUSACT2        *PGM CLP                          */
/*                 Suspends or activate the file for the target.     */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000410 FK  Initial delivery                                     */
/* 20020626 FK  Optional refresh                                     */
/* 20030605 FK  Enable for iCluster                                  */
/* 20111222 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &OBJNAM &OBJLIB &ACTION &RFSH +
                          &ICLIB &RTNCDE)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RFSH) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Set current library dependent on product                */
             CHGCURLIB  CURLIB(&ICLIB)

/*           Suspend the file for iCluster                           */
             IF         COND(&ACTION *EQ '*SUS') THEN(DO)
              DMSUSOBJ   GROUP(&ICGROUP) OBJ(&OBJLIB/&OBJNAM) +
                          OBJTYPE(*FILE)
              SNDPGMMSG  MSGID(SAF0009) MSGF(HAUMSG) MSGDTA(&OBJNAM +
                          || &OBJLIB || &ICGROUP) TOPGMQ(*PRV +
                          (HSUSACTF)) MSGTYPE(*COMP)
             ENDDO

/*           Activate the file for iCluster                          */
             IF         COND(&ACTION *EQ '*ACT') THEN(DO)
              DMACTOBJ   GROUP(&ICGROUP) OBJ(&OBJLIB/&OBJNAM) +
                          OBJTYPE(*FILE) RFSH(&RFSH)
              SNDPGMMSG  MSGID(SAF0010) MSGF(HAUMSG) MSGDTA(&OBJNAM +
                          || &OBJLIB || &ICGROUP) TOPGMQ(*PRV +
                          (HSUSACTF)) MSGTYPE(*COMP)
             ENDDO

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
