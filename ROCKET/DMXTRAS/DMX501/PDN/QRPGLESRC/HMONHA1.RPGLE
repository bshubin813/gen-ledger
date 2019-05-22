      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONHA1         *PGM                              *
      *            Dependent on the action code passed, process      *
      *            event log entries, suspended objects and group    *
      *            activity.                                         *
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
      * 20041216 FK  Initial delivery (copy from HMONEVL)            *
      *              Only connect to listener if any message         *
      * 20041224 FK  Add offset in hours and minutes to event time   *
      * 20060404 FK  Check for group status                          *
      * 20070724 FK  Random message ID was passed to listener for    *
      *              *GRP message                                    *
      *              Inactivity message was sent when group was not  *
      *              active before                                   *
      * 20111220 FK  Remove HA                                       *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HACTGRP(*CALLER) BNDDIR('HMONHA' : 'QC2LE') EXTBININT(*YES)

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Event log
     FHUEVNL0   IF   E           K DISK    UsrOpn
      * Suspended objects on source
     FHUMOBSO   IF   E           K DISK    UsrOpn
      * Suspended objects on source (objects)
     FHUSOBSO   IF   E           K DISK    UsrOpn
      * Suspended objects on target
     FHUTMOBSO  IF   E           K DISK    UsrOpn
      * Suspended IFS objects on target
     FHUBTIDSO  IF   E           K DISK    UsrOpn
      * Target names by target ID
     FHUTGTTI   IF   E           K DISK    UsrOpn
      * Groups by group ID
     FHUGRPGI   IF   E           K DISK    UsrOpn
      * Groups configured
     FHLSTCFGG  IF   E           K DISK    UsrOpn
      * Group status
     FHMONHAG   UF A E           K DISK    UsrOpn

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
     D StrErr          PR              *   ExtProc( 'strerror' )
     D  Dummy                         1    Options( *Omit )

     D GetHostIP       PR            15
     D                              100

     D GetPort         PR            10i 0
     D                               30

     D OpnTCP          PR            10I 0

     D CnnTCP          PR            10I 0
     D                               10I 0 Const
     D                               15
     D                                2  0 Const
     D                                4  0 Const

     D SndTCP          PR            10I 0
     D                               10I 0 Const
     D                              600

     D RcvTCP          PR            10I 0
     d                               10I 0 Const
     d                              600

     D CloTCP          PR            10I 0
     D                               10I 0 Const

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Starting date/time
     D pStrDTI         DS             4
     D  pDateTime                    10i 0                                      * Starting date/time

      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available

      * *DOS Date format
     D DOSDTS          DS            11
     D  DOSHrs                        3U 0                                      * Hour
     D  DOSMin                        3U 0                                      * Minute
     D  DOSSec                        3U 0                                      * Second
     D  DOSHndSec                     3U 0                                      * Hunderds of secs
     D  DOSDay                        3U 0                                      * Day
     D  DOSMonth                      3U 0                                      * Month
     D  DOSYear                       5I 0                                      * Year
     D  DOSTimZon                     5I 0                                      * Time Zone
     D  DOSDOW                        3U 0                                      * Day of Week

      * RTVM0200 - Retrieve message description data structure
     D RTVM0200        DS            30
     D  BPVDRM                 1      4B 0                                      * Bytes provided
     D  BAVLRM                 5      8B 0                                      * Bytes available
     D  MSGSEVRM               9     12B 0                                      * Message severity
     D  ALRIDXRM              13     16B 0                                      * Alert index
     D  ALROPTRM              17     25                                         * Alert option
     D  LOGINDRM              26     26                                         * Log indicator

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

      * Message data
     D MSGDTA          DS           500
      * Message data for MHA0001/MHA0002 messages
     D  ORGSMD                 1      8                                         * System
     D  NBREMD                 9     12B 0                                      * # of events
     D  DTSMD                 13     31                                         * Date-time stamp
      * Message data for MHA0101
     D  SRVNMD                 1     30                                         * Service name
      * Message data for MHA0105/MHA0106/MHA0107/MHA0109
     D  HOSTMD                 1    100                                         * Host name
     D  IPADMD               101    115                                         * Host IP Address
     D  PORTMD               116    119B 0                                      * Remote port
      * Message data for MHA0108 (additional)
     D  ACTMD                  9     12                                         * Action
     D  MSGIDMD               13     19                                         * Message ID
     D  CTLSMD                20     27                                         * Controlling system
     D  FILLER01MD            28     37                                         * Target name
     D  GRPNMD                38     47                                         * Group name

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #YES            C                   CONST('*YES')
     D #NO             C                   CONST('*NO ')
     D #ACT            C                   CONST('*ACT')
     D #SUS            C                   CONST('*SUS')
     D #EVT            C                   CONST('*EVT')
     D #GRP            C                   CONST('*GRP')
     D #MSE            C                   CONST('*MSE')
     D #END            C                   CONST('*END')
     D #CNF            C                   CONST('*CNF')
     D #NONE           C                   CONST('*NONE')
     D #FILE           C                   CONST('*FILE')
     D #DIR            C                   CONST('*DIR')
     D #STMF           C                   CONST('*STMF')
     D #Inactive       C                   CONST('*INACTIVE')
     D #TypNtv         C                   Const('*NTV')
     D #TypIFS         C                   Const('*IFS')
     D #GrpEnd         C                   Const('*GRPEND')
     D #HAMSGF         C                   CONST('HAMSGF    *LIBL     ')
     D #DMKMSGF        C                   CONST('DMKMSGF   *LIBL     ')
     D #Epoch          C                   CONST(Z'1970-01-01-00.00.00')
      * Message values
     D #MSGF           C                   CONST('HAUMSG    *LIBL     ')
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

     D PrtNum          S             10i 0                                      * Port number
     D IPAddr          S             15                                         * IP address
     D SrvSkt          S             10I 0                                      * Server socket
     D CliSkt          S             10I 0                                      * Client socket
     D RtnTCP          S             10I 0                                      * TCP return code

     D ErrStr          S            100    Based(ErrStrPtr)                     * Error string

     D Error           S               N                                        * Error occurred
     D SktOpn          S               N                                        * Socket open?
     D MsgEnd          S               N                                        * End of messages?

     D NbrEvt          S              5  0                                      * # of Events
     D NbrSus          S              5  0                                      * # of Suspends
     D NbrGrp          S              5  0                                      * # of Group status

     D DATETIME        S             10i 0                                      * Redefinition file
     D BinDT           S             10i 0                                      * Binary date-time
     D CurDTS          S               Z                                        * Current date-time
     D DTS             S               Z                                        * Date-time stamp
     D DTS@            S             26A                                        * Date-time stamp
     D HghDTS          S             19A                                        * Highest date-time
     D ChkDTS          S             19A                                        * Check date-time
     D NbrMin          S             10  0                                      * # of minutes
     D GrpSts          S             10a                                        * Group status

      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
      * Key list for positioning to event log
     C     POSEVN        KList
     C                   KFld                    MSGTYPE                        * Message type
     C                   KFld                    DATETIME                       * Date/time
      * Key list for reading event log
     C     LIMEVN        KList
     C                   KFld                    MSGTYPE                        * Message type

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
      * QMHRTVM - Retrieve message description
     C     pRTVMD        PList
     C                   Parm                    RTVM0200                       * RTVM0200 format
     C                   Parm      30            INFLRM                         * Info length
     C                   Parm      'RTVM0200'    FMTNRM            8            * Format name
     C                   Parm                    MSGIDRM           7            * Message ID
     C                   Parm                    MSGFRM           20            * Message file
     C                   Parm                    MSGDTA                         * Message data
     C                   Parm                    MSGDTLSM                       * Message data lengt
     C                   Parm      '*YES'        RPLSRM           10            * Replace subst. var
     C                   Parm      '*NO'         RTNFRM           10            * Return Fmt ctl chr
     C                   Parm                    APIERR            8            * API Error
      * Entry parameters
     C     *Entry        Plist
     C                   Parm                    pCtlSys           8            * Controlling system
     C                   Parm                    pCtlHost        100            * Controlling host
     C                   Parm                    pOrgSys           8            * Originating system
     C                   Parm                    pSrvNme          30            * Service name
     C                   Parm                    pAction           4            * Action code
     C                   Parm                    pStrDTS          19            * Start Date/Time
     C                   Parm                    pSusTim           5 0          * Suspended for...
     C                   Parm                    pGrpTim           5 0          * Group inactive for
     C                   Parm                    RtnCde            7            * Return code

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Initialisation
     C                   Eval      Error = *OFF                                 * Error
     C                   Eval      SktOpn = *OFF                                * Socket open
     C                   Eval      RtnCde = *Blanks                             * Return code
     C                   Time                    CurDTS                         * Current date-time

      * If starting date-time not set yet, calculate start time, taking UTC offset into account
     C                   If        pStrDTS = *Blanks                            * No start date
      * Retrieve UTC offset
     C                   Clear                   APIErr
     C                   Eval      BPVDAE = 15                                  * Suppress error
     C                   Call      'QWCCVTDT'
     C                   Parm      '*CURRENT'    InpFmtWC         10            * Input format
     C                   Parm      *Blanks       InpDatWC         26            * Input date
     C                   Parm      '*DOS'        OutFmtWC         10            * Output format
     C                   Parm                    DOSDTS                         * Output date
     C                   Parm                    APIErr                         * API error
     C     CurDTS        AddDur    DOSTimZon:*MN DTS                            * Calculate DTS
     C                   MoveL     DTS           DTS@                           * Character DTS
     C                   Eval      pStrDTS = %Subst(DTS@:1:19)                  * Starting DTS
     C                   EndIf

      * Open files for handling event log messages
     C                   If        pAction = #EVT and                           * *EVT
     C                             not %Open(HUEVNL0)                           * Files not yet open
     C                   Open      HUEVNL0                              99
     C                   EndIf                                                  * *EVT

      * Open files for handling suspended objects
     C                   If        pAction = #SUS and                           * *SUS
     C                             not %Open(HUMOBSO)                           * Files not yet open
     C                   Open      HUMOBSO                              99
     C                   Open      HUSOBSO                              99
     C                   Open      HUTMOBSO                             99
     C                   Open      HUBTIDSO                             99
     C                   Open      HUTGTTI                              99
     C                   Open      HUGRPGI                              99
     C                   EndIf                                                  * *SUS

      * Open files for handling group status
     C                   If        pAction = #GRP and                           * *GRP
     C                             not %Open(HLSTCFGG)                          * Files not yet open
     C                   Open      HLSTCFGG                             99
     C                   Open      HMONHAG                              99
     C                   ExSR      SRLstGrp                                     * Fill group listing
     C                   EndIf                                                  * *GRP

      * Now do routine dependent on action code
     C                   Select

      *
      * If Action = *END --> Send individual message to listener
      *
     C                   When      pAction = #END                               * *END
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = pAction                             * Action
     C                   Eval      Msgid = #NONE                                * Message ID
     C                   Eval      MsgGrpNam = #None                            * Group name
     C                   ExSR      SRSndSkt                                     * Send socket

      *
      * If Action = *EVT --> Start reading event log from starting point
      *
     C                   When      pAction = #EVT                               * *EVT
      * Calculate binary date-time string for positioning
     C                   Eval      DTS@ = pStrDTS + '.000000'                   * Date-time
     C                   MoveL     DTS@          DTS                            * Date-time
     C     DTS           SubDur    #Epoch        BinDT:*S               31      * Binary date-time
      * Read source messages
     C                   Eval      HghDTS = pStrDTS                             * Highest date-time
     C                   Eval      MsgEnd = *Off                                * Message end
     C                   Eval      NbrEvt = 0                                   * # of events
     C                   Eval      MSGTYPE = 's'                                * Source
     C                   Eval      DATETIME = BinDT                             * Date/time
     C     POSEVN        SetGT     HUEVNL0@
     C     LIMEVN        ReadE     HUEVNL0@                               95
     C                   DoW       not *In95 and not Error                      * Not end of evt
     C                             and not MsgEnd
      * Convert binary date-time to date-time stamp
     C                   Clear                   DTS
     C     #Epoch        AddDur    DATETIME:*S   DTS                    31      * Date-time stamp
      * Keep date-time stamp for positioning
     C                   MoveL     DTS           DTS@                           * Keep DTS
     C                   MoveL     DTS@          ChkDTS                         * Keep DTS
      * Add offset for messages
     C                   AddDur    OFFSETHRS:*H  DTS                    31      * Add UTC Hours
     C                   AddDur    OFFSETMIN:*MN DTS                    31      * Add UTC Minutes
     C                   MoveL     DTS           MsgDTS                         * Message date-time
      * Only process messages for this machine
     C                   If        MACHNAME = pOrgSys                           * System name
      * Retrieve message severity
     C                   Eval      MSGIDRM = MSGID                              * Message ID
     C                   Eval      MSGDTLSM = MsgTextLen                        * Message data lengt
     C                   Eval      MSGDTA = MsgTextDta                          * Message data
     C                   ExSR      SRRtvMsg                                     * Retrieve message
     C                   If        MSGSEVRM >= 30                               * Severity >= 30
     C                   Eval      NbrEvt = NbrEvt + 1                          * # of events
      * Send detail message to listener
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = pAction                             * Action
     C                   Eval      MsgOrg = MSGTYPE                             * Message origin
     C                   Eval      MsgGrpNam = GRPNAME                          * Group name
     C                   ExSR      SRSndSkt                                     * Send socket
     C                   EndIf                                                  * Severity >= 30
     C                   EndIf                                                  * Current system
      * If date-time greater than highest value --> update
     C                   If        ChkDTS > HghDTS
     C                   Eval      HghDTS = ChkDTS
     C                   EndIf                                                  * Highest value
     C     LIMEVN        ReadE     HUEVNL0@                               95
     C                   EndDo                                                  * Source messages
      * Send diag message "# Errors found on ... system'
     C                   If        NbrEvt > 0                                   * Events found
     C                   Eval      ORGSMD = pOrgSys                             * Originating system
     C                   Eval      NBREMD = NbrEvt                              * Number of events
     C                   Eval      DTSMD = HghDTS                               * Highest date-time
     C                   Eval      MSGIDSM = 'MHA0001'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   ExSR      SRSNDPM
     C                   EndIf                                                  * Events found

      * Calculate binary date-time string for positioning
     C                   Eval      DTS@ = pStrDTS + '.000000'                   * Date-time
     C                   MoveL     DTS@          DTS                            * Date-time
     C     DTS           SubDur    #Epoch        BinDT:*S               31      * Binary date-time
      * Read target messages
     C                   Eval      MsgEnd = *Off                                * Message end
     C                   Eval      NbrEvt = 0                                   * # of events
     C                   Eval      MSGTYPE = 't'                                * Source
     C                   Eval      DATETIME = BinDT                             * Date/time
     C     POSEVN        SetGT     HUEVNL0@
     C     LIMEVN        ReadE     HUEVNL0@                               95
     C                   DoW       not *In95 and not Error                      * Not end of evt
     C                             and not MsgEnd
      * Convert binary date-time to date-time stamp
     C                   Clear                   DTS
     C     #Epoch        AddDur    DATETIME:*S   DTS                    31      * Date-time stamp
      * Keep date-time stamp for positioning
     C                   MoveL     DTS           DTS@                           * Keep DTS
     C                   MoveL     DTS@          ChkDTS                         * Keep DTS
      * Add offset for messages
     C                   AddDur    OFFSETHRS:*H  DTS                    31      * Add UTC Hours
     C                   AddDur    OFFSETMIN:*MN DTS                    31      * Add UTC Minutes
     C                   MoveL     DTS           MsgDTS                         * Message date-time
      * Only process messages for this machine
     C                   If        MACHNAME = pOrgSys                           * System name
      * Retrieve message severity
     C                   Eval      MSGIDRM = MSGID                              * Message ID
     C                   Eval      MSGDTLSM = MsgTextLen                        * Message data lengt
     C                   Eval      MSGDTA = MsgTextDta                          * Message data
     C                   ExSR      SRRtvMsg                                     * Retrieve message
     C                   If        MSGSEVRM >= 30                               * Severity >= 30
     C                   Eval      NbrEvt = NbrEvt + 1                          * # of events
      * Send detail message to listener
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = pAction                             * Action
     C                   Eval      MsgOrg = MSGTYPE                             * Message origin
     C                   Eval      MsgGrpNam = GRPNAME                          * Group name
     C                   ExSR      SRSndSkt                                     * Send socket
     C                   EndIf                                                  * Severity >= 30
     C                   EndIf                                                  * Current system
      * If date-time greater than highest value --> update
     C                   If        ChkDTS > HghDTS
     C                   Eval      HghDTS = ChkDTS
     C                   EndIf                                                  * Highest value
     C     LIMEVN        ReadE     HUEVNL0@                               95
     C                   EndDo                                                  * Target messages
      * Send diag message "# Errors found on ... system'
     C                   If        NbrEvt > 0                                   * Events found
     C                   Eval      ORGSMD = pOrgSys                             * Originating system
     C                   Eval      NBREMD = NbrEvt                              * Number of events
     C                   Eval      DTSMD = HghDTS                               * Highest date-time
     C                   Eval      MSGIDSM = 'MHA0002'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   ExSR      SRSNDPM
     C                   EndIf                                                  * Events found

      * Indicate end of messages being sent (Only if socket open)
     C                   If        SktOpn                                       * Socket is open
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = #MSE                                * Action
     C                   Eval      Msgid = #NONE                                * Message ID
     C                   Eval      MsgGrpNam = #None                            * Group name
     C                   ExSR      SRSndSkt                                     * Send socket
     C                   EndIf                                                  * Events found

      * Return highest value for starting point to calling program
     C                   Eval      pStrDTS = HghDTS                             * Starting point

      *
      * Read primary system suspended data objects
      *
     C                   When      pAction = #SUS                               * Suspended objects
     C                   Eval      HghDTS = pStrDTS                             * Highest date-time
     C                   Eval      NbrSus = 0                                   * # of suspends
     C     *Loval        SetLL     HUMOBSO@
     C                   Read      HUMOBSO@                               95
     C                   DoW       not *In95 and not Error                      * End or error
     C                             and not MsgEnd
     C                   MoveL     CHKPOINT      DTS@                           * Suspend date-time
     C                   Eval      ChkDTS = %Subst(DTS@:1:19)                   * Check date-time
     C     CurDTS        SubDur    CHKPOINT      NbrMin:*MN                     * Age in minutes
      * If reason is not blank
     C                   If        REASON <> *Blanks                            * Valid reason
     C                             and ChkDTS > pStrDTS                         * New suspended obje
     C                             and NbrMin >= pSusTim                        * Suspended for
      * Retrieve target and group
     C     TGTID         Chain     HUTGTTI@                           94
     C     GRPID         Chain     HUGRPGI@                           94
     C                   Eval      NbrSus = NbrSus + 1                          * # of suspends
     C                   Clear                   ExcStr                         * Exchange string
      * Send socket
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = #SUS                                * *SUS
     C                   Eval      Msgid = #TypNtv                              * Suspend type
     C                   Eval      MsgGrpNam = GRPNAME                          * Group name
     C                   Eval      MsgDTS = DTS@                                * Date-time sstamp
     C                   Eval      SusSusTyp = #TypNtv                          * Suspend type
     C                   Eval      SusRsnCde = REASON                           * Reason code
     C                   Eval      SusObjNam = OBJNAME                          * Object name
     C                   Eval      SusObjLib = OBJLIB                           * Library name
     C                   Eval      SusObjTyp = #FILE                            * Object type
     C                   ExSR      SRSndSkt                                     * Send socket
      * If date-time greater than highest value --> update
     C                   If        ChkDTS > HghDTS                              * Highest value
     C                   Eval      HghDTS = ChkDTS
     C                   EndIf                                                  * Highest value
     C                   EndIf                                                  * Valid reason
     C                   Read      HUMOBSO@                               95
     C                   EndDo                                                  * Source suspended

      * Read backup system suspended data objects
     C     *Loval        SetLL     HUTMOBSO@
     C                   Read      HUTMOBSO@                              95
     C                   DoW       not *In95 and not Error                      * End or error
     C                             and not MsgEnd
     C                   MoveL     CHKPOINT      DTS@                           * Suspend date-time
     C                   Eval      ChkDTS = %Subst(DTS@:1:19)                   * Check date-time
     C     CurDTS        SubDur    CHKPOINT      NbrMin:*MN                     * Age in minutes
      * If reason is not blank
     C                   If        REASON <> *Blanks                            * Valid reason
     C                             and ChkDTS > pStrDTS                         * New suspended obje
     C                             and NbrMin >= pSusTim                        * Suspended for
      * Retrieve target and group
     C     TGTID         Chain     HUTGTTI@                           94
     C     GRPID         Chain     HUGRPGI@                           94
     C                   Eval      NbrSus = NbrSus + 1                          * # of suspends
     C                   Clear                   ExcStr                         * Exchange string
      * Send socket
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = #SUS                                * *SUS
     C                   Eval      Msgid = #TypNtv                              * Suspend type
     C                   Eval      MsgGrpNam = GRPNAME                          * Group name
     C                   Eval      MsgDTS = DTS@                                * Date-time sstamp
     C                   Eval      SusSusTyp = #TypNtv                          * Suspend type
     C                   Eval      SusRsnCde = REASON                           * Reason code
     C                   Eval      SusObjNam = OBJNAME                          * Object name
     C                   Eval      SusObjLib = OBJLIB                           * Library name
     C                   Eval      SusObjTyp = #FILE                            * Object type
     C                   ExSR      SRSndSkt                                     * Send socket
      * If date-time greater than highest value --> update
     C                   If        ChkDTS > HghDTS                              * Highest value
     C                   Eval      HghDTS = ChkDTS
     C                   EndIf                                                  * Highest value
     C                   EndIf                                                  * Valid reason
     C                   Read      HUTMOBSO@                              95
     C                   EndDo                                                  * Target suspended

      * Read suspended objects
     C     *Loval        SetLL     HUSOBSO@
     C                   Read      HUSOBSO@                               95
     C                   DoW       not *In95 and not Error                      * End or error
     C                             and not MsgEnd
     C                   MoveL     CHECKPOINT    DTS@                           * Suspend date-time
     C                   MoveL     CHECKPOINT    DTS                            * Suspend date-time
     C                   Eval      ChkDTS = %Subst(DTS@:1:19)                   * Check date-time
     C     CurDTS        SubDur    DTS           NbrMin:*MN                     * Age in minutes
      * If reason is not blank
     C                   If        REASON <> *Blanks                            * Valid reason
     C                             and ChkDTS > pStrDTS                         * New suspended obje
     C                             and NbrMin >= pSusTim                        * Suspended for
      * Retrieve target and group
     C     TGTID         Chain     HUTGTTI@                           94
     C     GRPID         Chain     HUGRPGI@                           94
     C                   Eval      NbrSus = NbrSus + 1                          * # of suspends
     C                   Clear                   ExcStr                         * Exchange string
      * Send socket
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = #SUS                                * *SUS
     C                   Eval      Msgid = #TypNtv                              * Suspend type
     C                   Eval      MsgGrpNam = GRPNAME                          * Group name
     C                   Eval      MsgDTS = DTS@                                * Date-time sstamp
     C                   Eval      SusSusTyp = #TypNtv                          * Suspend type
     C                   Eval      SusRsnCde = REASON                           * Reason code
     C                   Eval      SusObjNam = OBJNAME                          * Object name
     C                   Eval      SusObjLib = OBJLIB                           * Library name
     C                   Eval      SusObjTyp = OBJTYPE                          * Object type
     C                   Eval      SusObjAtr = OBJATTR                          * Object attribute
     C                   Eval      SusObjMbr = MEMBER                           * Object member
     C                   ExSR      SRSndSkt                                     * Send socket
      * If date-time greater than highest value --> update
     C                   If        ChkDTS > HghDTS                              * Highest value
     C                   Eval      HghDTS = ChkDTS
     C                   EndIf                                                  * Highest value
     C                   EndIf                                                  * Valid reason
     C                   Read      HUSOBSO@                               95
     C                   EndDo                                                  * Source suspended

      * Read suspended IFS objects
     C     *Loval        SetLL     HUBTIDSO@
     C                   Read      HUBTIDSO@                              95
     C                   DoW       not *In95 and not Error                      * End or error
     C                             and not MsgEnd
     C                   MoveL     CHKPOINT      DTS@                           * Suspend date-time
     C                   Eval      ChkDTS = %Subst(DTS@:1:19)                   * Check date-time
     C     CurDTS        SubDur    CHKPOINT      NbrMin:*MN                     * Age in minutes
      * If reason is not blank
     C                   If        REASON <> *Blanks                            * Valid reason
     C                             and ChkDTS > pStrDTS                         * New suspended obje
     C                             and NbrMin >= pSusTim                        * Suspended for
     C                   Eval      NbrSus = NbrSus + 1                          * # of suspends
     C                   Clear                   ExcStr                         * Exchange string
      * Send socket
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = #SUS                                * *SUS
     C                   Eval      Msgid = #TypIFS                              * Suspend type
     C                   Eval      MsgGrpNam = GRPNAME                          * Group name
     C                   Eval      MsgDTS = DTS@                                * Date-time sstamp
     C                   Eval      SusSusTyp = #TypIFS                          * Suspend type (IFS)
     C                   Eval      SusRsnCde = REASON                           * Reason code
     C                   If        %Len(PATHNME) <= 480                         * Fits
     C                   Eval      SusIFSPth = PATHNME                          * IFS path name
     C                   Else
     C                   Eval      SusIFSPth = %Subst(PATHNME:1:475)+'...'
     C                   EndIf
      * Fill object type
     C                   Select
     C                   When      BSFTYPE='D'                                  * Directory
     C                   Eval      SusIFSTyp = #DIR                             * *DIR
     C                   When      BSFTYPE='F'                                  * Stream file
     C                   Eval      SusIFSTyp = #STMF                            * *STMF
     C                   Other
     C                   Eval      SusIFSTyp = '????'                           * Unknown
     C                   EndSL
     C                   ExSR      SRSndSkt                                     * Send socket
      * If date-time greater than highest value --> update
     C                   If        ChkDTS > HghDTS                              * Highest value
     C                   Eval      HghDTS = ChkDTS
     C                   EndIf                                                  * Highest value
     C                   EndIf                                                  * Valid reason
     C                   Read      HUBTIDSO@                              95
     C                   EndDo                                                  * Suspended IFS

      * Send diag message "# Suspended objects found on ... system'
     C                   If        NbrSus > 0                                   * Inactive groups fn
     C                   Eval      ORGSMD = pOrgSys                             * Originating system
     C                   Eval      NBREMD = NbrGrp                              * Number of events
     C                   Eval      DTSMD = HghDTS                               * Highest date-time
     C                   Eval      MSGIDSM = 'MHA0016'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   ExSR      SRSNDPM
     C                   EndIf                                                  * Events found

      * Indicate end of messages being sent (Only if socket open)
     C                   If        SktOpn                                       * Socket open?
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = #MSE                                * Action
     C                   Eval      Msgid = #NONE                                * Message ID
     C                   Eval      MsgGrpNam = #None                            * Group name
     C                   ExSR      SRSndSkt                                     * Send socket
     C                   EndIf                                                  * Events found

      * Return highest value for starting point to calling program
     C                   Eval      pStrDTS = HghDTS                             * Starting point

      *
      * If Action = *GRP --> Process all groups and retrieve status
      *
     C                   When      pAction = #GRP                               * *GRP
      * Check group statuses
     C                   Eval      HghDTS = pStrDTS                             * Highest date-time
     C                   Eval      MsgEnd = *Off                                * Message end
     C                   Eval      NbrGrp = 0                                   * # of group status
     C     pOrgSys       SetLL     HMONHAGR
     C     pOrgSys       ReadE     HMONHAGR                               95
     C                   DoW       not *In95 and not Error                      * Not end of groups
     C                             and not MsgEnd
      * Retrieve group status
     C                   Call      'HMONHA1A'                                   * Get group status
     C                   Parm                    MGGRPNAM                       * Group name
     C                   Parm                    GrpSts                         * Group status
      * Update fields in record
     C                   Eval      MGRTVDTS=CurDTS                              * Retrieve DTS
      * If group status has changed --> inform controlling system
     C                   If        GrpSts<>MGCURSTS                             * Status changed
     C                   Eval      MGPRVSTS=MGCURSTS                            * Previous status
     C                   Eval      MGCURSTS=GrpSts
     C                   Eval      MGCURDTS=CurDTS                              * Current DTS
     C                   Eval      MGALRSNT=#No                                 * Alert sent
     C                   EndIf                                                  * Status changed
      * If status *INACTIVE longer than specified minutes
     C     MGRTVDTS      SubDur    MGCURDTS      NbrMin:*MN                     * Age in minutes
     C                   If        MGCURSTS=#Inactive and MGPRVSTS<>*Blanks and * Become inactive an
     C                             NbrMin >= pGrpTim and MGALRSNT=#No           * for specified minu
     C                   Eval      NbrGrp = NbrGrp + 1                          * # of group status
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = pAction                             * Action
     C                   Eval      MsgId = #GrpEnd                              * Message ID
     C                   Eval      MsgGrpNam = MGGRPNAM                         * Group name
     C                   Eval      GrpCurSts = MGCURSTS                         * Current status
     C                   MoveL     MGCURDTS      GrpCurDts                      * Status date-time
     C                   Eval      GrpPrvSts = MGPRVSTS                         * Previous status
     C                   MoveL     MGRTVDTS      GrpRtvDts                      * Retrieve date-time
     C                   ExSR      SRSndSkt                                     * Send socket
     C                   If        not Error                                    * No error
     C                   Eval      MGALRSNT=#Yes                                * Alert sent
     C                   EndIf                                                  * No Error
     C                   EndIf                                                  * Inactive
     C                   Update    HMONHAGR
      * Read next group
     C     pOrgSys       ReadE     HMONHAGR                               95
     C                   EndDo                                                  * Listed groups
      * Send diag message "# Inactive groups found on ... system'
     C                   If        NbrGrp > 0                                   * Inactive groups fn
     C                   Eval      ORGSMD = pOrgSys                             * Originating system
     C                   Eval      NBREMD = NbrGrp                              * Number of events
     C                   MoveL     CurDTS        DTS@                           * Highest date-time
     C                   MoveL     DTS@          DTSMD                          * Highest date-time
     C                   Eval      MSGIDSM = 'MHA0017'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   ExSR      SRSNDPM
     C                   EndIf                                                  * Events found

      * Indicate end of messages being sent (Only if socket open)
     C                   If        SktOpn                                       * Socket open?
     C                   Eval      OrgSys = pOrgSys                             * Originating system
     C                   Eval      Action = #MSE                                * Action
     C                   Eval      Msgid = #NONE                                * Message ID
     C                   Eval      MsgGrpNam = #None                            * Group name
     C                   ExSR      SRSndSkt                                     * Send socket
     C                   EndIf                                                  * Events found

      * Return highest value for starting point to calling program
     C                   MoveL     CurDTS        DTS@                           * Highest date-time
     C                   MoveL     DTS@          pStrDTS                        * Starting point

     C                   EndSL

     C                   If        SktOpn                                       * Socket open
      * Send info message "Closing connection with host ...'
     C                   Eval      MSGIDSM = 'MHA0109'                          * Message ID
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   Eval      HOSTMD = pCtlHost                            * Host name
     C                   Eval      IPADMD = IPAddr                              * IP Address
     C                   Eval      PORTMD = PrtNum                              * Port number
     C                   ExSR      SRSNDPM
     C                   Eval      RtnTCP = CloTCP(CliSkt)
     C                   EndIf
      *
     C                   Return

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
      * Get the number for the service name
     C                   Eval      PrtNum = GetPort(pSrvNme)
     C     PrtNum        IfEQ      -1                                           * Not retrieved
      * Send diag message "Service table entry not found"
     C                   Eval      MSGIDSM = 'MHA0101'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      SRVNMD = pSrvNme                             * Service name
     C                   ExSR      SRSNDPM
     C                   Eval      Error = *ON                                  * Error
     C                   Eval      RtnCde = 'MHA0101'                           * Port not retrieved
     C                   EndIf                                                  * Port retrieved

      * Get the IP address of the controlling system
     C     Error         IfEQ      *OFF
     C                   Eval      IPAddr = GetHostIP(pCtlHost)
     C                   If        IPAddr = ' '
     C                   Eval      Error = *ON                                  * Error
      * Send info message "Error retrieving host information.'
     C                   Eval      MSGIDSM = 'MHA0105'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      HOSTMD = pCtlHost                            * Host name
     C                   ExSR      SRSNDPM
     C                   Eval      Error = *ON                                  * Error
     C                   Eval      RtnCde = 'MHA0105'                           * Host not retrieved
     C                   EndIf
     C                   EndIf
      * If error during initialisation, make sure init subroutine is called next time
     C                   If        Error
     C                   SetOn                                        LR
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSNDPM - Send program message                                      *
      * ------------------------------------------------------------------- *
     C     SRSNDPM       BegSR
      * Determine message file value for QMHSNDPM API
     C     MSGFSM        IfEQ      *Blanks
     C                   MoveL     #MSGF         MSGFSM                         * Default msgf
     C                   EndIf
      * Set default message type
     C     MSGTYPSM      IfEQ      *Blanks                                      * Message type
     C                   MoveL     #DIAG         MSGTYPSM                       * Message type
     C                   EndIf
      * Determine stack entry/counter value, based on message type
     C                   SelecT
     C     STCENTSM      WhenNE    *Blanks                                      * Stack entry
     C     MSGTYPSM      WhenEQ    #STATUS                                      * Status message
     C                   MoveL(P)  #EXT          STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C     MSGTYPSM      WhenEQ    #INFO                                        * Status message
     C                   MoveL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-Add     1             STCCTRSM                       * Stack counter
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

      * ------------------------------------------------------------------- *
      * SRRtvMsg - Retrieve message description                             *
      * ------------------------------------------------------------------- *
     C     SRRtvMsg      BegSR
      * Determine message file value for QMHRTVM API
     C                   If        %subst(MSGIDRM:1:3) = 'DMK'
     C                   MoveL     #DMKMSGF      MSGFRM                         * Message file
     C                   Else
     C                   MoveL     #HAMSGF       MSGFRM                         * Message file
     C                   EndIf
     C                   Z-ADD     8             BPVDAE                         * Bytes provide
      * Retrieve program message
     C                   Call      'QMHRTVM'     pRTVMD                         * Retrieve message
      * If errors in the API --> Clear retrieve data structure
     C     BAVLAE        IfNe      0                                            * Errors
     C                   Clear                   RTVM0200
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSndSkt - Send socket to controlling system                        *
      * ------------------------------------------------------------------- *
     C     SRSndSkt      BegSR
      * If socket not open --> Open now
     C     SktOpn        IfEQ      *Off                                         * Socket open?
     C                   Eval      CliSkt = OpnTCP
     C                   If        CliSkt = -1
     C     'Open Failed' Dsply
     C                   Eval      Error = *On                                  * Error
     C                   EndIf
      * Connect to the remote socket
     C     Error         IfEQ      *Off
      * Send info message "Connecting to host ...'
     C                   Eval      MSGIDSM = 'MHA0106'                          * Message ID
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   Eval      HOSTMD = pCtlHost                            * Host name
     C                   Eval      IPADMD = IPAddr                              * IP Address
     C                   Eval      PORTMD = PrtNum                              * Port number
     C                   ExSR      SRSNDPM
     C                   Eval      RtnTCP = CnnTCP(CliSkt: IPAddr: 15: PrtNum)
     C                   If        RtnTCP = -1
     C                   Eval      Error = *On                                  * Error
      * Send info message "Cannot connect to host.'
     C                   Eval      MSGIDSM = 'MHA0107'                          * Message ID
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      HOSTMD = pCtlHost                            * Host name
     C                   Eval      IPADMD = IPAddr                              * IP Address
     C                   Eval      PORTMD = PrtNum                              * Port number
     C                   ExSR      SRSNDPM
     C                   EndIf                                                  * RtnTCP = -1
     C                   EndIf                                                  * No previous error
      * If no error --> socket is now open
     C                   If        not Error                                    * No error
     C                   Eval      SktOpn = *On                                 * Socket open!
     C                   EndIf                                                  * No error
     C                   EndIf                                                  * Socket open?

      * If no errors in opening socket, send socket
     C                   If        SktOpn                                       * No error
      * Send info message "Sending request ...'
     C                   MoveL     'MHA0108'     MSGIDSM                        * Message ID
     C                   MoveL     #INFO         MSGTYPSM                       * Message type
     C                   MoveL     OrgSys        ORGSMD                         * Original system
     C                   MoveL     Action        ACTMD                          * Action
     C                   MoveL     MSGID         MSGIDMD                        * Message ID
     C                   MoveL     pCtlSys       CTLSMD                         * Controlling system
     C                   MoveL     MsgGrpNam     GRPNMD                         * Group name
     C                   ExSR      SRSNDPM
      * Send string
     C                   Eval      RtnTCP = SndTCP(CliSkt:ExcStr)
     C                   If        RtnTCP = -1
     C     'Snd Failed'  Dsply
     C                   Eval      Error = *ON                                  * Error
     C                   EndIf
      * Wait for confirmation from remote system
     C     Error         IfEQ      *OFF                                         * No errors
     C                   Eval      RtnTCP = RcvTCP(CliSkt:CnfStr)
     C                   If        RtnTCP = -1
     C     'No confirm'  Dsply
     C                   Eval      Error = *ON                                  * Error
     C                   EndIf
      * If listener requested end --> end loop
     C     ActCnf        IfEQ      #END                                         * End requested
     C                   Move      *On           MsgEnd                         * Message end
     C                   EndIf
     C                   EndIf
     C                   EndIf                                                  * No error
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRLstGrp - Populate HMONHAG file based on HLSTCFGG                  *
      * ------------------------------------------------------------------- *
     C     SRLstGrp      BegSR
     C     *Loval        SetLL     LSTCFGG@
     C                   Read      LSTCFGG@                               95
     C                   DoW       not *In95
      * Populate detail fields of HMONHAG
     C                   Eval      MGORGSYS=pOrgSys                             * Originating system
     C                   Eval      MGGRPNAM=LGGRPN                              * Group name
     C                   Eval      MGCURSTS=*Blanks                             * Current status
     C                   Eval      MGCURDTS=CurDTS                              * Current date-time
     C                   Eval      MGPRVSTS=*Blanks                             * Previous status
     C                   Eval      MGALRSNT=*Blanks                             * Alert sent
     C                   Eval      MGRTVDTS=CurDTS                              * Retrieve date-time
     C                   Write     HMONHAGR
     C                   Read      LSTCFGG@                               95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
