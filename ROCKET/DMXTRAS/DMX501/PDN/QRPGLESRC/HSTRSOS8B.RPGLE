      * ============================================================ *
      * Object:    HSTRSOS8B       *PGM RPG                          *
      *            Fills the system type and deletes all records     *
      *            before the first SOS0100 message                  *
      *                                                              *
      * Synopsis:  See Command HSTRSOS.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20030206 FK  Initial delivery                                *
      * ============================================================ *
      * Switchover Job log
     FHSOSLOG   UF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     LimSys        KList
     C                   KFld                    SYSWY             4            * System type (blank
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    SYSPA             4            * System type
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Clear                   SYSWY                          * System type (blank
     C                   Move      *Off          SOSFlg            1            * SOS Start flag
      * Process all records with blank system type
     C     LimSys        SetLL     HSOSLOG@
     C     LimSys        ReadE     HSOSLOG@                               95
     C     *In95         DoWEQ     *Off
      * Set start flag if message is 'SOS0100'
     C     QMHMID        IfEQ      'SOS0100'                                    * Checkpoint message
     C                   Move      *On           SOSFlg                         * SOS Start flag
     C                   EndIf
      * If start flag not set yet --> delete record
     C     SOSFlg        IfEQ      *Off
     C                   Delete    HSOSLOG@
      * Fill the system type
     C                   Else
     C                   MoveL     SYSPA         SLSYS                          * System type
     C                   Update    HSOSLOG@
     C                   EndIf
      *
     C     LimSys        ReadE     HSOSLOG@                               95
     C                   EndDo
     C                   SETON                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
