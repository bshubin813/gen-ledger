/* ================================================================= */
/* Object:         HMONHA2         *PGM CLP                          */
/*                 Clean up event logs                               */
/*                                                                   */
/* Synopsis:       This program is executed on both the source- and  */
/*                 target system to clean up event log messages      */
/*                 based on the HA Suite/iCluster system settings.   */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20041216 FK  Initial delivery (copy from HMONEVL)                 */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM

/*           Declare parameter variables                             */

/*           Declare program variables                               */
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Determine product that event log must be displayed for  */
             HRTVPRDLIB ICPRODLIB(&ICLIB)

/*           Clean up iCluster logs by printing output               */
             IF         COND(&ICLIB *NE '*NONE') THEN(DO)
              DMDSPLOG   EVNTTYPE(*ALL) OUTPUT(*PRINT)
              DLTSPLF    FILE(OMEVENTLOG) SPLNBR(*LAST)
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
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
