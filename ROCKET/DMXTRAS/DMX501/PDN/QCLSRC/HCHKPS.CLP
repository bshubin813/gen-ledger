/********************************************************************/
/*                                                                  */
/* 5722SS1 V5R4M0 060210     RTVCLSRC Output     12/22/11 17:19:36  */
/*                                                                  */
/* Program name . . . . . . . . . . . . . . :   HCHKPS            PN*/
/* Library name . . . . . . . . . . . . . . :   DMX421OBJ         PL*/
/* Original source file . . . . . . . . . . :   QCLSRC            SN*/
/* Library name . . . . . . . . . . . . . . :   DMX421SRC         SL*/
/* Original source member . . . . . . . . . :   HCHKPS            SM*/
/* Source file change                                               */
/*   date/time  . . . . . . . . . . . . . . :   07/26/11 03:50:47 SC*/
/* Patch option . . . . . . . . . . . . . . :   *NOPATCH          PO*/
/* User profile . . . . . . . . . . . . . . :   *USER             UP*/
/* Text . . . : Check if program is in the program stack          TX*/
/* Owner  . . . . . . . . . . . . . . . . . :   QSECOFR           OW*/
/* Patch change ID  . . . . . . . . . . . . :                     PC*/
/* Patch APAR ID  . . . . . . . . . . . . . :                     PA*/
/* User mod flag  . . . . . . . . . . . . . :   *YES              UM*/
/*                                                                ED*/
/********************************************************************/
     PGM PARM(&PGM &INSTK)
     DCL VAR(&PGM) TYPE(*CHAR) LEN(10)
     DCL VAR(&INSTK) TYPE(*CHAR) LEN(4)
     DCL VAR(&APIERR) TYPE(*CHAR) LEN(4)
     DCL VAR(&MSGKEY) TYPE(*CHAR) LEN(4)
     MONMSG MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))
     CHGVAR VAR(&INSTK) VALUE(*YES)
     SNDPGMMSG MSGID(CPF9897) MSGF(QCPFMSG) MSGDTA('Check if program'-
 |> &PGM |> 'is in the stack; this message will be removed') -
TOPGMQ(*SAME (&PGM)) KEYVAR(&MSGKEY)
     MONMSG MSGID(CPF0000) EXEC(DO)
     RCVMSG MSGTYPE(*LAST)
     CHGVAR VAR(&INSTK) VALUE(*NO)
     GOTO CMDLBL(CHKEND)
     ENDDO
     RMVMSG PGMQ(*SAME (&PGM)) MSGQ(*PGMQ) MSGKEY(&MSGKEY) -
CLEAR(*BYKEY)
     MONMSG MSGID(CPF0000)
CHKEND: +
     GOTO CMDLBL(END)
ERROR: +
     CHGVAR VAR(&APIERR) VALUE(X'00000000')
     CALL PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' '*' X'00000001' -
&APIERR)
     CHGVAR VAR(&APIERR) VALUE(X'00000000')
     CALL PGM(QMHRSNEM) PARM(' ' &APIERR)
END: +
     ENDPGM
