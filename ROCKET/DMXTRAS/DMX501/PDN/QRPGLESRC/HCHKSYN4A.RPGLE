      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HCHKSYN4A       *PGM RPG                          *
      *            Reads the object description files and determines *
      *            discrepancies between:                            *
      *            - Objects                                         *
      *            - Members                                         *
      *            - Authorities                                     *
      *            - IFS Objects                                     *
      *            - IFS Object authorities                          *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20021125 FK  Initial delivery (redesign)                     *
      * 20021203 FK  New Field: Reference authority                  *
      * 20021206 FK  Use date-time stamps in difference files        *
      * 20030112 FK  Check for invalid dates                         *
      * 20030414 FK  Object management discrepancies not shown       *
      *              Show member differences only for PFs            *
      *              Add support for locked members                  *
      * 20030623 FK  Ignore differences in middle part of mode       *
      * 20031209 FK  New field: IFS authority fixed                  *
      * 20050215 FK  Journal information now in objects file         *
      * 20050401 FK  Missing object should not indicate journal dif. *
      *              Member-less file should not display blank member*
      * 20050428 FK  Handle *LIB object                              *
      * 20050517 FK  IFS authorities                                 *
      * 20051010 FK  Handle different target library                 *
      * 20051230 FK  Handle records flagged for exclude              *
      *              Do not check DDM DTAARA & DTAQ                  *
      * 20060215 FK  Include marked string in reports                *
      * 20060301 FK  Added fields to HCHKSYNOD(T)                    *
      * 20060323 FK  Non-mirrored objects also included in file      *
      * 20060327 FK  Include original object to successfully compare *
      * 20060428 FK  Object lock parameters not filled properly      *
      * 20080206 FK  Consider mirror contents parameter              *
      * ============================================================ *
     HDatFmt(*YMD)
      * Group definitions
     FHLSTCFGG  IF   E           K DISK
      * Object descriptions (source)
     FHCHKSYNOD IF   E           K DISK
      * Object descriptions (target)
     FHCHKSYNODTIF   E           K DISK    Rename(SYNOD@:SYNODT@)
      * Member descriptions (source)
     FHCHKSYNMD IF   E           K DISK    UsrOpn
      * Member descriptions (target)
     FHCHKSYNMDTIF   E           K DISK    UsrOpn Rename(SYNMD@:SYNMDT@)
      * Object authorities (source)
     FHCHKSYNOA IF   E           K DISK    UsrOpn
      * Object authorities (target)
     FHCHKSYNOATIF   E           K DISK    UsrOpn Rename(SYNOA@:SYNOAT@)
      * IFS object descriptions (source)
     FHCHKSYNID IF   E           K DISK    UsrOpn
      * IFS object descriptions (target)
     FHCHKSYNIDTIF   E           K DISK    UsrOpn Rename(SYNID@:SYNIDT@)
      * IFS object authorities (source)
     FHCHKSYNIA IF   E           K DISK    UsrOpn
      * IFS object authorities (target)
     FHCHKSYNIATIF   E           K DISK    UsrOpn Rename(SYNIA@:SYNIAT@)
      * Object discrepancies
     FHCHKSYNOBJUF A E           K DISK
      * Member discrepancies
     FHCHKSYNMBRUF A E           K DISK    UsrOpn
      * Authority discrepancies
     FHCHKSYNAUTUF A E           K DISK    UsrOpn
      * IFS object discrepancies
     FHCHKSYNIFSUF A E           K DISK    UsrOpn
      * IFS object authority discrepancies
     FHCHKSYNIFAUF A E           K DISK    UsrOpn
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #YES            C                   CONST('*YES')
     D #NO             C                   CONST('*NO')
     D #LIB            C                   CONST('*LIB')
     D #FILE           C                   CONST('*FILE')
     D #DTAARA         C                   CONST('*DTAARA')
     D #DTAQ           C                   CONST('*DTAQ')
     D #PFDTA          C                   CONST('PFDTA')
     D #DDM            C                   CONST('DDM')
     D #JRNRCV         C                   CONST('*JRNRCV')
     D #Public         C                   CONST('*PUBLIC')
     D #Locked         C                   CONST('*LOCKED')
     D #NullDat        C                   CONST(x'000000000000')
     D #Jobrun         C                   CONST('*JOBRUN0')
     D #MDY            C                   CONST('*MDY0   ')
     D #YMD            C                   CONST('*YMD0   ')
     D#INC             C                   CONST('*INC')
     D#EXC             C                   CONST('*EXC')
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Other field definitions                                       *
      * ------------------------------------------------------------- *
     D DatFmt          S              8                                         * Date format
     D ChrDat          S              6                                         * Character date
     D ChrTim          S              6                                         * Character time
     D CvtDat          S               D                                        * Conversion date
     D CvtTim          S               T                                        * Conversion time
     D CvtDTS          S               Z                                        * Conversion DTS
     D RtvDTS          S               Z                                        * Retrieve DTS
     D ChkDTS          S               Z                                        * Check DTS
     D tmpObj          S           5000    Varying                              * Temporary obj name
     D SVGRPN          S             10a                                        * Saved group
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * Field renames for HCHKSYNOD
     ISYNOD@
     I              ODCCEN                      SOCCEN
     I              ODCDAT                      SOCDAT
     I              ODCTIM                      SOCTIM
     I              ODLCEN                      SOLCEN
     I              ODLDAT                      SOLDAT
     I              ODLTIM                      SOLTIM
     I              ODOBTX                      SOOBTX
     I              ODOBOW                      SOOBOW
     I              ODOBSZ                      SOOBSZ
     I              ODSIZU                      SOSIZU
     I              ODBPUN                      SOBPUN
     I              ODJRST                      SOJRST
     I              ODJRNM                      SOJRNM
     I              ODJRLB                      SOJRLB
     I              ODJRIM                      SOJRIM
     I              ODOBLK                      SOOBLK
     I              ODOBDM                      SOOBDM
     I              ODDCEN                      SODCEN
     I              ODDDAT                      SODDAT
     I              ODDTIM                      SODTIM
     I              ODDOM                       SODOM
      * Field renames for HCHKSYNODT
     ISYNODT@
     I              ODCCEN                      TOCCEN
     I              ODCDAT                      TOCDAT
     I              ODCTIM                      TOCTIM
     I              ODLCEN                      TOLCEN
     I              ODLDAT                      TOLDAT
     I              ODLTIM                      TOLTIM
     I              ODOBTX                      TOOBTX
     I              ODOBOW                      TOOBOW
     I              ODOBSZ                      TOOBSZ
     I              ODSIZU                      TOSIZU
     I              ODBPUN                      TOBPUN
     I              ODJRST                      TOJRST
     I              ODJRNM                      TOJRNM
     I              ODJRLB                      TOJRLB
     I              ODJRIM                      TOJRIM
     I              ODOBLK                      TOOBLK
     I              ODOBDM                      TOOBDM
     I              ODDCEN                      TODCEN
     I              ODDDAT                      TODDAT
     I              ODDTIM                      TODTIM
     I              ODDOM                       TODOM
      * Field renames for HCHKSYNMD
     ISYNMD@
     I              MBCCEN                      SMCCEN
     I              MBCDAT                      SMCDAT
     I              MBCTIM                      SMCTIM
     I              MBCHGC                      SMCHGC
     I              MBCHGD                      SMCHGD
     I              MBCHGT                      SMCHGT
     I              MBNRCD                      SMNRCD
     I              MBNDTR                      SMNDTR
     I              MBCNTS                      SMCNTS
     I              MBDSZ2                      SMDSZ2
     I              MBLOCK                      SMLOCK
     I              MBRCEN                      SMRCEN
     I              MBRDAT                      SMRDAT
     I              MBRTIM                      SMRTIM
      * Field renames for HCHKSYNMDT
     ISYNMDT@
     I              MBCCEN                      TMCCEN
     I              MBCDAT                      TMCDAT
     I              MBCTIM                      TMCTIM
     I              MBCHGC                      TMCHGC
     I              MBCHGD                      TMCHGD
     I              MBCHGT                      TMCHGT
     I              MBNRCD                      TMNRCD
     I              MBNDTR                      TMNDTR
     I              MBCNTS                      TMCNTS
     I              MBDSZ2                      TMDSZ2
     I              MBLOCK                      TMLOCK
     I              MBRCEN                      TMRCEN
     I              MBRDAT                      TMRDAT
     I              MBRTIM                      TMRTIM
      * Field renames for HCHKSYNOA
     ISYNOA@
     I              OAOWN                       SAOWN
     I              OAOBJA                      SAOBJA
     I              OAANAM                      SAANAM
     I              OAOPR                       SAOPR
     I              OAOMGT                      SAOMGT
     I              OAEXS                       SAEXS
     I              OAREAD                      SAREAD
     I              OAADD                       SAADD
     I              OAUPD                       SAUPD
     I              OADLT                       SADLT
     I              OAEXEC                      SAEXEC
     I              OAALT                       SAALT
     I              OAREF                       SAREF
     I              OAAMGT                      SAAMGT
      * Field renames for HCHKSYNOAT
     ISYNOAT@
     I              OAOWN                       TAOWN
     I              OAOBJA                      TAOBJA
     I              OAANAM                      TAANAM
     I              OAOPR                       TAOPR
     I              OAOMGT                      TAOMGT
     I              OAEXS                       TAEXS
     I              OAREAD                      TAREAD
     I              OAADD                       TAADD
     I              OAUPD                       TAUPD
     I              OADLT                       TADLT
     I              OAEXEC                      TAEXEC
     I              OAALT                       TAALT
     I              OAREF                       TAREF
     I              OAAMGT                      TAAMGT
      * Field renames for HCHKSYNID
     ISYNID@
     I              IDSIZE                      SISIZE
     I              IDCNTD                      SICNTD
     I              IDSTSD                      SISTSD
     I              IDRTVD                      SIRTVD
      * Field renames for HCHKSYNIDT
     ISYNIDT@
     I              IDSIZE                      TISIZE
     I              IDCNTD                      TICNTD
     I              IDSTSD                      TISTSD
     I              IDRTVD                      TIRTVD
      * Field renames for HCHKSYNIA
     ISYNIA@
     I              IAOWN                       SJOWN
     I              IADTAA                      SJDTAA
     I              IAANAM                      SJANAM
     I              IAOPR                       SJOPR
     I              IAOMGT                      SJOMGT
     I              IAEXS                       SJEXS
     I              IAREAD                      SJREAD
     I              IAADD                       SJADD
     I              IAUPD                       SJUPD
     I              IADLT                       SJDLT
     I              IAEXEC                      SJEXEC
     I              IAALT                       SJALT
     I              IAREF                       SJREF
     I              IAAMGT                      SJAMGT
      * Field renames for HCHKSYNIAT
     ISYNIAT@
     I              IAOWN                       TJOWN
     I              IADTAA                      TJDTAA
     I              IAANAM                      TJANAM
     I              IAOPR                       TJOPR
     I              IAOMGT                      TJOMGT
     I              IAEXS                       TJEXS
     I              IAREAD                      TJREAD
     I              IAADD                       TJADD
     I              IAUPD                       TJUPD
     I              IADLT                       TJDLT
     I              IAEXEC                      TJEXEC
     I              IAALT                       TJALT
     I              IAREF                       TJREF
     I              IAAMGT                      TJAMGT
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list to retrieve group definition
     C     ChnGrp        KList
     C                   KFld                    ODGRPN                         * Group name
      * Key list to check objects
     C     ChkObj        KList
     C                   KFld                    ODGRPN                         * Group name
     C                   KFld                    ODCMPL                         * Original library
     C                   KFld                    ODCMPO                         * Original object
     C                   KFld                    ODOBTP                         * Object type
      * Key list to check members
     C     ChkMbr        KList
     C                   KFld                    MBGRPN                         * Group name
     C                   KFld                    MBCMPL                         * Original library
     C                   KFld                    MBCMPF                         * Original file
     C                   KFld                    MBNAME                         * Member name
      * Key list to check object authorities
     C     ChkAut        KList
     C                   KFld                    OAGRPN                         * Group name
     C                   KFld                    OACMPL                         * Original library
     C                   KFld                    OACMPO                         * Original object
     C                   KFld                    OATYPE                         * Object type
     C                   KFld                    OAUSR                          * User profile
      * Key list to check IFS objects
     C     ChkIFS        KList
     C                   KFld                    IDGRPN                         * Group name
     C                   KFld                    IDOBJK                         * IFS Object (key)
      * Key list to check IFS authorities
     C     ChkIFA        KList
     C                   KFld                    IAGRPN                         * Group name
     C                   KFld                    IAOBJK                         * IFS Object (key)
     C                   KFld                    IAUSR                          * User profile
      * Key list to check locked object authorities
     C     ChkLck        KList
     C                   KFld                    OAGRPN                         * Group name
     C                   KFld                    OACMPL                         * Compare/Org. lib.
     C                   KFld                    OANAME                         * Object name
     C                   KFld                    OATYPE                         * Object type
     C                   KFld                    UserWY           10            * *PUBLIC
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    CHKMPA            4            * Check Members
     C                   Parm                    CHKIPA            4            * Check IFS
     C                   Parm                    CHKAPA            4            * Check authorities
     C                   Parm                    IGNIPA            5 0          * Ignore interval
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Clear                   IGNIWY            5 0          * Ignore interval
      * Open UsrOpn files dependent on parameters
     C     CHKMPA        IfEQ      #YES                                         * CHKMBR(*YES)
     C                   Open      HCHKSYNMD                                    * Mbr Source
     C                   Open      HCHKSYNMDT                                   * Mbr Target
     C                   Open      HCHKSYNMBR                                   * Mbr discrepancies
     C                   EndIf
     C     CHKIPA        IfEQ      #YES                                         * CHKIFS(*YES)
     C                   Open      HCHKSYNID                                    * IFS Source
     C                   Open      HCHKSYNIDT                                   * IFS Target
     C                   Open      HCHKSYNIFS                                   * IFS discrepancies
     C                   EndIf
     C     CHKAPA        IfEQ      #YES                                         * CHKAUT(*YES)
     C                   Open      HCHKSYNOA                                    * Aut Source
     C                   Open      HCHKSYNOAT                                   * Aut Target
     C                   Open      HCHKSYNAUT                                   * Aut discrepancies
     C                   EndIf
     C     CHKIPA        IfEQ      #YES                                         * CHKIFS(*YES)
     C     CHKAPA        AndEQ     #YES                                         * CHKAUT(*YES)
     C                   Open      HCHKSYNIA                                    * IFS aut source
     C                   Open      HCHKSYNIAT                                   * IFS aut target
     C                   Open      HCHKSYNIFA                                   * IFS aut discr.
     C                   EndIf
      * Execute subroutine to check object discrepancies
     C                   ExSR      SRChkObj
      * Execute subroutine to check member discrepancies
     C     CHKMPA        IfEQ      #YES                                         * CHKMBR(*YES)
     C                   ExSR      SRChkMbr
     C                   EndIf
      * Execute subroutine to check authority discrepancies
     C     CHKAPA        IfEQ      #YES                                         * CHKAUT(*YES)
     C                   ExSR      SRChkAut
     C                   EndIf
      * Execute subroutine to check IFS Object discrepancies
     C     CHKIPA        IfEQ      #YES                                         * CHKIFS(*YES)
     C                   ExSR      SRChkIFS
     C                   EndIf
      * Execute subroutine to check IFS authority discrepancies
     C     CHKAPA        IfEQ      #YES                                         * CHKAUT(*YES)
     C     CHKIPA        AndEQ     #YES                                         * CHKIFS(*YES)
     C                   ExSR      SRChkIFA
     C                   EndIf

     C                   Seton                                        LR

      * ------------------------------------------------------------------- *
      * SRChkObj - Check object discrepancies                               *
      * ------------------------------------------------------------------- *
     C     SRChkObj      BegSR
      * Read the HCHKSYNOD (Source) sequentially for Missing Object/Object Differences
     C     *Loval        SetLL     SYNOD@
     C                   Clear                   SYNOBJ@
     C                   Read      SYNOD@                                 95
     C     *In95         DowEQ     *Off
      * If new group --> retrieve group definition
     C                   If        ODGRPN<>SVGRPN                               * New group?
     C     ChnGrp        Chain     LSTCFGG@                           94
     C                   Eval      SVGRPN=ODGRPN                                * Saved group
     C                   EndIf                                                  * New target/group?
      * Only process included objects
     C                   If        ODINC<>#EXC                                  * Not *EXC
      * Assume that there are no discrepancies
     C                   Move      *Off          ObjDif            1            * Object difference
     C                   MoveL     'N'           ODMOT                          * Missing object
     C                   MoveL     'N'           ODMOS                          * Obsolete object
     C                   MoveL     'N'           ODNJ                           * Not journalled
     C                   MoveL     'N'           ODJD                           * Journal difference
     C                   MoveL     'N'           ODNM                           * Not mirrored
      * Convert Source Creation date to timestamp
     C                   MoveL     #MDY          DatFmt                         * Date format
     C                   MoveL     SOCDAT        ChrDat                         * Character date
     C                   MoveL     SOCTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        SOCDTS                         * Creation DTS
      * Convert Source Change date to timestamp
     C                   MoveL     #MDY          DatFmt                         * Date format
     C                   MoveL     SOLDAT        ChrDat                         * Character date
     C                   MoveL     SOLTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        SOLDTS                         * Change DTS
      * Skip journal receivers
     C     ODOBTP        IfNE      #JRNRCV                                      * Journal receiver
      * First, check if the object exists on the target
     C     ChkObj        SetLL     SYNODT@                                94
     C                   Select
      * Object doesn't exist --> Missing object
     C     *In94         WhenEQ    *Off                                         * Not existent
     C                   Move      *On           ObjDif                         * Object difference
     C                   MoveL     'Y'           ODMOT                          * Missing object
      * Object exists --> Determine discrepancies
     C     *In94         WhenEQ    *On                                          * Existent
     C     ChkObj        ReadE     SYNODT@                                94
      * Convert Target Creation date to timestamp
     C                   MoveL     #MDY          DatFmt                         * Date format
     C                   MoveL     TOCDAT        ChrDat                         * Character date
     C                   MoveL     TOCTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TOCDTS                         * Creation DTS
      * Convert Target Change date to timestamp
     C                   MoveL     #MDY          DatFmt                         * Date format
     C                   MoveL     TOLDAT        ChrDat                         * Character date
     C                   MoveL     TOLTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TOLDTS                         * Change DTS
      * Data object --> Journal attributes and object included in HATMOBJ
     C                   If        (ODOBTP=#FILE and ODOBAT=#PFDTA) or          * PFDTA file
     C                             (ODOBTP=#DTAARA and                          * *DTAARA (not DDM)
     C                                     %Subst(ODOBAT:1:3)<>#DDM) or
     C                             (ODOBTP=#DTAQ and                            * *DTAQ (not DDM)
     C                                     %Subst(ODOBAT:1:3)<>#DDM)
     C                   If        LGJRNBCK=#Yes and                            * Journal on backup
     C                             (SOJRST<>TOJRST or SOJRNM<>TOJRNM or         * Journal not the
     C                              SOJRLB<>TOJRLB or SOJRIM<>TOJRIM)           * same
     C                   Move      *On           ObjDif                         * Object difference
     C                   Move      'Y'           ODJD                           * Journal difference
     C                   EndIf                                                  * Journal attributes
     C                   If        TODOM=#No                                    * Not mirrored?
     C                   Move      *On           ObjDif                         * Object difference
     C                   Move      'Y'           ODNM                           * Not mirrored
     C                   EndIf                                                  * Not mirrored?
     C                   EndIf                                                  * Data object
     C                   EndSL
      * Object not journalled/mirrored
     C                   If        (ODOBTP=#FILE and ODOBAT=#PFDTA) or          * PFDTA file
     C                             (ODOBTP=#DTAARA and                          * *DTAARA (not DDM)
     C                                     %Subst(ODOBAT:1:3)<>#DDM) or
     C                             (ODOBTP=#DTAQ and                            * *DTAQ (not DDM)
     C                                     %Subst(ODOBAT:1:3)<>#DDM)
     C     SOJRST        IfEQ      '0'                                          * Not journalled
     C                   Move      *On           ObjDif                         * Object difference
     C                   Move      'Y'           ODNJ                           * Not journalled
     C                   EndIf                                                  * Not journalled
     C     SODOM         IfEQ      #No                                          * Not mirrored
     C                   Move      *On           ObjDif                         * Object difference
     C                   Move      'Y'           ODNM                           * Not mirrored
     C                   EndIf                                                  * Not mirrored
     C                   EndIf                                                  * Data object
      * If object discrepancy --> write record (respect interval)
     C     ObjDif        IfEQ      *On
      * Calculate ignore interval (Object create date)
     C                   Move      SOCDTS        ChkDTS                         * Check DTS
      * Convert Retrieve date to timestamp
     C                   MoveL     #Jobrun       DatFmt                         * Date format
     C                   MoveL     SODDAT        ChrDat                         * Character date
     C                   MoveL     SODTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        RtvDTS                         * Retrieve DTS
     C                   ExSR      SRClcItv                                     * Calculate interval
      * If interval greater than allowed interval --> write
     C     IGNIWY        IfGE      IGNIPA
     C                   Write     SYNOBJ@
     C                   EndIf                                                  * Ignore interval
     C                   EndIf                                                  * Object discrepancy
     C                   EndIf                                                  * Journal receiver
     C                   EndIf                                                  * Not *EXC
      * Read next object
     C                   Clear                   SYNOBJ@
     C                   Read      SYNOD@                                 95
     C                   EndDo
      * Read the HCHKSYNODT (Target) sequentially for Obsolete object
     C                   Clear                   SYNOBJ@
     C     *Loval        SetLL     SYNODT@
     C                   Read      SYNODT@                                95
     C     *In95         DowEQ     *Off
      * Only process included objects
     C                   If        ODINC<>#EXC                                  * Not *EXC
      * Assume that there are no discrepancies
     C                   Move      *Off          ObjDif                         * Object difference
     C                   MoveL     'N'           ODMOT                          * Missing object
     C                   MoveL     'N'           ODMOS                          * Obsolete object
      * Convert Target Creation date to timestamp
     C                   MoveL     #MDY          DatFmt                         * Date format
     C                   MoveL     TOCDAT        ChrDat                         * Character date
     C                   MoveL     TOCTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TOCDTS                         * Creation DTS
      * Convert Target Change date to timestamp
     C                   MoveL     #MDY          DatFmt                         * Date format
     C                   MoveL     TOLDAT        ChrDat                         * Character date
     C                   MoveL     TOLTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TOLDTS                         * Change DTS
      * Skip journal receivers
     C     ODOBTP        IfNE      #JRNRCV                                      * Journal receiver
      * First, check if the object exists on the source
     C     ChkObj        SetLL     SYNOD@                                 94
      * Object doesn't exist --> Obsolete object
     C     *In94         IfEQ      *Off                                         * Not existent
     C                   Move      *On           ObjDif                         * Object difference
     C                   MoveL     'Y'           ODMOS                          * Obsolete object
     C                   EndIf
      * If object discrepancy --> write record
     C     ObjDif        IfEQ      *On
      * Calculate ignore interval (Object create date)
     C                   Move      TOCDTS        ChkDTS                         * Check DTS
      * Convert Retrieve date to timestamp
     C                   MoveL     #Jobrun       DatFmt                         * Date format
     C                   MoveL     TODDAT        ChrDat                         * Character date
     C                   MoveL     TODTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        RtvDTS                         * Change DTS
     C                   ExSR      SRClcItv                                     * Calculate interval
      * If interval greater than allowed interval --> write
     C     IGNIWY        IfGE      IGNIPA
     C                   Write     SYNOBJ@
     C                   EndIf                                                  * Ignore interval
     C                   EndIf                                                  * Object discrepancy
     C                   EndIf                                                  * Journal receiver
     C                   EndIf                                                  * Not *EXC
      * Read next object
     C                   Clear                   SYNOBJ@
     C                   Read      SYNODT@                                95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRChkMbr - Check member discrepancies                               *
      * ------------------------------------------------------------------- *
     C     SRChkMbr      BegSR
      * Read the HCHKSYNMD (Source) sequentially for Missing Members/Member Differences
     C                   Clear                   SYNMBR@
     C     *Loval        SetLL     SYNMD@
     C                   Read      SYNMD@                                 95
     C     *In95         DowEQ     *Off
      * Only process real member (member name not blank)
     C     MBNAME        IfNE      *Blanks                                      * Member
      * Only process included members
     C                   If        MBINC<>#EXC                                  * Not *EXC
      * Assume that there are no discrepancies
     C                   Move      *Off          MbrDif            1            * Member difference
     C                   MoveL     'N'           MBMMT                          * Missing member
     C                   MoveL     'N'           MBMMS                          * Obsolete member
     C                   MoveL     'N'           MBMD                           * Member differences
      * Convert Source Creation date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     SMCDAT        ChrDat                         * Character date
     C                   MoveL     SMCTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        SMCDTS                         * Creation DTS
      * Convert Source Change date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     SMCHGD        ChrDat                         * Character date
     C                   MoveL     SMCHGT        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        SMCHDT                         * Change DTS
      * First, check if the member exists on the target
     C     ChkMbr        SetLL     SYNMDT@                                94
     C                   Select
      * Member doesn't exist --> Missing member (only if not missing object)
     C     *In94         WhenEQ    *Off                                         * Not existent
     C                   ExSR      SRRtvObjM                                    * Retrieve Obj <-Mbr
     C     ODMOT         IfNE      'Y'                                          * Missing object
     C                   Move      *On           MbrDif                         * Member difference
     C                   MoveL     'Y'           MBMMT                          * Missing member
     C                   EndIf                                                  * Missing object
      * Member exists --> Determine discrepancies
     C     *In94         WhenEQ    *On                                          * Existent
     C     ChkMbr        ReadE     SYNMDT@                                94
      * Convert Target Creation date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     TMCDAT        ChrDat                         * Character date
     C                   MoveL     TMCTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TMCDTS                         * Creation DTS
      * Convert Target Change date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     TMCHGD        ChrDat                         * Character date
     C                   MoveL     TMCHGT        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TMCHDT                         * Change DTS
      * Difference in number of records (only if PF and contents mirrored)
     C     SMNRCD        IfNE      TMNRCD                                       * # Records
     C     MBFTYP        AndEQ     'P'                                          * Physical file
     C     SMCNTS        AndNE     'N'                                          * Mirror contents
     C     SMNDTR        OrNE      TMNDTR                                       * # Deleted records
     C     MBFTYP        AndEQ     'P'                                          * Physical file
     C     SMCNTS        AndNE     'N'                                          * Mirror contents
     C                   Move      *On           MbrDif                         * Member difference
     C                   Move      'Y'           MBMD                           * Member difference
     C                   EndIf                                                  * # record differ.
     C                   EndSL
      * If member discrepancy --> write record
     C     MbrDif        IfEQ      *On
      * Calculate ignore interval (Target Member change date if member difference)
     C     MBMD          IfEQ      'Y'                                          * Member difference
     C                   Move      TMCHDT        ChkDTS                         * Check DTS
      * Convert Retrieve date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     TMRDAT        ChrDat                         * Character date
     C                   MoveL     TMRTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        RtvDTS                         * Retrieve DTS
     C                   Else
      * Calculate ignore interval (Source Member change date if not member difference)
     C                   Move      SMCHDT        ChkDTS                         * Check DTS
      * Convert Retrieve date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     SMRDAT        ChrDat                         * Character date
     C                   MoveL     SMRTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        RtvDTS                         * Retrieve DTS
     C                   EndIf
     C                   ExSR      SRClcItv                                     * Calculate interval
      * If interval greater than allowed interval --> write
     C     IGNIWY        IfGE      IGNIPA
     C                   Write     SYNMBR@
     C                   EndIf                                                  * Ignore interval
     C                   EndIf                                                  * Member difference
     C                   EndIf                                                  * Not *EXC
     C                   EndIf                                                  * Real member name
      * Read next member
     C                   Clear                   SYNMBR@
     C                   Read      SYNMD@                                 95
     C                   EndDo
      * Read the HCHKSYNMDT (Target) sequentially for Obsolete member or Non-Mirrored
     C                   Clear                   SYNMBR@
     C     *Loval        SetLL     SYNMDT@
     C                   Read      SYNMDT@                                95
     C     *In95         DowEQ     *Off
      * Only process real member (member name not blank)
     C     MBNAME        IfNE      *Blanks                                      * Member
      * Only process included members
     C                   If        MBINC<>#EXC                                  * Not *EXC
      * Assume that there are no discrepancies
     C                   Move      *Off          MbrDif                         * Member difference
     C                   MoveL     'N'           MBMMT                          * Missing member
     C                   MoveL     'N'           MBMMS                          * Obsolete member
     C                   MoveL     'N'           MBMD                           * Member differences
      * Convert Target Creation date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     TMCDAT        ChrDat                         * Character date
     C                   MoveL     TMCTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TMCDTS                         * Creation DTS
      * Convert Target Change date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     TMCHGD        ChrDat                         * Character date
     C                   MoveL     TMCHGT        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        TMCHDT                         * Change DTS
      * First, check if the member exists on the source
     C     ChkMbr        SetLL     SYNMD@                                 94
      * Member doesn't exist --> Obsolete member
     C     *In94         IfEQ      *Off                                         * Not existent
     C                   ExSR      SRRtvObjM                                    * Retrieve Obj <-Mbr
     C     ODMOS         IfNE      'Y'                                          * Obsolete object
     C                   Move      *On           MbrDif                         * Member difference
     C                   MoveL     'Y'           MBMMS                          * Obsolete member
     C                   EndIf                                                  * Obsolete object
     C                   EndIf                                                  * Not existent
      * If member discrepancy --> write record
     C     MbrDif        IfEQ      *On                                          * Member difference
      * Calculate ignore interval (Member change date)
     C                   Move      TMCHDT        ChkDTS                         * Check DTS
      * Convert Retrieve date to timestamp
     C                   MoveL     #YMD          DatFmt                         * Date format
     C                   MoveL     TMRDAT        ChrDat                         * Character date
     C                   MoveL     TMRTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        RtvDTS                         * Retrieve DTS
     C                   ExSR      SRClcItv                                     * Calculate interval
      * If interval greater than allowed interval --> write
     C     IGNIWY        IfGE      IGNIPA
     C                   Write     SYNMBR@
     C                   EndIf                                                  * Ignore interval
     C                   EndIf                                                  * Member difference
     C                   EndIf                                                  * Not *EXC
     C                   EndIf                                                  * Real member name
      * Read next member
     C                   Clear                   SYNMBR@
     C                   Read      SYNMDT@                                95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRChkAut - Check authority discrepancies                            *
      * ------------------------------------------------------------------- *
     C     SRChkAut      BegSR
      * Read the HCHKSYNAO (Source) sequentially for Missing Authorities/Differences
     C                   Clear                   SYNAUT@
     C     *Loval        SetLL     SYNOA@
     C                   Read      SYNOA@                                 95
     C     *In95         DowEQ     *Off
      * Assume that there are no discrepancies
     C                   Move      *Off          AutDif            1            * Auth. difference
     C                   MoveL     'N'           OAMAT                          * Missing auth.
     C                   MoveL     'N'           OAMAS                          * Obsolete auth.
     C                   MoveL     'N'           OAAD                           * Auth. difference
     C                   MoveL     'N'           OAOD                           * Owner difference
     C                   MoveL     'N'           OAFIX                          * Auth. fixed
      * Skip journal receivers
     C     OATYPE        IfNE      #JRNRCV                                      * Journal receiver
      * First, check if the authority exists on the target
     C     ChkAut        SetLL     SYNOAT@                                94
     C                   Select
      * Authority doesn't exist --> Missing authority
     C     *In94         WhenEQ    *Off                                         * Not existent
     C                   ExSR      SRRtvObjA                                    * Retrieve Obj <-Aut
     C     ODMOT         IfNE      'Y'                                          * Missing object
     C                   Move      *On           AutDif                         * Auth. difference
     C                   MoveL     'Y'           OAMAT                          * Missing auth.
     C                   EndIf                                                  * Missing object
      * Authority exists --> Determine discrepancies
     C     *In94         WhenEQ    *On                                          * Existent
     C     ChkAut        ReadE     SYNOAT@                                94
      * Owner differences
     C     SAOWN         IfNE      TAOWN                                        * Owner
     C     SAOBJA        IfEQ      #Locked                                      * Locked object
     C                   Eval      SAOWN = #Locked
     C                   EndIf
     C                   Move      *On           AutDif                         * Auth. difference
     C                   Move      'Y'           OAOD                           * Owner difference
     C                   EndIf
      * Authority difference
     C     SAOBJA        IfNE      TAOBJA                                       * Authority
     C     SAANAM        OrNE      TAANAM                                       * Authorisation list
     C     SAOPR         OrNE      TAOPR                                        * Operational
     C     SAOMGT        OrNE      TAOMGT                                       * Object management
     C     SAEXS         OrNE      TAEXS                                        * Existence
     C     SAREAD        OrNE      TAREAD                                       * Read
     C     SAADD         OrNE      TAADD                                        * Add
     C     SAUPD         OrNE      TAUPD                                        * Update
     C     SADLT         OrNE      TADLT                                        * Delete
     C     SAEXEC        OrNE      TAEXEC                                       * Execute
     C     SAALT         OrNE      TAALT                                        * Alter object
     C     SAREF         OrNE      TAREF                                        * Reference
     C     SAAMGT        OrNE      TAAMGT                                       * Auth. list managem
     C                   Move      *On           AutDif                         * Auth. difference
     C                   Move      'Y'           OAAD                           * Auth. difference
     C                   EndIf
     C                   EndSL
      * If authority discrepancy --> write record
     C     AutDif        IfEQ      *On
     C                   Write     SYNAUT@
     C                   EndIf
     C                   EndIf                                                  * Journal receiver
      * Read next authority
     C                   Clear                   SYNAUT@
     C                   Read      SYNOA@                                 95
     C                   EndDo
      * Read the HCHKSYNOAT (Target) sequentially for Obsolete authorities
     C                   Clear                   SYNAUT@
     C     *Loval        SetLL     SYNOAT@
     C                   Read      SYNOAT@                                95
     C     *In95         DowEQ     *Off
      * Assume that there are no discrepancies
     C                   Move      *Off          AutDif                         * Auth. difference
     C                   MoveL     'N'           OAMAT                          * Missing auth.
     C                   MoveL     'N'           OAMAS                          * Obsolete auth.
     C                   MoveL     'N'           OAAD                           * Auth. difference
     C                   MoveL     'N'           OAOD                           * Owner difference
     C                   MoveL     'N'           OAFIX                          * Auth. fixed
      * Skip journal receivers
     C     OATYPE        IfNE      #JRNRCV                                      * Journal receiver
      * First, check if the authority exists on the source
     C     ChkAut        SetLL     SYNOA@                                 94
      * Authority doesn't exist --> Obsolete authority
     C     *In94         IfEQ      *Off                                         * Not existent
      * Check if object was obsolete
     C                   ExSR      SRRtvObjA                                    * Retrieve Obj <-Aut
     C     ODMOS         IfNE      'Y'                                          * Obsolete object
     C                   Move      *On           AutDif                         * Auth. difference
     C                   MoveL     'Y'           OAMAS                          * Obsolete auth.
     C                   EndIf                                                  * Obsolete object
      * If authority discrepancy --> write record
     C     AutDif        IfEQ      *On
     C                   Write     SYNAUT@
     C                   EndIf
     C                   EndIf                                                  * Journal receiver
     C                   EndIf                                                  * Locked on source
      * Read next authority
     C                   Clear                   SYNAUT@
     C                   Read      SYNOAT@                                95
     C                   EndDo
      * Read all obsolete authorities and remove if object locked on source
     C     *Loval        SetLL     SYNAUT@
     C                   Read      SYNAUT@                                95
     C     *In95         DowEQ     *Off
     C                   If        OAMAS='Y'                                    * Obsolete authority
      * Check if object was locked on the source. If so, skip
     C                   MoveL(p)  #Public       UserWY                         * *PUBLIC
     C     ChkLck        Chain     SYNOA@                             93
     C                   If        not *In93 and SAOBJA=#Locked                 * *LOCKED
     C                   Delete    SYNAUT@
     C                   EndIf                                                  * *LOCKED
     C                   EndIf                                                  * Obsolete authority
     C                   Read      SYNAUT@                                95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRChkIFS - Check IFS object discrepancies                           *
      * ------------------------------------------------------------------- *
     C     SRChkIFS      BegSR
      * Read the HCHKSYNID (Source) sequentially for Missing IFS objects/Differences
     C                   Clear                   SYNIFS@
     C     *Loval        SetLL     SYNID@
     C                   Read      SYNID@                                 95
     C     *In95         DowEQ     *Off
      * Only process included IFS objects
     C                   If        IDINC<>#EXC                                  * Not *EXC
      * Assume that there are no discrepancies
     C                   Move      *Off          IFSDif            1            * IFS difference
     C                   MoveL     'N'           IDMIT                          * Missing IFS Obj.
     C                   MoveL     'N'           IDMIS                          * Obsolete IFS Obj.
     C                   MoveL     'N'           IDID                           * IFS difference
      * First, check if the IFS object exists on the target
     C                   Eval      tmpObj = IDOBJ
     C     ChkIFS        SetLL     SYNIDT@
     C     ChkIFS        ReadE     SYNIDT@                                94
     C     *In94         DowEQ     *Off                                         * End of selection
     C     IDOBJ         AndNE     tmpObj                                       * Same object
      * If still not same object --> read next record
     C     IDOBJ         IfNE      tmpObj                                       * Same object
     C     ChkIFS        ReadE     SYNIDT@                                94
     C                   EndIf
     C                   EndDo
     C                   Select
      * Object doesn't exist --> Missing IFS object
     C     *In94         WhenEQ    *On                                          * Not existent
     C                   Move      *On           IFSDif                         * IFS Object diff.
     C                   MoveL     'Y'           IDMIT                          * Missing IFS object
      * IFS object exists --> Determine discrepancies
     C     *In94         WhenEQ    *Off                                         * Existent
      * Differences on attributes
     C                   EndSL
      * If object discrepancy --> write record
     C     IFSDif        IfEQ      *On
      * Calculate ignore interval (Target Contents change date if Contents Difference)
     C     IDID          IfEQ      'Y'
     C                   Move      TICNTD        ChkDTS                         * Check DTS
     C                   Move      TIRTVD        RtvDTS                         * Retrieve DTS
     C                   Else
      * Calculate ignore interval (Source Contents change date if not Contents Difference)
     C                   Move      SICNTD        ChkDTS                         * Check DTS
     C                   Move      SIRTVD        RtvDTS                         * Retrieve DTS
     C                   EndIf
     C                   ExSR      SRClcItv                                     * Calculate interval
      * If interval greater than allowed interval --> write
     C     IGNIWY        IfGE      IGNIPA
     C                   Write     SYNIFS@
     C                   EndIf                                                  * Ignore interval
     C                   EndIf
     C                   EndIf                                                  * Not *EXC
      * Read next object
     C                   Clear                   SYNIFS@
     C                   Read      SYNID@                                 95
     C                   EndDo
      * Read the HCHKSYNIDT (Target) sequentially for Obsolete IFS Objects
     C                   Clear                   SYNIFS@
     C     *Loval        SetLL     SYNIDT@
     C                   Read      SYNIDT@                                95
     C     *In95         DowEQ     *Off
      * Only process included IFS objects
     C                   If        IDINC<>#EXC                                  * Not *EXC
      * Assume that there are no discrepancies
     C                   Move      *Off          IFSDif                         * IFS Object diff.
     C                   MoveL     'N'           IDMIT                          * Missing IFS Obj.
     C                   MoveL     'N'           IDMIS                          * Obsolete IFS Obj.
     C                   MoveL     'N'           IDID                           * IFS difference
      * First, check if the IFS Object exists on the source
     C                   Eval      tmpObj = IDOBJ
     C     ChkIFS        SetLL     SYNID@
     C     ChkIFS        ReadE     SYNID@                                 94
     C     *In94         DowEQ     *Off                                         * End of selection
     C     IDOBJ         AndNE     tmpObj                                       * Same object
      * If still not same object --> read next record
     C     IDOBJ         IfNE      tmpObj                                       * Same object
     C     ChkIFS        ReadE     SYNID@                                 94
     C                   EndIf
     C                   EndDo
      * Object doesn't exist --> Obsolete object
     C     *In94         IfEQ      *On                                          * Not existent
     C                   Move      *On           IFSDif                         * IFS Object diff.
     C                   MoveL     'Y'           IDMIS                          * Obsolete IFS Objec
     C                   EndIf
      * If object discrepancy --> write record
     C     IFSDif        IfEQ      *On
      * Calculate ignore interval (Contents change date)
     C                   Move      TICNTD        ChkDTS                         * Check DTS
     C                   Move      TIRTVD        RtvDTS                         * Retrieve DTS
     C                   ExSR      SRClcItv                                     * Calculate interval
      * If interval greater than allowed interval --> write
     C     IGNIWY        IfGE      IGNIPA
     C                   Write     SYNIFS@
     C                   EndIf                                                  * Ignore interval
     C                   EndIf
     C                   EndIf                                                  * Not *EXC
      * Read next IFS object
     C                   Clear                   SYNIFS@
     C                   Read      SYNIDT@                                95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRChkIFA - Check IFS authority discrepancies                        *
      * ------------------------------------------------------------------- *
     C     SRChkIFA      BegSR
      * Read the HCHKSYNIA (Source) sequentially for Missing IFS authorities
     C                   Clear                   SYNIFA@
     C     *Loval        SetLL     SYNIA@
     C                   Read      SYNIA@                                 95
     C     *In95         DowEQ     *Off
      * Assume that there are no discrepancies
     C                   Move      *Off          IFADif            1            * IFS auth. differen
     C                   MoveL     'N'           IAMAT                          * Missing IFS Aut.
     C                   MoveL     'N'           IAMAS                          * Obsolete IFS Aut.
     C                   MoveL     'N'           IAAD                           * IFS Aut. differenc
     C                   MoveL     'N'           IAOD                           * Owner difference
     C                   MoveL     'N'           IAFIX                          * Auth. fixed
      * First, check if the IFS authority exists on the target
     C                   Eval      tmpObj = IAOBJ
     C     ChkIFA        SetLL     SYNIAT@
     C     ChkIFA        ReadE     SYNIAT@                                94
     C     *In94         DowEQ     *Off                                         * End of selection
     C     IAOBJ         AndNE     tmpObj                                       * Same object
      * If still not same object --> read next record
     C     IAOBJ         IfNE      tmpObj                                       * Same object
     C     ChkIFA        ReadE     SYNIAT@                                94
     C                   EndIf
     C                   EndDo
     C                   Select
      * Auth. doesn't exist --> Missing IFS authority
     C     *In94         WhenEQ    *On                                          * Not existent
     C                   ExSR      SRRtvIFSA                                    * Retrieve IFS <-Aut
     C     IDMIT         IfNE      'Y'                                          * Missing object
     C                   Move      *On           IFADif                         * IFS Auth. diff.
     C                   MoveL     'Y'           IAMAT                          * Missing IFS auth.
     C                   EndIf
      * IFS auth. exists --> Determine discrepancies
     C     *In94         WhenEQ    *Off                                         * Existent
      * Owner differences
     C     SJOWN         IfNE      TJOWN                                        * Owner
     C                   Move      *On           IFADif                         * Auth. difference
     C                   Move      'Y'           IAOD                           * Owner difference
     C                   EndIf
      * Authority difference
     C     SJDTAA        IfNE      TJDTAA                                       * Data authority
     C     SJANAM        OrNE      TJANAM                                       * Authorisation list
     C     SJOPR         OrNE      TJOPR                                        * Operational
     C     SJOMGT        OrNE      TJOMGT                                       * Object management
     C     SJEXS         OrNE      TJEXS                                        * Existence
     C     SJREAD        OrNE      TJREAD                                       * Read
     C     SJADD         OrNE      TJADD                                        * Add
     C     SJUPD         OrNE      TJUPD                                        * Update
     C     SJDLT         OrNE      TJDLT                                        * Delete
     C     SJEXEC        OrNE      TJEXEC                                       * Execute
     C     SJALT         OrNE      TJALT                                        * Alter object
     C     SJREF         OrNE      TJREF                                        * Reference
     C     SJAMGT        OrNE      TJAMGT                                       * Auth. list managem
     C                   Move      *On           IFADif                         * Auth. difference
     C                   Move      'Y'           IAAD                           * Auth. difference
     C                   EndIf
     C                   EndSL
      * If IFS auth. discrepancy --> write record
     C     IFADif        IfEQ      *On
     C                   Write     SYNIFA@
     C                   EndIf
      * Read next object
     C                   Clear                   SYNIFA@
     C                   Read      SYNIA@                                 95
     C                   EndDo
      * Read the HCHKSYNIAT (Target) sequentially for Obsolete IFS Authorities
     C                   Clear                   SYNIFA@
     C     *Loval        SetLL     SYNIAT@
     C                   Read      SYNIAT@                                95
     C     *In95         DowEQ     *Off
      * Assume that there are no discrepancies
     C                   Move      *Off          IFADif                         * IFS auth. differen
     C                   MoveL     'N'           IAMAT                          * Missing IFS Aut.
     C                   MoveL     'N'           IAMAS                          * Obsolete IFS Aut.
     C                   MoveL     'N'           IAAD                           * IFS Aut. differenc
     C                   MoveL     'N'           IAOD                           * Owner difference
     C                   MoveL     'N'           IAFIX                          * Auth. fixed
      * First, check if the IFS auth. exists on the source
     C                   Eval      tmpObj = IAOBJ
     C     ChkIFA        SetLL     SYNIA@
     C     ChkIFA        ReadE     SYNIA@                                 94
     C     *In94         DowEQ     *Off                                         * End of selection
     C     IAOBJ         AndNE     tmpObj                                       * Same object
      * If still not same object --> read next record
     C     IAOBJ         IfNE      tmpObj                                       * Same object
     C     ChkIFA        ReadE     SYNIA@                                 94
     C                   EndIf
     C                   EndDo
      * Object doesn't exist --> Obsolete authority
     C     *In94         IfEQ      *On                                          * Not existent
     C                   ExSR      SRRtvIFSA                                    * Retrieve IFS <-Aut
     C     IDMIS         IfNE      'Y'                                          * Obsolete object
     C                   Move      *On           IFADif                         * IFS Auth. diff.
     C                   MoveL     'Y'           IAMAS                          * Obsolete IFS auth.
     C                   EndIf                                                  * Obsolete object
     C                   EndIf                                                  * Not existent
      * If object discrepancy --> write record
     C     IFADif        IfEQ      *On
     C                   Write     SYNIFA@
     C                   EndIf
      * Read next IFS authority
     C                   Clear                   SYNIFA@
     C                   Read      SYNIAT@                                95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRRtvObjM - Retrieve object discrepancy from member                 *
      * ------------------------------------------------------------------- *
     C     SRRtvObjM     BegSR
      * Clear all fields in the record
     C                   Clear                   SYNOBJ@
      * Fill the fields in the key list
     C                   MoveL     MBGRPN        ODGRPN                         * Group name
     C                   MoveL     MBCMPL        ODCMPL                         * Compare library
     C                   MoveL     MBCMPF        ODCMPO                         * Compare object
     C                   MoveL(p)  #FILE         ODOBTP                         * Object type
     C     ChkObj        SetLL     SYNOD@                                 96
     C     *In96         IfEQ      *Off                                         * Not found
     C                   MoveL     'Y'           ODMOS                          * Obsolete object
     C                   EndIf
     C     ChkObj        SetLL     SYNODT@                                96
     C     *In96         IfEQ      *Off                                         * Not found
     C                   MoveL     'Y'           ODMOT                          * Missing object
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRRtvObjA - Retrieve object discrepancy from authorisation          *
      * ------------------------------------------------------------------- *
     C     SRRtvObjA     BegSR
      * Clear all fields in the record
     C                   Clear                   SYNOBJ@
      * Fill the fields in the key list
     C                   MoveL     OAGRPN        ODGRPN                         * Group name
     C                   MoveL     OACMPL        ODCMPL                         * Compare library
     C                   MoveL     OACMPO        ODCMPO                         * Compare object
     C                   MoveL     OATYPE        ODOBTP                         * Object type
     C     ChkObj        SetLL     SYNOD@                                 96
     C     *In96         IfEQ      *Off                                         * Not found
     C                   MoveL     'Y'           ODMOS                          * Obsolete object
     C                   EndIf
     C     ChkObj        SetLL     SYNODT@                                96
     C     *In96         IfEQ      *Off                                         * Not found
     C                   MoveL     'Y'           ODMOT                          * Missing object
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRRtvIFSA - Retrieve IFS object discrepancy from authorisation      *
      * ------------------------------------------------------------------- *
     C     SRRtvIFSA     BegSR
      * Clear all fields in the record
     C                   Clear                   SYNIFS@
      * Fill the fields in the key list
     C                   MoveL     IAGRPN        IDGRPN                         * Group name
     C                   Eval      IDOBJK = IAOBJK                              * Object (key)
     C                   Eval      IDOBJ = IAOBJ                                * Object
      * Check if there is an IFS discrepancy record for the authority record
     C                   Eval      tmpObj = IDOBJ
     C     ChkIFS        SetLL     SYNIFS@
     C     ChkIFS        ReadE     SYNIFS@                                94
     C     *In94         DowEQ     *Off                                         * End of selection
     C     IDOBJ         AndNE     tmpObj                                       * Same object
      * If still not same object --> read next record
     C     IDOBJ         IfNE      tmpObj                                       * Same object
     C     ChkIFS        ReadE     SYNIFS@                                94
     C                   EndIf
     C                   EndDo
      * If object not found in HCHKSYNIFS --> Blank IDMIT and IDMIS
     C     IDOBJ         IfNE      tmpObj                                       * Same object
     C                   Eval      IDMIT = *Blanks                              * Missing object
     C                   Eval      IDMIS = *Blanks                              * Obsolete object
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRClcItv - Calculate interval between the two date/times (minutes)  *
      * ------------------------------------------------------------------- *
     C     SRClcItv      BegSR
     C                   Clear                   IGNIWY                         * Ignore interval
     C     RtvDTS        SubDur    ChkDTS        IGNIWY:*MN                     * Ignore interval
     C     IGNIWY        IfLT      *Zero
     C                   Mult      -1            IGNIWY                         * Make positive
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRCvtDTS - Convert string date-time to date, time & DTS fields      *
      * ------------------------------------------------------------------- *
     C     SRCvtDTS      BegSR
     C                   Clear                   CvtDat                         * Convert date
     C                   Clear                   CvtTim                         * Convert time
     C                   Clear                   CvtDTS                         * Convert timestamp
      * Convert the date dependent on date format
     C                   Select
      * Convert dates in *JOBRUN format
     C     DatFmt        WhenEQ    #Jobrun                                      * *JOBRUN0
     C     *JOBRUN0      Test(D)                 ChrDat                 91      * Check date
     C     *In91         IfEQ      *On                                          * Erroneous date
     C                   Clear                   CvtDat                         * Convert date
     C                   Else
     C     *JOBRUN0      Move      ChrDat        CvtDat                         * Convert date
     C                   EndIf
      * Convert dates in *MDY format
     C     DatFmt        WhenEQ    #MDY                                         * *MDY0
     C     *MDY0         Test(D)                 ChrDat                 91      * Check date
     C     *In91         IfEQ      *On                                          * Erroneous date
     C                   Clear                   CvtDat                         * Convert date
     C                   Else
     C     *MDY0         Move      ChrDat        CvtDat                         * Convert date
     C                   EndIf
      * Convert dates in *YMD format
     C     DatFmt        WhenEQ    #YMD                                         * *YMD0
     C     *YMD0         Test(D)                 ChrDat                 91      * Check date
     C     *In91         IfEQ      *On                                          * Erroneous date
     C                   Clear                   CvtDat                         * Convert date
     C                   Else
     C     *YMD0         Move      ChrDat        CvtDat                         * Convert date
     C                   EndIf
     C                   EndSL
      * Convert the time
     C     *HMS0         Test(T)                 ChrTim                 91      * Check time
     C     *In91         IfEQ      *On                                          * Erroneous time
     C                   Clear                   CvtTim                         * Convert date
     C                   Else
     C     *HMS0         Move      ChrTim        CvtTim                         * Convert time
     C                   EndIf
      * Move date and time field into DTS
     C                   Move      CvtDat        CvtDTS                         * Convert DTS
     C                   Move      CvtTim        CvtDTS                         * Convert DTS
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
