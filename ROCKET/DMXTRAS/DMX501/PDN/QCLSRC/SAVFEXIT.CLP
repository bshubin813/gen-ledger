/* ================================================================= */
/* Object:         SAVFEXIT        *PGM CLP                          */
/*                 Restores the saved IFS path/Changed files         */
/*                 onto the target system.                           */
/*                                                                   */
/* Create remarks: USEADPAUT(*NO)                                    */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000317 FK  Initial delivery                                     */
/* 20000405 FK  Retry a couple of times (10)                         */
/* 20000614 FK  Support deletion of DLS objects                      */
/* 20000630 FK  Allow configuration exchange                         */
/* 20000712 FK  IFS use different method                             */
/* 20010527 FK  Allow immediate actions in save file                 */
/* 20010813 FK  Allow immediate save/delete of IFS object            */
/* 20010913 FK  Allow for restore of changed files                   */
/* 20010919 FK  Do not execute command if restore failed             */
/* 20020110 FK  Execute HCHKSYNTGT on secondary system               */
/* 20020305 FK  Allow for delay before running command on HRSHCHGF   */
/* 20030418 FK  Change to USEADPAUT(*NO) for HA 3.6.1                */
/* 20030505 FK  Call HCHKSYNSVF instead of submitting it             */
/* 20050216 FK  Remove HSTRMIF functionality                         */
/* 20050324 FK  Utilities library in savf description                */
/* ================================================================= */
             PGM        PARM(&SAVF &SAVFL)

/*           Declare parameter variables                              */
             DCL        VAR(&SAVF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFL) TYPE(*CHAR) LEN(10)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&TEXT) TYPE(*CHAR) LEN(50)
             DCL        VAR(&DEV) TYPE(*CHAR) LEN(100)
             DCL        VAR(&IFSOBJ) TYPE(*LGL)
             DCL        VAR(&IMMOBJ) TYPE(*LGL)
             DCL        VAR(&DLSOBJ) TYPE(*LGL)
             DCL        VAR(&CFGOBJ) TYPE(*LGL)
             DCL        VAR(&LIBOBJ) TYPE(*LGL)
             DCL        VAR(&CFGTYP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SAVFQ) TYPE(*CHAR) LEN(20)

             DCL        VAR(&IFSPTH) TYPE(*CHAR) LEN(512)
             DCL        VAR(&RTYCNT) TYPE(*DEC) LEN(2 0)

             DCL        VAR(&SAVTYP) TYPE(*CHAR) LEN(3)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&DOC) TYPE(*CHAR) LEN(12)
             DCL        VAR(&DLOPTH) TYPE(*CHAR) LEN(256)

             DCL        VAR(&SVFTYP) TYPE(*CHAR) LEN(8)
             DCL        VAR(&SAVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(256)
             DCL        VAR(&CMDDLY@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CMDDLY) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&DLY) TYPE(*DEC) LEN(6 0)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&SAVFQ) VALUE(&SAVF || &SAVFL)
             CHGVAR     VAR(&DEV) VALUE('/QSYS.LIB/' |< &SAVFL |< +
                          '.LIB/' |< &SAVF |< '.FILE')
             CHGVAR     VAR(&CFGOBJ) VALUE('0')
             CHGVAR     VAR(&DLSOBJ) VALUE('0')
             CHGVAR     VAR(&IFSOBJ) VALUE('0')
             CHGVAR     VAR(&IMMOBJ) VALUE('0')
             CHGVAR     VAR(&LIBOBJ) VALUE('0')

/*           First check that the save file was produced by HRSHCHGF */
/*           or HCHKSYNTGT                                           */
             RTVOBJD    OBJ(&SAVFL/&SAVF) OBJTYPE(*FILE) TEXT(&TEXT)
             CHGVAR     VAR(&SVFTYP) VALUE(%SST(&TEXT 1 8))
             IF         COND(&SVFTYP *NE 'HRSHCHGF' *AND &SVFTYP *NE +
                          'HCHKSYNT') THEN(DO)
