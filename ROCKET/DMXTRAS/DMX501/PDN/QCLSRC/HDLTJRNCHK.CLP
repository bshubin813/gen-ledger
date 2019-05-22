/* ================================================================= */
/* Object:         HDLTJRNCHK      *PGM CLP                          */
/*                 Command processing program for HDLTJRNCHK.        */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020226 FK  Initial delivery                                     */
/* 20021015 FK  Also create temp LF HUFGTTG                          */
/* 20030512 FK  Add support for iCluster                             */
/* 20030807 FK  Check how journal is used by product                 */
/* 20031107 FK  Create LF for TS (5.1)                               */
/* 20040526 FK  New parameter for processing type (*MRK/*ACT)        */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20070117 FK  Allow checking for multiple TS libraries             */
/*              Return journal receiver and -library                 */
/* 20070122 FK  Return code for success of retrieval                 */
/* 20070511 FK  Receiver attach date, journal type and product lib   */
/*              Replaces HDLTRCV4                                    */
/*              Do not send messages to alert message queue          */
/*              No escapes to be percolated to calling program       */
/* 20111220 FK  Remove HA/CDC                                        */
/* ================================================================= */
             PGM        PARM(&JRNQ &PRD &PRC &PRCTYP &JRNTYPE &RCV +
                          &RCVLIB &RCVATTDT &GRPNAM &PRDLIB +
                          &RTNCDE)

/*           Declare parameter variables                             */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)
             DCL        VAR(&PRC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&PRCTYP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JRNTYPE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&RCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVATTDT) TYPE(*CHAR) LEN(13)
             DCL        VAR(&GRPNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CURLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)

             DCL        VAR(&RTNTMP) TYPE(*CHAR) LEN(7)
             DCL        VAR(&RESULT) TYPE(*CHAR) LEN(10)

             DCL        VAR(&PRC@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&PRCTYP@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JRNTYPE@) TYPE(*CHAR) LEN(8)
             DCL        VAR(&RCV@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVLIB@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVATTDT@) TYPE(*CHAR) LEN(13)
             DCL        VAR(&TGTNAM@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GRPNAM@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRDLIB@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE@) TYPE(*CHAR) LEN(7)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&RTNCDE@) VALUE(' ')
             CHGVAR     VAR(&PRC@) VALUE('*NO')
             RTVJOBA    CURLIB(&CURLIB)
             IF         COND(&CURLIB *EQ '*NONE') THEN(CHGVAR +
                          VAR(&CURLIB) VALUE('*CRTDFT'))
             HRTVNETA   SYSNAME(&SYSNAM)

/*           Initialise return variables                             */
             CHGVAR     VAR(&RTNCDE@) VALUE(' ')
             CHGVAR     VAR(&PRC@) VALUE('*NO')
             CHGVAR     VAR(&PRCTYP@) VALUE(' ')
             CHGVAR     VAR(&JRNTYPE@) VALUE(' ')
             CHGVAR     VAR(&RCV@) VALUE(' ')
             CHGVAR     VAR(&RCVLIB@) VALUE(' ')
             CHGVAR     VAR(&RCVATTDT@) VALUE('9999999999999')
             CHGVAR     VAR(&GRPNAM@) VALUE(' ')
             CHGVAR     VAR(&PRDLIB@) VALUE(' ')

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))

/*           Verify that the specified journal exists                */
             CHKOBJ     OBJ(&JRNL/&JRN) OBJTYPE(*JRN)

/*           Retrieve product libraries                              */
             HRTVPRDLIB ICPRODLIB(&ICLIB)

/*           Product must be in library list                         */
             IF         COND(&PRD *EQ '*IC' *AND &ICLIB *EQ '*NONE') +
                          THEN(SNDPGMMSG MSGID(DMX0012) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Determine journal type                                  */
             CALL       PGM(HDLTRCV4E) PARM(&JRN &JRNL &JRNTYPE@ +
                          &RTNTMP)

/*           Retrieve journal position for iCluster                  */
             IF         COND(&PRD *EQ '*IC') THEN(DO)
              CHGVAR     VAR(&PRDLIB@) VALUE(&ICLIB)
              CHGCURLIB  CURLIB(&ICLIB)
              SNDPGMMSG  MSGID(DJR0027) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &ICLIB || &PRD) TOPGMQ(*SAME (* +
                          *NONE *NONE)) MSGTYPE(*INFO)
/*            Create LFs over product                                */
              CALL       PGM(HCRTLF) PARM('HUDGTJL')
              CALL       PGM(HCRTLF) PARM('HUDGTTG')
              CALL       PGM(HCRTLF) PARM('HUDSJJL')
              CALL       PGM(HCRTLF) PARM('HUTGTTI')
              CALL       PGM(HCRTLF) PARM('HUGRPGI')
              CALL       PGM(HCRTLF) PARM('HUFGTTG')
              OVRDBF     FILE(HUDGTJL) TOFILE(QTEMP/HUDGTJL)
              OVRDBF     FILE(HUDGTTG) TOFILE(QTEMP/HUDGTTG)
              OVRDBF     FILE(HUDSJJL) TOFILE(QTEMP/HUDSJJL)
              OVRDBF     FILE(HUTGTTI) TOFILE(QTEMP/HUTGTTI)
              OVRDBF     FILE(HUGRPGI) TOFILE(QTEMP/HUGRPGI)
              OVRDBF     FILE(HUFGTTG) TOFILE(QTEMP/HUFGTTG)
/*            Create extra LF over iCluster                          */
              CALL       PGM(HCRTLF) PARM('HIGRPGN')
              CALL       PGM(HCRTLF) PARM('HUPIDTGJR')
              OVRDBF     FILE(HIGRPGN) TOFILE(QTEMP/HIGRPGN)
              OVRDBF     FILE(HUPIDTGJR) TOFILE(QTEMP/HUPIDTGJR)
