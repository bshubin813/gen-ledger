/* ================================================================= */
/* Object:         HLSTJRN         *PGM CLP                          */
/*                 Builds list of journals & receivers based on      */
/*                 passed parameters                                 */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20070422 FK  Initial delivery                                     */
/* 20111217 FK  Remove HA and CDC                                    */
/* ================================================================= */
             PGM        PARM(&JRNQ &CHKIC &LSTRCV &OUTFILEQ)

/*           Declare parameter variables                             */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&CHKIC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LSTRCV) TYPE(*CHAR) LEN(4)
             DCL        VAR(&OUTFILEQ) TYPE(*CHAR) LEN(19)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVFILE) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CURLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    CURLIB(&CURLIB)
             IF         COND(&CURLIB *EQ '*NONE') THEN(CHGVAR +
                          VAR(&CURLIB) VALUE('*CRTDFT'))

/*           Split qualifiers                                        */
             CHGVAR     VAR(&OUTFILE) VALUE(%SST(&OUTFILEQ 1 9))
             CHGVAR     VAR(&OUTFILEL) VALUE(%SST(&OUTFILEQ 10 10))
             CHGVAR     VAR(&JRN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB)
             IF         COND(&JRNL *EQ '*PRD') THEN(DO)
/*            At least one of the products must be checked           */
              IF         COND(&CHKIC *EQ '*NO') THEN(SNDPGMMSG +
                          MSGID(LJR0004) MSGF(HAUMSG) MSGTYPE(*ESCAPE))
/*            If CHKIC(*YES) --> iCluster library must be known      */
              IF         COND(&CHKIC *EQ '*YES' *AND &ICLIB *EQ +
                          '*NONE') THEN(SNDPGMMSG MSGID(DMX0012) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))
             ENDDO

/*           Prepare files in the output library                     */
             CHGVAR     VAR(&JRNFILE) VALUE(&OUTFILE)
             CHKOBJ     OBJ(&OUTFILEL/&JRNFILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDUPOBJ  OBJ(HLSTJRN) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(&OUTFILEL) NEWOBJ(&JRNFILE) DATA(*NO)
             ENDDO
             CLRPFM     FILE(&OUTFILEL/&JRNFILE)
             OVRDBF     FILE(HLSTJRN) TOFILE(&OUTFILEL/&JRNFILE)

             IF         COND(&LSTRCV *EQ '*YES') THEN(DO)
              CHGVAR     VAR(&RCVFILE) VALUE(&OUTFILE |< 'R')
              CHKOBJ     OBJ(&OUTFILEL/&RCVFILE) OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CRTDUPOBJ  OBJ(HLSTJRNR) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&OUTFILEL) +
                          NEWOBJ(&RCVFILE) DATA(*NO)
              ENDDO
              CLRPFM     FILE(&OUTFILEL/&RCVFILE)
              OVRDBF     FILE(HLSTJRNR) TOFILE(&OUTFILEL/&RCVFILE)
             ENDDO

/*           Now, list journals for HA Suite or iCluster             */
             IF         COND(&JRNL *EQ '*PRD' *AND &CHKIC *EQ +
                          '*YES') THEN(DO)
/*            Build LFs for iCluster                                 */
              CALL       PGM(HCRTLF) PARM(HUDGTJL)
              CALL       PGM(HCRTLF) PARM(HUDSJJL)
              CALL       PGM(HCRTLF) PARM(HUPIDTGJR)
              OVRDBF     FILE(HUDGTJL) TOFILE(QTEMP/HUDGTJL)
              OVRDBF     FILE(HUDSJJL) TOFILE(QTEMP/HUDSJJL)
              OVRDBF     FILE(HUPIDTGJR) TOFILE(QTEMP/HUPIDTGJR)
/*            Call program that builds HLSTJRN for iCluster          */
              CALL       PGM(HLSTJRN1) PARM(&JRN &JRNL &LSTRCV '*IC')
             ENDDO

/*           Display object descriptions for journals                */
             IF         COND(&JRNL *NE '*PRD') THEN(DO)
              CALL       PGM(HLSTJRN1) PARM(&JRN &JRNL &LSTRCV '*OBJ')
             ENDDO

/*           Return current library                                  */
             CHGCURLIB  CURLIB(&CURLIB)

/*           Copy back any diagnostic messages                       */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
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
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' X'00000001' +
                          '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
