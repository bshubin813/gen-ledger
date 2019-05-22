/* ================================================================= */
/* Object:         HMRKPOS         *PGM CLP                          */
/*                 Command processing program for HMRKPOS.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030603 FK  Initial delivery                                     */
/* 20040319 FK  Only mark positions for local groups                 */
/* 20050429 FK  Delete LFs in QTEMP in the end                       */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20111222 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &WAIT &JOBQQ)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&WAIT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JOBQQ) TYPE(*CHAR) LEN(20)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&NBRGRP) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRACT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRJOBQ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRGRP@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRACT@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRJOBQ@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&JOBQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBQL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    CURLIB(&CURLIB)
             IF         COND(&CURLIB *EQ '*NONE') THEN(CHGVAR +
                          VAR(&CURLIB) VALUE('*CRTDFT'))
             CHGVAR     VAR(&JOBQ) VALUE(%SST(&JOBQQ 1 10))
             CHGVAR     VAR(&JOBQL) VALUE(%SST(&JOBQQ 11 10))

/*           Check jobq queue existence                              */
             IF         COND(&JOBQ *NE '*JOBD') THEN(CHKOBJ +
                          OBJ(&JOBQL/&JOBQ) OBJTYPE(*JOBQ))

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

             HRTVNETA   SYSNAME(&SYSNAME)

/*           Create file to access iCluster groups                   */
             CALL       PGM(HCRTLF) PARM('HIGRPGN')
             OVRDBF     FILE(HIGRPGN) TOFILE(QTEMP/HIGRPGN)

/*           Set current library                                     */
             CHGCURLIB  CURLIB(&ICLIB)

/*           Create file to hold submitted jobs                      */
             DLTF       FILE(QTEMP/HMRKPOS)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HMRKPOS) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(QTEMP)
             OVRDBF     FILE(HMRKPOS) TOFILE(QTEMP/HMRKPOS)

/*           Call program to submit job for every group              */
             CALL       PGM(HMRKPOS1) PARM(&ICGROUP &SYSNAME &JOBQQ +
                          &NBRGRP)
             CHGVAR     VAR(%BIN(&NBRGRP@)) VALUE(&NBRGRP)

/*           If no jobs submitted or no groups found --> error       */
             IF         COND(&NBRGRP *EQ 0) THEN(SNDPGMMSG +
                          MSGID(MPO0004) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP || &JOBQQ) MSGTYPE(*ESCAPE))

/*           If WAIT(*YES) specified --> wait for completion         */
 WAIT:       IF         COND(&WAIT *EQ '*YES') THEN(DO)
              CALL       PGM(HMRKPOS3) PARM(&NBRACT &NBRJOBQ)
              IF         COND(&NBRACT *NE 0 *OR &NBRJOBQ *NE 0) THEN(DO)
               CHGVAR     VAR(%BIN(&NBRACT@)) VALUE(&NBRACT)
               CHGVAR     VAR(%BIN(&NBRJOBQ@)) VALUE(&NBRJOBQ)
               SNDPGMMSG  MSGID(MPO0001) MSGF(HAUMSG) MSGDTA(&NBRGRP@ +
                          || &NBRACT@ || &NBRJOBQ@) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)
               SNDPGMMSG  MSGID(MPO0001) MSGF(HAUMSG) MSGDTA(&NBRGRP@ +
                          || &NBRACT@ || &NBRJOBQ@) MSGTYPE(*INFO)
               DLYJOB     DLY(5)
               GOTO       CMDLBL(WAIT)
              ENDDO
             ENDDO

/*           Delete temporary file from QTEMP                        */
             DLTF       FILE(QTEMP/HMRKPOS)
             MONMSG     MSGID(CPF2105)

/*           Delete H* files in QTEMP                                */
             CALL       PGM(HCRTLFDLT) PARM('*ALL' '*ALL')

/*           Reset current library                                   */
             CHGCURLIB  CURLIB(&CURLIB)

/*           Send completion message based on WAIT parameter         */
             IF         COND(&WAIT *EQ '*YES') THEN(SNDPGMMSG +
                          MSGID(MPO0002) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP || &NBRGRP@) MSGTYPE(*COMP))
             IF         COND(&WAIT *EQ '*NO') THEN(SNDPGMMSG +
                          MSGID(MPO0003) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP || &NBRGRP@) MSGTYPE(*COMP))

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
