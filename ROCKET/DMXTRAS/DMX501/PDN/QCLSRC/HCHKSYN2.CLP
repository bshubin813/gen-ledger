/* ================================================================= */
/* Object:         HCHKSYN2        *PGM CLP                          */
/*                 Retrieves the object- and member descriptions to  */
/*                 the specified output files.                       */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000227 FK  Initial delivery                                     */
/* 20000422 FK  Also process objects if name, type not *ALL          */
/* 20001011 FK  First output to temporary file, then copy            */
/* 20001204 FK  Clear temporary file, prior to DSPOBJD/DSPFD         */
/* 20020110 FK  Fill compare library after DSPOBJD/DSPFD             */
/* 20021119 FK  Fill target/group name in description files          */
/* 20030414 FK  Write entry if member locked                         */
/* 20031010 FK  Handle failing DSPOBJD/DSPFD, do not skip to end     */
/*              Duplicate records -> Do not run 2B from here         */
/* 20050210 FK  Optional check of members                            */
/* 20050324 FK  CHKMBR parameter not correctly handled               */
/* 20050607 FK  Duplicate QADSPOBJ to avoid member full              */
/* 20051010 FK  Remove obsolete parameters                           */
/* 20060306 FK  Include library in DSPOBJD                           */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &OBJ &OBJTYP &OBJLIB &CHKMBR)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJTYP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CHKMBR) TYPE(*CHAR) LEN(4)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&MSGSTR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MSGKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MSGID) TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGDTA) TYPE(*CHAR) LEN(132)
             DCL        VAR(&MSGLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGMBR) TYPE(*CHAR) LEN(10)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve object descriptions                            */
             SNDPGMMSG  MSGID(CST0002) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &OBJ || &OBJTYP || &OBJLIB) +
                          TOPGMQ(*SAME (* *NONE *NONE))
/*           Create template file in QTEMP                           */
             CHKOBJ     OBJ(QTEMP/HCHKSYNTO) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDUPOBJ  OBJ(QADSPOBJ) FROMLIB(QSYS) OBJTYPE(*FILE) +
                          TOLIB(QTEMP) NEWOBJ(HCHKSYNTO) DATA(*NO)
              ADDPFM     FILE(QTEMP/HCHKSYNTO) MBR(HCHKSYNTO)
              CHGPF      FILE(QTEMP/HCHKSYNTO) SIZE(*NOMAX)
             ENDDO
             CLRPFM     FILE(QTEMP/HCHKSYNTO)
             MONMSG     MSGID(CPF0000)
             RCVMSG     MSGTYPE(*LAST)
             DSPOBJD    OBJ(QSYS/&OBJLIB) OBJTYPE(*LIB) +
                          DETAIL(*FULL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HCHKSYNTO)
             MONMSG     MSGID(CPF0000 MCH0000)
             DSPOBJD    OBJ(&OBJLIB/&OBJ) OBJTYPE(&OBJTYP) +
                          DETAIL(*FULL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HCHKSYNTO) OUTMBR(*FIRST *ADD)
             MONMSG     MSGID(CPF0000 MCH0000)
             CPYF       FROMFILE(QTEMP/HCHKSYNTO) +
                          TOFILE(QTEMP/HCHKSYNOD) MBROPT(*ADD) +
                          FMTOPT(*MAP *DROP)
             MONMSG     MSGID(CPF0000)
             RCVMSG     MSGTYPE(*LAST)

/*           Retrieve member descriptions                            */
             IF         COND((&OBJTYP *EQ '*ALL' *OR &OBJTYP *EQ +
                          '*FILE') *AND &CHKMBR *EQ '*YES') THEN(DO)
              SNDPGMMSG  MSGID(CST0003) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &OBJ || &OBJLIB) TOPGMQ(*SAME (* *NONE +
                          *NONE)) KEYVAR(&MSGSTR)
/*            Create template file in QTEMP                          */
              CHKOBJ     OBJ(QTEMP/HCHKSYNTM) OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CRTDUPOBJ  OBJ(QAFDMBR) FROMLIB(QSYS) OBJTYPE(*FILE) +
                          TOLIB(QTEMP) NEWOBJ(HCHKSYNTM) DATA(*NO)
               ADDPFM     FILE(QTEMP/HCHKSYNTM) MBR(HCHKSYNTM)
               CHGPF      FILE(QTEMP/HCHKSYNTM) SIZE(*NOMAX)
              ENDDO
              CLRPFM     FILE(QTEMP/HCHKSYNTM)
              MONMSG     MSGID(CPF0000)
              RCVMSG     MSGTYPE(*LAST)
              DSPFD      FILE(&OBJLIB/&OBJ) TYPE(*MBR) +
                          OUTPUT(*OUTFILE) FILEATR(*PF *LF) +
                          OUTFILE(QTEMP/HCHKSYNTM)
              MONMSG     MSGID(CPF0000 MCH0000)
/*            Verify that the DSPFD could retrieve all members        */
              RCVMSG     MSGTYPE(*LAST) RMV(*NO) KEYVAR(&MSGKEY) +
                          MSGDTA(&MSGDTA) MSGID(&MSGID)
 LOOPMSG:     IF         COND(&MSGKEY *GT &MSGSTR) THEN(DO)
               IF         COND(&MSGID *EQ 'CPF3018' *OR &MSGID *EQ +
                          'CPF3202') THEN(DO)
/*              If member locked --> Write Locked entry in MD file    */
                CHGVAR     VAR(&MSGFILE) VALUE(%SST(&MSGDTA 1 10))
                CHGVAR     VAR(&MSGLIB) VALUE(%SST(&MSGDTA 11 10))
                CHGVAR     VAR(&MSGMBR) VALUE(%SST(&MSGDTA 21 10))
                OVRDBF     FILE(HCHKSYNMD) TOFILE(QTEMP/HCHKSYNMD)
                CALL       PGM(HCHKSYN2C) PARM(&MSGLIB &MSGFILE &MSGMBR)
                DLTOVR     FILE(HCHKSYNMD)
               ENDDO
               RCVMSG     MSGTYPE(*PRV) MSGKEY(&MSGKEY) RMV(*NO) +
                          KEYVAR(&MSGKEY) MSGDTA(&MSGDTA) MSGID(&MSGID)
               GOTO       CMDLBL(LOOPMSG)
              ENDDO
              CPYF       FROMFILE(QTEMP/HCHKSYNTM) +
                          TOFILE(QTEMP/HCHKSYNMD) MBROPT(*ADD) +
                          FMTOPT(*MAP *DROP)
              MONMSG     MSGID(CPF0000)
              RCVMSG     MSGTYPE(*LAST)
             ENDDO

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG and *ESCAPE messages to previous queue   */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
