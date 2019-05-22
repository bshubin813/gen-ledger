      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HDLTRCV2        *PGM RPG                          *
      *            Reads the entries in the HLSTJRNR file. If a      *
      *            journal receiver matches the selection criteria   *
      *            (age, saved, processed by products), HDLTRCV3     *
      *            deletes the receiver                              *
      *                                                              *
      * Synopsis:  See Command HDLTJRNRCV.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 19990722 FK  Initial delivery                                *
      * 19990108 FK  Converted to RPGLE and built in check on target *
      * 19990927 FK  Determine if receiver processed by number       *
      * 19991220 FK  Check TS journals too                           *
      * 20000225 FK  Use proper journal receiver counter for TS      *
      * 20000225 FK  Use APIs to retrieve confirmed journal pos.     *
      * 20000305 FK  Return number of receivers left over            *
      * 20000323 FK  Pass product libraries                          *
      * 20000523 FK  Exit program to retrieve external position      *
      * 20000614 FK  Log journal receiver deletions                  *
      * 20000705 FK  Use logical files                               *
      * 20020116 FK  Allow checking for RJP journals                 *
      * 20020226 FK  Check if processed in external program          *
      *              Change checking for RJP journal                 *
      * 20020515 FK  Add support for iCluster                        *
      * 20020612 FK  Changed function of HDLTRCV file                *
      * 20040602 FK  Issue message for currently attached receiver   *
      *              First check if receiver used by product         *
      * 20050510 FK  Remove CHKRJP parameter                         *
      * 20070108 FK  Allow instrumental mode                         *
      * 20070112 FK  Allow checking of multiple TS libraries         *
      * 20070507 FK  Include journal type                            *
      *              Use different intput files                      *
      * 20070515 FK  One call to determine oldest product receiver   *
      * 20070516 FK  Return size of deleted receivers                *
      * 20111220 FK  remove HA/CDC                                   *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * Journal receivers in chain
     FHLSTJRNR  IF   E           K Disk
      * Journal receivers deletion log
     FHDLTLOG   O    E           K Disk

      * ------------------------------------------------------------- *
      * Prototypes                                                    *
      * ------------------------------------------------------------- *
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
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Program status data structure
     DPSDS            SDS
     D PSJobNam              244    253                                         * Job name
     D PSJobUsr              254    263                                         * Job user
     D PSJobNbr              264    269S 0                                      * Job number

      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data
      * API-Error data structure for SndPgmMsg
     D SPAPIErr        DS
     D  SPBytPvd                     10i 0 Inz(%Size(SPAPIErr))                 * Bytes provided
     D  SPBytAvl                     10i 0                                      * Bytes available
     D  SPMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  SPMsgDta                    256a                                        * Message data

     D RcvQ            DS            20                                         * Receiver qualified
     D  RcvWY                        10    Overlay(RcvQ:1)                      * Receiver
     D  RcvLWY                       10    Overlay(RcvQ:*Next)                  * Receiver lib

      * Message data
     D MsgDta          DS           256
      * General message data for DJRxxxx messages
     D  RcvMD                        10    Overlay(MsgDta:1)                    * Receiver name
     D  RcvLMD                       10    Overlay(MsgDta:11)                   * Receiver library
     D  JrnMD                        10    Overlay(MsgDta:21)                   * Journal name
     D  JRNLMD                       10    Overlay(MsgDta:31)                   * Journal library
      * Additional message data for DJR0009
     D  STSMD                         8    Overlay(MsgDta:41)                   * Receiver status
      * Additional message data for DJR0030
     D  DAYSMD                       10i 0 Overlay(MsgDta:41)                   * Number of days
      * Additional message data for DJR0031
     D  KeepRMD                      10i 0 Overlay(MsgDta:41)                   * Number of receiver

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #NO             C                   CONST('*NO')
     D #YES            C                   CONST('*YES')
     D #IC             C                   CONST('*IC')
     D #NoExit         C                   CONST('*NONE     *LIBL     ')
     D #IGNORE         C                   CONST('*IGNORE')

      * Journal receiver status value
     D #Attached       c                   Const('ATTACHED')
     D #Saved          c                   Const('SAVED   ')
     D #Freed          c                   Const('FREED   ')

      * Message values
     D #CPFMSGF        C                   CONST('QCPFMSG   *LIBL     ')
     D #HAUMSGF        c                   Const('HAUMSG    *LIBL     ')
     D #STATUS         c                   Const('*STATUS')
     D #DIAG           c                   Const('*DIAG')
     D #INFO           c                   Const('*INFO')
     D #EXT            c                   Const('*EXT')

      * ------------------------------------------------------------- *
      * Work fields                                                   *
      * ------------------------------------------------------------- *
     D TmpAttDts       s             13a                                        * Temporary att dts
     D PrdAttDts       s             13a                                        * Oldest att dts
     D EPAttDts        s             13a                                        * Exit attach dts

     D DltRcv          s               n                                        * Receiver deleted

     D ChkAgeDts       s               z                                        * Check age
     D ChkChgDts       s             13a                                        * Check change dts
     D CurDTS          s               z                                        * Current DTS

     D RtnCde          s              7a                                        * Return code

     D DateWY          s               d                                        * Date
     D Date7WY         s              7a                                        * Date 7 pos
     D TimeWY          s               t                                        * Time
     D Time6WY         s              6a                                        * Time pos

     D MsgKey          s              4a                                        * Message key

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list to limit by journal
     C     LimJrn        KList
     C                   KFld                    JRNLPA                         * Journal library
     C                   KFld                    JRNNPA                         * Journal

      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    JRNNPA           10            * Journal
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    DAYSPA            3 0          * Days to keep
     C                   Parm                    KEEPRPA           3 0          * Number to keep
     C                   Parm                    CURNPA           10 0          * # of Receivers
     C                   Parm                    UNSRPA            4            * Delete unsaved?
     C                   Parm                    RPYSPA            4 0          * Reply list sequenc
     C                   Parm                    LOGDPA            4            * Log deletes
     C                   Parm                    CHKIPA            4            * Check iCluster
     C                   Parm                    NBRDPA            5 0          * Number deleted
     C                   Parm                    RMNNPA            5 0          * Remaining number
     C                   Parm                    SIZDPA            9 0          * Size deleted
     C                   Parm                    RMNSPA           12 0          * Remaining size
     C                   Parm                    ALRMPA           20            * Alert message queu
     C                   Parm                    RCVEPA           20            * Receiver exit pgm
     C                   Parm                    POSEPA           20            * External pos. exit
     C                   Parm                    DLTRPA            4            * Delete receivers

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Clear                   NBRDPA                         * Number deleted
     C                   Clear                   SIZDPA                         * Deleted size
     C                   Eval      DltRcv=*On                                   * Receiver deleted?
     C                   Eval      RMNNPA=CURNPA                                * Remaining number
     C                   Clear                   RMNSPA                         * Remaining size
     C                   Eval      PrdAttDts=*Hival                             * Product att dts
     C                   Eval      EPAttDts=*Hival                              * Attached Exit
      * If number of days specified, calculate DTS for check
     C                   Eval      ChkChgDts=*Hival                             * Check attached age
     C                   If        DAYSPA<>-1
     C                   Time                    CurDTS                         * Current timestamp
     C     CurDts        SubDur    DAYSPA:*Days  ChkAgeDts                      * Calculated check
     C                   MoveL     ChkAgeDts     DateWY
     C                   Move      ChkAgeDts     TimeWY
     C     *CYMD0        MoveL     DateWY        Date7WY                        * Date 7 digits
     C     *HMS0         MoveL     TimeWY        Time6WY                        * Time 6 digits
     C                   Eval      ChkChgDts=Date7WY+Time6WY
     C                   EndIf
      * If any of the products must be checked --> Check oldest receiver still in use
     C                   If        CHKIPA=#Yes                                  * CHKIC(*YES)
     C                   ExSR      SRChkPrd
     C                   EndIf                                                  * CHKIC(*YES)
      * Call position exit if required
     C                   If        POSEPA<>#NoExit                              * POSEXIT(xxxx)
     C                   ExSR      SRChkEP
     C                   EndIf                                                  * POSEXIT(xxxx)
      * Read all records for the journal and process
     C     LimJrn        SetLL     LSTJRNRR
     C     LimJrn        ReadE     LSTJRNRR                               95
     C                   DoW       not *In95
     C                   If        DltRcv                                       * Delete receiver?
      * If HA Suite, iCluster, TS or exit program checked -> verify attach date
     C                   If        (LRATTD>=PrdAttDts) or                       * In use by product
     C                             (LRATTD>=EPAttDts)                           * In use by exit
     C                   Eval      DltRcv=*Off                                  * Delete receiver
      * Send diagnostic message "Receiver scraped by product"
     C                   Eval      RcvMD=LRRCV                                  * Receiver
     C                   Eval      RcvLMD=LRRCVL                                * Receiver lib
     C                   Eval      JrnMD=LRJRN                                  * Journal
     C                   Eval      JrnLMD=LRJRNL                                * Journal lib
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('DJR0038':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf                                                  * In use by product
      * Keep the currently attached journal receiver and issue message
     C                   If        LRSTS=#Attached                              * Attached receiver
     C                   Eval      DltRcv=*Off                                  * Delete receiver
      * Send diagnostic message "Receiver is currently attached"
     C                   Eval      RcvMD=LRRCV                                  * Receiver
     C                   Eval      RcvLMD=LRRCVL                                * Receiver lib
     C                   Eval      JrnMD=LRJRN                                  * Journal
     C                   Eval      JrnLMD=LRJRNL                                * Journal lib
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('DJR0037':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf
     C                   If        DltRcv                                       * Skip if not delete
      * Is the receiver old enough to be deleted?
     C                   If        LRCHGD>ChkChgDts                             * Age of receiver
     C                   Eval      DltRcv=*Off                                  * Delete receiver
      * Send diagnostic message "Receiver changed since number of days"
     C                   Eval      RcvMD=LRRCV                                  * Receiver
     C                   Eval      RcvLMD=LRRCVL                                * Receiver lib
     C                   Eval      JrnMD=LRJRN                                  * Journal
     C                   Eval      JrnLMD=LRJRNL                                * Journal lib
     C                   Eval      DaysMD=DAYSPA                                * Days to keep
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('DJR0030':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf                                                  * Age of receiver
      * Keep the number of receivers that was specified
     C                   If        RMNNPA<=KEEPRPA                              * Number to keep
     C                   Eval      DltRcv=*Off                                  * Delete receiver
      * Send diagnostic message "Number of receivers must be kept"
     C                   Eval      RcvMD=LRRCV                                  * Receiver
     C                   Eval      RcvLMD=LRRCVL                                * Receiver lib
     C                   Eval      JrnMD=LRJRN                                  * Journal
     C                   Eval      JrnLMD=LRJRNL                                * Journal lib
     C                   Eval      KeepRMD=KEEPRPA                              * Number to keep
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('DJR0031':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf                                                  * Number to keep
      * Is the receiver either fully saved or must it be deleted anyway?
     C                   If        UNSRPA=#No and LRSTS<>#Saved                 * Delete unsaved
     C                                        and LRSTS<>#Freed
     C                   Eval      DltRcv=*Off                                  * Delete receiver
      * Send diagnostic message "Receiver not fully saved"
     C                   Eval      RcvMD=LRRCV                                  * Receiver
     C                   Eval      RcvLMD=LRRCVL                                * Receiver lib
     C                   Eval      JrnMD=LRJRN                                  * Journal
     C                   Eval      JrnLMD=LRJRNL                                * Journal lib
     C                   Eval      STSMD=LRSTS                                  * Receiver status
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('DJR0009':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf                                                  * Delete unsaved
      * If exit program specified --> also invoke this to check receiver
     C                   If        RCVEPA<>#NoExit                              * Exit program spec.
     C                   Call      'HDLTRCV5'
     C                   Parm                    RCVEPA                         * Exit program qual.
     C                   Parm                    LRJRN                          * Journal name
     C                   Parm                    LRJRNL                         * Journal lib
     C                   Parm                    LRRCV                          * Receiver name
     C                   Parm                    LRRCVL                         * Receiver lib
     C                   Parm                    RtnCde                         * Return code
     C     RtnCde        IfNE      *Blanks
     C                   Eval      DltRcv=*Off                                  * Delete receiver
     C                   EndIf
     C                   EndIf
      * If receiver must still be deleted --> delete
     C                   If        DltRcv                                       * Delete receiver
     C                   Call      'HDLTRCV3'
     C                   Parm                    LRJRN                          * Journal name
     C                   Parm                    LRJRNL                         * Journal lib
     C                   Parm                    LRRCV                          * Receiver name
     C                   Parm                    LRRCVL                         * Receiver lib
     C                   Parm                    UNSRPA                         * Delete unsaved?
     C                   Parm                    RPYSPA                         * Reply list sequenc
     C                   Parm                    DLTRPA                         * Delete receivers?
     C                   Parm                    DltRcv                         * Receiver deleted?
     C                   EndIf                                                  * Delete receiver
     C                   EndIf                                                  * DltRcv = *ON
     C                   EndIf                                                  * DltRcv = *ON
      * If receiver deleted --> increment; else increment size and number remaining
     C                   If        DltRcv                                       * Deleted!
     C                   Add       1             NBRDPA                         * Number deleted
     C                   Add       LRSIZE        SIZDPA                 99      * Size deleted
     C     CURNPA        Sub       NBRDPA        RMNNPA                         * Remaining number
      * Optionally --> log delete
     C                   If        LOGDPA=#Yes and DLTRPA=#Yes                  * Deleted & log?
     C                   Eval      DLJRNN=LRJRN                                 * Journal name
     C                   Eval      DLJRNL=LRJRNL                                * Journal lib
     C                   Eval      DLRCVN=LRRCV                                 * Receiver name
     C                   Eval      DLRCVL=LRRCVL                                * Receiver lib
     C                   Eval      DLJOBN=PSJobNam                              * Job name
     C                   Eval      DLJOBU=PSJobUsr                              * Job user
     C                   Move      PSJobNbr      DLJOB#                         * Job number
     C                   Time                    DLDTS                          * Current timestamp
     C                   Eval      DLSIZE=LRSIZE                                * Receiver size
     C                   Write     HDLTLOG@
     C                   EndIf
     C                   Else                                                   * Delete receiver?
     C                   Add       LRSIZE        RMNSPA                         * Remaining size
     C                   EndIf                                                  * Delete receiver?
     C     LimJrn        ReadE     LSTJRNRR                               95
     C                   EndDo
      * End program
     C                   Return

      * ------------------------------------------------------------- *
      * SRChkPrd - Retrieve oldest receiver for product               *
      * ------------------------------------------------------------- *
     C     SRChkPrd      BegSR
      * Initialise
     C                   Eval      RtnCde=*Blanks                               * Return code
      * Call program to retrieve oldest receiver for products
     C                   Call      'HDLTRCV4'
     C                   Parm                    JRNNPA                         * Journal name
     C                   Parm                    JRNLPA                         * Journal library
     C                   Parm                    CHKIPA                         * Check iCluster
     C                   Parm                    ALRMPA                         * Alert message queu
     C                   Parm                    RcvWY                          * Receiver name
     C                   Parm                    RcvLWY                         * Receiver library
     C                   Parm                    PrdAttDts                      * Product att dts
     C                   Parm                    RtnCde                         * Return code
     C                   If        RtnCde<>*Blanks                              * Error
     C                   Eval      DltRcv=*Off                                  * Delete receiver
     C                   EndIf                                                  * Error
     C                   EndSR                                                  * Error

      * ------------------------------------------------------------- *
      * SRChkEP - Retrieve external position exit                     *
      * ------------------------------------------------------------- *
     C     SRChkEP       BegSR
      * Initialise
     C                   Eval      EPAttDts=*Loval                              * EP Attach DTS
     C                   Eval      RtnCde=*Blanks                               * Return code
      * Retrieve oldest receiver that is currently being processed by external application
     C                   Call      'HDLTRCV6'
     C                   Parm                    POSEPA                         * External pos. exit
     C                   Parm                    JRNNPA                         * Journal name
     C                   Parm                    JRNLPA                         * Journal library
     C                   Parm                    RcvWY                          * Receiver name
     C                   Parm                    RcvLWY                         * Receiver library
     C                   Parm                    RtnCde                         * Return code
     C                   If        RtnCde<>#Ignore                              * *IGNORE
     C                   If        RtnCde=*Blanks                               * No error
     C                   ExSR      SRRtvRcv
     C                   Eval      EPAttDts=TmpAttDts                           * Attached DTS
     C                   Else
     C                   Eval      DltRcv=*Off                                  * Delete receiver
     C                   EndIf                                                  * No error
      * If not processed, make sure that exit is ignored
     C                   Else                                                   * *IGNORE
     C                   Eval      EPAttDts=*Hival                              * EP Attach DTS
     C                   EndIf                                                  * *IGNORE
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
