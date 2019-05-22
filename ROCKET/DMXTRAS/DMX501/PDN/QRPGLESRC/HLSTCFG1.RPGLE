      * ============================================================ *
      * Object:    HLSTCFG1        *PGM RPG                          *
      *            Builds object configuration file.                 *
      *                                                              *
      * Synopsis:  See Command HLSTCFG.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20020917 FK  Initial delivery                                *
      * 20021104 FK  Allow for configuration type                    *
      * 20021122 FK  Determine sequence for IFS path                 *
      * 20030115 FK  Include HMIRIFS object specifiers               *
      * 20030117 FK  Terminate DLS path name with X'00'              *
      * 20030424 FK  iCluster support                                *
      * 20040119 FK  Only process local groups for iCluster          *
      * 20040319 FK  Handle different target library for iCluster    *
      * 20050201 FK  Allow specify of backup node                    *
      *              Remove reference to HMIRIFS                     *
      * 20050210 FK  Build HLSTCFGG file                             *
      * 20050224 FK  Allow backup node *FIRST                        *
      * 20060206 FK  Allow generic group name and marked string      *
      * 20060215 FK  Include node information from group             *
      * 20060317 FK  Include journal info for group                  *
      * 20080107 FK  Support for mirror contents                     *
      * 20111217 FK  remove HA                                       *
      * ============================================================ *
      * iCluster groups by group
     FHIGRPGN21 IF   E           K DISK    USROPN
      * iCluster objects by group/library
     FHIOBJGL   IF   E           K DISK    USROPN
      * iCluster objects by group/library, iC 5.0+
     FHIOBJGL50 IF   E           K DISK    USROPN
      * iCluster BSF objects by group
     FHIBSFGN   IF   E           K DISK    USROPN
      * Groups configuration
     FHLSTCFGG  O    E           K DISK
      * Object configuration to be built
     FHLSTCFGO  O    E           K DISK    USROPN
      * IFS configuration to be built
     FHLSTCFGI  O    E           K DISK    USROPN
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
     D SrcSysVals     UDS           600    DTAARA(DMSRCSVALS)
     D  SVDBJrn              112    121                                         * Dft DB Jrn
     D  SVDBJrnL             122    131                                         * Dft DB Jrn lib
     D  SVJrnBck             138    138                                         * Journal on backup
     D  SVBSFJrn             141    150                                         * Dft BSF Jrn
     D  SVBSFJrnL            151    160                                         * Dft BSF Jrn lib
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#ALL             C                   CONST('*ALL')
     D#FIRST           C                   CONST('*FIRST')
     D#MRKSTR          C                   CONST('*MRKSTR')
     D#OBJ             C                   CONST('*OBJ')
     D#IFS             C                   CONST('*IFS')
     D#YES             C                   CONST('*YES')
     D#NO              C                   CONST('*NO ')
     D#Include         C                   CONST('*INCLUDE')
     D#ICluster        C                   CONST('*ICLUSTER')
     D#Cluster         C                   CONST('*CLUSTER')
     D#Local           C                   CONST('*LCL')
     D#Remote          C                   CONST('*RMT')
     D#TgtDft          C                   CONST('*TGTDFT')
     D#ProdDft         C                   CONST('*PRODDFT')
      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D StrPos          S              3  0                                      * Position of string
     D GenName         s              9a                                        * Generic name
     D GrpSel          s               n                                        * Group selected
     D PathWY          S           5000
     D TgtDftDB        S             20a                                        * Target DB journal
     D TgtDftBSF       S             20a                                        * Target BSF journal
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    ICGRPA           10            * iCluster group
     C                   Parm                    CFGTPA            4            * Configuration type
     C                   Parm                    SYSNPA            8            * System name
     C                   Parm                    BCKNPA            8            * Backup node
     C                   Parm                    MRKSPA            4            * Marked by string
     C                   Parm                    ICVERPA           6            * iCluster version
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Open Object configuration file (if selected)
     C     CFGTPA        IfEQ      #OBJ                                         * *OBJ
     C     CFGTPA        OrEQ      #ALL                                         * *ALL
     C                   Open      HLSTCFGO                                     * Object configurati
     C                   EndIf
      * Open IFS configuration file (if selected)
     C     CFGTPA        IfEQ      #IFS                                         * *IFS
     C     CFGTPA        OrEQ      #ALL                                         * *ALL
     C                   Open      HLSTCFGI                                     * IFS Configuration
     C                   EndIf
      * Dependent on configuration for HA suite or iCluster --> run subroutine
     C                   ExSR      SRLstIC
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *

      * ------------------------------------------------------------------- *
      * SRLstIC - List iCluster objects                                     *
      * ------------------------------------------------------------------- *
     C     SRLstIC       BegSR
      * Get source system values
     C                   In        SrcSysVals
      * Check if group name is generic
     C     '*'           Scan      ICGRPA:2      StrPos                         * Find asteriks
     C                   if        StrPos>0
     C                   Eval      StrPos=StrPos-1
     C                   Eval      GenName=%Subst(ICGRPA:1:StrPos)
     C                   EndIf
      * Open files for iCluster
     C                   Open      HIGRPGN21                                    * Group definitions
      * Open Object configuration file (if selected)
     C     CFGTPA        IfEQ      #OBJ                                         * *OBJ
     C     CFGTPA        OrEQ      #ALL                                         * *ALL
     C                   If        ICVERPA < 'iC 5.0'                           * iC 5.0?
     C                   Open      HIOBJGL                                      * Object specifiers
     C                   Else                                                   * iC 5.0?
     C                   Open      HIOBJGL50                                    * Object specifiers
     C                   EndIf                                                  * iC 5.0?
     C                   EndIf
      * Open IFS configuration file (if selected)
     C     CFGTPA        IfEQ      #IFS                                         * *IFS
     C     CFGTPA        OrEQ      #ALL                                         * *ALL
     C                   Open      HIBSFGN                                      * IFS Object spec.
     C                   EndIf
      * Process all specified groups or resilient application
     C     *Loval        SetLL     HIGRPGN@
     C                   Read      HIGRPGN@                               95
     C     *IN95         DowEQ     *Off
      * Is the group for the local system?
     C     CURRPRIM      IfEQ      SYSNPA                                       * Current system
      * Check if group name matches selection criteria
     C                   Eval      GrpSel=*Off                                  * Group not selected
     C                   Select
     C                   When      ICGRPA=#ALL                                  * *ALL
     C                   Eval      GrpSel=*On                                   * Group selected
     C                   When      GROUP=ICGRPA                                 * Exact same name
     C                   Eval      GrpSel=*On                                   * Group selected
     C                   When      (StrPos>0 and %Subst(GROUP:1:StrPos)=        * Generic name
     C                              GenName)
     C                   Eval      GrpSel=*On                                   * Group selected
     C                   When      ICGRPA=#MRKSTR and                           * *MRKSTR
     C                             %Scan(%TrimR(MRKSPA):DESC)>0                 * String in desc
     C                   Eval      GrpSel=*On                                   * Group selected
     C                   EndSL
      * If selection on backup node, retrieve current group's backup node
     C                   If        GrpSel
     C                   Eval      GrpSel=*Off                                  * Group not selected
     C     BCKNPA        IfNE      #ALL                                         * All backup nodes
     C                   Call      'HLSTCFG2'
     C                   Parm                    GROUP                          * Group name
     C                   Parm                    BCKNWY            8            * Backup node
      * If backup node *FIRST --> fill selection parameter
     C     BCKNPA        IfEQ      #FIRST                                       * First backup node
     C                   MoveL     BCKNWY        BCKNPA                         * Backup node
     C                   EndIf                                                  * First backup node
     C                   EndIf                                                  * All backup node
     C     BCKNPA        IfEQ      #ALL                                         * All backup nodes
     C     BCKNWY        OrEQ      BCKNPA                                       * Specified node
     C                   Eval      GrpSel=*On                                   * Group selected
     C                   EndIf                                                  * Same backup node
     C                   EndIf                                                  * Group selected
     C                   If        GrpSel
      * Fill values for group record
     C                   MoveL     GROUP         LGGRPN                         * Group name
     C                   MoveL     DESC          LGDESC                         * Group name
     C                   MoveL     CURRPRIM      LGPRINOD                       * Primary node
     C                   MoveL     BACKUP        LGBCKNOD                       * Backup node
      * Fill journal name
     C                   Eval      LGDFTJRN=%Subst(DFTDBJRN:1:10)               * Default DB journal
     C                   Eval      LGDFTJRNL=%Subst(DFTDBJRN:11:10)             * Default DB lib
     C                   If        LGDFTJRN=#Cluster                            * *CLUSTER
     C                   Eval      LGDFTJRN=SVDBJrn                             * DB Journal
     C                   Eval      LGDFTJRNL=SVDBJrnL                           * DB Journal lib
     C                   EndIf
     C                   Eval      LGDFTBSF=%Subst(DFTBSFJRN:1:10)              * Default BSF jrn
     C                   Eval      LGDFTBSFL=%Subst(DFTBSFJRN:11:10)            * Default BSF lib
     C                   If        LGDFTBSF=#Cluster                            * *CLUSTER
     C                   Eval      LGDFTBSF=SVBSFJrn                            * BSF Journal
     C                   Eval      LGDFTBSFL=SVBSFJrnL                          * BSF Journal lib
     C                   EndIf
      * Fill journal on backup
     C                   If        SVJrnBck='Y'                                 * Journal on backup?
     C                   Eval      LGJRNBCK=#YES                                * Journal on backup
     C                   Else                                                   * Not journal backup
     C                   Eval      LGJRNBCK=#NO                                 * Not journal backup
     C                   EndIf                                                  * Journal on backup?
      * Fill journal location
     C                   If        JRNLOC='R'                                   * Remote journal
     C                   Eval      LGJRNLOC=#Remote                             * Journal location
     C                   Else                                                   * Local journal
     C                   Eval      LGJRNLOC=#Local                              * Journal location
     C                   EndIf                                                  * Remote journal?
     C                   Write     LSTCFGG@                                     * Configuration
      * Retrieve object specifier for library object
     C     CFGTPA        IfEQ      #OBJ                                         * *OBJ
     C     CFGTPA        OrEQ      #ALL                                         * *ALL
      * Process all object specifiers for the group
     C                   If        ICVERPA < 'iC 5.0'                           * iC 5.0?
     C     GROUP         SetLL     HIOBJGL@
     C     GROUP         ReadE     HIOBJGL@                               96
     C                   Else                                                   * iC 5.0?
     C     GROUP         SetLL     HIOBJGL50@
     C     GROUP         ReadE     HIOBJGL50@                             96
     C                   EndIf                                                  * iC 5.0?
     C     *IN96         DowEQ     *OFF
      * Now prepare to write to configuration file
     C                   MoveL     GROUP         LOGRPN                         * Group name
     C                   MoveL     LIB           LOLIB                          * Library
     C                   MoveL     OBJ           LOOBJ                          * Object
     C                   MoveL     TYPE          LOOBJT                         * Object type
     C                   MoveL     ATTR          LOOBJA                         * Object attribute
     C                   MoveL     MIRRCNTS      LOCNTS                         * Mirror contents?
     C                   If        LOCNTS=' '                                   * Mirror contents?
     C                   Eval      LOCNTS='Y'
     C                   EndIf                                                  * Mirror contents?
     C                   MoveL     INCLUDE       LOINCF                         * Include/exclude
      * Determine object library, dependent object specifier and grous specifier
     C                   MoveL     OBJTGTLIB     LOLIBT                         * Target library
     C     LOLIBT        IfEQ      '*GROUP'
     C                   MoveL     GRPTGTLIB     LOLIBT                         * Target library
     C                   EndIf
     C     LOLIBT        IfEQ      '*PRIMARY'                                   * Source library
     C     LOLIBT        OrEQ      *Blanks                                      * Source library
     C                   MoveL     LIB           LOLIBT                         * Object library
     C                   EndIf
      * Determine the processing sequence for the object specifier
     C                   ExSR      SRClcOsq
      * Write the object specifier record
     C                   Write     LSTCFGO@                                     * Configuration
     C                   If        ICVERPA < 'iC 5.0'                           * iC 5.0?
     C     GROUP         ReadE     HIOBJGL@                               96
     C                   Else                                                   * iC 5.0?
     C     GROUP         ReadE     HIOBJGL50@                             96
     C                   EndIf                                                  * iC 5.0?
     C                   EndDo                                                  * Objects per group
     C                   EndIf                                                  * Objects
      * Process all BSF object specifiers for the group
     C     CFGTPA        IfEQ      #IFS                                         * *IFS
     C     CFGTPA        OrEQ      #ALL                                         * *ALL
      * Process all object specifiers for the group
     C     GROUP         SetLL     HIBSFGN@
     C     GROUP         ReadE     HIBSFGN@                               96
     C     *IN96         DowEQ     *OFF
      * Now prepare to write to configuration file
     C                   MoveL     GROUP         LIGRPN                         * Group name
     C                   MoveL     INCLUDE       LIINCF                         * Include/exclude
     C                   Eval      LIBASE = PATH                                * Path
      * Determine the processing sequence number for the BSF object
     C                   Eval      PathWY=LIBASE
     C     '*'           Scan      PathWY:1      LISEQ                          * Sequence number
     C     LISEQ         IfEQ      0                                            * No * found
     C                   Z-Add     *Hival        LISEQ                          * Highest value
     C                   EndIf
      * Write the BSF object specifier record
     C                   Write     LSTCFGI@                                     * Configuration
     C     GROUP         ReadE     HIBSFGN@                               96
     C                   EndDo                                                  * Objects per group
     C                   EndIf                                                  * BSF Objects
     C                   EndIf                                                  * Group selected
     C                   EndIf                                                  * Current system?
      * Process next group
     C                   Read      HIGRPGN@                               95
     C                   EndDo                                                  * Group
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRClcOsq - Calculate object specifier sequence number               *
      * ------------------------------------------------------------------- *
     C     SRClcOsq      BegSR
     C                   Select
      * *ALL specified for Object, Type and Attribute
     C     LOOBJ         WhenEQ    #ALL                                         * *ALL
     C     LOOBJT        AndEQ     #ALL                                         * *ALL
     C     LOOBJA        AndEQ     #ALL                                         * *ALL
     C                   Z-Add     0             LOSEQ                          * Sequence
      * *ALL specified for Object and Attribute
     C     LOOBJ         WhenEQ    #ALL                                         * *ALL
     C     LOOBJA        AndEQ     #ALL                                         * *ALL
     C                   Z-Add     10            LOSEQ                          * Sequence
      * *ALL specified for Object only
     C     LOOBJ         WhenEQ    #ALL                                         * *ALL
     C                   Z-Add     20            LOSEQ                          * Sequence

      * Generic object specifier?
     C                   Other
     C     '*'           Scan      LOOBJ:1       PosWY             2 0          * Position
     C                   Select
      * Generic* specified for Object, Type(*ALL) and Attribute(*ALL)
     C     PosWY         WhenNE    0                                            * Generic*
     C     LOOBJT        AndEQ     #ALL                                         * *ALL
     C     LOOBJA        AndEQ     #ALL                                         * *ALL
     C     29            Add       PosWY         LOSEQ                          * Sequence
      * Generic* specified for Object, Attribute(*ALL)
     C     PosWY         WhenNE    0                                            * Generic*
     C     LOOBJA        AndEQ     #ALL                                         * *ALL
     C     39            Add       PosWY         LOSEQ                          * Sequence
      * Generic* specified for Object only
     C     PosWY         WhenNE    0                                            * Generic*
     C     49            Add       PosWY         LOSEQ                          * Sequence

      * Specific object specifier
      * Object specifier, Type(*ALL) and Attribute(*ALL)
     C     PosWY         WhenEQ    0                                            * Specific
     C     LOOBJT        AndEQ     #ALL                                         * *ALL
     C     LOOBJA        AndEQ     #ALL                                         * *ALL
     C                   Z-Add     60            LOSEQ                          * Sequence
      * Object specifier, Attribute(*ALL)
     C     PosWY         WhenEQ    0                                            * Specific
     C     LOOBJA        AndEQ     #ALL                                         * *ALL
     C                   Z-Add     70            LOSEQ                          * Sequence
      * Object specifier, specific type, specific attribute
     C     PosWY         WhenEQ    0                                            * Specific
     C                   Z-Add     80            LOSEQ                          * Sequence

     C                   EndSL                                                  * Generic?
     C                   EndSL                                                  * *ALL?
     C                   EndSR
