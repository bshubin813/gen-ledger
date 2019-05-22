/* ================================================================= */
/* Object:         HCRTLFDLT       *PGM CLP                          */
/*                 Deletes all HCRTLF logical files in QTEMP         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20050429 FK  Initial delivery                                     */
/* 20070502 FK  Only create user space if not existing yet           */
/* ================================================================= */
             PGM        PARM(&LFNAM &JOBS)

/*           Declare parameter variables                             */
             DCL        VAR(&LFNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBS) TYPE(*CHAR) LEN(4)

/*           Declare constants used for this program                  */
             DCL        VAR(&#USRSPC) TYPE(*CHAR) LEN(20) +
                          VALUE('HCRTLFDLT QTEMP')

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')


             DCL        VAR(&GENNAM) TYPE(*LGL) VALUE('0')
             DCL        VAR(&POS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&OBJQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&OBJ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TYPE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJATR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJTXT) TYPE(*CHAR) LEN(50)

             DCL        VAR(&USER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBTYP) TYPE(*CHAR) LEN(1)

             DCL        VAR(&LSTHDR) TYPE(*CHAR) LEN(140)
             DCL        VAR(&I) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&STRLST) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRENT) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&ENTSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&STRPOS@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&LSTENT) TYPE(*CHAR) LEN(200)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    USER(&USER) TYPE(&JOBTYP)

/*           If *INT specified --> only run if interactive           */
             IF         COND(&JOBS *EQ '*INT' *AND &JOBTYP *EQ '0') +
                          THEN(DO)
              GOTO       CMDLBL(END)
             ENDDO

/*           Must all LFs be deleted?                                */
             CHGVAR     VAR(&GENNAM) VALUE('0')
             IF         COND(&LFNAM *EQ '*ALL') THEN(DO)
              CHGVAR     VAR(&GENNAM) VALUE('1')
             ENDDO

/*           If not *ALL, retrieve object description                */
             IF         COND(*NOT &GENNAM) THEN(DO)
              CHGVAR     VAR(&OBJ) VALUE(&LFNAM)
              RTVOBJD    OBJ(QTEMP/&OBJ) OBJTYPE(*FILE) +
                          OBJATR(&OBJATR) TEXT(&OBJTXT)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(END)
              ENDDO
             ENDDO

/*           Reclaim resources to close files                        */
             RCLRSC     LVL(*CALLER)

/*           Process list of objects for generic objects             */
             IF         COND(&GENNAM) THEN(DO)
              CHKOBJ     OBJ(QTEMP/HCRTLFDLT) OBJTYPE(*USRSPC)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
/*             Create user space for objects                         */
               CHGVAR     VAR(&APIERR) VALUE(X'00000000')
               CALL       PGM(QUSCRTUS) PARM(&#USRSPC 'HCRTLFDLT' +
                          X'000003F8' ' ' '*ALL' 'HCRTLFDLT - List +
                          of LFs' '*YES' &APIERR)
               RCVMSG     MSGTYPE(*LAST)
              ENDDO
/*            Generate list of objects                               */
              CHGVAR     VAR(&OBJQ) VALUE('H*        QTEMP     ')
              CHGVAR     VAR(&TYPE) VALUE('*FILE')
              CHGVAR     VAR(&APIERR) VALUE(X'00080000')
              CALL       PGM(QUSLOBJ) PARM(&#USRSPC 'OBJL0200' &OBJQ +
                          &TYPE &APIERR)
/*            If the API returns an error --> skip                   */
              IF         COND(%BIN(&APIERR 3 2) *NE 0) THEN(GOTO +
                          CMDLBL(END))
/*            Retrieve user space header information                 */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&#USRSPC X'00000001' +
                          X'0000008C' &LSTHDR &APIERR)
              CHGVAR     VAR(&STRLST) VALUE(%BIN(&LSTHDR 125 4) + 1)
              CHGVAR     VAR(&NBRENT) VALUE(%BIN(&LSTHDR 133 4))
              CHGVAR     VAR(&ENTSIZ) VALUE(%BIN(&LSTHDR 137 4))
              CHGVAR     VAR(&ENTSIZ@) VALUE(%SST(&LSTHDR 137 4))
/*            No objects retrieved --> skip                          */
              IF         COND(&NBRENT *EQ 0) THEN(GOTO CMDLBL(END))
              CHGVAR     VAR(&I) VALUE(1)
             ENDDO

 LOOPOBJ:    IF         COND(&GENNAM *AND &I *LE &NBRENT) THEN(DO)
/*            Retrieve entry                                         */
              CHGVAR     VAR(&STRPOS) VALUE(&STRLST + ((&I - 1) * +
                          &ENTSIZ))
              CHGVAR     VAR(%BIN(&STRPOS@)) VALUE(&STRPOS)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&#USRSPC &STRPOS@ &ENTSIZ@ +
                          &LSTENT &APIERR)

/*            Extract variables                                      */
              CHGVAR     VAR(&OBJ) VALUE(%SST(&LSTENT 1 10))
              CHGVAR     VAR(&OBJATR) VALUE(%SST(&LSTENT 32 10))
              CHGVAR     VAR(&OBJTXT) VALUE(%SST(&LSTENT 42 50))
             ENDDO

/*           If not DMXtras LF, skip                                 */
             IF         COND(&OBJATR *NE 'LF' *OR %SST(&OBJTXT 1 3) +
                          *NE 'DMX') THEN(DO)
              GOTO       CMDLBL(NEXT)
             ENDDO

/*           First remove object lock                                */
             DLCOBJ     OBJ((QTEMP/&OBJ *FILE *SHRRD)) SCOPE(*JOB)
             MONMSG     MSGID(CPF0000)

/*           Now delete LF                                           */
             DLTF       FILE(QTEMP/&OBJ)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXT))
             RCVMSG     MSGTYPE(*LAST)

/*           If generic object --> loop                              */
 NEXT:       IF         COND(&GENNAM) THEN(DO)
              CHGVAR     VAR(&I) VALUE(&I + 1)
              IF         COND(&I *LE &NBRENT) THEN(GOTO CMDLBL(LOOPOBJ))
             ENDDO

/*           Clear all program messages                              */
             RMVMSG     PGMQ(*SAME) CLEAR(*ALL)
             MONMSG     MSGID(CPF0000)

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
