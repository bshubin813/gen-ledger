/* ================================================================= */
/* Object:         HCHKSYNSVF      *PGM CLP                          */
/*                 Executes the HCHKSYNTGT on the secondary system.  */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020110 FK  Initial delivery                                     */
/* 20020523 FK  Allow check for IFS                                  */
/* 20021122 FK  New parameter: Ignore interval                       */
/* 20030428 FK  New parameter: iCluster group                        */
/* 20030501 FK  Program also restores description files              */
/* 20030505 FK  Submit sync check from this program                  */
/* 20030512 FK  New parameter: Check libraries                       */
/* 20030626 FK  Submit sync check job with DEV(*JOBD)                */
/* 20050210 FK  New parameters                                       */
/* 20060215 FK  New parameter: Mark string                           */
/* 20070919 FK  New parameter: E-mail reports                        */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&SAVF &SAVFL &SBMSYNC)

/*           Declare parameter variables                              */
             DCL        VAR(&SAVF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBMSYNC) TYPE(*CHAR) LEN(1)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&SYNPAR) TYPE(*CHAR) LEN(1024)
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CHKMBR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKIFS) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKLIB) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SUSAPY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&IGNITV@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SYNID) TYPE(*CHAR) LEN(5)
             DCL        VAR(&SETAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SAVFLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MRKSTR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&EMLRPT) TYPE(*CHAR) LEN(6)

             DCL        VAR(&TEXT) TYPE(*CHAR) LEN(50)

             DCL        VAR(&SYNFG) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&IGNITV) TYPE(*DEC) LEN(5 0)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve description of save file                       */
             RTVOBJD    OBJ(&SAVFL/&SAVF) OBJTYPE(*FILE) TEXT(&TEXT)

/*           First, restore the configuration data area              */
 RST1:       RSTOBJ     OBJ(HCHKSYNCFG) SAVLIB(QTEMP) DEV(*SAVF) +
                          OBJTYPE(*DTAARA) SAVF(&SAVFL/&SAVF) +
                          MBROPT(*ALL) ALWOBJDIF(*ALL)
             MONMSG     MSGID(CPF3812) EXEC(DO)
              DLYJOB     DLY(1)
              GOTO       CMDLBL(RST1)
             ENDDO

/*           Read the parameter from the data area                   */
             RTVDTAARA  DTAARA(QTEMP/HCHKSYNCFG) RTNVAR(&SYNPAR)
             CHGVAR     VAR(&ICGROUP) VALUE(%SST(&SYNPAR 21 10))
             CHGVAR     VAR(&BCKNOD) VALUE(%SST(&SYNPAR 31 8))
             CHGVAR     VAR(&CHKMBR) VALUE(%SST(&SYNPAR 39 4))
             CHGVAR     VAR(&CHKIFS) VALUE(%SST(&SYNPAR 43 4))
             CHGVAR     VAR(&CHKAUT) VALUE(%SST(&SYNPAR 47 4))
             CHGVAR     VAR(&CHKLIB) VALUE(%SST(&SYNPAR 51 4))
             CHGVAR     VAR(&SUSAPY) VALUE(%SST(&SYNPAR 55 4))
             CHGVAR     VAR(&OUTFILE) VALUE(%SST(&SYNPAR 59 4))
             CHGVAR     VAR(&SYNID) VALUE(%SST(&SYNPAR 63 5))
             CHGVAR     VAR(&SETAUT) VALUE(%SST(&SYNPAR 68 4))
             CHGVAR     VAR(&IGNITV@) VALUE(%SST(&SYNPAR 72 5))
             CHGVAR     VAR(&IGNITV) VALUE(&IGNITV@)
             CHGVAR     VAR(&SAVFLIB) VALUE(%SST(&SYNPAR 77 10))
             CHGVAR     VAR(&UTLLIB) VALUE(%SST(&SYNPAR 87 10))
             CHGVAR     VAR(&MRKSTR) VALUE(%SST(&SYNPAR 97 4))
             CHGVAR     VAR(&EMLRPT) VALUE(%SST(&SYNPAR 101 6))

/*           If Configuration save file --> delete objects from prv. */
             IF         COND(%SST(&TEXT 12 3) *EQ 'CFG') THEN(DO)
              CHGVAR     VAR(&SYNFG) VALUE('HS' |< &SYNID |< 'S*')
              DLTF       FILE(&UTLLIB/&SYNFG)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             ENDDO

/*           When called for the first time --> just submit          */
             IF         COND(&SBMSYNC *EQ '1') THEN(DO)
              IF         COND(%SST(&TEXT 12 3) *EQ 'CFG') THEN(CHGVAR +
                          VAR(&JOB) VALUE('HS' |< &SYNID))
              ELSE       CMD(CHGVAR VAR(&JOB) VALUE('HS' |< &SYNID |< +
                          'RST'))
              SBMJOB     CMD(CALL PGM(HCHKSYNSVF) PARM(&SAVF &SAVFL +
                          '0')) JOB(&JOB) JOBD(&UTLLIB/HCHKSYNTGT) +
                          PRTDEV(*JOBD) INLLIBL(*JOBD)
              GOTO       CMDLBL(END)
             ENDDO

/*           Restore the saved objects in QTEMP                      */
 RST2:       RSTOBJ     OBJ(*ALL) SAVLIB(QTEMP) DEV(*SAVF) +
                          SAVF(&SAVFL/&SAVF) MBROPT(*ALL) +
                          ALWOBJDIF(*ALL)
             MONMSG     MSGID(CPF3812) EXEC(DO)
              DLYJOB     DLY(1)
              GOTO       CMDLBL(RST2)
             ENDDO

/*           If Configuration save file --> run sync. check          */
             IF         COND(%SST(&TEXT 12 3) *EQ 'CFG') THEN(DO)
/*            Now, run the sync check on the target machine           */
              ADDLIBLE   LIB(&UTLLIB)
              MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))
              HCHKSYNTGT ICGROUP(&ICGROUP) SAVFLIB(&SAVFLIB) +
                          OUTFILE(&OUTFILE) SETAUT(&SETAUT) +
                          IGNITV(&IGNITV) BCKNOD(&BCKNOD) +
                          EMLRPT(&EMLRPT) SYNID(&SYNID) +
                          CHKMBR(&CHKMBR) CHKIFS(&CHKIFS) +
                          CHKAUT(&CHKAUT) CHKLIB(&CHKLIB) +
                          SUSAPY(&SUSAPY) MRKSTR(&MRKSTR)
             ENDDO

/*           If Files save file --> restore objects                  */
             IF         COND(%SST(&TEXT 12 3) *EQ 'FIL') THEN(DO)
              RSTOBJ     OBJ(*ALL) SAVLIB(&UTLLIB) DEV(*SAVF) +
                          SAVF(QTEMP/HCHKSYNFIL) MBROPT(*ALL) +
                          ALWOBJDIF(*ALL)
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
