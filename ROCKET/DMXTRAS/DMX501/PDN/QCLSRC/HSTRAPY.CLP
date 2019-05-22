/* ================================================================= */
/* Object:         HSTRAPY         *PGM CLP                          */
/*                 Command processing program for HSTRAPY.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030505 FK  Initial delivery                                     */
/* 20030626 FK  Do not create HIGRPGN if not iCluster                */
/* 20040405 FK  Only end apply jobs for current system (iCluster)    */
/* 20040610 FK  Use HRTVCRG to retrieve group direction              */
/*              New parameter for draining staging sgore             */
/* 20050429 FK  Delete LFs in QTEMP in the end                       */
/* 20060102 FK  iCluster 2.2 compatibility                           */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &FRCDRN)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FRCDRN) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)
             DCL        VAR(&CURLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&SYSNAME) TYPE(*CHAR) LEN(8)
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)

/*           Declare file                                            */
             DCLF       FILE(HIGRPGN)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    CURLIB(&CURLIB)
             IF         COND(&CURLIB *EQ '*NONE') THEN(CHGVAR +
                          VAR(&CURLIB) VALUE('*CRTDFT'))

/*           Determine product that command runs for                 */
             CHGVAR     VAR(&PRD) VALUE('*IC')

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

             HRTVNETA   SYSNAME(&SYSNAME)

/*           Create files to access iCluster                         */
             IF         COND(&PRD *EQ '*IC') THEN(DO)
              CALL       PGM(HCRTLF) PARM('HIGRPGN')
              OVRDBF     FILE(HIGRPGN) TOFILE(QTEMP/HIGRPGN)
             ENDDO

/*           Start apply job for iCluster                            */
             IF         COND(&PRD *EQ '*IC') THEN(DO)
              CHGCURLIB  CURLIB(&ICLIB)
              IF         COND(&ICGROUP *EQ '*ALL') THEN(DO)
 LOOPGRP:      RCVF
               MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOPGRP))
              ENDDO
              ELSE       CMD(CHGVAR VAR(&GROUP) VALUE(&ICGROUP))
/*            Is the apply job for the current system?               */
              HRTVCRG    CRG(&GROUP) BCKNOD(&BCKNOD)
              MONMSG     MSGID(RCR0000 CPF0000)
              IF         COND(&BCKNOD *EQ &SYSNAME) THEN(DO)
               DMSTRAPY   GROUP(&GROUP) FRCDRN(&FRCDRN)
              ENDDO
              IF         COND(&ICGROUP *EQ '*ALL') THEN(GOTO +
                          CMDLBL(LOOPGRP))
 ELOOPGRP:   ENDDO

/*           Delete H* files in QTEMP                                */
             CALL       PGM(HCRTLFDLT) PARM('*ALL' '*ALL')

/*           Reset current library                                   */
             CHGCURLIB  CURLIB(&CURLIB)

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
