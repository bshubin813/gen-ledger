/* ================================================================= */
/* Object:         HSUSACT3        *PGM CLP                          */
/*                 Suspend or activate (a set of) file(s) for a      */
/*                 target and group.                                 */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020626 FK  Initial delivery                                     */
/* 20030605 FK  Enable for iCluster                                  */
/* 20111222 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &OBJNAM &OBJLIB &ACTION &RFSH +
                          &ICLIB &RTNCDE)

/*           Declare parameter variables                             */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RFSH) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&MBFILESV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBLIBSV) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */
             DCLF       FILE(HSUSACTF)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Display the file descriptions to an output file         */
             DSPFD      FILE(&OBJLIB/&OBJNAM) TYPE(*MBR) +
                          OUTPUT(*OUTFILE) FILEATR(*PF) +
                          OUTFILE(QTEMP/HSUSACTTMP)
             CPYF       FROMFILE(QTEMP/HSUSACTTMP) +
                          TOFILE(QTEMP/HSUSACTF) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
             OVRDBF     FILE(HSUSACTF) TOFILE(QTEMP/HSUSACTF)

/*           Read all entries and process                            */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

             IF         COND(&MBFILE *EQ &MBFILESV *AND &MBLIB *EQ +
                          &MBLIBSV) THEN(GOTO CMDLBL(LOOP))

/*           Suspend or activate the file                            */
             CALL       PGM(HSUSACT2) PARM(&ICGROUP &MBFILE &MBLIB +
                          &ACTION &RFSH &ICLIB &RTNCDE)
             CHGVAR     VAR(&MBLIBSV) VALUE(&MBLIB)
             CHGVAR     VAR(&MBFILESV) VALUE(&MBFILE)

             GOTO       CMDLBL(LOOP)

 ELOOP:      GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
