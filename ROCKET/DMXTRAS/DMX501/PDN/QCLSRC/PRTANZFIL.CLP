/*********************************************************************/
/*                                                                   */
/* -------------------                                               */
/* PRINT FILE ANALYSIS                                               */
/* -------------------                                               */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is processed by command PRTANZFIL (which is called by     */
/* menu HAMENU) and accepts a library name, filtering value of U (for*/
/* uniquely keyed) N (for Non keyed) or A (for ALL) and a yes no     */
/* switch for including key field values. This CL then submits pgm   */
/* PRTANZFILS to a batch job on hold called ANZFILS.                 */
/*                                                                   */
/* Input Parameters:  &LIB    - Library of files to print            */
/*                    &UNIQ   - Filter on unique key, non or all     */
/*                    &KEYS   - Include key values                   */
/*                                                                   */
/* Output Parameters: &JRNNME and &JRNLIB and &IND to program        */
/*                    HADSPJRN                                       */
/*                                                                   */
/* Author:            DataMirror Corporation                         */
/*                                                                   */
/*                                                                   */
/* Change Log:        Mike Warkentin Jan 07, 2000                    */
/*                    Added error handling and comments              */
/*                    Mike Warkentin Jul 13, 2000                    */
/*                    Remove library validation as some customers    */
/*                    send the ANZJRNPF files and want us to run it  */
/*                                                                   */
/*                                                                   */
/*                    ROBERT PHILO May 14th 2002                     */
/*                    Replace use of HASETUP data area to find       */
/*                    product libraries with HRTVPRDLIB              */
/*********************************************************************/
             PGM        PARM(&LIB &UNIQ &KEYS)

/******************************************************************/
/*  Standard Error Handling Variables                             */
/******************************************************************/
             DCL        VAR(&ERRORSW) TYPE(*LGL)
             DCL        VAR(&MSGID)   TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGDTA)  TYPE(*CHAR) LEN(100)
             DCL        VAR(&MSGF)    TYPE(*CHAR) LEN(10)
             DCL        VAR(&MSGFLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&KEYVAR)  TYPE(*CHAR) LEN(4)

 /*******************************************************************/
 /*  User Defined Program Varaiables                                */
 /*******************************************************************/
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TOOLSLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UNIQ) TYPE(*CHAR) LEN(1)
             DCL        VAR(&KEYS) TYPE(*CHAR) LEN(4)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* Get HA Toollib info */
             HRTVPRDLIB UTILLIB(&TOOLSLIB)

 /*******************************************************************/
 /*  SUBMIT THE JOB                                                 */
 /*******************************************************************/

             SBMJOB     CMD(CALL PGM(&TOOLSLIB/PRTANZFILS) PARM(&LIB +
                          &UNIQ &KEYS)) JOB(PRTANZFILS) JOBQ(*JOBD) +
                          CURLIB(&TOOLSLIB)
/*           Copy back SBMJOB message to previous queue              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     ' +
                          X'00000001' '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
