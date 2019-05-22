/* ================================================================= */
/* Object:         HCHKSYNTGT      *PGM CLP                          */
/*                 Checks the synchronisation for a target           */
/*                 definition.                                       */
/*                                                                   */
/* Create remarks: CRTCLPGM USRPRF(*OWNER)                           */
/*                                                                   */
/* Synopsis:                                                         */
/*                                                                   */
/* ----------------------------------------------------------------- */
/*                  Changes made to this source                      */
/*                  ---------------------------                      */
/*                                                                   */
/* Date     Who Description                                          */
/* -------- --- ---------------------------------------------------- */
/* 20000227 FK  Initial delivery                                     */
/* 20000410 FK  Create with USRPRF(*OWNER)                           */
/*              Job name is <ID>                                     */
/* 20000422 FK  Make sure that HA Suite is current library           */
/* 20000613 FK  Only send source files to target                     */
/* 20000705 FK  Build LFs over HA Suite files for diff. releases     */
/* 20001011 FK  Handle excludes                                      */
/* 20001013 FK  Optionally suspend apply job                         */
/*              Include group                                        */
/* 20001203 FK  Check for replication lag                            */
/*              Scope exclusions by group                            */
/*              Authority check is optional                          */
/* 20010226 FK  Always submit for HASUITE user profile               */
/* 20010404 FK  Remove replication lag                               */
/*              Allow for output file                                */
/* 20010514 FK  Allow for delay time in sending files from source    */
/* 20010809 FK  Include query for non-existing/not-mirrored libaries */
/* 20010906 FK  Fix error in library handling                        */
/* 20011221 FK  Allow setting of authorities after finished          */
/* 20020110 FK  Execute through save file user exit                  */
/*              Remove target utilities library                      */
/* 20020425 FK  Also pass SETAUT parameter on SBMJOB                 */
/* 20020523 FK  Allow check for IFS object specifiers                */
/* 20020820 FK  HCHKSYNTGT fails if QSH not on system                */
/* 20021112 FK  Allow ignore interval.                               */
/*              Redesign of Synchronisation check                    */
/* 20021204 FK  QSH is no longer a requirement                       */
/* 20030115 FK  Prevent running on target system                     */
/* 20030220 FK  Send sensible message when waiting for file arrival  */
/*              Allocate files sent from source system (wait)        */
/* 20030425 FK  Also accept if submitted by user DMCLUSTER           */
/* 20030505 FK  Enable for iCluster                                  */
/*              Resequence parameters                                */
/* 20030512 FK  Library report optional                              */
/* 20030626 FK  Submit job with DEV(*JOBD) to allow for printing     */
/* 20030710 FK  Change TARGET/GROUP back to TGTNAM/GRPNAM            */
/* 20031010 FK  Allow for target release (save files)                */
/* 20031208 FK  Pass role to HCHKSYN3                                */
/* 20050210 FK  New parameters: Backup node & check member           */
/* 20050214 FK  Submit job for each group, wait until complete       */
/* 20050216 FK  Only *ALLUSR libraries                               */
/* 20050324 FK  Include &UTLLIB in save file text                    */
/* 20050422 FK  Change sequence of BCKNOD parameter                  */
/* 20050510 FK  IFS authorities                                      */
/* 20051006 FK  Concurrent sync checks fail even if different ID     */
/* 20060206 FK  Group selection by marking string                    */
/* 20060327 FK  Include QSYS in library descriptions                 */
/* 20070121 FK  Depend running on backup system on data area instead */
/*              of HLSTCFGO                                          */
/* 20070504 FK  Allow for different iCluster user                    */
/* 20070919 FK  Allow sending reports by e-mail                      */
/* 20081111 FK  Libraries starting with Q show up as non-existing    */
/* 20111217 FK  Remove HA                                            */
/* ================================================================= */
             PGM        PARM(&ICGROUP &SAVFLIB &OUTFILE &SETAUT +
                          &IGNITV &BCKNOD &EMLRPT &SYNID &CHKMBR +
                          &CHKIFS &CHKAUT &CHKLIB &SUSAPY &SNDDLY +
                          &MRKSTR &TGTRLS)

