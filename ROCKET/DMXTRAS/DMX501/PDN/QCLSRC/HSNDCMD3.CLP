/* ================================================================= */
/* Object:         HSNDCMD3        *PGM CLP                          */
/*                 Restarts the apply jobs after command completion  */
/*                                                                   */
/* Create remarks: None                                              */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20080526 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&DTAARA &UTLLIB &KEY &SBMJOB &SBMUSR +
                          &SBMNBR)

/*           Declare parameter variables                              */
             DCL        VAR(&DTAARA) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&KEY) TYPE(*CHAR) LEN(17)
             DCL        VAR(&SBMJOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBMUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SBMNBR) TYPE(*CHAR) LEN(6)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&SBMSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURDTA) TYPE(*CHAR) LEN(1000)
             DCL        VAR(&CURKEY) TYPE(*CHAR) LEN(17)
             DCL        VAR(&CURNBRGRP@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CURNBRSYN@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CURCMDCMP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CURCMDJOB) TYPE(*CHAR) LEN(28)
             DCL        VAR(&CURGRPSYN) TYPE(*CHAR) LEN(500)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&POS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&LEN) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&GRP) TYPE(*CHAR) LEN(10)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve checkpoint data area                           */
             RTVDTAARA  DTAARA(&UTLLIB/&DTAARA) RTNVAR(&CURDTA)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(END))

/*           Retrieve checkpoint data area                           */
             CHGVAR     VAR(&CURKEY) VALUE(%SST(&CURDTA 23 17))
             CHGVAR     VAR(&CURNBRGRP@) VALUE(%SST(&CURDTA 73 5))
             CHGVAR     VAR(&CURNBRSYN@) VALUE(%SST(&CURDTA 123 5))
             CHGVAR     VAR(&CURCMDCMP) VALUE(%SST(&CURDTA 173 4))
             CHGVAR     VAR(&CURCMDJOB) VALUE(%SST(&CURDTA 223 28))
             CHGVAR     VAR(&CURGRPSYN) VALUE(%SST(&CURDTA 273 500))
/*           Only wait for current key                               */
             IF         COND(&CURKEY *NE &KEY) THEN(SNDPGMMSG +
                          MSGID(SCM0020) MSGF(HAUMSG) +
                          MSGDTA(&DTAARA || &UTLLIB || &CURKEY || +
                          &KEY) MSGTYPE(*ESCAPE))
             SNDPGMMSG  MSGID(SCM0019) MSGF(HAUMSG) MSGDTA(&KEY || +
                          &SBMJOB || &SBMUSR || &SBMNBR) TOPGMQ(*SAME)

/*           Check status of job and wait                            */
 WAITCOMP:   HRTVJOBSTS JOB(&SBMNBR/&SBMUSR/&SBMJOB) STATUS(&SBMSTS)
/*           If job completed or not found, stop waiting             */
             IF         COND(&SBMSTS *EQ '*OUTQ' *OR &SBMSTS *EQ +
                          '*ERROR') THEN(DO)
              SNDPGMMSG  MSGID(SCM0017) MSGF(HAUMSG) MSGDTA(&KEY || +
                          &SBMJOB || &SBMUSR || &SBMNBR) +
                          TOPGMQ(*SAME) MSGTYPE(*COMP)
              CHGVAR     VAR(&CURCMDCMP) VALUE('*YES')
              CHGDTAARA  DTAARA(&UTLLIB/&DTAARA (173 4)) +
                          VALUE(&CURCMDCMP)
              MONMSG     MSGID(CPF0000)
              GOTO       CMDLBL(EWAITCOMP)
             ENDDO
/*           Wait for 1/2 second and loop                            */
             CALL       PGM(HDLYJOBMS) PARM(X'0000500F')
             GOTO       CMDLBL(WAITCOMP)

/*           Restart apply jobs for stopped groups                   */
 EWAITCOMP:  SNDPGMMSG  MSGID(SCM0021) MSGF(HAUMSG) MSGDTA(&KEY || +
                          &SBMJOB || &SBMUSR || &SBMNBR) +
                          TOPGMQ(*SAME) MSGTYPE(*COMP)
             CHGVAR     VAR(&STRPOS) VALUE(1)
 NEXTGRP:    CALL       PGM(QCLSCAN) PARM(&CURGRPSYN X'500F' &STRPOS +
                          ',' X'001F' '0' '0' ' ' &POS)
             IF         COND(&POS *GT 0) THEN(CHGVAR VAR(&LEN) +
                          VALUE(&POS - &STRPOS))
             ELSE       CMD(CHGVAR VAR(&LEN) VALUE(10))
             CHGVAR     VAR(&GRP) VALUE(%SST(&CURGRPSYN &STRPOS &LEN))
             HSTRAPY    ICGROUP(&GRP)
             CHGVAR     VAR(&STRPOS) VALUE(&POS + 1)
             IF         COND(&POS *GT 0) THEN(GOTO CMDLBL(NEXTGRP))

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)
 END:        ENDPGM
