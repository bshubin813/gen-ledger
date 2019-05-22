/* ================================================================= */
/* Object:         HRTVJRNE        *PGM CLP                          */
/*                 Replacement of RTVJRNE command which allows       */
/*                 for 20-digit sequence numbers                     */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20070425 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&JRNQ &JRNRCVQ &FROMENTLRG &FROMTIMEL +
                          &NBRENT &RTNRCV &RTNRCVLIB &RTNSEQLRG +
                          &RTNENTDTS &RTNJRNCDE &RTNENTTYP)

/*           Declare parameter variables                             */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JRNRCVQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&FROMENTLRG) TYPE(*CHAR) LEN(20)
             DCL        VAR(&FROMTIMEL) TYPE(*CHAR) LEN(15)
             DCL        VAR(&NBRENT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&RTNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNRCVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNSEQLRG) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RTNENTDTS) TYPE(*CHAR) LEN(26)
             DCL        VAR(&RTNJRNCDE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&RTNENTTYP) TYPE(*CHAR) LEN(2)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRCVL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&J) TYPE(*DEC) LEN(3 0)

             DCL        VAR(&FROMENT) TYPE(*CHAR) LEN(20)
             DCL        VAR(&FROMTIMEZ) TYPE(*CHAR) LEN(26)
             DCL        VAR(&DATE@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TIME@) TYPE(*CHAR) LEN(8)

             DCL        VAR(&RTNRCV@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNRCVLIB@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNSEQLRG@) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RTNENTDTS@) TYPE(*CHAR) LEN(26)
             DCL        VAR(&RTNJRNCDE@) TYPE(*CHAR) LEN(1)
             DCL        VAR(&RTNENTTYP@) TYPE(*CHAR) LEN(2)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))
             CHGVAR     VAR(&JRNRCV) VALUE(%SST(&JRNRCVQ 1 10))
             CHGVAR     VAR(&JRNRCVL) VALUE(%SST(&JRNRCVQ 11 10))

/*           Check journal existence                                 */
             CHKOBJ     OBJ(&JRNL/&JRN) OBJTYPE(*JRN)

/*           Check journal receiver existence                        */
             IF         COND(&JRNRCV *NE '*CURRENT' *AND &JRNRCV *NE +
                          '*CURCHAIN') THEN(DO)
              CHKOBJ     OBJ(&JRNRCVL/&JRNRCV) OBJTYPE(*JRNRCV)
             ENDDO

/*           Convert sequence number to right-aligned                */
             IF         COND(&FROMENTLRG *NE '*FIRST' *AND +
                          &FROMENTLRG *NE '*LAST') THEN(DO)
              CHGVAR     VAR(&I) VALUE(20)
              CHGVAR     VAR(&J) VALUE(20)
 LOOPENT:     IF         COND(%SST(&FROMENTLRG &I 1) *NE ' ') THEN(DO)
               CHGVAR     VAR(%SST(&FROMENT &J 1)) +
                          VALUE(%SST(&FROMENTLRG &I 1))
               CHGVAR     VAR(&J) VALUE(&J - 1)
              ENDDO
              CHGVAR     VAR(&I) VALUE(&I - 1)
              IF         COND(&I *GE 1) THEN(GOTO CMDLBL(LOOPENT))
              CHGVAR     VAR(&FROMENTLRG) VALUE(&FROMENT)
             ENDDO

/*           Convert date & time                                     */
             IF         COND(%SST(&FROMTIMEL 3 13) *NE +
                          '0000000000000') THEN(DO)
              CVTDAT     DATE(%SST(&FROMTIMEL 3 7)) TOVAR(&DATE@) +
                          FROMFMT(*CYMD) TOFMT(*ISO)
              CHGVAR     VAR(&TIME@) VALUE(%SST(&FROMTIMEL 10 2) || +
                          '.' || %SST(&FROMTIMEL 12 2) || '.' || +
                          %SST(&FROMTIMEL 14 2))
              CHGVAR     VAR(&FROMTIMEZ) VALUE(&DATE@ || '-' || +
                          &TIME@ || '.000000')
             ENDDO

/*           Call program to retrieve journal entry                  */
             CALL       PGM(HRTVJRNE1) PARM(&JRNQ &JRNRCVQ +
                          &FROMENTLRG &FROMTIMEZ &NBRENT &RTNRCV@ +
                          &RTNRCVLIB@ &RTNSEQLRG@ &RTNENTDTS@ +
                          &RTNJRNCDE@ &RTNENTTYP@ &RTNCDE)

/*           Return values                                           */
             CHGVAR     VAR(&RTNRCV) VALUE(&RTNRCV@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RTNRCVLIB) VALUE(&RTNRCVLIB@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RTNSEQLRG) VALUE(&RTNSEQLRG@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RTNENTDTS) VALUE(&RTNENTDTS@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RTNJRNCDE) VALUE(&RTNJRNCDE@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RTNENTTYP) VALUE(&RTNENTTYP@)
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
