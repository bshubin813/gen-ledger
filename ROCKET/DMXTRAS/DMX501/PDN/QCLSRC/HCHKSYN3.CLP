/* ================================================================= */
/* Object:         HCHKSYN3        *PGM CLP                          */
/*                 Retrieves the object authorities for all objects  */
/*                 left after exclusion processing. This is for both */
/*                 native and IFS objects.                           */
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
/* 20000227 FK  Initial delivery                                     */
/* 20011126 FK  Optimisation by combining DSPOBJAUT for 1 library    */
/* 20011128 FK  Also save compare library and use for correction     */
/* 20020531 FK  If 1 library --> also copy back data                 */
/* 20021122 FK  Sync. check redesign                                 */
/* 20031208 FK  Retrieve proper object authorities, dep. on role     */
/* 20050211 FK  Authorities retrieved in QTEMP only                  */
/* 20050428 FK  Also retrieve library authority when new lib         */
/* 20050510 FK  Include IFS authorities and use of API               */
/* ================================================================= */
             PGM        PARM(&CHKIFS)

/*           Declare parameter variables                              */
             DCL        VAR(&CHKIFS) TYPE(*CHAR) LEN(4)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Call program to retrieve authorities                    */
             CALL       PGM(HCHKSYN3A) PARM(&CHKIFS)

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
