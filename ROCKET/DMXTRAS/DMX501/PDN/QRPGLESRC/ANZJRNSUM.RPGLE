      * ============================================================ *
      * Object:    ANZJRNSUM       *PGM RPG                          *
      *            Calculates totals of ANZJRNPF into ANZTOTx        *
      *                                                              *
      * Synopsis:  See Command ANZJRNDLT                             *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20060127 FK  Initial delivery (replaces COBOL program)       *
      * 20060130 FK  Include building of ANZTOT6                     *
      * 20060203 FK  Handle IFS object                               *
      * ============================================================ *
      * Journal analysis file
     FANZJRNL2  IF   E           K DISK
      * Totals per date/hour
     FANZTOT1   UF A E           K DISK
      * Totals per file
     FANZTOT2   UF A E           K DISK
      * Totals per program
     FANZTOT3   UF A E           K DISK
      * Totals per job
     FANZTOT4   UF A E           K DISK
      * Totals per transaction type
     FANZTOT5   UF A E           K DISK
      * Totals per journal
     FANZTOT6   UF A E           K DISK

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
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D DTESV           S              8a                                        * Saved date
     D Hr              S              2  0                                      * Hour
     D HOURXSV         S              2                                         * Saved hour value

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list to access ANZTOT1
     C     ChnTot1       KList
     C                   KFld                    DTE                            * Date
     C                   KFld                    HOURX                          * Hour

      * Key list to access ANZTOT2
     C     ChnTot2       KList
     C                   KFld                    FLIB                           * Object library
     C                   KFld                    FNAM                           * Object name
     C                   KFld                    IFSID                          * IFS Object ID
     C                   KFld                    OTYP                           * Object type
     C                   KFld                    DTE                            * Date
     C                   KFld                    HOURX                          * Hour

      * Key list to access ANZTOT3
     C     ChnTot3       KList
     C                   KFld                    PGMN                           * Program name
     C                   KFld                    DTE                            * Date
     C                   KFld                    HOURX                          * Hour

      * Key list to access ANZTOT4
     C     ChnTot4       KList
     C                   KFld                    JOBNM                          * Job name
     C                   KFld                    DTE                            * Date
     C                   KFld                    HOURX                          * Hour

      * Key list to access ANZTOT5
     C     ChnTot5       KList
     C                   KFld                    FLIB                           * Object library
     C                   KFld                    FNAM                           * Object name
     C                   KFld                    IFSID                          * IFS Object ID
     C                   KFld                    JCOD                           * Journal code
     C                   KFld                    JTYP                           * Entry type

      * Key list to access ANZTOT6
     C     ChnTot6       KList
     C                   KFld                    JRNLIB                         * Journal library
     C                   KFld                    JRNNME                         * Journal name
     C                   KFld                    DTE                            * Date
     C                   KFld                    HOURX                          * Hour

      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
     C     *Loval        SetLL     ANZREC
     C                   Read      ANZREC                                 95
     C                   DoW       not *In95
      * Calculate totals for ANZTOT1
     C                   ExSR      SRTot1
      * Calculate totals for ANZTOT2
     C                   ExSR      SRTot2
      * Calculate totals for ANZTOT3
     C                   ExSR      SRTot3
      * Calculate totals for ANZTOT4
     C                   ExSR      SRTot4
      * Calculate totals for ANZTOT5
     C                   ExSR      SRTot5
      * Calculate totals for ANZTOT6
     C                   ExSR      SRTot6
      * Process next record
     C                   Read      ANZREC                                 95
     C                   EndDo

     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRTot1 - Create totals in ANZTOT1                                   *
      * ------------------------------------------------------------------- *
     C     SRTot1        BegSR
      * If new date --> Generate 1 record per hour
     C                   If        DTE <> DTESV                                 * New date
     C                   Eval      HOURXSV=HOURX                                * Saved hour value
     C                   Eval      Hr=0                                         * Hour
     C                   DoW       Hr<=23                                       * Maximum hour
     C                   MoveL     Hr            HOURX
     C                   Eval      TOTENT=0                                     * Total # of Tx
     C                   Eval      TOTLEN=0                                     * Total Tx length
     C                   Write     ANZTR1
     C                   Eval      Hr=Hr+1                                      * Hour
     C                   EndDo
     C                   Eval      DTESV=DTE                                    * Saved date
     C                   Eval      HOURX=HOURXSV                                * Restore HOURX val
     C                   EndIf
      * Update total record
     C     ChnTot1       Chain     ANZTR1                             94
     C                   If        not *in94
     C                   Eval      TOTENT=TOTENT+TOTL                           * Total # of Tx
     C                   Eval      TOTLEN=TOTLEN+JLEN                           * Total Tx length
     C                   Update    ANZTR1
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRTot2 - Create totals in ANZTOT2                                   *
      * ------------------------------------------------------------------- *
     C     SRTot2        BegSR
      * Update total record
     C     ChnTot2       Chain     ANZTR2                             94
     C                   If        not *in94
     C                   Eval      TOTENT=TOTENT+TOTL                           * Total # of Tx
     C                   Eval      TOTLEN=TOTLEN+JLEN                           * Total Tx length
     C                   Update    ANZTR2
     C                   Else
     C                   Eval      TOTENT=TOTL                                  * Total # of Tx
     C                   Eval      TOTLEN=JLEN                                  * Total Tx length
     C                   Write     ANZTR2
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRTot3 - Create totals in ANZTOT3                                   *
      * ------------------------------------------------------------------- *
     C     SRTot3        BegSR
      * Update total record
     C     ChnTot3       Chain     ANZTR3                             94
     C                   If        not *in94
     C                   Eval      TOTENT=TOTENT+TOTL                           * Total # of Tx
     C                   Eval      TOTLEN=TOTLEN+JLEN                           * Total Tx length
     C                   Update    ANZTR3
     C                   Else
     C                   Eval      TOTENT=TOTL                                  * Total # of Tx
     C                   Eval      TOTLEN=JLEN                                  * Total Tx length
     C                   Write     ANZTR3
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRTot4 - Create totals in ANZTOT4                                   *
      * ------------------------------------------------------------------- *
     C     SRTot4        BegSR
      * Update total record
     C     ChnTot4       Chain     ANZTR4                             94
     C                   If        not *in94
     C                   Eval      TOTENT=TOTENT+TOTL                           * Total # of Tx
     C                   Eval      TOTLEN=TOTLEN+JLEN                           * Total Tx length
     C                   Update    ANZTR4
     C                   Else
     C                   Eval      TOTENT=TOTL                                  * Total # of Tx
     C                   Eval      TOTLEN=JLEN                                  * Total Tx length
     C                   Write     ANZTR4
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRTot5 - Create totals in ANZTOT5                                   *
      * ------------------------------------------------------------------- *
     C     SRTot5        BegSR
      * Update total record
     C     ChnTot5       Chain     ANZTR5                             94
     C                   If        not *in94
     C                   Eval      TOTENT=TOTENT+TOTL                           * Total # of Tx
     C                   Eval      TOTLEN=TOTLEN+JLEN                           * Total Tx length
     C                   Update    ANZTR5
     C                   Else
     C                   Eval      TOTENT=TOTL                                  * Total # of Tx
     C                   Eval      TOTLEN=JLEN                                  * Total Tx length
     C                   Write     ANZTR5
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRTot6 - Create totals in ANZTOT6                                   *
      * ------------------------------------------------------------------- *
     C     SRTot6        BegSR
      * Update total record
     C     ChnTot6       Chain     ANZTR6                             94
     C                   If        not *in94
     C                   Eval      TOTENT=TOTENT+TOTL                           * Total # of Tx
     C                   Eval      TOTLEN=TOTLEN+JLEN                           * Total Tx length
     C                   Update    ANZTR6
     C                   Else
     C                   Eval      TOTENT=TOTL                                  * Total # of Tx
     C                   Eval      TOTLEN=JLEN                                  * Total Tx length
     C                   Write     ANZTR6
     C                   EndIf
     C                   EndSR
