      *CP: ALWNULL(*USRCTL)
      * ============================================================ *
      * Object:    HMONJRN1B       *PGM RPG                          *
      *            Processes the OMFHLOG file and reports replic-    *
      *            ation lags greater than the allowed lag           *
      *                                                              *
      * Synopsis:  See Command HMONJRNLAG.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20031006 FK  Initial delivery                                *
      * ============================================================ *
      * History monitor entries
     FHUFHLTS   IF   E           K DISK
      * Journal replication lag by System, type, date-time, journal
     FHJRNLAGDJ IF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available

      * Date-time in YYYYMMDDHHMMSSUUUUU format
     D DTSDS           DS            20
     D  DatTimWY               1     14
     D  DateWY                 1      8
     D  TimeWY                 9     14
     D  MillWY                15     20    INZ('00000')

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *
     D DTSWY           S               Z                                        * Date-Time stamp
     D DTSMWY          S               Z                                        * Date-Time stamp
     D LstJrnSeq       s             20a                                        * Journal position
     D SrcJrnSeq       s             20a                                        * Journal position
     D TgtJrnSeq       s             20a                                        * Journal position

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #HST            C                   CONST('*HST')

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     PosLag        KList
     C                   KFld                    SYSNPA                         * System name
     C                   KFld                    TYPMWY                         * Measurement type
     C                   KFld                    DTSMWY                         * Measurement dts
     C     LimLag        KList
     C                   KFld                    SYSNPA                         * System name
     C                   KFld                    TYPMWY                         * Measurement type
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    SYSNPA            8            * System name
     C                   Parm                    DTSSPA           26            * Start dts

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * First determine when the previous measurement was done and determine starting point
     C                   MoveL     #HST          TYPMWY            4            * Measurement type
     C                   Move      *Hival        DTSMWY                         * Date-Time stamp
     C     PosLag        SetGT     HJRNLAG@
     C     LimLag        ReadPE    HJRNLAG@                               96
     C     *In96         IfEQ      *Off                                         * Record found
     C     JLDTSM        AddDur    1:*S          DTSMWY                         * Date-Time stamp
     C                   Else
     C                   Move      *Loval        DTSMWY                         * Date-Time stamp
     C                   EndIf
     C                   Move      DTSMWY        DTSSPA                         * Start DTS
      * Convert the starting date-time to the positioning value
     C     *ISO0         MoveL     DTSMWY        DTSDS
     C     DatTimWY      SetLL     HUFHLTS@
     C                   Read      HUFHLTS@                               95
     C     *In95         DowEQ     *Off
      * If Monitor entry --> Process
     C     RCDTYP        IfEQ      'MO'                                         * Monitor entry
      * Convert measurement date-time stamp
     C                   Clear                   DTSDS
     C                   MoveL     RCDTIMSTMP    DatTimWY
     C     *ISO0         MoveL     DTSDS         DTSMWY                         * Measurement DTS
      * Retrieve date-time stamp for last journal entry
     C                   Move      LASTJPOS      LstJrnSeq                      * Convert to char20
     C                   Call      'HMONJRN5'
     C                   Parm                    JRN                            * Journal
     C                   Parm                    JRNLIB                         * Journal library
     C                   Parm                    LASTJRCV                       * Last receiver
     C                   Parm                    LASTJRLIB                      * Last receiver lib
     C                   Parm                    LstJrnSeq                      * Last position
     C                   Parm                    LASTJDTS         26            * Last date-time
      * Retrieve date-time stamp for source journal entry
     C                   Move      SRCJPOS       SrcJrnSeq                      * Convert to char20
     C                   Call      'HMONJRN5'
     C                   Parm                    JRN                            * Journal
     C                   Parm                    JRNLIB                         * Journal library
     C                   Parm                    SRCJRCV                        * Source receiver
     C                   Parm                    SRCJRLIB                       * Source receiver li
     C                   Parm                    SrcJrnSeq                      * Source position
     C                   Parm                    SRCJDTS          26            * Source date-time
      * Retrieve date-time stamp for apply journal entry
     C                   Move      TGTJPOS       TgtJrnSeq                      * Convert to char20
     C                   Call      'HMONJRN5'
     C                   Parm                    JRN                            * Journal
     C                   Parm                    JRNLIB                         * Journal library
     C                   Parm                    TGTJRCV                        * Apply receiver
     C                   Parm                    TGTJRLIB                       * Apply receiver lib
     C                   Parm                    TgtJrnSeq                      * Apply position
     C                   Parm                    TGTJDTS          26            * Apply date-time
      * Add record to the journal lag file
     C                   Call      'HMONJRN2'
     C                   Parm                    SYSNPA                         * System name
     C                   Parm                    TYPMWY                         * Measurement type
     C                   Parm                    TGTSYS                         * Target
     C                   Parm                    GROUP                          * Group
     C                   Parm                    JRN                            * Journal
     C                   Parm                    JRNLIB                         * Journal library
     C                   Parm                    DTSMWY                         * Measurement DTS
     C                   Parm                    LASTJRCV                       * Last receiver
     C                   Parm                    LASTJRLIB                      * Last receiver lib
     C                   Parm                    LstJrnSeq                      * Last position
     C                   Parm                    LASTJDTS                       * Last date-time
     C                   Parm                    SRCJRCV                        * Source receiver
     C                   Parm                    SRCJRLIB                       * Source receiver li
     C                   Parm                    SrcJrnSeq                      * Source position
     C                   Parm                    SRCJDTS                        * Source date-time
     C                   Parm                    TGTJRCV                        * Apply receiver
     C                   Parm                    TGTJRLIB                       * Apply receiver lib
     C                   Parm                    TgtJrnSeq                      * Apply position
     C                   Parm                    TGTJDTS                        * Apply date-time
     C                   EndIf
     C                   Read      HUFHLTS@                               95
     C                   EndDo

      * End program
     C                   Return
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *INZSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