/*           Declare parameter variables                              */
             DCL        VAR(&ICGROUP) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OUTFILE) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SETAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&IGNITV) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&BCKNOD) TYPE(*CHAR) LEN(8)
             DCL        VAR(&EMLRPT) TYPE(*CHAR) LEN(6)
             DCL        VAR(&SYNID) TYPE(*CHAR) LEN(5)
             DCL        VAR(&CHKMBR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKIFS) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKAUT) TYPE(*CHAR) LEN(4)
             DCL        VAR(&CHKLIB) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SUSAPY) TYPE(*CHAR) LEN(4)
             DCL        VAR(&SNDDLY) TYPE(*DEC) LEN(3 0)
             DCL        VAR(&MRKSTR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&TGTRLS) TYPE(*CHAR) LEN(8)

/*           Declare program variables                                */
             DCL        VAR(&APIERR) TYPE(*CHAR) LEN(4)
             DCL        VAR(&ERROR) TYPE(*LGL) VALUE('0')
             DCL        VAR(&JOBTYPE) TYPE(*CHAR) LEN(1)
             DCL        VAR(&RTNCDE) TYPE(*CHAR) LEN(7)

             DCL        VAR(&UTLLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&ICLIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&HAROLE) TYPE(*CHAR) LEN(1)

             DCL        VAR(&TGTSTS) TYPE(*CHAR) LEN(10)

             DCL        VAR(&LIBDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&OBJAF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&MBRDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSDF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&IFSAF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CFGGF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CFGOF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&CFGIF) TYPE(*CHAR) LEN(10)

             DCL        VAR(&SYNF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SYNFG) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFLIB@) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFCFG) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SAVFFIL) TYPE(*CHAR) LEN(10)

             DCL        VAR(&WAIT) TYPE(*LGL)
             DCL        VAR(&SYNPAR) TYPE(*CHAR) LEN(1024)

             DCL        VAR(&USRPRF) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SNDDLYM) TYPE(*DEC) LEN(5 0)

             DCL        VAR(&TGTSTS) TYPE(*CHAR) LEN(10)
             DCL        VAR(&APYEND) TYPE(*LGL) VALUE('0')

             DCL        VAR(&IGNITV@) TYPE(*CHAR) LEN(5)
             DCL        VAR(&PRD) TYPE(*CHAR) LEN(3)
             DCL        VAR(&MSGDTA) TYPE(*CHAR) LEN(256)
             DCL        VAR(&MSGID) TYPE(*CHAR) LEN(7)
             DCL        VAR(&JOBNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&SCJOBNAM) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SCJOBUSR) TYPE(*CHAR) LEN(10)
             DCL        VAR(&SCJOBNBR) TYPE(*CHAR) LEN(6)
             DCL        VAR(&NBRJOB) TYPE(*DEC) LEN(5 0)
             DCL        VAR(&NBRJOB@) TYPE(*CHAR) LEN(4)
             DCL        VAR(&I) TYPE(*DEC) LEN(3 0)

             DCL        VAR(&NBRCURRCD) TYPE(*DEC) LEN(10 0)

             DCL        VAR(&ICUSER) TYPE(*CHAR) LEN(10)

/*           Declare file                                             */
             DCLF       FILE(HLSTCFGG)

/*           Global monitor                                           */
             MONMSG     MSGID(CPF0000 CST0000) EXEC(GOTO CMDLBL(ERROR))

/* ----------------------------------------------------------------- */
/*           Main line                                               */
/* ----------------------------------------------------------------- */

/*           Determine product that sync check runs for              */
             CHGVAR     VAR(&PRD) VALUE('*IC')

