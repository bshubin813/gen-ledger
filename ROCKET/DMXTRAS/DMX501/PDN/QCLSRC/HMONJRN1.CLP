/* ================================================================= */
/* Object:         HMONJRN1        *PGM CLP                          */
/*                 Retrieve replication lag and signal if too big.   */
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
/* 20031002 FK  Rebuild to allow *ADH and *HST measurement           */
/*              Multiple lag measurements, send, apply               */
/* ================================================================= */
             PGM        PARM(&MSMTYP &LAGFILEL &ALRMSGQQ &ALWLAG +
                          &ALWSNDLAG &ALWAPYLAG &PRGHST)

/*           Declare parameter variables                             */
             DCL        VAR(&MSMTYP) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LAGFILEL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ALRMSGQQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&ALWLAG) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&ALWSNDLAG) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&ALWAPYLAG) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&PRGHST) TYPE(*DEC) LEN(4 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&SYSNAM) TYPE(*CHAR) LEN(8)
             DCL        VAR(&STRDTS) TYPE(*CHAR) LEN(26)

             DCL        VAR(&PRGHST@) TYPE(*CHAR) LEN(4)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVNETA    SYSNAME(&SYSNAM)

/*           Make sure proper files are used                         */
             OVRDBF     FILE(HJRNLAG) TOFILE(&LAGFILEL/HJRNLAG)
             OVRDBF     FILE(HJRNLAGDJ) TOFILE(&LAGFILEL/HJRNLAGDJ)

/*           Call program to retrieve lags ad-hoc                    */
             IF         COND(&MSMTYP *EQ '*ADH') THEN(DO)
              CALL       PGM(HMONJRN1A) PARM(&SYSNAM &STRDTS)
             ENDDO

/*           Call program to retrieve lags from history              */
             IF         COND(&MSMTYP *EQ '*HST') THEN(DO)
              CALL       PGM(HMONJRN1B) PARM(&SYSNAM &STRDTS)
             ENDDO

/*           Send messages if lag too big                            */
             CALL       PGM(HMONJRN3) PARM(&SYSNAM &MSMTYP &STRDTS +
                          &ALRMSGQQ &ALWLAG &ALWSNDLAG &ALWAPYLAG)

/*           If history must be purged --> do so                     */
             IF         COND(&PRGHST *NE 0) THEN(DO)
              CHGVAR     VAR(%BIN(&PRGHST@)) VALUE(&PRGHST)
              SNDPGMMSG  MSGID(MJL0007) MSGF(HAUMSG) MSGDTA(&PRGHST@) +
                          TOPGMQ(*SAME)
              CALL       PGM(HMONJRN4) PARM(&SYSNAM &MSMTYP &PRGHST)
             ENDDO

/*           Delete overrides                                        */
             DLTOVR     FILE(HJRNLAG HJRNLAGDJ)
             MONMSG     MSGID(CPF0000)

             RCLRSC

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
