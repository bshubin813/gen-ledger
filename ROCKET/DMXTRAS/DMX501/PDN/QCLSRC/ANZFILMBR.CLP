 /*******************************************************************/
 /*  -----------------------------                                  */
 /*  DETERMINE FILE ATTRIBUTES                                      */
 /*  -----------------------------                                  */
 /*   (C) Copyright Rocket Software, Inc. 1997-2012.                */
 /*   All rights reserved.                                          */
 /*                                                                 */
 /*******************************************************************/

             PGM        PARM(&RECS)

 /*******************************************************************/
 /*  User Defined Program Varaiables                                */
 /*******************************************************************/
             DCL        VAR(&RECS) TYPE(*DEC) LEN(10 0)
             DCLF       FILE(ANZFILD)

             OVRDBF     FILE(ANZFILD) TOFILE(QTEMP/ANZFILD)
             CHGVAR     VAR(&RECS) VALUE(0)
NEXT:        RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ENDPGM))
             CHGVAR     VAR(&RECS) VALUE(&RECS + &MLNRCD)
             GOTO       CMDLBL(NEXT)

 ENDPGM:     ENDPGM

