/* ================================================================= */
/* Object:         HCHKSYN4        *PGM CLP                          */
/*                 Generate output files and reports.                */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000227 FK  Initial delivery                                     */
/* 20001013 FK  Remove # of objects reports                          */
/* 20001202 FK  Hold spooled files to prevent inadvertent printing   */
/* 20001203 FK  Authority check is optional                          */
/*              Determine replication lag                            */
/* 20010322 FK  New query HCHKSYNOC                                  */
/* 20010404 FK  Remove replication lag                               */
/*              Optionally product output files                      */
/* 20010719 FK  New query HCHKSYNNJ                                  */
/* 20010809 FK  New query HCHKSYNLNE (Library not existing)          */
/*              New query HCHKSYNLNR (Library not referenced)        */
/* 20010831 FK  Also run some queries on the source machine          */
/* 20010907 FK  New query HCHKSYNNM                                  */
/* 20020523 FK  Check for IFS objects                                */
/* 20021122 FK  Redesign of synchronisation check                    */
/* 20030113 FK  Delete detail reports if no discrepancies            */
/* 20030501 FK  Enable for iCluster                                  */
/* 20030512 FK  Make library reports optional                        */
/* 20030521 FK  Include group name for setting authorities           */
/* 20050214 FK  Check member parameter                               */
/* 20050517 FK  Check IFS authorities                                */
/* 20060215 FK  Include mark string in reports                       */
/* 20060323 FK  Check journaling based on group settings             */
/* 20070919 FK  Allow to e-mail reports                              */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &MRKSTR &HAROLE &UTLLIB &SYNID +
                          &CHKMBR &CHKIFS &CHKAUT &CHKLIB &OUTFILE +
                          &SETAUT &IGNITV &EMLRPT)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MRKSTR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&HAROLE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYNID) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CHKMBR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKIFS) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKLIB) TYPE(*CHAR) LEN(4)
             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SETAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&IGNITV) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&EMLRPT) TYPE(*CHAR) LEN(6)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&LIBDFS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJDFS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJAFS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDFS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSDFS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSAFS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJDFT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJAFT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDFT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSDFT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSAFT) TYPE(*CHAR) LEN(10)

             DCL        VAR(&LIBDIF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJDIF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDIF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSDIF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&AUTDIF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFADIF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SUMDIF) TYPE(*CHAR) LEN(10)

             DCL        VAR(&OBJDSC) TYPE(*LGL)
             DCL        VAR(&MBRDSC) TYPE(*LGL)
             DCL        VAR(&AUTDSC) TYPE(*LGL)
             DCL        VAR(&IFSDSC) TYPE(*LGL)
             DCL        VAR(&IFADSC) TYPE(*LGL)
             DCL        VAR(&NBRDSC) TYPE(*DEC) LEN(9 0)

             DCL        VAR(&SYNF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&SYNF) VALUE('HS' |< &SYNID)
             CHGVAR     VAR(&LIBDFS) VALUE(&SYNF |< 'SL')
             CHGVAR     VAR(&OBJDFS) VALUE(&SYNF |< 'SO')
             CHGVAR     VAR(&OBJAFS) VALUE(&SYNF |< 'SA')
             CHGVAR     VAR(&MBRDFS) VALUE(&SYNF |< 'SM')
             CHGVAR     VAR(&IFSDFS) VALUE(&SYNF |< 'SI')
             CHGVAR     VAR(&IFSAFS) VALUE(&SYNF |< 'SJ')
             CHGVAR     VAR(&OBJDFT) VALUE(&SYNF |< 'TO')
             CHGVAR     VAR(&OBJAFT) VALUE(&SYNF |< 'TA')
             CHGVAR     VAR(&MBRDFT) VALUE(&SYNF |< 'TM')
             CHGVAR     VAR(&IFSDFT) VALUE(&SYNF |< 'TI')
             CHGVAR     VAR(&IFSAFT) VALUE(&SYNF |< 'TJ')

             CHGVAR     VAR(&LIBDIF) VALUE(&SYNF |< 'LIB')
             CHGVAR     VAR(&OBJDIF) VALUE(&SYNF |< 'OBJ')
             CHGVAR     VAR(&MBRDIF) VALUE(&SYNF |< 'MBR')
             CHGVAR     VAR(&IFSDIF) VALUE(&SYNF |< 'IFS')
             CHGVAR     VAR(&AUTDIF) VALUE(&SYNF |< 'AUT')
             CHGVAR     VAR(&IFADIF) VALUE(&SYNF |< 'IFA')
             CHGVAR     VAR(&SUMDIF) VALUE(&SYNF |< 'SUM')

/*           Determine location of output files                      */
             IF         COND(&OUTFILE *EQ '*YES') THEN(CHGVAR +
                          VAR(&OUTLIB) VALUE(&UTLLIB))
             IF         COND(&OUTFILE *NE '*YES') THEN(CHGVAR +
                          VAR(&OUTLIB) VALUE('QTEMP'))

