      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HDLTRCV4D       *PGM RPG                          *
      *            Returns the oldest journal receiver still being   *
      *            by iCluster, only for remote journals.            *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20070508 FK  Initial delivery                                *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * Target journal positions in iCluster
     FHUPIDTGJR IF   E           K DISK

      * ------------------------------------------------------------- *
      * Prototypes                                                    *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Qualified receiver
     D RcvQ            DS            20                                         * Receiver qualified
     D  RcvWY                        10    Overlay(RcvQ:1)                      * Receiver
     D  RcvLWY                       10    Overlay(RcvQ:*Next)                  * Receiver lib

      * Message data
     D MsgDta          DS           512

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *

      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D TmpAttDts       s             13a                                        * Temporary att dts
     D FndWY           s               n                                        * Found?
     D LowRcvWY        s             10a                                        * Low receiver
     D LowRcvLWY       s             10a                                        * Low receiver lib
     D LowAttDWY       s             13a                                        * Low attach DTS
     D LowTgtWY        s             10a                                        * Low target
     D LowGrpWY        s             10a                                        * Low group

     D RmtRcvLWY       s             10a                                        * Remote receiver li

     D ChkTgtWY        s             10a                                        * Check target
     D ChkGrpWY        s             10a                                        * Check group
     D ChkJrnWY        s             10a                                        * Check journal
     D ChkJrnLWY       s             10a                                        * Check journal lib
     D ChkPrcWY        s              4a                                        * Check process

     D SavTgtWY        s             10a                                        * Check target
     D SavGrpWY        s             10a                                        * Check group
     D SavJrnWY        s             10a                                        * Check journal
     D SavJrnLWY       s             10a                                        * Check journal lib
     D SavPrcWY        s              4a                                        * Check process

     D MsgKey          s              4a

      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     ChkPrc        KList
     C                   Kfld                    ChkTgtWY                       * Target
     C                   Kfld                    ChkGrpWY                       * Group
     C                   Kfld                    ChkJrnLWY                      * Journal library
     C                   Kfld                    ChkJrnWY                       * Journal name
     C                   Kfld                    ChkPrcWY                       * Process
      *
     C     SavPrc        KList
     C                   Kfld                    SavTgtWY                       * Target
     C                   Kfld                    SavGrpWY                       * Group
     C                   Kfld                    SavJrnLWY                      * Journal library
     C                   Kfld                    SavJrnWY                       * Journal name
     C                   Kfld                    SavPrcWY                       * Process

      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    JRNNPA           10            * Journal name
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    RCVNPA           10            * Returned receiver
     C                   Parm                    RCVLPA           10            * Receiver library
     C                   Parm                    ATTDPA           13            * Attach date-time
     C                   Parm                    TGTNPA           10            * Target
     C                   Parm                    GRPNPA           10            * Group
     C                   Parm                    RtnCde            7            * Return code

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Eval      RCVNPA=*Blanks                               * Receiver name
     C                   Eval      RCVLPA=*Blanks                               * Receiver library
     C                   Eval      TGTNPA=*Blanks                               * Target
     C                   Eval      TGTNPA=*Blanks                               * Group
     C                   Eval      RtnCde=*Blanks                               * Return code

     C                   Eval      FndWY=*Off                                   * Journal found
     C                   Eval      LowAttDWY=*Hival                             * Lowest attach dts
     C                   Eval      LowRcvWY=*Hival                              * Lowest receiver
     C                   Eval      LowRcvLWY=*Hival                             * Lowest library
     C                   Eval      LowTgtWY=*Blanks                             * Lowest target
     C                   Eval      LowGrpWY=*Blanks                             * Lowest group

      * Read all records for the journal in HAPID
     C     *Loval        SetLL     HUPIDTGJR@
     C                   Read      HUPIDTGJR@                             95
     C                   DoW       not *In95
      * If remote journal matches parameter and process is DJSR, entry found
     C                   If        RMTJRN=JRNNPA and RMTJRNLIB=JRNLPA and       * Remote journal &
     C                             PIDPRC='DJSR'                                * Remote scraper
      * Save remote receiver library
     C                   Eval      RmtRcvLWY=RMTRCVLIB                          * Remote rcv lib
      * Save current key for re-positioning
     C                   Eval      SavTgtWY=TGTNAME                             * Target
     C                   Eval      SavGrpWY=GRPNAME                             * Group
     C                   Eval      SavJrnWY=JRNNAME                             * Journal name
     C                   Eval      SavJrnLWY=JRNLIB                             * Journal lib
     C                   Eval      SavPrcWY=PIDPRC                              * Process
      * Retrieve TUP record for journal for receiver being processed
     C                   Eval      ChkTgtWY=TGTNAME                             * Target
     C                   Eval      ChkGrpWY=GRPNAME                             * Group
     C                   Eval      ChkJrnWY=JRNNAME                             * Journal name
     C                   Eval      ChkJrnLWY=JRNLIB                             * Journal lib
     C                   Eval      ChkPrcWY='TUP'                               * TUP process
     C     ChkPrc        Chain     HUPIDTGJR@                         96
     C                   If        not *In96                                    * TUP found
     C                   Eval      FndWY=*On                                    * Journal found
      * Retrieve receiver attach date-time
     C                   Eval      RcvWY=RCVNAME                                * Receiver name
     C                   Eval      RcvLWY=RmtRcvLWY                             * Receiver lib
     C                   ExSR      SRrtvRcv
     C                   If        RtnCde=*Blanks and TmpAttDts<LowAttDWY       * Lower attach dts
     C                   Eval      LowRcvWY=RcvWY                               * Low receiver name
     C                   Eval      LowRcvLWY=RcvLWY                             * Low receiver lib
     C                   Eval      LowTgtWY=TGTNAME                             * Low target
     C                   Eval      LowGrpWY=GRPNAME                             * Low group
     C                   Eval      LowAttDWY=TmpAttDts                          * Low attach dts
     C                   EndIf                                                  * Lower attach dts
     C                   EndIf                                                  * TUP found
      * Reposition to after saved record
     C     SavPrc        SetGT     HUPIDTGJR@                         96
     C                   EndIf                                                  * Rmt jrn & scrp
     C                   Read      HUPIDTGJR@                             95
     C                   EndDo
      * If entry found --> return found receiver and target
     C                   If        FndWY                                        * Record found?
     C                   Eval      RCVNPA=LowRcvWY                              * Receiver name
     C                   Eval      RCVLPA=LowRcvLWY                             * Receiver library
     C                   Eval      ATTDPA=LowAttDWY                             * Attach DTS
     C                   Eval      TGTNPA=LowTgtWY                              * Lowest target
     C                   Eval      GRPNPA=LowGrpWY                              * Lowest group
     C                   EndIf                                                  * Record found?
      * End program
     C                   Return

      * ------------------------------------------------------------------- *
      * SRRtvRcv - Retrieve receiver information                            *
      * ------------------------------------------------------------------- *
     C     SRRtvRcv      BegSR
      * Call program to retrieve journal receiver  information
     C                   Call      'HDLTRCV4F'
     C                   Parm                    RcvWY                          * Receiver
     C                   Parm                    RcvLWY                         * Receiver lib
     C                   Parm                    TmpAttDts                      * Temporary att dts
     C                   Parm                    RtnTmp            7            * Return code
     C                   If        RtnTmp <> *Blanks                            * Error occurred
     C                   Eval      RtnCde=RtnTmp
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
