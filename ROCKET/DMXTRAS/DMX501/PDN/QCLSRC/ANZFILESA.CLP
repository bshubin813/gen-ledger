             PGM        PARM(&FIL &LIB)

 /*******************************************************************/
 /*  User Defined Program Varaiables                                */
 /*******************************************************************/
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FIL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SEQ) TYPE(*DEC) LEN(4 0) VALUE(1)
             DCL        VAR(&UNIQ) TYPE(*CHAR) LEN(1) VALUE('N')
             DCL        VAR(&JOIN) TYPE(*CHAR) LEN(1) VALUE('N')
             DCL        VAR(&MBRS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&RECS) TYPE(*DEC) LEN(10 0)

             DCLF       FILE(ANZFILA)

             DSPFD      FILE(&LIB/&FIL) TYPE(*ATR) OUTPUT(*OUTFILE) +
                          FILEATR(*PF) OUTFILE(QTEMP/ANZFILA) +
                          OUTMBR(*FIRST *REPLACE)
             MONMSG     MSGID(CPF3012 CPF3092) EXEC(DO)
             SNDUSRMSG  MSG('DSPFD - The requested file/library does +
                          not exist or is not a file. Please verify +
                          entry') MSGTYPE(*INFO) TOMSGQ(*EXT)
             GOTO      CMDLBL(ENDPGM)
             ENDDO

             OVRDBF     FILE(ANZFILA) TOFILE(QTEMP/ANZFILA)
             OVRDBF     FILE(ANZFILC) TOFILE(QTEMP/ANZFILC)
             OVRDBF     FILE(ANZFILD) TOFILE(QTEMP/ANZFILD)

NEXT:        RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ENDPGM))
             IF         COND(&PHDTAT *EQ 'D') THEN(DO)
             CALL       PGM(RESETANZ) PARM(&PHFILE &PHLIB)
             IF         COND(&PHACCP *EQ 'K') THEN(DO)
             DSPFD      FILE(&PHLIB/&PHFILE) TYPE(*ACCPTH) +
                          OUTPUT(*OUTFILE) FILEATR(*ALL) +
                          OUTFILE(QTEMP/ANZFILC) OUTMBR(*FIRST +
                          *REPLACE)
             CALL       PGM(ADDANZFLD) PARM(&PHFILE &PHLIB &UNIQ &JOIN)
             ENDDO
             DSPFD      FILE(&PHLIB/&PHFILE) TYPE(*MBRLIST) +
                          OUTPUT(*OUTFILE) FILEATR(*PF) +
                          OUTFILE(QTEMP/ANZFILD) OUTMBR(*FIRST +
                          *REPLACE)
             CALL       PGM(ANZFILMBR) PARM(&RECS)
             CHGVAR     VAR(&MBRS) VALUE('N')
             IF         COND(&PHNOMB *GT 1) THEN(DO)
             CHGVAR     VAR(&MBRS) VALUE('Y')
             ENDDO
             CALL       PGM(ADDANZFILE) PARM(&PHFILE &PHLIB &PHFATR +
                          &MBRS &PHJRNL &PHJRNM &PHJRLB &PHJRIM +
                          &SEQ &UNIQ &RECS &JOIN &PHFILE &PHLIB +
                          &PHRUSE &PHMXRL &PHACCP)
             CALL       PGM(ADDANZLF) PARM(&PHFILE &PHLIB)
             ENDDO
             CHGVAR     VAR(&UNIQ) VALUE('N')
             CHGVAR     VAR(&JOIN) VALUE('N')
             CHGVAR     VAR(&RECS) VALUE(0)
             GOTO       CMDLBL(NEXT)

 ENDPGM:     ENDPGM

