/* ================================================================= */
/* Object:         HRTVSTS         *PGM CLP                          */
/*                 Returns the status of the passed group            */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000410 FK  Initial delivery                                     */
/* 20030506 FK  Enable for iCluster                                  */
/* 20040506 FK  Enable *RCV                                          */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &PRC &P_JOBNAM &P_JOBUSR +
                          &P_JOBNBR &P_STATUS &P_RTNCDE)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&P_JOBNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_JOBUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_JOBNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&P_STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JOBNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve product libraries                              */
             HRTVPRDLIB ICPRODLIB(&ICLIB)

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Create necessary files in QTEMP                         */
             CALL       PGM(HCRTLF) PARM('HUTGTTI')
             CALL       PGM(HCRTLF) PARM('HUTGTTN')
             CALL       PGM(HCRTLF) PARM('HUGRPGI')
             CALL       PGM(HCRTLF) PARM('HUFGTTG')
             CALL       PGM(HCRTLF) PARM('HUDGTTG')
             CALL       PGM(HCRTLF) PARM('HUPID')
             OVRDBF     FILE(HUTGTTI) TOFILE(QTEMP/HUTGTTI)
             OVRDBF     FILE(HUTGTTN) TOFILE(QTEMP/HUTGTTN)
             OVRDBF     FILE(HUGRPGI) TOFILE(QTEMP/HUGRPGI)
             OVRDBF     FILE(HUFGTTG) TOFILE(QTEMP/HUFGTTG)
             OVRDBF     FILE(HUDGTTG) TOFILE(QTEMP/HUDGTTG)
             OVRDBF     FILE(HUPID) TOFILE(QTEMP/HUPID)

/*           Call program that retrieves status                      */
             CALL       PGM(HRTVSTS1) PARM(&ICGROUP &PRC &JOBNAM +
                          &JOBUSR &JOBNBR &STATUS &RTNCDE)

/*           Return values to calling program                        */
             CHGVAR     VAR(&P_JOBNAM) VALUE(&JOBNAM)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_JOBUSR) VALUE(&JOBUSR)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_JOBNBR) VALUE(&JOBNBR)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_STATUS) VALUE(&STATUS)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_RTNCDE) VALUE(&RTNCDE)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))

 ELOOP:      GOTO       CMDLBL(END)

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
