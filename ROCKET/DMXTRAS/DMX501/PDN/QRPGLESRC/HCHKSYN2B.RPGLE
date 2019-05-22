      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HCHKSYN2B       *PGM RPG                          *
      *            Fill the target/group name and compare library    *
      *            when blank. Also removes duplicate object entries *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20020110 FK  Replacement for HCHKSYN5                        *
      * 20021119 FK  Also fill target/group                          *
      * 20021122 FK  Delete duplicate records                        *
      * 20031010 FK  Duplicate records not deleted (need extra key)  *
      * 20031208 FK  Fill target library into library                *
      * 20050216 FK  Get specific attribute for PF/LF                *
      * 20051010 FK  Errors when different target library            *
      * 20060306 FK  Handle target library for objects in QSYS       *
      * 20060324 FK  Fill object reference in HAMOBJ                 *
      * 20060327 FK  Fill original object                            *
      * 20070420 FK  If remote journal, HAMOBJ must not be checked   *
      *              If remote journal, HAROBJ check on target       *
      * 20070917 FK  *LIB objects not handled correctly              *
      * 20070918 FK  Removal of duplicate moved to HCHKSYN5          *
      * 20080107 FK  Indicator to mirror contents                    *
      * 20080206 FK  Include sequence in output file                 *
      * 20111217 FK  Remove HA                                       *
      * ============================================================ *
      * Object descriptions
     FHCHKSYNOD UF   E           K DISK
      * Member descriptions
     FHCHKSYNMD UF   E           K DISK
      * Data objects (primary)
     FHUMOBOL   IF   E           K DISK    UsrOpn
      * Data objects (backup)
     FHUTMOBOL  IF   E           K DISK    UsrOpn
      * Data objects (backup, remote journal)
     FHUROBOL   IF   E           K DISK    UsrOpn
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data

      * FILD0100 data structure
     D FILD0100        DS          1000
     D  LRTNFD                 1      4B 0                                      * Length dta returne
     D  BPVDFD                 5      8B 0                                      * Bytes provided
     D  ATR1FD                 9      9                                         * Attribute bytes
     D  ATR2FD                10     10                                         * Attribute bytes
     D  RestFD                11     50                                         * Remaining bytes
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#Yes             C                   CONST('*YES')
     D#No              C                   CONST('*NO ')
     D#Lcl             C                   CONST('*LCL')
     D#Rmt             C                   CONST('*RMT')
     D#QSys            C                   CONST('QSYS')
     D#Lib             C                   CONST('*LIB      ')
     D#DTAARA          C                   CONST('*DTAARA   ')
     D#DTAQ            C                   CONST('*DTAQ     ')
     D#FILE            C                   CONST('*FILE     ')
     D#PFDTA           C                   CONST('PFDTA     ')
     D#PFSRC           C                   CONST('PFSRC     ')
     D#LFDTA           C                   CONST('LF        ')
     D#LFSRC           C                   CONST('LFSRC     ')
     D#DBFile          C                   CONST('DB-FILE   ')
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
      * API parameter values
     D RcvVarLen       S              9B 0                                      * Receiver var len
     D ObjTypWY        s             10                                         * Object type
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     LimDsc        KList
     C                   KFld                    GRPNWY           10            * Group name (blank)
     C                   KFld                    CMPLWY           10            * Compare lib (blank
     C                   KFld                    CMPOWY           10            * Compare obj (blank
     C     LimHAM        KList
     C                   KFld                    ODOBNM                         * Object name
     C                   KFld                    ODLBNM                         * Object library
     C                   KFld                    ObjTypWY                       * Object type
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Parameter list for QDBRTVFD API
     C     pRTVFD        PList
     C                   Parm                    FILD0100                       * FILD0100 format
     C                   Parm      1000          RcvVarLen                      * Rcv Var length
     C                   Parm                    RtnFilFD         20            * Returned file
     C                   Parm      'FILD0100'    FmtFD             8            * Format
     C                   Parm                    FileFD           20            * Qualified file
     C                   Parm      '*FIRST'      RcdFmtFD         10            * Record format
     C                   Parm      '0'           OvrPrcFD          1            * Override processin
     C                   Parm      '*FILETYPE'   SysFD            10            * System
     C                   Parm      '*EXT'        FmtTypFD         10            * Format type
     C                   Parm                    ApiErr                         * API Error
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    GRPNPA           10            * Group name
     C                   Parm                    OBJLPA           10            * Object library
     C                   Parm                    CMPLPA           10            * Compare/org librar
     C                   Parm                    TGTLPA           10            * Target library
     C                   Parm                    ROLEPA            1            * Role of system
     C                   Parm                    JRNLOCPA          4            * Journal location
     C                   Parm                    CNTSPA            1            * Mirror contents?
     C                   Parm                    SEQPA             3 0          * Sequence
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Clear                   GRPNWY                         * Group name (blank)
     C                   Clear                   CMPLWY                         * Compare lib (blank
     C                   Clear                   CMPOWY                         * Compare obj (blank
      * Open HAMOBJ, HATMOBJ or HAROBJ depending on system and journal location
     C                   Select
     C                   When      ROLEPA='P' and JRNLOCPA=#Lcl                 * Primary and *LCL
     C                   Open      HUMOBOL
     C                   When      ROLEPA='S'                                   * Backup
     C                   Open      HUTMOBOL
     C                   Open      HUROBOL
     C                   EndSL
      * Process all objects and change compare library
     C     LimDsc        SetLL     SYNOD@
     C     LimDsc        ReadE     SYNOD@                                 95
     C     *In95         DoWEQ     *Off
     C                   Eval      ODGRPN=GRPNPA                                * Group name
     C                   Eval      ODSEQ=SEQPA                                  * Sequence
      * Fill original library/object dependent on type
     C                   Select
      * For "normal" objects, populate the original library with the object specifier library
     C                   When      ODLBNM<>#QSys                                * Not QSYS object
     C                   Eval      ODCMPL=CMPLPA                                * Original library
     C                   Eval      ODCMPO=ODOBNM                                * Original object
     C                   Eval      ODTGTL=TGTLPA                                * Target library
      * Objects in QSYS cannot be mirrored to a different library, original=object library
     C                   When      ODLBNM=#QSys and (ODOBTP<>#Lib or            * QSYS object
     C                             TGTLPA=CMPLPA)                               * Same target
     C                   Eval      ODCMPL=#QSys                                 * Object library
     C                   Eval      ODCMPO=ODOBNM                                * Original object
     C                   Eval      ODTGTL=#QSys                                 * Target library
      * Library description for different target library
     C                   When      ODLBNM=#QSys and ODOBTP=#Lib                 * Library object
     C                             and TGTLPA<>CMPLPA                           * Different target
     C                   Eval      ODCMPL=#QSys                                 * Original library
     C                   Eval      ODCMPO=CMPLPA                                * Original object
     C                   Eval      ODTGTL=TGTLPA                                * Target library
     C                   EndSL
      * If PF or LF --> Determine exact attribute
     C     ODOBTP        IfEQ      #FILE                                        * *FILE object
     C     ODOBAT        AndEQ     'PF'                                         * PF
     C     ODOBTP        OrEQ      #FILE                                        * *FILE object
     C     ODOBAT        AndEQ     'LF'                                         * LF
     C                   ExSR      SRRtvAtr                                     * Retrieve object at
     C                   EndIf
     C                   Clear                   ODDOM                          * Data Object Mirror
      * Determine existence in HAMOBJ, HATMOBJ or HAROBJ if data object
     C                   If        (ODOBTP=#FILE and                            * Data Object
     C                                     (ODOBAT=#PFDTA or ODOBAT=#LFDTA)) or
     C                             ODOBTP=#DTAARA or ODOBTP=#DTAQ
     C                   Eval      ObjTypWY=ODOBTP                              * Object type
     C                   If        ObjTypWY=#File                               * *FILE
     C                   Eval      ObjTypWY=#DBFile                             * DB-FILE
     C                   EndIf                                                  * *FILE
      * If primary, check existence in HAMOBJ
     C                   If        ROLEPA='P'                                   * Primary
     C                   If        JRNLOCPA=#Lcl                                * *LCL
     C     LimHam        SetLL     HUMOBOL@                               94
     C                   Else
     C                   Eval      *In94=*On                                    * Assume HAMOBJ
     C                   EndIf                                                  * *LCL
     C                   EndIf                                                  * Primary
      * If backup, check existence in HATMOBJ and/or HAROBJ
     C                   If        ROLEPA='S'                                   * Backup
     C     LimHam        SetLL     HUTMOBOL@                              94
      * If object exists in HATMOBJ and there is a remote journal, also check there
     C                   If        *In94 and JRNLOCPA=#Rmt                      * *RMT
     C     LimHam        SetLL     HUROBOL@                               94
     C                   EndIf                                                  * *RMT
     C                   EndIf                                                  * Backup
      * Determine value of ODDOM depending on existence in HAMOBJ/HATMOBJ/HAROBJ
     C                   If        *In94                                        * Exists?
     C                   Eval      ODDOM=#Yes                                   * *YES
     C                   Else
     C                   Eval      ODDOM=#No                                    * *NO
     C                   EndIf                                                  * Exists?
     C                   EndIf                                                  * Data object
      * Now update record
     C                   Update    SYNOD@
     C     LimDsc        ReadE     SYNOD@                                 95
     C                   EndDo
      * Process all members and update target/group
     C     LimDsc        SetLL     SYNMD@
     C     LimDsc        ReadE     SYNMD@                                 95
     C     *In95         DoWEQ     *Off
     C                   MoveL     GRPNPA        MBGRPN                         * Group name
     C                   MoveL     CMPLPA        MBCMPL                         * Compare library
     C                   MoveL     MBFILE        MBCMPF                         * Compare file
     C                   MoveL     TGTLPA        MBTGTL                         * Target library
     C                   Eval      MBCNTS=CNTSPA                                * Mirror contents?
     C                   Eval      MBSEQ=SEQPA                                  * Sequence
     C                   Update    SYNMD@
     C     LimDsc        ReadE     SYNMD@                                 95
     C                   EndDo
     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * SRRtvAtr - Retrieve file attribute                                  *
      * ------------------------------------------------------------------- *
     C     SRRtvAtr      BegSR
      * Call API to retrieve file attribute
     C                   Reset                   ApiErr
     C                   Eval      FileFD = ODOBNM + ODLBNM                     * Qualified file
     C                   Call      'QDBRTVFD'    pRTVFD                         * QDBRTVFD API
      * Determine object attribute, dependent on returned attribute
     C                   If        AEBytAvl=0                                   * No error
     C                   TestB     '2'           ATR1FD                   21    * PF=0/LF=1
     C                   TestB     '4'           ATR1FD                   22    * DTA=0/SRC=1
     C                   Select
     C                   When      not *In21 and not *In22                      * Physical-data
     C                   MoveL     #PFDTA        ODOBAT                         * Object attribute
     C                   When      *In21 and not *In22                          * Logical
     C                   MoveL     #LFDTA        ODOBAT                         * Object attribute
     C                   When      not *In21 and *In22                          * Physical-source
     C                   MoveL     #PFSRC        ODOBAT                         * Object attribute
     C                   When      *In21 and *In22                              * Logical source
     C                   MoveL     #LFSRC        ODOBAT                         * Object attribute
     C                   EndSL
     C                   Else
     C                   Eval      ODOBAT = *Blanks                             * Attribute????
     C                   EndIf
     C                   EndSR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
