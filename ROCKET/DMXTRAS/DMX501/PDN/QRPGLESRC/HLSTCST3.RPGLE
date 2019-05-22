      * ============================================================ *
      * Object:    HLSTCST3        *PGM RPG                          *
      *            Fill the target/group name and remove constraints *
      *            records for files not in selection                *
      *                                                              *
      * Synopsis:  See Command HLSTCST.                              *
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
      * Constraints
     FHLSTCST   UF   E           K DISK
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
     C     LimCst        KList
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
      * Process all constraints with blank target/group and fill
     C     LimCst        SetLL     HLSTCST@
     C     LimCst        ReadE     HLSTCST@                               95
     C     *In95         DoWEQ     *Off
      * Fill target and group
     C                   MoveL     GRPNPA        CSGRPN                         * Group name
      * Check if object must be included or excluded
     C                   Call      'HMTCOBJ'
     C                   Parm                    CSGRPN                         * Group name
     C                   Parm                    CSLIB                          * Library
     C                   Parm                    CSFILE                         * File (object)
     C                   Parm      #FILE         OBJTWY            8            * Object type
     C                   Parm      #PFDTA        OBJAWY           10            * Object attribute
     C                   Parm                    INCWY             4            * Included?
      * If object excluded --> delete, else update target and group
     C     INCWY         IfEQ      #YES                                         * *YES
     C                   Update    HLSTCST@
     C                   Else
     C                   Delete    HLSTCST@
     C                   EndIf
     C     LimCst        ReadE     HLSTCST@                               95
     C                   EndDo
      *
     C                   Return
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