/*            Is journal used by product and how?                    */
              CALL       PGM(HDLTRCV4C) PARM(&PRD &PRDLIB@ &JRN &JRNL +
                          &JRNTYPE@ &SYSNAM &PRC@ &PRCTYP@)
              IF         COND(&PRC@ *EQ '*YES') THEN(DO)
/*             If local journal and actively read --> RTVHAPOS       */
               IF         COND(&PRCTYP@ *EQ '*ACT' *AND &JRNTYPE@ *EQ +
                          '*LOCAL') THEN(DO)
                SNDPGMMSG  MSGID(DJR0034) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRN || &PRD) TOPGMQ(*SAME) MSGTYPE(*INFO)
                RTVHAPOS   JOURNAL(&JRNL/&JRN) TARGET(&TGTNAM@) +
                          GROUP(&GRPNAM@) JRNRCVNME(&RCV@) +
                          JRNRCVLIB(&RCVLIB@) RESULT(&RESULT)
                IF         COND(&RESULT *EQ '*ERROR' *OR %SST(&RCV@ 1 5) +
                          *EQ '*NONE') THEN(DO)
                 CHGVAR     VAR(&RTNCDE@) VALUE('DJR0002')
                 SNDPGMMSG  MSGID(DJR0002) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RCV@ || &RCVLIB@ || &TGTNAM@ || +
                          &GRPNAM@ || &PRD) MSGTYPE(*DIAG)
                ENDDO      /* Error in RTVHAPOS */
                ELSE       CMD(DO)
                 CALL       PGM(HDLTRCV4F) PARM(&RCV@ &RCVLIB@ +
                          &RCVATTDT@ &RTNCDE@)
                ENDDO      /* No error in RTVHAPOS */
               ENDDO      /* Process type *ACT *LOCAL */
/*             If remote journal and actively read --> get from HAPID*/
               IF         COND(&PRCTYP@ *EQ '*ACT' *AND &JRNTYPE@ *EQ +
                          '*REMOTE') THEN(DO)
                SNDPGMMSG  MSGID(DJR0043) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &PRD) TOPGMQ(*SAME) MSGTYPE(*INFO)
                CALL       PGM(HDLTRCV4D) PARM(&JRN &JRNL &RCV@ +
                          &RCVLIB@ &RCVATTDT@ &TGTNAM@ &GRPNAM@ +
                          &RTNTMP)
                IF         COND(&RTNTMP *NE ' ') THEN(DO)
                 CHGVAR     VAR(&RTNCDE@) VALUE('DJR0004')
                 SNDPGMMSG  MSGID(DJR0004) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RCV@ || &RCVLIB@ || &TGTNAM@ || +
                          &GRPNAM@ || &PRD) MSGTYPE(*DIAG)
                ENDDO      /* Error in HDLTRCV4D */
               ENDDO      /* Process type *ACT *REMOTE */
/*             If used by marked postion --> get from HADSAVJRN      */
               IF         COND(&PRCTYP@ *EQ '*MRK') THEN(DO)
                CALL       PGM(HDLTRCV4A) PARM(&PRD &JRN &JRNL &SYSNAM +
                          &RCV@ &RCVLIB@ &RCVATTDT@ &TGTNAM@ +
                          &GRPNAM@ &RTNTMP)
                IF         COND(&RTNTMP *NE ' ') THEN(DO)
                 CHGVAR     VAR(&RTNCDE@) VALUE('DJR0036')
                 SNDPGMMSG  MSGID(DJR0036) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RCV@ || &RCVLIB@ || &TGTNAM@ || +
                          &GRPNAM@) MSGTYPE(*DIAG)
                ENDDO
/*              Send warning message that marked position used       */
                SNDPGMMSG  MSGID(DJR0035) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RCV@ || &RCVLIB@ || &TGTNAM@ || +
                          &GRPNAM@) MSGTYPE(*INFO)
               ENDDO      /* Process type *MRK */
/*             Issue message with retrieved position in job log      */
               IF         COND(&RTNCDE@ *EQ ' ') THEN(DO)
                SNDPGMMSG  MSGID(DJR0024) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RCV@ || &RCVLIB@ || &RCVATTDT@ +
                          || &PRD || &TGTNAM@ || &GRPNAM@) +
                          TOPGMQ(*SAME)
               ENDDO
              ENDDO      /* Processed */
             ENDDO      /* iC */

             CHGCURLIB  CURLIB(&CURLIB)
             RCVMSG     MSGTYPE(*LAST)

/*           If error --> return low value for receiver attach dts   */
             IF         COND(&RTNCDE@ *NE ' ') THEN(CHGVAR +
                          VAR(&RCVATTDT@) VALUE('0000000000000'))
             IF         COND(&RTNCDE@ *EQ ' ' *AND &PRC@ *EQ '*NO') +
                          THEN(CHGVAR VAR(&RCVATTDT@) +
                          VALUE('9999999999999'))

/*           Return values to calling program                        */
             CHGVAR     VAR(&PRC) VALUE(&PRC@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&PRCTYP) VALUE(&PRCTYP@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&JRNTYPE) VALUE(&JRNTYPE@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RCV) VALUE(&RCV@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RCVLIB) VALUE(&RCVLIB@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RCVATTDT) VALUE(&RCVATTDT@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&PRDLIB) VALUE(&PRDLIB@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&GRPNAM) VALUE(&GRPNAM@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&RTNCDE) VALUE(&RTNCDE@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

             RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGID(&RTNCDE@)
             CHGVAR     VAR(&RTNCDE) VALUE(&RTNCDE@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
