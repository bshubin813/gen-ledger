/* ================================================================= */
/* Object:         HRTVSTS         *PGM CLP                          */
/*                 Rerieves the libraries into which products &and   */
/*                 utility are installed                             */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20020513 FK  Initial delivery                                     */
/* 20030710 FK  Return either iCluster or HA Suite, not both         */
/* 20061208 FK  If wanted, return all TS libraries in library list   */
/* 20070424 FK  Also return TS library list if only 1 library checkd */
/* 20070504 FK  Return iCluster product user and subsystem           */
/* 20071116 FK  If iCluster user does not exist, default to DMCLUSTER*/
/*              Retrieve iC user from job description                */
/* 20110811 FK  Use different object for iCluster                    */
/* 20111217 FK  Remove HA and CDC                                    */
/* ================================================================= */
             PGM        PARM(&UTILLIB &ICLIB +
                        &ICUSER &ICSBSD)

/*           Declare parameter variables                              */
             DCL        VAR(&UTILLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICUSER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICSBSD) TYPE(*CHAR) LEN(10)

/*           Declare constants                                        */

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')

             DCL        VAR(&UTILLIB@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICUSER@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICSBSD@) TYPE(*CHAR) LEN(10)

             DCL        VAR(&DMCREGQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&DMCREG) TYPE(*CHAR) LEN(1000)
             DCL        VAR(&RSLPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&ENDPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&RAWSBSD) TYPE(*CHAR) LEN(21)

             DCL        VAR(&JOBDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JOBD0100) TYPE(*CHAR) LEN(2048)
             DCL        VAR(&RCVLEN) TYPE(*CHAR) LEN(4)

/*           Declare file                                             */

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Find DMXtras library in library list                    */
             RTVOBJD    OBJ(DMXHA) OBJTYPE(*MENU) RTNLIB(&UTILLIB@)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CHGVAR     VAR(&UTILLIB@) VALUE(*NONE)
             ENDDO

/*           Find iCluster library in library list                   */
             RTVOBJD    OBJ(DMCLUSTER) OBJTYPE(*DTAARA) RTNLIB(&ICLIB@)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CHGVAR     VAR(&ICLIB@) VALUE('*NONE')
             ENDDO

/*           Retrieve iCluster user and subsystem from DMCREG        */
             IF         COND(&ICLIB@ *NE '*NONE') THEN(DO)
              CHGVAR     VAR(&ICUSER@) VALUE('*NONE')
              CHGVAR     VAR(&ICSBSD@) VALUE('*NONE')
/*            Check existence of DMCREG in iCluster library          */
              CHKOBJ     OBJ(&ICLIB@/DMCREG) OBJTYPE(*USRSPC)
              MONMSG     MSGID(CPF9801) EXEC(DO) /* DMCREG not found */
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(EICRTV)
              ENDDO
/*            Retrieve entire string in DMCREG user space            */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CHGVAR     VAR(&DMCREGQ) VALUE('DMCREG    ' || &ICLIB@)
              CALL       PGM(QUSRTVUS) PARM(&DMCREGQ X'00000001' +
                          X'000003E8' &DMCREG &APIERR)
/*            Scan for DEF_SBSD string to find subsystem             */
              CALL       PGM(QCLSCAN) PARM(&DMCREG X'999F' X'001F' +
                          'DEF_SBSD' X'008F' '0' '0' ' ' &RSLPOS)
/*            If string found, derive subsystem name and library     */
              IF         COND(&RSLPOS > 0) THEN(DO)
               CHGVAR     VAR(&STRPOS) VALUE(&RSLPOS + 8)
               CHGVAR     VAR(&RAWSBSD) VALUE(%SST(&DMCREG &STRPOS 21))
/*             Strip off any trailing nulls                          */
               CALL       PGM(QCLSCAN) PARM(&RAWSBSD X'021F' X'001F' +
                          X'00' X'001F' '0' '0' ' ' &RSLPOS)
               IF         COND(&RSLPOS > 1) THEN(DO)
                CHGVAR     VAR(&ENDPOS) VALUE(&RSLPOS - 1)
                CHGVAR     VAR(&RAWSBSD) VALUE(%SST(&RAWSBSD 1 &ENDPOS))
               ENDDO
/*             Find subsystem name in string                         */
               CALL       PGM(QCLSCAN) PARM(&RAWSBSD X'021F' X'002F' +
                          '/' X'001F' '0' '0' ' ' &RSLPOS)
               IF         COND(&RSLPOS > 0) THEN(DO)
                CHGVAR     VAR(&STRPOS) VALUE(&RSLPOS + 1)
                CHGVAR     VAR(&ICSBSD@) VALUE(%SST(&RAWSBSD &STRPOS 10))
               ENDDO
              ENDDO      /* DEF_SBSD string found */
/*            Obtain user from CSTCPJOBD job description             */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CHGVAR     VAR(&JOBDQ) VALUE('CSTCPJOBD ' || &ICLIB@)
              CHGVAR     VAR(%BIN(&RCVLEN)) VALUE(2048)
              CALL       PGM(QWDRJOBD) PARM(&JOBD0100 &RCVLEN +
                          'JOBD0100' &JOBDQ &APIERR)
              CHGVAR     VAR(&ICUSER@) VALUE(%SST(&JOBD0100 29 10))
/*            If user not found, default                             */
 EICRTV:      IF         COND(&ICUSER@ *EQ '*NONE' *OR &ICUSER@ *EQ ' +
                          ') THEN(CHGVAR VAR(&ICUSER@) +
                          VALUE('DMCLUSTER'))
/*            If retrieved iCluster user doesn't exist, default      */
              CHKOBJ     OBJ(&ICUSER@) OBJTYPE(*USRPRF)
              MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&ICUSER@) +
                          VALUE('DMCLUSTER'))
/*            If subsystem not found in registry, default            */
              IF         COND(&ICSBSD@ *EQ '*NONE') THEN(CHGVAR +
                          VAR(&ICSBSD@) VALUE('XDMCLUSTER'))
             ENDDO

/*           Return values                                           */
             CHGVAR     VAR(&UTILLIB) VALUE(&UTILLIB@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&ICLIB) VALUE(&ICLIB@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&ICUSER) VALUE(&ICUSER@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGVAR     VAR(&ICSBSD) VALUE(&ICSBSD@)
             MONMSG     MSGID(MCH3601) EXEC(RCVMSG MSGTYPE(*LAST))

             GOTO       CMDLBL(END)

/* ----------------------------------------------------------------- */
/*           Error handling                                          */
/* ----------------------------------------------------------------- */
/*           Ensure that the program does not loop when error        */
 ERROR:      IF         COND(&ERROR) THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&ERROR) VALUE('1')

/*           Move all *DIAG messages to the previous queue           */
             CHGVAR     VAR(&APIERR) VALUE(X'00000000')
             CALL       PGM(QMHMOVPM) PARM(' ' '*DIAG     *ESCAPE' +
                          X'00000002' '*' X'00000001' &APIERR)

 END:        ENDPGM
