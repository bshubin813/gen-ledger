/* ================================================================= */
/* Object:         HACTBSF2        *PGM CLP                          */
/*                 Activate IFS object according to specifications   */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20051110 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&TGTNAM &GRPNAM &ENTTYP &ACTTZC &AUDTCO +
                          &ACTTCO &IFSOBJ)

/*           Declare parameter variables                              */
             DCL        VAR(&TGTNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GRPNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ENTTYP) TYPE(*CHAR) LEN(2)
             DCL        VAR(&ACTTZC) TYPE(*CHAR) LEN(4)
             DCL        VAR(&AUDTCO) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ACTTCO) TYPE(*CHAR) LEN(4)
             DCL        VAR(&IFSOBJ) TYPE(*CHAR) LEN(5002)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&IFSLEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&IFSOBJ@) TYPE(*CHAR) LEN(5000)
             DCL        VAR(&IFSOBJS) TYPE(*CHAR) LEN(30)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Change auditing for BSF object                          */
             IF         COND(&ENTTYP *EQ 'CO' *AND &AUDTCO *EQ +
                          '*YES') THEN(DO)
              CHGAUD     OBJ(&IFSOBJ@) OBJAUD(*CHANGE)
             ENDDO

/*           Activate BSF object                                     */
             IF         COND((&ENTTYP *EQ 'ZC' *AND &ACTTZC *EQ +
                          '*YES') *OR (&ENTTYP *EQ 'CO' *AND +
                          &ACTTCO *EQ '*YES')) THEN(DO)
              CHGVAR     VAR(&IFSLEN) VALUE(%BIN(&IFSOBJ 1 2))
              CHGVAR     VAR(&IFSOBJ@) VALUE(%SST(&IFSOBJ 3 &IFSLEN))
              ACTHABSF   TARGET(&TGTNAM) GROUP(&GRPNAM) PATH(&IFSOBJ@)
/*            Indicate which object was activated                    */
              CHGVAR     VAR(&IFSOBJS) VALUE(&IFSOBJ@)
              IF         COND(&IFSLEN *GT 30) THEN(CHGVAR +
                          VAR(%SST(&IFSOBJS 28 3)) VALUE('...'))
              SNDPGMMSG  MSGID(ABS0004) MSGF(HAUMSG) MSGDTA(&GRPNAM +
                          || &IFSOBJS || %SST(&IFSOBJ 1 2000)) +
                          TOPGMQ(*SAME)
             ENDDO

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all error messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
