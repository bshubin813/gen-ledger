/*********************************************************************/
/*                                                                   */
/*   -------------------------                                       */
/*   INTERACTIVE FILE ANALYSIS                                       */
/*   -------------------------                                       */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is called by HAMENU and accepts a file name and library   */
/* from display file ANZFILEINT and then runs the programs ANZFILESI */
/* and DSPANZFILI to display inetractively a file analysis for the   */
/* library and file entered.                                         */
/*                                                                   */
/* Input Parameters:  As provided by display file ANZFILEBAT:        */
/*                    &FNAM     - File to analyze                    */
/*                    &FLIB     - Library containing the file        */
/*                    As required by the TFRCTL from HAMENU          */
/*                    &MENUNAME - Menu name                          */
/*                    &MENULIB  - Menu library                       */
/*                    &ACTION   - Function key action                */
/*                                                                   */
/* Output Parameters: To pgm ANZFILSI - &FNAM and &FLIB              */
/*                                                                   */
/* Author:            DataMirror Corporation                         */
/*                                                                   */
/* Change Log:        Mike Warkentin Jan 07, 2000                    */
/*                    Added error handling and comments              */
/*                                                                   */
/*********************************************************************/
             PGM        PARM(&MENUNAME &MENULIB &ACTION)
/******************************************************************/
/*  Standard Error Handling Variables                             */
/******************************************************************/
             DCL        VAR(&ERRORSW) TYPE(*LGL)
             DCL        VAR(&MSGID)   TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGDTA)  TYPE(*CHAR) LEN(100)
             DCL        VAR(&MSGF)    TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGFLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&KEYVAR)  TYPE(*CHAR) LEN(4)

/******************************************************************/
/*  USER DEFINED PROGRAM VARIABLES                                */
/******************************************************************/
             DCL        VAR(&MENUNAME) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MENULIB)  TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(2)
             DCL        VAR(&IN03) TYPE(*LGL) LEN(1)
             DCL        VAR(&IND)  TYPE(*CHAR) LEN(2)
             DCL        VAR(&BLANK) TYPE(*CHAR) LEN(10) +
                          VALUE('          ')
             DCL        VAR(&DMERROR) TYPE(*CHAR) LEN(70)

             DCLF       FILE(*LIBL/ANZFILEINT) RCDFMT(*ALL)

VALID:
             SNDF       RCDFMT(ANZFIL)

             RCVF       RCDFMT(ANZFIL)
             CHGVAR     VAR(&DMERROR) VALUE(&BLANK)
             RMVMSG     PGMQ(*SAME) CLEAR(*ALL)

             IF         COND(&IN03 *EQ '1') THEN(DO)
             CHGVAR     VAR(&ACTION) VALUE(X'FFFF')
             GOTO       END
             ENDDO
             IF         COND(&IN12 *EQ '1') THEN(DO)
             CHGVAR     VAR(&ACTION) VALUE(X'FFFE')
             TFRCTL     PGM(HAMENU) PARM(&MENUNAME &MENULIB &ACTION)
             ENDDO

/* Check for valid library and file name */

             IF         COND(&FNAM *EQ &BLANK) THEN(GOTO +
                          CMDLBL(ERROR1))

             IF         COND(&FLIB *EQ &BLANK) THEN(GOTO +
                          CMDLBL(ERROR2))

             CHKOBJ     OBJ(&FLIB) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF0000) EXEC(GOTO ERROR3)

             CHKOBJ     OBJ(&FLIB/&FNAM) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO ERROR4)

/* Clear all files, override and call ANZFILESI and DSPANZFILI */

             CLRPFM     FILE(QTEMP/ANZFILA)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(QTEMP/ANZFILB)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(QTEMP/ANZFILC)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(QTEMP/ANZFILD)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(*LIBL/ANZFILPFI)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(*LIBL/ANZFLDPFI)
             MONMSG     MSGID(CPF0000)
             OVRDBF     FILE(ANZFILL1) TOFILE(*LIBL/ANZFILL1I)
             OVRDBF     FILE(ANZFILL2) TOFILE(*LIBL/ANZFILL2I)
             OVRDBF     FILE(ANZFLDL1) TOFILE(*LIBL/ANZFLDL1I)
             OVRDBF     FILE(ANZFLDL3) TOFILE(*LIBL/ANZFLDL3I)
             CALL       PGM(*LIBL/ANZFILESI) PARM(&FNAM &FLIB)
             CHGVAR     VAR(&IND) VALUE('  ')
             CALL       PGM(*LIBL/DSPANZFILI) PARM(&IND)

/* Check for PF12 or PF3 from DSPANZFILI */

             IF         COND(&IND *EQ '03') THEN(DO)
             CHGVAR     VAR(&ACTION) VALUE(X'FFFF')
             GOTO       END
             ENDDO
             IF         COND(&IND *EQ '12') THEN(DO)
             CHGVAR     VAR(&ACTION) VALUE(X'FFFE')
             TFRCTL     PGM(HAMENU) PARM(&MENUNAME &MENULIB &ACTION)
             ENDDO

/* Clear out the display */

             RMVMSG     PGMQ(*SAME) CLEAR(*ALL)
             CHGVAR     VAR(&FNAM) VALUE(&BLANK)
             CHGVAR     VAR(&FLIB) VALUE(&BLANK)
             GOTO       VALID

ERROR1:
             CHGVAR     VAR(&DMERROR) VALUE('File Name +
                          must be entered.')
             GOTO       VALID
ERROR2:
             CHGVAR     VAR(&DMERROR) VALUE('File Library must +
                          be entered.')
             GOTO       VALID
ERROR3:
             CHGVAR     VAR(&DMERROR) VALUE('Library does not exist.')
             GOTO       VALID

ERROR4:
             CHGVAR     VAR(&DMERROR) VALUE('File does not exist.')
             GOTO       VALID

/****************************************************************/
/*  STANDARD ERROR HANDLING ROUTINES                            */
/****************************************************************/

 STDERR1:    IF         &ERRORSW SNDPGMMSG MSGID(CPF9999) +
                          MSGF(QCPFMSG) MSGTYPE(*ESCAPE) /* FUNC CHK */
             CHGVAR     &ERRORSW '1' /* SET TO FAIL IF ERROR OCCURS */

 STDERR2:    RCVMSG     MSGTYPE(*DIAG) RMV(*NO) KEYVAR(&KEYVAR) +
                          MSGDTA(&MSGDTA) MSGID(&MSGID) MSGF(&MSGF) +
                          SNDMSGFLIB(&MSGFLIB)
             IF         (&KEYVAR *EQ '    ') GOTO STDERR3
             RMVMSG     MSGKEY(&KEYVAR)
             SNDPGMMSG  MSGID(&MSGID) MSGF(&MSGFLIB/&MSGF) +
                          MSGDTA(&MSGDTA) MSGTYPE(*DIAG)
             GOTO       STDERR2 /* LOOP BACK FOR ADDL DIAGNOSTICS */

 STDERR3:    RCVMSG     MSGTYPE(*EXCP) MSGDTA(&MSGDTA) MSGID(&MSGID) +
                          MSGF(&MSGF) SNDMSGFLIB(&MSGFLIB)
             SNDPGMMSG  MSGID(&MSGID) MSGF(&MSGFLIB/&MSGF) +
                          MSGDTA(&MSGDTA) MSGTYPE(*ESCAPE)

END:         CHGVAR     VAR(&DMERROR) VALUE(&BLANK)
             RMVMSG     PGMQ(*SAME) CLEAR(*ALL)
             ENDPGM
