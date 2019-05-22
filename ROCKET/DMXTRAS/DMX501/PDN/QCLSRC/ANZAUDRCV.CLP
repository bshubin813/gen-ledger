/*********************************************************************/
/*                                                                   */
/*   ----------------------                                          */
/*   DISPLAY AUDIT ANALYSIS                                          */
/*   ----------------------                                          */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is processed by command ANZAUDRCV (as called by HAMENU).  */
/* It validates all of the parms passed from the display file and    */
/* submits program ANZAUDCLP as batch job ANZJRNRCV on hold.         */
/*                                                                   */
/* Input Parameters:  As passed from display file ANZJRNDSP          */
/*                    &JNAM    - Journal name for analysis           */
/*                    &JLIB    - Journal library                     */
/*                    &JRCV    - Journal receiver name               */
/*                    &JRCL    - Journal receiver library            */
/*                    &STRDTE  - Starting date                       */
/*                    &ENDDTE  - Ending date                         */
/*                    &APDANZ  - Append to analysis file flag        */
/*                    &CLRANZ  - Clear analysis file flag            */
/*                    &ARCANZ  - Archive analysis file & clear flag  */
/*                    &SBMHLD  - Submit job on hold                  */
/*                                                                   */
/* Output Parameters: None                                           */
/*                                                                   */
/* Author:            DataMirror Corporation                         */
/*                                                                   */
/*                                                                   */
/* Change Log:        Mike Warkentin Jan 07, 2000                    */
/*                    Added error handling and comments              */
/*                    Mike Warkentin Feb 05, 2000                    */
/*                    Modify to allow *YES and *NO                   */
/*                                                                   */
/*                    ROBERT PHILO May 14th 2002                     */
/*                    Replace use of HASETUP data area to find       */
/*                    product libraries with HRTVPRDLIB              */
/*                                                                   */
/*********************************************************************/
             PGM
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
             DCL        VAR(&IN03) TYPE(*LGL) LEN(1)
             DCL        VAR(&SSEQ) TYPE(*DEC) LEN(12) VALUE(0)
             DCL        VAR(&ESEQ) TYPE(*DEC) LEN(12) VALUE(0)
             DCL        VAR(&STRDTEN) TYPE(*DEC) LEN(6 0) VALUE(0)
             DCL        VAR(&ENDDTEN) TYPE(*DEC) LEN(6 0) VALUE(0)
             DCL        VAR(&HATOOLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BLANK) TYPE(*CHAR) LEN(10) +
                          VALUE('          ')
             DCL        VAR(&BLANK6) TYPE(*CHAR) LEN(6) VALUE('      ')
             DCL        VAR(&BLANK12) TYPE(*CHAR) LEN(12) +
                          VALUE('            ')
             DCL        VAR(&DMERROR) TYPE(*CHAR) LEN(70)
             DCL        VAR(&ARCOPT) TYPE(*CHAR) LEN(1) VALUE('1')
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)

/* Declare display file, initialize variables and retrieve HATOOLIB */

             DCLF       FILE(*LIBL/ANZAUDDSP) RCDFMT(*ALL)
             CHGVAR     VAR(&JNAM) VALUE('QAUDJRN')
             CHGVAR     VAR(&JLIB) VALUE('QSYS')
             CHGVAR     VAR(&JRCV) VALUE('*CURCHAIN')
             CHGVAR     VAR(&JRCL) VALUE('*LIBL')
             CHGVAR     VAR(&APDANZ) VALUE('*YES')
             CHGVAR     VAR(&CLRANZ) VALUE('*NO ')
             CHGVAR     VAR(&ARCANZ) VALUE('*NO ')
             CHGVAR     VAR(&SBMHLD) VALUE('*YES')

             HRTVPRDLIB UTILLIB(&HATOOLLIB)

             ADDLIBLE   LIB(&HATOOLLIB)
             MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))

VALID:
             RMVMSG     PGMQ(*SAME) CLEAR(*ALL)
             SNDF       RCDFMT(ANZJRN)

             RCVF       RCDFMT(ANZJRN)

