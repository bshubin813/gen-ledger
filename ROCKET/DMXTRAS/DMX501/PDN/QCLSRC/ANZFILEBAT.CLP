/*********************************************************************/
/*                                                                   */
/*   ------------------------------                                  */
/*   DISPLAY SUBMIT ANALYSIS SCREEN                                  */
/*   ------------------------------                                  */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is called by HAMENU and submits a program to a batch job  */
/* ANZFILESA to start analyzing either specific files or all files   */
/* in the library specified from the display file ANZFILEBAT.        */
/*                                                                   */
/* Input Parameters:  As provided by display file ANZFILEBAT:        */
/*                    &FNAM - Files to Analyze                       */
/*                    &FLIB - Library to Analyze                     */
/*                    As required by the TFRCTL from HAMENU          */
/*                    &MENUNAME - Menu name                          */
/*                    &MENULIB  - Menu library                       */
/*                    &ACTION   - Function key action                */
/*                                                                   */
/* Output Parameters: None                                           */
/*                                                                   */
/* Author:            DataMirror Corporation                         */
/*                                                                   */
/* Change Log:        Mike Warkentin Jan 07, 2000                    */
/*                    Added error handling and comments              */
/*                                                                   */
/*********************************************************************/
             PGM       PARM(&MENUNAME &MENULIB &ACTION)
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
             DCL        VAR(&BLANK) TYPE(*CHAR) LEN(10) +
                          VALUE('          ')
             DCL        VAR(&DMERROR) TYPE(*CHAR) LEN(70)

             DCLF       FILE(*LIBL/ANZFILEBAT) RCDFMT(*ALL)

VALID:
             SNDF       RCDFMT(ANZFIL)

             RCVF       RCDFMT(ANZFIL)
             IF         COND(&IN03 *EQ '1') THEN(DO)
             CHGVAR     VAR(&ACTION) VALUE(X'FFFF')
             GOTO       END
             ENDDO
             IF         COND(&IN12 *EQ '1') THEN(DO)
             CHGVAR     VAR(&ACTION) VALUE(X'FFFE')
             TFRCTL     PGM(HAMENU) PARM(&MENUNAME &MENULIB &ACTION)
             ENDDO

/* Check for valid library and file */

             IF         COND(&FNAM *EQ &BLANK) THEN(GOTO +
                          CMDLBL(ERROR1))

             IF         COND(&FLIB *EQ &BLANK) THEN(GOTO +
                          CMDLBL(ERROR2))

             CHKOBJ     OBJ(&FLIB) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF0000) EXEC(GOTO ERROR3)

/* Submit the analysis job to batch on hold */

SBMANZ:
             SBMJOB     CMD(CALL PGM(*LIBL/ANZFILESA) PARM(&FNAM +
                          &FLIB)) JOB(ANZFILES) JOBQ(*JOBD) +
                          LOGCLPGM(*NO) HOLD(*YES)

/* Percolate the messages from the option back up to display */

             CHGVAR     &PGM VALUE('ANZFILEBAT')
             SNDF       RCDFMT(MSGCTL)
             SNDRCVF    RCDFMT(MSGCTL) WAIT(*NO)
             DLYJOB     DLY(5)
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

END:
             ENDPGM
