/* ================================================================= */
/* Object:         HSETAUT         *PGM CLP                          */
/*                 Command processing program for HSETAUT.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010101 FK  Initial delivery                                     */
/* 20010227 FK  Act on target name instead of file name              */
/* 20010921 FK  Allow for processing differences only                */
/* 20011221 FK  Only restart apply if stopped by this process        */
/* 20020923 FK  Do not check for role anymore                        */
/* 20021126 FK  Authority differences are all in 1 file now          */
/*              Use HRTVPRDLIB to retrieve HA Suite library          */
/* 20030710 FK  Change TARGET/GROUP back to TGTNAM/GRPNAM            */
/* 20040629 FK  Wait a maximum of 1 hour to end apply jobs           */
/* 20050518 FK  IFS authorities                                      */
/* 20051006 FK  Job always submitted under HASUITE even if iC        */
/* 20070504 FK  Allow for different iCluster user                    */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &ACTION +
                          &IFSAUT &SYNID &TGTLIB &SUSAPY)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&IFSAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SYNID) TYPE(*CHAR) LEN(5)
             DCL        VAR(&TGTLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SUSAPY) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)

             DCL        VAR(&OBJSV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIBSV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TYPESV) TYPE(*CHAR) LEN(8)

             DCL        VAR(&SBMUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICUSER) TYPE(*CHAR) LEN(10)

             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

             DCL        VAR(&TGTSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&APYEND) TYPE(*LGL) VALUE('0')
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)

             DCL        VAR(&OWNER) TYPE(*CHAR) LEN(10)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEAUT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEIFS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURRCDAUT) TYPE(*DEC) LEN(10 0)
             DCL        VAR(&CURRCDIFS) TYPE(*DEC) LEN(10 0)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000 SAU0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Determine product that sync check runs for              */
             CHGVAR     VAR(&PRD) VALUE('*IC')

/*           Determine synchronisation ID                            */
             IF         COND(&SYNID *EQ '*TGT' *AND &PRD *EQ '*IC' +
                          *AND &ICGROUP *EQ '*ALL') THEN(CHGVAR +
                          VAR(&SYNID) VALUE('CLUST'))
             IF         COND(&SYNID *EQ '*TGT' *AND &PRD *EQ '*IC' +
                          *AND &ICGROUP *NE '*ALL') THEN(CHGVAR +
                          VAR(&SYNID) VALUE(%SST(&ICGROUP 1 5)))

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)

/*           Retrieve HA Suite/iCluster product libraries            */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB) +
                          ICUSER(&ICUSER)

/*           iCluster must be in library list                        */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           If only differences processed --> check if necessary    */
             IF         COND(&ACTION *EQ '*DIF') THEN(DO)
              CHGVAR     VAR(&FILEAUT) VALUE('HS' |< &SYNID |< 'AUT')
              RTVMBRD    FILE(&UTLLIB/&FILEAUT) NBRCURRCD(&CURRCDAUT)
              MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(SAU0001) +
                          MSGF(HAUMSG) MSGDTA(&FILEAUT || '*DIF') +
                          MSGTYPE(*DIAG))
              IF         COND(&IFSAUT *EQ '*YES') THEN(DO)
               CHGVAR     VAR(&FILEIFS) VALUE('HS' |< &SYNID |< 'IFA')
               RTVMBRD    FILE(&UTLLIB/&FILEIFS) NBRCURRCD(&CURRCDIFS)
               MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(SAU0001) +
                          MSGF(HAUMSG) MSGDTA(&FILEIFS || '*DIF') +
                          MSGTYPE(*DIAG))
              ENDDO
/*            If no records to process --> complete with message     */
              IF         COND(&CURRCDAUT *EQ 0 *AND (&IFSAUT *EQ +
                          '*YES' *AND &CURRCDIFS *EQ 0)) THEN(DO)
               SNDPGMMSG  MSGID(SAU0005) MSGF(HAUMSG) MSGDTA(&ICGROUP) +
                          MSGTYPE(*COMP)
               GOTO       CMDLBL(END)
              ENDDO
             ENDDO

/*           Submit job to batch if executed interactively           */
             IF         COND(&JOBTYPE *EQ '1') THEN(DO)
              IF         COND(&PRD *EQ '*HA') THEN(CHGVAR +
                          VAR(&SBMUSR) VALUE('HASUITE'))
              IF         COND(&PRD *EQ '*IC') THEN(CHGVAR +
                          VAR(&SBMUSR) VALUE(&ICUSER))
              SBMJOB     CMD(HSETAUT ICGROUP(&ICGROUP) +
                          ACTION(&ACTION) AUTIFS(&IFSAUT) +
                          SYNID(&SYNID) TGTLIB(&TGTLIB) +
                          SUSAPY(&SUSAPY)) JOB(HSETAUT) +
                          JOBD(HAUTILS) USER(&SBMUSR) INLLIBL(*JOBD)
/*            Move *COMP message to previous queue                   */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP     ' +
                          X'00000001' '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Suspend apply jobs if any library objects to be changed  */
             IF         COND(&ACTION *NE '*DIF' *OR &CURRCDAUT *NE +
                          0) THEN(DO)
              HRTVSTS    ICGROUP(&ICGROUP) PRCTYP(*APY) STATUS(&TGTSTS)
              IF         COND(&SUSAPY *EQ '*YES' *AND &TGTSTS *EQ +
                          '*ACTIVE') THEN(DO)
/*             Now wait until apply jobs have stopped                 */
               SNDPGMMSG  MSGID(SAU0004) MSGF(HAUMSG) MSGDTA(&ICGROUP) +
                          TOPGMQ(*SAME (* *NONE *NONE))
               HENDAPY    ICGROUP(&ICGROUP) WAIT(*YES) MAXWAIT(60)
               CHGVAR     VAR(&APYEND) VALUE('1')
              ENDDO
             ENDDO

/*           Now call proper program, dependent on action            */
             IF         COND(&ACTION *EQ '*DIF' *AND &CURRCDAUT *GT +
                          0) THEN(DO)
/*            Call program to process authority differences          */
             CALL       PGM(HSETAUTAD) PARM(&ICGROUP &FILEAUT +
                          &TGTLIB &UTLLIB)
             ENDDO
             IF         COND(&ACTION *EQ '*DIF' *AND &IFSAUT *EQ +
                          '*YES' *AND &CURRCDIFS *GT 0) THEN(DO)
/*            Call program to process authority differences          */
              OVRDBF     FILE(HCHKSYNIFA) TOFILE(&UTLLIB/&FILEIFS)
              CALL       PGM(HSETAUTAI) PARM(&ICGROUP)
              DLTOVR     FILE(HCHKSYNIFA)
             ENDDO
             IF         COND(&ACTION *NE '*DIF') THEN(DO)
/*            Call program to *GRT/*RVK all authorities              */
              CALL       PGM(HSETAUTA) PARM(&ICGROUP &SYNID &TGTLIB +
                          &ACTION &UTLLIB)
             ENDDO

/*           Optionally, activate apply jobs again                   */
             IF         COND(&SUSAPY *EQ '*YES' *AND &APYEND) +
                          THEN(HSTRAPY ICGROUP(&ICGROUP))

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
