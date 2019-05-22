/* ================================================================= */
/* Object:         HSETAUTAI       *PGM CLP                          */
/*                 Adjust IFS authority differences                  */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20031209 FK  Initial delivery                                     */
/* 20040119 FK  Check proper characters for mode                     */
/* 20050518 FK  Set private authorities                              */
/* ================================================================= */
             PGM        PARM(&IAMAT &IAMAS &IAAD &IAOD &IAUSR &SJOWN +
                          &TJOWN &SJDTAA &TJDTAA &SJANAM &TJANAM +
                          &SJOPR &TJOPR &SJOMGT &TJOMGT &SJEXS +
                          &TJEXS &SJALT &TJALT &SJREF &TJREF +
                          &SJREAD &TJREAD &SJADD &TJADD &SJUPD +
                          &TJUPD &SJDLT &TJDLT &SJEXEC &TJEXEC +
                          &AUTFIX &IFSLEN &IDOBJ)

/*           Declare parameter variables                             */
             DCL        VAR(&IAMAT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&IAMAS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&IAAD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&IAOD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&IAUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SJOWN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TJOWN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SJDTAA) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TJDTAA) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SJANAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TJANAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SJOPR) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJOPR) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJOMGT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJOMGT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJEXS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJEXS) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJALT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJALT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJREF) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJREF) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJREAD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJREAD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJADD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJADD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJUPD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJUPD) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJDLT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJDLT) TYPE(*CHAR) LEN(1)
             DCL        VAR(&SJEXEC) TYPE(*CHAR) LEN(1)
             DCL        VAR(&TJEXEC) TYPE(*CHAR) LEN(1)
             DCL        VAR(&AUTFIX) TYPE(*CHAR) LEN(1)
             DCL        VAR(&IFSLEN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&IDOBJ) TYPE(*CHAR) LEN(5000)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&IFSOBJ) TYPE(*CHAR) LEN(5000)
             DCL        VAR(&DTAAUT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJAUT) TYPE(*CHAR) LEN(50)
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(6000)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000)

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve IFS object name                                */
             CHGVAR     VAR(&IFSOBJ) VALUE(%SST(&IDOBJ 1 &IFSLEN))

/*           Default authority fixed to *On                          */
             CHGVAR     VAR(&AUTFIX) VALUE('Y')

/*           Change owner if different                               */
             IF         COND(&IAOD *EQ 'Y') THEN(DO)
              CHGOWN     OBJ(&IFSOBJ) NEWOWN(&SJOWN)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('N'))
             ENDDO

/*           Remove obsolete authority                               */
             IF         COND(&IAMAS *EQ 'Y') THEN(DO)
              CHGAUT     OBJ(&IFSOBJ) USER(&IAUSR) DTAAUT(*NONE) +
                          OBJAUT(*NONE)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('N'))
             ENDDO

/*           Add/change authority if missing/different               */
             IF         COND(&IAMAT *EQ 'Y' *OR &IAAD *EQ 'Y') THEN(DO)
/*            First change authorisation list if different           */
              IF         COND(&SJANAM *NE &TJANAM *AND &IAUSR *EQ +
                          '*PUBLIC') THEN(DO)
               CHGAUT     OBJ(&IFSOBJ) AUTL(&SJANAM)
               MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('N'))
              ENDDO
/*            Make up command to set authority                       */
              CHGVAR     VAR(&CMD) VALUE('CHGAUT OBJ(''' |< &IFSOBJ +
                          |< ''') USER(' |< &IAUSR |< ') DTAAUT(' +
                          |< &SJDTAA |< ') OBJAUT(')
/*            Add object authorities                                 */
              IF         COND(&SJDTAA *EQ '*AUTL' *OR &SJDTAA *EQ +
                          '*EXCLUDE') THEN(CHGVAR VAR(&OBJAUT) +
                          VALUE('*NONE'))
              ELSE       CMD(DO)
               IF         COND(&SJEXS *EQ 'X') THEN(CHGVAR +
                          VAR(&OBJAUT) VALUE(&OBJAUT |> '*OBJEXIST'))
               IF         COND(&SJOMGT *EQ 'X') THEN(CHGVAR +
                          VAR(&OBJAUT) VALUE(&OBJAUT |> '*OBJMGT'))
               IF         COND(&SJALT *EQ 'X') THEN(CHGVAR +
                          VAR(&OBJAUT) VALUE(&OBJAUT |> '*OBJALTER'))
               IF         COND(&SJREF *EQ 'X') THEN(CHGVAR +
                          VAR(&OBJAUT) VALUE(&OBJAUT |> '*OBJREF'))
              ENDDO
              CHGVAR     VAR(&CMD) VALUE(&CMD |< &OBJAUT |< ')')
              CALL       PGM(QCMDEXC) PARM(&CMD 6000)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&AUTFIX) +
                          VALUE('N'))
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
