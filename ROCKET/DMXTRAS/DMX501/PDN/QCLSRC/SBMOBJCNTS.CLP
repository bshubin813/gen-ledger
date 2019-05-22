/*********************************************************************/
/*                                                                   */
/*   --------------------                                            */
/*   SUBMIT OBJECT COUNTS                                            */
/*   --------------------                                            */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is processed by command OBJCOUNTS and just submits the    */
/* OBJCOUNTS CL to batch (after verifying inand out parameters).     */
/*                                                                   */
/* Input Parameters:  &LIB Library to be analyzed                    */
/*                                                                   */
/* Output Parameters: To program OBJCOUNTS                           */
/*                    &LIB      - Library to be analyzed             */
/*                    &HATOOLIB - HA Tools 2000 Library              */
/*                                                                   */
/* Author:            Mike Warkentin Jan 05, 2000                    */
/*                                                                   */
/*                                                                   */
/* Change Log:                                                       */
/*                                                                   */
/*********************************************************************/

             PGM        PARM(&LIB)
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

             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&HATOOLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NBR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&QUE) TYPE(*CHAR) LEN(10)

/* Retrieve HA Tools Library        */



             HRTVPRDLIB UTILLIB(&HATOOLLIB)

/* Validate Library */

             IF         COND(&LIB *NE '*ALLUSR') THEN(DO)
             CHKOBJ     OBJ(QSYS/&LIB) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF9801) EXEC(DO)
             SNDPGMMSG  MSGID(CPF9898) MSGF(QCPFMSG) MSGDTA('Library +
                          does not exist.') TOPGMQ(*PRV)
             GOTO       CMDLBL(END)
             ENDDO
             ENDDO

/* Submit OBJCOUNTS  */

             SBMJOB     CMD(CALL PGM(OBJCOUNTS) PARM(&LIB &HATOOLLIB)) +
                          JOB(OBJCOUNTS) HOLD(*YES)
             RCVMSG     MSGTYPE(*COMP) RMV(*NO) MSGDTA(&MSGDTA)
             CHGVAR     VAR(&JOB) VALUE(%SST(&MSGDTA 01 10))
             CHGVAR     VAR(&USR) VALUE(%SST(&MSGDTA 11 10))
             CHGVAR     VAR(&NBR) VALUE(%SST(&MSGDTA 21 06))
             CHGVAR     VAR(&QUE) VALUE(%SST(&MSGDTA 27 10))
             SNDPGMMSG  MSG('Job ' |> &JOB |< '/' |< &USR |< +
                        '/' |< &NBR |< ' submitted on hold to job +
                        queue ' |> &QUE) TOPGMQ(*PRV)
             GOTO END

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

 END:        ENDPGM
