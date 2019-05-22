/* ================================================================= */
/* Object:         HAAANEWPO       *PGM CLP                          */
/*                 Prompt override program for the HAAANEW command.  */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20011128 FK  Initial delivery                                     */
/* 20020516 FK  Use different method to enforce prompting            */
/* 20020522 FK  Include batch parameter                              */
/* 20021230 FK  Rename to HAAANEWPO                                  */
/* 20030728 FK  Only prompt parameter that are non-default           */
/* 20041218 FK  Replace HMONEVL by HMONHA                            */
/* 20050302 FK  New parameter MODULES                                */
/* 20070821 FK  New parameter: TMONTS                                */
/* 20071024 FK  New parameter: CCSID                                 */
/* 20111212 FK  Remove HA Suite and CDC                              */
/* ================================================================= */
             PGM        PARM(&CMD &CUSLIB &CMDPARM)

/*           Declare parameter variables                             */
             DCL        VAR(&CMD) TYPE(*CHAR) LEN(20)
             DCL        VAR(&CUSLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CMDPARM) TYPE(*CHAR) LEN(2002)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&HAAANEW) TYPE(*CHAR) LEN(2000)

             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&HMONHA@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&MODULES) TYPE(*CHAR) LEN(40)
             DCL        VAR(&MODULES@) TYPE(*CHAR) LEN(100)
             DCL        VAR(&CCSID@) TYPE(*CHAR) LEN(5)

             DCL        VAR(&NEWLIB) TYPE(*LGL) VALUE('0')
             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(3 0)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Does the custom library already exist                   */
             CHKOBJ     OBJ(&CUSLIB) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CHGVAR     VAR(&NEWLIB) VALUE('1')
             ENDDO

/*           Retrieve the current values from the &CUSLIB            */
             IF         COND(*NOT &NEWLIB) THEN(DO)
              RTVDTAARA  DTAARA(&CUSLIB/HAAANEW (1 2000)) +
                          RTNVAR(&HAAANEW)
/*            If HAAANEW data area not found, try H###NEW for values */
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               RTVDTAARA  DTAARA(&CUSLIB/H###NEW (1 2000)) +
                          RTNVAR(&HAAANEW)
               MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              ENDDO
             ENDDO

/*           Fill the command parameters with the retrieved values   */
             CHGVAR     VAR(&ICLIB) VALUE(%SST(&HAAANEW 21 10))
             CHGVAR     VAR(&HMONHA@) VALUE(%SST(&HAAANEW 36 5))
             CHGVAR     VAR(&MODULES) VALUE(%SST(&HAAANEW 101 40))
             CHGVAR     VAR(&CCSID@) VALUE(%SST(&HAAANEW 146 5))

/*           Correct values that could not be retrieved              */
             IF         COND(&ICLIB *EQ ' ') THEN(CHGVAR VAR(&ICLIB) +
                          VALUE('*NONE'))
             IF         COND(&HMONHA@ *EQ ' ') THEN(CHGVAR +
                          VAR(&HMONHA@) VALUE('4446'))
             IF         COND(&MODULES *EQ ' ') THEN(CHGVAR +
                          VAR(&MODULES) VALUE('*ALL'))

/*           Now, compose first part of command parameters           */
             CHGVAR     VAR(&CMDPARM) VALUE('  ' || +
                          '??OLDLIB(DMXTRASOLD)')

/*           Now, compose rest of command parameters if not default  */
             IF         COND(&ICLIB *NE '*NONE') THEN(CHGVAR +
                          VAR(&CMDPARM) VALUE(&CMDPARM |> +
                          '??ICLIB(' |< &ICLIB |< ')'))
             IF         COND(&HMONHA@ *NE '04446' *AND &HMONHA@ *NE +
                          '4446') THEN(CHGVAR VAR(&CMDPARM) +
                          VALUE(&CMDPARM |> '??HMONHA(' |< &HMONHA@ +
                          |< ')'))
             CHGVAR     VAR(&I) VALUE(1)
 LOOPMOD:    IF         COND(&I *LE 10) THEN(DO)
              CHGVAR     VAR(&STRPOS) VALUE(((&I - 1) * 4) + 1)
              CHGVAR     VAR(&MODULES@) VALUE(&MODULES@ |> +
                          %SST(&MODULES &STRPOS 4))
              CHGVAR     VAR(&I) VALUE(&I + 1)
             ENDDO
             IF         COND(&MODULES *NE '*ALL') THEN(CHGVAR +
                          VAR(&CMDPARM) VALUE(&CMDPARM |> +
                          '??MODULES(' |< &MODULES@ |< ')'))
             IF         COND(&CCSID@ *NE ' ') THEN(CHGVAR +
                          VAR(&CMDPARM) VALUE(&CMDPARM |> +
                          '??CCSID(' |< &CCSID@ |< ')'))
             CHGVAR     VAR(%BIN(&CMDPARM 1 2)) VALUE(2000)

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
