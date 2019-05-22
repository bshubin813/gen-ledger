/* ================================================================= */
/* Object:         ANZJRN01        *PGM CLP                          */
/*                 Performs the journal analysis for the passed      */
/*                 journal.                                          */
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
/* 20060126 FK  Use API for better performance                       */
/* ================================================================= */
             PGM        PARM(&JRNNME &JRNLIB &DLTRCV &STRRCVQ +
                          &ENDRCVQ &STRDTE &ENDDTE)

/*           Declare parameter variables                              */
             DCL        VAR(&JRNNME)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNLIB)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&DLTRCV)  TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRRCVQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ENDRCVQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&STRDTE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ENDDTE) TYPE(*CHAR) LEN(8)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Indicate journal being processed                        */
             SNDPGMMSG  MSGID(AJD0003) MSGF(HAUMSG) MSGDTA(&JRNNME +
                          || &JRNLIB) TOPGMQ(*SAME)

/*           Generate new receiver for journal                       */
             SNDPGMMSG  MSGID(AJD0002) MSGF(HAUMSG) MSGDTA(&JRNNME +
                          || &JRNLIB) TOPGMQ(*SAME)
             CHGJRN     JRN(&JRNLIB/&JRNNME) JRNRCV(*GEN)

/*           Store name of journal and date selection in *LDA        */
             CHGDTAARA  DTAARA(*LDA (1 36)) VALUE(&JRNNME || &JRNLIB +
                          || &STRDTE || &ENDDTE)

/*           Generate list of journal receivers and process          */
             CALL       PGM(ANZJRN02) PARM(&JRNNME &JRNLIB &DLTRCV +
                          &STRRCVQ &ENDRCVQ &STRDTE &ENDDTE)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG and *ESCAPE messages                     */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