/*           Determine synchronisation ID                            */
             IF         COND(&SYNID *EQ '*TGT' *AND &PRD *EQ '*IC' +
                          *AND &ICGROUP *EQ '*ALL') THEN(CHGVAR +
                          VAR(&SYNID) VALUE('CLUST'))
             IF         COND(&SYNID *EQ '*TGT' *AND &PRD *EQ '*IC' +
                          *AND &ICGROUP *EQ '*MRKSTR') THEN(DO)
              CHGVAR     VAR(&I) VALUE(1)
              CHGVAR     VAR(&SYNID) VALUE(' ')
 LOOPMRK:     IF         COND(&I *LE 4) THEN(DO)
               IF         COND(%SST(&MRKSTR &I 1) *GE 'A' *AND +
                          %SST(&MRKSTR &I 1) *LE '9') THEN(CHGVAR +
                          VAR(&SYNID) VALUE(&SYNID |< %SST(&MRKSTR +
                          &I 1)))
               CHGVAR     VAR(&I) VALUE(&I + 1)
               GOTO       CMDLBL(LOOPMRK)
              ENDDO
              IF         COND(&SYNID *EQ ' ') THEN(CHGVAR VAR(&SYNID) +
                          VALUE('MRK'))
             ENDDO
             IF         COND(&SYNID *EQ '*TGT' *AND &PRD *EQ '*IC' +
                          *AND &ICGROUP *NE '*ALL' *AND &ICGROUP +
                          *NE '*MRKSTR') THEN(DO)
              CHGVAR     VAR(&I) VALUE(1)
              CHGVAR     VAR(&SYNID) VALUE(' ')
 LOOPGRS:     IF         COND(&I *LE 10) THEN(DO)
               IF         COND(%SST(&ICGROUP &I 1) *GE 'A' *AND +
                          %SST(&ICGROUP &I 1) *LE '9') THEN(CHGVAR +
                          VAR(&SYNID) VALUE(&SYNID |< %SST(&ICGROUP +
                          &I 1)))
               CHGVAR     VAR(&I) VALUE(&I + 1)
               GOTO       CMDLBL(LOOPGRS)
              ENDDO
              IF         COND(&SYNID *EQ ' ') THEN(CHGVAR VAR(&SYNID) +
                          VALUE('GROUP'))
             ENDDO

/*           Initialisation                                          */
             CHGVAR     VAR(&SYNF) VALUE('HS' |< &SYNID)
             CHGVAR     VAR(&SYNFG) VALUE(&SYNF |< 'S*')
             CHGVAR     VAR(&SAVFCFG) VALUE(&SYNF *TCAT 'VCF')
             CHGVAR     VAR(&SAVFFIL) VALUE(&SYNF *TCAT 'VFL')
             CHGVAR     VAR(&IGNITV@) VALUE(&IGNITV)

/*           Retrieve HA Suite/iCluster product libraries            */
             HRTVPRDLIB UTILLIB(&UTLLIB) ICPRODLIB(&ICLIB) +
                          ICUSER(&ICUSER)

/*           HA Suite or iCluster must be in library list            */
             IF         COND(&ICLIB *EQ '*NONE') THEN(SNDPGMMSG +
                          MSGID(DMX0012) MSGF(HAUMSG) MSGTYPE(*ESCAPE))

/*           Check existence of save file library                    */
             IF         COND(&SAVFLIB *NE '*SNDOBJ') THEN(CHKOBJ +
                          OBJ(&SAVFLIB) OBJTYPE(*LIB))