/* Check for PF12 or PF3 from dspf ANZAUDDSP & send escape message back*/
/* to HAMENU                                                           */

             IF         COND(&IN12) THEN(SNDPGMMSG MSGID(CPF6801) +
                          MSGF(QSYS/QCPFMSG) MSGDTA(F12) +
                          MSGTYPE(*ESCAPE))

             IF         COND(&IN03) THEN(SNDPGMMSG +
                          MSGID(CPF6801) MSGF(QSYS/QCPFMSG) +
                          MSGDTA(F3 ) MSGTYPE(*ESCAPE))

/* Validate parms from display file */

             IF         COND(&JNAM *EQ &BLANK) THEN(GOTO +
                          CMDLBL(ERROR1))

             IF         COND(&JLIB *EQ &BLANK) THEN(GOTO +
                          CMDLBL(ERROR2))

             CHKOBJ     OBJ(&JLIB/&JNAM) OBJTYPE(*JRN)
             MONMSG     MSGID(CPF0000) EXEC(GOTO ERROR3)

             IF         COND(&JRCV *EQ '*CURCHAIN' *OR &JRCV *EQ +
                          '*CURRENT') THEN(GOTO CMDLBL(NEXT))

             IF         COND(&JRCV *EQ &BLANK) THEN(GOTO +
                        CMDLBL(ERROR14))

             IF         COND(&JRCL *EQ &BLANK) THEN(GOTO +
                        CMDLBL(ERROR4))

             CHKOBJ     OBJ(&JRCL/&JRCV) OBJTYPE(*JRNRCV)
             MONMSG     MSGID(CPF0000) EXEC(GOTO ERROR5)

NEXT:

             IF         COND((&APDANZ *NE '*YES') *AND (&APDANZ *NE +
                          '*NO ')) THEN(GOTO CMDLBL(ERROR12))
             IF         COND((&CLRANZ *NE '*YES') *AND (&CLRANZ *NE +
                          '*NO ')) THEN(GOTO CMDLBL(ERROR12))
             IF         COND((&ARCANZ *NE '*YES') *AND (&ARCANZ *NE +
                          '*NO ')) THEN(GOTO CMDLBL(ERROR12))

             IF         COND((&APDANZ *EQ '*YES') *AND ((&CLRANZ *EQ +
                          '*YES') *OR (&ARCANZ *EQ '*YES'))) THEN(GOTO +
                          CMDLBL(ERROR13))
             IF         COND((&CLRANZ *EQ '*YES') *AND ((&APDANZ *EQ +
                          '*YES') *OR (&ARCANZ *EQ '*YES'))) THEN(GOTO +
                          CMDLBL(ERROR13))
             IF         COND((&ARCANZ *EQ '*YES') *AND ((&APDANZ *EQ +
                          '*YES') *OR (&CLRANZ *EQ '*YES'))) THEN(GOTO +
                          CMDLBL(ERROR13))

             IF         COND(&APDANZ *EQ '*YES') THEN(DO)
             CHGVAR     VAR(&ARCOPT) VALUE('1')
             ENDDO
             IF         COND(&CLRANZ *EQ '*YES') THEN(DO)
             CHGVAR     VAR(&ARCOPT) VALUE('2')
             ENDDO
             IF         COND(&ARCANZ *EQ '*YES') THEN(DO)
             CHGVAR     VAR(&ARCOPT) VALUE('3')
             ENDDO

             GOTO       SBMANZ

             IF         COND((&APDANZ *NE '*YES') *AND (&APDANZ *NE +
                          '*NO ')) THEN(GOTO CMDLBL(ERROR12))
             IF         COND((&CLRANZ *NE '*YES') *AND (&CLRANZ *NE +
                          '*NO ')) THEN(GOTO CMDLBL(ERROR12))
             IF         COND((&ARCANZ *NE '*YES') *AND (&ARCANZ *NE +
                          '*NO ')) THEN(GOTO CMDLBL(ERROR12))
             IF         COND((&SBMHLD *NE '*YES') *AND (&SBMHLD *NE +
                          '*NO ')) THEN(GOTO CMDLBL(ERROR19))

             IF         COND((&APDANZ *EQ '*YES') *AND ((&CLRANZ *EQ +
                          '*YES') *OR (&ARCANZ *EQ '*YES'))) THEN(GOTO +
                          CMDLBL(ERROR13))
             IF         COND((&CLRANZ *EQ '*YES') *AND ((&APDANZ *EQ +
                          '*YES') *OR (&ARCANZ *EQ '*YES'))) THEN(GOTO +
                          CMDLBL(ERROR13))
             IF         COND((&ARCANZ *EQ '*YES') *AND ((&APDANZ *EQ +
                          '*YES') *OR (&CLRANZ *EQ '*YES'))) THEN(GOTO +
                          CMDLBL(ERROR13))

             IF         COND(&APDANZ *EQ '*YES') THEN(DO)
             CHGVAR     VAR(&ARCOPT) VALUE('1')
             ENDDO
             IF         COND(&CLRANZ *EQ '*YES') THEN(DO)
             CHGVAR     VAR(&ARCOPT) VALUE('2')
             ENDDO
             IF         COND(&ARCANZ *EQ '*YES') THEN(DO)
             CHGVAR     VAR(&ARCOPT) VALUE('3')
             ENDDO

