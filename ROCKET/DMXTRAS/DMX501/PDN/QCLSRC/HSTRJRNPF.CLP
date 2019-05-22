/* ================================================================= */
/* Object:         HSTRJRNPF       *PGM CLP                          */
/*                 Command processing program for HSTRJRNPF.         */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990806 FK  Initial delivery                                     */
/* 20020502 FK  Allow for maximum of 100 file libraries              */
/* 20030521 FK  Send message if there were not files found           */
/* 20030721 FK  Allow more than 99999 objects in library (count)     */
/* 20050715 FK  Allow to specify object type                         */
/* ================================================================= */
             PGM        PARM(&JRNQ &OLSTQ &IMAGES &RESTART &BATCH)

/*           Declare parameter variables                             */
             DCL        VAR(&JRNQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&OLSTQ) TYPE(*CHAR) LEN(2802)
             DCL        VAR(&IMAGES) TYPE(*CHAR) LEN(6)
             DCL        VAR(&RESTART) TYPE(*CHAR) LEN(4)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&OBJQ) TYPE(*CHAR) LEN(28)
             DCL        VAR(&OBJN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJT) TYPE(*CHAR) LEN(8)
             DCL        VAR(&JRNN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&DFTWAIT) TYPE(*DEC) LEN(7 0)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&NBROBJ) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBROBJ@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRJRN) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBRJRN@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRRST) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBRRST@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRERR) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBRERR@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&NBRLCK) TYPE(*DEC) LEN(9 0) VALUE(0)
             DCL        VAR(&NBRLCK@) TYPE(*CHAR) LEN(4)

             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&NBROLSTQ) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(3000)
             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&POS) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&LIBERR) TYPE(*LGL)
             DCL        VAR(&JRNIMG) TYPE(*CHAR) LEN(1)

/*           Declare file                                            */
             DCLF       FILE(HSTRJRNPF)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             IF         COND(&IMAGES *EQ '*BOTH') THEN(CHGVAR +
                          VAR(&JRNIMG) VALUE('1'))
             ELSE       CMD(CHGVAR VAR(&JRNIMG) VALUE('0'))
             RTVJOBA    TYPE(&JOBTYPE)

/*           Retrieve product libraries                              */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Split qualifier variables                               */
             CHGVAR     VAR(&NBROLSTQ) VALUE(%BIN(&OLSTQ 1 2))
             CHGVAR     VAR(&JRNN) VALUE(%SST(&JRNQ 1 10))
             CHGVAR     VAR(&JRNL) VALUE(%SST(&JRNQ 11 10))
             CHGVAR     VAR(&LIBERR) VALUE('0')

/*           Check library existence and make up command             */
             CHGVAR     VAR(&CMD) VALUE(&UTLLIB |< '/HSTRJRNPF FILE(')
             CHGVAR     VAR(&I) VALUE(1)
 LOOPLIB:    IF         COND(&I *LE &NBROLSTQ) THEN(DO)
              CHGVAR     VAR(&POS) VALUE(((&I - 1) * 28) + 3)
              CHGVAR     VAR(&OBJQ) VALUE(%SST(&OLSTQ &POS 28))
              CHGVAR     VAR(&OBJN) VALUE(%SST(&OBJQ 1 10))
              CHGVAR     VAR(&OBJL) VALUE(%SST(&OBJQ 11 10))
              CHGVAR     VAR(&OBJT) VALUE(%SST(&OBJQ 21 8))
/*            Add object qualifier to command                        */
              CHGVAR     VAR(&CMD) VALUE(&CMD |> &OBJT |< '/' |< +
                          &OBJL |< '/' |< &OBJN)
/*            If library doesn't exist --> warning                   */
              CHKOBJ     OBJ(&OBJL) OBJTYPE(*LIB)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               SNDPGMMSG  MSGID(SJP0006) MSGF(HAUMSG) MSGDTA(&OBJN || +
                          &OBJL || &OBJT) MSGTYPE(*DIAG)
               CHGVAR     VAR(&LIBERR) VALUE('1')
              ENDDO
              CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOPLIB)
             ENDDO
/*           Add remainder of parameters to command                  */
             CHGVAR     VAR(&CMD) VALUE(&CMD |< ') JRN(' |< &JRNL |< +
                          '/' |< &JRNN |< ') IMAGES(' |< &IMAGES |< +
                          ') RESTART(' |< &RESTART |< ') BATCH(' |< +
                          &BATCH |< ')')
/*           Send command to menu program to allow F9                */
             IF         COND(&JOBTYPE *EQ '1') THEN(DO)
              SNDPGMMSG  MSG(&CMD) TOPGMQ(*SAME) MSGTYPE(*RQS)
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             ENDDO

