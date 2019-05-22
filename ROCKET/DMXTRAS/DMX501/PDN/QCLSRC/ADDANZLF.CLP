 /*******************************************************************/
 /*  -----------------------------                                  */
 /*  DETERMINE FILE ATTRIBUTES                                      */
 /*  -----------------------------                                  */
 /*                                                                 */
 /*  (C) Copyright Rocket Software, Inc. 1997-2012.                 */
 /*  All rights reserved.                                           */

             PGM        PARM(&FIL &LIB)

 /*******************************************************************/
 /*  User Defined Program Varaiables                                */
 /*******************************************************************/
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FIL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UNIQ) TYPE(*CHAR) LEN(1) VALUE('N')
             DCL        VAR(&JOIN) TYPE(*CHAR) LEN(1) VALUE('N')
             DCL        VAR(&SEQ) TYPE(*DEC) LEN(4 0) VALUE(2)
             DCL        VAR(&RECS) TYPE(*DEC) LEN(10 0) VALUE(0)
             DCL        VAR(&RLEN) TYPE(*DEC) LEN(5 0) VALUE(0)
             DCL        VAR(&KEYYES) TYPE(*CHAR) LEN(1) VALUE('K')
             DCL        VAR(&LGFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LGLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LGFATR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&BLANK1) TYPE(*CHAR) LEN(1) VALUE(' ')
             DCL        VAR(&BLANK10) TYPE(*CHAR) LEN(10) +
                          VALUE('          ')
             DCLF       FILE(ANZFILB)

 /*******************************************************************/
 /*  DISPLAY DATABASE RELATIONS INTO TEMPORARY FILE                 */
 /*******************************************************************/
             DSPDBR     FILE(&LIB/&FIL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/ANZFILB) OUTMBR(*FIRST +
                          *REPLACE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO +
                          CMDLBL(ENDPGM))

             OVRDBF     FILE(ANZFILB) TOFILE(QTEMP/ANZFILB)
 NEXT:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO ENDPGM)
             IF         COND(&WHNO *EQ 0) THEN(DO)
             GOTO       CMDLBL(NEXT)
             ENDDO
             IF         COND(&WHREFI *EQ '          ') THEN(DO)
             GOTO       CMDLBL(NEXT)
             ENDDO
             DSPFD      FILE(&WHRELI/&WHREFI) TYPE(*ACCPTH) +
                          OUTPUT(*OUTFILE) FILEATR(*ALL) +
                          OUTFILE(QTEMP/ANZFILC) OUTMBR(*FIRST +
                          *REPLACE)
             CALL       PGM(ADDANZFLD) PARM(&WHREFI &WHRELI &UNIQ +
                          &JOIN)
             CALL       PGM(ADDANZFILE) PARM(&WHREFI &WHRELI 'LF' +
                          &BLANK1 &BLANK1 &BLANK10 &BLANK10 &BLANK1 +
                          &SEQ &UNIQ &RECS &JOIN &FIL &LIB &BLANK1 +
                          &RLEN &KEYYES)
             CHGVAR     VAR(&SEQ) VALUE(&SEQ + 1)
             CHGVAR     VAR(&UNIQ) VALUE('N')
             CHGVAR     VAR(&JOIN) VALUE('N')

             GOTO       CMDLBL(NEXT)

 ENDPGM:     ENDPGM

