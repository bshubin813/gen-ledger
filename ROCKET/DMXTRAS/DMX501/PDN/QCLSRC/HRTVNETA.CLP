/* ================================================================= */
/* Object:         HRTVNETA        *PGM CLP                          */
/*                 Returns the node name of the current system.      */
/*                                                                   */
/* Synopsis:       The name of the current node is retrieved from    */
/*                 data area DMNODE (iC 2.2+). If the data area      */
/*                 was not found, the current system's name (NETA)   */
/*                 will be returned.                                 */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20060102 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&SYSNAME)

/*           Declare parameter variables                              */
             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVNETA    SYSNAME(&SYSNAME)
             RTVDTAARA  DTAARA(DMNODE (1 8)) RTNVAR(&SYSNAME)
             MONMSG     MSGID(CPF1015) EXEC(RCVMSG MSGTYPE(*LAST))

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
