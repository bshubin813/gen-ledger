/* ================================================================= */
/* Object:         HSETAUTA        *PGM CLP                          */
/*                 Set all authorities (*RVK/*GRT)                   */
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
/* 20021129 FK  New file layout HCHKSYNOA                            */
/* 20030113 FK  Allow for *OBJREF authority                          */
/* 20030505 FK  Allow selection by group                             */
/* 20030512 FK  Add support for *AUTL                                */
/* ================================================================= */
             PGM        PARM(&GRPNAM &SYNID &TGTLIB &ACTION +
                          &UTLLIB)

/*           Declare parameter variables                             */
             DCL        VAR(&GRPNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYNID) TYPE(*CHAR) LEN(5)
             DCL        VAR(&TGTLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&FILE) TYPE(*CHAR) LEN(10)

             DCL        VAR(&OBJSV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LIBSV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TYPESV) TYPE(*CHAR) LEN(8)

             DCL        VAR(&OWNER) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(512)

/*           Declare file                                            */
             DCLF       FILE(HCHKSYNOA)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Make up name for input file                             */
             IF         COND(&ACTION *EQ '*GRT') THEN(CHGVAR +
                          VAR(&FILE) VALUE('HS' |< &SYNID |< 'SA'))
             IF         COND(&ACTION *EQ '*RVK') THEN(CHGVAR +
                          VAR(&FILE) VALUE('HS' |< &SYNID |< 'TA'))

/*           Check existence of file                                 */
             CHKOBJ     OBJ(&UTLLIB/&FILE) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(SAU0001) +
                          MSGF(HAUMSG) MSGDTA(&FILE || &UTLLIB || +
                          &ACTION || &GRPNAM) MSGTYPE(*ESCAPE))

/*           Override to proper file                                 */
             OVRDBF     FILE(HCHKSYNOA) TOFILE(&UTLLIB/&FILE)

/*           Read specified file until end of file                   */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Check if object exists on target machine                */
             CHKOBJ     OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE)
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(LOOP))

/*           If not selected group and not *ALL --> read next        */
             IF         COND(&GRPNAM *NE '*ALL' *AND &OAGRPN *NE +
                          &GRPNAM) THEN(GOTO CMDLBL(LOOP))

/*           If not selected library and not *ALL --> read next      */
             IF         COND(&TGTLIB *NE '*ALL' *AND &OALIB *NE +
                          &TGTLIB) THEN(GOTO CMDLBL(LOOP))

/*           If user is '*LOCKED' --> Skip                           */
             IF         COND(&OAUSR *EQ '*LOCKED') THEN(GOTO +
                          CMDLBL(LOOP))

/*           Action = *GRT --> Set object authorities                */
             IF         COND(&ACTION *EQ '*GRT') THEN(DO)
/*            If new object --> check owner and set authorisation lst*/
              IF         COND(&OANAME *NE &OBJSV *OR &OALIB *NE +
                          &LIBSV *OR &OATYPE *NE &TYPESV) THEN(DO)
               CHGVAR     VAR(&OBJSV) VALUE(&OANAME)
               CHGVAR     VAR(&LIBSV) VALUE(&OALIB)
               CHGVAR     VAR(&TYPESV) VALUE(&OATYPE)
               RTVOBJD    OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          OWNER(&OWNER)
/*             Change owner if not equal                             */
               IF         COND(&OAOWN *NE &OWNER) THEN(DO)
                CHGOBJOWN  OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          NEWOWN(&OAOWN)
               ENDDO
/*             Set authorisation list                                */
               IF         COND(&OAANAM *NE '*NONE') THEN(DO)
                GRTOBJAUT  OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          AUTL(&OAANAM)
               ENDDO
              ENDDO
/*            Set authority if not USER DEF                          */
              IF         COND(&OAOBJA *NE 'USER DEF' *AND &OATYPE *NE +
                          '*AUTL') THEN(DO)
               GRTOBJAUT  OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(&OAOBJA)
              ENDDO
              IF         COND(&OAOBJA *NE 'USER DEF' *AND &OATYPE *EQ +
                          '*AUTL') THEN(DO)
               RMVAUTLE   AUTL(&OANAME) USER(&OAUSR)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
               IF         COND(&OAAMGT *NE 'X') THEN(ADDAUTLE +
                          AUTL(&OANAME) USER(&OAUSR) AUT(&OAOBJA))
               IF         COND(&OAAMGT *NE 'X') THEN(ADDAUTLE +
                          AUTL(&OANAME) USER(&OAUSR) AUT(&OAOBJA +
                          *AUTLMGT))
              ENDDO
