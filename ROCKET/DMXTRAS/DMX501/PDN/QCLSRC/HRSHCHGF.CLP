/* ================================================================= */
/* Object:         HRSHCHGF        *PGM CLP                          */
/*                 Command processing program for HRSHCHGF.          */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010914 FK  Initial delivery                                     */
/* 20010919 FK  Retry save to save file (maximum 10 times)           */
/*              Allow specification of refresh method                */
/* 20020305 FK  Include delay before running command                 */
/* 20050324 FK  Include &UTLLIB in save file text                    */
/* 20111222 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&OBJQ &RSHMTH &SAVFQ &CMD &CMDDLY +
                          &MBRDBFRQ &MBRDAFTQ)

/*           Declare parameter variables                             */
             DCL        VAR(&OBJQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RSHMTH) TYPE(*CHAR) LEN(5)
             DCL        VAR(&SAVFQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(256)
             DCL        VAR(&CMDDLY) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MBRDBFRQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&MBRDAFTQ) TYPE(*CHAR) LEN(20)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&OBJ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDBFR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDBFRL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDAFT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDAFTL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&OBJLST) TYPE(*CHAR) LEN(3300)

             DCL        VAR(&SAVCMD) TYPE(*CHAR) LEN(4096)
             DCL        VAR(&NBROBJ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBROBJ@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&CMDDLY@) TYPE(*CHAR) LEN(5)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&OBJLST) VALUE('*ALL')
             IF         COND(&CMDDLY *EQ -1) THEN(CHGVAR +
                          VAR(&CMDDLY@) VALUE('*NONE'))
             ELSE       CMD(CHGVAR VAR(&CMDDLY@) VALUE(&CMDDLY))

/*           Split qualifiers                                        */
             CHGVAR     VAR(&OBJ) VALUE(%SST(&OBJQ 1 10))
             CHGVAR     VAR(&OBJL) VALUE(%SST(&OBJQ 11 10))
             CHGVAR     VAR(&SAVF) VALUE(%SST(&SAVFQ 1 10))
             CHGVAR     VAR(&SAVFL) VALUE(%SST(&SAVFQ 11 10))
             CHGVAR     VAR(&MBRDBFR) VALUE(%SST(&MBRDBFRQ 1 10))
             CHGVAR     VAR(&MBRDBFRL) VALUE(%SST(&MBRDBFRQ 11 10))
             CHGVAR     VAR(&MBRDAFT) VALUE(%SST(&MBRDAFTQ 1 10))
             CHGVAR     VAR(&MBRDAFTL) VALUE(%SST(&MBRDAFTQ 11 10))

/*           Verify that the specified libraries exist               */
             CHKOBJ     OBJ(&OBJL) OBJTYPE(*LIB)
             CHKOBJ     OBJ(&SAVFL) OBJTYPE(*LIB)

/*           If OBJ(*CHG) specified --> Check existence of outfiles  */
             IF         COND(&OBJ *EQ '*CHG') THEN(DO)
              CHKOBJ     OBJ(&MBRDBFRL/&MBRDBFR) OBJTYPE(*FILE)
              CHKOBJ     OBJ(&MBRDAFTL/&MBRDAFT) OBJTYPE(*FILE)
             ENDDO

/*           Retrieve utilities library                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Prepare files in QTEMP of OBJ(*CHG)                     */
             IF         COND(&OBJ *EQ '*CHG') THEN(DO)
/*            Create temporary files in QTEMP                        */
              DLTF       FILE(QTEMP/HRSHCHGFB)
              MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
              DLTF       FILE(QTEMP/HRSHCHGFA)
              MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
              CRTDUPOBJ  OBJ(HRSHCHGFB) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP)
              CRTDUPOBJ  OBJ(HRSHCHGFA) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP)
/*            Copy in the records                                    */
              CPYF       FROMFILE(&MBRDBFRL/&MBRDBFR) +
                          TOFILE(QTEMP/HRSHCHGFB) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
              CPYF       FROMFILE(&MBRDAFTL/&MBRDAFT) +
                          TOFILE(QTEMP/HRSHCHGFA) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
/*            Make sure that the QTEMP files are used in the program */
              OVRDBF     FILE(HRSHCHGFB) TOFILE(QTEMP/HRSHCHGFB)
              OVRDBF     FILE(HRSHCHGFA) TOFILE(QTEMP/HRSHCHGFA)
