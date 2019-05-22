/* ================================================================= */
/* Object:         HLSTCST         *PGM CLP                          */
/*                 Command processing program for HLSTCST.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020708 FK  Initial delivery                                     */
/* 20030114 FK  Reclaim resources at end of program                  */
/* 20030506 FK  Add iCluster support                                 */
/* 20050203 FK  New parameter: STATE                                 */
/* 20050429 FK  Delete LFs in QTEMP in the end                       */
/* 20111217 FK  REMOVE HA                                            */
/* ================================================================= */
             PGM        PARM(&ACTION &CSTFILEQ &ICGROUP &STATE &LIB)

/*           Declare parameter variables                             */
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CSTFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STATE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CSTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CSTFILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&NBRFIL) TYPE(*DEC) LEN(7 0) VALUE(0)
             DCL        VAR(&NBRFIL@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRCST) TYPE(*DEC) LEN(7 0) VALUE(0)
             DCL        VAR(&NBRCST@) TYPE(*CHAR) LEN(4)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 OFC0000 MCH0000) EXEC(GOTO +
                          CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&CSTFILE) VALUE(%SST(&CSTFILEQ 1 10))
             CHGVAR     VAR(&CSTFILEL) VALUE(%SST(&CSTFILEQ 11 10))

/*           Check for existence libraries (if specified)            */
             IF         COND(&ACTION *NE '*LST') THEN(CHKOBJ +
                          OBJ(&CSTFILEL/&CSTFILE) OBJTYPE(*FILE))
             IF         COND(&LIB *NE '*ALL') THEN(CHKOBJ OBJ(&LIB) +
                          OBJTYPE(*LIB))

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           If *LST action --> iCluster in library list             */
             IF         COND(&ACTION *EQ '*LST') THEN(DO)
              IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))
             ENDDO

/*           Dependent on action --> Call program                    */
             IF         COND(&ACTION *EQ '*LST') THEN(CALL +
                          PGM(HLSTCST1) PARM(&UTLLIB &CSTFILEQ +
                          &ICGROUP &NBRCST))
             IF         COND(&ACTION *NE '*LST') THEN(CALL +
                          PGM(HLSTCST2) PARM(&UTLLIB &ACTION +
                          &CSTFILEQ &STATE &LIB &NBRFIL &NBRCST))

/*           Reclaim resources to remove locks                       */
             RCLRSC     LVL(*CALLER)

/*           Delete H* files in QTEMP                                */
             CALL       PGM(HCRTLFDLT) PARM('*ALL' '*ALL')

/*           Send completion message                                 */
             CHGVAR     VAR(%BIN(&NBRFIL@)) VALUE(&NBRFIL)
             CHGVAR     VAR(%BIN(&NBRCST@)) VALUE(&NBRCST)
             IF         COND(&ACTION *EQ '*LST') THEN(SNDPGMMSG +
                          MSGID(LCS0002) MSGF(HAUMSG) +
                          MSGDTA(&NBRCST@ || &ICGROUP || &CSTFILEQ) +
                          MSGTYPE(*COMP))
             IF         COND(&ACTION *EQ '*RMV') THEN(SNDPGMMSG +
                          MSGID(LCS0003) MSGF(HAUMSG) +
                          MSGDTA(&NBRFIL@ || &NBRCST@ || &CSTFILEQ) +
                          MSGTYPE(*COMP))
             IF         COND(&ACTION *EQ '*RST') THEN(SNDPGMMSG +
                          MSGID(LCS0004) MSGF(HAUMSG) +
                          MSGDTA(&NBRFIL@ || &NBRCST@ || &CSTFILEQ) +
                          MSGTYPE(*COMP))
             IF         COND(&ACTION *EQ '*CHG') THEN(SNDPGMMSG +
                          MSGID(LCS0005) MSGF(HAUMSG) +
                          MSGDTA(&NBRFIL@ || &NBRCST@ || &CSTFILEQ +
                          || &STATE) MSGTYPE(*COMP))

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
