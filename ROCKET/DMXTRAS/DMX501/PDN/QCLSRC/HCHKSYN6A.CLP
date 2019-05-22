/* ================================================================= */
/* Object:         HCHKSYN6A       *PGM CLP                          */
/*                 Calls the program that lists the IFS objects for  */
/*                 the specified path.                               */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020523 FK  Initial delivery                                     */
/* 20021204 FK  Redesign of retrieving IFS objects (APIs in C)       */
/* 20030501 FK  Enable for iCluster                                  */
/* ================================================================= */
             PGM        PARM(&ICGROUP &PATH)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PATH) TYPE(*CHAR) LEN(5000)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Send message "Retrieving IFS objects ..."               */
             SNDPGMMSG  MSGID(CST0008) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &PATH) TOPGMQ(*SAME (* *NONE *NONE))

/*           List IFS objects to QTEMP/HCHKSYNID                     */
             OVRDBF     FILE(HCHKSYNID) TOFILE(QTEMP/HCHKSYNID)
             CALL       PGM(HCHKSYN6C) PARM(&ICGROUP &PATH '\S')
             DLTOVR     FILE(HCHKSYNID)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG and *ESCAPE messages to previous queue   */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
