      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONHAL1        *PGM                              *
      *            Waits for messages and requests from other        *
      *            systems.                                          *
      *                                                              *
      * Synopsis:  N/A.                                              *
      *                                                              *
      * Creation:  CRTBNDRPG                                         *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20011217 FK  Initial delivery (copy from HMONEVL)            *
      * 20060419 FK  Group status                                    *
      * 20111220 FK  Remove HA                                       *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HACTGRP(*CALLER) BNDDIR('HMONHA' : 'QC2LE')

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Messages received from remote system
     FHMONHAE   UF A E           K DISK
      * Suspended objects received from remote system
     FHMONHAS   UF A E           K DISK
      * Inactive groups received from remote system
     FHMONHAG   UF A E           K DISK

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
     D StrErr          PR              *   ExtProc( 'strerror' )
     D  Dummy                         1    Options( *Omit )

     D GetPort         PR            10i 0
     D                               30

     D OpnTCP          PR            10I 0

     D BndTCP          PR            10I 0
     D                               10I 0 Const
     D                               10I 0 Const
     D                               10I 0 Const
     D                                 *   Const

     D AcpTCP          PR            10i 0
     D                               10i 0 Const
     D                                 *   Const

     D RcvTCP          PR            10I 0
     d                               10I 0 Const
     d                              600

     D SndTCP          PR            10I 0
     D                               10I 0 Const
     D                              600

     D CloTCP          PR            10I 0
     D                               10I 0 Const

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * List of message queues
     D pLstMsgQ        DS           102
     D  pNbrMsgQ                      4B 0                                      * # of Msg queues
     D  pArrMsgQ                     20    Dim(5)                               * Message queues

     D SktAdr          DS
     D  #family                       5i 0
     D  #port                         5u 0
     D  #ip                          10u 0
     D  #zero                         8

      * String being exchanged
     D ExcStr          DS           600
     D  OrgSys                 1      8                                         * Original system
     D  Action                 9     12                                         * Action
     D  MsgOrg                13     13                                         * Message Origin
     D  Filler01              14     23                                         * Target name
     D  MsgGrpNam             24     33                                         * Group name
     D  Msgid                 34     40                                         * Message ID
     D  MsgDTS                41     66                                         * Message date-time
      * Event message
     D  ExcStrVar             67    600                                         * Variable string
      * Event message
     D  EvMsgTxt                           Overlay(ExcStrVar:1)                 * Message text
     D  MsgTextLen                    4B 0 OVERLAY(EvMsgTxt:1)                  * Message text lengt
     D  MsgTextDta                  500    OVERLAY(EvMsgTxt:3)                  * Message text data
      * Suspended objects (general)
     D  SusSusTyp                     4    OVERLAY(ExcStrVar:1)                 * Suspend type
     D  SusRsnCde                     3    OVERLAY(ExcStrVar:5)                 * Reason code
      * Suspended objects (Native)
     D  SusObjNam                    10    OVERLAY(ExcStrVar:8)                 * Suspend object
     D  SusObjLib                    10    OVERLAY(ExcStrVar:18)                * Suspend library
     D  SusObjMbr                    10    OVERLAY(ExcStrVar:28)                * Suspend library
     D  SusObjTyp                    10    OVERLAY(ExcStrVar:38)                * Suspend type
     D  SusObjAtr                    10    OVERLAY(ExcStrVar:48)                * Suspend attribute
      * Suspended objects (IFS)
     D  SusIFSTyp                    10    OVERLAY(ExcStrVar:8)                 * IFS Object type
     D  SusIFSPth                   480    OVERLAY(ExcStrVar:18)                * IFS Object
      * Group status
     D  GrpCurSts                    10    OVERLAY(ExcStrVar:1)                 * Group status
     D  GrpCurDts                    26    OVERLAY(ExcStrVar:11)                * Status date-time
     D  GrpPrvSts                    10    OVERLAY(ExcStrVar:37)                * Previous status
     D  GrpRtvDts                    26    OVERLAY(ExcStrVar:47)                * Retrieve date-time

      * Confirmation string
     D CnfStr          DS           600
     D  OrgSysCnf                     8                                         * Original system
     D  ActCnf                        4                                         * Action

      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available

      * Message data
     D MSGDTA          DS          1024
      * Message data for MHA0008
     D  MAXMMD                 1      4B 0                                      * Max # of messages
      * Message data for MHA0101
     D  SRVNMD                 1     30                                         * Service name
      * Message data for MHA0102/MHA0103
     D  PORTMD                 1      4B 0                                      * Listening port
      * Message data for MHA0104 message
     D  ORGSMD                 1      8                                         * System
     D  ACTMD                  9     12                                         * Action
     D  MSGIDMD               13     19                                         * Message ID

      * ------------------------------------------------------------ *
      * Constants                                                    *
      * ------------------------------------------------------------ *
     D #YES            C                   CONST('*YES')
     D #CHK            C                   CONST('*CHK')
     D #SUS            C                   CONST('*SUS')
     D #EVT            C                   CONST('*EVT')
     D #GRP            C                   CONST('*GRP')
     D #MSE            C                   CONST('*MSE')
     D #END            C                   CONST('*END')
     D #CNF            C                   CONST('*CNF')
     D #HAMSGF         C                   CONST('HAMSGF    *LIBL     ')
     D #DMKMSGF        C                   CONST('DMKMSGF   *LIBL     ')
     D #MaxSkt         C                   CONST(1000)
     D #TypMSG         C                   CONST('*MSG')
     D #TypEML         C                   CONST('*EMAIL')
     D #TypNtv         C                   Const('*NTV')
     D #TypIFS         C                   Const('*IFS')
      * Character string conversion
     D #Lo             C                   CONST('abcdefghijklmnopqrstuvwxyz')
     D #Up             C                   CONST('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
      * Message values
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *

      * API parameter values
     D MSGDTLSM        S              9B 0                                      * Message data lengt
     D STCCTRSM        S              9B 0                                      * Stack counter
     D INFLRM          S              9B 0                                      * Information length
     D NBRMQSM         S              9B 0                                      * Number of MSGQ

      * Miscellaneous
     D SrvSkt          S             10I 0
     D CliSkt          S             10I 0
     D RtnTCP          S             10I 0
     D ErrStr          S            100    Based( ErrStrPtr )
     D PrtNum          S             10I 0

     D Error           S               N                                        * Error occurred
     D EndRqs          S               N                                        * End requested
     D MsgEnd          S               N                                        * End of messages

     D RtnCde          S              7A                                        * Return code
     D i               S              3  0                                      * Index
     D NbrSkt          S              5  0                                      * # of sockets
     D NbrErr          S              5  0                                      * # of errors
     D NbrEvt          S              5  0                                      * # of events
     D NbrSus          S              5  0                                      * # of suspended
     D NbrGrp          S              5  0                                      * # of Group status
     D Pos             S              5  0                                      * Starting position
     D Len             S              5  0                                      * Length of string
     D CurDTS          S               Z                                        * Current date-time
     D SusIFSKey       S            500A   Varying                              * Suspend IFS key
     D ActionSV        S              4A                                        * Saved action

      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
      * Key list for native suspended objects
     C     ChnSusNtv     KList                                                  * Chain to HMONEVLSN
     C                   KFld                    OrgSys                         * Originating system
     C                   KFld                    SusSusTyp                      * Suspend type
     C                   KFld                    MsgGrpNam                      * Group name
     C                   KFld                    SusObjNam                      * Object name
     C                   KFld                    SusObjLib                      * Object library
     C                   KFld                    SusObjMbr                      * Member name
     C                   KFld                    SusObjTyp                      * Object type
      * Key list for IFS suspended objects
     C     ChnSusIFS     KList                                                  * Chain to HMONEVLSI
     C                   KFld                    OrgSys                         * Originating system
     C                   KFld                    SusSusTyp                      * Suspend type
     C                   KFld                    MsgGrpNam                      * Group name
     C                   KFld                    SusIFSTyp                      * IFS object type
     C                   KFld                    SusIFSKey                      * IFS object key

      * ------------------------------------------------------------ *
      * Parameter lists                                              *
      * ------------------------------------------------------------ *
      * QMHSNDPM - Send program message
     C     pSNDPM        PList
     C                   Parm                    MSGIDSM           7            * Message ID
     C                   Parm                    MSGFSM           20            * Message file
     C                   Parm                    MSGDTA                         * Message data
     C                   Parm                    MSGDTLSM                       * Message data lengt
     C                   Parm                    MSGTYPSM         10            * Message type
     C                   Parm                    STCENTSM         10            * Call stack entry
     C                   Parm                    STCCTRSM                       * Stack counter
     C                   Parm                    MSGKEYSM          4            * Message key
     C                   Parm                    APIERR            8            * API Error

      * Entry parameters
     C     *Entry        Plist
     C                   Parm                    pPrd              3            * Product
     C                   Parm                    pCurUsr          10            * Current user
     C                   Parm                    pSrvNme          30            * Service name
     C                   Parm                    pRtnCde           7            * Return code

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Initialisation
     C                   Eval      Error = *OFF                                 * Error
     C                   Eval      pRtnCde = *Blanks                            * Return code

      * Get the number for the service name
     C                   Eval      PrtNum = GetPort(pSrvNme)
     C                   If        PrtNum = -1                                  * Not retrieved
      * Send diag message "Service table entry not found"
     C                   Eval      MSGIDSM = 'MHA0101'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      SRVNMD = pSrvNme                             * Service name
     C                   ExSR      SRSNDPM
     C                   Eval      Error = *ON                                  * Error
     C                   Eval      pRtnCde = 'MHA0101'                          * Port not retrieved
     C                   EndIf                                                  * Port retrieved

      * Open the socket
     C                   If        not Error                                    * No errors
     C                   Eval      SrvSkt = OpnTCP
     C                   If        SrvSkt = -1
     C     'Open Failed' Dsply
     C                   Eval      Error = *ON                                  * Error
     C                   EndIf
     C                   EndIf

      * Bind/listen
     C                   If        not Error                                    * No errors
      * Send info message "Listening on port ..."
     C                   Eval      MSGIDSM = 'MHA0102'                          * Message ID
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   Eval      PORTMD = PrtNum                              * Service name
     C                   ExSR      SRSNDPM
     C                   Eval      RtnTCP = BndTCP(SrvSkt:PrtNum:30:
     C                                             %addr(SktAdr))
     C                   If        RtnTCP = -1
     C                   Eval      Error = *ON                                  * Error
     C                   Eval      pRtnCde = 'MHA0103'                          * Bind failed
      * Send escape message "Bind failed ..."
     C                   Eval      MSGIDSM = 'MHA0103'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      PORTMD = PrtNum                              * Service name
     C                   ExSR      SRSNDPM
     C                   EndIf
     C                   EndIf

     C                   If        not Error                                    * No errors
      * Initialise/Check forwarding parameters
     C                   Call      'HMONHAL1A'
     C                   Parm      '***'         PrdWY             3            * Initialise
     C                   Parm                    pCurUsr                        * Current user
     C                   Parm                    OrgSys                         * Originating system
     C                   Parm                    MsgOrg                         * Message Origin
     C                   Parm                    ActionSV                       * Saved action
     C                   Parm                    NbrErr                         * # of error
     C                   Parm                    RtnCde                         * Return code
      * Now accept sockets until error or end requested
     C                   Eval      EndRqs = *Off                                * End requested
     C                   DoW       not Error and not EndRqs
     C                   Eval      Error = *Off                                 * Error
      * Accept
     C                   Eval      CliSkt = AcpTCP(SrvSkt:%addr(SktAdr))
     C                   If        CliSkt = -1
     C     'Acp Failed'  Dsply
     C                   Eval      Error = *ON                                  * Error
     C                   EndIf

     C                   Time                    CurDTS                         * Current date-time
     C                   Eval      NbrSkt = 0                                   * Number of sockets
     C                   Eval      NbrEvt = 0                                   * Number of events
     C                   Eval      NbrSus = 0                                   * Number of suspend
     C                   Eval      NbrGrp = 0                                   * Number of group st
     C                   Eval      MsgEnd = *Off                                * Message end
      * While end not requested and not error, receive sockets
     C                   DoW       not Error and not EndRqs and not MsgEnd
      * Receive request from remote computer
     C                   Eval      RtnTCP = RcvTCP(CliSkt:ExcStr)
     C                   If        RtnTCP = -1
     C     'Rcv Failed'  Dsply
     C                   Eval      Error = *On                                  * Error
     C                   EndIf
     C                   Eval      NbrSkt = NbrSkt + 1                          * Number of sockets
      * Send confirmation
     C                   If        not Error
     C                   Eval      OrgSysCnf = OrgSys                           * Originating system
      * If maximum number of sockets reached --> Confirm with End
     C                   If        NbrSkt >= #MaxSkt
     C                   Eval      MsgEnd = *On                                 * Message end
     C                   Eval      ActCnf = #END                                * End of messages
     C                   Else
     C                   Eval      ActCnf = #CNF                                * Action confirm
     C                   EndIf
     C                   Eval      RtnTCP = SndTCP(CliSkt:CnfStr)
     C                   If        RtnTCP = -1
     C     'No confirm'  Dsply
     C                   EndIf
     C                   EndIf

      * Process request done by remote computer
     C                   If        not Error
      * Send info message "Received message &2/&3 from system &1'
     C                   Eval      MSGIDSM = 'MHA0104'                          * Message ID
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   Eval      ORGSMD = OrgSys                              * Originating system
     C                   Eval      ACTMD = Action                               * Action
     C                   Eval      MSGIDMD = MsgID                              * Message ID
     C                   ExSR      SRSNDPM

     C                   Select
      * Do not take any action on '*CHK' request
     C                   When      Action = #CHK                                * Activity check

      * If end requested --> Set indicator
     C                   When      Action = #END                                * End request
     C                   Eval      EndRqs = *On                                 * End request

      * If end of messages --> Close client socket
     C                   When      Action = #MSE                                * End of messages
      * Close the client socket
     C                   Eval      RtnTCP = CloTCP(CliSkt)
     C                   Eval      MsgEnd = *On                                 * Message end

      * Message --> Handle message in subroutine
     C                   When      Action = #EVT                                * Event log entry
     C                   Eval      ActionSV = Action                            * Save action
     C                   Eval      NbrEvt = NbrEvt + 1                          * Number of events
     C                   ExSR      SRHndMsg                                     * Handle message

      * Suspended object --> Handle in subroutine
     C                   When      Action = #SUS                                * Suspended object
     C                   Eval      ActionSV = Action                            * Save action
     C                   Eval      NbrSus = NbrSus + 1                          * Number of suspend
     C                   ExSR      SRHndSus                                     * Handle suspend

      * Group status --> Handle in subroutine
     C                   When      Action = #GRP                                * Group status
     C                   Eval      ActionSV = Action                            * Save action
     C                   Eval      NbrGrp = NbrGrp + 1                          * Number of group st
     C                   ExSR      SRHndGrp                                     * Handle group statu

     C                   EndSL

     C                   EndIf                                                  * Error
     C                   EndDo                                                  * End of messages

      * If Maximum number of messages received --> Send diagnostic message
     C                   If        NbrSkt >= #MaxSkt
     C                   Eval      MSGIDSM = 'MHA0008'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      MAXMMD = #MaxSkt                             * Maximum # sockets
     C                   ExSR      SRSNDPM
      * Also send last message to specified message queue
     C                   Eval      MsgID = MSGIDSM                              * Message ID
     C                   Eval      MsgTextDta = MSGDTA                          * Message data
     C                   Eval      MsgTextLen = 4                               * Message data lengt
     C                   ExSR      SRHndMsg                                     * Handle message
      * Close the client socket
     C                   Eval      RtnTCP = CloTCP(CliSkt)
     C                   EndIf                                                  * Maximum # messages

      * Forward messages to message queues and e-mail addresses and call exit program
     C                   Eval      NbrErr=NbrEvt+NbrSus+NbrGrp                  * Total events
     C                   If        NbrErr > 0                                   * Any new errors?
     C                   Call      'HMONHAL1A'
     C                   Parm                    pPrd                           * Product
     C                   Parm                    pCurUsr                        * Current user
     C                   Parm                    OrgSys                         * Originating system
     C                   Parm                    MsgOrg                         * Message Origin
     C                   Parm                    ActionSV                       * Saved action
     C                   Parm                    NbrErr                         * # of error
     C                   Parm                    RtnCde                         * Return code
      * If no errors, delete remaining records
     C                   If        RtnCde = *Blanks                             * No Error
      * Delete messages
     C                   If        NbrEvt > 0                                   * Any events?
     C     *Loval        SetLL     HMONHAER
     C                   Read      HMONHAER                               95
     C     *In95         DowEQ     *Off
     C                   Delete    HMONHAER
     C                   Read      HMONHAER                               95
     C                   EndDo
     C                   EndIf                                                  * Any events?
      * Delete suspended native and IFS objects
     C                   If        NbrSus > 0                                   * Any suspends?
     C     OrgSys        SetLL     HMONHASR
     C     OrgSys        ReadE     HMONHASR                               95
     C     *In95         DowEQ     *Off
     C                   Delete    HMONHASR
     C     OrgSys        ReadE     HMONHASR                               95
     C                   EndDo
     C                   EndIf                                                  * Any suspends?
      * Delete group statuses
     C                   If        NbrGrp > 0                                   * Any group status?
     C     OrgSys        SetLL     HMONHAGR
     C     OrgSys        ReadE     HMONHAGR                               95
     C     *In95         DowEQ     *Off
     C                   Delete    HMONHAGR
     C     OrgSys        ReadE     HMONHAGR                               95
     C                   EndDo
     C                   EndIf                                                  * Any group status?
     C                   Else                                                   * Error found
     C                   Eval      pRtnCde = RtnCde                             * Return return code
     C                   Eval      Error = *On                                  * End loop
     C                   EndIf                                                  * No Error
     C                   EndIf                                                  * Any msg/sus

     C                   EndDo                                                  * End requested
     C                   EndIf                                                  * Error

      * Close the socket
     C                   Eval      RtnTCP = CloTCP(SrvSkt)

     C                   Eval      *InLR = *On

      * ------------------------------------------------------------------- *
      * SRHndMsg - Handle received message                                  *
      * ------------------------------------------------------------------- *
     C     SRHndMsg      BegSR
      * Determine message file value, based on first 3 characters of MSGID
     C                   Select
     C                   When      %subst(MSGID:1:3) = 'DMK'
     C                   MoveL     #DMKMSGF      MEMSGF                         * Message file
     C                   When      %subst(MSGID:1:3) = 'MHA'
     C                   MoveL     #HAUMSGF      MEMSGF                         * Message file
     C                   Other
     C                   MoveL     #HAMSGF       MEMSGF                         * Message file
     C                   EndSL
      * Fill remainder of fields
     C                   Eval      MEORGSYS = OrgSys                            * Originating system
     C                   MoveL     MsgDTS        MEMSGDTS                       * Message date-time
     C                   Eval      MEMSGID = MsgID                              * Message ID
     C                   Eval      MEMSGORG = MsgOrg                            * Message Origin
     C                   Eval      MEGRPNAM = MsgGrpNam                         * Group name
     C                   Eval      MEMSGDTA = MsgTextDta                        * Message data
     C                   Eval      %len(MEMSGDTA) = MsgTextLen                  * Message data lengt
      *
     C                   Write     HMONHAER

     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRHndSus - Handle suspended object                                  *
      * ------------------------------------------------------------------- *
     C     SRHndSus      BegSR

     C                   Select
      * If object is native
     C                   When      SusSusTyp = #TypNtv                          * Native object
     C                   Clear                   HMONHASR                       * Clear all fields
     C                   Eval      MSORGSYS = OrgSys                            * Originating system
     C                   Eval      MSSUSTYP = SusSusTyp                         * Suspension type
     C                   Eval      MSGRPNAM = MsgGrpNam                         * Group name
     C                   Eval      MSRSNCDE = SusRsnCde                         * Reason code
     C                   MoveL     MsgDTS        MSSUSDTS                       * Suspend date-time
     C                   Eval      MSUPDDTS = CurDTS                            * Suspend update
     C                   Eval      MSOBJNAM = SusObjNam                         * Object name
     C                   Eval      MSOBJLIB = SusObjLib                         * Object library
     C                   Eval      MSOBJMBR = SusObjMbr                         * Member name
     C                   Eval      MSOBJTYP = SusObjTyp                         * Object type
     C                   Eval      MSOBJATR = SusObjAtr                         * Object attribute
     C                   Write     HMONHASR                                     * Write suspend rcd

      * If object is BSF
     C                   When      SusSusTyp = #TypIFS                          * IFS object
     C                   Eval      SusIFSKey = SusIFSPth
     C     #Lo:#Up       XLate     SusIFSKey     SusIFSKey                      * Make upper case
     C                   Clear                   HMONHASR                       * Clear all fields
     C                   Eval      MSORGSYS = OrgSys                            * Originating system
     C                   Eval      MSSUSTYP = SusSusTyp                         * Suspension type
     C                   Eval      MSGRPNAM = MsgGrpNam                         * Group name
     C                   Eval      MSRSNCDE = SusRsnCde                         * Reason code
     C                   MoveL     MsgDTS        MSSUSDTS                       * Suspend date-time
     C                   Eval      MSUPDDTS = CurDTS                            * Suspend update
     C                   Eval      MSIFSTYP = SusIFSTyp                         * IFS type
     C                   Eval      MSIFSKEY = SusIFSKey                         * IFS key
     C                   Eval      MSIFSPTH = %TrimR(SusIFSPth)                 * IFS object path
     C                   Write     HMONHASR                                     * Write suspend rcd
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRHndGrp - Handle group status                                      *
      * ------------------------------------------------------------------- *
     C     SRHndGrp      BegSR
     C                   Clear                   HMONHAGR                       * Clear all fields
     C                   Eval      MGORGSYS = OrgSys                            * Originating system
     C                   Eval      MGGRPNAM = MsgGrpNam                         * Group name
     C                   Eval      MGCURSTS = GrpCurSts                         * Current status
     C                   MoveL     GrpCurDTS     MGCURDTS                       * Status date-time
     C                   Eval      MGPRVSTS = GrpPrvSts                         * Previous status
     C                   MoveL     GrpRtvDTS     MGRTVDTS                       * Retrieve date-time
     C                   Write     HMONHAGR                                     * Write group record
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSNDPM - Send program message                                      *
      * ------------------------------------------------------------------- *
     C     SRSNDPM       BegSR
      * Determine message file value for QMHSNDPM API
     C     MSGFSM        IfEQ      *BLANKS
     C                   MoveL     #HAUMSGF      MSGFSM                         * Default msgf
     C                   EndIf
      * Set default message type
     C     MSGTYPSM      IfEQ      *BLANKS                                      * Message type
     C                   MoveL     #DIAG         MSGTYPSM                       * Message type
     C                   EndIf
      * Determine stack entry/counter value, based on message type
     C                   Select
     C     STCENTSM      WhenNE    *BLANKS                                      * Stack entry
     C     MSGTYPSM      WhenEQ    #STATUS                                      * Status message
     C                   MoveL(P)  #EXT          STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C     MSGTYPSM      WhenEQ    #INFO                                        * Status message
     C                   MoveL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   Other
     C                   MoveL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-Add     1             STCCTRSM                       * Stack counter
     C                   EndSL
      * Send program message
     C                   Z-Add     0             BPVDAE                         * Bytes provide
     C                   Z-Add     1024          MSGDTLSM                       * Message data lengt
     C                   Call      'QMHSNDPM'    pSNDPM                         * Send program msg
      * Reset values for next message send
     C                   MoveL     *BLANKS       MSGFSM                         * Message file
     C                   MoveL     *BLANKS       MSGTYPSM                       * Message type
     C                   MoveL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   EndSR
