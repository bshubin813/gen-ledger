/* ================================================================= */
/* Object:         HDLTRCV3        *PGM CLP                          */
/*                 Deletes the passed journal receiver.              */
/*                                                                   */
/* Synopsis:       This program is passed the journal receiver that  */
/*                 is to be deleted. The program verifies that the   */
/*                 receiver is fully processed by HA Suite and       */
/*                 subsequently deletes it.                          */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 19990721 FK  Initial delivery                                     */
/* 20070108 FK  Allow instrumental mode                              */
/* ================================================================= */
             PGM        PARM(&JRN &JRNL &RCV &RCVL &DLTUNSRCV +
                          &RPYSEQ &DLTRCV &RCVDLT)

/*           Declare parameter variables                              */
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DLTUNSRCV) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RPYSEQ) TYPE(*DEC) LEN(4 0)
             DCL        VAR(&DLTRCV) TYPE(*CHAR) LEN(4)
             DCL        VAR(&RCVDLT) TYPE(*LGL)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&DLTOPT) TYPE(*CHAR) LEN(10)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&RCVDLT) VALUE('0')
             CHGVAR     VAR(&DLTOPT) VALUE('*NONE')
             IF         COND(&RPYSEQ *EQ -2) THEN(CHGVAR +
                          VAR(&DLTOPT) VALUE('*IGNINQMSG'))

/*           Delete unsaved --> add reply list entry                 */
             IF         COND(&RPYSEQ *GT 0) THEN(ADDRPYLE +
                          SEQNBR(&RPYSEQ) MSGID(CPA7025) +
                          CMPDTA((&RCV || &RCVL)) RPY(I))
             IF         COND(&DLTRCV *EQ '*YES') THEN(DO)
              DLTJRNRCV  JRNRCV(&RCVL/&RCV) DLTOPT(&DLTOPT)
              MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(RMVRPYLE))
             ENDDO
             ELSE       CMD(DO)
              SNDPGMMSG  MSGID(DJR0042) MSGF(HAUMSG) MSGDTA(&JRN || +
                          &JRNL || &RCV || &RCVL)
             ENDDO
             CHGVAR     VAR(&RCVDLT) VALUE('1')
/*           Delete unsaved --> remove list entry again              */
 RMVRPYLE:   IF         COND(&RPYSEQ *GT 0) THEN(RMVRPYLE +
                          SEQNBR(&RPYSEQ))

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
