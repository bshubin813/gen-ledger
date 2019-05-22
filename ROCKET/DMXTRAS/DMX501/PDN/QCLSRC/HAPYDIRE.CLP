/* ================================================================= */
/* Object:         HAPYDIRE        *PGM CLP                          */
/*                 Command processing program for HAPYDIRE.          */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010719 FK  Initial delivery                                     */
/* 20050128 FK  New parameters: ORGSYS, ORGADR, NEWSYS, NEWADR       */
/*                              USRLESS                              */
/* 20050710 FK  Distinguish between local and remote directory ent.  */
/* ================================================================= */
             PGM        PARM(&DIREFILEQ &ORGSYS &ORGADR &NEWSYS +
                          &NEWADR &USRLESS)

/*           Declare parameter variables                             */
             DCL        VAR(&DIREFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ORGSYS) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ORGADR) TYPE(*CHAR) LEN(8)
             DCL        VAR(&NEWSYS) TYPE(*CHAR) LEN(8)
             DCL        VAR(&NEWADR) TYPE(*CHAR) LEN(8)
             DCL        VAR(&USRLESS) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&PRDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBRDIRE) TYPE(*DEC) LEN(5 0) VALUE(0)
             DCL        VAR(&NBRDIRE@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRAPY) TYPE(*DEC) LEN(5 0) VALUE(0)
             DCL        VAR(&NBRAPY@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&DIREFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DIREFILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)

/*           Declare file                                            */
             DCLF       FILE(HAPYDIRE)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             HRTVPRDLIB UTILLIB(&PRDLIB)
             CHGVAR     VAR(&NBRDIRE) VALUE(0)
             CHGVAR     VAR(&NBRAPY) VALUE(0)
             RTVNETA    SYSNAME(&SYSNAM)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&DIREFILE) VALUE(%SST(&DIREFILEQ 1 10))
             CHGVAR     VAR(&DIREFILEL) VALUE(%SST(&DIREFILEQ 11 10))

/*           Check existence of file                                 */
             CHKOBJ     OBJ(&DIREFILEL/&DIREFILE) OBJTYPE(*FILE)

/*           Create file in QTEMP that holds directory entries       */
             DLTF       FILE(QTEMP/HAPYDIRE)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HAPYDIRE) FROMLIB(&PRDLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP)

/*           Make sure that the QTEMP file is used in the program    */
             OVRDBF     FILE(HAPYDIRE) TOFILE(QTEMP/HAPYDIRE)

/*           Copy all the records to HAPYDIRE to avoid incompat.     */
             CPYF       FROMFILE(&DIREFILEL/&DIREFILE) +
                          TOFILE(QTEMP/HAPYDIRE) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
             MONMSG     MSGID(CPF0000)

/*           Send status message "Directory entries being processed" */
             SNDPGMMSG  MSGID(ADE0001) MSGF(HAUMSG) +
                          MSGDTA(&DIREFILEQ) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)

/*           Read all records in the temporary file                  */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Must address be selected?                               */
             IF         COND((&WOSDDGN *EQ &ORGADR *OR &ORGADR *EQ +
                          '*ALL') *AND (&WOSDREN *EQ &ORGSYS *OR +
                          &ORGSYS *EQ '*ALL') *AND (&USRLESS *EQ +
                          '*YES' *OR &WOSDUSRP *NE ' ')) THEN(DO)
              CHGVAR     VAR(&NBRDIRE) VALUE(&NBRDIRE + 1)
/*            Change new address?                                    */
              IF         COND(&WOSDUSRP *NE ' ' *AND &NEWADR *NE +
                          '*ORGADR' *AND &NEWADR *NE '*CURRENT') +
                          THEN(CHGVAR VAR(&WOSDDGN) VALUE(&NEWADR))
              IF         COND(&WOSDUSRP *NE ' ' *AND &NEWADR *EQ +
                          '*CURRENT') THEN(CHGVAR VAR(&WOSDDGN) +
                          VALUE(&SYSNAM))
              IF         COND(&WOSDUSRP *NE ' ' *AND &NEWSYS *NE +
                          '*ORGSYS' *AND &NEWSYS *NE '*CURRENT') +
                          THEN(CHGVAR VAR(&WOSDREN) VALUE(&NEWSYS))
              IF         COND(&WOSDUSRP *NE ' ' *AND &NEWSYS *EQ +
                          '*CURRENT') THEN(CHGVAR VAR(&WOSDREN) +
                          VALUE(&SYSNAM))
/*            Apply directory entries                                */
              IF         COND(&WOSDUSRP *EQ ' ') THEN(CHGVAR +
                          VAR(&WOSDUSRP) VALUE('*NONE'))
              ADDDIRE    USRID(&WOSDDEN &WOSDDGN) USRD(&WOSDDESC) +
                          USER(&WOSDUSRP) SYSNAME(&WOSDREN &WOSDRGN)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))

/*            If successful, increase number applied                 */
              CHGVAR     VAR(&NBRAPY) VALUE(&NBRAPY + 1)
             ENDDO

             GOTO       CMDLBL(LOOP)

/*           Send completion message                                 */
 ELOOP:      CHGVAR     VAR(%BIN(&NBRDIRE@)) VALUE(&NBRDIRE)
             CHGVAR     VAR(%BIN(&NBRAPY@)) VALUE(&NBRAPY)
             SNDPGMMSG  MSGID(ADE0002) MSGF(HAUMSG) +
                          MSGDTA(&DIREFILEQ || &NBRDIRE@ || +
                          &NBRAPY@) MSGTYPE(*COMP)

/*           Clean-up                                                */
             DLTF       FILE(QTEMP/HAPYDIRE)

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
