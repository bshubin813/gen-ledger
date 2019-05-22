      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HDLTRCV4C       *PGM RPG                          *
      *            Checks if the journal is being processed by the   *
      *            specified product                                 *
      *                                                              *
      * Synopsis:  See Command HDLTJRNRCV.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20020226 FK  Initial delivery                                *
      * 20020904 FK  Group is idle --> journal receivers may be      *
      *              deleted, i.e. Check HA is *NO                   *
      * 20030512 FK  Add iCluster support                            *
      * 20030717 FK  See that the journal is actually in use by any  *
      *              of the subscriptions' tables                    *
      * 20031107 FK  Use LFs over TS files (TS 5.1)                  *
      * 20031114 FK  Different method for checking audit journal     *
      *              Send diagnostic message at end                  *
      * 20031208 FK  Ignore groups which are to be deleted           *
      * 20040526 FK  Also check HADSAVJRN                            *
      * 20060421 FK  Marked position only if later timestamp         *
      * 20070117 FK  Renamed to HDLTRCV4C                            *
      * 20070508 FK  Also check if used as remote journal            *
      * 20070516 FK  Include product library in message              *
      * 20111220 FK  Remove HA/CDC                                   *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * HA journals in use by Journal/Library
     FHUDGTJL   IF   E           K DISK    USROPN
      * HA journals in use by Target ID/Group ID/Journal/Library
     FHUDGTTG   IF   E           K DISK    USROPN
      * HA journals marked positions by Journal/Library
     FHUDSJJL   IF   E           K DISK    USROPN
      * Targets defined in HA Suite
     FHUTGTTI   IF   E           K DISK    USROPN
      * Groups defined in HA Suite
     FHUGRPGI   IF   E           K DISK    USROPN
      * Target group selections for HA Suite
     FHUFGTTG   IF   E           K DISK    USROPN
      * Groups defined in iCluster
     FHIGRPGN   IF   E           K DISK    USROPN
      * Target journal positions in iCluster
     FHUPIDTGJR IF   E           K DISK    UsrOpn
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

      * Message data
     D MsgDta          DS           256
      * Message data for DJR0033
     D  JRNNMD                       10    Overlay(MsgDta:1)                    * Journal name
     D  JRNLMD                       10    Overlay(MsgDta:11)                   * Journal library
     D  PRDMD                         3    Overlay(MsgDta:21)                   * Product
     D  PRCMD                         4    Overlay(MsgDta:24)                   * Processed?
     D  PRCTMD                        4    Overlay(MsgDta:28)                   * Process type
     D  PRDLMD                       10    Overlay(MsgDta:32)                   * Product library

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * Send Program Message
     D SndPgmMsg       Pr                  ExtPgm('QMHSNDPM')
     D  SPMsgID                       7a   Const                                * Message ID
     D  SPMsgF                       20a   Const                                * Message file
     D  SPMsgDta                    512a   Const Options(*Varsize)              * Message data
     D  SPMsgDtaLen                  10i 0 Const                                * Message data len
     D  SPMsgTyp                     10a   Const                                * Message type
     D  SPCllStkEnt                  10a   Const                                * Call stack entry
     D  SPCllStkCnt                  10i 0 Const                                * Call stack count
     D  SPMsgKey                      4a                                        * Message Key
     D  SPAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #NO             C                   CONST('*NO ')
     D #YES            C                   CONST('*YES')
     D #IC             C                   CONST('*IC')
     D #ACT            C                   CONST('*ACT')
     D #MRK            C                   CONST('*MRK')
     D #NONE           C                   CONST('*N  ')
     D #Local          C                   CONST('*LOCAL')
     D #Remote         C                   CONST('*REMOTE')
      * Message values
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #DIAG           C                   CONST('*DIAG')
     D #INFO           C                   CONST('*INFO')
     D #EXT            C                   CONST('*EXT')
      * ------------------------------------------------------------- *
      * Working variables                                             *
      * ------------------------------------------------------------- *
     D AudJrnWY        S               n                                        * Audit journal?
     D POSTIME@        S             26a                                        * Audit journal?

     D MsgKey          s              4a                                        * Message key

      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Read HUDGTJL, HUDSJJL by journal/library
     C     LIMJRN        KList
     C                   KFld                    JRNNPA                         * Journal name
     C                   KFld                    JRNLPA                         * Journal library
      * Read target/group combination from HUFGTTG and/or HUDGTTG
     C     CHNGT         KList
     C                   KFld                    TGTID                          * Target ID
     C                   KFld                    GRPID                          * Group ID
      * Read target/group/journal from HUDGTTG
     C     CHNGTJ        KList
     C                   KFld                    TGTID                          * Target ID
     C                   KFld                    GRPID                          * Group ID
     C                   KFld                    JRNNPA                         * Journal name
     C                   KFld                    JRNLPA                         * Journal library
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    PRDPA             3            * Product to check
     C                   Parm                    PRDLPA           10            * Prodct library
     C                   Parm                    JRNNPA           10            * Journal
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    JRNTPA            8            * Journal type
     C                   Parm                    SYSNPA            8            * Name of system
     C                   Parm                    PRCPA             4            * Processed?
     C                   Parm                    PRCTPA            4            * Process type
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C     *Like         Define    TGTID         TGTIDSV
     C     *Like         Define    GRPID         GRPIDSV
     C                   MoveL     #NO           PRCPA                          * Processed
     C                   MoveL     #NONE         PRCTPA                         * Process type
      * Must the audit journal be verified?
     C                   Move      *Off          AudJrnWY                       * Audit journal
     C     JRNNPA        IfEQ      'QAUDJRN'
     C     JRNLPA        AndEQ     'QSYS'
     C                   Move      *On           AudJrnWY                       * Audit journal
     C                   EndIf

      * Now check, dependent on product
     C                   Select
      *
      * If iCluster must be checked
      *
     C     PRDPA         WhenEQ    #IC                                          * *IC
      * Open the required files (iCluster)
     C                   Open      HUDSJJL                              98
     C                   Open      HUDGTJL                              98
     C                   Open      HUDGTTG                              98
     C                   Open      HUTGTTI                              98
     C                   Open      HUGRPGI                              98
     C                   Open      HUFGTTG                              98
      * Open the required files (iCluster)
     C     PRDPA         IfEQ      #IC                                          * *IC
     C                   Open      HIGRPGN                              98
     C                   Open      HUPIDTGJR                            98
     C                   EndIf
      * First, process all entries in HADSAVJRN for marked journal positions
      * Marked journal position if primary and entry in HADGT/OMFGT older than marked entry
     C     *Loval        SetLL     HUDSJJL@
     C                   Read      HUDSJJL@                               96
     C     *In96         DowEQ     *Off
     C                   Select
      * Audit journal
     C                   When      AudJrnWY                                     * Audit journal
      * Is the target/group primary?
     C                   ExSR      SRChkPri                                     * Check if primary
     C     GrpPriWY      IfEQ      *On                                          * Primary
     C     ChnGT         Chain     HUFGTTG@                           93
      * If marked date-time later than position date-time or no entry in OMFGT --> Marked
     C  N93              MoveL     POSTIME       POSTIME@                       * DTS to character
     C                   If        *In93 or TIMESTAMP>POSTIME@                  * Not active journal
     C                   MoveL     #YES          PRCPA                          * Processed
     C                   MoveL     #MRK          PRCTPA                         * Process type
     C                   EndIf                                                  * Not active journal
     C                   EndIf                                                  * Primary
      * Matching data journal
     C                   When      JRNNAME=JRNNPA and JRNLIB=JRNLPA             * Same data journal
      * Is the target/group primary?
     C                   ExSR      SRChkPri                                     * Check if primary
     C     GrpPriWY      IfEQ      *On                                          * Primary
     C     ChnGTJ        Chain     HUDGTTG@                           93
      * If marked date-time later than position date-time or no entry in HADGT --> Marked
     C  N93              MoveL     POSTIME       POSTIME@                       * DTS to character
     C                   If        *In93 or TIMESTAMP>POSTIME@                  * Not active journal
     C                   MoveL     #YES          PRCPA                          * Processed
     C                   MoveL     #MRK          PRCTPA                         * Process type
     C                   EndIf                                                  * Not active journal
     C                   EndIf                                                  * Primary
     C                   EndSL                                                  * Journal selected
     C                   Read      HUDSJJL@                               96
     C                   EndDo

      * If local journal still not processed (by *MRK) --> check if in use in HADGT/OMFGT
     C                   If        PRCPA<>#YES and JRNTPA=#Local                * Local not process
     C                   Select
      * If audit journal --> in use if any groups primary
     C     AudJrnWY      WhenEQ    *On                                          * Audit journal
     C     *Loval        SetLL     HUFGTTG@
     C                   Read      HUFGTTG@                               96
     C     *In96         DowEQ     *Off
      * Save current TGTID/GRPID to reposition
     C                   Z-Add     TGTID         TGTIDSV                        * Target ID
     C                   Z-Add     GRPID         GRPIDSV                        * Group ID
      * Is the target/group primary?
     C                   ExSR      SRChkPri                                     * Check if primary
     C     GrpPriWY      IfEQ      *On                                          * Primary
     C                   MoveL     #YES          PRCPA                          * Process
     C                   MoveL     #ACT          PRCTPA                         * Process type
     C                   EndIf                                                  * Primary
      * Set pointer 1 record after last record
     C                   Z-Add     TGTIDSV       TGTID                          * Target ID
     C                   Z-Add     GRPIDSV       GRPID                          * Group ID
     C     CHNGT         SetGT     HUFGTTG@
     C                   Read      HUFGTTG@                               96
     C                   EndDo

      * If not audit journal --> read records in HADGT
     C     AudJrnWY      WhenEQ    *Off                                         * Audit journal
     C     LIMJRN        SetLL     HUDGTJL@
     C     LIMJRN        ReadE     HUDGTJL@                               96
     C     *In96         DowEQ     *Off
      * Is the target/group primary?
     C                   ExSR      SRChkPri                                     * Check if primary
     C     GrpPriWY      IfEQ      *On                                          * Primary
     C                   MoveL     #YES          PRCPA                          * Process
     C                   MoveL     #ACT          PRCTPA                         * Process type
     C                   EndIf                                                  * Primary
      * Read next record
     C     LIMJRN        ReadE     HUDGTJL@                               96
     C                   EndDo
     C                   EndSL
     C                   EndIf                                                  * Local not process

      * If remote journal still not processed --> check if in use in HAPID
     C                   If        PRCPA<>#YES and JRNTPA=#Remote               * Remote not process
      * Read records in HAPID
     C     *Loval        SetLL     HUPIDTGJR@
     C                   Read      HUPIDTGJR@                             96
     C     *In96         DowEQ     *Off
      * Is the remote journal scraped?
     C                   If        RMTJRN=JRNNPA and RMTJRNLIB=JRNLPA           * Remote journal
     C                             and PIDPRC='DJSR'                            * Apply process
      * Is the target/group primary?
     C                   ExSR      SRChkPri                                     * Check if primary
     C     GrpPriWY      IfEQ      *Off                                         * Backup
     C                   MoveL     #YES          PRCPA                          * Process
     C                   MoveL     #ACT          PRCTPA                         * Process type
     C                   EndIf                                                  * Backup
     C                   EndIf                                                  * Remote & apply
      * Read next record
     C                   Read      HUPIDTGJR@                             96
     C                   EndDo
     C                   EndIf                                                  * Remote not process
     C                   EndSL

      * Indicate in message whether product uses journal
     C                   Eval      JRNNMD=JRNNPA                                * Journal name
     C                   Eval      JRNLMD=JRNLPA                                * Journal library
     C                   Eval      PRDMD=PRDPA                                  * Product
     C                   Eval      PRCMD=PRCPA                                  * Processed?
     C                   Eval      PRCTMD=PRCTPA                                * Process type
     C                   Eval      PRDLMD=PRDLPA                                * Product library
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('DJR0033':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#INFO:'*':2:
     C                                     MsgKey:APIErr)

      * End program
     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * SRChkPri - Check if target/group is primary                         *
      * ------------------------------------------------------------------- *
     C     SRChkPri      BegSR
     C                   Move      *Off          GrpPriWY          1            * Group primary?

     C                   Select

      * iCluster
     C     PRDPA         WhenEQ    #IC                                          * *IC
      * Get the group associated with this journal record
     C     GRPID         Chain     HUGRPGI@                           94
     C     *IN94         IfEQ      *Off                                         * Group exists
     C     GRPNAME       Chain     HIGRPGN@                           94
     C     *IN94         IfEQ      *Off                                         * iCluster group exs
      * Current primary node must be current system
     C     CURRPRIM      IfEQ      SYSNPA                                       * System name
     C                   MoveL     *On           GrpPriWY                       * Group is primary
     C                   EndIf                                                  * Primary node
     C                   EndIf                                                  * iCluster group exs
     C                   EndIf                                                  * Group exists
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
