/* ================================================================= */
/* Object:         HAAANEW1        *PGM CLP                          */
/*                 Deletes (generic) object(s) as specified by the   */
/*                 passed parameters.                                */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20021230 FK  Initial delivery                                     */
/* 20030207 FK  Only skip deletion of objects compiled from CUSLIB   */
/* 20050123 FK  Also delete dependent logical files                  */
/* 20050124 FK  Only send completion message if generic object       */
/* 20050302 FK  Don't delete HAAANEW data area                       */
/* ================================================================= */
             PGM        PARM(&P_LIB &P_OBJ &P_TYPE)

/*           Declare parameter variables                             */
             DCL        VAR(&P_LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_OBJ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&P_TYPE) TYPE(*CHAR) LEN(8)

/*           Declare constants used for this program                  */
             DCL        VAR(&#OBJSPC) TYPE(*CHAR) LEN(20) +
                          VALUE('HAAANEW1O QTEMP')
             DCL        VAR(&#DBRSPC) TYPE(*CHAR) LEN(20) +
                          VALUE('HAAANEW1D QTEMP')

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(8)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&OBJATR) TYPE(*CHAR) LEN(10)

             DCL        VAR(&GENNAM) TYPE(*LGL) VALUE('0')
             DCL        VAR(&POS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&OBJQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&OBJ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TYPE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&USER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBTYP) TYPE(*CHAR) LEN(1)

             DCL        VAR(&DBRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DBRFL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&OBJSTR) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBROBJ) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&OBJSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&OBJL0400) TYPE(*CHAR) LEN(400)

             DCL        VAR(&DBRSTR) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRDBR) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&DBRSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&DBRL0100) TYPE(*CHAR) LEN(400)

             DCL        VAR(&LSTHDR) TYPE(*CHAR) LEN(140)
             DCL        VAR(&STRPOS@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&I) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&J) TYPE(*DEC) LEN(5 0)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    USER(&USER) TYPE(&JOBTYP)
             CHGVAR     VAR(&OBJ) VALUE(&P_OBJ)
             CHGVAR     VAR(&LIB) VALUE(&P_LIB)
             CHGVAR     VAR(&TYPE) VALUE(&P_TYPE)

/*           Is the object name generic?                             */
             CHGVAR     VAR(&GENNAM) VALUE('0')
             CALL       PGM(QCLSCAN) PARM(&P_OBJ X'010F' X'001F' '*' +
                          X'001F' '0' '0' ' ' &POS)
             IF         COND(&POS *NE 0 *OR &TYPE *EQ '*ALL') +
                          THEN(CHGVAR VAR(&GENNAM) VALUE('1'))

/*           Check if non-generic object exists                      */
             IF         COND(*NOT &GENNAM) THEN(DO)
              RTVOBJD    OBJ(&P_LIB/&P_OBJ) OBJTYPE(&P_TYPE) +
                          OBJATR(&OBJATR)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(NEXTOBJ)
              ENDDO
             ENDDO

/*           Process list of objects for generic objects             */
             IF         COND(&GENNAM) THEN(DO)
/*            Create user space for objects                          */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSCRTUS) PARM(&#OBJSPC 'HAAANEW1' +
                          X'000003F8' ' ' '*ALL' 'HAAANEW1 - List +
                          of objects (generic)' '*YES' &APIERR)
/*            Generate list of objects                               */
              CHGVAR     VAR(&OBJQ) VALUE(&P_OBJ || &P_LIB)
              CHGVAR     VAR(&APIERR) VALUE(X'00080000')
              CALL       PGM(QUSLOBJ) PARM(&#OBJSPC 'OBJL0400' &OBJQ +
                          &P_TYPE &APIERR)
/*            If the API returns an error --> skip object            */
              IF         COND(%BIN(&APIERR 3 2) *NE 0) THEN(GOTO +
                          CMDLBL(NEXTOBJ))
/*            Retrieve user space header information                 */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&#OBJSPC X'00000001' +
                          X'0000008C' &LSTHDR &APIERR)
              CHGVAR     VAR(&OBJSTR) VALUE(%BIN(&LSTHDR 125 4) + 1)
              CHGVAR     VAR(&NBROBJ) VALUE(%BIN(&LSTHDR 133 4))
              CHGVAR     VAR(&OBJSIZ@) VALUE(%SST(&LSTHDR 137 4))
/*            No objects retrieved --> skip                          */
              IF         COND(&NBROBJ *EQ 0) THEN(GOTO CMDLBL(END))
              CHGVAR     VAR(&I) VALUE(1)
             ENDDO

 LOOPOBJ:    IF         COND(&GENNAM *AND &I *LE &NBROBJ) THEN(DO)
/*            Retrieve entry                                         */
              CHGVAR     VAR(%BIN(&STRPOS@)) VALUE(&OBJSTR + ((&I - +
                          1) * %BIN(&OBJSIZ@)))
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&#OBJSPC &STRPOS@ &OBJSIZ@ +
                          &OBJL0400 &APIERR)

/*            Extract variables                                      */
              CHGVAR     VAR(&OBJ) VALUE(%SST(&OBJL0400 1 10))
              CHGVAR     VAR(&TYPE) VALUE(%SST(&OBJL0400 21 10))
              CHGVAR     VAR(&OBJATR) VALUE(%SST(&OBJL0400 32 10))
             ENDDO

