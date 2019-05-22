/* ================================================================= */
/* Object:         OBJCOUNTS       *PGM CLP                          */
/*                 Count objects in libraries on system              */
/*                                                                   */
/* Synopsis:       See command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19980204 MW  Initial delivery                                     */
/* 20070803 FK  Fixed parameter issue                                */
/* 20071104 FK  Library was ignored when running interactively       */
/* ================================================================= */
             PGM        PARM(&LIB)

/*           Declare parameter variables                             */
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&TYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(10)

/*           Initialisation                                          */
             RTVJOBA    TYPE(&TYPE)

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Retrieve system name                                    */
             HRTVNETA   SYSNAME(&SYSNAM)

/*           Utilities library must be in library list for SBMJOB    */
             ADDLIBLE   LIB(&UTLLIB)
             MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))

/*           If executed interactively --> submit to batch           */
             IF         COND(&TYPE *EQ '1') THEN(DO)
              SBMJOB     CMD(OBJCOUNTS LIB(&LIB)) JOB(OBJCOUNTS) +
                          JOBD(HAUTILS) HOLD(*YES)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

             DSPOBJD    OBJ(&LIB/*ALL) OBJTYPE(*ALL) DETAIL(*BASIC) +
                          OUTPUT(*OUTFILE) OUTFILE(&UTLLIB/OBJCOUNTSB) +
                          OUTMBR(*FIRST *REPLACE)
             IF         COND(&LIB *EQ '*ALLUSR') THEN(DO)
             CHGVAR     VAR(&LIB) VALUE('*ALL')
             ENDDO
             DSPOBJD    OBJ(QSYS/&LIB) OBJTYPE(*LIB) DETAIL(*BASIC) +
                          OUTPUT(*OUTFILE) OUTFILE(&UTLLIB/OBJCOUNTSA) +
                          OUTMBR(*FIRST *REPLACE)

/* Produce Report */
             CALL       PGM(OBJCOUNTS2) PARM(&SYSNAM)

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