/*           If executed interactively --> submit to batch           */
             RTVJOBA    TYPE(&JOBTYPE) CURUSER(&USRPRF)
             IF         COND(&JOBTYPE *EQ '1' *OR (&PRD *EQ '*IC' +
                          *AND &USRPRF *NE &ICUSER)) THEN(DO)
              CHGVAR     VAR(&USRPRF) VALUE(&ICUSER)
              SBMJOB     CMD(HCHKSYNTGT ICGROUP(&ICGROUP) +
                          SAVFLIB(&SAVFLIB) OUTFILE(&OUTFILE) +
                          SETAUT(&SETAUT) IGNITV(&IGNITV) +
                          BCKNOD(&BCKNOD) EMLRPT(&EMLRPT) +
                          SYNID(&SYNID) CHKMBR(&CHKMBR) +
                          CHKIFS(&CHKIFS) CHKAUT(&CHKAUT) +
                          CHKLIB(&CHKLIB) SUSAPY(&SUSAPY) +
                          SNDDLY(&SNDDLY) MRKSTR(&MRKSTR) +
                          TGTRLS(&TGTRLS)) JOB(&SYNF) +
                          JOBD(HCHKSYNTGT) PRTDEV(*JOBD) +
                          USER(&USRPRF) INLLIBL(*JOBD)
/*            Move *COMP message to previous queue                   */
              CHGVAR     VAR(&APIERR) VALUE(X'00000000')
              CALL       PGM(QMHMOVPM) PARM(' ' '*COMP     ' +
                          X'00000001' '*' X'00000001' &APIERR)
              GOTO       CMDLBL(END)
             ENDDO

/*           Make sure that iCluster is current library              */
 NOSBM:      CHGCURLIB  CURLIB(&ICLIB)

/*           Determine save file library                             */
             IF         COND(&SAVFLIB *EQ '*SNDOBJ') THEN(CHGVAR +
                          VAR(&SAVFLIB@) VALUE(&UTLLIB))
             ELSE       CMD(CHGVAR VAR(&SAVFLIB@) VALUE(&SAVFLIB))

/*           If configuration file already exists in QTEMP -->       */
/*            this is the secondary system, else build               */
             CHGVAR     VAR(&HAROLE) VALUE('S')
             CHKOBJ     OBJ(QTEMP/HCHKSYNCFG) OBJTYPE(*DTAARA)
             MONMSG     MSGID(CPF9801) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              CHGVAR     VAR(&HAROLE) VALUE('P')
             ENDDO

/*           If primary system --> Retrieve and send configuration   */
             IF         COND(&HAROLE *EQ 'P') THEN(DO)
/*            List configuration for specified group                 */
              HLSTCFG    ICGROUP(&ICGROUP) BCKNOD(&BCKNOD) +
                          MRKSTR(&MRKSTR)
/*            If no groups listed --> end with error                 */
              RTVMBRD    FILE(QTEMP/HLSTCFGG) MBR(*FIRST) +
                          NBRCURRCD(&NBRCURRCD)
              IF         COND(&NBRCURRCD *EQ 0) THEN(SNDPGMMSG +
                          MSGID(CST0016) MSGF(HAUMSG) +
                          MSGDTA(&ICGROUP || &MRKSTR) MSGTYPE(*ESCAPE))
/*            If backup node *FIRST --> Retrieve node name           */
              IF         COND(&BCKNOD *EQ '*FIRST') THEN(DO)
               CALL       PGM(HCHKSYN7) PARM(&BCKNOD)
              ENDDO
