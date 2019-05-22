/* ================================================================= */
/* Object:         HSETPOS2        *PGM CLP                          */
/*                 Builds the HUPIDTGJ logical file over the HAPID   */
/*                 file (executed via SBMRMTCMD).                    */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030106 FK  Initial delivery                                     */
/* 20030711 FK  Enable for iCluster                                  */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&UTLLIB &ICLIB)

/*           Declare parameter variables                              */
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Ensure that DMXtras is in library list                  */
             ADDLIBLE   LIB(&UTLLIB)
             MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Ensure that iCluster is in library list and on top      */
             IF         COND(&ICLIB *NE '*NONE') THEN(DO)
              RMVLIBLE   LIB(&ICLIB)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ADDLIBLE   LIB(&ICLIB)
             ENDDO

/*           Create LF over HAPID                                    */
             CALL       PGM(HCRTLF) PARM('HUPIDTGJ')

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
