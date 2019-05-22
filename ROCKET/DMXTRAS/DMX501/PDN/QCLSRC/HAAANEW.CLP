/* ================================================================= */
/* Object:         HAAANEW         *PGM CLP                          */
/*                 Command processing program for HAAANEW.           */
/*                                                                   */
/* Synopsis:       See Command.                                      */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000411 FK  Initial delivery                                     */
/* 20000510 FK  Make sure that objects have the proper owner         */
/* 20000510 FK  Support TS                                           */
/* 20000702 FK  Support iCluster                                     */
/* 20000705 FK  DO copy the QLFSRC file to the customer library      */
/* 20001202 FK  Service table entry for hstrha                       */
/* 20010102 FK  Service table entry for hmonevl                      */
/* 20010314 FK  Service table entry for tstrts                       */
/* 20010316 FK  User profile for TSTRTS job description              */
/* 20010906 FK  Check for activity before allowing upgrade           */
/* 20011113 FK  Always set PF size and CCSID                         */
/* 20011115 FK  Always replace HSTRSOS2                              */
/* 20011128 FK  Keep values for the H###NEW command                  */
/* 20020516 FK  Do not allow upgrade of HATOOLS                      */
/*              First save to save file                              */
/* 20020530 FK  If ANZJRNTP/ANZJRNTP2 empty --> copy in defaults     */
/* 20020531 FK  If no dependent products --> change jobq to QBATCH   */
/*              Fixed job queue per product                          */
/* 20020531 FK  Library list not changed upon install                */
/* 20020612 FK  Do not copy back DMX* data areas                     */
/* 20020829 FK  Fail if save did not complete normally               */
/*              Check *ALLOBJ, *SECADM and *IOSYSCFG special auth.   */
/* 20021227 FK  Rename to HAAANEW for code page compatibility        */
/*              Delete obsolete objects at the beginning             */
/*              Remove DMXTRAS base library from library list        */
/* 20030207 FK  Only skip objects compiled from CUSLIB               */
/* 20030418 FK  SAVFEXIT must have USEADPAUT(*NO)                    */
/* 20030603 FK  Job description job queue not always changed         */
/*              Add reference to QGY to iCluster CSJOBD job descr.   */
/* 20030710 FK  Change job description user to proper user if        */
/*              iCluster                                             */
/* 20030725 FK  Install from objects in QTEMP                        */
/*              Delete HAAANEW command, file and programs afterwards */
/* 20030728 FK  Install from objects in install library (&INSLIB)    */
/*              Allow deletion of &OLDLIB and &INSLIB                */
/*              Customer messages are no longer retained             */
/* 20031010 FK  Submit installation with *CURRENT initial libl       */
/* 20040519 FK  Correct jobq and user for TS according to DMTCPJOBD  */
/*              Set command defaults for HCFGAJE for iCluster/TS     */
/* 20040604 FK  QGY must be set according to existence               */
/* 20041108 FK  Change to code page 37 if 65535                      */
/* 20041218 FK  Replace HMONEVL parameter by HMONHA                  */
/* 20050106 FK  Work from DMXOBJ file                                */
/* 20050124 FK  Do not copy back empty file                          */
/*              Do not try to move if object does not exist          */
/* 20050302 FK  Allow to specify modules to install                  */
/* 20050707 FK  Always submit with CCSID 37                          */
/* 20050714 FK  Change HSNDCMD2 to USEADPAUT(*NO)                    */
/* 20060421 FK  Change command defaults for HDLTJRNRCV               */
/* 20060428 FK  DMXTRASOBJ replaced by DMXvrmOBJ                     */
/* 20070121 FK  Retain jobd library lists                            */
/*              Change H* jobd jobq queue if HA/iC not installed     */
/* 20070125 FK  Set command defaults based on HA/iC installation     */
/* 20070424 FK  Set command defaults for HLSTJRN and HWRKJRN         */
/* 20070504 FK  Override iCluster user if QA installation            */
/* 20070516 FK  Write DMXtras in iCluster system values              */
/* 20070521 FK  Customer library cannot be base library              */
/* 20070607 FK  Install fails when new install for iCluster          */
/* 20070810 FK  Owner of DMXtras objects for TS is D_MIRROR          */
/* 20070821 FK  Service table entry for tmonts                       */
/* 20070919 FK  Default TS subsystem for HCFGAJE if TS installed     */
/*              HSETAUT command default to ICGROUP(*ALL) for iC      */
/* 20071024 FK  Allow to specify CCSID                               */
/* 20071118 FK  Make sure DMTCPJOBD holds DMXtras library in libl    */
/* 20111212 FK  Remove HA Suite and CDC                              */
/* ================================================================= */
             PGM        PARM(&CUSLIB &OLDLIB &INSLIB &ICLIB &UTLLIB +
                          &BATCH &HMONHA &CCSID &MODULES)

/*           Declare parameter variables                             */
             DCL        VAR(&CUSLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OLDLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&INSLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&BATCH) TYPE(*CHAR) LEN(4)
             DCL        VAR(&HMONHA) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&MODULES) TYPE(*CHAR) LEN(42)
             DCL        VAR(&CCSID) TYPE(*DEC) LEN(5 0)

