/* ================================================================= */
/* Object:         HMONJRN1A       *PGM CLP                          */
/*                 Processes list of journals in HADGT and retrieve  */
/*                 lag through the RTVHAPOS command.                 */
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
/* 20021015 FK  Error in passing parameters to HMONJRN2              */
/* 20021029 FK  Allow purge of history older than # days             */
/* 20031002 FK  Rebuild of HMONJRNLAG tool                           */
/*              Skip security audit journal                          */
/* 20070502 FK  Support for 20-digit sequence numbers                */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&SYSNAM &STRDTS)

/*           Declare parameter variables                             */
             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&STRDTS) TYPE(*CHAR) LEN(26)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&CURDAT) TYPE(*CHAR) LEN(6)
             DCL        VAR(&CURTIME) TYPE(*CHAR) LEN(6)
             DCL        VAR(&CURDATISO) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURDATDTS) TYPE(*CHAR) LEN(26)

             DCL        VAR(&PRCAUDJRN) TYPE(*LGL)
             DCL        VAR(&PRC) TYPE(*CHAR) LEN(4)

             DCL        VAR(&JRNE) TYPE(*CHAR) LEN(625)

             DCL        VAR(&LSTJRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LSTJRNRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LSTJRNSEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&LSTJRNDTS) TYPE(*CHAR) LEN(26)
             DCL        VAR(&SRCJRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SRCJRNRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SRCJRNSEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&SRCJRNDTS) TYPE(*CHAR) LEN(26)
             DCL        VAR(&APYJRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&APYJRNRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&APYJRNSEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&APYJRNDTS) TYPE(*CHAR) LEN(26)
             DCL        VAR(&APYSEQ10) TYPE(*DEC) LEN(10 0)

             DCL        VAR(&TARGET) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RESULT) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JRNSV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNLIBSV) TYPE(*CHAR) LEN(10)

             DCL        VAR(&PRGHST@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)

             DCL        VAR(&CMDDATE) TYPE(*CHAR) LEN(13)

/*           Declare file                                            */
             DCLF       FILE(HUDGTJL)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&SRCJRNRCV) VALUE(' ')
             CHGVAR     VAR(&SRCJRNRCVL) VALUE(' ')
             CHGVAR     VAR(&SRCJRNSEQ) VALUE('00000000000000000000')
             CHGVAR     VAR(&SRCJRNDTS) VALUE(' ')

/*           Determine command version (with or witout large pos)    */
             RTVOBJD    OBJ(RTVHAPOS) OBJTYPE(*CMD) SRCDATE(&CMDDATE)

/*           Retrieve product for which tool runs                    */
             HRTVPRDLIB ICPRODLIB(&ICLIB)
             IF         COND(&ICLIB *NE '*NONE') THEN(CHGVAR +
                          VAR(&PRD) VALUE('*IC'))

/*           Retrieve key values for populating the lag file         */
             RTVNETA    SYSNAME(&SYSNAM)
             RTVSYSVAL  SYSVAL(QDATE) RTNVAR(&CURDAT)
             RTVSYSVAL  SYSVAL(QTIME) RTNVAR(&CURTIME)
             CVTDAT     DATE(&CURDAT) TOVAR(&CURDATISO) +
                          FROMFMT(*SYSVAL) TOFMT(*ISO)
             CHGVAR     VAR(&CURDATDTS) VALUE(&CURDATISO || '-' || +
                          %SST(&CURTIME 1 2) || '.' || +
                          %SST(&CURTIME 3 2) || '.' || +
                          %SST(&CURTIME 5 2) || '.000000')
             CHGVAR     VAR(&STRDTS) VALUE(&CURDATDTS)

/*           Process all data journals                               */
 LOOPJRN:    RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOPJRN))
/*           Process only one entry for the data journals            */
             IF         COND(&JRNNAME *EQ &JRNSV *AND &JRNLIB *EQ +
                          &JRNLIBSV) THEN(GOTO CMDLBL(LOOPJRN))
             CHGVAR     VAR(&JRNSV) VALUE(&JRNNAME)
             CHGVAR     VAR(&JRNLIBSV) VALUE(&JRNLIB)

/*           Send status message to indicate current journal         */
             SNDPGMMSG  MSGID(MJL0003) MSGF(HAUMSG) MSGDTA(&JRNNAME +
                          || &JRNLIB) TOPGMQ(*SAME) MSGTYPE(*INFO)

/*           Check if journal is processed by iCluster               */
             HDLTJRNCHK JRN(&JRNLIB/&JRNNAME) PRD(&PRD) PRC(&PRC)
             MONMSG     MSGID(DJC0000 CPF0000) EXEC(GOTO +
                          CMDLBL(LOOPJRN))
             IF         COND(&PRC *EQ '*NO') THEN(DO)
              SNDPGMMSG  MSGID(MJL0004) MSGF(HAUMSG) MSGDTA(&JRNNAME +
                          || &JRNLIB) TOPGMQ(*SAME) MSGTYPE(*DIAG)
              GOTO       CMDLBL(LOOPJRN)
             ENDDO

/*           Retrieve current apply journal position in iCluster     */
              RTVHAPOS   JOURNAL(&JRNLIB/&JRNNAME) TARGET(&TARGET) +
                          GROUP(&GROUP) JRNENTLRG(&APYJRNSEQ) +
                          JRNRCVNME(&APYJRNRCV) +
                          JRNRCVLIB(&APYJRNRCVL) RESULT(&RESULT)
             IF         COND(&RESULT *NE '*SUCCESS') THEN(do)
              SNDPGMMSG  MSGID(MJL0005) MSGF(HAUMSG) MSGDTA(&JRNNAME +
                          || &JRNLIB) TOPGMQ(*SAME) MSGTYPE(*DIAG)
              GOTO       CMDLBL(LOOPJRN)
             ENDDO

/*           Retrieve date-time stamp for journal entry              */
             CALL       PGM(HMONJRN5) PARM(&JRNNAME &JRNLIB +
                          &APYJRNRCV &APYJRNRCVL &APYJRNSEQ &APYJRNDTS)

/*           Retrieve the last entry of the current receiver         */
             HRTVJRNE   JRN(&JRNLIB/&JRNNAME) JRNRCV(*CURRENT) +
                          FROMENTLRG(*LAST) RTNRCV(&LSTJRNRCV) +
                          RTNRCVLIB(&LSTJRNRCVL) +
                          RTNSEQLRG(&LSTJRNSEQ) RTNENTDTS(&LSTJRNDTS)
             MONMSG     MSGID(CPF0000) EXEC(GOTO LOOPJRN)

/*           Retrieve date-time stamp for journal entry              */
             CALL       PGM(HMONJRN5) PARM(&JRNNAME &JRNLIB +
                          &LSTJRNRCV &LSTJRNRCVL &LSTJRNSEQ &LSTJRNDTS)

/*           Write replication lag record in lag file                */
             CALL       PGM(HMONJRN2) PARM(&SYSNAM '*ADH' &TARGET +
                          &GROUP &JRNNAME &JRNLIB &CURDATDTS +
                          &LSTJRNRCV &LSTJRNRCVL &LSTJRNSEQ +
                          &LSTJRNDTS &SRCJRNRCV &SRCJRNRCVL +
                          &SRCJRNSEQ &SRCJRNDTS &APYJRNRCV +
                          &APYJRNRCVL &APYJRNSEQ &APYJRNDTS)

/*           Read next record                                        */
             GOTO       CMDLBL(LOOPJRN)

 ELOOPJRN:   GOTO       CMDLBL(END)

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
