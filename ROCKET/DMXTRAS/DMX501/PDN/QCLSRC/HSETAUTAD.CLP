/* ================================================================= */
/* Object:         HSETAUTAD       *PGM CLP                          */
/*                 Adjust authority differences                      */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010921 FK  Initial delivery                                     */
/* 20011113 FK  Avoid level check                                    */
/* 20021202 FK  Authority differences in 1 file                      */
/* 20021212 FK  Input file in utilities library specific             */
/* 20030113 FK  Set *OBJREF authorities                              */
/* 20030505 FK  Allow selection by group                             */
/* 20030512 FK  Add support for *AUTL                                */
/* 20050428 FK  Handle special object name *LIB                      */
/*              Avoid usage of RVKOBJAUT                             */
/* 20050518 FK  Only use object authority if *AUTL                   */
/* 20050526 FK  Do not remove obsolete authority for *PUBLIC         */
/*              Do not change owner if *LOCKED                       */
/* 20060306 FK  *PUBLIC authorisation for *AUTL not fixed            */
/*              Special *LIB object handled differently              */
/* 20070919 FK  Missing authorities and authority differences not    */
/*              fixed if different target library                    */
/* ================================================================= */
             PGM        PARM(&GRPNAM &FILE &TGTLIB &UTLLIB)

/*           Declare parameter variables                             */
             DCL        VAR(&GRPNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TGTLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(512)

             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&AUTFIX) TYPE(*LGL)

/*           Declare file                                            */
             DCLF       FILE(HCHKSYNAUT)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Check existence of file                                 */
             CHKOBJ     OBJ(&UTLLIB/&FILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(SAU0001) +
                          MSGF(HAUMSG) MSGDTA(&FILE || &UTLLIB || +
                          '*DIF' || &GRPNAM) MSGTYPE(*ESCAPE))

/*           Override to proper file                                 */
             OVRDBF     FILE(HCHKSYNAUT) TOFILE(&UTLLIB/&FILE)

/*           Read specified file until end of file                   */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Default authority fixed to *On                          */
             CHGVAR     VAR(&AUTFIX) VALUE('1')

/*           Determine name of object                                */
             CHGVAR     VAR(&OBJ) VALUE(&OANAME)
             CHGVAR     VAR(&LIB) VALUE(&OALIB)

/*           Fix object name if different target library             */
             IF         COND(&OATGTL *NE &OACMPL *AND &OATYPE *EQ +
                          '*LIB') THEN(CHGVAR VAR(&OBJ) VALUE(&OATGTL))
             IF         COND(&OATGTL *NE &OACMPL *AND &OATYPE *NE +
                          '*LIB') THEN(CHGVAR VAR(&LIB) VALUE(&OATGTL))

/*           Check if object exists on target machine                */
             CHKOBJ     OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))

/*           If not selected group and not *ALL --> read next        */
             IF         COND(&GRPNAM *NE '*ALL' *AND &OAGRPN *NE +
                          &GRPNAM) THEN(GOTO CMDLBL(LOOP))

/*           If not selected library and not *ALL --> read next      */
             IF         COND(&TGTLIB *NE '*ALL' *AND &LIB *NE +
                          &TGTLIB) THEN(GOTO CMDLBL(LOOP))

/*           If authority is '*LOCKED' --> Skip                      */
             IF         COND(&SAOBJA *EQ '*LOCKED' *OR &TAOBJA *EQ +
                          '*LOCKED') THEN(GOTO CMDLBL(LOOP))

/*           Adjust owner (if different)                             */
             IF         COND(&OAOD *EQ 'Y' *AND &SAOWN *NE +
                          '*LOCKED') THEN(DO)
              CHGOBJOWN  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          NEWOWN(&SAOWN)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
             ENDDO

/*           If obsolete authority for *PUBLIC --> NOT POSSIBLE,     */
/*              DO NOT FIX                                           */
             IF         COND(&OAMAS *EQ 'Y' *AND &OAUSR *EQ +
                          '*PUBLIC') THEN(DO)
              CHGVAR     VAR(&AUTFIX) VALUE('0')
              GOTO       CMDLBL(LOOP)
             ENDDO
