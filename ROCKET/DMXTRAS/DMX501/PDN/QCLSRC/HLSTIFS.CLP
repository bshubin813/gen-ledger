/* ================================================================= */
/* Object:         HLSTIFS         *PGM CLP                          */
/*                 Lists the contents of the specified IFS folder.   */
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
/* 20070712 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&P_PATH &OUTFILEQ &OPTION)

/*           Declare parameter variables                              */
             DCL        VAR(&P_PATH) TYPE(*CHAR) LEN(1002)
             DCL        VAR(&OUTFILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&OPTION) TYPE(*CHAR) LEN(8)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&PATH) TYPE(*CHAR) LEN(1002)
             DCL        VAR(&PATHLEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&POS) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILEL) TYPE(*CHAR) LEN(10)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&PATHLEN) VALUE(%BIN(&P_PATH 1 2))
             CHGVAR     VAR(&PATH) VALUE(%SST(&P_PATH 3 &PATHLEN))
             CHGVAR     VAR(&POS) VALUE(&PATHLEN + 1)
             CHGVAR     VAR(%SST(&PATH &POS 1)) VALUE(X'00')

/*           Split qualifiers                                        */
             CHGVAR     VAR(&OUTFILE) VALUE(%SST(&OUTFILEQ 1 10))
             CHGVAR     VAR(&OUTFILEL) VALUE(%SST(&OUTFILEQ 11 10))

/*           Retrieve utilities library                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Output library cannot be utilities library              */
             IF         COND(&OUTFILEL *EQ &UTLLIB) THEN(SNDPGMMSG +
                          MSGID(LIF0002) MSGF(HAUMSG) +
                          MSGDTA(&OUTFILEL) MSGTYPE(*ESCAPE))

/*           Delete output file if *REPLACE                          */
             IF         COND(&OPTION *EQ '*REPLACE') THEN(DO)
              DLTF       FILE(&OUTFILEL/&OUTFILE)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             ENDDO
/*           Create output file if it doesn't exist                  */
             CHKOBJ     OBJ(&OUTFILEL/&OUTFILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDUPOBJ  OBJ(HLSTIFS) FROMLIB(&UTLLIB) OBJTYPE(*FILE) +
                          TOLIB(&OUTFILEL) NEWOBJ(&OUTFILE) DATA(*NO)
             ENDDO

/*           Send message "Retrieving IFS objects ..."               */
             SNDPGMMSG  MSGID(LIF0001) MSGF(HAUMSG) MSGDTA(&P_PATH) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)

/*           List IFS objects to specified output file               */
             OVRDBF     FILE(HLSTIFS) TOFILE(&OUTFILEL/&OUTFILE)
             CALL       PGM(HLSTIFS1) PARM(&PATH '\S')
             DLTOVR     FILE(HLSTIFS)

/*           Send message "IFS objects listed to output file."       */
             SNDPGMMSG  MSGID(LIF0003) MSGF(HAUMSG) MSGDTA(&OUTFILEQ +
                          || &P_PATH) MSGTYPE(*COMP)

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG and *ESCAPE messages to previous queue   */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
