/* ================================================================= */
/* Object:         HPRTSAJ         *PGM CLP                          */
/*                 Command processing program for HPRTSAJ.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990708 FK  Initial delivery                                     */
/* 20010719 FK  Allow output to output file                          */
/* 20030123 FK  DAYS and HOURS can both be specified                 */
/*              Allow submit to batch                                */
/* 20070521 FK  Rename HPRTSAJ$ to HPRTSAJP                          */
/* ================================================================= */
             PGM        PARM(&DAYS &HOURS &USRPRF &JOB &PGM &OBJ +
                          &LIB &TYPE &SCAN &INCTZC &ENTTYP &BATCH +
                          &OUTPUT &JRNRCVQ &OUTFILEQ)

/*           Declare parameter variables                              */
             DCL        VAR(&DAYS) TYPE(*DEC) LEN(3)
             DCL        VAR(&HOURS) TYPE(*DEC) LEN(3)
             DCL        VAR(&USRPRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PGM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TYPE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&SCAN) TYPE(*CHAR) LEN(20)
             DCL        VAR(&INCTZC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENTTYP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)
             DCL        VAR(&OUTPUT) TYPE(*CHAR) LEN(8)
             DCL        VAR(&JRNRCVQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&OUTFILEQ) TYPE(*CHAR) LEN(20)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&CURDAT) TYPE(*CHAR) LEN(6)
             DCL        VAR(&CURDATJ) TYPE(*CHAR) LEN(7)
             DCL        VAR(&CURDAY) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&CURYEAR) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&CURTIM) TYPE(*CHAR) LEN(6)
             DCL        VAR(&CURHOUR) TYPE(*DEC) LEN(2 0)
             DCL        VAR(&STRDAT) TYPE(*CHAR) LEN(6)
             DCL        VAR(&STRTIM) TYPE(*CHAR) LEN(6)

             DCL        VAR(&PRDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&JRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILEL) TYPE(*CHAR) LEN(10)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)
             IF         COND(&JOBTYPE *EQ '0' *AND &OUTPUT *EQ '*') +
                          THEN(CHGVAR VAR(&OUTPUT) VALUE('*PRINT'))

/*           Retrieve library where to find supporting objects       */
             RTVOBJD    OBJ(HPRTSAJ) OBJTYPE(*PGM) RTNLIB(&PRDLIB)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRNRCV) VALUE(%SST(&JRNRCVQ 1 10))
             CHGVAR     VAR(&JRNRCVL) VALUE(%SST(&JRNRCVQ 11 10))
             CHGVAR     VAR(&OUTFILE) VALUE(%SST(&OUTFILEQ 1 10))
             CHGVAR     VAR(&OUTFILEL) VALUE(%SST(&OUTFILEQ 11 10))

/*           Check existence of journal receiver                     */
             IF         COND(&JRNRCV *NE '*CURCHAIN') THEN(CHKOBJ +
                          OBJ(&JRNRCVL/&JRNRCV) OBJTYPE(*JRNRCV))

/*           Submit to batch if specified                            */
             IF         COND(&BATCH *EQ '*YES' *AND &JOBTYPE *EQ +
                          '1') THEN(DO)
              SBMJOB     CMD(HPRTSAJ DAYS(&DAYS) HOURS(&HOURS) +
                          USRPRF(&USRPRF) JOB(&JOB) PGM(&PGM) +
                          OBJ(&OBJ) LIB(&LIB) TYPE(&TYPE) +
                          SCAN(&SCAN) INCTZC(&INCTZC) +
                          ENTTYP(&ENTTYP) BATCH(*NO) +
                          OUTPUT(&OUTPUT) +
                          OUTFILE(&OUTFILEL/&OUTFILE) +
                          JRNRCV(&JRNRCVL/&JRNRCV)) JOB(HPRTSAJ) +
                          JOBD(HAUTILS) INLLIBL(*JOBD)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Retrieve current date in julian format                  */
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&CURDAT)
             CVTDAT     DATE(&CURDAT) TOVAR(&CURDATJ) +
                          FROMFMT(*SYSVAL) TOFMT(*LONGJUL) TOSEP(*NONE)
             CHGVAR     VAR(&CURYEAR) VALUE(%SST(&CURDATJ 1 4))
             CHGVAR     VAR(&CURDAY) VALUE(%SST(&CURDATJ 5 3))

/*           Calculate the starting time (if not *DAYS)              */
             CHGVAR     VAR(&STRTIM) VALUE('000000')
             IF         COND(&HOURS *NE -1) THEN(DO)
              RTVSYSVAL  SYSVAL(QTIME) RTNVAR(&CURTIM)
              CHGVAR     VAR(&CURHOUR) VALUE(%SST(&CURTIM 1 2))
              CHGVAR     VAR(&CURHOUR) VALUE(&CURHOUR - &HOURS)
              IF         COND(&CURHOUR *LT 0) THEN(DO)
               CHGVAR     VAR(&CURHOUR) VALUE(24 - &CURHOUR)
               CHGVAR     VAR(&DAYS) VALUE(1)
              ENDDO
              CHGVAR     VAR(%SST(&STRTIM 1 2)) VALUE(&CURHOUR)
              CHGVAR     VAR(%SST(&STRTIM 3 4)) VALUE(%SST(&CURTIM 3 4))
             ENDDO

