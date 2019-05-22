      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONHAL1A       *PGM                              *
      *            Read event log messages and suspended objects     *
      *            from HMONHAE & HMONHAS and send to specified      *
      *            destinations.                                     *
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
      * 20041112 FK  Initial delivery                                *
      * 20050104 FK  Get date in DOS format for e-mail header        *
      * 20050102 FK  Character set & Content variable                *
      * 20060419 FK  Group status                                    *
      * 20070522 FK  Allow for 50 e-mail addresses                   *
      * 20070724 FK  Target and group not displayed for MHA0057      *
      * 20070808 FK  QtmmSendMail reports own error if failing       *
      *              Changed usage of APIErr data structure          *
      * 20111220 FK  Remove HA                                       *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HActGrp(*Caller) BndDir('HMONHA')

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Defined destinations for alert
     FHMONALRU  IF   E           K DISK
      * Messages received from remote system
     FHMONHAE   IF   E           K DISK
      * Native suspended objects received from remote system
     FHMONHASN  IF   E           K DISK
      * IFS suspended objects received from remote system
     FHMONHASI  IF   E           K DISK
      * Group status received from remote system
     FHMONHAG   IF   E           K DISK

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * Open IFS file
     Dopen             PR            10I 0 ExtProc('open')
     D  filename                       *   Value
     D  openflags                    10I 0 Value
     D  mode                         10U 0 Value Options(*NOPASS)
     D  codepage                     10U 0 Value Options(*NOPASS)

      * Read IFS file
     Dread             PR            10I 0 ExtProc('read')
     D  filehandle                   10I 0 Value
     D  datareceived                   *   Value
     D  nbytes                       10U 0 Value

      * Write IFS file
     Dwrite            PR            10I 0 ExtProc('write')
     D  filehandle                   10I 0 Value
     D  datatowrite                    *   Value
     D  nbytes                       10U 0 Value

      * Close IFS file
     Dclose            PR            10I 0 ExtProc('close')
     D  filehandle                   10I 0 Value

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * List of message queues
     D LstMsgQ         DS           202
     D  NbrMsgQ                       4B 0                                      * # of Msg queues
     D  ArrMsgQ                      20    Dim(10)                              * Message queues

      * List of e-mail addresses
     D LstEML          DS          5002
     D  NbrEML                        4B 0                                      * # of addresses
     D  ArrEML                      100    Dim(50)                              * e-Mail addresse

      * RTVM0200 - Retrieve message description data structure
     D RTVM0200        DS         10000
     D  BPVDRM                 1      4B 0                                      * Bytes provided
     D  BAVLRM                 5      8B 0                                      * Bytes available
     D  MSGSEVRM               9     12B 0                                      * Message severity
     D  ALRIDXRM              13     16B 0                                      * Alert index
     D  ALROPTRM              17     25                                         * Alert option
     D  LOGINDRM              26     26                                         * Log indicator
     D  LRRTNRM               29     32B 0                                      * Length reply retur
     D  LRAVLRM               33     36B 0                                      * Length reply avl
     D  LMRTNRM               37     40B 0                                      * Length msg return
     D  LMAVLRM               41     44B 0                                      * Length msg avail
     D  LHRTNRM               45     48B 0                                      * Length help return
     D  LHAVLRM               49     52B 0                                      * Length help avail
     D  MSGVARRM              53  10000                                         * Variable RTVM0200

      * ADDT0100 - Recipient address data structure
     D ADDT0100        DS
     D  OffsetRA               1      4B 0                                      * Offset to next str
     D  AdrLenRA               5      8B 0                                      * SMTP address len
     D  AdrFmtRA               9     16                                         * Address format
     D  DstTypRA              17     20B 0                                      * Distr. type
     D  Rsv01RA               21     24B 0                                      * Reserved
     D  SMTPAdrRA             25    124                                         * SMTP Address

      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data

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

      * Message data
     D MSGDTA          DS          1024
      * Message data for MHA0013
     D  CURUMD                 1     10                                         * Current user
      * Message data for MHA0014 (additional)
     D  SNDRMD                11    110                                         * Sender address
     D  SNDNMD               111    160                                         * Sender name
     D  CHRMD                161    190                                         * Character set
     D  CTEMD                191    220                                         * Content Transfer E
      * Message data for MHA0015
     D  RCPAMD                 1    100                                         * Recipient address
      * General message data for MHA0051, MHA0052 & MHA0053 & MHA0054 & MHA0056
     D  PRDMD                  1      3                                         * Product
     D  ORGSMD                 4     11                                         * Originating system
      * Additional message data for MHA0051 & MHA0052 & MHA0056
     D  NBREMD                12     15B 0                                      * # of errors
      * Additional message data for MHA0053 & MHA0054 & MHA0057
     D  Filler01              12     21                                         * Target name
     D  GRPNMD                22     31                                         * Group name
      * Additional message data for MHA0053 & MHA0054
     D  RSNCMD                32     34                                         * Reason code
     D  SUSDMD                35     53                                         * Suspend date/time
      * Additional message data for MHA0053
     D  OBJNMD                54     63                                         * Object name
     D  OBJLMD                64     73                                         * Object library
     D  OBJTMD                74     83                                         * Object type
     D  OBJMMD                84     93                                         * Member name
      * Additional message data for MHA0054
     D  IFSTMD                54     63                                         * IFS type
     D  IFSPMD                64    543                                         * IFS path
      * Additional message data for MHA0057
     D  CURSMD                32     41                                         * Current status
     D  PRVSMD                42     51                                         * Current status
     D  STSDMD                52     70                                         * Status date-time
      * Message data for message MHA0055 (Error when sending e-mail)
     D  SDRAMD                 1    256                                         * Sender address
     D  MSGIMD               257    263                                         * MSGID of error

      * ------------------------------------------------------------ *
      * Constants                                                    *
      * ------------------------------------------------------------ *
     D #YES            C                   CONST('*YES')
     D #TypMSGQ        C                   CONST('*MSGQ')
     D #TypEML         C                   CONST('*EMAIL')
     D #EVT            C                   CONST('*EVT')
     D #SUS            C                   CONST('*SUS')
     D #GRP            C                   CONST('*GRP')
     D #HMONHA         C                   CONST('HMONHA    ')
     D #ALL            C                   CONST('*ALL      ')
      * Message values
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #DMKMSGF        C                   CONST('DMKMSGF   *LIBL     ')
     D #HAMSGF         C                   CONST('HAMSGF    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

      * Constants for MIME file handling
     D #MIMEEvt        C                   Const('/tmp/hmonhaevt.txt')
     D #MIMESus        C                   Const('/tmp/hmonhasus.txt')
     D #MIMEGrp        C                   Const('/tmp/hmonhagrp.txt')
     D #MIMEBound      C                   Const('--BOUNDARY.HMONHA.BOUNDARY')
     D #CRLF           C                   Const(X'0D25')
     D #Null           C                   Const(X'00')
     D #USASCII        C                   CONST('us-ascii')                    * us-ascii
     D #7BIT           C                   CONST('7bit')                        * 7-bit encoding

      * File Open flags
     D #O_CREAT        S             10I 0 Inz(8)                               * Open with Create
     D #O_EXCL         S             10I 0 Inz(16)                              * Open Exclusive
     D #O_TRUNC        S             10I 0 Inz(64)                              * Open Truncate
     D #O_CODEPAGE     S             10I 0 Inz(8388608)                         * Set Code page
     D #O_TEXTDATA     S             10I 0 Inz(16777216)                        * Open as Text file
      * File access modes
     D #O_RDONLY       S             10I 0 Inz(1)                               * Read-Only
     D #O_WRONLY       S             10I 0 Inz(2)                               * Write-Only
     D #O_RDWR         S             10I 0 Inz(4)                               * Read-Write
      * File Status flags
     D #O_NONBLOCK     S             10I 0 Inz(128)                             * Status Non-block
     D #O_APPEND       S             10I 0 Inz(256)                             * Status Append
      * Share modes
     D #O_SHARE_NONE   S             10I 0 Inz(2000000)                         * Share None
     D#O_SHARE_RDONLY  S             10I 0 Inz(0200000)                         * Share Read-Only
     D #O_SHARE_RDWR   S             10I 0 Inz(1000000)                         * Share Read-Write
     D#O_SHARE_WRONLY  S             10I 0 Inz(0400000)                         * Share Write-Only
      * File permissions (mode)
     D #S_IRUSR        S             10I 0 Inz(256)                             * User Read
     D #S_IWUSR        S             10I 0 Inz(128)                             * User Write
     D #S_IXUSR        S             10I 0 Inz(64)                              * User Execute
     D #S_IRWXU        S             10I 0 Inz(448)                             * User RWX
     D #S_IRGRP        S             10I 0 Inz(32)                              * Group Read
     D #S_IWGRP        S             10I 0 Inz(16)                              * Group Write
     D #S_IXGRP        S             10I 0 Inz(8)                               * Group Execute
     D #S_IRWXG        S             10I 0 Inz(56)                              * Group RWX
     D #S_IROTH        S             10I 0 Inz(4)                               * Other Read
     D #S_IWOTH        S             10I 0 Inz(2)                               * Other Write
     D #S_IXOTH        S             10I 0 Inz(1)                               * Other Execute
     D #S_IRWXO        S             10I 0 Inz(7)                               * Other RWX
      * Miscellaneous
     D #CP_ASCII       S             10I 0 Inz(819)                             * US-ASCII

      * Date conversion tables
     D #Month          S              3    Dim(12) PerRcd(12) CTData            * Months of the year
     D #DOW            S              3    Dim(7) PerRcd(7) CTData              * Days of Week

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *

      * API parameter values
     D MSGDTLSM        S              9B 0                                      * Message data lengt
     D STCCTRSM        S              9B 0                                      * Stack counter
     D INFLRM          S              9B 0                                      * Information length
     D NBRMQSM         S              9B 0                                      * Number of MSGQ

      * Miscellaneous
     D Error           S               N                                        * Error occurred

     D i               S              3  0                                      * Index
     D j               S              3  0                                      * Index
     D Pos             S              5  0                                      * Starting position
     D Len             S              5  0                                      * Length of string
     D Spc             S              3  0 Dim(256)                             * Spaces
     D MsgLin          S             80    Dim(10)                              * Broken-up message
     D PthLin          S             60    Dim(10)                              * Broken-up path
     D Msg1stRM        S            256                                         * First level Msg
     D Msg2ndRM        S           5000                                         * Second level Msg
     D DTS             S               Z                                        * Date-time stamp
     D DTS@            S             26                                         * Date-time stamp
     D DTSSub          S             19                                         * Substring DTS

     D IFSFile         S            255A                                        * IFS File name
     D IFSFileLen      S              9B 0                                      * IFS File name len
     D IFSFileHnd      S             10I 0                                      * IFS File handle
     D IFSLine         S           1000                                         * Line in MIME file
     D IFSBytWrt       S             10I 0                                      * IFS bytes written
     D IFSRtnVal       S             10I 0                                      * General return val

     D ArrADDT         S            124A   Dim(10)                              * Array of ADDT0100
     D SdrAddr         S            256A                                        * Sender Address
     D SdrName         S             50A                                        * Sender Name
     D SMTPOrg         S            256a                                        * Originator SMTP
     D SMTPOrgLen      S              9B 0                                      * Orig. SMTP length
     D SMTPNbrAdr      S              9B 0                                      * # of Recipients
     D FstLin          S               N                                        * First line
     D MsgSev          S              2  0                                      * Message severity
     D MsgSev@         S              2A                                        * Message severity

     D DOSDay@         S              2                                         * Day
     D DOSYear@        S              4                                         * Year
     D DOSHrs@         S              2                                         * Hour
     D DOSMin@         S              2                                         * Minute
     D DOSSec@         S              2                                         * Seconds
     D DOSTimZon@      S              5                                         * Time zone
     D TimZon          S              4  0                                      * Time zone (abs)
     D TimZonHrs       S              2  0                                      * Time hours
     D TimZonHrs@      S              2                                         * Time hours char
     D TimZonMin       S              2  0                                      * Time minutes
     D TimZonMin@      S              2                                         * Time minutes char
     D CharDTS         S             80a                                        * Character date
     D EMLChr          S             30a                                        * Character set
     D EMLCTE          S             30a                                        * Content Transfer E

      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
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
     C                   Parm                    APIErr                         * API Error
      * QMHSNDM - Send nonprogram message
     C     pSNDM         PList
     C                   Parm                    MSGIDSM           7            * Message ID
     C                   Parm                    MSGFSM           20            * Message file
     C                   Parm                    MSGDTA                         * Message data
     C                   Parm                    MSGDTLSM                       * Message data lengt
     C                   Parm                    MSGTYPSM         10            * Message type
     C                   Parm                    MSGQSM           20            * Qualified MSGQ
     C                   Parm      1             NBRMQSM                        * Number of MSGQ
     C                   Parm      *Blanks       RPYQSM           20            * Reply MSGQ
     C                   Parm                    MSGKEYSM          4            * Message key
     C                   Parm                    APIErr                         * API Error
      * QMHRTVM - Retrieve message description
     C     pRTVMD        PList
     C                   Parm                    RTVM0200                       * RTVM0200 format
     C                   Parm      5000          INFLRM                         * Info length
     C                   Parm      'RTVM0200'    FMTNRM            8            * Format name
     C                   Parm                    MSGIDRM           7            * Message ID
     C                   Parm                    MSGFRM           20            * Message file
     C                   Parm                    MSGDTA                         * Message data
     C                   Parm                    MSGDTLSM                       * Message data lengt
     C                   Parm      '*YES'        RPLSRM           10            * Replace subst. var
     C                   Parm      '*NO'         RTNFRM           10            * Return Fmt ctl chr
     C                   Parm                    APIErr                         * API Error
      * Entry parameters
     C     *Entry        Plist
     C                   Parm                    pPrd              3            * Product
     C                   Parm                    pCurUsr          10            * Current user
     C                   Parm                    pOrgSys           8            * Originating system
     C                   Parm                    pMsgOrg           1            * Message Origin
     C                   Parm                    pAction           4            * Action
     C                   Parm                    pNbrErr           5 0          * # of errors
     C                   Parm                    pRtnCde           7            * Return code

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Initialisation
     C                   Eval      pRtnCde = *Blanks                            * Return code

     C                   If        pPrd<>'***'                                  * Initialise
      * If e-mail must be sent, create MIME file and write header
     C                   If        NbrEML > 0                                   * E-Mail to be sent
     C                   ExSR      SRWrtEMHdr                                   * Write e-Mail hdr
     C                   EndIf

     C                   Select
      * Process all events for originating system
     C                   When      pAction = #EVT                               * Events?
     C                   Eval      FstLin = *On                                 * First line
     C     pOrgSys       SetLL     HMONHAER
     C     pOrgSys       ReadE     HMONHAER                               95
     C                   DoW       not *In95
      * If e-mail must be sent, add to MIME file
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtMsg                                     * Write e-Mail dtl
     C                   EndIf
      * If message must be sent, send it
     C                   If        NbrMsgQ > 0                                  * Message queue
     C                   ExSR      SRSndMsg                                     * Send message
     C                   EndIf

     C     pOrgSys       ReadE     HMONHAER                               95
     C                   EndDo
      * If E-Mail, write separator
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtSep                                     * Write separator
     C                   EndIf

      * Process all suspends for originating system
     C                   When      pAction = #SUS                               * Suspends
      * Process all native suspended objects
     C                   Eval      FstLin = *On                                 * First line
     C     pOrgSys       SetLL     HMONHASNR
     C     pOrgSys       ReadE     HMONHASNR                              95
     C     *In95         DowEQ     *Off
      * If e-mail must be sent, add to MIME file
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtSusNtv                                  * Write suspended
     C                   EndIf
      * If message must be sent, send it
     C                   If        NbrMsgQ > 0                                  * Message queue
     C                   ExSR      SRSndMsgNtv                                  * Send suspend msg
     C                   EndIf

     C     pOrgSys       ReadE     HMONHASNR                              95
     C                   EndDo
      * If E-Mail, write separator
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtSep                                     * Write separator
     C                   EndIf

      * Process all IFS suspended objects
     C                   Eval      FstLin = *On                                 * First line
     C     pOrgSys       SetLL     HMONHASIR
     C     pOrgSys       ReadE     HMONHASIR                              95
     C     *In95         DowEQ     *Off
      * If e-mail must be sent, add to MIME file
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtSusIFS                                  * Write suspended
     C                   EndIf
      * If message must be sent, send it
     C                   If        NbrMsgQ > 0                                  * Message queue
     C                   ExSR      SRSndMsgIFS                                  * Send suspend msg
     C                   EndIf

     C     pOrgSys       ReadE     HMONHASIR                              95
     C                   EndDo
      * If E-Mail, write separator
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtSep                                     * Write separator
     C                   EndIf

      * Process all group statuses for originating system
     C                   When      pAction = #GRP                               * Group status?
     C                   Eval      FstLin = *On                                 * First line
     C     pOrgSys       SetLL     HMONHAGR
     C     pOrgSys       ReadE     HMONHAGR                               95
     C                   DoW       not *In95
      * If e-mail must be sent, add to MIME file
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtGrp
     C                   EndIf
      * If message must be sent, send it
     C                   If        NbrMsgQ > 0                                  * Message queue
     C                   ExSR      SRSndMsgGrp                                  * Send message
     C                   EndIf

     C     pOrgSys       ReadE     HMONHAGR                               95
     C                   EndDo
      * If E-Mail, write separator
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtSep                                     * Write separator
     C                   EndIf

     C                   EndSL

      * If e-mail must be sent, write MIME footer and close file
     C                   If        NbrEML > 0                                   * E-Mail
     C                   ExSR      SRWrtEMFtr                                   * Write footer & snd
     C                   EndIf
     C                   EndIf                                                  * Initialise

     C                   Return

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
      * Initialisation
     C                   Eval      Error = *Off                                 * No Error
      * Initialise arrays with destinations
     C                   Clear                   LstMSGQ                        * List of MSGQ
     C                   Clear                   LstEML                         * List of E-Mail
      * First read HMONHA specific alert destinations
     C     #HMONHA       SetLL     HMONALRUR
     C     #HMONHA       ReadE     HMONALRUR                              95
     C                   DoW       not *In95
     C                   Select
     C                   When      ALDSTTYP = #TypMSGQ                          * *MSGQ
     C                             and NbrMSGQ < %elem(ArrMSGQ)
     C                   Eval      NbrMSGQ = NbrMSGQ + 1
     C                   Eval      ArrMSGQ(NbrMSGQ) = ALALRDST                  * Alert destination
     C                   When      ALDSTTYP = #TypEML                           * *EMAIL
     C                             and NbrEML < %elem(ArrEML)
     C                   Eval      NbrEML = NbrEML + 1
     C                   Eval      ArrEML(NbrEML) = ALALRDST                    * Alert destination
      * Fill character set and content transfer encoding
     C                   If        EMLChr=*Blanks                               * Not filled yet
     C                   Eval      EMLChr=ALEMLCHR                              * Character set
     C                   EndIf
     C                   If        EMLCTE=*Blanks                               * Not filled yet
     C                   Eval      EMLCTE=ALEMLCTE                              * Content Transfer E
     C                   EndIf
     C                   EndSL
     C     #HMONHA       ReadE     HMONALRUR                              95
     C                   EndDo
      * Then read *ALL alert destinations
     C     #ALL          SetLL     HMONALRUR
     C     #ALL          ReadE     HMONALRUR                              95
     C                   DoW       not *In95
     C                   Select
     C                   When      ALDSTTYP = #TypMSGQ                          * *MSGQ
     C                             and NbrMSGQ < %elem(ArrMSGQ)
     C                   Eval      NbrMSGQ = NbrMSGQ + 1
     C                   Eval      ArrMSGQ(NbrMSGQ) = ALALRDST                  * Alert destination
     C                   When      ALDSTTYP = #TypEML                           * *EMAIL
     C                             and NbrEML < %elem(ArrEML)
     C                   Eval      NbrEML = NbrEML + 1
     C                   Eval      ArrEML(NbrEML) = ALALRDST                    * Alert destination
      * Fill character set and content transfer encoding
     C                   If        EMLChr=*Blanks                               * Not filled yet
     C                   Eval      EMLChr=ALEMLCHR                              * Character set
     C                   EndIf
     C                   If        EMLCTE=*Blanks                               * Not filled yet
     C                   Eval      EMLCTE=ALEMLCTE                              * Content Transfer E
     C                   EndIf
     C                   EndSL
     C     #ALL          ReadE     HMONALRUR                              95
     C                   EndDo
      * If any e-mail address, retrieve sender e-mail address and fill recipients data structure
     C                   If        NbrEML > 0                                   * E-Mail?
      * Retieve sender address
     C                   Call      'HMONHAL1B'
     C                   Parm                    pCurUsr                        * Current user
     C                   Parm                    SdrAddr                        * Sender address
     C                   Parm                    SdrName                        * Sender name
      * If SMTP address not found for user --> Error
     C                   If        SdrAddr = *Blanks                            * No Sender address
      * Send error in job log and return error
     C                   MoveL     'MHA0013'     MSGIDSM                        * Message ID
     C                   Eval      CURUMD = pCurUsr                             * Current user
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   ExSR      SRSNDPM
     C                   Eval      Error = *On                                  * Error
     C                   Eval      pRtnCde = 'MHA0013'                          * Return code
     C                   Else                                                   * Sender address fd
     C                   If        SdrName = *Blanks                            * No Sender name
     C                   Eval      SdrName = pCurUsr                            * Current user
     C                   EndIf                                                  * No Sender name
      * Issue information message in job log
     C                   MoveL     'MHA0014'     MSGIDSM                        * Message ID
     C                   Eval      CURUMD = pCurUsr                             * Current user
     C                   Eval      SNDRMD = SdrAddr                             * Sender address
     C                   Eval      SNDNMD = SdrName                             * Sender name
     C                   Eval      CHRMD = EMLChr                               * Character set
     C                   Eval      CTEMD = EMLCTE                               * Content Transfer E
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   ExSR      SRSNDPM
     C                   EndIf                                                  * No Sender address
      * Fill recipients data structure
     C                   If        not Error                                    * No error found
     C                   Clear                   ArrADDT                        * Recipient array
     C                   Eval      i = 1                                        * Index
     C                   DoW       i <= NbrEML                                  * Number of e-mail
     C                   Clear                   ADDT0100                       * Data structure
     C                   If        i < NbrEML                                   * Not last element
     C                   Eval      OffSetRA = 124                               * Next structure
     C                   Else
     C                   Eval      OffSetRA = 0                                 * Next structure
     C                   EndIf
     C                   Eval      AdrFmtRA = 'ADDT0100'                        * Structure format
     C                   Eval      SMTPAdrRA = ArrEML(i)                        * SMTP Address
     C                   Eval      AdrLenRA = %Len(%TrimR(SMTPAdrRA))           * SMTP Address len
     C                   Eval      DstTypRA = 0                                 * Distribution type
     C                   Eval      ArrADDT(i) = ADDT0100
      * Send informational message to indicate recipient
     C                   MoveL     'MHA0015'     MSGIDSM                        * Message ID
     C                   Eval      RCPAMD = ArrEML(i)                           * Recipient address
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   ExSR      SRSNDPM
     C                   Eval      i = i + 1                                    * Index
     C                   EndDo                                                  * Number of e-mail
     C                   EndIf                                                  * No error found
     C                   EndIf                                                  * E-Mail?
      * If error occurred during initalisation, return
     C                   If        Error                                        * Error occurred
     C                   SetOn                                        LR
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSndMsg - Send message to message queues                           *
      * ------------------------------------------------------------------- *
     C     SRSndMsg      BegSR
      * Send messages to message queues
     C                   Eval      MSGIDSM = MEMSGID                            * Message ID
     C                   Eval      MSGDTA = MEMSGDTA                            * Message data
     C                   Eval      MSGDTLSM = %Len(MEMSGDTA)                    * Message data lengt
     C                   Eval      i=1
     C                   DoW       i <= NbrMSGQ                                 * # of MSGQs
     C                   Eval      MSGFSM = MEMSGF + '*LIBL     '
     C                   Eval      MSGQSM = ArrMsgQ(i)                          * Message queue
     C                   ExSR      SRSNDM                                       * Send nonprogram ms
     C                   Eval      i=i+1
     C                   EndDo

     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSndMsgNtv - Send native suspended object to message queues        *
      * ------------------------------------------------------------------- *
     C     SRSndMsgNtv   BegSR
      * Send messages to message queues
     C                   Eval      MSGIDSM = 'MHA0053'                          * Message ID
     C                   Eval      PRDMD = pPrd                                 * Product
     C                   Eval      ORGSMD = MSORGSYS                            * Originating system
     C                   Eval      GRPNMD = MSGRPNAM                            * Group name
     C                   Eval      RSNCMD = MSRSNCDE                            * Reason code
     C                   MoveL     MSSUSDTS      DTS@                           * Suspend date/time
     C                   Eval      SUSDMD = %Subst(DTS@:1:19)                   * Suspend date/time
     C                   Eval      OBJNMD = MSOBJNAM                            * Object name
     C                   Eval      OBJLMD = MSOBJLIB                            * Library name
     C                   Eval      OBJTMD = MSOBJTYP                            * Object type
     C                   Eval      OBJMMD = MSOBJMBR                            * Object member
     C                   Eval      MSGFSM = #HAUMSGF
     C                   Eval      MSGDTLSM = 100                               * Message data lengt
     C                   Eval      i=1
     C                   DoW       i <= NbrMSGQ                                 * # of MSGQs
     C                   Eval      MSGQSM = ArrMsgQ(i)                          * Message queue
     C                   ExSR      SRSNDM                                       * Send nonprogram ms
     C                   Eval      i=i+1
     C                   EndDo

     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSndMsgIFS - Send IFS suspended object to message queues           *
      * ------------------------------------------------------------------- *
     C     SRSndMsgIFS   BegSR
      * Send messages to message queues
     C                   Eval      MSGIDSM = 'MHA0054'                          * Message ID
     C                   Eval      PRDMD = pPrd                                 * Product
     C                   Eval      ORGSMD = MSORGSYS                            * Originating system
     C                   Eval      GRPNMD = MSGRPNAM                            * Group name
     C                   Eval      RSNCMD = MSRSNCDE                            * Reason code
     C                   MoveL     MSSUSDTS      DTS@                           * Suspend date/time
     C                   Eval      SUSDMD = %Subst(DTS@:1:19)                   * Suspend date/time
     C                   Eval      IFSTMD = MSIFSTYP                            * IFS object type
     C                   Eval      IFSPMD = MSIFSPTH                            * IFS path
     C                   Eval      MSGFSM = #HAUMSGF
     C                   Eval      MSGDTLSM = 600                               * Message data lengt
     C                   Eval      i=1
     C                   DoW       i <= NbrMSGQ                                 * # of MSGQs
     C                   Eval      MSGQSM = ArrMsgQ(i)                          * Message queue
     C                   ExSR      SRSNDM                                       * Send nonprogram ms
     C                   Eval      i=i+1
     C                   EndDo

     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSndMsgGrp - Send group status to message queues                   *
      * ------------------------------------------------------------------- *
     C     SRSndMsgGrp   BegSR
      * Send group status to message queues
     C                   Eval      MSGIDSM = 'MHA0057'                          * Message ID
     C                   Eval      PRDMD = pPrd                                 * Product
     C                   Eval      ORGSMD = MGORGSYS                            * Originating system
     C                   Eval      GRPNMD = MGGRPNAM                            * Group name
     C                   Eval      CURSMD = MGCURSTS                            * Current status
     C                   MoveL     MGCURDTS      DTS@                           * Status date-time
     C                   Eval      STSDMD = %Subst(DTS@:1:19)                   * Status date-time
     C                   Eval      PRVSMD = MGPRVSTS                            * Previous status
     C                   Eval      MSGFSM = #HAUMSGF
     C                   Eval      MSGDTLSM = 100                               * Message data lengt
     C                   Eval      i=1
     C                   DoW       i <= NbrMSGQ                                 * # of MSGQs
     C                   Eval      MSGQSM = ArrMsgQ(i)                          * Message queue
     C                   ExSR      SRSNDM                                       * Send nonprogram ms
     C                   Eval      i=i+1
     C                   EndDo

     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtEMHdr - Write header in MIME file                              *
      * ------------------------------------------------------------------- *
     C     SRWrtEMHdr    BegSR
      * Create the MIME file
     C                   Select
     C                   When      pAction = #EVT                               * Events?
     C                   Eval      IFSFile = %TrimR(#MIMEEvt) + #Null
     C                   When      pAction = #SUS                               * Suspends?
     C                   Eval      IFSFile = %TrimR(#MIMESus) + #Null
     C                   When      pAction = #GRP                               * Events?
     C                   Eval      IFSFile = %TrimR(#MIMEGrp) + #Null
     C                   EndSL
     C                   Eval      IFSFileHnd = open(%Addr(IFSFile)
     C                               : #O_CREAT + #O_WRONLY +
     C                                 #O_TRUNC + #O_CODEPAGE
     C                               : #S_IRWXU + #S_IROTH
     C                               : #CP_ASCII)
     C                   Eval      IFSRtnVal = close(IFSFileHnd)
     C                   Eval      IFSFileHnd = open(%Addr(IFSFile)
     C                               : #O_TEXTDATA + #O_RDWR)
      * Build MIME header fields
     C                   Eval      IFSLine = 'Sender: ' + SdrAddr + #CRLF
     C                   ExSR      SRWrtLin
      * Build date and write string
     C                   ExSR      SRBldDte                                     * Build date string
     C                   Eval      IFSLine = 'Date: ' + %TrimR(CharDTS) + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine = 'From: ' + %TrimR(SdrName) +
     C                             ' <' + %TrimR(SdrAddr) + '>' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine = 'MIME-Version: 1.0' + #CRLF
     C                   ExSR      SRWrtLin
      * Add Addressee e-mail addresses
     C                   Eval      IFSLine = 'To:'
     C                   Z-Add     1             i                              * Index
     C     i             DowLE     NbrEML
     C                   Eval      IFSLine = %TrimR(IFSLine) + ' ' +
     C                             ArrEML(i)
      * If not last addressee --> Add comma for next address
     C                   If        i <= NbrEML-1
     C                   Eval      IFSLine = %TrimR(IFSLine) + ','
     C                   EndIf
     C                   Eval      IFSLine = %TrimR(IFSLine) + #CRLF
     C                   ExSR      SRWrtLin
     C                   Add       1             i                              * Index
     C                   EndDo
      * Add Subject to header (dependent on type)
     C                   Select
     C                   When      pAction = #EVT                               * Events?
     C                   Eval      MSGIDRM = 'MHA0051'                          * Message ID
     C                   When      pAction = #SUS                               * Suspends?
     C                   Eval      MSGIDRM = 'MHA0052'                          * Message ID
     C                   When      pAction = #GRP                               * Group status?
     C                   Eval      MSGIDRM = 'MHA0056'                          * Message ID
     C                   EndSL
     C                   Eval      MSGFRM = #HAUMSGF                            * Message file
     C                   Eval      PRDMD = pPrd                                 * Product
     C                   Eval      ORGSMD = pOrgSys                             * Originating system
     C                   Eval      NBREMD = pNbrErr                             * # of errors
     C                   Eval      MSGDTLSM = 40                                * Message data lengt
      * Retrieve message description
     C                   ExSR      SRRtvMsg                                     * Retrieve message
      * Compose string
     C                   Eval      IFSLine = 'Subject: ' + %TrimR(Msg1stRM) +
     C                             #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Content-Type: multipart/mixed; boundary=' +
     C                             '"' + #MIMEBound + '"' + #CRLF + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'E-mail from the DMXtras iCluster monitor,' +
     C                             ' HMONHA.'+#CRLF + '--' + #MIMEBound + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Content-Type: text/plain; charset='+EMLChr+
     C                             #CRLF+'Content-Transfer-Encoding:'+EMLCTE+
     C                             #CRLF + #CRLF
     C                   ExSR      SRWrtLin
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtMsg   - Write event message to MIME file                       *
      * ------------------------------------------------------------------- *
     C     SRWrtMsg      BegSR
     C                   If        FstLin = *On                                 * First line
     C                   Eval      FstLin = *Off
     C                   Eval      IFSLine =
     C                             'EVENT LOG MESSAGES:' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '-------------------' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Event date-time     System   Message Sev ' +
     C                             'Description' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '------------------- -------- ------- --- ' +
     C                             '----------------------------------------' +
     C                             '----------------------------------------' +
     C                             #CRLF
     C                   ExSR      SRWrtLin
     C                   EndIf
      * Retrieve message text
     C                   MoveL     MEMSGID       MSGIDRM                        * Message ID
     C                   Eval      MSGFRM = MEMSGF + '*LIBL     '
     C                   Eval      MSGDTA = MEMSGDTA                            * Message data
     C                   Eval      MSGDTLSM = %Len(MEMSGDTA)                    * Message data lengt
      * Retrieve message description
     C                   ExSR      SRRtvMsg                                     * Retrieve message
      * Break 1st message level into strings of maximum 80 characters
     C                   Clear                   Spc                            * Space positions
     C                   Clear                   MsgLin                         * Message lines
     C     ' '           Scan      Msg1stRM      Spc                            * Scan for spaces
     C                   Eval      Len=%Len(%TrimR(Msg1stRM))
     C                   Eval      i=1                                          * MsgLin index
     C                   Eval      j=1                                          * Spc index
     C                   Eval      Pos=1                                        * Position of string
      * Fill strings in MsgLin array
     C                   DoW       i<=5 and Pos <= Len
      * Find next position close to 80 positions
     C                   DoW       j<=256 and Spc(j) <= Len
     C                             and (Spc(j)-Pos <= 80)
     C                   Eval      j=j+1                                        * Spc index
     C                   EndDo
      * Fill current MsgLin array element with string
     C                   Select
     C                   When      Spc(j) > Len and j=1
     C                   Eval      MsgLin(i) = %Subst(Msg1stRM:Pos:             * No spaces
     C                                         80)
     C                   Eval      Pos=81
     C                   When      Spc(j) > Len and (Spc(j)-Pos<=80)
     C                   Eval      MsgLin(i) = %Subst(Msg1stRM:Pos:             * Take remain length
     C                                         Spc(j)-Pos)
     C                   Eval      Pos=Spc(j)
     C                   When      Spc(j-1) - Pos > 80
     C                   Eval      MsgLin(i) = %Subst(Msg1stRM:Pos:80)          * Take 80 first
     C                   Eval      Pos=Pos+80
     C                   Other
     C                   Eval      MsgLin(i) = %Subst(Msg1stRM:Pos:             * Take string length
     C                                         Spc(j-1)-Pos)
     C                   Eval      Pos=Spc(j-1)+1
     C                   EndSL
     C                   Eval      i=i+1                                        * MsgLin index
     C                   EndDo
      * Compose string
     C                   Eval      i=1                                          * MsgLin index
     C                   MoveL     MEMSGDTS      DTS@                           * Message date-time
     C                   Eval      DTSSub = %Subst(DTS@:1:19)                   * Trim microseconds
     C                   Eval      MsgSev=MSGSEVRM                              * Severity
     C                   Move      MsgSev        MsgSev@                        * Severity character
     C                   Eval      IFSLine = DTSSub + ' ' + MEORGSYS +
     C                             ' ' + MEMSGID + ' ' + MsgSev@ + '  ' +
     C                             MsgLin(i) + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      i=i+1                                        * MsgLin index
     C                   DoW       i<=5 and MsgLin(i) <> ' '                    * Not blank
     C                   Eval      IFSLine = '                    ' +
     C                             '         ' + '        ' + '    ' +
     C                             MsgLin(i) + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      i=i+1                                        * MsgLin index
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtSusNtv - Write suspended record (native)                       *
      * ------------------------------------------------------------------- *
     C     SRWrtSusNtv   BegSR
     C                   If        FstLin = *On                                 * First line
     C                   Eval      FstLin = *Off
     C                   Eval      IFSLine =
     C                             'SUSPENDED NATIVE OBJECTS:' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '-------------------------' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Suspend date-time   Group     ' +
     C                             ' Object     Library    Type      ' +
     C                             ' Member     Reason' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '------------------- ----------' +
     C                             ' ---------- ---------- ----------' +
     C                             ' ---------- ------' + #CRLF
     C                   ExSR      SRWrtLin
     C                   EndIf
      * Compose string
     C                   MoveL     MSSUSDTS      DTS@                           * Suspend date-time
     C                   Eval      DTSSub = %Subst(DTS@:1:19)                   * Trim microseconds
     C                   Eval      IFSLine = DTSSub +
     C                             ' ' + MSGRPNAM + ' ' + MSOBJNAM + ' ' +
     C                             MSOBJLIB + ' ' + MSOBJTYP + ' ' + MSOBJMBR +
     C                             ' ' + MSRSNCDE + #CRLF
     C                   ExSR      SRWrtLin
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtSusIFS - Write suspended record (IFS)                          *
      * ------------------------------------------------------------------- *
     C     SRWrtSusIFS   BegSR
     C                   If        FstLin = *On                                 * First line
     C                   Eval      FstLin = *Off
     C                   Eval      IFSLine =
     C                             'SUSPENDED IFS OBJECTS:' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '----------------------' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Suspend date-time   Group     ' +
     C                             ' Reason Type       IFS Object' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '------------------- ----------' +
     C                             ' ------ ---------- --------------------' +
     C                             '----------------------------------------' +
     C                             #CRLF
     C                   ExSR      SRWrtLin
     C                   EndIf
      * Break path name into strings of maximum 60 characters
     C                   Clear                   PthLin                         * Path lines
     C                   Eval      Len=%Len(MSIFSPTH)
     C                   Eval      i=1                                          * PthLin index
     C                   Eval      Pos=1                                        * Position of string
      * Fill strings in PthLin array
     C                   DoW       i<=10 and Pos <= Len
     C                   Select
     C                   When      (Len-Pos+1) > 60                             * Remaining > 60
     C                   Eval      PthLin(i) = %Subst(MSIFSPTH:Pos:60)
     C                   Eval      Pos = Pos+60
     C                   Other
     C                   Eval      PthLin(i) = %Subst(MSIFSPTH:Pos:Len-Pos+1)
     C                   Eval      Pos = Len+1
     C                   EndSL
     C                   Eval      i=i+1                                        * PthLin index
     C                   EndDo
      * Compose string
     C                   Eval      i=1                                          * MsgLin index
     C                   MoveL     MSSUSDTS      DTS@                           * Suspend date-time
     C                   Eval      DTSSub = %Subst(DTS@:1:19)                   * Trim microseconds
     C                   Eval      IFSLine = DTSSub +
     C                             ' ' + MSGRPNAM + ' ' + MSRSNCDE + '    ' +
     C                             MSIFSTYP + ' ' + PthLin(i) + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      i=i+1                                        * PthLin index
     C                   DoW       i<=10 and PthLin(i) <> ' '                   * Not blank
     C                   Eval      IFSLine =
     C                             '                    ' + '           ' +
     C                             '           ' + '       ' + '           ' +
     C                             PthLin(i) + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      i=i+1                                        * PthLin index
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtGrp - Write group status                                       *
      * ------------------------------------------------------------------- *
     C     SRWrtGrp      BegSR
     C                   If        FstLin = *On                                 * First line
     C                   Eval      FstLin = *Off
     C                   Eval      IFSLine =
     C                             'INACTIVE GROUPS:' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '----------------' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Group      Status     ' +
     C                             'Status date-time    Previous     ' +
     C                             ' Member     Reason' + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             '---------- ---------- ' +
     C                             '------------------- ----------' + #CRLF
     C                   ExSR      SRWrtLin
     C                   EndIf
      * Compose string
     C                   MoveL     MGCURDTS      DTS@                           * Current status dat
     C                   Eval      DTSSub = %Subst(DTS@:1:19)                   * Trim microseconds
     C                   Eval      IFSLine = MGGRPNAM + ' ' +
     C                             MGCURSTS + ' ' + DTSSub + ' ' + MGPRVSTS +
     C                             #CRLF
     C                   ExSR      SRWrtLin
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtSep   - Write separator to MIME file                           *
      * ------------------------------------------------------------------- *
     C     SRWrtSep      BegSR
     C                   Eval      IFSLine =
     C                             '========================================' +
     C                             '========================================' +
     C                             '========================================' +
     C                             '==' +
     C                             #CRLF + #CRLF + #CRLF
     C                   ExSR      SRWrtLin
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtEMFtr - Write footer in MIME file                              *
      * ------------------------------------------------------------------- *
     C     SRWrtEMFtr    BegSR
     C                   Eval      IFSLine = #CRLF + #CRLF +
     C                             '--' + #MIMEBound + '--' + #CRLF
     C                   ExSR      SRWrtLin
      * Close the IFS file
     C                   Eval      IFSRtnVal = close(IFSFileHnd)
      * Prepare parameters for QtmmSendMail API
     C                   Eval      IFSFileLen = %Len(%TrimR(IFSFile))           * File name length
     C                   Eval      SMTPOrg = SdrAddr                            * Sender address
     C                   Eval      SMTPOrgLen = %Len(%TrimR(SMTPOrg))           * Originator length
     C                   Eval      SMTPNbrAdr = NbrEML                          * # of Recipients
     C                   Clear                   APIErr                         * API Error
      * Send e-mail
     C                   CallB     'QtmmSendMail'                       99
     C                   Parm                    IFSFile                        * IFS File
     C                   Parm                    IFSFileLen                     * IFS File Length
     C                   Parm                    SMTPOrg                        * Originator
     C                   Parm                    SMTPOrgLen                     * Originator length
     C                   Parm                    ArrADDT                        * Recipients
     C                   Parm                    SMTPNbrAdr                     * # of Recipients
     C                   Parm                    APIErr
      * If any error in QtmmSendMail API --> issue message in job log
     C                   If        *In99                                        * Error in API
     C                   MoveL     'MHA0055'     MSGIDSM                        * Message ID
     C                   Eval      SDRAMD = %TrimR(SdrAddr)                     * Sender address
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   ExSR      SRSNDPM
     C                   Else
      * Send information message that e-mail was sent
     C                   MoveL     'MHA0009'     MSGIDSM                        * Message ID
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   ExSR      SRSNDPM
     C                   EndIf                                                  * Error in API
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSNDPM - Send program message                                      *
      * ------------------------------------------------------------------- *
     C     SRSNDPM       BegSR
      * Set default message file
     C                   If        MSGFSM = *Blanks                             * Not passed
     C                   Eval      MSGFSM = #HAUMSGF                            * HAUMSG
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
     C                   Clear                   APIErr                         * API Error
     C                   Eval      AEBytPvd=%Size(APIErr)
     C                   Z-Add     1024          MSGDTLSM                       * Message data lengt
     C                   Call      'QMHSNDPM'    pSNDPM                         * Send program msg
      * Reset values for next message send
     C                   MoveL     *BLANKS       MSGFSM                         * Message file
     C                   MoveL     *BLANKS       MSGTYPSM                       * Message type
     C                   MoveL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSNDM - Send nonprogram message                                    *
      * ------------------------------------------------------------------- *
     C     SRSNDM        BegSR
      * Set default message file
     C                   If        MSGFSM = *Blanks                             * Not passed
     C                   Eval      MSGFSM = #HAUMSGF                            * HAUMSG
     C                   EndIf
      * Set default message type
     C                   If        MSGTYPSM = *Blanks                           * Message type
     C                   MoveL     #DIAG         MSGTYPSM                       * Message type
     C                   EndIf
      * Set default message type
     C                   If        MSGTYPSM = *Blanks                           * Message type
     C                   MoveL     #DIAG         MSGTYPSM                       * Message type
     C                   EndIf
      * Send nonprogram message
     C                   Reset                   APIErr                         * API Error
     C                   Z-Add     1024          MSGDTLSM                       * Message data lengt
     C                   Call(E)   'QMHSNDM'     pSNDM                          * Send program msg
      * Reset values for next message send
     C                   MoveL     *BLANKS       MSGFSM                         * Message file
     C                   MoveL     *BLANKS       MSGTYPSM                       * Message type
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRRtvMsg - Retrieve message description                             *
      * ------------------------------------------------------------------- *
     C     SRRtvMsg      BegSR
      * Fill 1st and 2nd level message text
     C                   Clear                   Msg1stRM                       * 1st level message
     C                   Clear                   Msg2ndRM                       * 2nd level message
      * Retrieve program message
     C                   Reset                   APIErr                         * API Error
     C                   Call      'QMHRTVM'     pRTVMD                         * Retrieve message
      * If errors in the API --> Clear retrieve data structure
     C     AEBytAvl      IfNe      0                                            * Errors
     C                   Clear                   RTVM0200
     C                   Eval      Msg1stRM = AEMsgID                           * Message ID
     C                   Else
      * 1st level message
     C                   Eval      Pos = 1 + LRRTNRM
     C                   If        LMRTNRM > 0
     C                   Eval      Msg1stRM = %Subst(MSGVARRM:1+LRRTNRM:LMRTNRM)
     C                   EndIf
      * 2nd level message
     C                   If        LHRTNRM > 0
     C                   Eval      Msg2ndRM = %Subst(MSGVARRM:1+LRRTNRM+LMRTNRM
     C                                        :LHRTNRM)
     C                   EndIf
     C                   EndIf                                                  * Errors?
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtLin - Write MIME file line                                     *
      * ------------------------------------------------------------------- *
     C     SRWrtLin      BegSR
     C                   Eval      IFSBytWrt = write(IFSFileHnd
     C                               : %Addr(IFSLine) : %Len(%TrimR(IFSLine)))
     C                   Clear                   IFSLine
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRBldDte - Build character date format                              *
      * ------------------------------------------------------------------- *
     C     SRBldDte      BegSR
      * Convert current time to *DOS format
     C                   Clear                   CharDTS                        * Date string
     C                   Reset                   APIErr
     C                   Call      'QWCCVTDT'
     C                   Parm      '*CURRENT'    InpFmtWC         10            * Input format
     C                   Parm      *Blanks       InpDatWC         26            * Input date
     C                   Parm      '*DOS'        OutFmtWC         10            * Output format
     C                   Parm                    DOSDTS                         * Output date
     C                   Parm                    APIErr                         * API error
      *
     C                   Move      DOSDay        DOSDay@                        * Day
     C                   Move      DOSYear       DOSYear@                       * Year
     C                   Move      DOSHrs        DOSHrs@                        * Hours
     C                   Move      DOSMin        DOSMin@                        * Minutes
     C                   Move      DOSSec        DOSSec@                        * Seconds
     C                   Eval      TimZon = %Abs(DOSTimZon)                     * Absolute time zone
     C                   Eval      TimZonHrs = %Div(TimZon:60)                  * Hours
     C                   Move      TimZonHrs     TimZonHrs@                     * Hours
     C                   Eval      TimZonMin = %Rem(TimZon:60)                  * Minutes
     C                   Move      TimZonMin     TimZonMin@                     * Minutes
     C                   If        DOSTimZon >= 0                               * Negative !!
     C                   Eval      DOSTimZon@ = '-' + TimZonHrs@ + TimZonMin@   * '-hhmm'
     C                   Else
     C                   Eval      DOSTimZon@ = '+' + TimZonHrs@ + TimZonMin@   * '+hhmm'
     C                   EndIf
     C                   Eval      CharDTS = #DOW(DOSDOW+1) + ', ' +
     C                             DOSDay@ + ' ' + #Month(DOSMonth) +
     C                             ' ' + DOSYear@ +
     C                             ' ' + DosHrs@ + ':' + DOSMin@ + ':' +
     C                             DOSSec@ + ' ' + DOSTimZon@
     C                   EndSR
**CTDATA #Month
JanFebMarAprMayJunJulAugSepOctNovDec
**CTDATA #DOW
SunMonTueWedThuFriSat
