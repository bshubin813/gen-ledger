      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HCHKSYN1        *PGM RPG                          *
      *            Processes all object specifiers for the specified *
      *            target definition and retrieves object- and       *
      *            member descriptions.                              *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20000227 FK  Initial delivery                                *
      * 20000422 FK  Also process objects if object not *ALL         *
      * 20000705 FK  Use logical files in QTEMP                      *
      * 20001013 FK  Include group selection                         *
      * 20001203 FK  Handle exclusions by group                      *
      * 20001217 FK  Different target library handling               *
      * 20010809 FK  Mark existing/included libraries                *
      * 20010906 FK  Only process libraries if library file specified*
      * 20011217 FK  Omit BSF objects (through LF)                   *
      * 20020110 FK  Process from HCHKSYNCFG file                    *
      * 20021111 FK  Process from HLSTCFGO file                      *
      * 20021119 FK  Process only includes                           *
      * 20031010 FK  Fill target/group when library changes          *
      * 20031208 FK  Fill target library if different                *
      * 20050517 FK  Library referenced not checked properly         *
      * 20051010 FK  Different target library various errors         *
      * 20060323 FK  Check location of journal                       *
      * 20060327 FK  Do not include QSYS in non-existing libraries   *
      * 20111217 FK  Remove HA                                       *
      * ============================================================ *
      * Group configuration file
     FHLSTCFGG  IF   E           K Disk
      * Configuration file to be processed
     FHLSTCFGO  IF   E           K Disk
      * Library descriptions
     FHCHKSYNLD UF A E           K Disk    UsrOpn
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#QSys            C                   CONST('QSYS')
     D#ALL             C                   CONST('*ALL')
     D#YES             C                   CONST('*YES')
     D#NO              C                   CONST('*NO ')
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Limit group configuration by group
     C     ChnCFGG       KList
     C                   KFld                    GRPNPA                         * Group name
      * Limit object configuration by group
     C     LimCFGO       KList
     C                   KFld                    GRPNPA                         * Group name
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    GRPNPA           10            * Group name
     C                   Parm                    CHKMPA            4            * Check members
     C                   Parm                    CHKLPA            4            * Check libraries
     C                   Parm                    ROLEPA            1            * Primary/Secondary
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
      * Open library file?
     C                   If        CHKLPA = #YES                                * CHKLIB(*YES)
     C                             and ROLEPA = 'P'                             * Primary
     C                   Open      HCHKSYNLD
     C                   EndIf
      * Get group definition
     C     ChnCFGG       Chain     LSTCFGG@                           96
      * Process all records in the HLSTCFGO file
     C     LimCFGO       SetLL     LSTCFGO@
     C     LimCFGO       ReadE     LSTCFGO@                               95
     C     *In95         DowEQ     *Off
      * Determine object library, dependent on role of target and target library
     C                   MoveL     LOLIB         OBJLWY           10            * Object library
     C     ROLEPA        IfEQ      'S'                                          * Secondary system
     C                   MoveL     LOLIBT        OBJLWY                         * Object library
     C                   EndIf
      * If libraries must be processed
     C                   If        CHKLPA = #YES                                * CHKLIB(*YES)
     C                             and ROLEPA = 'P'                             * Primary
      * Mark existence / inclusion of the library
     C     LOLIB         SetLL     SYNLD@                                 93
      * If library does not exist --> Mark in HCHKSYNLD
     C     *In93         IfEQ      *Off                                         * Non-existing lib
     C                   MoveL     LOLIB         ODOBNM                         * Library name
     C                   MoveL     LOGRPN        LDGRPN                         * Group name
     C                   MoveL     #NO           LDLEXS                         * Library exists?
     C                   Write     SYNLD@
      * If library referenced --> Mark in HCHKSYNLD
     C                   Else
     C     LOLIB         Chain     SYNLD@                             93
     C     LDLREF        IfNE      #YES
     C                   MoveL     LOGRPN        LDGRPN                         * Group name
     C                   MoveL     #YES          LDLREF                         * Library referenced
     C                   Update    SYNLD@
     C                   Else
     C                   Unlock    HCHKSYNLD
     C                   EndIf                                                  * Library referenced
     C                   EndIf                                                  * Library exists?
     C                   EndIf                                                  * Libraries process?
      * Retrieve object- and member descriptions to temp output file
     C     LOINCF        IfEQ      'Y'                                          * *INCLUDE
     C                   CALL      'HCHKSYN2'
     C                   Parm                    GRPNPA                         * Group name
     C                   Parm                    LOOBJ                          * Object name
     C                   Parm                    LOOBJT                         * Object type
     C                   Parm                    OBJLWY                         * Object library
     C                   Parm                    CHKMPA                         * Check members?
      * Fill empty fields
     C                   Call      'HCHKSYN2B'
     C                   Parm                    GRPNPA                         * Group name
     C                   Parm                    OBJLWY                         * Object library
     C                   Parm                    LOLIB                          * Original library
     C                   Parm                    LOLIBT                         * Target library
     C                   Parm                    ROLEPA                         * Primary/Secondary
     C                   Parm                    LGJRNLOC                       * Journal location
     C                   Parm                    LOCNTS                         * Mirror contents
     C                   Parm                    LOSEQ                          * Sequence
     C                   EndIf
      * Process next object specifier
     C     LimCFGO       ReadE     LSTCFGO@                               95
     C                   EndDo
      * Remove duplicates and flag excludes
     C                   Call      'HCHKSYN5'
     C                   Parm                    GRPNPA                         * Saved group name
     C                   Parm                    CHKMPA                         * Check members
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
