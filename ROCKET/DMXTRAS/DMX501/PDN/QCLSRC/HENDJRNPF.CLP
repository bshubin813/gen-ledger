/* ================================================================= */
/* Object:         HENDJRNPF       *PGM CLP                          */
/*                 Command processing program for HENDJRNPF.         */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20010808 FK  Initial delivery                                     */
/* 20030721 FK  Allow more than 99999 objects in library (count)     */
/* 20041025 FK  Wrong message sent at the end                        */
/* 20050715 FK  Allow to specify object type                         */
/* 20051006 FK  Journaling for DTAARA/DTAQ never ended               */
/* 20070627 FK  Journaling not ended if journal specified            */
/* ================================================================= */
             PGM        PARM(&OBJQ &OBJTYPE &JRNQ)

/*           Declare parameter variables                             */
             DCL        VAR(&OBJQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&OBJTYPE) TYPE(*CHAR) LEN(8)
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&OBJN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&DFTWAIT) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&NBROBJ) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBROBJ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBREND) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBREND@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRERR) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBRERR@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRLCK) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBRLCK@) TYPE(*CHAR) LEN(4)

/*           Declare file                                            */
             DCLF       FILE(HENDJRNPF)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Split qualifier variables                               */
             CHGVAR     VAR(&OBJN) VALUE(%SST(&OBJQ 1 10))
             CHGVAR     VAR(&OBJL) VALUE(%SST(&OBJQ 11 10))
             CHGVAR     VAR(&JRNN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))

/*           Initialisation                                          */
             RTVJOBA    DFTWAIT(&DFTWAIT)
             CHGJOB     DFTWAIT(1)

/*           Verify that the file library exists                     */
             CHKOBJ     OBJ(&OBJL) OBJTYPE(*LIB)

/*           Verify that the specified journal exists                */
             IF         COND(&JRNN *NE '*OBJECT') THEN(RTVOBJD +
                          OBJ(&JRNL/&JRNN) OBJTYPE(*JRN) RTNLIB(&JRNL))

/*           Create file in QTEMP that holds DSPOBJD output          */
             SNDPGMMSG  MSGID(EJP0003) MSGF(HAUMSG) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)
             DLTF       FILE(QTEMP/HENDJRNPF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HENDJRNPF) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP)

/*           Make sure that the QTEMP file is used in the program    */
             OVRDBF     FILE(HENDJRNPF) TOFILE(QTEMP/HENDJRNPF)

/*           Retrieve list of specified objects                      */
             SNDPGMMSG  MSGID(EJP0004) MSGF(HAUMSG) MSGDTA(&OBJQ || +
                          &OBJTYPE) TOPGMQ(*EXT) MSGTYPE(*STATUS)
             SNDPGMMSG  MSGID(EJP0004) MSGF(HAUMSG) MSGDTA(&OBJQ || +
                          &OBJTYPE) TOPGMQ(*SAME)
             IF         COND(&OBJTYPE *EQ '*ALL') THEN(DO)
              DSPOBJD    OBJ(&OBJL/&OBJN) OBJTYPE(*FILE *DTAARA +
                          *DTAQ) DETAIL(*FULL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HENDJRNTMP) OUTMBR(*FIRST *ADD)
              MONMSG     MSGID(CPF0000)
             ENDDO
             IF         COND(&OBJTYPE *NE '*ALL') THEN(DO)
              DSPOBJD    OBJ(&OBJL/&OBJN) OBJTYPE(&OBJTYPE) +
                          DETAIL(*FULL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HENDJRNTMP) OUTMBR(*FIRST *ADD)
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           If no objects found --> error                           */
             CHKOBJ     OBJ(QTEMP/HENDJRNTMP) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(SNDPGMMSG MSGID(EJP0006) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Copy all the records to HENDJRNPF to avoid incompat.    */
             CPYF       FROMFILE(QTEMP/HENDJRNTMP) +
                          TOFILE(QTEMP/HENDJRNPF) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(QTEMP/HENDJRNTMP)

/*           Send status message that journaling is ended            */
             SNDPGMMSG  MSGID(EJP0005) MSGF(HAUMSG) MSGDTA(&OBJQ || +
                          &OBJTYPE || &JRNQ) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)

