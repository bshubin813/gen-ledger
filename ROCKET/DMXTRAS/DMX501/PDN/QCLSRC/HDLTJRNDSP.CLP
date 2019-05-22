/* ================================================================= */
/* Object:         HDLTJRNDSP      *PGM CLP                          */
/*                 Command processing program for HDLTJRNDSP.        */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20070511 FK  Initial delivery                                     */
/* 20111220 FK  Remove HA/CDC                                        */
/* ================================================================= */
             PGM        PARM(&JRNQ &PRD)

/*           Declare parameter variables                             */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JRNN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&PRCTYP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JRNTYPE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&RCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVATTDT) TYPE(*CHAR) LEN(13)
             DCL        VAR(&TGTNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GRPNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 DMX0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRNN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))

/*           Call command to check usage                             */
             HDLTJRNCHK JRN(&JRNL/&JRNN) PRD(&PRD) PRC(&PRC) +
                          PRCTYP(&PRCTYP) JRNTYPE(&JRNTYPE) +
                          RCV(&RCV) RCVLIB(&RCVLIB) +
                          RCVATTDT(&RCVATTDT) GRPNAM(&GRPNAM) +
                          PRDLIB(&PRDLIB) RTNCDE(&RTNCDE)

/*           Delete H* files in QTEMP                                */
             CALL       PGM(HCRTLFDLT) PARM('*ALL' '*ALL')

             IF         COND(&RTNCDE *EQ ' ') THEN(DO)
              IF         COND(&PRC *EQ '*YES') THEN(SNDPGMMSG +
                          MSGID(DJD0001) MSGF(HAUMSG) MSGDTA(&JRNQ +
                          || &PRD || &PRC || &PRCTYP || &JRNTYPE || +
                          &RCV || &RCVLIB || &RCVATTDT || &TGTNAM +
                          || &GRPNAM || &PRDLIB) MSGTYPE(*COMP))
              IF         COND(&PRC *EQ '*NO') THEN(SNDPGMMSG +
                          MSGID(DJD0002) MSGF(HAUMSG) MSGDTA(&JRNQ +
                          || &PRD || &PRC) MSGTYPE(*COMP))
             ENDDO
             ELSE       CMD(SNDPGMMSG MSGID(DJD0003) MSGF(HAUMSG) +
                          MSGDTA(&JRNQ || &PRD || &RTNCDE) +
                          MSGTYPE(*ESCAPE))

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
