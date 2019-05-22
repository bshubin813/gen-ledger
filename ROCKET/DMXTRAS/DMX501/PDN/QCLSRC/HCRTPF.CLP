/* ================================================================= */
/* Object:         HCRTPF          *PGM CLP                          */
/*                 Creates a new PF based on the format of the base  */
/*                 PF. If file already exists, replace with new      */
/*                 record format if different                        */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20070427 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&CURPF &CURPFL &BASEPF &BASEPFL &UTILITY)

/*           Declare parameter variables                             */
             DCL        VAR(&CURPF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURPFL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BASEPF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BASEPFL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTILITY) TYPE(*CHAR) LEN(10)

/*           Declare constants used for this program                  */
             DCL        VAR(&#DBRSPC) TYPE(*CHAR) LEN(20) +
                          VALUE('HCRTPF    QTEMP')

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&RCVVAR) TYPE(*CHAR) LEN(1000)
             DCL        VAR(&FILEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&TMPNUM) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&TMPNUM@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&TMPFIL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CURPFEXS) TYPE(*LGL)

             DCL        VAR(&CURRCDFMT) TYPE(*CHAR) LEN(13)
             DCL        VAR(&BASERCDFMT) TYPE(*CHAR) LEN(13)
             DCL        VAR(&NBRCURRCD) TYPE(*DEC) LEN(10 0)

             DCL        VAR(&DBRSTR) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&NBRDBR) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&DBRSIZ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&DBRL0100) TYPE(*CHAR) LEN(400)

             DCL        VAR(&DBRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DBRFL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&LSTHDR) TYPE(*CHAR) LEN(140)
             DCL        VAR(&STRPOS@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&J) TYPE(*DEC) LEN(5 0)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Check if files exist                                    */
             CHKOBJ     OBJ(&BASEPFL/&BASEPF) OBJTYPE(*FILE)
             CHGVAR     VAR(&CURPFEXS) VALUE('1')
             CHKOBJ     OBJ(&CURPFL/&CURPF) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CHGVAR     VAR(&CURPFEXS) VALUE('0')
             ENDDO

/*           Retrieve current output file format                     */
             IF         COND(&CURPFEXS) THEN(DO)
              CHGVAR     VAR(&FILEQ) VALUE(&CURPF || &CURPFL)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QDBRTVFD) PARM(&RCVVAR X'000003E8' +
                          &FILEQ 'FILD0200' &FILEQ '*FIRST' '0' +
                          '*FILETYPE' '*EXT' &APIERR)
              CHGVAR     VAR(&CURRCDFMT) VALUE(%SST(&RCVVAR 81 13))

/*            Retrieve original output file format                   */
              CHGVAR     VAR(&FILEQ) VALUE(&BASEPF || &BASEPFL)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QDBRTVFD) PARM(&RCVVAR X'000003E8' +
                          &FILEQ 'FILD0200' &FILEQ '*FIRST' '0' +
                          '*FILETYPE' '*EXT' &APIERR)
              CHGVAR     VAR(&BASERCDFMT) VALUE(%SST(&RCVVAR 81 13))
             ENDDO

/*           If record formats not the same --> replace current      */
             IF         COND(&CURPFEXS *AND &CURRCDFMT *NE +
                          &BASERCDFMT) THEN(DO)
              SNDPGMMSG  MSGID(CRF0001) MSGF(HAUMSG) MSGDTA(&CURPF || +
                          &CURPFL || &BASEPF || &BASEPFL || +
                          &UTILITY) TOPGMQ(*SAME)
/*            First duplicate current PF to FILEnnnn                 */
              CHGVAR     VAR(&TMPNUM) VALUE(0)
 LOOPFIL:     CHGVAR     VAR(&TMPNUM@) VALUE(&TMPNUM)
              CHGVAR     VAR(&TMPFIL) VALUE(%SST(&CURPF 1 6) |< +
                          &TMPNUM@)
              CHKOBJ     OBJ(&CURPFL/&TMPFIL) OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CRTDUPOBJ  OBJ(&CURPF) FROMLIB(&CURPFL) OBJTYPE(*FILE) +
                          NEWOBJ(&TMPFIL) DATA(*YES)
               SNDPGMMSG  MSGID(CRF0002) MSGF(HAUMSG) MSGDTA(&CURPF || +
                          &CURPFL || &TMPFIL) TOPGMQ(*SAME)
               GOTO       CMDLBL(ELOOPFIL)
              ENDDO
/*            If program gets here, file already exists, next loop   */
              CHGVAR     VAR(&TMPNUM) VALUE(&TMPNUM + 1)
              GOTO       CMDLBL(LOOPFIL)
/*            Delete dependent logicals of current PF                */
 ELOOPFIL:    CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSCRTUS) PARM(&#DBRSPC 'HCHKRCDFMT' +
                          X'000003F8' ' ' '*ALL' 'HCHKRCDFMT - List +
                          of database relations' '*YES' &APIERR)
/*            List database relations                                */
              CHGVAR     VAR(&FILEQ) VALUE(&CURPF || &CURPFL)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QDBLDBR) PARM(&#DBRSPC 'DBRL0100' +
                          &FILEQ '*ALL' '*ALL' &APIERR)
