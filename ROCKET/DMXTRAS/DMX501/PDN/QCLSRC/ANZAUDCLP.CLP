/*********************************************************************/
/*                                                                   */
/*   ------------------------                                        */
/*   ANALYZE AUDIT CL PROGRAM                                        */
/*   ------------------------                                        */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                  */
/*   All rights reserved.                                            */
/*                                                                   */
/* This CL is called by the ANZAUDDSP CLP as processed by the        */
/* ANZAUDRCV command.                                                */
/* It does a DSPJRN for each audit entry of QAUDJRN for each entry   */
/* type that is used by HA Suite into it's own output file, and then */
/* combines them all into one output file DSPAUDJRN for the ANZAUDRCV*/
/* query.                                                            */
/*                                                                   */
/* Input Parameters:  As passed from ANZAUDDSP CL                    */
/*                    &JNAM    - Journal name for analysis           */
/*                    &JLIB    - Journal library                     */
/*                    &JRCV    - Journal receiver name               */
/*                    &JRCL    - Journal receiver library            */
/*                    &STRDTE  - Starting date                       */
/*                    &ENDDTE  - Ending date                         */
/*                    &ARCOPT  - Archive option                      */
/*                                                                   */
/* Output Parameters: None                                           */
/*                                                                   */
/* Author:                                                           */
/*          (C) Copyright Rocket Software, Inc. 1997-2012.           */
/*           All rights reserved.                                    */
/*                                                                   */
/* Change Log:        Mike Warkentin Oct 27, 2000                    */
/*                    Added error handling, comments, and ANZAUDRCV  */
/*                    query                                          */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030730 FK  Monitor for messages in DSPJRN                       */
/*              Follow basic standards for DMXtras programs          */
/* 20050217 FK  Remove starting/ending sequence number               */
/*              Audit journal information now in HAUDJRN.. files     */
/* ================================================================= */
             PGM        PARM(&JLIB &JNAM &JRCV &JRCL &STRDTE &ENDDTE +
                          &ARCOPT)

/*           Declare parameter variables                             */
             DCL        VAR(&JLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRCL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STRDTE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&ENDDTE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&ARCOPT) TYPE(*CHAR) LEN(1)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&STRTIM) TYPE(*CHAR) LEN(6)
             DCL        VAR(&ENDTIM) TYPE(*CHAR) LEN(6)

             DCL        VAR(&ARCFILCA) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILCO) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILCP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILDO) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILOM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILOR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILOW) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILPG) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILSF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ARCFILZC) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JOBNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&BLANK12) TYPE(*CHAR) LEN(12) +
                          VALUE('            ')
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                       */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Replace library if *CURRENT or *CURCHAIN receiver    */
             IF         COND(&JRCV *EQ '*CURRENT' *OR &JRCV *EQ +
                          '*CURCHAIN') THEN(CHGVAR VAR(&JRCL) +
                          VALUE('*N'))
             IF         COND(&STRDTE *EQ ' ') THEN(DO)
              CVTDAT     DATE(410101) TOVAR(&STRDTE) FROMFMT(*YMD) +
                          TOSEP(*NONE)
             ENDDO
             CHGVAR     VAR(&STRTIM) VALUE('000000')
             IF         COND(&ENDDTE *EQ ' ') THEN(DO)
              CVTDAT     DATE(391231) TOVAR(&ENDDTE) FROMFMT(*YMD) +
                          TOSEP(*NONE)
             ENDDO
             CHGVAR     VAR(&ENDTIM) VALUE('235959')

             IF         COND(&ARCOPT *EQ '2') THEN(DO)
             CLRPFM     FILE(&UTLLIB/HAUDJRNCA)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNCO)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNCP)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNDO)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNOM)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNOR)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNOW)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNPG)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNSF)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(&UTLLIB/HAUDJRNZC)
             MONMSG     MSGID(CPF0000)
             ENDDO

             IF         COND(&ARCOPT *EQ '3') THEN(DO)
             RTVJOBA    NBR(&JOBNBR)
             CHGVAR     VAR(&ARCFILCA) VALUE('HXCA' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILCO) VALUE('HXCO' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILCP) VALUE('HXCP' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILDO) VALUE('HXDO' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILOM) VALUE('HXOM' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILOR) VALUE('HXOR' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILOW) VALUE('HXOW' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILPG) VALUE('HXPG' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILSF) VALUE('HXSF' *CAT &JOBNBR)
             CHGVAR     VAR(&ARCFILZC) VALUE('HXZC' *CAT &JOBNBR)
             SNDUSRMSG  MSG('Archive Files were created in library' +
                          |< &UTLLIB) MSGTYPE(*INFO)
             CRTDUPOBJ  OBJ(HAUDJRNCA) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILCA) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNCO) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILCO) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNCP) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILCP) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNDO) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILDO) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNOM) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILOM) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNOW) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILOW) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNOR) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILOR) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNPG) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILPG) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             CRTDUPOBJ  OBJ(HAUDJRNSF) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILSF) DATA(*YES)
             CRTDUPOBJ  OBJ(HAUDJRNZC) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&ARCFILZC) DATA(*YES)
             MONMSG     MSGID(CPF2130)
             MONMSG     MSGID(CPF2130)
             CLRPFM     FILE(HAUDJRNCA)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNCO)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNCO)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNDO)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNOW)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNOM)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNOR)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNPG)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNSF)
             MONMSG     MSGID(CPF0000)
             CLRPFM     FILE(HAUDJRNZC)
             MONMSG     MSGID(CPF0000)
             ENDDO

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(CA) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNCA)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(CO) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNCO)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(CP) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNCP)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(DO) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNDO)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(OM) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNOM)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(OR) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNOR)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(OW) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNOW)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(PG) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNPG)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(SF) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNSF)
             MONMSG     MSGID(CPF7000)

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCL/&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(ZC) OUTPUT(*OUTFILE) +
                          OUTFILFMT(*TYPE4) OUTFILE(&UTLLIB/HAUDJRNZC)
             MONMSG     MSGID(CPF7000)

/* Now create the ANZAUDRCV file                              */

             DSPJRN     JRN(&JLIB/&JNAM) RCVRNG(&JRCV) +
                          FROMTIME(&STRDTE &STRTIM) TOTIME(&ENDDTE +
                          &ENDTIM) ENTTYP(CA CO CP DO OM OR OW PG +
                          SF ZC) OUTPUT(*OUTFILE) OUTFILFMT(*TYPE2) +
                          OUTFILE(&UTLLIB/DSPAUDJRN)
             MONMSG     MSGID(CPF7000)

/* Run the ANZAUDRCV query to populate the ANZAUDRCV file */
             RUNQRY     QRY(ANZAUDRCV) QRYFILE((&UTLLIB/DSPAUDJRN)) +
                          OUTTYPE(*OUTFILE) OUTFILE(&UTLLIB/ANZAUDRCV)

 ENDMSG:     SNDUSRMSG  MSG('ANZAUDRCV: Processing completed') +
                          MSGTYPE(*INFO)
             GOTO         END

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
