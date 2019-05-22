      *CP: ALWNULL(*USRCTL) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONJRN4        *PGM RPG                          *
      *            Processes the HJRNLAGDJ file and deletes any      *
      *            records older than the specified number of        *
      *            days.                                             *
      *                                                              *
      * Synopsis:  See Command HMONJRNLAG.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20021029 FK  Initial delivery                                *
      * 20021119 FK  Fix record locking by same job error            *
      * 20031006 FK  Purge history for measurement type only         *
      * ============================================================ *
      * Journal replication lag by System name, type, date/time, journal
     FHJRNLAGDJ UF   E           K DISK
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

      * Message data
     D MSGDTA          DS          1024

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *
     D SysDatWY        S               Z   Inz(*SYS)                            * System date-time
     D DTSMWY          S               Z                                        * Date-Time stamp

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * Message values
     D #MSGF           C                   CONST('HAUMSG    *LIBL     ')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #STATUS         C                   CONST('*STATUS')

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     LimLag        KList
     C                   KFld                    SYSNPA                         * System name
     C                   KFld                    TYPMPA                         * Measurement type

      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    SYSNPA            8            * System name
     C                   Parm                    TYPMPA            4            * Measurement type
     C                   Parm                    PRGHPA            4 0          * History to purge

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Move      SysDatWY      DTSMWY                         * Date-Time stamp
      * Subtract number of days
     C                   SubDur    PRGHPA:*D     DTSMWY                         * Date-Time stamp
      * Process all records for system/measurement dts
     C     LimLag        SetLL     HJRNLAG@
     C     LimLag        ReadE     HJRNLAG@                               95
     C     *In95         DowEQ     *Off
     C     JLDTSM        IfLT      DTSMWY                                       * Date-Time stamp
     C                   Delete    HJRNLAG@
     C                   Else
     C                   Unlock    HJRNLAGDJ
     C                   Move      *On           *In95                          * Force EOF
     C                   EndIf
      * Read next record
     C     *In95         IfEQ      *Off
     C     LimLag        ReadE     HJRNLAG@                               95
     C                   EndIf
     C                   EndDo

      * End program
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *INZSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
