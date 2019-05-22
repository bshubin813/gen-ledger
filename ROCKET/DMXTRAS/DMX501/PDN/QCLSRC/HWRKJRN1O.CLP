/* ================================================================= */
/* Object:         HWRKJRN1O       *PGM CLP                          */
/*                 Work with product journals - process subfile      */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20070424 FK  Initial delivery                                     */
/* 20070513 FK  Check use by product                                 */
/* 20111220 FK  Remove HA/CDC                                        */
/* ================================================================= */
             PGM        PARM(&JRN &JRNL &CHKIC &SFLOPT)

/*           Declare parameter variables                             */
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CHKIC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SFLOPT) TYPE(*CHAR) LEN(2)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 DJR0000 DMX0000 DJD0000) +
                          EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Option 4: Delete journal receivers                      */
             IF         COND(&SFLOPT *EQ '4' *OR &SFLOPT *EQ ' 4') +
                          THEN(DO)
              ?          HDLTJRNRCV JRN(&JRNL/&JRN) ??DLTUNSRCV(*NO) +
                          ??CHKIC(&CHKIC)

             ENDDO

/*           Option 8: Check use by product                          */
             IF         COND(&SFLOPT *EQ '8' *OR &SFLOPT *EQ ' 8') +
                          THEN(DO)
              IF         COND(&CHKIC *EQ '*YES') THEN(HDLTJRNDSP +
                          JRN(&JRNL/&JRN) PRD(*IC))
             ENDDO

/*           Option 12: Work with journal attributes                 */
             IF         COND(&SFLOPT *EQ '12') THEN(DO)
              WRKJRNA    JRN(&JRNL/&JRN)
             ENDDO

/*           Move all *COMP and *DIAG messages to previous queue     */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *COMP     +
                          ' X'00000002' '*' X'00000001' &APIERR)

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