/*            Retrieve user space header information                 */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&#DBRSPC X'00000001' +
                          X'0000008C' &LSTHDR &APIERR)
              CHGVAR     VAR(&DBRSTR) VALUE(%BIN(&LSTHDR 125 4) + 1)
              CHGVAR     VAR(&NBRDBR) VALUE(%BIN(&LSTHDR 133 4))
              CHGVAR     VAR(&DBRSIZ@) VALUE(%SST(&LSTHDR 137 4))
/*            Process all dependent LFs                              */
              CHGVAR     VAR(&J) VALUE(1)
 LOOPDBR1:    IF         COND(&J *LE &NBRDBR) THEN(DO)
/*             Retrieve entry                                        */
               CHGVAR     VAR(%BIN(&STRPOS@)) VALUE(&DBRSTR + ((&J - +
                          1) * %BIN(&DBRSIZ@)))
               CHGVAR     VAR(&APIERR) VALUE(X'00000000')
               CALL       PGM(QUSRTVUS) PARM(&#DBRSPC &STRPOS@ &DBRSIZ@ +
                          &DBRL0100 &APIERR)
/*             Extract variables                                     */
               CHGVAR     VAR(&DBRF) VALUE(%SST(&DBRL0100 21 10))
               CHGVAR     VAR(&DBRFL) VALUE(%SST(&DBRL0100 31 10))
/*             Delete LF                                             */
               IF         COND(&DBRF *NE '*NONE') THEN(DO)
                DLTF       FILE(&DBRFL/&DBRF)
               ENDDO
               CHGVAR     VAR(&J) VALUE(&J + 1)
               GOTO       CMDLBL(LOOPDBR1)
              ENDDO      /* Loop DBR1 */
/*            Delete PF                                              */
              DLTF       FILE(&CURPFL/&CURPF)
             ENDDO      /* Replace current */

/*           Now, duplicate new PF and LFs into current PF library  */
             IF         COND(*NOT &CURPFEXS *OR (&CURPFEXS *AND +
                          &CURRCDFMT *NE &BASERCDFMT)) THEN(DO)
              CRTDUPOBJ  OBJ(&BASEPF) FROMLIB(&BASEPFL) +
                          OBJTYPE(*FILE) TOLIB(&CURPFL) +
                          NEWOBJ(&CURPF) DATA(*NO)
/*            Duplicate dependent logical files                      */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSCRTUS) PARM(&#DBRSPC 'HCHKRCDFMT' +
                          X'000003F8' ' ' '*ALL' 'HCHKRCDFMT - List +
                          of database relations' '*YES' &APIERR)
/*            List database relations for base file                  */
              CHGVAR     VAR(&FILEQ) VALUE(&BASEPF || &BASEPFL)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QDBLDBR) PARM(&#DBRSPC 'DBRL0100' +
                          &FILEQ '*ALL' '*ALL' &APIERR)
/*            Retrieve user space header information                 */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QUSRTVUS) PARM(&#DBRSPC X'00000001' +
                          X'0000008C' &LSTHDR &APIERR)
              CHGVAR     VAR(&DBRSTR) VALUE(%BIN(&LSTHDR 125 4) + 1)
              CHGVAR     VAR(&NBRDBR) VALUE(%BIN(&LSTHDR 133 4))
              CHGVAR     VAR(&DBRSIZ@) VALUE(%SST(&LSTHDR 137 4))
/*            Process all dependent LFs                              */
              CHGVAR     VAR(&J) VALUE(1)
 LOOPDBR2:    IF         COND(&J *LE &NBRDBR) THEN(DO)
/*             Retrieve entry                                        */
               CHGVAR     VAR(%BIN(&STRPOS@)) VALUE(&DBRSTR + ((&J - +
                          1) * %BIN(&DBRSIZ@)))
               CHGVAR     VAR(&APIERR) VALUE(X'00000000')
               CALL       PGM(QUSRTVUS) PARM(&#DBRSPC &STRPOS@ &DBRSIZ@ +
                          &DBRL0100 &APIERR)
/*             Extract variables                                     */
               CHGVAR     VAR(&DBRF) VALUE(%SST(&DBRL0100 21 10))
               CHGVAR     VAR(&DBRFL) VALUE(%SST(&DBRL0100 31 10))
/*             Delete LF                                             */
               IF         COND(&DBRF *NE '*NONE') THEN(DO)
                CRTDUPOBJ  OBJ(&DBRF) FROMLIB(&DBRFL) OBJTYPE(*FILE) +
                          TOLIB(&CURPFL)
               ENDDO
               CHGVAR     VAR(&J) VALUE(&J + 1)
               GOTO       CMDLBL(LOOPDBR2)
              ENDDO      /* Loop DBR2 */
             ENDDO      /* New file copied */

/*           If existing file replaced, copy back data               */
             IF         COND(&CURPFEXS *AND &CURRCDFMT *NE +
                          &BASERCDFMT) THEN(DO)
              RTVMBRD    FILE(&CURPFL/&TMPFIL) NBRCURRCD(&NBRCURRCD)
              IF         COND(&NBRCURRCD *NE 0) THEN(CPYF +
                          FROMFILE(&CURPFL/&TMPFIL) +
                          TOFILE(&CURPFL/&CURPF) MBROPT(*ADD) +
                          FMTOPT(*MAP *DROP))
/*            If program gets here, copy was successful              */
              SNDPGMMSG  MSGID(CRF0003) MSGF(HAUMSG) MSGDTA(&CURPF || +
                          &CURPFL || &BASEPF || &BASEPFL || +
                          &UTILITY) MSGTYPE(*COMP)
             ENDDO      /* Existing file replaced */

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