/*            Create data area with configuration information        */
              CHGVAR     VAR(&SYNPAR) VALUE('          ' || +
                          '          ' || &ICGROUP || &BCKNOD || +
                          &CHKMBR || &CHKIFS || &CHKAUT || &CHKLIB +
                          || &SUSAPY || &OUTFILE || &SYNID || +
                          &SETAUT || &IGNITV@ || &SAVFLIB || +
                          &UTLLIB || &MRKSTR || &EMLRPT)
              CRTDTAARA  DTAARA(QTEMP/HCHKSYNCFG) TYPE(*CHAR) +
                          LEN(1024) VALUE(&SYNPAR) TEXT('HCHKSYNTGT +
                          - Parameters for secondary system')
/*            Create save file with configuration to be sent         */
              CRTSAVF    FILE(QTEMP/&SAVFCFG) TEXT('HCHKSYNTGT CFG ' +
                          || &UTLLIB || ' - Configuration')
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              SAVOBJ     OBJ(HCHKSYNCFG HLSTCFG*) LIB(QTEMP) +
                          DEV(*SAVF) OBJTYPE(*DTAARA *FILE) +
                          SAVF(QTEMP/&SAVFCFG) TGTRLS(&TGTRLS) +
                          CLEAR(*ALL) DTACPR(*YES)
/*            Move save file to location where it is replicated      */
              DLTF       FILE(&SAVFLIB@/&SAVFCFG)
              MONMSG     MSGID(CPF0000)
              MOVOBJ     OBJ(QTEMP/&SAVFCFG) OBJTYPE(*FILE) +
                          TOLIB(&SAVFLIB@)
/*            Send save file to target if *SNDOBJ                    */
              IF         COND(&SAVFLIB *EQ '*SNDOBJ') THEN(DMSNDOBJ +
                          TGTNODE(&BCKNOD) OBJ(&SAVFLIB@/&SAVFCFG) +
                          OBJTYPE(*FILE))
             ENDDO

/*           Suspend apply jobs?                                     */
             IF         COND(&HAROLE *EQ 'S' *AND &SUSAPY *EQ +
                          '*YES') THEN(DO)
              HRTVSTS    ICGROUP(&ICGROUP) PRCTYP(*APY) STATUS(&TGTSTS)
/*            Now wait until apply jobs have stopped                 */
              IF         COND(&TGTSTS *EQ '*ACTIVE') THEN(DO)
               SNDPGMMSG  MSGID(CST0001) MSGF(HAUMSG) MSGDTA(&ICGROUP)
               HENDAPY    ICGROUP(&ICGROUP) WAIT(*YES)
               CHGVAR     VAR(&APYEND) VALUE('1')
              ENDDO
             ENDDO

/*           Copy configuration to utility library for use sbm job   */
             CHGVAR     VAR(&CFGGF) VALUE(&SYNF |< 'CG')
             CHGVAR     VAR(&CFGOF) VALUE(&SYNF |< 'CO')
             CHGVAR     VAR(&CFGIF) VALUE(&SYNF |< 'CI')
             DLTF       FILE(&UTLLIB/&CFGGF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(&UTLLIB/&CFGOF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(&UTLLIB/&CFGIF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HLSTCFGG) FROMLIB(QTEMP) OBJTYPE(*FILE) +
                          TOLIB(&UTLLIB) NEWOBJ(&CFGGF) DATA(*YES)
             CRTDUPOBJ  OBJ(HLSTCFGO) FROMLIB(QTEMP) OBJTYPE(*FILE) +
                          TOLIB(&UTLLIB) NEWOBJ(&CFGOF) DATA(*YES)
             CRTDUPOBJ  OBJ(HLSTCFGI) FROMLIB(QTEMP) OBJTYPE(*FILE) +
                          TOLIB(&UTLLIB) NEWOBJ(&CFGIF) DATA(*YES)

/*           Determine names of output files                         */
             IF         COND(&HAROLE *EQ 'P') THEN(DO)
              CHGVAR     VAR(&LIBDF) VALUE(&SYNF |< 'SL')
              CHGVAR     VAR(&OBJDF) VALUE(&SYNF |< 'SO')
              CHGVAR     VAR(&OBJAF) VALUE(&SYNF |< 'SA')
              CHGVAR     VAR(&MBRDF) VALUE(&SYNF |< 'SM')
              CHGVAR     VAR(&IFSDF) VALUE(&SYNF |< 'SI')
              CHGVAR     VAR(&IFSAF) VALUE(&SYNF |< 'SJ')
              DLTF       FILE(&UTLLIB/(&SYNF *TCAT 'S*'))
              MONMSG     MSGID(CPF0000)
             ENDDO
             IF         COND(&HAROLE *EQ 'S') THEN(DO)
              CHGVAR     VAR(&OBJDF) VALUE(&SYNF |< 'TO')
              CHGVAR     VAR(&OBJAF) VALUE(&SYNF |< 'TA')
              CHGVAR     VAR(&MBRDF) VALUE(&SYNF |< 'TM')
              CHGVAR     VAR(&IFSDF) VALUE(&SYNF |< 'TI')
              CHGVAR     VAR(&IFSAF) VALUE(&SYNF |< 'TJ')
              DLTF       FILE(&UTLLIB/(&SYNF *TCAT 'T*'))
              MONMSG     MSGID(CPF0000)
             ENDDO

/*           Prepare files in utilities library                      */
             IF         COND(&HAROLE *EQ 'P') THEN(DO)
              CPYF       FROMFILE(&UTLLIB/HCHKSYNLD) +
                          TOFILE(&UTLLIB/&LIBDF) CRTFILE(*YES)
              MONMSG     MSGID(CPF0000)
              CLRPFM     FILE(&UTLLIB/&LIBDF)
              RCVMSG     MSGTYPE(*LAST)
             ENDDO
             DLTF       FILE(&UTLLIB/&OBJDF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HCHKSYNOD) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&OBJDF) DATA(*NO)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(&UTLLIB/&OBJAF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HCHKSYNOA) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&OBJAF) DATA(*NO)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(&UTLLIB/&MBRDF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HCHKSYNMD) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&MBRDF) DATA(*NO)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(&UTLLIB/&IFSDF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HCHKSYNID) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&IFSDF) DATA(*NO)
             MONMSG     MSGID(CPF0000)
             DLTF       FILE(&UTLLIB/&IFSAF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             CRTDUPOBJ  OBJ(HCHKSYNIA) FROMLIB(&UTLLIB) +
                          OBJTYPE(*FILE) TOLIB(&UTLLIB) +
                          NEWOBJ(&IFSAF) DATA(*NO)
             MONMSG     MSGID(CPF0000)

/*           Retrieve library descriptions                           */
             IF         COND(&HAROLE *EQ 'P' *AND &CHKLIB *EQ +
                          '*YES') THEN(DO)
              DSPOBJD    OBJ(*ALL) OBJTYPE(*LIB) DETAIL(*FULL) +
                          OUTPUT(*OUTFILE) OUTFILE(QTEMP/HCHKTMPLD)
              CPYF       FROMFILE(QTEMP/HCHKTMPLD) +
                          TOFILE(&UTLLIB/&LIBDF) MBROPT(*ADD) +
                          FMTOPT(*MAP *DROP)
              DLTF       FILE(QTEMP/HCHKTMPLD)
             ENDDO

/*           Now process all groups                                  */
             RTVJOBA    NBR(&JOBNBR)
             OVRDBF     FILE(HLSTCFGG) TOFILE(QTEMP/HLSTCFGG)
 LOOPGRP:    RCVF
             MONMSG     MSGID(CPF0864) EXEC(DO)
              RCVMSG     MSGTYPE(*LAST)
              GOTO       CMDLBL(ELOOPGRP)
             ENDDO

/*           Call program that retrieves objects for group           */
             CHGVAR     VAR(&SCJOBNAM) VALUE('HS' |< %SST(&LGGRPN 1 8))
             SBMJOB     CMD(CALL PGM(HCHKSYN0) PARM(&LGGRPN &UTLLIB +
                          &SYNF &CHKMBR &CHKAUT &CHKIFS &CHKLIB +
                          &HAROLE &RTNCDE)) JOB(&SCJOBNAM) +
                          JOBD(HCHKSYNTGT)
/*           Store submitted job info                                */
             RCVMSG     MSGTYPE(*LAST) RMV(*NO) MSGDTA(&MSGDTA) +
                          MSGID(&MSGID)
             IF         COND(&MSGID *EQ 'CPC1221') THEN(DO)
              CHGVAR     VAR(&SCJOBNAM) VALUE(%SST(&MSGDTA 1 10))
              CHGVAR     VAR(&SCJOBUSR) VALUE(%SST(&MSGDTA 11 10))
              CHGVAR     VAR(&SCJOBNBR) VALUE(%SST(&MSGDTA 21 60))
             ENDDO
             CALL       PGM(HCHKSYN0A) PARM('*ADD' &JOBNBR &SCJOBNAM +
                          &SCJOBUSR &SCJOBNBR &LGGRPN)

             GOTO       CMDLBL(LOOPGRP)

/*           Now wait until submitted jobs have completed            */
 ELOOPGRP:   SNDPGMMSG  MSGID(CST0011) MSGF(HAUMSG) TOPGMQ(*SAME)
             DLYJOB     DLY(5)
 LOOPJOB:    CALL       PGM(HCHKSYN0B) PARM(&JOBNBR &NBRJOB)
             IF         COND(&NBRJOB *NE 0) THEN(DO)
              CHGVAR     VAR(%BIN(&NBRJOB@)) VALUE(&NBRJOB)
              SNDPGMMSG  MSGID(CST0012) MSGF(HAUMSG) MSGDTA(&JOBNBR +
                          || &NBRJOB@) TOPGMQ(*SAME)
              DLYJOB     DLY(5)
              GOTO       CMDLBL(LOOPJOB)
             ENDDO

/*           Remove records from submitted job list                  */
             CALL       PGM(HCHKSYN0A) PARM('*RMV' &JOBNBR ' ' ' ' ' +
                          ' ' ')

/*           Delete configuration files                              */
             DLTF       FILE(&UTLLIB/&CFGGF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(&UTLLIB/&CFGOF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))
             DLTF       FILE(&UTLLIB/&CFGIF)
             MONMSG     MSGID(CPF2105) EXEC(RCVMSG MSGTYPE(*LAST))

/*           If primary system --> send files to target machine      */
             IF         COND(&HAROLE *EQ 'P') THEN(DO)
/*            First wait specified number of minutes                 */
              IF         COND(&SNDDLY *NE 0) THEN(DO)
               CHGVAR     VAR(&SNDDLYM) VALUE(&SNDDLY * 60)
               DLYJOB     DLY(&SNDDLYM)
              ENDDO
/*            Create save file with files to be sent                 */
              CRTSAVF    FILE(QTEMP/HCHKSYNFIL) TEXT('HCHKSYNTGT - +
                          Description files')
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              SAVOBJ     OBJ(&SYNFG) LIB(&UTLLIB) DEV(*SAVF) +
                          OBJTYPE(*FILE) SAVF(QTEMP/HCHKSYNFIL) +
                          TGTRLS(&TGTRLS) CLEAR(*ALL) DTACPR(*YES)
/*            Create save file for files and configuration           */
              CRTSAVF    FILE(QTEMP/&SAVFFIL) TEXT('HCHKSYNTGT FIL ' +
                          || &UTLLIB || ' - Files')
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              SAVOBJ     OBJ(HCHKSYNCFG HCHKSYNFIL) LIB(QTEMP) +
                          DEV(*SAVF) OBJTYPE(*FILE *DTAARA) +
                          SAVF(QTEMP/&SAVFFIL) TGTRLS(&TGTRLS) +
                          CLEAR(*ALL) DTACPR(*YES)
/*            Move save file to replicated library                   */
              DLTF       FILE(&SAVFLIB@/&SAVFFIL)
              MONMSG     MSGID(CPF0000)
              MOVOBJ     OBJ(QTEMP/&SAVFFIL) OBJTYPE(*FILE) +
                          TOLIB(&SAVFLIB@)
              IF         COND(&SAVFLIB *EQ '*SNDOBJ') THEN(DMSNDOBJ +
                          TGTNODE(&BCKNOD) OBJ(&SAVFLIB@/&SAVFFIL) +
                          OBJTYPE(*FILE))
             ENDDO

/*           If secondary system --> start apply jobs                */
             IF         COND(&HAROLE *EQ 'S' *AND &APYEND) THEN(DO)
              HSTRAPY    ICGROUP(&ICGROUP)
             ENDDO

/*           If secondary system --> await arrival and determine dsc */
             IF         COND(&HAROLE *EQ 'S') THEN(DO)
/*            Wait until source member description file arrives      */
 LOOPWAIT:    CHGVAR     VAR(&WAIT) VALUE('0')
              CHKOBJ     OBJ(&UTLLIB/('HS' |< &SYNID |< 'SL')) +
                          OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              CHKOBJ     OBJ(&UTLLIB/('HS' |< &SYNID |< 'SO')) +
                          OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              CHKOBJ     OBJ(&UTLLIB/('HS' |< &SYNID |< 'SA')) +
                          OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              CHKOBJ     OBJ(&UTLLIB/('HS' |< &SYNID |< 'SM')) +
                          OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              CHKOBJ     OBJ(&UTLLIB/('HS' |< &SYNID |< 'SI')) +
                          OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              CHKOBJ     OBJ(&UTLLIB/('HS' |< &SYNID |< 'SJ')) +
                          OBJTYPE(*FILE)
              MONMSG     MSGID(CPF9801) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              IF         COND(&WAIT) THEN(DO)
               SNDPGMMSG  MSGID(CST0009) MSGF(HAUMSG) TOPGMQ(*SAME)
               DLYJOB     DLY(15)
               GOTO       CMDLBL(LOOPWAIT)
              ENDDO
/*            Wait until lock on source files can be obtained        */
 LOOPLOCK:    CHGVAR     VAR(&WAIT) VALUE('0')
              ALCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SL') *FILE +
                          *SHRNUP *FIRST)) WAIT(15)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              ALCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SO') *FILE +
                          *SHRNUP *FIRST)) WAIT(15)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              ALCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SA') *FILE +
                          *SHRNUP *FIRST)) WAIT(15)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              ALCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SM') *FILE +
                          *SHRNUP *FIRST)) WAIT(15)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              ALCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SI') *FILE +
                          *SHRNUP *FIRST)) WAIT(15)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
              ALCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SJ') *FILE +
                          *SHRNUP *FIRST)) WAIT(15)
              MONMSG     MSGID(CPF0000) EXEC(DO)
               RCVMSG     MSGTYPE(*LAST)
               CHGVAR     VAR(&WAIT) VALUE('1')
              ENDDO
/*            Now deallocate all objects to prevent errors           */
              DLCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SL') *FILE +
                          *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SO') *FILE +
                          *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SA') *FILE +
                          *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SM') *FILE +
                          *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SI') *FILE +
                          *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
              DLCOBJ     OBJ((&UTLLIB/('HS' |< &SYNID |< 'SJ') *FILE +
                          *SHRNUP *FIRST))
              MONMSG     MSGID(CPF0000) EXEC(RCVMSG MSGTYPE(*LAST))
/*            If one of the locks could not be obtained --> wait     */
              IF         COND(&WAIT) THEN(DO)
               SNDPGMMSG  MSGID(CST0010) MSGF(HAUMSG) TOPGMQ(*SAME)
               DLYJOB     DLY(5)
               GOTO       CMDLBL(LOOPLOCK)
              ENDDO
             ENDDO

/*           Determine discrepancies and run reports                 */
             CALL       PGM(HCHKSYN4) PARM(&ICGROUP &MRKSTR &HAROLE +
                          &UTLLIB &SYNID &CHKMBR &CHKIFS &CHKAUT +
                          &CHKLIB &OUTFILE &SETAUT &IGNITV &EMLRPT)

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
