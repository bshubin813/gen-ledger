      * ============================================================ *
      * Object:    HCHKSYN6        *PGM RPG                          *
      *            Processes all "Include" IFS object specifiers     *
      *            and calls the program that retrieves the objects  *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20020523 FK  Initial delivery                                *
      * 20021204 FK  Process from HLSTCFGI file                      *
      *              Process only includes                           *
      * 20050211 FK  No intermediate copy                            *
      * 20051010 FK  Only first record read                          *
      * 20111217 FK  REMOVE HA                                       *
      * ============================================================ *
      * Configuration file to be processed
     FHLSTCFGI  IF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
     D PathWY          S           5000
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Limit object configuration by target/group
     C     LimCFGI       KList
     C                   KFld                    GRPNPA                         * Group name
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    GRPNPA           10            * Group name
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Process all records in the HLSTCFGI file
     C     LimCFGI       SetLL     LSTCFGI@
     C     LimCFGI       ReadE     LSTCFGI@                               95
     C     *In95         DowEQ     *Off
      * Retrieve IFS Object descriptions to temp output file
     C     LIINCF        IfEQ      'Y'                                          * *INCLUDE
     C                   If        %len(LIREL) <> 0
     C                   Eval      PathWY=%subst(LIBASE:1:%len(LIBASE)-1) +
     C                                    LIREL
     C                   Else
     C                   Eval      PathWY=LIBASE
     C                   EndIf
     C                   Call      'HCHKSYN6A'
     C                   Parm                    LIGRPN                         * Group name
     C                   Parm                    PathWY                         * Path to process
     C                   EndIf
      * Process next object specifier
     C     LimCFGI       ReadE     LSTCFGI@                               95
     C                   EndDo
      * Remove excludes
     C                   Call      'HCHKSYN6D'
     C                   Parm                    GRPNPA                         * Saved group name
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