/*           Initialisation                                          */
             RTVJOBA    TYPE(&JOBTYPE) DFTWAIT(&DFTWAIT)
             CHGJOB     DFTWAIT(1)

/*           If any of the libraries doesn't exist --> error         */
             IF         COND(&LIBERR) THEN(SNDPGMMSG MSGID(SJP0007) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Verify that the specified journal exists                */
             RTVOBJD    OBJ(&JRNL/&JRNN) OBJTYPE(*JRN) RTNLIB(&JRNL)

/*           Submit job to batch if desired                          */
             IF         COND(&BATCH *EQ '*YES' *AND &JOBTYPE *EQ +
                          '1') THEN(DO)
              CHGVAR     VAR(&CMD) VALUE('SBMJOB CMD(' |< &CMD |< ') +
                          JOB(HSTRJRNPF) JOBD(HAUTILS)')
              CALL       PGM(QCMDEXC) PARM(&CMD 3000)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Create file in QTEMP that holds DSPOBJD entries         */
             SNDPGMMSG  MSGID(SJP0003) MSGF(HAUMSG) TOPGMQ(*EXT) +
                          MSGTYPE(*STATUS)
             DLTF       FILE(QTEMP/HSTRJRNPF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HSTRJRNPF) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(QTEMP)

/*           Make sure that the QTEMP file is used in the program    */
             OVRDBF     FILE(HSTRJRNPF) TOFILE(QTEMP/HSTRJRNPF)

/*           Process all specified object qualifiers                 */
             DLTF       FILE(QTEMP/HSTRJRNTMP)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&I) VALUE(1)
 LOOPFQ:     IF         COND(&I *LE &NBROLSTQ) THEN(DO)
              CHGVAR     VAR(&POS) VALUE(((&I - 1) * 28) + 3)
              CHGVAR     VAR(&OBJQ) VALUE(%SST(&OLSTQ &POS 28))
              CHGVAR     VAR(&OBJN) VALUE(%SST(&OBJQ 1 10))
              CHGVAR     VAR(&OBJL) VALUE(%SST(&OBJQ 11 10))
              CHGVAR     VAR(&OBJT) VALUE(%SST(&OBJQ 21 8))
/*            Retrieve list of specified objects                     */
              SNDPGMMSG  MSGID(SJP0004) MSGF(HAUMSG) MSGDTA(&OBJQ) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(SJP0004) MSGF(HAUMSG) MSGDTA(&OBJQ) +
                          TOPGMQ(*SAME)
              IF         COND(&OBJT *EQ '*ALL') THEN(DO)
               DSPOBJD    OBJ(&OBJL/&OBJN) OBJTYPE(*FILE *DTAARA +
                          *DTAQ) DETAIL(*FULL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HSTRJRNTMP) OUTMBR(*FIRST *ADD)
               MONMSG     MSGID(CPF0000)
              ENDDO
              IF         COND(&OBJT *NE '*ALL') THEN(DO)
               DSPOBJD    OBJ(&OBJL/&OBJN) OBJTYPE(&OBJT) +
                          DETAIL(*FULL) OUTPUT(*OUTFILE) +
                          OUTFILE(QTEMP/HSTRJRNTMP) OUTMBR(*FIRST *ADD)
               MONMSG     MSGID(CPF0000)
              ENDDO
              CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOPFQ)
             ENDDO

/*           If no objects found --> error                           */
             CHKOBJ     OBJ(QTEMP/HSTRJRNTMP) OBJTYPE(*FILE)
             MONMSG     MSGID(CPF9801) EXEC(SNDPGMMSG MSGID(SJP0008) +
                          MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Copy all the records to HSTRJRNPF to avoid incompat.    */
             CPYF       FROMFILE(QTEMP/HSTRJRNTMP) +
                          TOFILE(QTEMP/HSTRJRNPF) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(QTEMP/HSTRJRNTMP)

/*           Send status message that journalling is started         */
             SNDPGMMSG  MSGID(SJP0005) MSGF(HAUMSG) MSGDTA(&JRNQ) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)

/*           Read all records in the temporary file                  */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           If object must not be journaled by definition -> skip   */
             IF         COND(*NOT (&ODOBTP *EQ '*DTAARA' *OR &ODOBTP +
                          *EQ '*DTAQ' *OR (&ODOBTP *EQ '*FILE' *AND +
                          &ODOBAT *EQ 'PF'))) THEN(GOTO CMDLBL(LOOP))

