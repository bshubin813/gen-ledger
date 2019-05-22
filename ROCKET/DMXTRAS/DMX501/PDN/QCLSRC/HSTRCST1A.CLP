/* ================================================================= */
/* Object:         HSTRCST1A       *PGM CLP                          */
/*                 Checks if any nodes have status *ACT_PEND and     */
/*                 returns this value.                               */
/*                                                                   */
/* Create:         CRTCLPGM                                          */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040524 FK  Initial delivery                                     */
/* 20050223 FK  Also consider *PENDING for decoupled mode            */
/* ================================================================= */
             PGM        PARM(&NODSTRTNG)

/*           Declare parameter variables                              */
             DCL        VAR(&NODSTRTNG) TYPE(*CHAR) LEN(1)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LSTSTS) TYPE(*CHAR) LEN(10)

/*           Declare files                                            */
             DCLF       FILE(HINODNN)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&NODSTRTNG) VALUE('0')

/*           Create LF to nodes file                                 */
             CALL       PGM(HCRTLF) PARM('HINODNN')
             OVRDBF     FILE(HINODNN) TOFILE(QTEMP/HINODNN)
 LOOPNODE:   RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOPNODE))
             HRTVNODSTS NODE(&NODE) STATUS(&STATUS) LSTSTS(&LSTSTS)
             IF         COND(&STATUS *EQ '*ACT_PEND' *OR &STATUS *EQ +
                          '*PENDING') THEN(CHGVAR VAR(&NODSTRTNG) +
                          VALUE('1'))
             GOTO       CMDLBL(LOOPNODE)

 ELOOPNODE:  GOTO       CMDLBL(END)

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
