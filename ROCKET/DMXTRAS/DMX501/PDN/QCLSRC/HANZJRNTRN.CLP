/* ================================================================= */
/* Object:         HANZJRNTRN      *PGM CLP                          */
/*                 Analyse transactions in ANZJRNPF (summarise       */
/*                 transaction types                                 */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020508 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&ANALFILE &ANALFLIB)

/*           Declare parameter variables                              */
             DCL        VAR(&ANALFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ANALFLIB) TYPE(*CHAR) LEN(10)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&MSG) TYPE(*CHAR) LEN(80)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */

/* Verify existence of analysis file                                 */

             CHKOBJ     OBJ(&ANALFLIB/&ANALFILE) OBJTYPE(*FILE) +
                          MBR(*FIRST)
             MONMSG     MSGID(CPF9801) EXEC(DO)
             CHGVAR     VAR(&MSG) VALUE('Analysis file' *BCAT +
                          &ANALFLIB *TCAT '/' *CAT &ANALFILE *TCAT +
                          ' does not exist')
             SNDPGMMSG  MSGID(CPF9898) MSGF(QCPFMSG) MSGDTA(&MSG) +
                          MSGTYPE(*ESCAPE)
             GOTO       CMDLBL(END)
             ENDDO

             RUNQRY     QRY(ANZJRNTRN1) QRYFILE((&ANALFLIB/&ANALFILE))
             RUNQRY     QRY(ANZJRNTRN2) QRYFILE((&ANALFLIB/&ANALFILE))

 ELOOP:      GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */
/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG' +
                          X'00000001' '*' X'00000001' &APIERR)

/*           Resend last escape message                              */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHRSNEM) PARM(' ' &APIERR)

 END:        ENDPGM
