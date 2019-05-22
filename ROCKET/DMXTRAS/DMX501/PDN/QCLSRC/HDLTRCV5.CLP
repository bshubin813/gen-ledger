/* ================================================================= */
/* Object:         HDLTRCV5        *PGM CLP                          */
/*                 Calls the exit program specified at the HDLTJRNRCV*/
/*                 command to verify if the receiver can be deleted. */
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
/* 20000305 FK  Initial delivery                                     */
/* ================================================================= */
             PGM        PARM(&RCVEXITQ &JRN &JRNLIB &RCV &RCVLIB +
                          &RTNCDE)

/*           Declare parameter variables                              */
             DCL        VAR(&RCVEXITQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JRN) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JRNLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCV) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

/*           Declare program variables                                */
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&RCVEXIT) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RCVEXITL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&DLT) TYPE(*CHAR) LEN(1)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 MCH0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             CHGVAR     VAR(&RTNCDE) VALUE(' ')
             CHGVAR     VAR(&DLT) VALUE('1')
             CHGVAR     VAR(&RCVEXIT) VALUE(%SST(&RCVEXITQ 1 10))
             CHGVAR     VAR(&RCVEXITL) VALUE(%SST(&RCVEXITQ 11 10))

/*           Call program specified on command                       */
             CALL       PGM(&RCVEXITL/&RCVEXIT) PARM(&JRN &JRNLIB +
                          &RCV &RCVLIB &DLT)

/*           If delete not allowed --> set return code and issue msg */
             IF         COND(&DLT *NE '1') THEN(DO)
              CHGVAR     VAR(&RTNCDE) VALUE('DJR0020')
              SNDPGMMSG  MSGID(DJR0020) MSGF(HAUMSG) MSGDTA(&RCVEXITQ +
                          || &JRN || &JRNLIB || &RCV || &RCVLIB) +
                          TOPGMQ(*PRV (HDLTJRNRCV)) MSGTYPE(*DIAG)
             ENDDO

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

             CHGVAR     VAR(&RTNCDE) VALUE('DJR0019')
             SNDPGMMSG  MSGID(DJR0019) MSGF(HAUMSG) MSGDTA(&RCVEXITQ +
                          || &JRN || &JRNLIB || &RCV || &RCVLIB) +
                          TOPGMQ(*PRV (HDLTJRNRCV)) MSGTYPE(*DIAG)

 END:        ENDPGM