/* Submit the analysis job on hold */

 SBMANZ:     SBMJOB     CMD(CALL PGM(ANZAUDCLP) PARM(&JLIB &JNAM +
                          &JRCV &JRCL &STRDTE &ENDDTE &ARCOPT)) +
                          JOB(ANZAUDRCV) JOBD(HAUTILS) HOLD(&SBMHLD)
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
             GOTO       CMDLBL(END)

ERROR1:
             CHGVAR     VAR(&DMERROR) VALUE('Journal Name +
                          must be entered')
             GOTO       VALID
ERROR2:
             CHGVAR     VAR(&DMERROR) VALUE('Journal Library must  +
                          be entered')
             GOTO       VALID
ERROR3:
             CHGVAR     VAR(&DMERROR) VALUE('Journal does not exist')
             GOTO       VALID
ERROR4:
             CHGVAR     VAR(&DMERROR) VALUE('Journal Receiver +
                          Library must be entered')
             GOTO       VALID
ERROR5:
             CHGVAR     VAR(&DMERROR) VALUE('Journal Receiver does +
                          not exist')
             GOTO       VALID
ERROR6:
             CHGVAR     VAR(&DMERROR) VALUE('Invalid selections. +
                          Choose either sequence numbers or +
                          dates/times')
             GOTO       VALID
ERROR7:
             CHGVAR     VAR(&DMERROR) VALUE('Invalid Starting +
                          Sequence Number')
             GOTO       VALID
ERROR8:
             CHGVAR     VAR(&DMERROR) VALUE('Invalid Ending Sequence +
                          Number')
             GOTO       VALID
ERROR9:
             CHGVAR     VAR(&DMERROR) VALUE('Starting Sequence +
                          Number cannot be greater than the Ending +
                          Sequence Number')
             GOTO       VALID
ERROR10:
             CHGVAR     VAR(&DMERROR) VALUE('Starting Date and +
                          Ending Date must be entered')
             GOTO       VALID
ERROR11:
             CHGVAR     VAR(&DMERROR) VALUE('Starting Date cannot +
                          br greater than Ending Date')
             GOTO       VALID
ERROR12:
             CHGVAR     VAR(&DMERROR) VALUE('Valid Options are *YES or *NO')
             GOTO       VALID
ERROR13:
             CHGVAR     VAR(&DMERROR) VALUE('Choose only one Option, +
                          Append, Clear or Archive')
             GOTO       VALID
ERROR14:
             CHGVAR     VAR(&DMERROR) VALUE('Journal Receiver Name +
                          must be entered or *CURCHAIN')
             GOTO       VALID
ERROR15:
             CHGVAR     VAR(&DMERROR) VALUE('Invalid Starting Date')
             GOTO       VALID
ERROR16:
             CHGVAR     VAR(&DMERROR) VALUE('Invalid Ending Date')
             GOTO       VALID
ERROR19:
             CHGVAR     VAR(&DMERROR) VALUE('Submit on Hold must be +
                          *YES or *NO.')
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
