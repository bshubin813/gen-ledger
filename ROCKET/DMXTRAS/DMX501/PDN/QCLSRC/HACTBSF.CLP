/* ================================================================= */
/* Object:         HACTBSF           *PGM CLP                        */
/*                 Shell program for reading the audit journal and   */
/*                 activating BSF objects as changes occur.          */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:       Calls the RCVJRNE command to process the journal  */
/*                 entries from QAUDJRN and calls exit program       */
/*                 HACTBSF1 to process the entries belonging to the  */
/*                 group being processed.                            */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20090212 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&ICGROUP &ACTTZC &AUDTCO &ACTTCO +
                          &POSFILEQ &DELAY &RESETPOS)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTTZC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&AUDTCO) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ACTTCO) TYPE(*CHAR) LEN(4)
             DCL        VAR(&POSFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DELAY) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&RESETPOS) TYPE(*CHAR) LEN(4)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&POSFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&POSFILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICUSER) TYPE(*CHAR) LEN(10)

             DCL        VAR(&TGTNAM) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNSEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JRNDTS) TYPE(*CHAR) LEN(26)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&ENDSTS) TYPE(*CHAR) LEN(1)

             DCL        VAR(&DELAY@) TYPE(*CHAR) LEN(3)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB) +
                          ICUSER(&ICUSER)
/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Split qualifiers                                        */
             CHGVAR     VAR(&POSFILE) VALUE(%SST(&POSFILEQ 1 10))
             CHGVAR     VAR(&POSFILEL) VALUE(%SST(&POSFILEQ 11 10))

/*           Create or replace output file(s)                        */
             CALL       PGM(HCRTPF) PARM(&POSFILE &POSFILEL +
                          'HACTBSF' &UTLLIB 'HACTBSF')

/*           Ensure proper file is used                              */
             OVRDBF     FILE(HACTBSF) TOFILE(&POSFILEL/&POSFILE)

/*           Retrieve current position                               */
             CALL       PGM(HACTBSF3) PARM('*RTV' &ICGROUP &JRNRCV +
                          &JRNRCVL &JRNSEQ &JRNDTS &RTNCDE)
             IF         COND(&RTNCDE *NE ' ') THEN(CHGVAR +
                          VAR(&RESETPOS) VALUE('*YES'))

/*           If action reset --> get last journal entry              */
             IF         COND(&RESETPOS *EQ '*YES') THEN(DO)
              HRTVJRNE   JRN(QSYS/QAUDJRN) FROMENTLRG(*LAST) +
                          RTNRCV(&JRNRCV) RTNRCVLIB(&JRNRCVL) +
                          RTNSEQLRG(&JRNSEQ) RTNENTDTS(&JRNDTS)
              CALL       PGM(HACTBSF3) PARM('*SET' &ICGROUP &JRNRCV +
                          &JRNRCVL &JRNSEQ &JRNDTS &RTNCDE)
              SNDPGMMSG  MSGID(ABS0001) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &JRNRCV || &JRNRCVL || &JRNSEQ || +
                          &JRNDTS) MSGTYPE(*COMP)
              GOTO       CMDLBL(ENDPRC)
             ENDDO

/*           If run interactively, submit to batch                   */
             IF         COND(&JOBTYPE *EQ '1') THEN(DO)
              SBMJOB     CMD(HACTBSF ICGROUP(&ICGROUP) +
                          ACTTZC(&ACTTZC) AUDTCO(&AUDTCO) +
                          ACTTCO(&ACTTCO) DELAY(&DELAY) +
                          POSFILE(&POSFILEL/&POSFILE) +
                          RESETPOS(*NO)) JOB(HACTBSF) JOBD(HACTBSF) +
                          USER(&ICUSER)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(ENDPRC)
             ENDDO

/*           Determine target name for group                         */
             CHGCURLIB  CURLIB(&ICLIB)
             HRTVCRG    CRG(&ICGROUP) BCKNOD(&TGTNAM)

/*           List IFS object specifiers                              */
             HLSTCFG    OUTLIB(QTEMP) ICGROUP(&ICGROUP) CFGTYP(*IFS)
             OVRDBF     FILE(HLSTCFGI) TOFILE(QTEMP/HLSTCFGI)

/*           Prepare LDA for inter-program communications            */
             CHGVAR     VAR(&DELAY@) VALUE(&DELAY)
             CHGDTAARA  DTAARA(*LDA *ALL) VALUE(&TGTNAM || &ICGROUP +
                          || &ACTTZC || &AUDTCO || &ACTTCO || +
                          &DELAY@ || &JRNRCV || &JRNRCVL)

/*           Start reading journal from retrieved position           */
             SNDPGMMSG  MSGID(ABS0002) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &JRNRCV || &JRNRCVL || &JRNSEQ || +
                          &JRNDTS) TOPGMQ(*SAME)
 LOOP:       RCVJRNE    JRN(QSYS/QAUDJRN) EXITPGM(HACTBSF1) +
                          RCVRNG(&JRNRCVL/&JRNRCV) FROMENT(&JRNSEQ) +
                          JRNCDE((T) (J)) ENTTYP(CO ZC NR PR) +
                          ENTFMT(*TYPE4) NULLINDLEN(1) +
                          DELAY(*NEXTENT 15)

/*           Check if reason for ending RCVJRNE was shut down        */
             RTVJOBA    ENDSTS(&ENDSTS)
             IF         COND(&ENDSTS *EQ '1') THEN(GOTO CMDLBL(ELOOP))

/*           If reason not shutdown --> get last applied and loop    */
             CALL       PGM(HACTBSF3) PARM('*RTV' &ICGROUP &JRNRCV +
                          &JRNRCVL &JRNSEQ &JRNDTS &RTNCDE)

             GOTO       CMDLBL(LOOP)

 ELOOP:      GOTO       CMDLBL(ENDPRC)

/*           Close open files and reclaim resources                  */
 ENDPRC:     RCLRSC     LVL(*CALLER)
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