/*           If obsolete authority --> Revoke user from object       */
             IF         COND(&OAMAS *EQ 'Y' *AND &OAUSR *NE +
                          '*PUBLIC') THEN(DO)
/*            Set authority to *EXCLUDE                              */
              GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXCLUDE)
/*            Revoke the just granted authority                      */
              RVKOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXCLUDE)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
             ENDDO
             IF         COND(&OAMAS *EQ 'Y' *AND &OATYPE *EQ +
                          '*AUTL') THEN(DO)
              RMVAUTLE   AUTL(&OBJ) USER(&OAUSR)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
             ENDDO

/*           Remainder only if Missing/Different authority           */
             IF         COND((&OAMAT *EQ 'Y' *OR &OAAD *EQ 'Y') *AND +
                          &OATYPE *NE '*AUTL') THEN(DO)
/*            Adjust authorisation list                              */
              IF         COND(&SAANAM *NE &TAANAM) THEN(DO)
               IF         COND(&SAANAM *NE '*NONE') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          AUTL(&SAANAM)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAANAM *EQ '*NONE' *AND &TAANAM *NE ' +
                          ') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) AUTL(*NONE)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
              ENDDO
/*            Adjust authority if *AUTL                              */
              IF         COND(&SAOBJA *EQ '*AUTL') THEN(DO)
               GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(&SAOBJA)
               MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
              ENDDO
/*            Set user-def authorities                                */
              IF         COND(&SAOBJA *NE '*AUTL') THEN(DO)
/*             First, remove all authorities for user                 */
               GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXCLUDE)
/*             Now, set individual authorities                        */
               IF         COND(&SAOPR *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJOPR)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAOMGT *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJMGT)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAEXS *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJEXIST)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAREAD *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*READ)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAADD *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*ADD)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAUPD *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*UPD)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SADLT *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*DLT)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAEXEC *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXECUTE)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAALT *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJALTER)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
               IF         COND(&SAREF *EQ 'X') THEN(DO)
                GRTOBJAUT  OBJ(&LIB/&OBJ) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJREF)
                MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
               ENDDO
              ENDDO
             ENDDO

/*           Missing/Different authority for *AUTL                   */
             IF         COND((&OAMAT *EQ 'Y' *OR &OAAD *EQ 'Y') *AND +
                          &OATYPE *EQ '*AUTL') THEN(DO)
/*            Add dummy entry if not *PUBLIC                         */
              IF         COND(&OAMAT *EQ 'Y' *AND &OAUSR *NE +
                          '*PUBLIC') THEN(DO)
               ADDAUTLE   AUTL(&OBJ) USER(&OAUSR) AUT(*EXCLUDE)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ENDDO
/*            Generate command for changing autl entry                */
              CHGAUTLE   AUTL(&OBJ) USER(&OAUSR) AUT(*EXCLUDE)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              CHGVAR     VAR(&CMD) VALUE('CHGAUTLE AUTL(' |< &OBJ +
                          |< ') USER(' |< &OAUSR |< ') AUT(')
/*            Now, set individual authorities                        */
              IF         COND(&SAOPR *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJOPR'))
              IF         COND(&SAOMGT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJMGT'))
              IF         COND(&SAEXS *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJEXIST'))
              IF         COND(&SAREAD *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*READ'))
              IF         COND(&SAADD *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*ADD'))
              IF         COND(&SAUPD *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*UPD'))
              IF         COND(&SADLT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*DLT'))
              IF         COND(&SAEXEC *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*EXECUTE'))
              IF         COND(&SAALT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJALTER'))
              IF         COND(&SAREF *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJREF'))
              IF         COND(&SAAMGT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*AUTLMGT'))
              CHGVAR     VAR(&CMD) VALUE(&CMD |< ')')
              CALL       PGM(QCMDEXC) PARM(&CMD 512)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('0'))
             ENDDO

/*           Authority is fixed --> adjust record in file            */
             IF         COND(&AUTFIX) THEN(CALL PGM(HSETAUTAF) +
                          PARM(&OAGRPN &OACMPL &OANAME &OATYPE &OAUSR))

             GOTO       CMDLBL(LOOP)

 ELOOP:      RCLRSC
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