/*            Send program message "Info: Save file not a Hxxx file  */
              SNDPGMMSG  MSGID(SAV0001) MSGF(HAUMSG) MSGDTA(&SAVF || +
                          &SAVFL) TOPGMQ(*SAME) MSGTYPE(*INFO)
              MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(CPF9898) +
                          MSGF(QCPFMSG) MSGDTA('Please add the +
                          DMXtras customer library to your apply +
                          job library list') MSGTYPE(*DIAG))
              GOTO       CMDLBL(END)
             ENDDO

/*           Add DMXtras customer library to library list             */
             CHGVAR     VAR(&UTLLIB) VALUE(%SST(&TEXT 16 10))
             ADDLIBLE   LIB(&UTLLIB) POSITION(*LAST)
             MONMSG     MSGID(CPF0000 MCH0000)

/*           If HCHKSYNTGT save file --> submit job                   */
             IF         COND(&SVFTYP *EQ 'HCHKSYNT') THEN(CALL +
                          PGM(HCHKSYNSVF) PARM(&SAVF &SAVFL '1'))

/*           Check if library objects were saved                     */
             IF         COND(&SVFTYP *EQ 'HRSHCHGF') THEN(DO)
              CHGVAR     VAR(&LIBOBJ) VALUE('1')
             ENDDO

/*           Send program message "Starting restore of ... "         */
             SNDPGMMSG  MSGID(SAV0002) MSGF(HAUMSG) MSGDTA(&SAVF || +
                          &SAVFL) TOPGMQ(*SAME) MSGTYPE(*INFO)
             MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(CPF9898) +
                          MSGF(QCPFMSG) MSGDTA('Please add the +
                          DMXtras customer library to your apply +
                          job library list') MSGTYPE(*DIAG))

/*           Restore the objects saved into the save file            */
             CHGVAR     VAR(&RTYCNT) VALUE(0)

/*           Restore library objects                                 */
 RSTOBJ:     IF         COND(&LIBOBJ) THEN(DO)
              RSTOBJ     OBJ(*ALL) SAVLIB(QTEMP) DEV(*SAVF) +
                          SAVF(&SAVFL/&SAVF) MBROPT(*ALL) +
                          ALWOBJDIF(*ALL)
              RTVDTAARA  DTAARA(QTEMP/HRSHCHGF (1 10)) RTNVAR(&SAVLIB)
              RTVDTAARA  DTAARA(QTEMP/HRSHCHGF (11 256)) RTNVAR(&CMD)
              RTVDTAARA  DTAARA(QTEMP/HRSHCHGF (267 5)) RTNVAR(&CMDDLY@)
/*            Calculate proper delay                                 */
              IF         COND(&CMDDLY@ *EQ '*NONE') THEN(CHGVAR +
                          VAR(&CMDDLY) VALUE(-1))
              ELSE       CMD(CHGVAR VAR(&CMDDLY) VALUE(&CMDDLY@))
/*            First restore the objects                              */
              RSTOBJ     OBJ(*ALL) SAVLIB(&SAVLIB) DEV(*SAVF) +
                          SAVF(QTEMP/HRSHCHGF)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))
/*            If command not blanks --> exeucte                      */
              IF         COND(&CMD *NE ' ') THEN(DO)
/*             Delay                                                 */
               IF         COND(&CMDDLY *NE -1) THEN(DO)
                CHGVAR     VAR(&DLY) VALUE(&CMDDLY * 60)
                DLYJOB     DLY(&DLY)
               ENDDO
/*             Execute command                                       */
               CALL       PGM(QCMDEXC) PARM(&CMD 256)
               MONMSG     MSGID(CPF0000)
              ENDDO
             ENDDO

/*           Make sure that save file is cleared in case of HRSHCHGF */
             IF         COND(&SVFTYP *EQ 'HRSHCHGF') THEN(DO)
              CLRSAVF    FILE(&SAVFL/&SAVF)
              MONMSG     MSGID(CPF0000)
             ENDDO

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