/*           Declare program variables                               */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&NEWCUS) TYPE(*LGL) VALUE('0')
             DCL        VAR(&EXSOBJ) TYPE(*LGL) VALUE('0')
             DCL        VAR(&CUSOBJ) TYPE(*LGL) VALUE('0')
             DCL        VAR(&SRCFL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CUROWNER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&NEWOWNER) TYPE(*CHAR) LEN(10) +
                          VALUE(QSECOFR)
             DCL        VAR(&CHGDATE) TYPE(*CHAR) LEN(13)

             DCL        VAR(&JOBD0100) TYPE(*CHAR) LEN(2048)
             DCL        VAR(&JOBDQ) TYPE(*CHAR) LEN(20)
             DCL        VAR(&JOBQ) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBQL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&RQSDTA) TYPE(*CHAR) LEN(256)
             DCL        VAR(&RQSDTAL) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&RQSDTAO) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&INLLIBL) TYPE(*CHAR) LEN(275)
             DCL        VAR(&INLLIBLL) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&INLLIBLO) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&INLLIBLN) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&RCVLEN) TYPE(*CHAR) LEN(4)
             DCL        VAR(&JOBDUSER) TYPE(*CHAR) LEN(10)

             DCL        VAR(&PRDUSER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICUSER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICSBSD) TYPE(*CHAR) LEN(10)

             DCL        VAR(&CMD) TYPE(*CHAR) LEN(512)
             DCL        VAR(&QCCSID) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&QCHRID) TYPE(*CHAR) LEN(20)

             DCL        VAR(&HAAANEW) TYPE(*CHAR) LEN(2000)
             DCL        VAR(&HMONHA@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CCSID@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CCSIDX) TYPE(*CHAR) LEN(10)

             DCL        VAR(&HATOOLS) TYPE(*LGL) VALUE('0')
             DCL        VAR(&OBJSEL) TYPE(*LGL)

             DCL        VAR(&USRPRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&GRPPRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SPCAUT) TYPE(*CHAR) LEN(100)
             DCL        VAR(&STRPOS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&POS) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)

             DCL        VAR(&ALLOBJ) TYPE(*LGL) VALUE('0')
             DCL        VAR(&SECADM) TYPE(*LGL) VALUE('0')
             DCL        VAR(&IOSYSCFG) TYPE(*LGL) VALUE('0')

             DCL        VAR(&USER) TYPE(*CHAR) LEN(10)
             DCL        VAR(&JOBTYP) TYPE(*CHAR) LEN(1)

             DCL        VAR(&ICVER) TYPE(*CHAR) LEN(6)
             DCL        VAR(&QGYLIB) TYPE(*CHAR) LEN(10)

             DCL        VAR(&MSGID) TYPE(*CHAR) LEN(7)
             DCL        VAR(&MSGRPY) TYPE(*CHAR) LEN(1)
             DCL        VAR(&NBRCURRCD) TYPE(*DEC) LEN(10 0)

             DCL        VAR(&NBRMOD) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&MODLEN) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&MODULES@) TYPE(*CHAR) LEN(100)
             DCL        VAR(&MOD@) TYPE(*CHAR) LEN(40)
             DCL        VAR(&CURMOD) TYPE(*CHAR) LEN(4)

             DCL        VAR(&VERSION) TYPE(*CHAR) LEN(6)
             DCL        VAR(&VRM) TYPE(*CHAR) LEN(3)
             DCL        VAR(&OBJLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SRCLIB) TYPE(*CHAR) LEN(10)

/*           Declare file                                            */
             DCLF       FILE(DMXOBJ)

