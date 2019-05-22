/* ================================================================= */
/* Object:         HDSPLIB         *PGM CLP                          */
/*                 Displays basic attributes for the library passed  */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20060102 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&LIB)

/*           Declare parameter variables                              */
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)

/*           Constants                                               */

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&RCVVAR) TYPE(*CHAR) LEN(1024)
             DCL        VAR(&ATRRTV) TYPE(*CHAR) LEN(256)

             DCL        VAR(&NBRRCD) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&POS) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&OFS) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&KEY) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&LEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&SIZ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&FLDVAL) TYPE(*CHAR) LEN(100)

             DCL        VAR(&MULT) TYPE(*DEC) LEN(9 0)
             DCL        VAR(&NBROBJ) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&LIBSIZ) TYPE(*DEC) LEN(15 0)
             DCL        VAR(&NBROBJ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LIBSIZ@) TYPE(*CHAR) LEN(4)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Check if library exists                                 */
             CHKOBJ     OBJ(QSYS/&LIB) OBJTYPE(*LIB)

/*           Specify which attributes to retrieve                    */
             CHGVAR     VAR(%BIN(&ATRRTV 1 4)) VALUE(2)
             CHGVAR     VAR(%BIN(&ATRRTV 5 4)) VALUE(6)
             CHGVAR     VAR(%BIN(&ATRRTV 9 4)) VALUE(7)
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QLIRLIBD) PARM(&RCVVAR X'00000400' &LIB +
                          &ATRRTV &APIERR)

             CHGVAR     VAR(&NBRRCD) VALUE(%BIN(&RCVVAR 9 4))
             CHGVAR     VAR(&I) VALUE(1)
             CHGVAR     VAR(&OFS) VALUE(17)
 LOOPKEY:    IF         COND(&I *LE &NBRRCD) THEN(DO)
              CHGVAR     VAR(&POS) VALUE(&OFS)
              CHGVAR     VAR(&LEN) VALUE(%BIN(&RCVVAR &POS 4))
              CHGVAR     VAR(&POS) VALUE(&OFS + 4)
              CHGVAR     VAR(&KEY) VALUE(%BIN(&RCVVAR &POS 4))
              CHGVAR     VAR(&POS) VALUE(&OFS + 8)
              CHGVAR     VAR(&SIZ) VALUE(%BIN(&RCVVAR &POS 4))
              CHGVAR     VAR(&POS) VALUE(&OFS + 12)
              CHGVAR     VAR(&FLDVAL) VALUE(%SST(&RCVVAR &POS &SIZ))

/*            Handle key value for library size                      */
              IF         COND(&KEY *EQ 6) THEN(DO)
               CHGVAR     VAR(&LIBSIZ) VALUE(%BIN(&FLDVAL 1 4))
               CHGVAR     VAR(&MULT) VALUE(%BIN(&FLDVAL 5 4))
               CHGVAR     VAR(&LIBSIZ) VALUE((&LIBSIZ / (1024 * 1024)) +
                          * &MULT)
              ENDDO
/*            Handle key value for number of objects                 */
              IF         COND(&KEY *EQ 7) THEN(CHGVAR VAR(&NBROBJ) +
                          VALUE(%BIN(&FLDVAL 1 4)))

/*            Read next entry                                        */
              CHGVAR     VAR(&OFS) VALUE(&OFS + &LEN)
              CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOPKEY)
             ENDDO

/*           Send message with objects/size                          */
             CHGVAR     VAR(%BIN(&NBROBJ@)) VALUE(&NBROBJ)
             CHGVAR     VAR(%BIN(&LIBSIZ@)) VALUE(&LIBSIZ)
             SNDPGMMSG  MSGID(DLI0001) MSGF(HAUMSG) MSGDTA(&LIB || +
                          &NBROBJ@ || &LIBSIZ@)
             GOTO       CMDLBL(END)

 TRIM1:      IF         COND(%SST(&NBROBJ@ 1 1) *EQ '0' *AND +
                          %SST(&NBROBJ@ 2 1) *NE ' ') THEN(DO)
/*            CHGVAR     VAR(&NBROBJ@) VALUE(%SST(&NBROBJ@ 2 6)) */
              GOTO       CMDLBL(TRIM1)
             ENDDO

             CHGVAR     VAR(&LIBSIZ@) VALUE(&LIBSIZ)
 TRIM2:      IF         COND(%SST(&LIBSIZ@ 1 1) *EQ '0' *AND +
                          %SST(&LIBSIZ@ 2 1) *NE ' ') THEN(DO)
/*            CHGVAR     VAR(&LIBSIZ@) VALUE(%SST(&LIBSIZ@ 2 23)) */
              GOTO       CMDLBL(TRIM2)
             ENDDO

             SNDPGMMSG  MSG('Library' *BCAT &LIB *BCAT 'has' *BCAT +
                          &NBROBJ@ *BCAT 'objects and a size of' +
                          *BCAT &LIBSIZ@ *BCAT 'MB.')

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