/*           Read all records in the termporary file                 */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           If object not journaled or the wrong type --> skip      */
             IF         COND(&ODJRST *NE '1' *OR (&ODOBTP *NE +
                          '*DTAARA' *AND &ODOBTP *NE '*DTAQ' *AND +
                          (&ODOBTP *NE '*FILE' *OR &ODOBAT *NE +
                          'PF'))) THEN(GOTO CMDLBL(LOOP))

/*           If journal not same as specified --> skip               */
             IF         COND(&JRNN *NE '*OBJECT' *AND (&JRNN *NE +
                          &ODJRNM *OR &JRNL *NE &ODJRLB)) THEN(GOTO +
                          CMDLBL(LOOP))

/*           If object locked --> skip                               */
             IF         COND(&ODOBLK *EQ '1') THEN(DO)
              CHGVAR     VAR(&NBRLCK) VALUE(&NBRLCK + 1)
              GOTO       CMDLBL(LOOP)
             ENDDO

/*           Ignore source files                                     */
             IF         COND(&ODOBTP *EQ '*FILE' *AND &ODOBAT *EQ +
                          'PF') THEN(DO)
              CALL       PGM(HENDJRNPF1) PARM(&ODOBNM &ODLBNM &ODOBAT)
              IF         COND(&ODOBAT *NE 'PFDTA') THEN(GOTO +
                          CMDLBL(LOOP))
             ENDDO

             CHGVAR     VAR(&NBROBJ) VALUE(&NBROBJ + 1)

/*           If the process gets here, something needs to be done    */

             IF         COND(&ODOBTP *EQ '*FILE') THEN(DO)
              ENDJRNPF   FILE(&ODLBNM/&ODOBNM)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               CHGVAR     VAR(&NBRERR) VALUE(&NBRERR + 1)
               GOTO       CMDLBL(LOOP)
              ENDDO
              CHGVAR     VAR(&NBREND) VALUE(&NBREND + 1)
             ENDDO
             IF         COND(&ODOBTP *NE '*FILE') THEN(DO)
              ENDJRNOBJ  OBJ(&ODLBNM/&ODOBNM) OBJTYPE(&ODOBTP)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               CHGVAR     VAR(&NBRERR) VALUE(&NBRERR + 1)
               GOTO       CMDLBL(LOOP)
              ENDDO
              CHGVAR     VAR(&NBREND) VALUE(&NBREND + 1)
             ENDDO

             GOTO       CMDLBL(LOOP)

/*           Change back the job value and clean up QTEMP            */
 ELOOP:      CHGJOB     DFTWAIT(&DFTWAIT)
             DLTF       FILE(QTEMP/HENDJRNPF)

/*           Send completion or escape message, dependent on errors  */
             CHGVAR     VAR(%BIN(&NBROBJ@)) VALUE(&NBROBJ)
             CHGVAR     VAR(%BIN(&NBREND@)) VALUE(&NBREND)
             CHGVAR     VAR(%BIN(&NBRERR@)) VALUE(&NBRERR)
             CHGVAR     VAR(%BIN(&NBRLCK@)) VALUE(&NBRLCK)
             IF         COND(&NBRERR *EQ 0 *AND &NBRLCK *EQ 0) +
                          THEN(SNDPGMMSG MSGID(EJP0001) +
                          MSGF(HAUMSG) MSGDTA(&NBROBJ@ || &NBREND@) +
                          MSGTYPE(*COMP))
             IF         COND(&NBRERR *NE 0 *OR &NBRLCK *NE 0) +
                          THEN(SNDPGMMSG MSGID(EJP0002) +
                          MSGF(HAUMSG) MSGDTA(&NBROBJ@ || &NBREND@ +
                          || &NBRERR@ || &NBRLCK@) MSGTYPE(*ESCAPE))

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