/*           Calculate the starting date (if not *HOURS)             */
             IF         COND(&DAYS *NE -1) THEN(DO)
              CHGVAR     VAR(&CURDAY) VALUE(&CURDAY - &DAYS)
              IF         COND(&CURDAY *LE 0) THEN(DO)
               CHGVAR     VAR(&CURDAY) VALUE(365 + &CURDAY)
               CHGVAR     VAR(&CURYEAR) VALUE(&CURYEAR - 1)
              ENDDO
             ENDDO

/*           Convert date to *JOB format again                       */
             CHGVAR     VAR(%SST(&CURDATJ 1 4)) VALUE(&CURYEAR)
             CHGVAR     VAR(%SST(&CURDATJ 5 3)) VALUE(&CURDAY)
             CVTDAT     DATE(&CURDATJ) TOVAR(&STRDAT) +
                          FROMFMT(*LONGJUL) TOFMT(*JOB) TOSEP(*NONE)

/*           Duplicate files to QTEMP                                */
             DLTF       FILE(QTEMP/HPRTSAJ)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HPRTSAJ) FROMLIB(&PRDLIB) OBJTYPE(*FILE) +
                          TOLIB(QTEMP)

/*           Display journal entries to output file                  */
             SNDPGMMSG  MSGID(PSA0001) MSGF(HAUMSG) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)
             IF         COND(&JRNRCV *EQ '*CURCHAIN') THEN(DSPJRN +
                          JRN(QSYS/QAUDJRN) RCVRNG(*CURCHAIN) +
                          FROMTIME(&STRDAT &STRTIM) ENTTYP(&ENTTYP) +
                          JOB(&JOB) PGM(&PGM) USRPRF(&USRPRF) +
                          OUTPUT(*OUTFILE) OUTFILFMT(*TYPE2) +
                          OUTFILE(QTEMP/HSAJTMP))
             ELSE       CMD(DSPJRN JRN(QSYS/QAUDJRN) +
                          RCVRNG(&JRNRCVL/&JRNRCV) FROMTIME(&STRDAT +
                          &STRTIM) ENTTYP(&ENTTYP) JOB(&JOB) +
                          PGM(&PGM) USRPRF(&USRPRF) +
                          OUTPUT(*OUTFILE) OUTFILFMT(*TYPE2) +
                          OUTFILE(QTEMP/HSAJTMP))

/*           Copy the journal entries to formatted output file       */
             CPYF       FROMFILE(QTEMP/HSAJTMP) +
                          TOFILE(QTEMP/HPRTSAJ) MBROPT(*REPLACE) +
                          FMTOPT(*NOCHK)
             DLTF       FILE(QTEMP/HSAJTMP)

/*           Send status message: "Selecting journal entries ..."    */
             SNDPGMMSG  MSGID(PSA0002) MSGF(HAUMSG) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)

/*           If output to display, hold the spooled file             */
             IF         COND(&OUTPUT *EQ '*') THEN(OVRPRTF +
                          FILE(HPRTSAJP) HOLD(*YES))

/*           Make sure that the proper file is used for output       */
             IF         COND(&OUTPUT *EQ '*' *OR &OUTPUT *EQ +
                          '*PRINT') THEN(DO)
              OVRDBF     FILE(HPRTSAJ) TOFILE(QTEMP/HPRTSAJ)
              CALL       PGM(HPRTSAJR) PARM(&DAYS &HOURS &USRPRF &JOB +
                          &PGM &OBJ &LIB &TYPE &SCAN &INCTZC &ENTTYP)
              DLTOVR     FILE(HPRTSAJ)
             ENDDO

/*           If output to display, display and delete the spoolfile  */
             IF         COND(&OUTPUT *EQ '*') THEN(DO)
              DSPSPLF    FILE(HPRTSAJP) SPLNBR(*LAST)
              DLTSPLF    FILE(HPRTSAJP) SPLNBR(*LAST)
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           Output to outfile                                       */
             IF         COND(&OUTPUT *EQ '*OUTFILE') THEN(DO)
              CPYF       FROMFILE(QTEMP/HPRTSAJ) +
                          TOFILE(&OUTFILEL/&OUTFILE) MBROPT(*ADD) +
                          CRTFILE(*YES)
             ENDDO

/*           Clean up QTEMP                                          */
             DLTF       FILE(QTEMP/HPRTSAJ)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Send completion message                                 */
             SNDPGMMSG  MSGID(PSA0007) MSGF(HAUMSG) MSGDTA(&OUTPUT) +
                          MSGTYPE(*COMP)

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
