/*CP: USRPRF(*OWNER)                                                 */
/* ================================================================= */
/* Object:         HCHKSYN0        *PGM CLP                          */
/*                 Processes group object specifiers                 */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050210 FK  Initial delivery                                     */
/* 20050322 FK  Change back wait time to original value              */
/*              Allocate file before CPYF to avoid error             */
/* 20050510 FK  Retrieve authorities using API and IFS authorities   */
/* 20070420 FK  Replace HAXMOBJ by HAROBJ access                     */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &UTLLIB &SYNF &CHKMBR +
                          &CHKAUT &CHKIFS &CHKLIB &HAROLE &RTNCDE)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYNF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CHKMBR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKIFS) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKLIB) TYPE(*CHAR) LEN(4)
             DCL        VAR(&HAROLE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&LIBDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJAF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSAF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CFGGF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CFGOF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CFGIF) TYPE(*CHAR) LEN(10)

             DCL        VAR(&DFTWAIT) TYPE(*DEC) LEN(7 0)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    DFTWAIT(&DFTWAIT)

/*           Determine names of output files                         */
             IF         COND(&HAROLE *EQ 'P') THEN(DO)
              CHGVAR     VAR(&LIBDF) VALUE(&SYNF |< 'SL')
              CHGVAR     VAR(&OBJDF) VALUE(&SYNF |< 'SO')
              CHGVAR     VAR(&OBJAF) VALUE(&SYNF |< 'SA')
              CHGVAR     VAR(&MBRDF) VALUE(&SYNF |< 'SM')
              CHGVAR     VAR(&IFSDF) VALUE(&SYNF |< 'SI')
              CHGVAR     VAR(&IFSAF) VALUE(&SYNF |< 'SJ')
             ENDDO
             IF         COND(&HAROLE *EQ 'S') THEN(DO)
              CHGVAR     VAR(&LIBDF) VALUE('DUMMY')
              CHGVAR     VAR(&OBJDF) VALUE(&SYNF |< 'TO')
              CHGVAR     VAR(&OBJAF) VALUE(&SYNF |< 'TA')
              CHGVAR     VAR(&MBRDF) VALUE(&SYNF |< 'TM')
              CHGVAR     VAR(&IFSDF) VALUE(&SYNF |< 'TI')
              CHGVAR     VAR(&IFSAF) VALUE(&SYNF |< 'TJ')
             ENDDO
             CHGVAR     VAR(&CFGGF) VALUE(&SYNF |< 'CG')
             CHGVAR     VAR(&CFGOF) VALUE(&SYNF |< 'CO')
             CHGVAR     VAR(&CFGIF) VALUE(&SYNF |< 'CI')

/*           Prepare files                                           */
             DLTF       FILE(QTEMP/HCHKSYNOD)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(QTEMP/HCHKSYNMD)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(QTEMP/HCHKSYNOA)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(QTEMP/HCHKSYNID)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(QTEMP/HCHKSYNIA)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HCHKSYNOD) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP) DATA(*NO)
             CRTDUPOBJ  OBJ(HCHKSYNMD) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP) DATA(*NO)
             CRTDUPOBJ  OBJ(HCHKSYNOA) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP) DATA(*NO)
             CRTDUPOBJ  OBJ(HCHKSYNID) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP) DATA(*NO)
             CRTDUPOBJ  OBJ(HCHKSYNIA) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP) DATA(*NO)

/*           Create LFs over HAMOBJ, HAXMOBJ and HATMOBJ             */
             CALL       PGM(HCRTLF) PARM('HUMOBOL')
             CALL       PGM(HCRTLF) PARM('HUTMOBOL')
             CALL       PGM(HCRTLF) PARM('HUROBOL')
             OVRDBF     FILE(HUMOBOL) TOFILE(QTEMP/HUMOBOL)
             OVRDBF     FILE(HUTMOBOL) TOFILE(QTEMP/HUTMOBOL)
             OVRDBF     FILE(HUROBOL) TOFILE(QTEMP/HUROBOL)

/*           Perform overrides                                       */
             OVRDBF     FILE(HCHKSYNLD) TOFILE(&UTLLIB/&LIBDF)
             OVRDBF     FILE(HLSTCFGG) TOFILE(&UTLLIB/&CFGGF)
             OVRDBF     FILE(HLSTCFGO) TOFILE(&UTLLIB/&CFGOF)
             OVRDBF     FILE(HLSTCFGI) TOFILE(&UTLLIB/&CFGIF)
             OVRDBF     FILE(HCHKSYNOD) TOFILE(QTEMP/HCHKSYNOD)
             OVRDBF     FILE(HCHKSYNMD) TOFILE(QTEMP/HCHKSYNMD)
             OVRDBF     FILE(HCHKSYNOA) TOFILE(QTEMP/HCHKSYNOA)
             OVRDBF     FILE(HCHKSYNID) TOFILE(QTEMP/HCHKSYNID)
             OVRDBF     FILE(HCHKSYNIA) TOFILE(QTEMP/HCHKSYNIA)
             CHGJOB     DFTWAIT(1)