/*            Set user-def authorities                               */
              IF         COND(&OAOBJA *EQ 'USER DEF' *AND &OATYPE *NE +
                          '*AUTL') THEN(DO)
/*             First, revoke all authorities for user                */
               GRTOBJAUT  OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXCLUDE)
/*             Now, set individual authorities                       */
               IF         COND(&OAOPR *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJOPR))
               IF         COND(&OAOMGT *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJMGT))
               IF         COND(&OAEXS *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJEXIST))
               IF         COND(&OAREAD *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*READ))
               IF         COND(&OAADD *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*ADD))
               IF         COND(&OAUPD *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*UPD))
               IF         COND(&OADLT *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*DLT))
               IF         COND(&OAEXEC *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXECUTE))
               IF         COND(&OAALT *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJALTER))
               IF         COND(&OAREF *EQ 'X') THEN(GRTOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJREF))
              ENDDO
/*            Set user-def authorities for *AUTL objects             */
              IF         COND(&OAOBJA *EQ 'USER DEF' *AND &OATYPE *EQ +
                          '*AUTL') THEN(DO)
/*             First, revoke all authorities for user                */
               RMVAUTLE   AUTL(&OANAME) USER(&OAUSR)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
/*             Generate command for adding autl entry                 */
               CHGVAR     VAR(&CMD) VALUE('ADDAUTLE AUTL(' |< &OANAME +
                          |< ') USER(' |< &OAUSR |< ') AUT(')
/*             Now, set individual authorities                        */
               IF         COND(&OAOPR *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJOPR'))
               IF         COND(&OAOMGT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJMGT'))
               IF         COND(&OAEXS *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJEXIST'))
               IF         COND(&OAREAD *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*READ'))
               IF         COND(&OAADD *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*ADD'))
               IF         COND(&OAUPD *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*UPD'))
               IF         COND(&OADLT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*DLT'))
               IF         COND(&OAEXEC *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*EXECUTE'))
               IF         COND(&OAALT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJALTER'))
               IF         COND(&OAREF *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*OBJREF'))
               IF         COND(&OAAMGT *EQ 'X') THEN(CHGVAR VAR(&CMD) +
                          VALUE(&CMD |> '*AUTLMGT'))
               CHGVAR     VAR(&CMD) VALUE(&CMD |< ')')
               CALL       PGM(QCMDEXC) PARM(&CMD 512)
              ENDDO
             ENDDO

/*           Action = *RVK --> Revoke object authorities             */
             IF         COND(&ACTION *EQ '*RVK') THEN(DO)
/*            Set authority if not USER DEF                          */
              IF         COND(&OAOBJA *NE 'USER DEF' *AND &OATYPE *NE +
                          '*AUTL') THEN(DO)
               RVKOBJAUT  OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(&OAOBJA)
              ENDDO
/*            Set authority if not USER DEF for *AUTL objects        */
              IF         COND(&OAOBJA *NE 'USER DEF' *AND &OATYPE *EQ +
                          '*AUTL') THEN(DO)
               RMVAUTLE   AUTL(&OANAME) USER(&OAUSR)
              ENDDO
/*            Set user-def authorities                               */
              IF         COND(&OAOBJA *EQ 'USER DEF' *AND &OATYPE *NE +
                          '*AUTL') THEN(DO)
/*             First, revoke all authorities for user                */
               RVKOBJAUT  OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXCLUDE)
/*             Now, set individual authorities                       */
               IF         COND(&OAOPR *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJOPR))
               IF         COND(&OAOMGT *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJMGT))
               IF         COND(&OAEXS *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJEXIST))
               IF         COND(&OAREAD *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*READ))
               IF         COND(&OAADD *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*ADD))
               IF         COND(&OAUPD *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*UPD))
               IF         COND(&OADLT *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*DLT))
               IF         COND(&OAEXEC *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*EXECUTE))
               IF         COND(&OAALT *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJALTER))
               IF         COND(&OAREF *EQ 'X') THEN(RVKOBJAUT +
                          OBJ(&OALIB/&OANAME) OBJTYPE(&OATYPE) +
                          USER(&OAUSR) AUT(*OBJREF))
              ENDDO
             ENDDO

             GOTO       CMDLBL(LOOP)

 ELOOP:      GOTO       CMDLBL(END)

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
