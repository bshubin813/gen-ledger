/* ================================================================= */
/* Object:         HSETPOS3        *PGM CLP                          */
/*                 Sets/Checks position for the passed journal       */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20030106 FK  Initial delivery                                     */
/* 20030109 FK  GRPNAM parameter used for SETHAPOS instead of NAME   */
/* 20030711 FK  Enable for iCluster                                  */
/* 20030929 FK  Fix error in record selection                        */
/* 20070413 FK  Interpret character value for LASTPOS                */
/* 20070427 FK  Rewrite for processing of 1 target/grp/journal       */
/* 20111220 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &ACTION &JRN &JRNL +
                          &JRNRCV &JRNRCVL &JRNSEQ &JRNSEQ1 &RTNCDE)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ACTION) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNRCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNSEQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JRNSEQ1) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&RTNSEQ10) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNSEQNBR) TYPE(*CHAR) LEN(20)
             DCL        VAR(&RTNRCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNRCVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNEDTS) TYPE(*CHAR) LEN(26)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Does the journal exist?                                 */
             CHKOBJ     OBJ(&JRNL/&JRN) OBJTYPE(*JRN)
             MONMSG     MSGID(CPF0000) EXEC(DO)
              CHGVAR     VAR(&RTNCDE) VALUE('SPS0009')
              SNDPGMMSG  MSGID(SPS0009) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &JRN || &JRNL) TOPGMQ(*PRV (HSETPOS +
                          *NONE *NONE)) MSGTYPE(*DIAG)
              GOTO       CMDLBL(END)
             ENDDO

/*           Error if journal position is 0                          */
             IF         COND(&JRNSEQ *EQ '00000000000000000000') +
                          THEN(DO)
              CHGVAR     VAR(&RTNCDE) VALUE('SPS0010')
              SNDPGMMSG  MSGID(SPS0010) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &JRN || &JRNL || &JRNRCV || &JRNRCVL) +
                          TOPGMQ(*PRV (HSETPOS *NONE *NONE)) +
                          MSGTYPE(*DIAG)
              GOTO       CMDLBL(END)
             ENDDO

/*           Retrieve last applied journal entry                     */
             HRTVJRNE   JRN(&JRNL/&JRN) JRNRCV(&JRNRCVL/&JRNRCV) +
                          FROMENTLRG(&JRNSEQ) RTNRCV(&RTNRCV) +
                          RTNRCVLIB(&RTNRCVLIB) RTNSEQLRG(&RTNSEQNBR)
             MONMSG     MSGID(CPF0000) EXEC(DO)
              CHGVAR     VAR(&RTNCDE) VALUE('SPS0011')
              SNDPGMMSG  MSGID(SPS0011) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &JRN || &JRNL || &JRNRCV || &JRNRCVL +
                          || &JRNSEQ) TOPGMQ(*PRV (HSETPOS *NONE +
                          *NONE)) MSGTYPE(*DIAG)
              GOTO       CMDLBL(END)
             ENDDO

/*           Ensure that there is an entry after the last            */
             SNDJRNE    JRN(&JRNL/&JRN) TYPE('SP') ENTDTA('HSETPOS +
                          or DMSETPOS run for group or resilient +
                          application' |> &ICGROUP |< ', action' |> +
                          &ACTION)
/*           Retrieve entry after last applied position              */
             HRTVJRNE   JRN(&JRNL/&JRN) JRNRCV(&JRNRCVL/&JRNRCV) +
                          FROMENTLRG(&JRNSEQ1) RTNRCV(&RTNRCV) +
                          RTNRCVLIB(&RTNRCVLIB) +
                          RTNSEQLRG(&RTNSEQNBR) RTNENTDTS(&JRNEDTS)
/*           Send completion message for iCluster *CHK               */
             IF         COND(&ACTION *EQ '*CHK') THEN(SNDPGMMSG +
                          MSGID(SPS0016) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP || &JRN || &JRN || +
                          &RTNRCV || &RTNRCVLIB || &RTNSEQNBR || +
                          &JRNEDTS) TOPGMQ(*PRV (HSETPOS *NONE +
                          *NONE)) MSGTYPE(*COMP))
/*           Send completion message and set position for iC *SET    */
             IF         COND(&ACTION *EQ '*SET') THEN(DO)
              SNDPGMMSG  MSGID(SPS0017) MSGF(HAUMSG) MSGDTA(&ICGROUP +
                          || &JRN || &JRNL || &RTNRCV || &RTNRCVLIB +
                          || &RTNSEQNBR || &JRNEDTS) TOPGMQ(*PRV +
                          (HSETPOS *NONE *NONE)) MSGTYPE(*COMP)
/*            Set positions depending on large/small sequence number */
              IF         COND(%SST(&RTNSEQNBR 1 10) *EQ '0000000000') +
                          THEN(DO)
               CHGVAR     VAR(&RTNSEQ10) VALUE(%SST(&RTNSEQNBR 11 10))
               DMSETPOS   GROUP(&ICGROUP) JRN(&JRNL/&JRN) +
                          JRNRCV(&RTNRCVLIB/&RTNRCV) JRNPOS(&RTNSEQ10)
              ENDDO
              ELSE       CMD(DMSETPOS GROUP(&ICGROUP) JRN(&JRNL/&JRN) +
                          JRNRCV(&RTNRCVLIB/&RTNRCV) +
                          JRNPOSLRG(&RTNSEQNBR))
             ENDDO

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */
/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG and *ESCAPE messages                     */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