/*           Global monitor                                          */
             MONMSG     MSGID(CPF0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Initialisation                                          */
             RTVJOBA    USER(&USER) TYPE(&JOBTYP)
             RTVDTAARA  DTAARA(DMXVERSION (9 6)) RTNVAR(&VERSION)
             CHGVAR     VAR(&VRM) VALUE(%SST(&VERSION 2 1) |< +
                          %SST(&VERSION 4 1) |< %SST(&VERSION 6 1))
             CHGVAR     VAR(&OBJLIB) VALUE('DMX' |< &VRM |< 'OBJ')
             CHGVAR     VAR(&SRCLIB) VALUE('DMX' |< &VRM |< 'SRC')

/*           Check MODULES parameter and extract values              */
             CHGVAR     VAR(&NBRMOD) VALUE(%BIN(&MODULES 1 2))
             CHGVAR     VAR(&I) VALUE(1)
 CHKMOD:     IF         COND(&I *LE &NBRMOD) THEN(DO)
              CHGVAR     VAR(&STRPOS) VALUE(((&I - 1) * 4) + 3)
              CHGVAR     VAR(&CURMOD) VALUE(%SST(&MODULES &STRPOS 4))
              IF         COND(&MODULES@ *EQ ' ') THEN(CHGVAR +
                          VAR(&MODULES@) VALUE(&CURMOD))
              ELSE       CMD(CHGVAR VAR(&MODULES@) VALUE(&MODULES@ |> +
                          &CURMOD))
/*            If *ALL somewhere in the list, fix MODULES parameter   */
              IF         COND(&CURMOD *EQ '*ALL') THEN(DO)
               CHGVAR     VAR(&NBRMOD) VALUE(1)
               CHGVAR     VAR(%BIN(&MODULES 1 2)) VALUE(&NBRMOD)
               CHGVAR     VAR(%SST(&MODULES 3 40)) VALUE('*ALL')
               CHGVAR     VAR(&MODULES@) VALUE('*ALL')
              ENDDO
              CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(CHKMOD)
             ENDDO
             CHGVAR     VAR(&MODLEN) VALUE(&NBRMOD * 4)
             CHGVAR     VAR(&MOD@) VALUE(%SST(&MODULES 3 &MODLEN))

/*           Convert numeric port numbers to alphanumeric            */
             IF         COND(&HMONHA *NE 0) THEN(CHGVAR +
                          VAR(&HMONHA@) VALUE(&HMONHA))
             ELSE       CMD(CHGVAR VAR(&HMONHA@) VALUE('*NONE'))

/*           HAAANEW command must be prompted!                       */
             IF         COND(&OLDLIB *EQ '*NOPROMPT') THEN(SNDPGMMSG +
                          MSGID(AAA0009) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Customer library cannot be base library                 */
             IF         COND(&CUSLIB *EQ &UTLLIB) THEN(SNDPGMMSG +
                          MSGID(AAA0015) MSGF(HAUMSG) +
                          MSGDTA(&CUSLIB || &UTLLIB) MSGTYPE(*ESCAPE))

/*           Does the iCluster library exist?                        */
             IF         COND(&ICLIB *NE '*NONE') THEN(CHKOBJ +
                          OBJ(&ICLIB) OBJTYPE(*LIB))

/*           Does the user have proper authority to install?         */
             RTVUSRPRF  RTNUSRPRF(&USRPRF)
 CHKAUT:     RTVUSRPRF  USRPRF(&USRPRF) SPCAUT(&SPCAUT) GRPPRF(&GRPPRF)
             CHGVAR     VAR(&I) VALUE(1)
 LOOPAUT:    IF         COND(&I *LE 10) THEN(DO)
              CHGVAR     VAR(&STRPOS) VALUE((&I -1) * 10 + 1)
              IF         COND(%SST(&SPCAUT &STRPOS 10) *EQ '*ALLOBJ') +
                          THEN(CHGVAR VAR(&ALLOBJ) VALUE('1'))
              IF         COND(%SST(&SPCAUT &STRPOS 10) *EQ '*SECADM') +
                          THEN(CHGVAR VAR(&SECADM) VALUE('1'))
              IF         COND(%SST(&SPCAUT &STRPOS 10) *EQ +
                          '*IOSYSCFG') THEN(CHGVAR VAR(&IOSYSCFG) +
                          VALUE('1'))
              CHGVAR     VAR(&I) VALUE(&I + 1)
              GOTO       CMDLBL(LOOPAUT)
             ENDDO
/*           If not all three special authorities, check group or err*/
             IF         COND(*NOT &ALLOBJ *OR *NOT &SECADM *OR *NOT +
                          &IOSYSCFG) THEN(DO)
              IF         COND(&GRPPRF *NE '*NONE') THEN(DO)
               CHGVAR     VAR(&USRPRF) VALUE(&GRPPRF)
               GOTO       CMDLBL(CHKAUT)
              ENDDO
              SNDPGMMSG  MSGID(AAA0016) MSGF(HAUMSG) MSGTYPE(*ESCAPE)
             ENDDO

/*           Does the customised library already exist?              */
             CHKOBJ     OBJ(&CUSLIB) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              CHGVAR     VAR(&NEWCUS) VALUE('1')
             ENDDO

/*           Check existence of old version library                  */
 CHKOLD:     IF         COND(*NOT &NEWCUS) THEN(DO)
              CHKOBJ     OBJ(&OLDLIB) OBJTYPE(*LIB)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(ECHKOLD)
              ENDDO
              SNDPGMMSG  MSGID(AAA0001) MSGF(HAUMSG) MSGDTA(&OLDLIB) +
                          TOPGMQ(*SAME) MSGTYPE(*DIAG)
              SNDUSRMSG  MSGID(AAA0001) MSGF(HAUMSG) MSGDTA(&OLDLIB) +
                          MSGTYPE(*INQ) MSGRPY(&MSGRPY)
              IF         COND(&MSGRPY *EQ 'G') THEN(DO)
               SNDPGMMSG  MSGID(AAA0020) MSGF(HAUMSG) MSGDTA(&OLDLIB) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
               DLTLIB     LIB(&OLDLIB)
               GOTO       CMDLBL(CHKOLD)
              ENDDO
              IF         COND(&MSGRPY *EQ 'C') THEN(SNDPGMMSG +
                          MSGID(AAA0018) MSGF(HAUMSG) MSGTYPE(*ESCAPE))
 ECHKOLD:    ENDDO

/*           Check existence of installation library                 */
 CHKINS:     CHKOBJ     OBJ(&INSLIB) OBJTYPE(*LIB)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              GOTO       CMDLBL(BATCH)
             ENDDO
             SNDPGMMSG  MSGID(AAA0019) MSGF(HAUMSG) MSGDTA(&INSLIB) +
                          TOPGMQ(*SAME) MSGTYPE(*DIAG)
             SNDUSRMSG  MSGID(AAA0019) MSGF(HAUMSG) MSGDTA(&INSLIB) +
                          MSGTYPE(*INQ) MSGRPY(&MSGRPY)
             IF         COND(&MSGRPY *EQ 'G') THEN(DO)
              SNDPGMMSG  MSGID(AAA0020) MSGF(HAUMSG) MSGDTA(&INSLIB) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
              DLTLIB     LIB(&INSLIB)
              GOTO       CMDLBL(CHKINS)
             ENDDO
             IF         COND(&MSGRPY *EQ 'C') THEN(SNDPGMMSG +
                          MSGID(AAA0018) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Submit command to batch?                                */
 BATCH:      IF         COND(&BATCH *EQ '*YES' *AND &JOBTYP *NE '0') +
                          THEN(DO)
              ADDLIBLE   LIB(&UTLLIB)
              MONMSG     MSGID(CPF2103)
              RCVMSG     MSGTYPE(*LAST)
/*            Make up command for submit                             */
              CHGVAR     VAR(&HMONHA@) VALUE(&HMONHA)
              CHGVAR     VAR(&CCSIDX) VALUE(&CCSID)
              IF         COND(&CCSID *EQ 0) THEN(CHGVAR VAR(&CCSIDX) +
                          VALUE('*QCCSID'))
              IF         COND(&CCSID *EQ 99999) THEN(CHGVAR +
                          VAR(&CCSIDX) VALUE('*QCHRID'))
              CHGVAR     VAR(&CMD) VALUE('SBMJOB CMD(HAAANEW CUSLIB(' +
                          |< &CUSLIB |< ') OLDLIB(' |< &OLDLIB |< +
                          ') INSLIB(' |< &INSLIB |< ') ICLIB(' |< +
                          &ICLIB |< ') BATCH(*NO) HMONHA(' |< +
                          &HMONHA@ |< ') CCSID(' |< &CCSIDX |< ') +
                          MODULES(' |< &MODULES@ |< ')) +
                          JOB(HAAANEW) INLLIBL(*CURRENT)')
              CALL       PGM(QCMDEXC) PARM(&CMD 512)
/*            Remove library from libl to avoid problems             */
              RMVLIBLE   LIB(&UTLLIB)
              RCVMSG     MSGTYPE(*LAST)
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP' X'00000001' +
                          '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Check if no processes active anymore                    */
             IF         COND(*NOT &NEWCUS) THEN(DO)
 ALCHMONHA:   CHKOBJ     OBJ(&CUSLIB/HMONHA) OBJTYPE(*DTAARA)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(ALCHSTRHA)
              ENDDO
              ALCOBJ     OBJ((&CUSLIB/HMONHA *DTAARA *EXCL)) WAIT(1)
              MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(AAA0008) +
                          MSGF(HAUMSG) MSGDTA('HMONHA    ' || +
                          &CUSLIB) MSGTYPE(*ESCAPE))
              DLCOBJ     OBJ((&CUSLIB/HMONHA *DTAARA *EXCL))
 ALCHSTRHA:   CHKOBJ     OBJ(&CUSLIB/HSTRHA) OBJTYPE(*DTAARA)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(ALCHSTRHAR)
              ENDDO
              ALCOBJ     OBJ((&CUSLIB/HSTRHA *DTAARA *EXCL)) WAIT(1)
              MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(AAA0008) +
                          MSGF(HAUMSG) MSGDTA('HSTRHA    ' || +
                          &CUSLIB) MSGTYPE(*ESCAPE))
              DLCOBJ     OBJ((&CUSLIB/HSTRHA *DTAARA *EXCL))
 ALCHSTRHAR:  CHKOBJ     OBJ(&CUSLIB/HSTRHAR) OBJTYPE(*DTAARA)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               GOTO       CMDLBL(ENDALC)
              ENDDO
              ALCOBJ     OBJ((&CUSLIB/HSTRHAR *DTAARA *EXCL)) WAIT(1)
              MONMSG     MSGID(CPF0000) EXEC(SNDPGMMSG MSGID(AAA0008) +
                          MSGF(HAUMSG) MSGDTA('HSTRHAR   ' || +
                          &CUSLIB) MSGTYPE(*ESCAPE))
              DLCOBJ     OBJ((&CUSLIB/HSTRHAR *DTAARA *EXCL))
 ENDALC:     ENDDO

/*           Create temp lib, save current version                   */
             IF         COND(*NOT &NEWCUS) THEN(DO)
              CRTLIB     LIB(&OLDLIB) TYPE(*TEST) TEXT('Old customer +
                          version of DMXtras')
/*            Save current customised library to save file           */
              CRTSAVF    FILE(&OLDLIB/&CUSLIB) TEXT('Saved version of +
                          customer DMXtras')
              SNDPGMMSG  MSGID(AAA0012) MSGF(HAUMSG) MSGDTA(&CUSLIB +
                          || &OLDLIB) TOPGMQ(*EXT) MSGTYPE(*STATUS)
              SNDPGMMSG  MSGID(AAA0012) MSGF(HAUMSG) MSGDTA(&CUSLIB +
                          || &OLDLIB) TOPGMQ(*SAME) MSGTYPE(*INFO)
              SAVLIB     LIB(&CUSLIB) DEV(*SAVF) +
                          SAVF(&OLDLIB/&CUSLIB) TGTRLS(*CURRENT) +
                          SAVACT(*LIB) DTACPR(*YES)
             ENDDO

/*           Determine CCSIDs to change PFs, handle special values   */
             RTVSYSVAL  SYSVAL(QCCSID) RTNVAR(&QCCSID)
             RTVSYSVAL  SYSVAL(QCHRID) RTNVAR(&QCHRID)
             IF         COND(&CCSID *EQ 0) THEN(CHGVAR VAR(&CCSID) +
                          VALUE(&QCCSID))
             IF         COND(&CCSID *EQ 99999) THEN(CHGVAR +
                          VAR(&CCSID) VALUE(%SST(&QCHRID 16 5)))
             CHGVAR     VAR(&CCSID@) VALUE(&CCSID)

/*           Determine iCluster user and subsystem                   */
             IF         COND(&ICLIB *NE '*NONE') THEN(DO)
              CHGVAR     VAR(&ICUSER) VALUE(&ICLIB)
              CHGVAR     VAR(&ICSBSD) VALUE(&ICLIB)
              CHKOBJ     OBJ(&ICLIB/&ICSBSD) OBJTYPE(*SBSD)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               CHGVAR     VAR(&ICUSER) VALUE('DMCLUSTER')
               CHGVAR     VAR(&ICSBSD) VALUE('XDMCLUSTER')
              ENDDO
             ENDDO

/*           Restore objects to be installed into &INSLIB            */
             SNDPGMMSG  MSGID(AAA0021) MSGF(HAUMSG) MSGDTA(&INSLIB) +
                          TOPGMQ(*EXT) MSGTYPE(*STATUS)
             SNDPGMMSG  MSGID(AAA0021) MSGF(HAUMSG) MSGDTA(&INSLIB) +
                          TOPGMQ(*SAME) MSGTYPE(*INFO)
             CRTLIB     LIB(&INSLIB) TYPE(*TEST) TEXT('Temporary +
                          DMXtras library for install')
             RSTOBJ     OBJ(*ALL) SAVLIB(&OBJLIB) DEV(*SAVF) +
                          SAVF(&UTLLIB/&OBJLIB) RSTLIB(&INSLIB)

/*           If customised library doesn't exist --> create          */
             IF         COND(&NEWCUS) THEN(DO)
              CRTLIB     LIB(&CUSLIB) TEXT('DMXtras -- Customised +
                          version')
             ENDDO

/*           Send status message                                     */
             IF         COND(&NEWCUS) THEN(CHGVAR VAR(&MSGID) +
                          VALUE('AAA0005'))
             ELSE       CMD(CHGVAR VAR(&MSGID) VALUE('AAA0010'))
             SNDPGMMSG  MSGID(&MSGID) MSGF(HAUMSG) MSGDTA(&UTLLIB || +
                          &CUSLIB) TOPGMQ(*EXT) MSGTYPE(*STATUS)
             SNDPGMMSG  MSGID(&MSGID) MSGF(HAUMSG) MSGDTA(&UTLLIB || +
                          &CUSLIB) TOPGMQ(*SAME) MSGTYPE(*INFO)

/*           Keep values in the HAAANEW data area                    */
             CHGVAR     VAR(%SST(&HAAANEW 1 10)) VALUE(' ')
             CHGVAR     VAR(%SST(&HAAANEW 11 10)) VALUE(' ')
             CHGVAR     VAR(%SST(&HAAANEW 21 10)) VALUE(&ICLIB)
             CHGVAR     VAR(%SST(&HAAANEW 31 5)) VALUE(' ')
             CHGVAR     VAR(%SST(&HAAANEW 36 5)) VALUE(&HMONHA@)
             CHGVAR     VAR(%SST(&HAAANEW 41 5)) VALUE(' ')
             CHGVAR     VAR(%SST(&HAAANEW 46 10)) VALUE(' ')
             CHGVAR     VAR(%SST(&HAAANEW 101 40)) VALUE(&MOD@)
             CHGVAR     VAR(%SST(&HAAANEW 141 5)) VALUE(' ')
             CHGVAR     VAR(%SST(&HAAANEW 146 5)) VALUE(&CCSID@)
             CHGDTAARA  DTAARA(&CUSLIB/HAAANEW) VALUE(&HAAANEW)
             MONMSG     MSGID(CPF1015) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CRTDTAARA  DTAARA(&CUSLIB/HAAANEW) TYPE(*CHAR) +
                          LEN(2000) VALUE(&HAAANEW) TEXT('HAAANEW - +
                          Parameter values upon installation')
             ENDDO
             IF         COND(&ICLIB *NE '*NONE') THEN(CHGVAR +
                          VAR(&NEWOWNER) VALUE(&ICUSER))
/*           If owner doesn't exist, revert to QSECOFR               */
             CHKOBJ     OBJ(&NEWOWNER) OBJTYPE(*USRPRF)
             MONMSG     MSGID(CPF0000) EXEC(DO)
              CHGVAR     VAR(&NEWOWNER) VALUE('QSECOFR')
             ENDDO

/*           Read all records in the DMXOBJ file                     */
 LOOP:       RCVF
             MONMSG     MSGID(CPF0864) EXEC(GOTO CMDLBL(ELOOP))

/*           Retrieve the current object's description               */
 RTV:        IF         COND(*NOT &NEWCUS) THEN(DO)
              CHGVAR     VAR(&EXSOBJ) VALUE('1')
              RTVOBJD    OBJ(&CUSLIB/&DOOBJNAM) OBJTYPE(&DOOBJTYP) +
                          OWNER(&CUROWNER) CHGDATE(&CHGDATE) +
                          SRCFLIB(&SRCFL)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&SRCFL) VALUE(' ')
               CHGVAR     VAR(&EXSOBJ) VALUE('0')
               CHGVAR     VAR(&CUSOBJ) VALUE('0')
               GOTO       CMDLBL(ERTV)
              ENDDO
/*            Determine if object has been customised                */
              CHGVAR     VAR(&CUSOBJ) VALUE('0')
              IF         COND(&SRCFL *EQ &CUSLIB *AND &DOCUSOBJ *EQ +
                          '*YES') THEN(DO)
               SNDPGMMSG  MSGID(AAA0002) MSGF(HAUMSG) MSGDTA(&DOOBJNAM +
                          || &CUSLIB || &DOOBJTYP || &UTLLIB) +
                          MSGTYPE(*DIAG)
               IF         COND(&JOBTYP *EQ '0') THEN(SNDPGMMSG +
                          MSGID(AAA0002) MSGF(HAUMSG) +
                          MSGDTA(&DOOBJNAM || &CUSLIB || &DOOBJTYP +
                          || &UTLLIB) TOUSR(&USER) MSGTYPE(*DIAG))
               CHGVAR     VAR(&CUSOBJ) VALUE('1')
              ENDDO
 ERTV:       ENDDO

/*           If not customised object --> manage changes             */
             IF         COND(*NOT &CUSOBJ) THEN(DO)
/*            Move the existing object to the old version library    */
 MOVE:        IF         COND(&EXSOBJ) THEN(DO)
               MOVOBJ     OBJ(&CUSLIB/&DOOBJNAM) OBJTYPE(&DOOBJTYP) +
                          TOLIB(&OLDLIB)
               MONMSG     MSGID(CPF0000) EXEC(DO)
                RCVMSG     MSGTYPE(*LAST)
                CHGVAR     VAR(&EXSOBJ) VALUE('0')
               ENDDO
              ENDDO

/*            Must object be selected?                               */
              CHGVAR     VAR(&OBJSEL) VALUE('0')
              IF         COND(&DOUTLID *NE '*OBSOLETE') THEN(DO)
/*             Check for supported products                          */
               IF         COND(&DOSUPPRD *NE '*ALL' *AND &DOSUPPRD *NE +
                          ' ') THEN(DO)
                CHGVAR     VAR(&I) VALUE(1)
 LOOPSUP:       IF         COND(&I *LE 4) THEN(DO)
                 CHGVAR     VAR(&STRPOS) VALUE(((&I - 1) * 3) + 1)
                 IF         COND(%SST(&DOSUPPRD &STRPOS 3) *EQ '*IC' +
                          *AND &ICLIB *NE '*NONE') THEN(CHGVAR +
                          VAR(&OBJSEL) VALUE('1'))
                 CHGVAR     VAR(&I) VALUE(&I + 1)
                 GOTO       CMDLBL(LOOPSUP)
                ENDDO
               ENDDO
               ELSE       CMD(CHGVAR VAR(&OBJSEL) VALUE('1'))
/*             Check for modules to install                          */
               IF         COND(&OBJSEL *AND &DODMXMOD *NE '*ALL' *AND +
                          &DODMXMOD *NE ' ' *AND &MOD@ *NE '*ALL') +
                          THEN(DO)
                CHGVAR     VAR(&OBJSEL) VALUE('0')
                CHGVAR     VAR(&I) VALUE(1)
 LOOPMOD:       IF         COND(&I *LE &NBRMOD *AND *NOT &OBJSEL) THEN(DO)
                 CHGVAR     VAR(&STRPOS) VALUE(((&I - 1) * 4) + 3)
                 CHGVAR     VAR(&CURMOD) VALUE(%SST(&MODULES &STRPOS 4))
                 CALL       PGM(QCLSCAN) PARM(&DODMXMOD X'064F' X'001F' +
                          &CURMOD X'004F' '0' '0' ' ' &POS)
                 IF         COND(&POS *NE 0) THEN(CHGVAR VAR(&OBJSEL) +
                          VALUE('1'))
                 CHGVAR     VAR(&I) VALUE(&I + 1)
                 GOTO       CMDLBL(LOOPMOD)
                ENDDO
               ENDDO
              ENDDO

/*            If object selected --> create new object               */
              IF         COND(&OBJSEL) THEN(DO)
/*             Move new object into customer DMXtras library         */
               MOVOBJ     OBJ(&INSLIB/&DOOBJNAM) OBJTYPE(&DOOBJTYP) +
                          TOLIB(&CUSLIB)
/*             Change the owner of the object                        */
               IF         COND(&EXSOBJ) THEN(CHGOBJOWN +
                          OBJ(&CUSLIB/&DOOBJNAM) OBJTYPE(&DOOBJTYP) +
                          NEWOWN(&CUROWNER))
               IF         COND(*NOT &EXSOBJ) THEN(CHGOBJOWN +
                          OBJ(&CUSLIB/&DOOBJNAM) OBJTYPE(&DOOBJTYP) +
                          NEWOWN(&NEWOWNER))
/*             In case of a physical file --> change size to *NOMAX  */
               IF         COND(&DOOBJATR *EQ 'PF') THEN(DO)
                CHGPF      FILE(&CUSLIB/&DOOBJNAM) SIZE(*NOMAX)
                MONMSG     MSGID(CPF0000)
                CHGPF      FILE(&CUSLIB/&DOOBJNAM) CCSID(&CCSID)
                MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
               ENDDO
/*             In case of a job description --> adjust job queue      */
/*               and job user                                         */
               IF         COND(&DOOBJTYP *EQ '*JOBD') THEN(DO)
/*              Determine defaults dependent on product               */
                IF         COND(&ICLIB *NE '*NONE') THEN(DO)
                 CHGVAR     VAR(&PRDUSER) VALUE('*RQD')
                 IF         COND(%SST(&DOOBJNAM 1 1) *EQ 'H' *AND &ICLIB +
                          *NE '*NONE') THEN(DO)
                  CHGVAR     VAR(&PRDUSER) VALUE(&ICUSER)
                  CHGVAR     VAR(&JOBQ) VALUE('DMCLUSTER')
                  CHGVAR     VAR(&JOBQL) VALUE(&ICLIB)
                 ENDDO
                ENDDO
                ELSE       CMD(DO)
                 CHGVAR     VAR(&JOBQ) VALUE('QBATCH')
                 CHGVAR     VAR(&JOBQL) VALUE('*LIBL')
                ENDDO
/*              Change job description user if not *RQD               */
                CHGVAR     VAR(&APIERR) VALUE(X'00000000')
                CHGVAR     VAR(&JOBDQ) VALUE(&DOOBJNAM || &CUSLIB)
                CHGVAR     VAR(%BIN(&RCVLEN)) VALUE(2048)
                CALL       PGM(QWDRJOBD) PARM(&JOBD0100 &RCVLEN +
                          'JOBD0100' &JOBDQ &APIERR)
                CHGVAR     VAR(&JOBDUSER) VALUE(%SST(&JOBD0100 29 10))
                IF         COND(&JOBDUSER *NE '*RQD') THEN(DO)
                 CHGJOBD    JOBD(&CUSLIB/&DOOBJNAM) USER(&PRDUSER)
                 MONMSG     MSGID(CPF0000)
                ENDDO
/*              Change job queue                                      */
                CHGJOBD    JOBD(&CUSLIB/&DOOBJNAM) JOBQ(&JOBQL/&JOBQ)
                MONMSG     MSGID(CPF0000)
/*              Set initial library list                             */
                CHGVAR     VAR(&CMD) VALUE('CHGJOBD JOBD(' |< &CUSLIB +
                          |< '/' |< &DOOBJNAM |< ') INLLIBL(QTEMP' |> +
                          &CUSLIB)
                IF         COND(&ICLIB *NE '*NONE') THEN(CHGVAR +
                          VAR(&CMD) VALUE(&CMD |> &ICLIB))
                CHGVAR     VAR(&CMD) VALUE(&CMD |< ')')
                CALL       PGM(QCMDEXC) PARM(&CMD 512)
                MONMSG     MSGID(CPF0000)
               ENDDO
/*             Command                                               */
               IF         COND(&DOOBJTYP *EQ '*CMD') THEN(DO)
                CHGCMD     CMD(&CUSLIB/&DOOBJNAM) PRDLIB(&CUSLIB)
               ENDDO
/*             Menu                                                  */
               IF         COND(&DOOBJTYP *EQ '*MENU') THEN(DO)
                CHGMNU     MENU(&CUSLIB/&DOOBJNAM) PRDLIB(&CUSLIB)
               ENDDO
/*             Replaced object --> return information                 */
               IF         COND(&EXSOBJ) THEN(DO)
/*              In case of variable physical file --> copy back rcds  */
                IF         COND(&DOOBJATR *EQ 'PF' *AND &DOOBJNAM *NE +
                          'QLFSRC' *AND %SST(&DOOBJNAM 1 4) *NE +
                          'HEXM' *AND %SST(&DOOBJNAM 1 4) *NE +
                          'TEXM' *AND %SST(&DOOBJNAM 1 8) *NE +
                          'ANZJRNTP' *AND %SST(&DOOBJNAM 1 6) *NE +
                          'DMXOBJ') THEN(DO)
                 RTVMBRD    FILE(&OLDLIB/&DOOBJNAM) NBRCURRCD(&NBRCURRCD)
                 MONMSG     MSGID(CPF0000) EXEC(CHGVAR VAR(&NBRCURRCD) +
                          VALUE(0))
                 IF         COND(&NBRCURRCD *NE 0) THEN(DO)
                  CPYF       FROMFILE(&OLDLIB/&DOOBJNAM) +
                          TOFILE(&CUSLIB/&DOOBJNAM) MBROPT(*REPLACE) +
                          FMTOPT(*MAP *DROP)
                  MONMSG     MSGID(CPF0000)
                 ENDDO
                ENDDO
/*              In case of a data area --> duplicate object back      */
                IF         COND(&DOOBJTYP *EQ '*DTAARA' *AND %SST(&DOOBJNAM +
                          1 3) *NE 'DMX') THEN(DO)
                 DLTDTAARA  DTAARA(&CUSLIB/&DOOBJNAM)
                 CRTDUPOBJ  OBJ(&DOOBJNAM) FROMLIB(&OLDLIB) +
                          OBJTYPE(*DTAARA) TOLIB(&CUSLIB)
                 CHGOBJOWN  OBJ(&CUSLIB/&DOOBJNAM) OBJTYPE(&DOOBJTYP) +
                          NEWOWN(&NEWOWNER)
                ENDDO
/*              In case of a job description --> retain request data  */
                IF         COND(&DOOBJTYP *EQ '*JOBD') THEN(DO)
                 CHGVAR     VAR(&APIERR) VALUE(X'00000000')
                 CHGVAR     VAR(&JOBDQ) VALUE(&DOOBJNAM || &OLDLIB)
                 CHGVAR     VAR(%BIN(&RCVLEN)) VALUE(2048)
                 CALL       PGM(QWDRJOBD) PARM(&JOBD0100 &RCVLEN +
                          'JOBD0100' &JOBDQ &APIERR)
                 CHGVAR     VAR(&RQSDTAO) VALUE(%BIN(&JOBD0100 369 4) + 1)
                 CHGVAR     VAR(&RQSDTAL) VALUE(%BIN(&JOBD0100 373 4))
                 CHGVAR     VAR(&RQSDTA) VALUE(%SST(&JOBD0100 &RQSDTAO +
                          &RQSDTAL))
                 CHGJOBD    JOBD(&CUSLIB/&DOOBJNAM) RQSDTA(&RQSDTA)
                 MONMSG     MSGID(CPF0000)
/*               Retain initial library list too                      */
                 CHGVAR     VAR(&INLLIBLO) VALUE(%BIN(&JOBD0100 361 4) + 1)
                 CHGVAR     VAR(&INLLIBLN) VALUE(%BIN(&JOBD0100 365 4))
                 CHGVAR     VAR(&INLLIBLL) VALUE(&INLLIBLN * 11)
                 IF         COND(&INLLIBLL *EQ 0) THEN(CHGVAR +
                          VAR(&INLLIBL) VALUE('*NONE'))
                 ELSE       CMD(CHGVAR VAR(&INLLIBL) +
                          VALUE(%SST(&JOBD0100 &INLLIBLO &INLLIBLL)))
/*               Ensure that ICLIB is in library list of jobd        */
                 IF         COND(&ICLIB *NE '*NONE' *AND &INLLIBLN *GE 1 +
                          *AND &INLLIBLN *LT 25) THEN(DO)
                  CALL       PGM(QCLSCAN) PARM(&INLLIBL X'275F' X'001F' +
                          &ICLIB X'010F' '0' '0' ' ' &POS)
                  IF         COND(&POS *EQ 0) THEN(DO)
                   CHGVAR     VAR(&INLLIBL) VALUE(&INLLIBL |> &ICLIB)
                   CHGVAR     VAR(&INLLIBLN) VALUE(&INLLIBLN + 1)
                  ENDDO
                 ENDDO
                 CHGVAR     VAR(&CMD) VALUE('CHGJOBD JOBD(' |< &CUSLIB +
                          |< '/' |< &DOOBJNAM |< ') INLLIBL(' |< +
                          &INLLIBL |< ')')
                 CALL       PGM(QCMDEXC) PARM(&CMD 512)
                 MONMSG     MSGID(CPF0000)
                ENDDO
               ENDDO      /* Existing object */
              ENDDO      /* Object selected */
/*            Delete object from old version library                 */
              IF         COND(&EXSOBJ) THEN(DO)
               CALL       PGM(HAAANEW1) PARM(&OLDLIB &DOOBJNAM &DOOBJTYP)
              ENDDO
             ENDDO      /* Customised object */

             GOTO       CMDLBL(LOOP)

 ELOOP:      IF         COND(&ICLIB *NE '*NONE') THEN(DO)
/*            Now set library list of job descriptions in iCluster   */
              CHGVAR     VAR(&QGYLIB) VALUE('QGY')
              CHKOBJ     OBJ(&QGYLIB) OBJTYPE(*LIB)
              MONMSG     MSGID(CPF9801) EXEC(CHGVAR VAR(&QGYLIB) +
                          VALUE('*N'))
              IF         COND(&QGYLIB *EQ '*N') THEN(CHGJOBD +
                          JOBD(&ICLIB/CSJOBD) INLLIBL(&ICLIB +
                          &CUSLIB QGPL QTEMP))
              IF         COND(&QGYLIB *NE '*N') THEN(CHGJOBD +
                          JOBD(&ICLIB/CSJOBD) INLLIBL(&ICLIB +
                          &CUSLIB &QGYLIB QGPL QTEMP))
              CHGJOBD    JOBD(&ICLIB/CSTCPJOBD) INLLIBL(&ICLIB +
                          &CUSLIB QGPL QTEMP)
/*            Change system value for iCluster to point to DMXtras   */
              RTVDTAARA  DTAARA(&ICLIB/HAPACKID (1 6)) RTNVAR(&ICVER)
              MONMSG     MSGID(CPF0000)
              IF         COND(&ICVER *GE 'iC 5.0') THEN(DO)
               CHGDTAARA  DTAARA(&ICLIB/DM_SYSVALS (210 10)) +
                          VALUE(&CUSLIB)
               MONMSG     MSGID(CPF0000)
              ENDDO
/*            Replace save file exit program in iCluster             */
              DLTPGM     PGM(&ICLIB/SAVFEXIT)
              MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
              CRTDUPOBJ  OBJ(SAVFEXIT) FROMLIB(&CUSLIB) OBJTYPE(*PGM) +
                          TOLIB(&ICLIB)
              CHGOBJOWN  OBJ(&ICLIB/SAVFEXIT) OBJTYPE(*PGM) +
                          NEWOWN(&ICUSER)
              CHGPGM     PGM(&ICLIB/SAVFEXIT) USEADPAUT(*NO)
/*            Set command defaults for several commands              */
              CHGCMDDFT  CMD(&CUSLIB/HCFGAJE) NEWDFT('SBSD(' |< +
                          &ICSBSD |< ')')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HDLTJRNRCV) NEWDFT('CHKIC(*YES)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HLSTJRN) NEWDFT('CHKIC(*YES)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HWRKJRN) NEWDFT('CHKIC(*YES)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HLSTCST) +
                          NEWDFT('TARGET(*ICLUSTER) ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HLSTTRG) +
                          NEWDFT('TARGET(*ICLUSTER) ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HCHKSYNTGT) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HDSPSYNTGT) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HSETAUT) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HLSTCFG) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HMRKPOS) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HSETPOS) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HSETPOS) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HSNDCMD) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
              CHGCMDDFT  CMD(&CUSLIB/HSTRAPY) NEWDFT('ICGROUP(*ALL)')
              MONMSG     MSGID(CPF0000)
/*            Add service table entry for hmonha                     */
              IF         COND(&HMONHA *NE 0) THEN(DO)
               ADDSRVTBLE SERVICE('hmonha') PORT(&HMONHA) +
                          PROTOCOL('tcp') TEXT('HMONHA Monitoring +
                          service')
               MONMSG     MSGID(TCP0000)
              ENDDO
             ENDDO

/*           Change some programs to USEADPAUT(*NO)                  */
             CHGPGM     PGM(&CUSLIB/HSNDCMD2) USEADPAUT(*NO)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Program HCHKSYNTGT must have USRPRF(*OWNER)             */
             CHGPGM     PGM(&CUSLIB/HCHKSYNTGT) USRPRF(*OWNER) +
                          USEADPAUT(*YES)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Program HSTRCST/HENDCST must have USRPRF(*OWNER)        */
             CHGPGM     PGM(&CUSLIB/HSTRCST) USRPRF(*OWNER)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
             CHGPGM     PGM(&CUSLIB/HENDCST) USRPRF(*OWNER)
             MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))

/*           Delete HAAANEW* objects from customer library           */
             CALL       PGM(HAAANEW1) PARM(&CUSLIB 'HAAANEW*' '*ALL')

/*           Delete installation library                             */
             DLTLIB     LIB(&INSLIB)
             MONMSG     MSGID(CPF0000)

/*           Send completion message                                 */
             IF         COND(*NOT &NEWCUS) THEN(SNDPGMMSG +
                          MSGID(AAA0003) MSGF(HAUMSG) +
                          MSGDTA(&CUSLIB || &UTLLIB || &OLDLIB) +
                          MSGTYPE(*COMP))
             IF         COND(*NOT &NEWCUS *AND &JOBTYP *EQ '0') +
                          THEN(SNDPGMMSG MSGID(AAA0003) +
                          MSGF(HAUMSG) MSGDTA(&CUSLIB || &UTLLIB || +
                          &OLDLIB) TOUSR(&USER) MSGTYPE(*COMP))
             IF         COND(&NEWCUS) THEN(SNDPGMMSG MSGID(AAA0004) +
                          MSGF(HAUMSG) MSGDTA(&CUSLIB || &UTLLIB) +
                          MSGTYPE(*COMP))
             IF         COND(&NEWCUS *AND &JOBTYP *EQ '0') +
                          THEN(SNDPGMMSG MSGID(AAA0004) +
                          MSGF(HAUMSG) MSGDTA(&CUSLIB || &UTLLIB) +
                          TOUSR(&USER) MSGTYPE(*COMP))

/*           Retain job log of installation                          */
             DSPJOBLOG  OUTPUT(*PRINT)

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
