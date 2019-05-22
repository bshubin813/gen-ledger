/* ================================================================= */
/* Object:         ANZJRNDLT       *PGM CLP                          */
/*                 Analyses the contents of the specified journal(s) */
/*                 and outputs to files.                             */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20060126 FK  Rebuild without message logging                      */
/* 20111217 FK  Remove HA suite                                      */
/* ================================================================= */
             PGM        PARM(&JRNQ &DLTRCV &STRRCVQ &ENDRCVQ &STRDTE +
                          &ENDDTE &CLRANZ &SBMHLD)

/*           Declare parameter variables                              */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DLTRCV) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRRCVQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ENDRCVQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&STRDTE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ENDDTE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&CLRANZ) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SBMHLD) TYPE(*CHAR) LEN(4)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JRNQNME) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNQLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STRRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&STRRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ENDRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ENDRCVL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&HALIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&ISODTE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&JRNNAMESV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNLIBSV) TYPE(*CHAR) LEN(10)

             DCL        VAR(&DESC)  TYPE(*CHAR) LEN(50)

/*           Declare file                                            */
             DCLF       FILE(HUDGTJL)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)

/*           Split qualifiers                                        */
             CHGVAR     VAR(&JRNQNME) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNQLIB) VALUE(%SST(&JRNQ 11 10))
             CHGVAR     VAR(&STRRCV) VALUE(%SST(&STRRCVQ 1 10))
             CHGVAR     VAR(&STRRCVL) VALUE(%SST(&STRRCVQ 11 10))
             IF         COND(&STRRCVL *EQ ' ') THEN(CHGVAR +
                          VAR(&STRRCVL) VALUE('*N'))
             CHGVAR     VAR(&ENDRCV) VALUE(%SST(&ENDRCVQ 1 10))
             CHGVAR     VAR(&ENDRCVL) VALUE(%SST(&ENDRCVQ 11 10))
             IF         COND(&ENDRCVL *EQ ' ') THEN(CHGVAR +
                          VAR(&ENDRCVL) VALUE('*N'))

/*           If not special value, check existence of journal        */
             IF         COND(%SST(&JRNQNME 1 1) *NE '*') THEN(CHKOBJ +
                          OBJ(&JRNQLIB/&JRNQNME) OBJTYPE(*JRN))

/*           If not special value, check existence of receivers      */
             IF         COND(%SST(&STRRCV 1 1) *NE '*') THEN(CHKOBJ +
                          OBJ(&STRRCVL/&STRRCV) OBJTYPE(*JRNRCV))
             IF         COND(%SST(&ENDRCV 1 1) *NE '*') THEN(CHKOBJ +
                          OBJ(&ENDRCVL/&ENDRCV) OBJTYPE(*JRNRCV))

/*           If not special value --> check dates                    */
             IF         COND(&STRDTE *NE '*START') THEN(CVTDAT +
                          DATE(&STRDTE) TOVAR(&ISODTE) +
                          FROMFMT(*YYMD) TOFMT(*ISO))
             IF         COND(&ENDDTE *NE '*END') THEN(CVTDAT +
                          DATE(&ENDDTE) TOVAR(&ISODTE) +
                          FROMFMT(*YYMD) TOFMT(*ISO))

/*           Utilities and HA library info                           */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)

/*           If *ALLIC, iCluster must exist in library list          */
             IF         COND(&JRNQNME *EQ '*ALLIC' *AND &ICLIB *EQ +
                          '*NONE') THEN(SNDPGMMSG MSGID(DMX0012) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Pre-fill variables in case file is not read             */
             CHGVAR     VAR(&JRNNAME) VALUE(&JRNQNME)
             CHGVAR     VAR(&JRNLIB) VALUE(&JRNQLIB)

/*           Clear analysis file if requested                        */
             IF         COND(&CLRANZ *EQ '*YES') THEN(CLRPFM +
                          FILE(&UTLLIB/ANZJRNPF))

/*           If journal specified and not already in batch --> submit*/
             IF         COND(&JOBTYPE *EQ '1' *AND %SST(&JRNQNME 1 +
                          1) *NE '*') THEN(DO)
              CHGVAR     VAR(&JOB) VALUE('ANZ' || &JRNNAME)
              SBMJOB     CMD(ANZJRNDLT JOURNAL(&JRNLIB/&JRNNAME) +
                          DELETEREC(&DLTRCV) +
                          STRJRNRCV(&STRRCVL/&STRRCV) +
                          ENDJRNRCV(&ENDRCVL/&ENDRCV) +
                          STRDAT(&STRDTE) ENDDAT(&ENDDTE) +
                          CLRANZ(*NO) SBMHLD(*NO)) JOB(&JOB) +
                          JOBD(HAUTILS) HOLD(&SBMHLD)
              GOTO       CMDLBL(EPROCESS)
             ENDDO

/*           Create temporary file if *ALLIC                         */
             IF         COND(%SST(&JRNQNME 1 1) *EQ '*') THEN(DO)
              CALL       PGM(HCRTLF) PARM('HUDGTJL')
              OVRDBF     FILE(HUDGTJL) TOFILE(QTEMP/HUDGTJL)
             ENDDO

/*           Process all product journals or just individual         */
 LOOP:       IF         COND(%SST(&JRNQNME 1 1) *EQ '*') THEN(DO)
              RCVF
              MONMSG     MSGID(CPF0864) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(EPROCESS)
              ENDDO
/*            If journal doesn't exist --> skip                      */
              CHKOBJ     OBJ(&JRNLIB/&JRNNAME) OBJTYPE(*JRN)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))
             ENDDO

/*           If journal different from previous --> process          */
             IF         COND(&JRNNAME *NE &JRNNAMESV *OR &JRNLIB *NE +
                          &JRNLIBSV) THEN(DO)
/*            Submit a job per journal if special value              */
              IF         COND(%SST(&JRNQNME 1 1) *EQ '*') THEN(DO)
               CHGVAR     VAR(&JOB) VALUE('ANZ' || &JRNNAME)
               SBMJOB     CMD(ANZJRNDLT JOURNAL(&JRNLIB/&JRNNAME) +
                          DELETEREC(&DLTRCV) +
                          STRJRNRCV(&STRRCVL/&STRRCV) +
                          ENDJRNRCV(&ENDRCVL/&ENDRCV) +
                          STRDAT(&STRDTE) ENDDAT(&ENDDTE) +
                          CLRANZ(*NO) SBMHLD(*NO)) JOB(&JOB) +
                          JOBD(HAUTILS) HOLD(&SBMHLD)
               GOTO       CMDLBL(LOOP)
              ENDDO

/*            Call program that processes journal                    */
              CALL       PGM(ANZJRN01) PARM(&JRNNAME &JRNLIB &DLTRCV +
                          &STRRCVQ &ENDRCVQ &STRDTE &ENDDTE)

             ENDDO

             CHGVAR     VAR(&JRNNAMESV) VALUE(&JRNNAME)
             CHGVAR     VAR(&JRNLIBSV) VALUE(&JRNLIB)

/*           If product journals --> process next entry in HADGT     */
             IF         COND(%SST(&JRNQNME 1 1) *EQ '*') THEN(GOTO +
                          CMDLBL(LOOP))

 ELOOP:      SNDPGMMSG  MSGID(AJD0001) MSGF(HAUMSG) TOPGMQ(*SAME)
             HPRTANZ    RECALC(*YES)

 EPROCESS:   CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     ' +
                          X'00000001' '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
