/* ================================================================= */
/* Object:         HRTVNODSTS      *PGM CLP                          */
/*                 Returns the status of the passed node.            */
/*                                                                   */
/* Synopsis:       The status of the specified node is retrieved     */
/*                 using the QcstListClusterInfo API. First, the     */
/*                 status of the current node is retrieved. If its   */
/*                 status is not active, the status of the specified */
/*                 node is *UNKNOWN.                                 */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20040429 FK  Initial delivery                                     */
/* 20050216 FK  Change for decoupled mode (iCluster 2.1+)            */
/* 20050223 FK  Also return if listener port is active               */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* ================================================================= */
             PGM        PARM(&NODE &P_STATUS &P_LSTSTS &P_LSNACT)

/*           Declare parameter variables                              */
             DCL        VAR(&NODE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&P_STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_LSTSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_LSNACT) TYPE(*CHAR) LEN(4)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STATUS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LSTSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LSNACT) TYPE(*CHAR) LEN(4)

             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CSTSRV) TYPE(*CHAR) LEN(1)

             DCL        VAR(&USRSPC) TYPE(*CHAR) LEN(20)
             DCL        VAR(&LSTHDR) TYPE(*CHAR) LEN(140)
             DCL        VAR(&I) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&STRLST) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRENT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&STRPOS@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LSTENT) TYPE(*CHAR) LEN(200)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 RNS0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           Replace special values                                  */
             IF         COND(&NODE *EQ '*CURRENT') THEN(CHGVAR +
                          VAR(&NODE) VALUE(&SYSNAME))

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

             HRTVNETA    SYSNAME(&SYSNAME)

/*           Use OS/400 cluster services?                            */
             RTVDTAARA  DTAARA(DM_SYSVALS (199 1)) RTNVAR(&CSTSRV)
             IF         COND(&CSTSRV *NE 'N') THEN(CHGVAR +
                          VAR(&CSTSRV) VALUE('Y'))

/*           Retrieve status of specified node, cluster services     */
             IF         COND(&CSTSRV *EQ 'Y') THEN(CALL +
                          PGM(HRTVNODST1) PARM(&UTLLIB &ICLIB &NODE +
                          &STATUS &LSTSTS &LSNACT))

/*           Retrieve status of specified node, decoupled            */
             IF         COND(&CSTSRV *EQ 'N') THEN(DO)
              CALL       PGM(HCRTLF) PARM(HINODNN21)
              OVRDBF     FILE(HINODNN21) TOFILE(QTEMP/HINODNN21)
              CALL       PGM(HRTVNODST2) PARM(&NODE &STATUS &LSTSTS +
                          &LSNACT)
             ENDDO

/*           Show status of node in job log                          */
             IF         COND(&STATUS *NE '*UNKNOWN') THEN(SNDPGMMSG +
                          MSGID(RNS0002) MSGF(HAUMSG) MSGDTA(&NODE +
                          || &STATUS))
             IF         COND(&STATUS *EQ '*UNKNOWN') THEN(SNDPGMMSG +
                          MSGID(RNS0003) MSGF(HAUMSG) MSGDTA(&NODE +
                          || &STATUS || &LSTSTS))

/*           Return values to calling program                        */
             CHGVAR     VAR(&P_STATUS) VALUE(&STATUS)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_LSTSTS) VALUE(&LSTSTS)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&P_LSNACT) VALUE(&LSNACT)
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
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