/*           If secondary system, create output files and reports    */
             IF         COND(&HAROLE *EQ 'S') THEN(DO)
/*            First, delete output files (if existing)               */
              DLTF       FILE(&OUTLIB/&OBJDIF)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLTF       FILE(&OUTLIB/&MBRDIF)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLTF       FILE(&OUTLIB/&AUTDIF)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLTF       FILE(&OUTLIB/&IFSDIF)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLTF       FILE(&OUTLIB/&IFADIF)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
/*            Create new version of output files                     */
              CPYF       FROMFILE(&UTLLIB/HCHKSYNOBJ) +
                          TOFILE(&OUTLIB/&OBJDIF) CRTFILE(*YES)
              IF         COND(&CHKMBR *EQ '*YES') THEN(CPYF +
                          FROMFILE(&UTLLIB/HCHKSYNMBR) +
                          TOFILE(&OUTLIB/&MBRDIF) CRTFILE(*YES))
              IF         COND(&CHKIFS *EQ '*YES') THEN(CPYF +
                          FROMFILE(&UTLLIB/HCHKSYNIFS) +
                          TOFILE(&OUTLIB/&IFSDIF) CRTFILE(*YES))
              IF         COND(&CHKAUT *EQ '*YES') THEN(CPYF +
                          FROMFILE(&UTLLIB/HCHKSYNAUT) +
                          TOFILE(&OUTLIB/&AUTDIF) CRTFILE(*YES))
              IF         COND(&CHKIFS *EQ '*YES' *AND &CHKAUT *EQ +
                          '*YES') THEN(CPYF +
                          FROMFILE(&UTLLIB/HCHKSYNIFA) +
                          TOFILE(&OUTLIB/&IFADIF) CRTFILE(*YES))
/*            Perform overrides for output files                     */
              OVRDBF     FILE(HCHKSYNOBJ) TOFILE(&OUTLIB/&OBJDIF)
              OVRDBF     FILE(HCHKSYNMBR) TOFILE(&OUTLIB/&MBRDIF)
              OVRDBF     FILE(HCHKSYNIFS) TOFILE(&OUTLIB/&IFSDIF)
              OVRDBF     FILE(HCHKSYNAUT) TOFILE(&OUTLIB/&AUTDIF)
              OVRDBF     FILE(HCHKSYNIFA) TOFILE(&OUTLIB/&IFADIF)
/*            Perform overrides for input files                      */
              OVRDBF     FILE(HCHKSYNLD) TOFILE(&UTLLIB/&LIBDFS)
              OVRDBF     FILE(HCHKSYNOD) TOFILE(&UTLLIB/&OBJDFS)
              OVRDBF     FILE(HCHKSYNODT) TOFILE(&UTLLIB/&OBJDFT)
              OVRDBF     FILE(HCHKSYNMD) TOFILE(&UTLLIB/&MBRDFS)
              OVRDBF     FILE(HCHKSYNMDT) TOFILE(&UTLLIB/&MBRDFT)
              OVRDBF     FILE(HCHKSYNOA) TOFILE(&UTLLIB/&OBJAFS)
              OVRDBF     FILE(HCHKSYNOAT) TOFILE(&UTLLIB/&OBJAFT)
              OVRDBF     FILE(HCHKSYNID) TOFILE(&UTLLIB/&IFSDFS)
              OVRDBF     FILE(HCHKSYNIDT) TOFILE(&UTLLIB/&IFSDFT)
              OVRDBF     FILE(HCHKSYNIA) TOFILE(&UTLLIB/&IFSAFS)
              OVRDBF     FILE(HCHKSYNIAT) TOFILE(&UTLLIB/&IFSAFT)
              OVRDBF     FILE(HLSTCFGG) TOFILE(QTEMP/HLSTCFGG)
/*            Determine discrepancies                                */
              CALL       PGM(HCHKSYN4A) PARM(&CHKMBR &CHKIFS &CHKAUT +
                          &IGNITV)
/*            Set authorities if requested                           */
              IF         COND(&SETAUT *EQ '*YES') THEN(HSETAUT +
                          ICGROUP(&ICGROUP) AUTIFS(&CHKIFS) +
                          SYNID(&SYNID) SUSAPY(*YES))
/*            Report discrepancies                                   */
/*            Perform overrides for printer files                    */
              OVRPRTF    FILE(HCHKSYNPO) HOLD(*YES) SPLFNAME(&OBJDIF)
              OVRPRTF    FILE(HCHKSYNPM) HOLD(*YES) SPLFNAME(&MBRDIF)
              OVRPRTF    FILE(HCHKSYNPI) HOLD(*YES) SPLFNAME(&IFSDIF)
              OVRPRTF    FILE(HCHKSYNPA) HOLD(*YES) SPLFNAME(&AUTDIF)
              OVRPRTF    FILE(HCHKSYNPJ) HOLD(*YES) SPLFNAME(&IFADIF)
              OVRPRTF    FILE(HCHKSYNPS) HOLD(*YES) SPLFNAME(&SUMDIF)
              OVRPRTF    FILE(HCHKSYNPL) HOLD(*YES) SPLFNAME(&LIBDIF)
              CALL       PGM(HCHKSYN4B) PARM(&ICGROUP &MRKSTR &IGNITV +
                          &OUTFILE &CHKMBR &CHKIFS &CHKAUT &CHKLIB +
                          &OBJDSC &MBRDSC &AUTDSC &IFSDSC &IFADSC +
                          &NBRDSC)
