/* ================================================================= */
/* Object:         HDLTRCV4        *PGM CLP                          */
/*                 Retrieves the confirmed position for a specific   */
/*                 journal from iCluster                             */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:       This program is invoked from HDLTRCV2 to          */
/*                 determine the oldest receiver still in use by     */
/*                 any of the products.                              */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20070514 FK  Initial delivery (full replacement of old function)  */
/* 20111220 FK  Remove HA/CDC                                        */
/* ================================================================= */
             PGM        PARM(&JRN &JRNL &CHKIC &ALRMSGQQ &RCV &RCVL +
                          &RCVATTD &RTNCDE)

/*           Declare parameter variables                              */
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CHKIC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ALRMSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVATTD) TYPE(*CHAR) LEN(13)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&PRC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ALRMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ALRMSGQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TMPRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TMPRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TMPATTD) TYPE(*CHAR) LEN(13)
             DCL        VAR(&TMPTARGET) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TMPGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TMPPRDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TMPRTN) TYPE(*CHAR) LEN(7)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&RTNCDE) VALUE(' ')
             CHGVAR     VAR(&RCVATTD) VALUE('9999999999999')
             CHGVAR     VAR(&ALRMSGQ) VALUE(%SST(&ALRMSGQQ 1 10))
             CHGVAR     VAR(&ALRMSGQL) VALUE(%SST(&ALRMSGQQ 11 10))

/*           Retrieve journal position for iCluster                  */
             IF         COND(&CHKIC *EQ '*YES') THEN(DO)
              HDLTJRNCHK JRN(&JRNL/&JRN) PRD(*IC) PRC(&PRC) +
                          RCV(&TMPRCV) RCVLIB(&TMPRCVL) +
                          RCVATTDT(&TMPATTD) GRPNAM(&TMPGROUP) +
                          PRDLIB(&TMPPRDLIB) RTNCDE(&TMPRTN)
              IF         COND(&TMPRTN *NE ' ') THEN(DO)
               CHGVAR     VAR(&RCV) VALUE(&TMPRCV)
               CHGVAR     VAR(&RCVL) VALUE(&TMPRCVL)
               CHGVAR     VAR(&RCVATTD) VALUE('0000000000000')
               CHGVAR     VAR(&RTNCDE) VALUE(&TMPRTN)
               SNDPGMMSG  MSGID(DJR0002) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &TMPRCV || &TMPRCVL || +
                          &TMPTARGET || &TMPGROUP || '*IC' || +
                          &TMPPRDLIB) TOMSGQ(&ALRMSGQL/&ALRMSGQ) +
                          MSGTYPE(*DIAG)
              ENDDO
/*            Adjust oldest receiver if receiver is older            */
              IF         COND(&TMPRTN *EQ ' ' *AND &PRC *EQ '*YES' +
                          *AND &TMPATTD *LT &RCVATTD) THEN(DO)
               CHGVAR     VAR(&RCV) VALUE(&TMPRCV)
               CHGVAR     VAR(&RCVL) VALUE(&TMPRCVL)
               CHGVAR     VAR(&RCVATTD) VALUE(&TMPATTD)
              ENDDO
             ENDDO

/*           Move all *DIAG and *ESCAPE messages to HDLTJRNRCV-1     */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' 'HDLTJRNRCV' X'00000001' &APIERR)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

             RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGID(&RTNCDE)

 END:        ENDPGM
