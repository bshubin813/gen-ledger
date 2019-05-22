/* ================================================================= */
/* Object:         HCHKSYN7        *PGM CLP                          */
/*                 Determines the backup node for the specified      */
/*                 group.                                            */
/*                                                                   */
/* Create remarks:                                                   */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050214 FK  Initial delivery                                     */
/* 20050224 FK  Handle *FIRST for backup node                        */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20060210 FK  Support for generic group name                       */
/* 20060215 FK  Retrieve info from HLSTCFGG                          */
/* ================================================================= */
             PGM        PARM(&BCKNOD)

/*           Declare parameter variables                              */
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

/*           Declare file                                            */
             DCLF       FILE(HLSTCFGG)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             OVRDBF     FILE(HLSTCFGG) TOFILE(QTEMP/HLSTCFGG)

/*           Retrieve first record from HLSTCFGG to determine backup */
             RCVF
             MONMSG     MSGID(CPF0864)

             HRTVCRG    CRG(&LGGRPN) BCKNOD(&BCKNOD)
             SNDPGMMSG  MSGID(CST0006) MSGF(HAUMSG) MSGDTA(&BCKNOD +
                          || &LGGRPN) TOPGMQ(*SAME)

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