/*            Delete spooled files if no differences found           */
              IF         COND(*NOT &OBJDSC) THEN(DO)
               DLTSPLF    FILE(&OBJDIF) SPLNBR(*LAST)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ENDDO
              IF         COND(*NOT &MBRDSC) THEN(DO)
               DLTSPLF    FILE(&MBRDIF) SPLNBR(*LAST)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ENDDO
              IF         COND(*NOT &AUTDSC) THEN(DO)
               DLTSPLF    FILE(&AUTDIF) SPLNBR(*LAST)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ENDDO
              IF         COND(*NOT &IFSDSC) THEN(DO)
               DLTSPLF    FILE(&IFSDIF) SPLNBR(*LAST)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ENDDO
              IF         COND(*NOT &IFADSC) THEN(DO)
               DLTSPLF    FILE(&IFADIF) SPLNBR(*LAST)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ENDDO
/*            E-Mail reports if requested                            */
              IF         COND(&EMLRPT *EQ '*YES' *OR (&EMLRPT *EQ +
                          '*ERROR' *AND &NBRDSC *NE 0)) THEN(DO)
               CALL       PGM(HCRTPF) PARM('HCHKSYNSPL' 'QTEMP' +
                          'HCHKSYNSPL' &UTLLIB 'HCHKSYN4')
               OVRDBF     FILE(HCHKSYNSPL) TOFILE(QTEMP/HCHKSYNSPL)
/*             Start with summary report (also in body)              */
               CPYSPLF    FILE(&SUMDIF) TOFILE(QTEMP/HCHKSYNSPL) +
                          MBROPT(*REPLACE)
               CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*BDY' ' ' &RTNCDE)
/*             End abnormally if first pass failed                   */
               IF         COND(&RTNCDE *NE ' ') THEN(SNDPGMMSG +
                          MSGID(CST0107) MSGF(HAUMSG) +
                          MSGDTA(&RTNCDE) MSGTYPE(*ESCAPE))
/*             Attach summary report                                 */
               CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*ATT' &SUMDIF +
                          &RTNCDE)
/*             Attach object differences report                      */
               IF         COND(&OBJDSC) THEN(DO)
                CPYSPLF    FILE(&OBJDIF) TOFILE(QTEMP/HCHKSYNSPL) +
                          MBROPT(*REPLACE)
                CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*ATT' &OBJDIF +
                          &RTNCDE)
               ENDDO
/*             Attach member differences report                      */
               IF         COND(&MBRDSC) THEN(DO)
                CPYSPLF    FILE(&MBRDIF) TOFILE(QTEMP/HCHKSYNSPL) +
                          MBROPT(*REPLACE)
                CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*ATT' &MBRDIF +
                          &RTNCDE)
               ENDDO
/*             Attach authority differences report                   */
               IF         COND(&AUTDSC) THEN(DO)
                CPYSPLF    FILE(&AUTDIF) TOFILE(QTEMP/HCHKSYNSPL) +
                          MBROPT(*REPLACE)
                CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*ATT' &AUTDIF +
                          &RTNCDE)
               ENDDO
/*             Attach IFS differences report                         */
               IF         COND(&IFSDSC) THEN(DO)
                CPYSPLF    FILE(&IFSDIF) TOFILE(QTEMP/HCHKSYNSPL) +
                          MBROPT(*REPLACE)
                CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*ATT' &IFSDIF +
                          &RTNCDE)
               ENDDO
/*             Attach IFS authority differences report               */
               IF         COND(&IFADSC) THEN(DO)
                CPYSPLF    FILE(&IFADIF) TOFILE(QTEMP/HCHKSYNSPL) +
                          MBROPT(*REPLACE)
                CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*ATT' &IFADIF +
                          &RTNCDE)
               ENDDO
/*             Attach library report                                 */
               IF         COND(&CHKLIB *EQ '*YES') THEN(DO)
                CPYSPLF    FILE(&LIBDIF) TOFILE(QTEMP/HCHKSYNSPL) +
                          MBROPT(*REPLACE)
                CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*ATT' &LIBDIF +
                          &RTNCDE)
               ENDDO
/*             Now close the IFS file and send the e-mail            */
               CALL       PGM(HCHKSYN4C) PARM(&NBRDSC '*SND' ' ' &RTNCDE)
              ENDDO      /* Send e-mail */
             ENDDO      /* Secondary system */

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG and *ESCAPE messages to previous queue   */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
