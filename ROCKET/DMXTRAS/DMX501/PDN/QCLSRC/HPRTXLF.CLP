/* ================================================================= */
/* Object:         HPRTXLF         *PGM CLP                          */
/*                 Command processing program for HPRTXLF.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020510 FK  Initial delivery                                     */
/* 20020627 FK  Also work from logical files                         */
/* ================================================================= */
             PGM        PARM(&LIBLST &OUTFILLIB &BATCH)

/*           Declare parameter variables                             */
             DCL        VAR(&LIBLST) TYPE(*CHAR) LEN(1002)
             DCL        VAR(&OUTFILLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&NBRLIB) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&POS) TYPE(*DEC) LEN(4 0)

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(3000)
             DCL        VAR(&LIBERR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)
             RTVOBJD    OBJ(HPRTXLF) OBJTYPE(*PGM) RTNLIB(&UTLLIB)

/*           Check existence of output file library                  */
             CHKOBJ     OBJ(&OUTFILLIB) OBJTYPE(*LIB)

/*           Library for output file must be different than tools lib*/
             IF         COND(&OUTFILLIB *EQ &UTLLIB) THEN(SNDPGMMSG +
                          MSGID(PXL0001) MSGF(HAUMSG) +
                          MSGDTA(&OUTFILLIB) MSGTYPE(*ESCAPE))

/*           Split qualifier variables                               */
             CHGVAR     VAR(&NBRLIB) VALUE(%BIN(&LIBLST 1 2))

/*           Check library existence and make up command             */
             CHGVAR     VAR(&CMD) VALUE('HPRTXLF LIB(')
             CHGVAR     VAR(&I) VALUE(1)
 LOOPLIB:    IF         COND(&I *LE &NBRLIB) THEN(DO)
              CHGVAR     VAR(&POS) VALUE(((&I - 1) * 10) + 3)
              CHGVAR     VAR(&LIB) VALUE(%SST(&LIBLST &POS 10))
/*            Add library to command                                 */
              CHGVAR     VAR(&CMD) VALUE(&CMD |> &LIB)
/*            If library doesn't exist --> warning                   */
              IF         COND(%SST(&LIB 1 1) *NE '*') THEN(DO)
               CHKOBJ     OBJ(&LIB) OBJTYPE(*LIB)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                RCVMSG     MSGTYPE(*LAST)
                SNDPGMMSG  MSGID(PXL0002) MSGF(HAUMSG) MSGDTA(&LIB) +
                          MSGTYPE(*DIAG)
                CHGVAR     VAR(&LIBERR) VALUE('1')
               ENDDO
              ENDDO
              CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOPLIB)
             ENDDO
/*           Add remainder of parameters to command                  */
             CHGVAR     VAR(&CMD) VALUE(&CMD |< ') OUTFILLIB(' |< +
                          &OUTFILLIB |< ') BATCH(' |< &BATCH |< ')')
/*           Send command to menu program to allow F9                */
             IF         COND(&JOBTYPE *EQ '1') THEN(DO)
              SNDPGMMSG  MSG(&CMD) TOPGMQ(*SAME) MSGTYPE(*RQS)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             ENDDO

/*           If any of the libraries doesn't exist --> error         */
             IF         COND(&LIBERR) THEN(SNDPGMMSG MSGID(PXL0003) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Submit job to batch if desired                          */
             IF         COND(&BATCH *EQ '*YES' *AND &JOBTYPE *EQ +
                          '1') THEN(DO)
              CHGVAR     VAR(&CMD) VALUE('SBMJOB CMD(' |< &CMD |< ') +
                          JOB(HPRTXLF) JOBD(HAUTILS)')
              CALL       PGM(QCMDEXC) PARM(&CMD 3000)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Create file in OUTFILLIB to hold DSPDBR output          */
             DLTF       FILE(&OUTFILLIB/HPRTXLF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HPRTXLF) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(&OUTFILLIB)
             DLTF       FILE(&OUTFILLIB/HPRTXLFLF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HPRTXLFLF) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&OUTFILLIB)

/*           Process all specified libraries                         */
             DLTF       FILE(QTEMP/HPRTXLFTMP)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(QTEMP/HPRTXLFFDT)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&I) VALUE(1)
 LOOPLIB2:   IF         COND(&I *LE &NBRLIB) THEN(DO)
              CHGVAR     VAR(&POS) VALUE(((&I - 1) * 20) + 3)
              CHGVAR     VAR(&LIB) VALUE(%SST(&LIBLST &POS 10))
/*            Retrieve member list of specified files                */
              SNDPGMMSG  MSGID(PXL0004) MSGF(HAUMSG) MSGDTA(&LIB) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(PXL0004) MSGF(HAUMSG) MSGDTA(&LIB) +
                          TOPGMQ(*SAME)
              DSPDBR     FILE(&LIB/*ALL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HPRTXLFTMP) OUTMBR(*FIRST *ADD)
              MONMSG     MSGID(CPF0000)
              DSPFD      FILE(&LIB/*ALL) TYPE(*MBR) OUTPUT(*OUTFILE) +
                          FILEATR(*LF) OUTFILE(QTEMP/HPRTXLFFDT) +
                          OUTMBR(*FIRST *ADD)
              MONMSG     MSGID(CPF0000)
              CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOPLIB2)
             ENDDO

/*           Copy all the records to HPRTXLFxx to avoid incompat.    */
             CPYF       FROMFILE(QTEMP/HPRTXLFTMP) +
                          TOFILE(&OUTFILLIB/HPRTXLF) +
                          MBROPT(*REPLACE) FMTOPT(*MAP *DROP)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(QTEMP/HPRTXLFTMP)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             CPYF       FROMFILE(QTEMP/HPRTXLFFDT) +
                          TOFILE(&OUTFILLIB/HPRTXLFLF) +
                          MBROPT(*REPLACE) FMTOPT(*MAP *DROP)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(QTEMP/HPRTXLFFDT)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Run the queries                                         */
             OVRPRTF    FILE(QPQUPRFIL) SPLFNAME(HPRTXLF)
             RUNQRY     QRY(&UTLLIB/HPRTXLF) +
                          QRYFILE((&OUTFILLIB/HPRTXLF)) +
                          OUTTYPE(*PRINTER)
             DLTOVR     FILE(QPQUPRFIL)
             OVRPRTF    FILE(QPQUPRFIL) SPLFNAME(HPRTXLFLF)
             RUNQRY     QRY(&UTLLIB/HPRTXLFLF) +
                          QRYFILE((&OUTFILLIB/HPRTXLFLF)) +
                          OUTTYPE(*PRINTER)
             DLTOVR     FILE(QPQUPRFIL)

/*           Send completion message                                 */
             SNDPGMMSG  MSGID(PXL0005) MSGF(HAUMSG) +
                          MSGDTA(&OUTFILLIB) MSGTYPE(*COMP)

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
