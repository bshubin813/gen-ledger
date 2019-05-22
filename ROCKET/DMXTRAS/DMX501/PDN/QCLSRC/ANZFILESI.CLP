/*********************************************************************/
/*                                                                   */
/*   ---------                                                       */
/*   ANZFILESI                                                       */
/*   ---------                                                       */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is called by CL ANZFILEINT and using the passed file name */
/* and library, does DSPPFDs to output files and runs programs       */
/* ADDANZFLD, ANZFILMBR, ADDANZFILE and ADDANZLF to analyze and      */
/* display the results.                                              */
/*                                                                   */
/* Input Parameters:  As provided by display file ANZFILEBAT:        */
/*                    &FNAM - File to analyze                        */
/*                    &FLIB - Library containing the file            */
/*                                                                   */
/* Output Parameters: To pgm ADDANZFLD:                              */
/*                    &PHFILE - File to analyze                      */
/*                    &PHLIB  - Library containing the file          */
/*                    &UNIQ   - Uniquely keyed ?                     */
/*                    &JOIN   - Joined files ?                       */
/* To pgm ANZFILMBR:  &RECS   - Number of records                    */
/* To pgm ADDANZFILE: &PHFILE - File to analyze                      */
/*                    &PHLIB  - Library containing the file          */
/*                    &PHFATR - File attributes                      */
/*                    &MBRS   - Multi member                         */
/*                    &PHJRNL - File journalled                      */
/*                    &PHJRNM - Journal name                         */
/*                    &PHJRLB - Journal library                      */
/*                    &PHJRIM - Both or only after images            */
/*                    &SEQ    - ?                                    */
/*                    &UNIQ   - Uniquely keyed                       */
/*                    &RECS   - Number of records                    */
/*                    &JOIN   - File joined                          */
/*                        &PHRUSE - Reused deleted records           */
/*                        &PHMXRL - ?                                */
/*                        &PHACCP - ?                                */
/* To pgm ADDANZLF:   &PHFILE - File to analyze                      */
/*                    &PHFILE - File to analyze                      */
/*                    &PHLIB  - Library containing the file          */
/*                    &UNIQ   - Uniquely keyed ?                     */
/*                    &JOIN   - Joined files ?                       */
/*                                                                   */
/* Author:            DataMirror Corporation                         */
/*                                                                   */
/* Change Log:        Mike Warkentin Jan 07, 2000                    */
/*                    Added error handling and comments              */
/*                                                                   */
/*********************************************************************/
             PGM        PARM(&FIL &LIB)
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
 /*  User Defined Program Variables                                 */
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
             GOTO      CMDLBL(ENDPGM)
             ENDDO

             OVRDBF     FILE(ANZFILA) TOFILE(QTEMP/ANZFILA)
NEXT:        RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ENDPGM))
             IF         COND(&PHDTAT *EQ 'D') THEN(DO)
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

 ENDPGM:     SNDPGMMSG  MSGID(CPI9801) MSGF(QCPFMSG) MSGTYPE(*STATUS)
             ENDPGM
