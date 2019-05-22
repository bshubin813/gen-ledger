/*********************************************************************/
/*                                                                   */
/*   --------------------------                                      */
/*   SAVE JOURNAL ANALYSIS DATA                                      */
/*   --------------------------                                      */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is called by HAMENU and saves the contents of ANZ* and    */
/* ARC* files to a savefile in the HA TOOLS 2000 library.            */
/*                                                                   */
/* Input Parameters:  &SFIL      - Savefile name                     */
/*                    &SLIB      - Savefile Library                  */
/*                                                                   */
/* Output Parameters: None                                           */
/*                                                                   */
/* Author:            DataMirror Corporation                         */
/*                                                                   */
/*                                                                   */
/* Change Log:        Mike Warkentin Jan 07, 2000                    */
/*                    Added error handling and comments              */
/*                    Mike Warkentin Feb 21, 2000                    */
/*                    Handle user specified file and library         */
/*                    Mike Warkentin Aug 17, 2000                    */
/*                    Fix bug - if specify library and savefile name */
/*                    program tried to save objects from savefile lib*/
/*                    instead of toollib                             */
/*                                                                   */
/*                    ROBERT PHILO May 14th 2002                     */
/*                    Replace use of HASETUP data area to find       */
/*                    product libraries with HRTVPRDLIB              */
/*                                                                   */
/*********************************************************************/
             PGM        PARM(&SFIL &SLIB)
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
             DCL        VAR(&SFIL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&HATOOLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBTIME) TYPE(*CHAR) LEN(6)

/* Retreive HA Tools Library                                      */


             HRTVPRDLIB UTILLIB(&HATOOLLIB)

/* If file and library non blank, use it otherwise use PER and HA */
/* Tools library.                                                 */

             IF         COND((&SFIL *EQ '          ') *OR +
                          (&SLIB *EQ '          ')) THEN(GOTO +
                          CMDLBL(USEPER))

/* Check for valid lib */

             CHKOBJ     OBJ(*LIBL/&SLIB) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF9801) EXEC(DO)
             SNDPGMMSG  MSGID(CPF9898) MSGF(QCPFMSG) MSGDTA('Specified +
                        Library does not exist. Please try again') +
                        TOPGMQ(*PRV)
             GOTO       CMDLBL(ENDPGM)
             ENDDO

             GOTO CRTSAVF

USEPER:

/* Get current time & concatenate with ANZ to create savf name  */

             IF         COND(&SFIL *EQ '          ') THEN(DO)
             RTVSYSVAL  SYSVAL(QTIME) RTNVAR(&JOBTIME)
             CHGVAR     VAR(&SFIL) VALUE('ANZ' || &JOBTIME)
             ENDDO

             IF         COND(&SLIB *EQ '          ') THEN(DO)
             CHGVAR     VAR(&SLIB) VALUE(&HATOOLLIB)
             ENDDO

/* Create the savefile and sav ANZ* and ARC* into savefile      */

CRTSAVF:     CRTSAVF    FILE(&SLIB/&SFIL)
             SAVOBJ     OBJ(ARC* ANZ*) LIB(&HATOOLLIB) DEV(*SAVF) +
                          OBJTYPE(*FILE) SAVF(&SLIB/&SFIL)
             MONMSG     MSGID(CPF0000)
             SNDPGMMSG  MSGID(CPF9898) MSGF(QCPFMSG) MSGDTA('Savefile ' +
                        *CAT &SFIL *TCAT ' in library ' *CAT &SLIB +
                        *TCAT ' has been created') TOPGMQ(*PRV)
             GOTO       ENDPGM

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

 ENDPGM:     ENDPGM
