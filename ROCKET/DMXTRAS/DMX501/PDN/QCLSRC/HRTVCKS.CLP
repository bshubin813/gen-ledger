/* ================================================================= */
/* Object:         HRTVCKS         *PGM CLP                          */
/*                 Retrieves the checksum of the passed file into    */
/*                 an output file.                                   */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050420 FK  Initial delivery                                     */
/* 20050521 FK  Also allow to run on backup node                     */
/* 20050721 FK  No override is used anymore                          */
/* 20050727 FK  Handle error on return code                          */
/*              Specify record length for IFS file                   */
/* 20060425 FK  Allow different target library for file              */
/*              Specify running system                               */
/* 20111217 FK  Remove HA Suite    tem                               */
/* ================================================================= */
             PGM        PARM(&FILSYS &FILEQ &MBR &PATH &OUTFILEQ +
                          &ICGROUP &BCKOUTFQ &NBRRCD &STRRCD +
                          &ENDRCD &BLKSIZ &RCDLEN &RUNSYS &TGTLIB +
                          &CKSTYP)

/*           Declare parameter variables                              */
             DCL        VAR(&FILSYS) TYPE(*CHAR) LEN(4)
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&MBR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PATH) TYPE(*CHAR) LEN(5002)
             DCL        VAR(&OUTFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKOUTFQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&NBRRCD) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&STRRCD) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&ENDRCD) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&BLKSIZ) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&RCDLEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&RUNSYS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TGTLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CKSTYP) TYPE(*CHAR) LEN(5)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKOUTF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKOUTFL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&PATHLEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&IFSFILE) TYPE(*CHAR) LEN(5000)
             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&CURUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEATR) TYPE(*CHAR) LEN(30)
             DCL        VAR(&CHKSUM) TYPE(*CHAR) LEN(32)
             DCL        VAR(&NBRRCD@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRRCD@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENDRCD@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RCDLEN@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&NBRCURRCD) TYPE(*DEC) LEN(10 0)
             DCL        VAR(&NBRDLTRCD) TYPE(*DEC) LEN(10 0)

             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    USER(&CURUSR) TYPE(&JOBTYPE)
             RTVNETA    SYSNAME(&SYSNAM)

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)
             IF         COND(&ICGROUP *NE '*NONE' *AND &ICLIB *EQ +
                          '*NONE') THEN(SNDPGMMSG MSGID(DMX0012) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Determine parameters                                    */
             IF         COND(&FILSYS *EQ '*NTV') THEN(DO)
              CHGVAR     VAR(&FILE) VALUE(%SST(&FILEQ 1 10))
              CHGVAR     VAR(&FILEL) VALUE(%SST(&FILEQ 11 10))
              CHGVAR     VAR(&IFSFILE) VALUE('*N')
             ENDDO
             IF         COND(&FILSYS *EQ '*IFS') THEN(DO)
              CHGVAR     VAR(&PATHLEN) VALUE(%BIN(&PATH 1 2))
              CHGVAR     VAR(&IFSFILE) VALUE(%SST(&PATH 3 &PATHLEN))
              CHGVAR     VAR(&FILE) VALUE('*N')
              CHGVAR     VAR(&FILEL) VALUE('*N')
              CHGVAR     VAR(&MBR) VALUE('*N')
             ENDDO

/*           Split qualifiers                                        */
             CHGVAR     VAR(&OUTFILE) VALUE(%SST(&OUTFILEQ 1 10))
             CHGVAR     VAR(&OUTFILEL) VALUE(%SST(&OUTFILEQ 11 10))
             CHGVAR     VAR(&BCKOUTF) VALUE(%SST(&BCKOUTFQ 1 10))
             CHGVAR     VAR(&BCKOUTFL) VALUE(%SST(&BCKOUTFQ 11 10))

/*           Retrieve input file                                     */
             IF         COND(&FILSYS *EQ '*NTV' *AND &RUNSYS *EQ +
                          '*PRIMARY') THEN(DO)
              RTVMBRD    FILE(&FILEL/&FILE) MBR(&MBR) RTNLIB(&FILEL) +
                          RTNMBR(&MBR) FILEATR(&FILEATR) +
                          NBRCURRCD(&NBRCURRCD) NBRDLTRCD(&NBRDLTRCD)
              IF         COND(&FILEATR *NE '*PF') THEN(SNDPGMMSG +
                          MSGID(RCK0001) MSGF(HAUMSG) MSGDTA(&FILE +
                          || &FILEL) MSGTYPE(*ESCAPE))
             ENDDO
             IF         COND(&TGTLIB *EQ '*FILELIB') THEN(CHGVAR +
                          VAR(&TGTLIB) VALUE(&FILEL))
             IF         COND(&FILSYS *EQ '*NTV' *AND &RUNSYS *EQ +
                          '*BACKUP') THEN(DO)
              RTVMBRD    FILE(&TGTLIB/&FILE) MBR(&MBR) +
                          RTNLIB(&TGTLIB) RTNMBR(&MBR) +
                          FILEATR(&FILEATR) NBRCURRCD(&NBRCURRCD) +
                          NBRDLTRCD(&NBRDLTRCD)
              IF         COND(&FILEATR *NE '*PF') THEN(SNDPGMMSG +
                          MSGID(RCK0001) MSGF(HAUMSG) MSGDTA(&FILE +
                          || &TGTLIB) MSGTYPE(*ESCAPE))
             ENDDO

/*           Check OUTFILE parameter                                 */
             IF         COND(&OUTFILE *NE '*NONE' *AND &OUTFILEL *EQ +
                          ' ') THEN(SNDPGMMSG MSGID(RCK0004) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Handle output file                                      */
             IF         COND(&OUTFILE *NE '*NONE') THEN(DO)
/*            Check existence and validity of outfile library        */
              CHKOBJ     OBJ(&OUTFILEL) OBJTYPE(*LIB)
              IF         COND(&OUTFILEL *EQ &UTLLIB) THEN(SNDPGMMSG +
                          MSGID(RCK0002) MSGF(HAUMSG) +
                          MSGDTA(&OUTFILEL) MSGTYPE(*ESCAPE))
/*            If output file doesn't exist --> create                */
              CHKOBJ     OBJ(&OUTFILEL/&OUTFILE) OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CRTDUPOBJ  OBJ(HRTVCKS) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(&OUTFILEL) NEWOBJ(&OUTFILE) DATA(*NO)
              ENDDO
             ENDDO

/*           If last block of file to be checked --> determine start */
             IF         COND(&FILSYS *EQ '*NTV' *AND &STRRCD *EQ +
                          999999999) THEN(DO)
              CHGVAR     VAR(&STRRCD) VALUE(&NBRCURRCD + &NBRDLTRCD - +
                          &NBRRCD)
              IF         COND(&STRRCD *LE 0) THEN(CHGVAR VAR(&STRRCD) +
                          VALUE(1))
             ENDDO

/*           Send command to target system                           */
             IF         COND(&ICGROUP *NE '*NONE') THEN(DO)
              HSNDCMD    CMD(HRTVCKS FILSYS(&FILSYS) +
                          FILE(&FILEL/&FILE) MBR(&MBR) +
                          PATH(&IFSFILE) +
                          OUTFILE(&BCKOUTFL/&BCKOUTF) +
                          NBRRCD(&NBRRCD) STRRCD(&STRRCD) +
                          ENDRCD(&ENDRCD) BLKSIZ(&BLKSIZ) +
                          RCDLEN(&RCDLEN) RUNSYS(*BACKUP) +
                          TGTLIB(&TGTLIB) CKSTYP(&CKSTYP)) +
                          ICGROUP(&ICGROUP) APPLY(*YES) BATCH(*YES) +
                          JOB(HRTVCKS)
             ENDDO

/*           Call program that retrieves checksum                    */
             IF         COND(&OUTFILE *NE '*NONE') THEN(OVRDBF +
                          FILE(HRTVCKS) TOFILE(&OUTFILEL/&OUTFILE))
             CALL       PGM(HRTVCKS1) PARM(&SYSNAM &FILSYS &FILEL +
                          &FILE &MBR &TGTLIB &RUNSYS &PATH +
                          &OUTFILE &CKSTYP &NBRRCD &STRRCD &ENDRCD +
                          &BLKSIZ &RCDLEN &CHKSUM &RTNCDE)
             IF         COND(&OUTFILE *NE '*NONE') THEN(DLTOVR +
                          FILE(HRTVCKS))

/*           If return code not empty --> forward error              */
             IF         COND(&RTNCDE *NE ' ') THEN(SNDPGMMSG +
                          MSGID(&RTNCDE) MSGF(QCPFMSG) +
                          MSGTYPE(*ESCAPE))

/*           Send completion message for total checksum              */
             IF         COND(&FILSYS *EQ '*NTV') THEN(DO)
              CHGVAR     VAR(%BIN(&NBRRCD@)) VALUE(&NBRRCD)
              CHGVAR     VAR(%BIN(&STRRCD@)) VALUE(&STRRCD)
              CHGVAR     VAR(%BIN(&ENDRCD@)) VALUE(&ENDRCD)
              CHGVAR     VAR(%BIN(&RCDLEN@)) VALUE(&RCDLEN)
              SNDPGMMSG  MSGID(RCK0003) MSGF(HAUMSG) MSGDTA(&FILE || +
                          &FILEL || &MBR || &CHKSUM || &STRRCD@ || +
                          &ENDRCD@ || &NBRRCD@ || &RCDLEN@) +
                          MSGTYPE(*COMP)
              IF         COND(&OUTFILE *EQ '*NONE' *AND &JOBTYPE *EQ +
                          '0') THEN(SNDPGMMSG MSGID(RCK0003) +
                          MSGF(HAUMSG) MSGDTA(&FILE || &FILEL || +
                          &MBR || &CHKSUM || &STRRCD@ || &ENDRCD@ +
                          || &NBRRCD@ || &RCDLEN@) TOUSR(&CURUSR) +
                          MSGTYPE(*COMP))
             ENDDO
             IF         COND(&FILSYS *EQ '*IFS') THEN(DO)
              CHGVAR     VAR(%BIN(&NBRRCD@)) VALUE(&NBRRCD)
              CHGVAR     VAR(%BIN(&STRRCD@)) VALUE(&STRRCD)
              CHGVAR     VAR(%BIN(&ENDRCD@)) VALUE(&ENDRCD)
              CHGVAR     VAR(%BIN(&RCDLEN@)) VALUE(&RCDLEN)
              SNDPGMMSG  MSGID(RCK0008) MSGF(HAUMSG) +
                          MSGDTA(%SST(&IFSFILE 1 2000) || &CHKSUM +
                          || &STRRCD@ || &ENDRCD@ || &NBRRCD@ || +
                          &RCDLEN@) MSGTYPE(*COMP)
              IF         COND(&OUTFILE *EQ '*NONE' *AND &JOBTYPE *EQ +
                          '0') THEN(SNDPGMMSG MSGID(RCK0008) +
                          MSGF(HAUMSG) MSGDTA(%SST(&IFSFILE 1 2000) +
                          || &CHKSUM || &STRRCD@ || &ENDRCD@ || +
                          &NBRRCD@ || &RCDLEN@) TOUSR(&CURUSR) +
                          MSGTYPE(*COMP))
             ENDDO

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
