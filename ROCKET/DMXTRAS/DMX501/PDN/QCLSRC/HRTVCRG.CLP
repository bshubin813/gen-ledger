/* ================================================================= */
/* Object:         HRTVCRG         *PGM CLP                          */
/*                 Returns the attributes of the passed CRG.         */
/*                                                                   */
/* Synopsis:       Calls program HRTVCFG1 to retrieve the CRG        */
/*                 information.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040519 FK  Initial delivery                                     */
/* 20040604 FK  Check for existence CRG                              */
/* 20050216 FK  Change for decoupled mode (iCluster 2.1+)            */
/* 20050422 FK  Detection of decoupled mode *EN 'N'                  */
/* ================================================================= */
             PGM        PARM(&CRG &P_INFVLD &P_CRGTYP &P_CRGSTS +
                          &P_PRINOD &P_BCKNOD)

/*           Declare parameter variables                              */
             DCL        VAR(&CRG) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_INFVLD) TYPE(*CHAR) LEN(4)
             DCL        VAR(&P_CRGTYP) TYPE(*CHAR) LEN(5)
             DCL        VAR(&P_CRGSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_PRINOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&P_BCKNOD) TYPE(*CHAR) LEN(8)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&INFVLD) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CRGTYP) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CRGSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRINOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&PRISTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&BCKSTS) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CSTSRV) TYPE(*CHAR) LEN(1)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 RCR0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Use OS/400 cluster services?                            */
             RTVDTAARA  DTAARA(DM_SYSVALS (199 1)) RTNVAR(&CSTSRV)
             IF         COND(&CSTSRV *NE 'N') THEN(CHGVAR +
                          VAR(&CSTSRV) VALUE('Y'))

/*           Call program which retrieves the information (CRS)      */
             IF         COND(&CSTSRV *EQ 'Y') THEN(DO)
/*            Check if CRG is existing                               */
              CHKOBJ     OBJ(QUSRSYS/&CRG) OBJTYPE(*CRG)
              CALL       PGM(HRTVCRG1) PARM(&UTLLIB &CRG &INFVLD +
                          &CRGTYP &CRGSTS &PRINOD &PRISTS &BCKNOD +
                          &BCKSTS)
             ENDDO

/*           Retrieve group information (decoupled)                  */
             IF         COND(&CSTSRV *EQ 'N') THEN(DO)
              CALL       PGM(HRTVCRG2) PARM(&CRG &INFVLD &CRGTYP +
                          &CRGSTS &PRINOD &BCKNOD)
             ENDDO

/*           Return information to calling program                   */
             CHGVAR     VAR(&P_INFVLD) VALUE(&INFVLD)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_CRGTYP) VALUE(&CRGTYP)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_CRGSTS) VALUE(&CRGSTS)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_PRINOD) VALUE(&PRINOD)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_BCKNOD) VALUE(&BCKNOD)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))

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
