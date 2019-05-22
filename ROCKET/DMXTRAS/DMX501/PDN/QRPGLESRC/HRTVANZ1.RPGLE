      * ============================================================ *
      * Object:    HRTVANZ1        *PGM RPG                          *
      *            Copies the specified analysis information to the  *
      *            output file and cleans up entries.                *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20010731 FK  Initial delivery                                *
      * 20040830 FK  Relative date not calculated correctly          *
      * ============================================================ *
      * Input file
     FANZTOT1   UF   E           K DISK
      * Output file
     FANZTOTO   O    E           K DISK    RENAME(ANZTR1:ANZTOR)
      * Journal entry file
     FANZJRNL2  UF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Variables
     D WRKDDS          DS            10                                         * Work date
     D  RELDWY                 1     10D   DATFMT(*ISO)
     D  RELDDD                 9     10  0
      *
     D CURDWY          S               D   DATFMT(*ISO)
     D ENDDWY          S               D   DATFMT(*ISO)
     D CLNDWY          S               D   DATFMT(*ISO)
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *ENTRY        PLIST
     C                   PARM                    MNTHPA            3 0
     C                   PARM                    RELDPA            7
     C                   PARM                    CLNHPA            3 0
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Process all records in ANZTOT1, write or delete
     C     *Loval        SetLL     ANZTR1
     C                   Read      ANZTR1                                 95
     C     *In95         DowEQ     *Off
     C                   If        DTE >= RELD@ and DTE < ENDD@
     C                   Write     ANZTOR
     C                   EndIf
     C                   If        DTE < CLND@
     C                   Delete    ANZTR1
     C                   EndIf
     C                   Read      ANZTR1                                 95
     C                   EndDo
      * Remove obsolete records from ANZJRNPF
     C     *Loval        SetLL     ANZREC
     C                   Read      ANZREC                                 95
     C     *In95         DowEQ     *Off
     C                   If        DTE < CLND@
     C                   Delete    ANZREC
     C                   EndIf
     C                   Read      ANZREC                                 95
     C                   EndDo
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *INZSR        BEGSR
      * Retrieve current date
     C                   Time                    CURDWY                         * Current date
      * Convert special values for date
     C                   Select
      * Calculate starting date in case of *STRCUR
     C                   When      (RELDPA = '0680827')                         * *STRCUR
     C                   Move      CURDWY        RELDWY                         * Relative date
     C                   Z-Add     1             RELDDD                         * Day of month
      * Calculate starting date in case of *STRPRV
     C                   When      (RELDPA = '0000827')                         * *STRPRV
     C                   Move      CURDWY        RELDWY                         * Relative date
     C                   Z-Add     1             RELDDD                         * Day of month
     C                   SubDur    1:*Months     RELDWY                         * Month - 1
      * Real date was specified
     C                   Other
     C     *CYMD0        Move      RELDPA        RELDWY                         * Relative date
     C                   EndSL
      * Calculate ending date / clean date
     C     RELDWY        AddDur    MNTHPA:*MonthsENDDWY
     C     CURDWY        SubDur    CLNHPA:*MonthsCLNDWY
      * Convert to character variables
     C     *ISO0         MoveL     ENDDWY        ENDD@             8
     C     *ISO0         MoveL     CLNDWY        CLND@             8
     C     *ISO0         MoveL     RELDWY        RELD@             8
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
