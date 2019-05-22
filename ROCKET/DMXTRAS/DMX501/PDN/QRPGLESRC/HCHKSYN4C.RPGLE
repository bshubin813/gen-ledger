      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HCHKSYN4C       *PGM                              *
      *            Prepares an e-mail with the sync check summary    *
      *            in its body and remaining reports as attachments. *
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
      * 20070919 FK  Initial delivery                                *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HActGrp(*Caller) BNDDIR('HCHKSYNTGT') DftActGrp(*No)

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Defined destinations for alert
     FHMONALRU  IF   E           K DISK
      * Attachment
     FHCHKSYNSPLIF   E           K DISK    UsrOpn

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

      * Open IFS file
     Dopen             Pr            10i 0 ExtProc('open')
     D  filename                       *   Value
     D  openflags                    10i 0 Value
     D  mode                         10u 0 Value Options(*NOPASS)
     D  codepage                     10u 0 Value Options(*NOPASS)

      * Read IFS file
     Dread             Pr            10i 0 ExtProc('read')
     D  filehandle                   10i 0 Value
     D  datareceived                   *   Value
     D  nbytes                       10u 0 Value

      * Write IFS file
     Dwrite            Pr            10i 0 ExtProc('write')
     D  filehandle                   10i 0 Value
     D  datatowrite                    *   Value
     D  nbytes                       10u 0 Value

      * Close IFS file
     Dclose            Pr            10i 0 ExtProc('close')
     D  filehandle                   10i 0 Value

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

      * Program status data structure
     D PgmSts         SDs
     D  PsJob                        10a   Overlay( PgmSts: 244 )
     D  PsJobUsr                     10a   Overlay( PgmSts: 254 )
     D  PsJobNbr                      6a   Overlay( PgmSts: 264 )
     D  PsCurUsr                     10a   Overlay( PgmSts: 358 )

      * List of e-mail addresses
     D LstEML          DS          5002
     D  NbrEML                        4b 0                                      * # of addresses
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

      * *DOS Date format
     D DOSDTS          DS            11
     D  DOSHrs                        3u 0                                      * Hour
     D  DOSMin                        3u 0                                      * Minute
     D  DOSSec                        3u 0                                      * Second
     D  DOSHndSec                     3u 0                                      * Hunderds of secs
     D  DOSDay                        3u 0                                      * Day
     D  DOSMonth                      3u 0                                      * Month
     D  DOSYear                       5i 0                                      * Year
     D  DOSTimZon                     5i 0                                      * Time Zone
     D  DOSDOW                        3u 0                                      * Day of Week

      * Message data
     D MsgDta          DS          1024
      * Message data for CST0101
     D  MDSbj                       100a   Overlay(MsgDta:1)                    * Subject
      * Message data for CST0102/CST0103
     D  MDCurUsr                     10a   Overlay(MsgDta:1)                    * Current user
      * Message data for CST0104
     D  MDRcpAdr                    100a   Overlay(MsgDta:1)                    * Recipient address
      * Message data for CST0105
     D  MDUtlID                      10a   Overlay(MsgDta:1)                    * Utility ID
      * Message data for CST0106
     D  MDNbrDsc                      9b 0 Overlay(MsgDta:1)                    * Number of discr.

      * ------------------------------------------------------------ *
      * Constants                                                    *
      * ------------------------------------------------------------ *
     D #HCHKSYNTGT     c                   CONST('HCHKSYNTGT')
     D #YES            c                   CONST('*YES')
     D #TypMSGQ        c                   CONST('*MSGQ')
     D #TypEML         c                   CONST('*EMAIL')
     D #ALL            c                   CONST('*ALL      ')

     D #Bdy            c                   Const('*BDY')
     D #Att            c                   Const('*ATT')
     D #Snd            c                   Const('*SND')

      * Message values
     D #HAUMSGF        c                   CONST('HAUMSG    *LIBL     ')
     D #CPFMSGF        c                   CONST('QCPFMSG   *LIBL     ')
     D #STATUS         c                   CONST('*STATUS')
     D #INFO           c                   CONST('*INFO')
     D #DIAG           c                   CONST('*DIAG')
     D #ESCAPE         c                   CONST('*ESCAPE')
     D #COMP           c                   CONST('*COMP')
     D #EXT            c                   CONST('*EXT')

      * Constants for MIME file handling
     D #MIMEFileLead   c                   Const('/tmp/hchksyntgt_')
     D #MIMEBoundDef   c                   Const('--BOUNDARY.HCHKSYNTGT')
     D #MIMEBound      c                   Const('----BOUNDARY.HCHKSYNTGT')
     D #CRLF           c                   Const(X'0D25')
     D #Null           c                   Const(X'00')
     D #USASCII        c                   CONST('us-ascii')                    * us-ascii
     D #7BIT           c                   CONST('7bit')                        * 7-bit encoding

      * File Open flags
     D #O_CREAT        s             10i 0 Inz(8)                               * Open with Create
     D #O_EXCL         s             10i 0 Inz(16)                              * Open Exclusive
     D #O_TRUNC        s             10i 0 Inz(64)                              * Open Truncate
     D #O_CODEPAGE     s             10i 0 Inz(8388608)                         * Set Code page
     D #O_TEXTDATA     s             10i 0 Inz(16777216)                        * Open as Text file
      * File access modes
     D #O_RDONLY       s             10i 0 Inz(1)                               * Read-Only
     D #O_WRONLY       s             10i 0 Inz(2)                               * Write-Only
     D #O_RDWR         s             10i 0 Inz(4)                               * Read-Write
      * File Status flags
     D #O_NONBLOCK     s             10i 0 Inz(128)                             * Status Non-block
     D #O_APPEND       s             10i 0 Inz(256)                             * Status Append
      * Share modes
     D #O_SHARE_NONE   s             10i 0 Inz(2000000)                         * Share None
     D#O_SHARE_RDONLY  s             10i 0 Inz(0200000)                         * Share Read-Only
     D #O_SHARE_RDWR   s             10i 0 Inz(1000000)                         * Share Read-Write
     D#O_SHARE_WRONLY  s             10i 0 Inz(0400000)                         * Share Write-Only
      * File permissions (mode)
     D #S_IRUSR        s             10i 0 Inz(256)                             * User Read
     D #S_IWUSR        s             10i 0 Inz(128)                             * User Write
     D #S_IXUSR        s             10i 0 Inz(64)                              * User Execute
     D #S_IRWXU        s             10i 0 Inz(448)                             * User RWX
     D #S_IRGRP        s             10i 0 Inz(32)                              * Group Read
     D #S_IWGRP        s             10i 0 Inz(16)                              * Group Write
     D #S_IXGRP        s             10i 0 Inz(8)                               * Group Execute
     D #S_IRWXG        s             10i 0 Inz(56)                              * Group RWX
     D #S_IROTH        s             10i 0 Inz(4)                               * Other Read
     D #S_IWOTH        s             10i 0 Inz(2)                               * Other Write
     D #S_IXOTH        s             10i 0 Inz(1)                               * Other Execute
     D #S_IRWXO        s             10i 0 Inz(7)                               * Other RWX
      * Miscellaneous
     D #CP_ASCII       s             10i 0 Inz(819)                             * US-ASCII

      * Date conversion tables
     D #Month          s              3    Dim(12) PerRcd(12) CTData            * Months of the year
     D #DOW            s              3    Dim(7) PerRcd(7) CTData              * Days of Week

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *
      * API parameter values
     D MSGDTLSM        s              9b 0                                      * Message data lengt
     D STCCTRSM        s              9b 0                                      * Stack counter
     D INFLRM          s              9b 0                                      * Information length
     D NBRMQSM         s              9b 0                                      * Number of MSGQ
     D MsgKey          s              4a                                        * Message key

      * Miscellaneous
     D Error           s               n                                        * Error occurred
     D FirstTime       s               n                                        * First time exc

     D i               s              3  0                                      * Index
     D j               s              3  0                                      * Index
     D Pos             s              5  0                                      * Starting position
     D Len             s              5  0                                      * Length of string
     D Spc             s              3  0 Dim(256)                             * Spaces
     D MsgLin          s            132a   Dim(10)                              * Broken-up message
     D Msg1stRM        s            256a                                        * First level Msg
     D Msg2ndRM        s           5000a                                        * Second level Msg
     D EMLSbj          s            100a                                        * Email subject

     D IFSFileNbr      s              5  0 Inz(0)                               * IFS File number
     D IFSFileNbr@     s              5a                                        * IFS File number
     D IFSFile         s            255a                                        * IFS File name
     D IFSFileLen      s              9b 0                                      * IFS File name len
     D IFSFileHnd      s             10i 0                                      * IFS File handle
     D IFSLine         s           1000a                                        * Line in MIME file
     D IFSBytWrt       s             10i 0                                      * IFS bytes written
     D IFSRtnVal       s             10i 0                                      * General return val

     D ArrADDT         s            124a   Dim(10)                              * Array of ADDT0100
     D SdrAddr         s            256a                                        * Sender Address
     D SdrName         s             50a                                        * Sender Name
     D SMTPOrg         s            256a                                        * Originator SMTP
     D SMTPOrgLen      s              9b 0                                      * Orig. SMTP length
     D SMTPNbrAdr      s              9b 0                                      * # of Recipients
     D FstLin          s               n                                        * First line
     D MsgSev          s              2  0                                      * Message severity
     D MsgSev@         s              2a                                        * Message severity

     D DOSDay@         s              2                                         * Day
     D DOSYear@        s              4                                         * Year
     D DOSHrs@         s              2                                         * Hour
     D DOSMin@         s              2                                         * Minute
     D DOSSec@         s              2                                         * Seconds
     D DOSTimZon@      s              5                                         * Time zone
     D TimZon          s              4  0                                      * Time zone (abs)
     D TimZonHrs       s              2  0                                      * Time hours
     D TimZonHrs@      s              2                                         * Time hours char
     D TimZonMin       s              2  0                                      * Time minutes
     D TimZonMin@      s              2                                         * Time minutes char
     D CharDTS         s             80a                                        * Character date
     D EMLChr          s             30a                                        * Character set
     D EMLCTE          s             30a                                        * Content Transfer E

      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
      * ------------------------------------------------------------ *
      * Parameter lists                                              *
      * ------------------------------------------------------------ *
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
     C                   Parm                    APIERR                         * API Error
      * Entry parameters
     C     *Entry        Plist
     C                   Parm                    pNbrDsc           9 0          * Number of discr.
     C                   Parm                    pAction           4            * Action
     C                   Parm                    pAttNme          10            * Attachment name
     C                   Parm                    pRtnCde           7            * Return code

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Initialisation
     C                   If        FirstTime
     C                   Eval      Error = *Off                                 * No Error
     C                   Eval      FirstTime=*Off                               * First time
      * Build arrays etc.
     C                   ExSR      SRBldDst                                     * Build destination
     C                   EndIf

      * If no error occurred during initialisation do rest
     C                   If        not Error                                    * No error
      * Action = *BDY --> Create MIME file and write body
     C                   If        pAction=#Bdy                                 * Print body
      * Create MIME file and write header
     C                   ExSR      SRWrtEMHdr                                   * Write e-Mail hdr
      * Write general info in e-mail
     C                   ExSR      SRWrtEM                                      * Write e-mail
     C                   EndIf                                                  * Print body
      * Action = *Att --> Append attachment
     C                   If        pAction=#Att                                 * Print attachment
     C                   ExSR      SRWrtEMAtt                                   * Write attachment
     C                   EndIf                                                  * Print attachment
      * Action = *SND --> Write footer and send
     C                   If        pAction=#Snd                                 * Send e-mail
     C                   ExSR      SRWrtEMFtr                                   * Write footer & snd
     C                   EndIf                                                  * Send e-mail
     C                   EndIf                                                  * No error

     C                   Return

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   Eval      FirstTime=*On                                * First time
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRBldDst - Build destination                                        *
      * ------------------------------------------------------------------- *
     C     SRBldDst      BegSR
      * Initialise array with destinations
     C                   Clear                   LstEML                         * List of E-Mail
      * First read HMONHA specific alert destinations
     C     #HCHKSYNTGT   SetLL     HMONALRUR
     C     #HCHKSYNTGT   ReadE     HMONALRUR                              95
     C                   DoW       not *In95
     C                   If        ALDSTTYP = #TypEML                           * *EMAIL
     C                             and NbrEML < %elem(ArrEML)
     C                   Eval      NbrEML = NbrEML + 1
     C                   Eval      ArrEML(NbrEML) = ALALRDST                    * Alert destination
      * Fill character set and content transfer encoding
     C                   If        EMLChr=*Blanks                               * Not filled yet
     C                   Eval      EMLChr=ALEMLCHR                              * Character set
     C                   EndIf                                                  * Not filled yet
     C                   If        EMLCTE=*Blanks                               * Not filled yet
     C                   Eval      EMLCTE=ALEMLCTE                              * Content Transfer E
     C                   EndIf                                                  * Not filled yet
     C                   EndIf                                                  * *EMAIL
     C     #HCHKSYNTGT   ReadE     HMONALRUR                              95
     C                   EndDo
      * Then read *ALL alert destinations
     C     #ALL          SetLL     HMONALRUR
     C     #ALL          ReadE     HMONALRUR                              95
     C                   DoW       not *In95
     C                   If        ALDSTTYP = #TypEML                           * *EMAIL
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
     C                   EndIf                                                  * *EMAIL
     C     #ALL          ReadE     HMONALRUR                              95
     C                   EndDo
      * If no e-mail address specified, send error message and cause program to exit
     C                   If        NbrEML = 0                                   * E-Mail?
     C                   Eval      MDUtlID=#HCHKSYNTGT                          * Utility ID
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('CST0105':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   Eval      Error = *On                                  * Error
     C                   Eval      pRtnCde = 'CST0105'                          * Return code
      * If any e-mail address, retrieve sender e-mail address and fill recipients data structure
     C                   Else                                                   * E-Mail?
      * Retrieve sender address
     C                   Call      'HCHKSYN4D'
     C                   Parm                    PsCurUsr                       * Current user
     C                   Parm                    SdrAddr                        * Sender address
     C                   Parm                    SdrName                        * Sender name
      * If SMTP address not found for user --> Error
     C                   If        SdrAddr = *Blanks                            * No Sender address
      * Send error in job log and return error
     C                   Eval      MDCurUsr=PsCurUsr                            * Current user
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('CST0102':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   Eval      Error = *On                                  * Error
     C                   Eval      pRtnCde = 'CST0102'                          * Return code
     C                   Else                                                   * Sender address fd
     C                   If        SdrName = *Blanks                            * No Sender name
     C                   Eval      SdrName = PsCurUsr                           * Current user
     C                   EndIf                                                  * No Sender name
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
     C                   Eval      MDRcpAdr=ArrEML(i)                           * Current user
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('CST0104':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#INFO:'*':1:
     C                                     MsgKey:APIErr)
     C                   Eval      i = i + 1                                    * Index
     C                   EndDo                                                  * Number of e-mail
     C                   EndIf                                                  * No error found
     C                   EndIf                                                  * E-Mail?
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtEMHdr - Write header in MIME file                              *
      * ------------------------------------------------------------------- *
     C     SRWrtEMHdr    BegSR
      * Create the MIME file
     C                   Eval      IFSFileNbr=IFSFileNbr+1
     C                   Move      IFSFileNbr    IFSFileNbr@
     C                   Eval      IFSFile = #MIMEFileLead + PsJobNbr +
     C                                       '_' + IFSFileNbr@ + '.txt' + #Null
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
      * Add Subject to header (message)
     C                   Eval      MDNbrDsc=pNbrDsc                             * Number of errors
     C                   Dump(a)
     C                   Eval      MSGIDRM = 'CST0106'                          * Message ID
     C                   Eval      MSGFRM = #HAUMSGF                            * Message file
     C                   Eval      MSGDTLSM = %Size(MsgDta)                     * Message data lengt
      * Retrieve message description
     C                   ExSR      SRRtvMsg                                     * Retrieve message
      * Compose string
     C                   Eval      EMLSbj=Msg1stRM                              * Subject
     C                   Eval      IFSLine = 'Subject: ' +
     C                             %TrimR(Msg1stRM) + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Content-Type: multipart/mixed; boundary=' +
     C                             '"' + #MIMEBoundDef + '"' + #CRLF + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'E-mail from the DMXtras HCHKSYNTGT utility'
     C                             + #CRLF + #MIMEBound + #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Content-Type: text/plain; charset='+EMLChr+
     C                             #CRLF+'Content-Transfer-Encoding:'+EMLCTE+
     C                             #CRLF + #CRLF
     C                   ExSR      SRWrtLin
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtEM - Write e-mail general                                      *
      * ------------------------------------------------------------------- *
     C     SRWrtEM       BegSR
      * Write the spooled file contents to the e-mail body
     C                   If        not %Open(HCHKSYNSPL)
     C                   Open      HCHKSYNSPL
     C                   EndIf
     C                   Read      CHKSYNSPLR                             95
     C                   DoW       not *In95
     C                   Eval      IFSLine = SFLINE+#CRLF
     C                   ExSR      SRWrtLin                                     * Write e-Mail dtl

     C                   Read      CHKSYNSPLR                             95
     C                   EndDo
      * Close the attachment file to prepare for next run
     C                   Close     HCHKSYNSPL
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtEMAtt - Write attachment                                       *
      * ------------------------------------------------------------------- *
     C     SRWrtEMAtt    BegSR
      * Write boundary to start header for this section
     C                   Eval      IFSLine = #CRLF + #CRLF +
     C                             #MIMEBound + #CRLF
     C                   ExSR      SRWrtLin
      * Start body for this section
     C                   Eval      IFSLine =
     C                             'Content-Type: text/plain; charset='+EMLChr+
     C                             #CRLF+'Content-Transfer-Encoding:'+EMLCTE+
     C                             #CRLF
     C                   ExSR      SRWrtLin
     C                   Eval      IFSLine =
     C                             'Content-Disposition: attachment; ' +
     C                             'filename="'+%TrimR(pAttNme)+'.txt"'+
     C                             #CRLF+#CRLF
     C                   ExSR      SRWrtLin
      * Now append the attachment file to the IFS file
     C                   If        not %Open(HCHKSYNSPL)
     C                   Open      HCHKSYNSPL
     C                   EndIf
     C                   Read      CHKSYNSPLR                             95
     C                   DoW       not *In95
     C                   Eval      IFSLine = SFLINE+#CRLF
     C                   ExSR      SRWrtLin                                     * Write e-Mail dtl
     C                   Read      CHKSYNSPLR                             95
     C                   EndDo
      * Close the attachment file to prepare for next run
     C                   Close     HCHKSYNSPL
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
      * SRWrtEMFtr - Close and send MIME file                               *
      * ------------------------------------------------------------------- *
     C     SRWrtEMFtr    BegSR
      * Write closing boundary
     C                   Eval      IFSLine = #CRLF + #MIMEBound + '--' + #CRLF
     C                   ExSR      SRWrtLin
      * Close the IFS file
     C                   Eval      IFSRtnVal = close(IFSFileHnd)
      * Prepare parameters for QtmmSendMail API
     C                   Eval      IFSFileLen = %Len(%TrimR(IFSFile))           * File name length
     C                   Eval      SMTPOrg = SdrAddr                            * Sender address
     C                   Eval      SMTPOrgLen = %Len(%TrimR(SMTPOrg))           * Originator length
     C                   Eval      SMTPNbrAdr = NbrEML                          * # of Recipients
     C                   Reset                   APIErr                         * API Error
      * Send e-mail
     C                   CallB     'QtmmSendMail'
     C                   Parm                    IFSFile                        * IFS File
     C                   Parm                    IFSFileLen                     * IFS File Length
     C                   Parm                    SMTPOrg                        * Originator
     C                   Parm                    SMTPOrgLen                     * Originator length
     C                   Parm                    ArrADDT                        * Recipients
     C                   Parm                    SMTPNbrAdr                     * # of Recipients
     C                   Parm                    APIErr
      * If any error in QtmmSendMail API --> issue message in job log
     C                   If        AEBytAvl <> 0                                * Error in API
      * Resend CPF message
     C                   Reset                   SPAPIErr                       * API Error
     C                   CallP     SndPgmMsg(AEMsgID:#CPFMSGF:AEMsgDta:
     C                                     %len(AEMsgDta):#DIAG:'*':2:
     C                                     MsgKey:SPAPIErr)
     C                   Else                                                   * No error in API
      * Send error in job log and return error
     C                   Eval      MDSbj=EMLSbj                                 * Email subject
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('CST0101':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#INFO:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf                                                  * Error in API
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
