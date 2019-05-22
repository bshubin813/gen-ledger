      * ============================================================ *
      * Object:    HLSTTRG3        *PGM RPG                          *
      *            Fill the group name and remove trigger            *
      *            records for files not in selection                *
      *                                                              *
      * Synopsis:  See Command HLSTTRG.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20030114 FK  Initial delivery                                *
      * 20111217 FK  REMOVE HA                                       *
      * ============================================================ *
      * Triggers
     FHLSTTRG   UF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #FILE           C                   Const('*FILE   ')
     D #PFDTA          C                   Const('PF-DTA    ')
     D #YES            C                   Const('*YES')
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     LimTrg        KList
     C                   KFld                    GRPNWY           10            * Group name (blank)
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    GRPNPA           10            * Group name
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Clear                   GRPNWY                         * Group name (blank)
      * Process all triggers with blank target/group and fill
     C     LimTrg        SetLL     HLSTTRG@
     C     LimTrg        ReadE     HLSTTRG@                               95
     C     *In95         DoWEQ     *Off
      * Fill target and group
     C                   MoveL     GRPNPA        TRGRPN                         * Group name
      * Check if object must be included or excluded
     C                   Call      'HMTCOBJ'
     C                   Parm                    TRGRPN                         * Group name
     C                   Parm                    TRLIB                          * Library
     C                   Parm                    TRFILE                         * File (object)
     C                   Parm      #FILE         OBJTWY            8            * Object type
     C                   Parm      #PFDTA        OBJAWY           10            * Object attribute
     C                   Parm                    INCWY             4            * Included?
      * If object excluded --> delete, else update target and group
     C     INCWY         IfEQ      #YES                                         * *YES
     C                   Update    HLSTTRG@
     C                   Else
     C                   Delete    HLSTTRG@
     C                   EndIf
     C     LimTrg        ReadE     HLSTTRG@                               95
     C                   EndDo
      *
     C                   Return
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
