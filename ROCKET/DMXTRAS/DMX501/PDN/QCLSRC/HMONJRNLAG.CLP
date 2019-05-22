/* ================================================================= */
/* Object:         HMONJRNLAG      *PGM CLP                          */
/*                 Command processing program for HMONJRNLAG.        */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020911 FK  Initial delivery                                     */
/* 20021029 FK  Allow purge after # of days                          */
/*              Reorganise file at start                             */
/* 20031002 FK  Both *HST and *ADH measurements are allowed          */
/*              Multiple lag measurements, send, apply               */
/* 20031010 FK  Verify format of output file and report error        */
/* 20070502 FK  Copy back data if formats not the same               */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&MSMTYP &LAGFILEL &CHKITV &ALRMSGQQ +
                          &ALWLAG &PRGHST &ALWSNDLAG &ALWAPYLAG)

/*           Declare parameter variables                             */
             DCL        VAR(&MSMTYP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LAGFILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CHKITV) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&ALRMSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ALWLAG) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&PRGHST) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&ALWSNDLAG) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&ALWAPYLAG) TYPE(*DEC) LEN(4 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&ALRMSGQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ALRMSGQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CHKITV@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&DLY) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&STSKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&MSGKEY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ENDSTS) TYPE(*CHAR) LEN(1)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&QDATE) TYPE(*CHAR) LEN(6)
             DCL        VAR(&QDATESV) TYPE(*CHAR) LEN(6)
             DCL        VAR(&PRGHST@) TYPE(*DEC) LEN(4 0)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Split qualifiers                                        */
             CHGVAR     VAR(&ALRMSGQ) VALUE(%SST(&ALRMSGQQ 1 10))
             CHGVAR     VAR(&ALRMSGQL) VALUE(%SST(&ALRMSGQQ 11 10))

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0014) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Check existence of lag file library                     */
             CHKOBJ     OBJ(&LAGFILEL) OBJTYPE(*LIB)

/*           Check existence of message queue                        */
             CHKOBJ     OBJ(&ALRMSGQL/&ALRMSGQ) OBJTYPE(*MSGQ)

/*           If run interactively --> execute in batch               */
             RTVJOBA    TYPE(&JOBTYPE)
             IF         COND(&JOBTYPE *EQ '1') THEN(do)
              ADDLIBLE   LIB(&UTLLIB)
              MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))
              SBMJOB     CMD(HMONJRNLAG MSMTYP(&MSMTYP) +
                          LAGFILEL(&LAGFILEL) CHKITV(&CHKITV) +
                          ALRMSGQ(&ALRMSGQL/&ALRMSGQ) +
                          ALWLAG(&ALWLAG) PRGHST(&PRGHST) +
                          ALWSNDLAG(&ALWSNDLAG) +
                          ALWAPYLAG(&ALWAPYLAG)) JOB(HMONJRNLAG) +
                          JOBD(HMONJRNLAG)
/*            Move all *COMP messages to the previous queue          */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Check if format is the one expected, else replace       */
             CALL       PGM(HCRTPF) PARM('HJRNLAG' &LAGFILEL +
                          'HJRNLAG' &UTLLIB 'HMONJRNLAG')

/*           Create necessary files in QTEMP                         */
 FILCRT:     CALL       PGM(HCRTLF) PARM('HUDGTJL')
             OVRDBF     FILE(HUFHLTS) TOFILE(QTEMP/HUDGTJL)
             CALL       PGM(HCRTLF) PARM('HUFHLTS')
             OVRDBF     FILE(HUFHLTS) TOFILE(QTEMP/HUFHLTS)

/*           Reorganise physical file                                */
             RGZPFM     FILE(&LAGFILEL/HJRNLAG) +
                          KEYFILE(&LAGFILEL/HJRNLAGDJ HJRNLAGDJ)
             MONMSG     MSGID(CPF0000)

/*           First, wait one loop to allow HA/iCluster to start      */
             GOTO       CMDLBL(WAITITV)

/*           Initialise loop                                         */
/*           Only purge history when new day started (or first time) */
 LOOPITV:    RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&QDATE)
             IF         COND(&QDATE *NE &QDATESV) THEN(DO)
              CHGVAR     VAR(&QDATESV) VALUE(&QDATE)
              CHGVAR     VAR(&PRGHST@) VALUE(&PRGHST)
             ENDDO
             ELSE       CMD(CHGVAR VAR(&PRGHST@) VALUE(0))

/*           Call program that processes journal(s)                  */
             CALL       PGM(HMONJRN1) PARM(&MSMTYP &LAGFILEL +
                          &ALRMSGQQ &ALWLAG &ALWSNDLAG &ALWAPYLAG +
                          &PRGHST@)

/*           Wait until next interval                                */
 WAITITV:    CHGVAR     VAR(%BIN(&CHKITV@)) VALUE(&CHKITV)
             CHGVAR     VAR(&DLY) VALUE(&CHKITV * 60)
             SNDPGMMSG  MSGID(MJL0002) MSGF(HAUMSG) MSGDTA(&CHKITV@) +
                          KEYVAR(&STSKEY)
             RCVMSG     MSGTYPE(*NEXT) MSGKEY(&STSKEY) WAIT(&DLY) +
                          KEYVAR(&MSGKEY)
/*           Delay the job 1 second to update status                 */
             DLYJOB     DLY(1)
/*           Remove status message to not confuse operator           */
             RMVMSG     MSGKEY(&STSKEY)
             MONMSG     MSGID(CPF0000)
/*           If job/subsystem or system ended --> quit, else loop    */
             RTVJOBA    ENDSTS(&ENDSTS)
             IF         COND(&ENDSTS *EQ '0') THEN(GOTO +
                          CMDLBL(LOOPITV))

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
