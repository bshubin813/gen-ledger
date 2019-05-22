      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HLSTJRN1        *PGM RPG                          *
      *            Builds list of journals and receivers in files    *
      *            files HLSTJRN and HLSTJRNR                        *
      *                                                              *
      * Synopsis:  See Command HLSTJRN.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20070423 FK  Initial delivery                                *
      * 20090918 FK  Ignore blank journals in the metadata           *
      * 20111217 FK  Remove HA and CDC                               *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * HA/iC - Journals being scraped
     FHUDGTJL   IF   E           K DISK    UsrOpn
      * HA/iC - Journals being received/applied (includes remote jrn)
     FHUPIDTGJR IF   E           K DISK    UsrOpn
      * HA/iC - Journals with marked positions
     FHUDSJJL   IF   E           K DISK    UsrOpn
      * List of journals
     FHLSTJRN   IF A E           K DISK
      * List of journal receivers
     FHLSTJRNR  IF A E           K DISK    UsrOpn

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D JrnStt          s              1    Dim(4) CtData
     D JrnSttNam       s             10    Dim(4) Alt(JrnStt)
     D RcvSts          s              1    Dim(5) CtData
     D RcvStsNam       s              8    Dim(5) Alt(RcvSts)
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Copy in the API data structures for Journal APIs
     D/COPY QSYSINC/QRPGLESRC,QJOURNAL
      * Copy in the API data structures for QUSROBJD
     D/COPY QSYSINC/QRPGLESRC,QUSROBJD

      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data
      * API-Error data structure for SndPgmMsg
     D SPAPIErr        DS
     D  SPBytPvd                     10i 0 Inz(%Size(SPAPIErr))                 * Bytes provided
     D  SPBytAvl                     10i 0                                      * Bytes available
     D  SPMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  SPMsgDta                    256a                                        * Message data

      * Generic header for user space
     D UsrSpc          DS                  Based(xUsrSpc)
     D  USOfsHdr                     10i 0 Overlay(UsrSpc:117)                  * Offset to header
     D  USOfsLst                     10i 0 Overlay(UsrSpc:125)                  * Offset to list sec
     D  USNbrEnt                     10i 0 Overlay(UsrSpc:133)                  * # of list entries
     D  USEntSiz                     10i 0 Overlay(UsrSpc:137)                  * Entry size

      * Generic header for user space
     D OBJL0100        DS                  Based(xObjEnt)
     D  OLObjNam                     10a   Overlay(OBJL0100:1)                  * Object name
     D  OLObjLib                     10a   Overlay(OBJL0100:11)                 * Object library
     D  OLObjTyp                     10a   Overlay(OBJL0100:21)                 * Object type

      * Journal information to retrieve
     D RtvInf          DS
     D  TINbrRcd               1      4B 0                                      * # of Records
     D  TIVarLen1              5      8B 0                                      * Var rcd length
     D  TIVarKey1              9     12B 0                                      * Var rcd key
     D  TIVarDtaL1            13     16B 0                                      * Var data length

      * Key information
     D KeyInfDS        DS         65535
     D  KIKey                  1      4B 0                                      * Key
     D  KIKeyOfs               5      8B 0                                      * Offset to key
     D  KIInfLen               9     12B 0                                      * Info header length
     D  KINbrEnt              13     16B 0                                      * Number of entries
     D  KIEntLen              17     20B 0                                      * Entry length

      * Receiver Header information
     D RcvHdrDS        DS         65535
     D  RHNbrRcv               1      4B 0                                      * # of Receivers
     D  RHTotSiz               5      8B 0                                      * Total size rcv
     D  RHTotSizMlt            9     12B 0                                      * Total size multipl
     D  RHRsv                 13     20                                         * Reserved

      * Message data
     D MsgDta          DS           500
      * Message data for LJR0001/LJR0002/LJR0003
     D  MDJrn                        10a   Overlay(MsgDta:1)                    * Journal name
     D  MDJrnL                       10a   Overlay(MsgDta:11)                   * Journal library
      * Additional message data for LJR0001
     D  MDNbrRcv                     10i 0 Overlay(MsgDta:21)                   * # of receivers
      * Additional message data for LJR0002
     D  MDMsgID                       7a   Overlay(MsgDta:21)                   * Message ID

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * Send Program Message
     D SndPgmMsg       Pr                  ExtPgm('QMHSNDPM')
     D  SPMsgID                       7a   Const                                * Message ID
     D  SPMsgF                       20a   Const                                * Message file
     D  SPMsgDta                    512a   Const Options(*Varsize)              * Message data
     D  SPMsgDtaLen                  10i 0 Const                                * Message data len
     D  SPMsgTyp                     10a   Const                                * Message type
     D  SPCllStkEnt                  10a   Const                                * Call stack entry
     D  SPCllStkCnt                  10i 0 Const                                * Call stack count
     D  SPMsgKey                      4a                                        * Message Key
     D  SPAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * List objects
     D LstObj          Pr                  ExtPgm('QUSLOBJ')
     D  LOUsrSpcQ                    20a   Const                                * User space
     D  LOFmt                         8a   Const                                * Format
     D  LOObjQ                       20a   Const                                * Qualified object
     D  LOObjTyp                     10a   Const                                * Object type
     D  LOAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * Retrieve object description
     D RtvObjD         Pr                  ExtPgm('QUSROBJD')
     D  RORcvVar                  65535a   Options(*VARSIZE)
     D  RORcvLen                     10i 0 Const
     D  ROFmt                         8a   Const                                * Format
     D  ROObjQ                       20a   Const                                * Qualified object
     D  ROObjTyp                     10a   Const                                * Object type
     D  ROAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * Create user space
     D CrtUS           Pr                  ExtPgm('QUSCRTUS')
     D  CuUsrSpcQ                    20a   Const                                * User space
     D  CUExtAtr                     10a   Const                                * Extended attribute
     D  CUIniSiz                     10i 0 Const                                * Initial size
     D  CUIniVal                      1a   Const                                * Initial value
     D  CUPubAut                     10a   Const                                * Public authority
     D  CUText                       50a   Const                                * Text description
     D  CUReplace                    10a   Const                                * Replace?
     D  CUAPIErr                  32767a         Options(*NoPass:*VarSize )

      * Retrieve pointer to user space
     D RtvPtrUS        Pr                  ExtPgm('QUSPTRUS')
     D  RPUsrSpcQ                    20a   Const
     D  RPPtr                          *
     D  RPErr                     32767a         Options(*NoPass:*VarSize )

      * Retrieve journal information
     D RtvJrnInfo      PR                  ExtProc(
     D                                     'QjoRetrieveJournalInformation')
     D  JIRcvVar                  65535A   Options(*VARSIZE)
     D  JIRcvLen                     10I 0 Const
     D  JIJrnQ                       20A   Const
     D  JIFmtNam                      8A   Const
     D  JIRtvInf                  32767A   Const                                * Info to retrieve
     D                                     Options(*VARSIZE)
     D  JIApiErr                           Like(APIERR)

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * Message values
     D #CPFMSGF        C                   CONST('QCPFMSG   *LIBL     ')
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

     D#NONE            C                   CONST('*NONE')
     D#ALL             C                   CONST('*ALL')
     D#ALLDTA          C                   CONST('*ALLDTA')
     D#OBJ             C                   CONST('*OBJ')
     D#IC              C                   CONST('*IC')
     D#YES             C                   CONST('*YES')
     D#NO              C                   CONST('*NO ')
     D#UsrSpc          C                   CONST('HLSTJRN   QTEMP     ')

      * Journal type
     D#Lcl             C                   CONST('*LOCAL')
     D#Rmt             C                   CONST('*REMOTE')

      * Journal state
     D#Inactive        C                   CONST('*INACTIVE')
     D#Active          C                   CONST('*ACTIVE')
     D#Failed          C                   CONST('*FAILED')
     D#Inactpend       C                   CONST('*INACTPEND')

      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D StrPos          s              3  0                                      * Position of string
     D GenName         s              9a                                        * Generic name
     D JrnSel          s               n                                        * Journal selected

     D JrnQPA          s             20a                                        * Journal qualified
     D JrnWY           s             10a                                        * Journal
     D JrnLWY          s             10a                                        * Journal library

     D xUsrSpc         s               *                                        * Pointer to usrspc
     D xObjEnt         s               *                                        * Ptr to Obj List en

     D RcvVar          s          65535                                         * Receiver variable

     D MsgKey          s              4a                                        * Message key
     D CurDTS          s               z                                        * Current date-time
     D i               s             10i 0                                      * Index
     D j               s             10i 0                                      * Index
     D x               s             10i 0                                      * Index

      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key to retrieve HLSTJRN
     C     ChnJrn        KList
     C                   KFld                    JrnLWY                         * Journal library
     C                   KFld                    JrnWY                          * Journal
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    JRNPA            10            * Journal
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    LSTRPA            4            * List receivers?
     C                   Parm                    PRDPA             4            * Product to list
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Open receivers file?
     C                   If        LSTRPA=#YES                                  * List receivers
     C                   Open      HLSTJRNR                                     * Receivers
     C                   EndIf                                                  * List receivers
      * Is the journal a generic name?
     C                   Clear                   GenName                        * Generic name
     C     '*'           Scan      JRNPA:1       StrPos                         * Find asteriks
     C                   if        StrPos>0
     C                   Eval      StrPos=StrPos-1
     C                   Eval      GenName=%Subst(JRNPA:1:StrPos)
     C                   EndIf
      * Execute procedure depending on product to list journals from
     C                   Select
     C                   When      PRDPA = #IC                                  * *IC
     C                   ExSR      SRLstIC
     C                   When      PRDPA = #OBJ                                 * *OBJ
     C                   ExSR      SRLstObj
     C                   EndSL
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *

      * ------------------------------------------------------------------- *
      * SRLstIC - List iCluster journals                                    *
      * ------------------------------------------------------------------- *
     C     SRLstIC       BegSR
      * Open files for iCluster
     C                   Open      HUDGTJL                                      * Active source jrn
     C                   Open      HUPIDTGJR                                    * Active target jrn
     C                   Open      HUDSJJL                                      * Marked journals
      * Process audit journal if *ALL
     C                   If        JRNPA=#ALL                                   * *ALL
     C                   Eval      JrnWY='QAUDJRN'                              * QAUDJRN
     C                   Eval      JrnLWY='QSYS'                                * QSYS
     C                   ExSR      SRPrcJrn
     C                   EndIf
      * Process all active source data journals
     C     *Loval        SetLL     HUDGTJL@
     C                   Read      HUDGTJL@                               95
     C                   DoW       not *In95
     C                   Eval      JrnWY=JRNNAME                                * Journal
     C                   Eval      JrnLWY=JRNLIB                                * Journal library
     C                   ExSR      SRPrcJrn
     C                   Read      HUDGTJL@                               95
     C                   EndDo
      * Process all marked source data journals
     C     *Loval        SetLL     HUDSJJL@
     C                   Read      HUDSJJL@                               95
     C                   DoW       not *In95
     C                   Eval      JrnWY=JRNNAME                                * Journal
     C                   Eval      JrnLWY=JRNLIB                                * Journal library
     C                   ExSR      SRPrcJrn
     C                   Read      HUDSJJL@                               95
     C                   EndDo
      * Process all active target data journals
     C     *Loval        SetLL     HUPIDTGJR@
     C                   Read      HUPIDTGJR@                             95
     C                   DoW       not *In95
     C                   If        PIDPRC='TUP'                                 * TUP process
     C                   Eval      JrnWY=JRNNAME                                * Journal
     C                   Eval      JrnLWY=JRNLIB                                * Journal library
     C                   ExSR      SRPrcJrn
     C                   EndIf                                                  * TUP process
      * If there is a remote journal involved, process too
     C                   If        RMTJRN<>#NONE                                * Remote journal
     C                   Eval      JrnWY=RMTJRN                                 * Journal
     C                   Eval      JrnLWY=RMTJRNLIB                             * Journal library
     C                   ExSR      SRPrcJrn
     C                   EndIf                                                  * Remote journal
     C                   Read      HUPIDTGJR@                             95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRLstObj - List journals by object specifier                        *
      * ------------------------------------------------------------------- *
     C     SRLstObj      BegSR
      * Process audit journal if *ALL
     C                   If        JRNPA=#ALL                                   * *ALL
     C                   Eval      JrnWY='QAUDJRN'                              * QAUDJRN
     C                   Eval      JrnLWY='QSYS'                                * QSYS
     C                   ExSR      SRPrcJrn
     C                   EndIf
      * Send status message that objects are being listed
     C                   Eval      MDJrn=JRNPA                                  * Journal name
     C                   Eval      MDJrnL=JRNLPA                                * Journal library
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('LJR0005':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#STATUS:'*EXT':0:
     C                                     MsgKey:APIErr)
      * Create user space to hold journal objects
     C                   Reset                   APIErr                         * API Error
     C                   CallP     CrtUS(#UsrSpc:'HLSTJRN':1000000:' ':
     C                                   '*ALL':'HLSTJRN - Journal objects':
     C                                   '*NO':APIErr)
      * Get pointer to user space
     C                   CallP     RtvPtrUS(#UsrSpc:xUsrSpc:APIErr)
      * List objects
     C                   Eval      JRNQPA=JRNPA+JRNLPA                          * Qualified name
     C                   If        JRNPA=#ALLDTA                                * *ALLDTA
     C                   Eval      JRNQPA='*ALL      ' + JRNLPA                 * *ALL
     C                   EndIf                                                  * *ALLDTA
     C                   CallP     LstObj(#UsrSpc:'OBJL0100':JRNQPA:'*JRN':
     C                                    APIErr)
      * If no error --> Process list entries
     C                   If        AEBytAvl=0                                   * No error
      * Retrieve offset to list section
     C                   Eval      xObjEnt=xUsrSpc+USOfsLst
      * Now process entire list of entries
     C                   Eval      j=1
     C                   DoW       j <= USNbrEnt
      * Process journal
     C                   Eval      JrnWY=OLObjNam                               * Journal
     C                   Eval      JrnLWY=OLObjLib                              * Journal library
     C                   ExSR      SRPrcJrn
      * Prepare for next loop
     C                   Eval      j=j+1
     C                   Eval      xObjEnt=xObjEnt+USEntSiz                     * Advance pointer
     C                   EndDo                                                  * Process list ent
     C                   EndIf                                                  * No error
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrcJrn - Process journal                                          *
      * ------------------------------------------------------------------- *
     C     SRPrcJrn      BegSR
     C                   Eval      JrnSel=*Off                                  * Journal selected
     C                   Select
     C                   When      JrnWY=*Blanks or JrnLWY=*Blanks              * Invalid journal
     C                   Eval      JrnSel=*Off                                  * Journal not select
     C                   When      JRNPA=#ALL                                   * *ALL specified
     C                   Eval      JrnSel=*On                                   * Journal selected
     C                   When      JRNPA=#ALLDTA and not                        * *ALLDTA
     C                             (JrnWY='QAUDJRN' and JrnLWY='QSYS')          * and not security
     C                   Eval      JrnSel=*On                                   * Journal selected
     C                   When      JrnWY=JRNPA                                  * Journal same
     C                   Eval      JrnSel=*On                                   * Journal selected
     C                   When      GenName<>*Blanks                             * Generic name
     C                   If        %Subst(JrnWY:1:StrPos)=GenName               * Generic same
     C                   Eval      JrnSel=*On                                   * Journal selected
     C                   EndIf                                                  * Generic same
     C                   EndSL
      * If journal still selected, process
     C                   If        JrnSel                                       * Journal selected
      * Only process if journal information not retrieved yet
     C     ChnJrn        SetLL     LSTJRNR                                94
     C                   If        not *In94                                    * Record not exist
      * Send status message
     C                   Eval      MDJrn=JrnWY                                  * Journal name
     C                   Eval      MDJrnL=JrnLWY                                * Journal library
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('LJR0003':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#STATUS:'*EXT':0:
     C                                     MsgKey:APIErr)
      * Always retrieve receiver info for totals
     C                   Eval      TINbrRcd=1                                   * # of keys
     C                   Eval      TIVarLen1=12                                 * Variable rcd len
     C                   Eval      TIVarKey1=1                                  * Variable rcd key
     C                   Eval      TIVarDtaL1=0                                 * Variable dta len
      * Now call API to retrieve receivers
     C                   Time                    CurDTS                         * Retrieve timestamp
     C                   Reset                   APIErr                         * API Error
     C                   CallP     RtvJrnInfo( RcvVar:
     C                                        %Size(RcvVar):
     C                                        JrnWY + JrnLWY:
     C                                        'RJRN0100':
     C                                        RtvInf:
     C                                        APIErr)
      * Write retrieved info to file
     C                   If        AEBytAvl=0                                   * No error
     C                   Eval      QJON0100 = RcvVar                            * RJRN0100
     C                   Eval      KeyInfDS = %subst(RcvVar:QJOOKI+5)
     C                   Eval      RcvHdrDS = %subst(KeyInfDS:KIKeyOfs+1)
      * Fill file fields
     C                   Eval      LJJRN=QJOJN00                                * Journal
     C                   Eval      LJJRNL=QJOJLN                                * Journal library
      * Fill journal type
     C                   If        QJOJT='0'                                    * Local journal
     C                   Eval      LJJRNTYP=#Lcl                                * *LOCAL
     C                   Else
     C                   Eval      LJJRNTYP=#Rmt                                * *REMOTE
     C                   EndIf                                                  * Local journal
      * Fill journal state
     C                   Z-Add     1             x                              * Array index
     C     QJOJS         LookUp    JrnStt(x)                              20
     C                   If        *In20
     C                   MoveL(p)  JrnSttNam(x)  LJJRNSTT                       * Journal state
     C                   EndIf
      * Fill remaining fields
     C                   Eval      LJNBRRCV=RHNbrRcv                            * # of attached rcv
     C                   Eval      LJTOTSIZGB=(RHTotSiz*RHTotSizMlt)/           * Total size in GB
     C                                        (1024*1024)
     C                   Eval      LJATTRCV=QJOAJRN                             * Attached receiver
     C                   Eval      LJATTRCVL=QJOAJRLN                           * Attached rcv lib
     C                   Eval      LJRTVDTS=CurDTS                              * Retrieve DTS
     C                   Write     LSTJRNR
      * If receivers must be listed, write receivers
     C                   If        LSTRPA=#YES                                  * List receivers
     C                   ExSR      SRLstRcv                                     * List receivers
     C                   EndIf                                                  * List receivers
      * If there was an error retrieving the journal information, send diagnostic
     C                   Else                                                   * If error
      * Resend CPF message
     C                   Reset                   SPAPIErr                       * API Error
     C                   CallP     SndPgmMsg(AEMsgID:#CPFMSGF:AEMsgDta:
     C                                     %len(AEMsgDta):#DIAG:'*':1:
     C                                     MsgKey:SPAPIErr)
      * Send diagnostic message LJR0002
     C                   Eval      MDJrn=JrnWY                                  * Journal name
     C                   Eval      MDJrnL=JrnLWY                                * Journal library
     C                   Eval      MDMsgID=AEMsgID                              * Message ID
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('LJR0002':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':2:
     C                                     MsgKey:APIErr)
     C                   EndIf                                                  * No error
     C                   EndIf                                                  * Record not exist
     C                   EndIf                                                  * Journal selected
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRLstRcv - List receivers to output file                            *
      * ------------------------------------------------------------------- *
     C     SRLstRcv      BegSR
      * If number of receivers greater than 500 --> Send diag message
     C                   If        RHNbrRcv>500                                 * # > 500
     C                   Eval      MDJrn=QJOJN00                                * Journal name
     C                   Eval      MDJrnL=QJOJLN                                * Journal library
     C                   Eval      MDNbrRcv=RHNbrRcv                            * # of receivers
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('LJR0001':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':2:
     C                                     MsgKey:APIErr)
     C                   EndIf                                                  * # > 500
      * Retrieve list of receivers and write entries
     C                   Z-Add     1             i                              * Counter
     C     i             DowLE     RHNbrRcv
     C     i             AndLE     500                                          * Maximum number
     C                   Eval      QJONRK1O=%subst(RcvHdrDS:KIInfLen+
     C                             ((i-1)*KIEntLen)+1:KIEntLen)
      * Move retrieved info to file fields
     C                   Eval      LRJRN=QJOJN00                                * Journal name
     C                   Eval      LRJRNL=QJOJLN                                * Journal library
     C                   Eval      LRRCV=QJOJRN                                 * Receiver name
     C                   Eval      LRRCVL=QJOJRLN                               * Receiver library
     C                   Eval      LRSEQ=QJOJRNBR                               * Receiver sequence
     C                   Eval      LRATTD=QJOJRADT                              * Attached date-time
     C                   Eval      LRSAVD=QJOJRSDT                              * Save date-time
     C                   Eval      LRSIZE=QJOJRS00                              * Receiver size kB
     C                   Eval      LRRTVDTS=CurDTS                              * Retrieve timestamp
      * Determine the receiver's change date
     C                   Reset                   ApiErr
     C                   CallP     RtvObjD(QUSD0100:90:'OBJD0100':
     C                                     LRRCV+LRRCVL:'*JRNRCV':APIErr)
     C                   If        AEBytAvl=0                                   * No error
     C                   Eval      LRCHGD=QUSCDT11                              * Change date
     C                   Else
     C                   Eval      LRCHGD='9999999999999'                       * High change date
     C                   EndIf                                                  * No error
      * Determine value of Status
     C                   Z-Add     1             x                              * Array index
     C     QJOJRS        LookUp    RcvSts(x)                              20
     C                   If        *In20
     C                   MoveL(p)  RcvStsNam(x)  LRSTS                          * Receiver status
     C                   EndIf
      * Write the record
     C                   Write     LSTJRNRR
     C                   Add       1             i                              * Counter
     C                   EndDo
     C                   EndSR

**CtData JrnStt
0*INACTIVE
1*ACTIVE
2*FAILED
4*INACTPEND
**CtData RcvSts
1ATTACHED
2ONLINE
3SAVED
4FREED
5PARTIAL
