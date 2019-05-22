/* ================================================================= */
/* Object:         HCRTLF          *PGM CLP                          */
/*                 Create logical file over product library.         */
/*                                                                   */
/* Synopsis:       This program is called in order to create         */
/*                 a logical file in QTEMP over the iCluster,        */
/*                 HA Suite or TS library to prevent level checks    */
/*                 in case of slight version differences.            */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000705 FK  Initial delivery                                     */
/* 20010404 FK  Do not produce LF listing if not necessary           */
/* 20050429 FK  Place object lock on LF so physical is locked        */
/* 20060503 FK  CRTLF with LVLCHK(*NO) due to V5R3 change in calc    */
/*              of record format level ID                            */
/* 20070112 FK  Allow recreation of LF if PF library different       */
/* 20070413 FK  Override CRTLF command with SHARE(*NO) to prevent    */
/*              problems if customer has changed command defaults    */
/* 20070516 FK  Do not display status message when building path     */
/* ================================================================= */
             PGM        PARM(&LFNAM)

/*           Declare parameter variables                             */
             DCL        VAR(&LFNAM) TYPE(*CHAR) LEN(10)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PRDFILE) TYPE(*CHAR) LEN(10)
             DCL        VAR(&PFLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&LFPFLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRTEXT) TYPE(*CHAR) LEN(50)
             DCL        VAR(&RTNLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&RSLPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&STRLEN) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&LFNAMQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&LFCRT) TYPE(*LGL)
             DCL        VAR(&OBJDTA) TYPE(*CHAR) LEN(30)

             DCL        VAR(&STSMSG) TYPE(*CHAR) LEN(7)

/*           Declare file                                            */

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    STSMSG(&STSMSG)

/*           Determine the utilities library                         */
             HRTVPRDLIB UTILLIB(&UTLLIB)

/*           Retrieve the based-on PF for the LF to be created       */
             CHGVAR     VAR(&PRDFILE) VALUE(' ')
             RTVMBRD    FILE(&UTLLIB/QLFSRC) MBR(&LFNAM) TEXT(&MBRTEXT)
             CALL       PGM(QCLSCAN) PARM(&MBRTEXT X'050F' X'005F' ' +
                          ' X'001F' '0' '0' ' ' &RSLPOS)
             IF         COND(&RSLPOS > 6) THEN(DO)
              CHGVAR     VAR(&STRLEN) VALUE(&RSLPOS - 5)
              CHGVAR     VAR(&PRDFILE) VALUE(%SST(&MBRTEXT 5 &STRLEN))
              RTVOBJD    OBJ(&PRDFILE) OBJTYPE(*FILE) RTNLIB(&PFLIB)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&PFLIB) +
                          VALUE(' '))
             ENDDO

/*           Check if the logical file already exists                */
             CHGVAR     VAR(&LFCRT) VALUE('0')
             RTVOBJD    OBJ(QTEMP/&LFNAM) OBJTYPE(*FILE) +
                          USRDFNATR(&LFPFLIB)
             MONMSG     MSGID(CPF0000) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CHGVAR     VAR(&LFCRT) VALUE('1')
             ENDDO
/*           If LF is based on PF in different library, delete       */
             IF         COND(*NOT &LFCRT *AND &LFPFLIB *NE &PFLIB) +
                          THEN(DO)
              CALL       PGM(HCRTLFDLT) PARM(&LFNAM '*ALL')
              CHGVAR     VAR(&LFCRT) VALUE('1')
             ENDDO
/*           Now create LF                                           */
             IF         COND(&LFCRT) THEN(DO)
              CHGJOB     STSMSG(*NONE)
              CRTLF      FILE(QTEMP/&LFNAM) SRCFILE(&UTLLIB/QLFSRC) +
                          OPTION(*NOSRC *NOLIST) SHARE(*NO) LVLCHK(*NO)
              RMVMSG     PGMQ(*SAME) CLEAR(*ALL)
              MONMSG     MSGID(CPF0000)
              CHGJOB     STSMSG(&STSMSG)
/*            Change user-defined attribute to PF library            */
              CHGVAR     VAR(&LFNAMQ) VALUE(&LFNAM || 'QTEMP')
              CHGVAR     VAR(%BIN(&OBJDTA 1 4)) VALUE(1)
              CHGVAR     VAR(%BIN(&OBJDTA 5 4)) VALUE(9)
              CHGVAR     VAR(%BIN(&OBJDTA 9 4)) VALUE(10)
              CHGVAR     VAR(%SST(&OBJDTA 13 10)) VALUE(&PFLIB)
              CHGVAR     VAR(&APIERR) VALUE(X'00080000')
              CALL       PGM(QLICOBJD) PARM(&RTNLIB &LFNAMQ +
                          '*FILE     ' &OBJDTA &APIERR)
/*            Lock LF to allocate PF                                 */
              ALCOBJ     OBJ((QTEMP/&LFNAM *FILE *SHRRD)) SCOPE(*JOB)
              MONMSG     MSGID(CPF0000)
             ENDDO

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */

/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

             CHGJOB     STSMSG(&STSMSG)

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
