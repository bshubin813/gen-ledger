      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HDLTRCV4F       *PGM RPG                          *
      *            Retrieves the attributes for the passed receiver  *
      *                                                              *
      * Synopsis:  See Command HDLTJRNRCV.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20070516 FK  Initial delivery                                *
      * ============================================================ *
     HDftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Prototypes                                                    *
      * ------------------------------------------------------------- *
      * API to retrieve journal receiver info
     D RtvRcvInfo      Pr                  ExtProc(
     D                                     'QjoRtvJrnReceiverInformation')
     D  RIRcvVar                    500A   Options(*VARSIZE)                    * Receiver variable
     D  RIRcvLen                     10I 0 Const                                * RcvVar length
     D  RIRcvQ                       20A   Const                                * Receiver name
     D  RIFmtNam                      8A   Const                                * Format
     D  RIApiErr                           Like(ApiErr)

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

      * Copy in the API data structures for Journal APIs
     D/COPY QSYSINC/QRPGLESRC,QJOURNAL

      * Message data
     D MsgDta          DS           256

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
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
     D RtnCde          s              7a                                        * Return code

     D MsgKey          s              4a                                        * Message key

     D RcvPA           s             10                                         * Receiver
     D RcvLPA          s             10                                         * Receiver lib
     D RcvAttDPA       s             13                                         * Attach date

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    RcvPA                          * Receiver
     C                   Parm                    RcvLPA                         * Receiver lib
     C                   Parm                    RcvAttDPA                      * Receiver att dt
     C                   Parm                    RtnCde                         * Return code

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Clear                   RtnCde                         * Return code
      * Now call API to retrieve journal info
     C                   Reset                   APIErr                         * API Error
     C                   CallP     RtvRcvInfo( QJOV0100                         * Receiver variable
     C                                      : %Size(QJOV0100)                   * RcvVar length
     C                                      : RcvPA+RcvLPA                      * Receiver qualified
     C                                      : 'RRCV0100'                        * Format name
     C                                      : ApiErr)
     C                   If        AEBytAvl<>0                                  * Error occurred
      * Set return code
     C                   Eval      RtnCde=AEMsgID
     C                   Eval      RcvAttDPA='0000000000000'
      * Resend CPF message
     C                   Reset                   SPAPIErr                       * API Error
     C                   CallP     SndPgmMsg(AEMsgID:#CPFMSGF:AEMsgDta:
     C                                     %len(AEMsgDta):#DIAG:'*':2:
     C                                     MsgKey:SPAPIErr)
     C                   Else                                                   * No error
     C                   Eval      RcvAttDPA=QJOADT
     C                   EndIf                                                  * Error occurred
      * End program
     C                   Return

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
