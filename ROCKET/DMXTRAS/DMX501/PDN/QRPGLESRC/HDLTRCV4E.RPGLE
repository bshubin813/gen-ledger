      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HDLTRCV4E       *PGM RPG                          *
      *            Retrieves the attributes for the passed journal   *
      *                                                              *
      * Synopsis:  See Command HDLTJRNRCV.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20070511 FK  Initial delivery                                *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Prototypes                                                    *
      * ------------------------------------------------------------- *
      * Retrieve journal information
     D RtvJrnInfo      PR                  ExtProc(
     D                                     'QjoRetrieveJournalInformation')
     D  JIRcvVar                  65535A   Options(*VARSIZE)
     D  JIRcvLen                     10I 0 Const
     D  JIJrnQ                       20A   Const
     D  JIFmtNam                      8A   Const
     D  JIRtvInf                  32767A   Const                                * Info to retrieve
     D                                     Options(*VARSIZE)
     D  JIApiErr                           Like(APIERR)

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

      * Journal information to retrieve
     D RtvInf          DS
     D  TINbrRcd               1      4B 0                                      * # of Records
     D  TIVarLen1              5      8B 0                                      * Var rcd length
     D  TIVarKey1              9     12B 0                                      * Var rcd key
     D  TIVarDtaL1            13     16B 0                                      * Var data length

      * Copy in the API data structures for Journal APIs
     D/COPY QSYSINC/QRPGLESRC,QJOURNAL

      * Message data
     D MsgDta          DS           256

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Local          c                   CONST('*LOCAL')
     D #Remote         c                   CONST('*REMOTE')

      * Message values
     D #CPFMSGF        C                   CONST('QCPFMSG   *LIBL     ')
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

      * ------------------------------------------------------------- *
      * Work fields                                                   *
      * ------------------------------------------------------------- *
     D RtnCde          s              7a                                        * Return code

     D MsgKey          s              4a                                        * Message key

     D JrnWY           s             10                                         * Journal
     D JrnLWY          s             10                                         * Journal lib
     D RcvVar          s          65535                                         * Receiver variable

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    JrnWY                          * Journal
     C                   Parm                    JrnLWY                         * Journal library
     C                   Parm                    JRNTPA            8            * Journal type
     C                   Parm                    RtnCde                         * Return code

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Clear                   RtnCde                         * Return code
      * Do not retrieve receiver info
     C                   Eval      TINbrRcd=0                                   * # of keys
      * Now call API to retrieve journal info
     C                   Reset                   APIErr                         * API Error
     C                   CallP     RtvJrnInfo( RcvVar:
     C                                        %Size(RcvVar):
     C                                        JrnWY + JrnLWY:
     C                                        'RJRN0100':
     C                                        RtvInf:
     C                                        APIErr)
      * Return retrieved info
     C                   If        AEBytAvl=0                                   * No error
     C                   Eval      QJON0100 = RcvVar                            * RJRN0100
      * Fill journal type
     C                   If        QJOJT='0'                                    * Local journal
     C                   Eval      JRNTPA=#Local                                * *LOCAL
     C                   Else
     C                   Eval      JRNTPA=#Remote                               * *REMOTE
     C                   EndIf                                                  * Local journal
      * If there was an error --> return message ID
     C                   Else
     C                   Eval      RtnCde=AEMsgID                               * Message data
      * Resend CPF message
     C                   Reset                   SPAPIErr                       * API Error
     C                   CallP     SndPgmMsg(AEMsgID:#CPFMSGF:AEMsgDta:
     C                                     %len(AEMsgDta):#DIAG:'*':2:
     C                                     MsgKey:SPAPIErr)
     C                   EndIf                                                  * No error
      * End program
     C                   Return

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
