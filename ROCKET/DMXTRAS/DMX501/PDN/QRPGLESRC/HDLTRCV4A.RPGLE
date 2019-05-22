      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HDLTRCV4A       *PGM RPG                          *
      *            Returns the marked journal position for the       *
      *            passed journal.                                   *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20040602 FK  Initial delivery                                *
      * 20040924 FK  Prevent overwrite of audit receiver with HADGT  *
      * 20060424 FK  Marked position only if later timestamp         *
      * 20071214 FK  PRDPA too long (should be 3)                    *
      *              If journal receiver not existent, return        *
      *              low value for attach date                       *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * Journals in use by Target ID/Group ID/Journal/Library
     FHUDGTTG   IF   E           K DISK
      * Journals marked positions by Journal/Library
     FHUDSJJL   IF   E           K DISK
      * Targets defined
     FHUTGTTI   IF   E           K DISK
      * Groups defined
     FHUGRPGI   IF   E           K DISK
      * Target group selections
     FHUFGTTG   IF   E           K DISK
      * Groups defined in iCluster
     FHIGRPGN   IF   E           K DISK    USROPN

      * ------------------------------------------------------------- *
      * Prototypes                                                    *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data

     D RcvQ            DS            20                                         * Receiver qualified
     D  RcvWY                        10    Overlay(RcvQ:1)                      * Receiver
     D  RcvLWY                       10    Overlay(RcvQ:*Next)                  * Receiver lib

      * Message data
     D MsgDta          DS           256

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #None           c                   Const('*NONE')
     D #IC             c                   Const('*IC')
     D #iCluster       c                   Const('*ICLUSTER')

      * ------------------------------------------------------------- *
      * Working variables                                             *
      * ------------------------------------------------------------- *
     D TmpAttDts       s             13a                                        * Temporary att dts

     D AudLibSV        s             10a                                        * Saved aud rcv lib
     D AudRcvSV        s             10a                                        * Saved aud rcv
     D DtaLibSV        s             10a                                        * Saved dta rcv lib
     D DtaRcvSV        s             10a                                        * Saved dta rcv
     D TGTNWY          s             10a                                        * Lowest target
     D GRPNWY          s             10a                                        * Lowest group
     D LowRcvWY        s             10a                                        * Lowest receiver
     D LowRcvLWY       s             10a                                        * Lowest rcv lib
     D LowAttDWY       s             13a                                        * Lowest attach date

     D POSTIME@        s             26a                                        * Position time

     D GrpPriWY        s               n                                        * Primary group

     D MsgKey          s              4a                                        * Message key

      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Read HUDGTJL, HUDSJJL or DMFS504L00 by journal/library
     C     LIMJRN        KLIST
     C                   KFLD                    JRNNPA                         * Journal name
     C                   KFLD                    JRNLPA                         * Journal library
      * Read target/group combination from HUFGTTG and/or HUDGTTG
     C     CHNGT         KLIST
     C                   KFLD                    TGTID                          * Target ID
     C                   KFLD                    GRPID                          * Group ID
      * Read target/group/journal from HUDGTTG
     C     CHNGTJ        KLIST
     C                   KFLD                    TGTID                          * Target ID
     C                   KFLD                    GRPID                          * Group ID
     C                   KFLD                    JRNNPA                         * Journal name
     C                   KFLD                    JRNLPA                         * Journal library

      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    PRDPA             3            * Product to check
     C                   Parm                    JRNNPA           10            * Journal
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    SYSNPA            8            * Name of system
     C                   Parm                    RCVNPA           10            * Receiver
     C                   Parm                    RCVLPA           10            * Receiver library
     C                   Parm                    ATTDPA           13            * Attach date
     C                   Parm                    TGTNPA           10            * Target/node
     C                   Parm                    GRPNPA           10            * Group
     C                   Parm                    RtnCde            7            * Return code

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Eval      RtnCde=*Blanks                               * Return code
     C                   Eval      LowRcvWY=*Hival                              * Lowest receiver
     C                   Eval      LowRcvLWY=*Hival                             * Lowest rcv lib
     C                   Eval      LowAttDWY=*Hival                             * Lowest attach date
     C                   Eval      TGTNWY=#None                                 * Found target
     C                   Eval      GRPNWY=#None                                 * Found group

      * Open the required files (iCluster)
     C                   If        PRDPA=#IC                                    * *IC
     C                   Open      HIGRPGN                              98
     C                   EndIf
      * First, process all entries in HADSAVJRN for marked journal positions
      * Marked journal position if primary and entry in HADGT/OMFGT older than marked entry
     C     *Loval        SetLL     HUDSJJL@
     C                   Read      HUDSJJL@                               96
     C                   DoW       not *In96 and RtnCde=*Blanks
     C                   Select
      * Audit journal
     C                   When      JRNNPA='QAUDJRN' and JRNLPA='QSYS'           * Audit journal
      * Is the target/group primary?
     C                   ExSR      SRChkPri                                     * Check if primary
     C                   If        GrpPriWY                                     * Primary
      * Keep values of audit receiver/lib
     C                   Eval      AudRcvSV=AJRNRCVNME                          * Saved audit rcv
     C                   Eval      AudLibSV=AJRNRCVLIB                          * Saved audit lib
     C     ChnGT         Chain     HUFGTTG@                           93
      * If marked date-time later than position date-time or no entry in OMFGT --> Marked
     C  N93              MoveL     POSTIME       POSTIME@                       * DTS to character
     C                   If        *In93 or TIMESTAMP>POSTIME@                  * Not active journal
     C                   Eval      RcvWY=AudRcvSV                               * Receiver name
     C                   Eval      RcvLWY=AudLibSV                              * Receiver library
     C                   ExSR      SRRtvRcv
     C                   Select
      * If older receiver
     C                   When      RtnCde=*Blanks and TmpAttDts<LowAttDWY       * Older receiver
     C                   Eval      LowRcvWY=RcvWY                               * Lowest receiver
     C                   Eval      LowRcvLWY=RcvLWY                             * Lowest rcv lib
     C                   Eval      LowAttDWY=TmpAttDts                          * Lowest att dt
     C                   Eval      TGTNWY=TGTNAME                               * Target name
     C                   Eval      GRPNWY=GRPNAME                               * Group name
      * If error retrieving receiver
     C                   When      RtnCde<>*Blanks                              * Error
     C                   Eval      LowRcvWY=RcvWY                               * Lowest receiver
     C                   Eval      LowRcvLWY=RcvLWY                             * Lowest rcv lib
     C                   Eval      LowAttDWY='0000000000000'                    * Lowest att dt
     C                   Eval      TGTNWY=TGTNAME                               * Target name
     C                   Eval      GRPNWY=GRPNAME                               * Group name
     C                   EndSL
     C                   EndIf                                                  * Not active journal
     C                   EndIf                                                  * Primary
      * Matching data journal
     C                   When      JRNNAME=JRNNPA and JRNLIB=JRNLPA             * Same data journal
      * Is the target/group primary?
     C                   ExSR      SRChkPri                                     * Check if primary
     C                   If        GrpPriWY                                     * Primary
      * Keep values of data receiver/lib
     C                   Eval      DtaRcvSV=DJRNRCVNME                          * Saved data rcv
     C                   Eval      DtaLibSV=DJRNRCVLIB                          * Saved data lib
     C     ChnGTJ        Chain     HUDGTTG@                           93
      * If marked date-time later than position date-time or no entry in HADGT --> Marked
     C  N93              MoveL     POSTIME       POSTIME@                       * DTS to character
     C                   If        *In93 or TIMESTAMP>POSTIME@                  * Not active journal
     C                   Eval      RcvWY=DtaRcvSV                               * Receiver name
     C                   Eval      RcvLWY=DtaLibSV                              * Receiver library
     C                   ExSR      SRRtvRcv
     C                   Select
      * If older receiver
     C                   When      RtnCde=*Blanks and TmpAttDts<LowAttDWY       * Older receiver
     C                   Eval      LowRcvWY=RcvWY                               * Lowest receiver
     C                   Eval      LowRcvLWY=RcvLWY                             * Lowest rcv lib
     C                   Eval      LowAttDWY=TmpAttDts                          * Lowest att dt
     C                   Eval      TGTNWY=TGTNAME                               * Target name
     C                   Eval      GRPNWY=GRPNAME                               * Group name
      * If error retrieving receiver
     C                   When      RtnCde<>*Blanks                              * Error
     C                   Eval      LowRcvWY=RcvWY                               * Lowest receiver
     C                   Eval      LowRcvLWY=RcvLWY                             * Lowest rcv lib
     C                   Eval      LowAttDWY='0000000000000'                    * Lowest att dt
     C                   Eval      TGTNWY=TGTNAME                               * Target name
     C                   Eval      GRPNWY=GRPNAME                               * Group name
     C                   EndSL
     C                   EndIf                                                  * Not active journal
     C                   EndIf                                                  * Primary
     C                   EndSL                                                  * Journal selected
     C                   Read      HUDSJJL@                               96
     C                   EndDo
      * Return found positions and target/group
     C                   Eval      RCVNPA=LowRcvWY                              * Receiver name
     C                   Eval      RCVLPA=LowRcvLWY                             * Receiver library
     C                   Eval      ATTDPA=LowAttDWY                             * Lowest att dt
     C                   Eval      TGTNPA=TGTNWY                                * Target name
     C                   Eval      GRPNPA=GRPNWY                                * Group name
     C                   If        PRDPA=#IC                                    * *IC
     C                   Eval      TGTNPA=#iCluster                             * *ICLUSTER
     C                   EndIf

      * End program
     C                   Return

      * ------------------------------------------------------------------- *
      * SRChkPri - Check if target/group is primary                         *
      * ------------------------------------------------------------------- *
     C     SRChkPri      BegSR
     C                   Eval      GrpPriWY=*Off                                * Group primary?
      * Keep current values of AJRNRCVNME and AJRNRCVLIB (overwritten in this procedure)
     C                   Eval      AudRcvSV=AJRNRCVNME                          * Saved audit rcv
     C                   Eval      AudLibSV=AJRNRCVLIB                          * Saved audit lib

     C                   Select
      * iCluster
     C     PRDPA         WhenEQ    #IC                                          * *IC
      * Get the group associated with this journal record
     C     GRPID         Chain     HUGRPGI@                           94
     C                   If        not *In94                                    * Group exists
     C     GRPNAME       Chain     HIGRPGN@                           94
     C                   If        not *In94                                    * iCluster group exs
      * Current primary node must be current system
     C                   If        CURRPRIM=SYSNPA                              * System name
     C                   Eval      GrpPriWY=*On                                 * Group is primary
     C                   EndIf                                                  * Primary node
     C                   EndIf                                                  * iCluster group exs
     C                   EndIf                                                  * Group exists
     C                   EndSL
      * Restore values of AJRNRCVNME and AJRNRCVLIB (overwritten in this procedure)
     C                   Eval      AJRNRCVNME=AudRcvSV                          * Saved audit rcv
     C                   Eval      AJRNRCVLIB=AudLibSV                          * Saved audit lib
     C                   EndSR

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