/*           If object locked --> skip                               */
             IF         COND(&ODOBLK *EQ '1') THEN(DO)
              CHGVAR     VAR(&NBRLCK) VALUE(&NBRLCK + 1)
              GOTO       CMDLBL(LOOP)
             ENDDO

/*           If physical file --> retrieve data attribute            */
             IF         COND(&ODOBTP *EQ '*FILE' *AND &ODOBAT *EQ +
                          'PF') THEN(DO)
              CALL       PGM(HSTRJRNPF1) PARM(&ODOBNM &ODLBNM &ODOBAT)
              IF         COND(&ODOBAT *NE 'PFDTA') THEN(GOTO +
                          CMDLBL(LOOP))
             ENDDO

             CHGVAR     VAR(&NBROBJ) VALUE(&NBROBJ + 1)

/*           If object already properly journaled --> skip           */
             IF         COND(&ODJRST *EQ '1' *AND (&RESTART *EQ +
                          '*NO' *OR (&ODJRNM *EQ &JRNN *AND &ODJRLB +
                          *EQ &JRNL *AND &ODJRIM *EQ &JRNIMG))) +
                          THEN(GOTO CMDLBL(LOOP))

/*           If the process gets here, something needs to be done    */

/*           If journaling must be restarted --> end journal first   */
             IF         COND(&ODJRST *EQ '1') THEN(DO)
              IF         COND(&ODOBTP *EQ '*FILE') THEN(DO)
               ENDJRNPF   FILE(&ODLBNM/&ODOBNM)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                CHGVAR     VAR(&NBRERR) VALUE(&NBRERR + 1)
                GOTO       CMDLBL(LOOP)
               ENDDO
              ENDDO
              IF         COND(&ODOBTP *NE '*FILE') THEN(DO)
               ENDJRNOBJ  OBJ(&ODLBNM/&ODOBNM) OBJTYPE(&ODOBTP)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                CHGVAR     VAR(&NBRERR) VALUE(&NBRERR + 1)
                GOTO       CMDLBL(LOOP)
               ENDDO
              ENDDO
              CHGVAR     VAR(&NBRRST) VALUE(&NBRRST + 1)
             ENDDO

/*           Start journalling for object                            */
             IF         COND(&ODOBTP *EQ '*FILE') THEN(DO)
              STRJRNPF   FILE(&ODLBNM/&ODOBNM) JRN(&JRNL/&JRNN) +
                          IMAGES(&IMAGES) OMTJRNE(*OPNCLO)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               CHGVAR     VAR(&NBRERR) VALUE(&NBRERR + 1)
               GOTO       CMDLBL(LOOP)
              ENDDO
             ENDDO
             IF         COND(&ODOBTP *NE '*FILE') THEN(DO)
             STRJRNOBJ  OBJ(&ODLBNM/&ODOBNM) OBJTYPE(&ODOBTP) +
                          JRN(&JRNL/&JRNN) IMAGES(&IMAGES)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               CHGVAR     VAR(&NBRERR) VALUE(&NBRERR + 1)
               GOTO       CMDLBL(LOOP)
              ENDDO
             ENDDO
             CHGVAR     VAR(&NBRJRN) VALUE(&NBRJRN + 1)

             GOTO       CMDLBL(LOOP)

/*           Change back the job value and clean up QTEMP            */
 ELOOP:      CHGJOB     DFTWAIT(&DFTWAIT)
             DLTF       FILE(QTEMP/HSTRJRNPF)

/*           Send completion or escape message, dependent on errors  */
             CHGVAR     VAR(%BIN(&NBROBJ@)) VALUE(&NBROBJ)
             CHGVAR     VAR(%BIN(&NBRJRN@)) VALUE(&NBRJRN)
             CHGVAR     VAR(%BIN(&NBRRST@)) VALUE(&NBRRST)
             CHGVAR     VAR(%BIN(&NBRERR@)) VALUE(&NBRERR)
             CHGVAR     VAR(%BIN(&NBRLCK@)) VALUE(&NBRLCK)
             IF         COND(&NBRERR *EQ 0 *AND &NBRLCK *EQ 0) +
                          THEN(SNDPGMMSG MSGID(SJP0001) +
                          MSGF(HAUMSG) MSGDTA(&NBROBJ@ || &NBRJRN@ +
                          || &NBRRST@) MSGTYPE(*COMP))
             IF         COND(&NBRERR *NE 0 *OR &NBRLCK *NE 0) +
                          THEN(SNDPGMMSG MSGID(SJP0002) +
                          MSGF(HAUMSG) MSGDTA(&NBROBJ@ || &NBRJRN@ +
                          || &NBRRST@ || &NBRERR@ || &NBRLCK@) +
                          MSGTYPE(*ESCAPE))

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
