/* ================================================================= */
/* Object:         HDLTRCV6        *PGM CLP                          */
/*                 Calls the exit program to retrieve the current    */
/*                 processed journal receiver by an external         */
/*                 product.                                          */
/*                                                                   */
/* Create remarks: None.                                             */
/*                                                                   */
/* Synopsis:       This program is invoked from HDLTRCV2 to          */
/*                 perform additional actions specified by the       */
/*                 user.                                             */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000523 FK  Initial delivery                                     */
/* 20000524 FK  Allow *IGNORE return code to ignore journal          */
/* ================================================================= */
             PGM        PARM(&POSEXITQ &JRN &JRNLIB &RCV &RCVLIB +
                          &RTNCDE)

/*           Declare parameter variables                              */
             DCL        VAR(&POSEXITQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare program variables                                */
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&POSEXIT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&POSEXITL) TYPE(*CHAR) LEN(10)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&RTNCDE) VALUE(' ')
             CHGVAR     VAR(&POSEXIT) VALUE(%SST(&POSEXITQ 1 10))
             CHGVAR     VAR(&POSEXITL) VALUE(%SST(&POSEXITQ 11 10))

/*           Call program specified on command                       */
             CALL       PGM(&POSEXITL/&POSEXIT) PARM(&JRN &JRNLIB +
                          &RCV &RCVLIB &RTNCDE)

/*           If error retrieving --> Set return code and issue msg   */
             IF         COND(&RTNCDE *NE ' ' *AND &RTNCDE *NE +
                          '*IGNORE') THEN(DO)
              CHGVAR     VAR(&RTNCDE) VALUE('DJR0021')
              SNDPGMMSG  MSGID(DJR0021) MSGF(HAUMSG) MSGDTA(&POSEXITQ +
                          || &JRN || &JRNLIB) TOPGMQ(*PRV +
                          (HDLTJRNRCV)) MSGTYPE(*DIAG)
             ENDDO

/*           If journal ignored --> send message in job log          */
             IF         COND(&RTNCDE *EQ '*IGNORE') THEN(SNDPGMMSG +
                          MSGID(DJR0023) MSGF(HAUMSG) +
                          MSGDTA(&POSEXITQ || &JRN || &JRNLIB) +
                          TOPGMQ(*SAME))

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

             CHGVAR     VAR(&RTNCDE) VALUE('DJR0022')
             SNDPGMMSG  MSGID(DJR0022) MSGF(HAUMSG) MSGDTA(&POSEXITQ +
                          || &JRN || &JRNLIB) TOPGMQ(*PRV +
                          (HDLTJRNRCV)) MSGTYPE(*DIAG)

 END:        ENDPGM