/*           Retrieve object and member descriptions                 */
             CALL       PGM(HCHKSYN1) PARM(&ICGROUP &CHKMBR &CHKLIB +
                          &HAROLE)

/*           Retrieve IFS object descriptions                        */
             IF         COND(&CHKIFS *EQ '*YES') THEN(DO)
             CALL       PGM(HCHKSYN6) PARM(&ICGROUP &UTLLIB &IFSDF +
                          &RTNCDE)
             ENDDO

/*           Retrieve object authorities for all retrieved objects   */
             IF         COND(&CHKAUT *EQ '*YES') THEN(DO)
              CALL       PGM(HCHKSYN3) PARM(&CHKIFS)
             ENDDO

/*           Now change back default wait to allow longer wait       */
             CHGJOB     DFTWAIT(&DFTWAIT)
             MONMSG     MSGID(CPF0000) EXEC(DO)
              CHGJOB     DFTWAIT(30)
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           Delete overrides                                        */
             DLTOVR     FILE(HLSTCFGO HLSTCFGI HCHKSYNLD HCHKSYNOD +
                          HCHKSYNMD HCHKSYNOA HCHKSYNID HCHKSYNIA)

/*           Copy retrieved information back                         */
 ALCOD:      ALCOBJ     OBJ((&UTLLIB/&OBJDF *FILE *EXCL *FIRST))
             MONMSG     MSGID(CPF1002) EXEC(DO)
              SNDPGMMSG  MSGID(CST0013) MSGF(HAUMSG) MSGDTA(&OBJDF || +
                          &UTLLIB) TOPGMQ(*SAME)
              GOTO       CMDLBL(ALCOD)
             ENDDO
             CPYF       FROMFILE(QTEMP/HCHKSYNOD) +
                          TOFILE(&UTLLIB/&OBJDF) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             DLCOBJ     OBJ((&UTLLIB/&OBJDF *FILE *EXCL *FIRST))
 ALCMD:      ALCOBJ     OBJ((&UTLLIB/&MBRDF *FILE *EXCL *FIRST))
             MONMSG     MSGID(CPF1002) EXEC(DO)
              SNDPGMMSG  MSGID(CST0013) MSGF(HAUMSG) MSGDTA(&MBRDF || +
                          &UTLLIB) TOPGMQ(*SAME)
              GOTO       CMDLBL(ALCMD)
             ENDDO
             CPYF       FROMFILE(QTEMP/HCHKSYNMD) +
                          TOFILE(&UTLLIB/&MBRDF) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             DLCOBJ     OBJ((&UTLLIB/&MBRDF *FILE *EXCL *FIRST))
 ALCOA:      ALCOBJ     OBJ((&UTLLIB/&OBJAF *FILE *EXCL *FIRST))
             MONMSG     MSGID(CPF1002) EXEC(DO)
              SNDPGMMSG  MSGID(CST0013) MSGF(HAUMSG) MSGDTA(&OBJAF || +
                          &UTLLIB) TOPGMQ(*SAME)
              GOTO       CMDLBL(ALCOA)
             ENDDO
             CPYF       FROMFILE(QTEMP/HCHKSYNOA) +
                          TOFILE(&UTLLIB/&OBJAF) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             DLCOBJ     OBJ((&UTLLIB/&OBJAF *FILE *EXCL *FIRST))
 ALCID:      ALCOBJ     OBJ((&UTLLIB/&IFSDF *FILE *EXCL *FIRST))
             MONMSG     MSGID(CPF1002) EXEC(DO)
              SNDPGMMSG  MSGID(CST0013) MSGF(HAUMSG) MSGDTA(&IFSDF || +
                          &UTLLIB) TOPGMQ(*SAME)
              GOTO       CMDLBL(ALCID)
             ENDDO
             CPYF       FROMFILE(QTEMP/HCHKSYNID) +
                          TOFILE(&UTLLIB/&IFSDF) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             DLCOBJ     OBJ((&UTLLIB/&IFSDF *FILE *EXCL *FIRST))
 ALCIA:      ALCOBJ     OBJ((&UTLLIB/&IFSAF *FILE *EXCL *FIRST))
             MONMSG     MSGID(CPF1002) EXEC(DO)
              SNDPGMMSG  MSGID(CST0013) MSGF(HAUMSG) MSGDTA(&IFSAF || +
                          &UTLLIB) TOPGMQ(*SAME)
              GOTO       CMDLBL(ALCIA)
             ENDDO
             CPYF       FROMFILE(QTEMP/HCHKSYNIA) +
                          TOFILE(&UTLLIB/&IFSAF) MBROPT(*ADD)
             MONMSG     MSGID(CPF0000)
             DLCOBJ     OBJ((&UTLLIB/&IFSAF *FILE *EXCL *FIRST))

/*           Delete temporary files from QTEMP                       */
             DLTF       FILE(QTEMP/HCHKSYNOD)
             DLTF       FILE(QTEMP/HCHKSYNMD)
             DLTF       FILE(QTEMP/HCHKSYNOA)
             DLTF       FILE(QTEMP/HCHKSYNID)
             DLTF       FILE(QTEMP/HCHKSYNIA)

             GOTO       CMDLBL(END)

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
