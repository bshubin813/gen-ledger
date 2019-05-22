/* ================================================================= */
/* Object:         HRTVFILANZ      *PGM CLP                          */
/*                 Command processing program for HRTVFILANZ         */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020507 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&FILEQ &BATCH)

/*           Declare parameter variables                             */
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILEL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE)

/*           Split qualifier variables                               */
             CHGVAR     VAR(&FILE) VALUE(%SST(&FILEQ 1 10))
             CHGVAR     VAR(&FILEL) VALUE(%SST(&FILEQ 11 10))

/*           Check library existence                                 */
             CHKOBJ     OBJ(&FILEL) OBJTYPE(*LIB)

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)
             ADDLIBLE   LIB(&UTLLIB)
             MONMSG     MSGID(CPF2103) EXEC(RCVMSG MSGTYPE(*LAST))

/*           If submit to batch --> do so                            */
             IF         COND(&BATCH *EQ '*YES' *AND &JOBTYPE *EQ +
                          '1') THEN(DO)
              SBMJOB     CMD(HRTVFILANZ FILE(&FILEL/&FILE) +
                          BATCH(*NO)) JOB(&FILEL) JOBD(HAUTILS)
/*            Move *COMP message to previous queue                   */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP     ' +
                          X'00000001' '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Call program that retrieves file attributes             */
             CALL       PGM(ANZFILESA) PARM(&FILE &FILEL)

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