/*           Delete object, dependent on type                        */
             IF         COND(&TYPE *EQ '*BNDDIR') THEN(DO)
              DLTBNDDIR  BNDDIR(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*CMD') THEN(DO)
              DLTCMD     CMD(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*DTAARA' *AND &OBJ *NE +
                          'HAAANEW') THEN(DO)
              DLTDTAARA  DTAARA(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*JOBD') THEN(DO)
              DLTJOBD    JOBD(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*MENU') THEN(DO)
              DLTMNU     MENU(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*MODULE') THEN(DO)
              DLTMOD     MODULE(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*MSGF') THEN(DO)
              DLTMSGF    MSGF(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*MSGQ') THEN(DO)
              DLTMSGQ    MSGQ(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*PGM') THEN(DO)
              DLTPGM     PGM(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*PNLGRP') THEN(DO)
              DLTPNLGRP  PNLGRP(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*QRYDFN') THEN(DO)
              DLTQRY     QRY(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*SRVPGM') THEN(DO)
              DLTSRVPGM  SRVPGM(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO
             IF         COND(&TYPE *EQ '*FILE') THEN(DO)
/*            For physical files --> delete dependent LFs first      */
              IF         COND(&OBJATR *EQ 'PF') THEN(DO)
/*             Create user space for database relations              */
               CHKOBJ     OBJ(QTEMP/HAAANEW1D) OBJTYPE(*USRSPC)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                RCVMSG     MSGTYPE(*LAST)
                CHGVAR     VAR(&APIERR) VALUE(X'00000000')
                CALL       PGM(QUSCRTUS) PARM(&#DBRSPC 'HAAANEW1' +
                          X'000003F8' ' ' '*ALL' 'HAAANEW1 - List +
                          of database relations' '*YES' &APIERR)
               ENDDO
/*             List database relations                               */
               CHGVAR     VAR(&OBJQ) VALUE(&OBJ || &LIB)
               CHGVAR     VAR(&APIERR) VALUE(X'00080000')
               CALL       PGM(QDBLDBR) PARM(&#DBRSPC 'DBRL0100' &OBJQ +
                          '*ALL' '*ALL' &APIERR)
/*             If the API returns an error --> skip DBRs             */
               IF         COND(%BIN(&APIERR 3 2) *NE 0) THEN(GOTO +
                          CMDLBL(EDBR))
/*             Retrieve user space header information                */
               CHGVAR     VAR(&APIERR) VALUE(X'00000000')
               CALL       PGM(QUSRTVUS) PARM(&#DBRSPC X'00000001' +
                          X'0000008C' &LSTHDR &APIERR)
               CHGVAR     VAR(&DBRSTR) VALUE(%BIN(&LSTHDR 125 4) + 1)
               CHGVAR     VAR(&NBRDBR) VALUE(%BIN(&LSTHDR 133 4))
               CHGVAR     VAR(&DBRSIZ@) VALUE(%SST(&LSTHDR 137 4))
/*             No LFs retrieved --> skip                             */
               IF         COND(&NBRDBR *EQ 0) THEN(GOTO CMDLBL(EDBR))
               CHGVAR     VAR(&J) VALUE(1)
/*             Process all dependent LFs                             */
 LOOPDBR:      IF         COND(&J *LE &NBRDBR) THEN(DO)
/*              Retrieve entry                                       */
                CHGVAR     VAR(%BIN(&STRPOS@)) VALUE(&DBRSTR + ((&J - +
                          1) * %BIN(&DBRSIZ@)))
                CHGVAR     VAR(&APIERR) VALUE(X'00000000')
                CALL       PGM(QUSRTVUS) PARM(&#DBRSPC &STRPOS@ &DBRSIZ@ +
                          &DBRL0100 &APIERR)
/*              Extract variables                                    */
                CHGVAR     VAR(&DBRF) VALUE(%SST(&DBRL0100 21 10))
                CHGVAR     VAR(&DBRFL) VALUE(%SST(&DBRL0100 31 10))
/*              Delete LF                                             */
                IF         COND(&DBRF *NE '*NONE') THEN(DO)
                 DLTF       FILE(&DBRFL/&DBRF)
                 MONMSG     MSGID(CPF0000)
                ENDDO
                CHGVAR     VAR(&J) VALUE(&J + 1)
                GOTO       CMDLBL(LOOPDBR)
               ENDDO
 EDBR:        ENDDO
/*            Now delete (physical) file                             */
              DLTF       FILE(&LIB/&OBJ)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(NEXTOBJ))
             ENDDO

/*           If generic object --> loop                              */
 NEXTOBJ:    IF         COND(&GENNAM) THEN(DO)
              CHGVAR     VAR(&I) VALUE(&I + 1)
              IF         COND(&I *LE &NBROBJ) THEN(GOTO CMDLBL(LOOPOBJ))
             ENDDO

/*           Indicate that generic object was deleted                */
             IF         COND(&GENNAM) THEN(DO)
              SNDPGMMSG  MSGID(AAA0014) MSGF(HAUMSG) MSGDTA(&P_OBJ || +
                          &P_LIB || &P_TYPE) TOPGMQ(*SAME) +
                          MSGTYPE(*COMP)
             ENDDO

/*           If interactive job --> clean-up user spaces             */
             IF         COND(&JOBTYP *EQ '1') THEN(DO)
              DLTUSRSPC  USRSPC(QTEMP/HAANEW1O)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLTUSRSPC  USRSPC(QTEMP/HAANEW1D)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             ENDDO

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