/*            Determine list of changed files                        */
              CHGVAR     VAR(&OBJLST) VALUE(' ')
              CALL       PGM(HRSHCHGF1) PARM(&OBJL &RSHMTH &OBJLST +
                          &NBROBJ)
              CHGVAR     VAR(%BIN(&NBROBJ@)) VALUE(&NBROBJ)
/*            Delete override                                        */
              DLTOVR     FILE(HRSHCHGFB)
              DLTOVR     FILE(HRSHCHGFA)
             ENDDO

/*           If objects still must be saved --> prepare for save     */
             IF         COND(&OBJLST *NE '*NONE' *AND &RSHMTH *EQ +
                          '*SAVF') THEN(DO)
              CHKOBJ     OBJ(&SAVFL/&SAVF) OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
/*             Create save file that will be mirrored                */
               CRTSAVF    FILE(&SAVFL/&SAVF) TEXT('HRSHCHGF       ' || +
                          &UTLLIB || ' - Saved objects')
               GOTO       CMDLBL(CRTTMP)
              ENDDO
/*            Clear save file if it already exists                   */
              CLRSAVF    FILE(&SAVFL/&SAVF)
/*            Create temporary save file in QTEMP                    */
 CRTTMP:      DLTF       FILE(QTEMP/HRSHCHGF)
              MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
              CRTSAVF    FILE(QTEMP/HRSHCHGF) TEXT('HRSHCHGF - Saved +
                          library ' || &OBJL)
/*            Create data area with saved library and command        */
              DLTDTAARA  DTAARA(QTEMP/HRSHCHGF)
              MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
              CRTDTAARA  DTAARA(QTEMP/HRSHCHGF) TYPE(*CHAR) LEN(512) +
                          VALUE(&OBJL || &CMD || &CMDDLY@) +
                          TEXT('HRSHCHGF - Library and command')
/*            Compose and execute save command                       */
              CHGVAR     VAR(&SAVCMD) VALUE('SAVOBJ OBJ(' || &OBJLST +
                          || ') LIB(' || &OBJL || ') DEV(*SAVF) +
                          SAVF(QTEMP/HRSHCHGF) DTACPR(*YES)')
              CALL       PGM(QCMDEXC) PARM(&SAVCMD 4096)
/*            Save objects in QTEMP to save file                     */
              CHGVAR     VAR(&I) VALUE(1)
 SAVSAVF:     SAVOBJ     OBJ(HRSHCHGF) LIB(QTEMP) DEV(*SAVF) +
                          SAVF(&SAVFL/&SAVF) DTACPR(*YES)
              MONMSG     MSGID(CPF9812) EXEC(DO)
               IF         COND(&I *LE 10) THEN(DO)
                DLYJOB     DLY(1)
                RCVMSG     MSGTYPE(*LAST)
                CHGVAR     VAR(&I) VALUE(&I + 1)
                GOTO       CMDLBL(SAVSAVF)
               ENDDO
               ELSE       CMD(GOTO CMDLBL(ERROR))
              ENDDO
             ENDDO

/*           Send completion message                                 */
             IF         COND(&RSHMTH *EQ '*SAVF') THEN(DO)
              IF         COND(&OBJLST *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(RCF0001) MSGF(HAUMSG) MSGDTA(&OBJL +
                          || &SAVFQ || &MBRDBFRQ || &MBRDAFTQ) +
                          MSGTYPE(*COMP))
              IF         COND(&OBJ *EQ '*CHG' *AND &OBJLST *NE +
                          '*NONE') THEN(SNDPGMMSG MSGID(RCF0002) +
                          MSGF(HAUMSG) MSGDTA(&OBJL || &SAVFQ || +
                          &MBRDBFRQ || &MBRDAFTQ || &NBROBJ@) +
                          MSGTYPE(*COMP))
             ENDDO
             IF         COND(&OBJ *EQ '*ALL') THEN(SNDPGMMSG +
                          MSGID(RCF0003) MSGF(HAUMSG) MSGDTA(&OBJL +
                          || &SAVFQ) MSGTYPE(*COMP))
             IF         COND(&RSHMTH *EQ '*ACT') THEN(SNDPGMMSG +
                          MSGID(RCF0005) MSGF(HAUMSG) MSGDTA(&OBJL +
                          || &MBRDBFRQ || &MBRDAFTQ || &NBROBJ@) +
                          MSGTYPE(*COMP))

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
