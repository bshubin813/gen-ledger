      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HRTVCKS1        *PGM RPG                          *
      *            Retrieves checksum for passed file and writes     *
      *            records to output file.                           *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20050420 FK  Initial delivery                                *
      * 20050425 FK  Allow specification of ending record            *
      * 20050503 FK  Block number not calculated correctly           *
      *              Added system name                               *
      * 20050509 FK  Skip block details if only 1 block              *
      * 20050520 FK  Use MD5 algorithm                               *
      * 20050721 FK  Use C APIs to read records in database files    *
      * 20050727 FK  Support for IFS objects                         *
      *              Specify IFS record length                       *
      * 20051018 FK  Include RRN in checksum calculations            *
      * 20060425 FK  Support for different target library            *
      * 20071030 FK  Allow for record lengths up to 65525 bytes      *
      * 20090716 FK  Allow for xLOB fields                           *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HACTGRP(*CALLER) BNDDIR('QC2LE')

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Output file with checksum entries
     FHRTVCKS   UF A E           K DISK    UsrOpn
      * ------------------------------------------------------------- *
      * Prototype definitions                                         *
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

      * __errno built-in function (get error number)
     D RtvErrno        Pr              *   extproc('__errno')

      * _Cipher built-in function (MI)
     D cipher          Pr                  extproc('_CIPHER')
     D  receiver                       *   value
     D  control                        *   value
     D  source                         *   value

      * MI function to create hex character dump of a memory spot
     D HexDump         Pr                  EXTPROC('cvthc')
     D  output                       32a
     D  input                        16a
     D  output_len                   10i 0 value

      * C function to open database file
     D Ropen           Pr              *   ExtProc('_Ropen')
     D  pRFile                         *   Value  Options(*String)              * File to open
     D  pMode                          *   Value  Options(*String)              * Open options

      * C function to close database file
     D Rclose          Pr            10i 0 ExtProc('_Rclose')
     D  pRFP                           *   Value                                * File pointer

      * C function to position to record in database file
     D Rlocate         Pr              *   ExtProc('_Rlocate')
     D  pRFP                           *   Value                                * File pointer
     D  pKey                           *   Value                                * Key value
     D  RRN                          10i 0 Value                                * Record number
     D  ReadOpt                      10i 0 Value                                * Locate options

      * C function to read next record in database file
     D Rreadn          Pr              *   ExtProc('_Rreadn')
     D  pRFP                           *   Value                                * File pointer
     D  pBuffer                        *   Value                                * Buffer
     D  BufLen                       10u 0 Value                                * Buffer length
     D  ReadOpt                      10i 0 Value                                * Read options

      * Open IFS file
     D IFSOpen         Pr            10I 0 ExtProc('open')
     D  path                           *   Value Options(*string)               * Path of file
     D  openflags                    10I 0 Value                                * Open flags
     D  mode                         10U 0 Value Options(*nopass)               * Mode for create
     D  codepage                     10U 0 Value Options(*nopass)               * Create code page

      * Get IFS file system status
     D IFSStatvfs      Pr            10i 0 ExtProc('statvfs64')
     D  path                           *   Value Options(*string)               * Path for file
     D  status                             like(Statvfs64)                      * Status buffer

      * Read IFS file
     D IFSRead         Pr            10i 0 ExtProc('read')
     D  filehandle                   10i 0 Value                                * File handle
     D  pBuffer                        *   Value                                * Received data
     D  pBufLen                      10u 0 Value                                * Buffer length

      * Close IFS file
     D IFSClose        Pr            10i 0 ExtProc('close')
     D  filehandle                   10i 0 Value                                * File handle

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D ApiErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(ApiErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID

      * API-Error data structure for SndPgmMsg
     D SPAPIErr        DS
     D  SPBytPvd                     10i 0 Inz(%Size(SPAPIErr))                 * Bytes provided
     D  SPBytAvl                     10i 0                                      * Bytes available
     D  SPMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  SPMsgDta                    256a                                        * Message data

      * Block hash control
     D BlkHC           DS
     D  BHFunction                    5i 0 Inz(#Hash)                           * Calculate Hash
     D  BHHashAlg                     1A   Inz(#MD5)                            * Use MD5 algorithm
     D  BHSequence                    1A   Inz(#Only)                           * Sequence of block
     D  BHLength                     10I 0 Inz                                  * Data length
     D  BHOutput                      1A   Inz(x'00')                           * Hash output
     D  BHReserved                    7A   Inz(x'00000000000000')
     D  BHCtxPtr                       *   Inz(%Addr(BlkWorkArea))              * Pointer to context

      * File hash control
     D FilHC           DS
     D  FHFunction                    5i 0 Inz(#Hash)                           * Calculate Hash
     D  FHHashAlg                     1A   Inz(#MD5)                            * Use MD5 algorithm
     D  FHSequence                    1A   Inz(#Only)                           * Sequence of block
     D  FHLength                     10I 0 Inz                                  * Data length
     D  FHOutput                      1A   Inz(x'00')                           * Hash output
     D  FHReserved                    7A   Inz(x'00000000000000')
     D  FHCtxPtr                       *   Inz(%Addr(FilWorkArea))              * Pointer to context

      * I/O Feedback structure
     D RIOFB           Ds                  Based(pRIOFB)
     D  pKey                           *                                        * Key
     D  pSysParm                       *                                        * System parameters
     D  IORRN                        10u 0                                      * RRN
     D  IORRN@                        4    Overlay(IORRN)                       * RRN, character
     D  IONbrByt                     10i 0                                      * Bytes read/written
     D  IORcdRmnBlk                   5i 0                                      * Records remain blk
     D  IOBlkFllBy                    1a                                        * Block filled by
     D  IOBitFld                      1a                                        * Bit fields
     D  IORsv01                      20a                                        * Reserved

      * IFS file information structure
     D Stat64          Ds
     D  S64Mode                      10u 0                                      * File mode
     D  S64Ino                       10u 0                                      * File serial number
     D  S64NLnk                       5u 0                                      * # of links
     D  S64Rsv02                      5u 0                                      * Reserved
     D  S64UID                       10u 0                                      * User ID of owner
     D  S64GID                       10u 0                                      * Group ID of group
     D  S64Size                      10i 0                                      * Size in bytes
     D  S64Atime                     10i 0                                      * Access time
     D  S64Mtime                     10i 0                                      * Modification time
     D  S64Ctime                     10i 0                                      * Status change time
     D  S64Dev                       10u 0                                      * Device of file
     D  S64BlkSiz                    10u 0                                      * Block size
     D  S64AlcSiz                    10u 0                                      * Allocated size
     D  S64ObjTyp                    11a                                        * AS/400 object type
     D  S64Rsv03                      1a                                        * Reserved
     D  S64CdePag                     5u 0                                      * Data code page
     D  S64CCSID                      5u 0                                      * Date CCSID
     D  S64Rdev                      10u 0                                      * Device special
     D  S64NLnk32                    10u 0                                      * # of links 32-bit
     D  S64RDev64                    20u 0                                      * Device - 64-bit
     D  S64Dev64                     20u 0                                      * Device of file 64
     D  S64Rsv01                     36a                                        * Reserved
     D  S64Ino_gen_id                10u 0                                      * File serial gen.

      * IFS file system information
     D Statvfs64       Ds
     D  SvBlkSiz                     10u 0                                      * Block size
     D  SvFBlkSiz                    10u 0                                      * Fundam. blk size
     D  SvNbrBlk                     20u 0                                      * # of blocks
     D  SvFreeBlk                    20u 0                                      * Free blocks
     D  SvAvlBlk                     20u 0                                      * Available blocks
     D  SvNbrSrl                     10u 0                                      * # of Files serial#
     D  SvFreeSrl                    10u 0                                      * # of free serial#
     D  SvAvlSrl                     10u 0                                      # Available serial#
     D  SvFSId                       10u 0                                      * File system ID
     D  SvFlag                       10u 0                                      * File system flags
     D  SvNameLen                    10u 0                                      * Maximum name len
     D  SvPathLen                    10u 0                                      * Maximum path len
     D  SvObjLnk                     10i 0                                      * Max. links obj.
     D  SvDirLnk                     10i 0                                      * Max. links dir.
     D  SvRsv01                       4a                                        * Reserved
     D  SvFSId64                     20u 0                                      * File system ID 64
     D  SvBaseType                   80a                                        * File system name

      * Message data
     D MsgDta          DS          1024
      * Message data for RCK0009/RCK0010/RCK0011
     D  MDFile                       10a   Overlay(MsgDta:1)                    * File
     D  MDLib                        10a   Overlay(MsgDta:11)                   * Library

      * Work variables
     D Dummy           S            100a                                        * Dummy string
     D pDummy          S               *                                        * Pointer to dummy
     D BlkChkSum       S             15  0                                      * Checksum for block
     D ChkSum          S             15  0                                      * Checksum
     D Elm             S              5  0                                      * Number of elements
     D CurBlkNum       S              9  0                                      * Current block nbr
     D SavBlkNum       S              9  0                                      * Saved block number
     D BlkStrRcd       S              9  0                                      * Block start record
     D BlkEndRcd       S              9  0                                      * Block end record
     D FilStrRcd       S              9  0                                      * File start record
     D FilEndRcd       S              9  0                                      * File end record
     D NbrRcd          S              9  0                                      * # of Records
     D RcdLen          S              5  0                                      * Record length
     D CurDTS          S               Z                                        * Current date-time
     D pPath           S           5000    Varying
     D PathKey         S            500    Varying
     D MsgKey          s              4a                                        * Message key

      * General variables
     D pErrno          S               *                                        * Pointer to Errno
     D Errno           S             10i 0 Based(pErrno)                        * Error number

      * Database file variables
     D CloRtnCde       s             10i 0                                      * Return code
     D FullNam         s             33a                                        * Full file name
     D pRFILE          s               *                                        * File pointer
     D ReadBuf         S          65535a                                        * Read buffer
     D pReadBuf        S               *
     D RtnBuf          S          65535a   Varying                              * Return buffer
     D pRtnBuf         S               *

      * IFS file variables
     D StatRtnCde      s             10i 0                                      * Return code
     D IFSFile         S           5000A                                        * IFS File name
     D IFSFileLen      S             10i 0                                      * IFS File name len
     D IFSFileHnd      S             10i 0                                      * IFS File handle
     D IFSBuffer       S               *                                        * IFS buffer
     D IFSBufSize      S             10i 0                                      * IFS buffer size
     D IFSReadLen      S             10i 0                                      * IFS bytes read
     D IFSRRN          S             10u 0                                      * IFS RRN

      * Hash variables
     D BlkBinHash      S             16a   Inz(*Loval)                          * Block bin hash
     D FilBinHash      S             16a   Inz(*Loval)                          * File bin hash
     D HexHash         s             32a                                        * Hexadecimal hash
     D p_BlkBinHash    s               *   Inz(%Addr(BlkBinHash))
     D p_FilBinHash    s               *   Inz(%Addr(FilBinHash))

     D BlkWorkArea     S            160A   Inz(*Loval)                          * Block work area
     D FilWorkArea     S            160A   Inz(*Loval)                          * File work area

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #None           c                   Const('*NONE')
     D #Ntv            c                   Const('*NTV')
     D #IFS            c                   Const('*IFS')
     D #Primary        c                   Const('*PRIMARY')
     D #Backup         c                   Const('*BACKUP')
      * Character string conversion
     D #Lo             C                   CONST('abcdefghijklmnopqrstuvwxyz')
     D #Up             C                   CONST('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
      * Database file constants
     D #NO_LOCK        c                   x'00000001'                          * __NO_LOCK
     D #RRN_EQ         c                   x'08000300'                          * __RRN_EQ
     D #RRN_EQ_NL      c                   x'08000301'                          * __RRN_EQ + NO_LOCK
      * IFS file constants
     D #O_RDONLY       S             10i 0 Inz(1)                               * Read-Only
      * Conversion
     D #LoH            C                   Const('abcdef')
     D #UpH            C                   Const('ABCDEF')
      * MD5 Cipher constants
     D #Hash           C                   Const(5)
     D #MD5            C                   Const(x'00')
     D #Sha1           C                   Const(x'01')
     D #Only           C                   Const(x'00')
     D #First          C                   Const(x'01')
     D #Middle         C                   Const(x'02')
     D #Final          C                   Const(x'03')
      * Message values
     D #HAUMSGF        c                   CONST('HAUMSG    *LIBL     ')
     D #CPFMSGF        c                   CONST('QCPFMSG   *LIBL     ')
     D #STATUS         c                   CONST('*STATUS')
     D #INFO           c                   CONST('*INFO')
     D #DIAG           c                   CONST('*DIAG')
     D #ESCAPE         c                   CONST('*ESCAPE')
     D #COMP           c                   CONST('*COMP')
     D #EXT            c                   CONST('*EXT')
      * ------------------------------------------------------------- *
      * Input specifications                                          *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     LimCKS        KList
     C                   KFld                    pLib                           * Library name
     C                   KFld                    pFile                          * File name
     C                   KFld                    pMbr                           * Member name
     C                   KFld                    PathKey                        * Path key
     C                   KFld                    pCksTyp                        * Checksum type
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    pSysNam           8            * System name
     C                   Parm                    pFilSys           4            * File system
     C                   Parm                    pLib             10            * Library name
     C                   Parm                    pFile            10            * File name
     C                   Parm                    pMbr             10            * Member name
     C                   Parm                    pTgtLib          10            * Target library
     C                   Parm                    pRunSys          10            * Running system
     C                   Parm                    pPath                          * Path name
     C                   Parm                    pOutF            10            * Output file
     C                   Parm                    pCksTyp           5            * Checksum type
     C                   Parm                    pNbrRcd           9 0          * Number of records
     C                   Parm                    pStrRcd           9 0          * Starting record
     C                   Parm                    pEndRcd           9 0          * Ending record
     C                   Parm                    pBlkSiz           9 0          * Block size
     C                   Parm                    pIFSRcdLen        5 0          * IFS record length
     C                   Parm                    pFilChkSum       32            * Total checksum
     C                   Parm                    pRtnCde           7            * Return code

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *

      * Initialise
     C                   Clear                   PathKey
     C                   Clear                   pRtnCde

      * Prepare parameters for use in remainder of program
     C                   Select
      * Native object
     C                   When      pFilSys = #Ntv                               * IFS path
     C                   Clear                   pPath                          * Path
     C                   Clear                   PathKey                        * Path key
      * IFS Object
     C                   When      pFilSys = #IFS                               * IFS path
     C                   Clear                   pLib                           * Library
     C                   Clear                   pFile                          * File
     C                   Clear                   pMbr                           * Member
     C                   Clear                   pTgtLib                        * Target library
      * Convert path to upper case for path key
     C                   Eval      PathKey = pPath                              * Path key
     C     #Lo:#Up       XLate     PathKey       PathKey                        * Convert to upper
     C                   EndSL

      * Open output file and delete all file's records if specified
     C                   If        pOutF <> #None
     C                   Open      HRTVCKS
     C     LimCKS        SetLL     RTVCKS@
     C     LimCKS        ReadE     RTVCKS@                                96
     C                   DoW       not *In96
     C                   Delete    RTVCKS@
     C     LimCKS        ReadE     RTVCKS@                                96
     C                   EndDo
     C                   EndIf

      * Now run procedure dependent on file system
     C                   Select
      * Native
     C                   When      pFilSys = #Ntv                               * Native
     C                   ExSR      SRCksNtv
      * IFS file
     C                   When      pFilSys = #IFS                               * IFS file
     C                   ExSR      SRCksIFS
     C                   EndSL

      * Return number of records
     C                   Eval      pNbrRcd = NbrRcd                             * Number of records

     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   Time                    CurDTS                         * Current date-time
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRCksNtv - Determine native checksum records                        *
      * ------------------------------------------------------------------- *
     C     SRCksNtv      BegSR
      * First, open input file
     C                   Select
     C                   When      pRunSys=#Primary                             * *PRIMARY
     C                   Eval      FullNam=%TrimR(pLib) + '/' +
     C                                     %TrimR(pFile) + '(' +
     C                                     %TrimR(pMbr) + ')'
     C                   When      pRunSys=#Backup                              * *BACKUP
     C                   Eval      FullNam=%TrimR(pTgtLib) + '/' +
     C                                     %TrimR(pFile) + '(' +
     C                                     %TrimR(pMbr) + ')'
     C                   EndSL
      * Open file with "normal" open attributes
     C                   Eval      pRFILE=Ropen(FullNam
     C                                         :'rr, arrseq=Y, nullcap=Y, -
     C                                          blkrcd=Y')
      * If open failed, open with LOB attributes
     C                   If        pRFILE=*Null
     C                   Eval      MDFile=pFile                                 * File
     C                   Eval      MDLib=pLib                                   * Library
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('RCK0009':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':1:
     C                                     MsgKey:APIErr)
     C                   Eval      pRFILE=Ropen(FullNam
     C                                         :'rr, arrseq=Y, nullcap=Y, -
     C                                          blkrcd=Y, lobptrs=Y')
      * If open failed, send error message and quit
     C                   If        pRFILE=*Null
     C                   Eval      MDFile=pFile                                 * File
     C                   Eval      MDLib=pLib                                   * Library
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('RCK0010':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#DIAG:'*':2:
     C                                     MsgKey:APIErr)
     C                   Eval      pRtnCde='RCK0010'                            * Return code
      * If open succeeded, send completion message and continue
     C                   Else
     C                   Eval      MDFile=pFile                                 * File
     C                   Eval      MDLib=pLib                                   * Library
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('RCK0011':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#COMP:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf
     C                   EndIf

      * Start with given starting record
     C                   If        pRtnCde=*Blank
     C                   Eval      pRIOFB=Rlocate(pRFILE                        * File pointer
     C                                           :*Null                         * Do not pass
     C                                           :pStrRcd-1                     * RRN
     C                                           :#RRN_EQ_NL)                   * RRN and No Lock
      * Read first record
     C                   Eval      pRIOFB=RReadn(pRFILE                         * File pointer
     C                                          :%Addr(ReadBuf)                 * Read buffer
     C                                          :%Size(ReadBuf)                 * Maximum size
     C                                          :#NO_LOCK)                      * No lock
      * If record read, store file starting record
     C                   If        IONbrByt > 0
     C                   Eval      RcdLen = IONbrByt                            * Record length
     C                   Eval      FilStrRcd = IORRN                            * File start record
     C                   Eval      FilWorkArea = *Loval                         * Initialise work ar
     C                   Eval      FilBinHash = *Loval                          * Binary hash val
     C                   Eval      FHSequence = #First                          * First rcd for hash
     C                   Eval      NbrRcd = 1                                   * # of Records
     C                   EndIf
      * Now process all records in the file
     C                   DoW       IONbrByt > 0 and
     C                             (pNbrRcd = 0 or NbrRcd <= pNbrRcd) and
     C                             IORRN <= pEndRcd
     C                   Eval      RtnBuf = %Subst(ReadBuf:1:IONbrByt) + IORRN@
     C                   Eval      FilEndRcd = IORRN                            * File ending record
      * If output file to be divided into blocks --> Write block record
     C                   If        pBlkSiz <> 0 and pOutF <> #None
     C                   Eval      CurBlkNum = %Div(IORRN:pBlkSiz)+1
     C                   If        CurBlkNum <> SavBlkNum                       * Changed block
     C                   If        SavBlkNum <> 0                               * Not empty block
     C                   ExSR      SRClcCks                                     * Calculate checksum
     C                   ExSR      SRWrtCks                                     * Write checksum ent
     C                   EndIf                                                  * Not first block
     C                   Eval      SavBlkNum = CurBlkNum                        * Saved block number
     C                   Eval      BlkWorkArea = *Loval                         * Initialise work ar
     C                   Eval      BlkBinHash = *Loval                          * Binary hash val
     C                   Eval      BHSequence = #First                          * First rcd for hash
     C                   Eval      BlkStrRcd = IORRN                            * Block start record
     C                   EndIf                                                  * Changed block
     C                   Eval      BlkEndRcd = IORRN                            * Block end record
     C                   EndIf                                                  * Blocks?
      * Calculate block checksum for record
     C                   If        pBlkSiz <> 0 and pOutF <> #None
     C                   Eval      BHLength = IONbrByt + 4
     C                   Eval      pRtnBuf = %Addr(RtnBuf)
     C                   CallP     Cipher(%Addr(p_BlkBinHash)
     C                                   :%Addr(BlkHC)
     C                                   :%Addr(pRtnBuf))
     C                   Eval      BHSequence = #Middle
     C                   EndIf
      * Add record to file checksum
     C                   Eval      FHLength = IONbrByt + 4
     C                   Eval      pRtnBuf = %Addr(RtnBuf)
     C                   CallP     Cipher(%Addr(p_FilBinHash)
     C                                   :%Addr(FilHC)
     C                                   :%Addr(pRtnBuf))
     C                   Eval      FHSequence = #Middle
      *
     C                   Eval      NbrRcd = NbrRcd + 1                          * # of Records
      * Read next record
     C                   Eval      pRIOFB=RReadn(pRFILE                         * File pointer
     C                                          :%Addr(ReadBuf)                 * Read buffer
     C                                          :%Size(ReadBuf)                 * Maximum size
     C                                          :#NO_LOCK)                      * No lock
     C                   EndDo
      * If any record read --> calculate and write checksums
     C                   If        NbrRcd <> 0
      * If output file to be divided into blocks and more than 1 block --> write last block
     C                   If        pBlkSiz <> 0 and SavBlkNum > 1
     C                             and pOutF <> #None
     C                   ExSR      SRClcCks                                     * Calculate checksum
     C                   ExSR      SRWrtCks                                     * Write checksum ent
     C                   EndIf
      * Calculate checksum for entire file
     C                   Eval      SavBlkNum = 0
     C                   ExSR      SRClcCks                                     * Calculate checksum
     C                   Eval      pFilChkSum=HexHash                           * File checksum
      * If output file --> Write file entry
     C                   If        pOutF <> #None
     C                   ExSR      SRWrtCks                                     * Write checksum ent
     C                   EndIf
     C                   EndIf                                                  * Record read
      * Close the file in the end
     C                   Eval      CloRtnCde=Rclose(pRFile)
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRCksIFS - Determine native checksum records                        *
      * ------------------------------------------------------------------- *
     C     SRCksIFS      BegSR
      * If IFS record length *AUTO --> get file system statistics to determine size
     C                   If        pIFSRcdLen = 0                               * *AUTO
     C                   Eval      StatRtnCde=IFSStatvfs(%TrimR(pPath)
     C                                                  :Statvfs64)
      * Calculate buffer size and allocate buffer
     C                   Eval      IFSBufSize=SvBlkSiz*8                        * Buffer size
     C                   Eval      IFSBuffer=%Alloc(IFSBufSize)                 * Allocate buffer
     C                   Eval      RcdLen = IFSBufSize                          * Record length
     C                   Eval      pIFSRcdLen = RcdLen                          * Return record len
     C                   Else                                                   * not *AUTO
      * Buffer size is fixed
     C                   Eval      IFSBuffer=%Alloc(pIFSRcdLen)                 * Allocate buffer
     C                   Eval      RcdLen = pIFSRcdLen                          * Record length
     C                   EndIf                                                  * *AUTO
      * Open input file
     C                   Eval      IFSFileHnd=IFSopen(%TrimR(pPath)
     C                                               :#O_RDONLY)
     C                   If        IFSFileHnd = -1                              * Error on open
     C                   Eval      pErrno = RtvErrno()
     C                   Eval      pRtnCde = 'CPE' + %char(Errno)
     C                   Else                                                   * No error on open
      * Read first record
     C                   Eval      IFSReadLen=IFSRead(IFSFileHnd                * File pointer
     C                                               :IFSBuffer                 * Buffer
     C                                               :IFSBufSize)               * Buffer length
     C                   If        IFSReadLen = -1                              * Error on read
     C                   Eval      pErrno = RtvErrno()
     C                   Eval      pRtnCde = 'CPE' + %char(Errno)
     C                   Else                                                   * No error on read
      * If record read, store file starting record
     C                   If        IFSReadLen > 0
     C                   Eval      IFSRRN = 1                                   * IFS RRN
     C                   Eval      FilStrRcd = IFSRRN                           * File start record
     C                   Eval      FilWorkArea = *Loval                         * Initialise work ar
     C                   Eval      FilBinHash = *Loval                          * Binary hash val
     C                   Eval      FHSequence = #First                          * First rcd for hash
     C                   Eval      NbrRcd = 0                                   * # of Records
     C                   EndIf
      * Now process all records in the file
     C                   DoW       IFSReadLen > 0 and
     C                             (pNbrRcd = 0 or NbrRcd <= pNbrRcd) and
     C                             IFSRRN <= pEndRcd
     C                   If        IFSRRN >= pStrRcd                            * Starting record
     C                   Eval      FilEndRcd = IFSRRN                           * File ending record
      * If output file to be divided into blocks --> Write block record
     C                   If        pBlkSiz <> 0 and pOutF <> #None
     C                   Eval      CurBlkNum = %Div(IFSRRN:pBlkSiz)+1
     C                   If        CurBlkNum <> SavBlkNum                       * Changed block
     C                   If        SavBlkNum <> 0                               * Not empty block
     C                   ExSR      SRClcCks                                     * Calculate checksum
     C                   ExSR      SRWrtCks                                     * Write checksum ent
     C                   EndIf                                                  * Not first block
     C                   Eval      SavBlkNum = CurBlkNum                        * Saved block number
     C                   Eval      BlkWorkArea = *Loval                         * Initialise work ar
     C                   Eval      BlkBinHash = *Loval                          * Binary hash val
     C                   Eval      BHSequence = #First                          * First rcd for hash
     C                   Eval      BlkStrRcd = IFSRRN                           * Block start record
     C                   EndIf                                                  * Changed block
     C                   Eval      BlkEndRcd = IFSRRN                           * Block end record
     C                   EndIf                                                  * Blocks?
      * Calculate block checksum for record
     C                   If        pBlkSiz <> 0 and pOutF <> #None
     C                   Eval      BHLength = IFSReadLen
     C                   CallP     Cipher( %Addr(p_BlkBinHash)
     C                                   : %Addr(BlkHC)
     C                                   : %Addr(IFSBuffer))
     C                   Eval      BHSequence = #Middle
     C                   EndIf
      * Add record to file checksum
     C                   Eval      FHLength = IFSReadLen
     C                   CallP     Cipher( %Addr(p_FilBinHash)
     C                                   : %Addr(FilHC)
     C                                   : %Addr(IFSBuffer))
     C                   Eval      FHSequence = #Middle
      *
     C                   Eval      NbrRcd = NbrRcd + 1                          * # of Records
     C                   EndIf                                                  * Starting record
      * Read next record
     C                   Eval      IFSReadLen=IFSRead(IFSFileHnd                * File pointer
     C                                               :IFSBuffer                 * Buffer
     C                                               :IFSBufSize)               * Buffer length
     C                   Eval      IFSRRN = IFSRRN + 1                          * IFS RRN
     C                   EndDo
      * If any record read --> calculate and write checksums
     C                   If        NbrRcd <> 0
      * If output file to be divided into blocks and more than 1 block --> write last block
     C                   If        pBlkSiz <> 0 and SavBlkNum > 1
     C                             and pOutF <> #None
     C                   ExSR      SRClcCks                                     * Calculate checksum
     C                   ExSR      SRWrtCks                                     * Write checksum ent
     C                   EndIf
      * Calculate checksum for entire file
     C                   Eval      SavBlkNum = 0
     C                   ExSR      SRClcCks                                     * Calculate checksum
     C                   Eval      pFilChkSum = HexHash                         * File checksum
      * If output file --> Write file entry
     C                   If        pOutF <> #None
     C                   ExSR      SRWrtCks                                     * Write checksum ent
     C                   EndIf
     C                   EndIf                                                  * Record read
     C                   EndIf                                                  * Error on read
      * Close the file in the end
     C                   Eval      CloRtnCde = IFSClose(IFSFileHnd)
     C                   EndIf                                                  * Error on open
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRClcCks - Calculate checksum                                       *
      * ------------------------------------------------------------------- *
     C     SRClcCks      BegSR
      * Calculate checksum for block/final
     C                   If        SavBlkNum <> 0                               * Block checksum
     C                   Eval      BHLength = 0                                 * No new data
     C                   Eval      BHSequence = #Final                          * Last record in blk
     C                   Eval      pDummy = %Addr(Dummy)
     C                   CallP     Cipher( %Addr(p_BlkBinHash)
     C                                   : %Addr(BlkHC)
     C                                   : %Addr(pDummy))
      * Convert binary value to hexadecimal string
     C                   CallP     HexDump( HexHash
     C                                    : BlkBinHash
     C                                    : %Size(HexHash))
     C                   Else                                                   * File checksum
     C                   Eval      FHLength = 0                                 * No new data
     C                   Eval      FHSequence = #Final                          * Last record in fil
     C                   Eval      pDummy = %Addr(Dummy)
     C                   CallP     Cipher( %Addr(p_FilBinHash)
     C                                   : %Addr(FilHC)
     C                                   : %Addr(pDummy))
      * Convert binary value to hexadecimal string
     C                   CallP     HexDump( HexHash
     C                                    : FilBinHash
     C                                    : %Size(HexHash))
     C                   EndIf
      * Make lower case of hexadecimal values
     C     #UpH:#LoH     XLate     HexHash       HexHash                        * Make lower case
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtCks - Write checksum record                                    *
      * ------------------------------------------------------------------- *
     C     SRWrtCks      BegSR
     C                   Clear                   RTVCKS@
      * Prepare record fields dependent on SavBlkNum
     C                   Eval      CKFSYS = pFilSys                             * File system
     C                   Eval      CKSYSNAM = pSysNam                           * System name
     C                   Eval      CKLIB = pLib                                 * File library
     C                   Eval      CKFILE = pFile                               * File
     C                   Eval      CKMBR = pMbr                                 * Member
     C                   Eval      CKTGTLIB = pTgtLib                           * Target library
     C                   Eval      CKRUNSYS = pRunSys                           * Running system
     C                   Eval      CKPATH = pPath                               * Path
     C                   Eval      CKPTHKEY = PathKey                           * Path key
     C                   Eval      CKCKSTYP = pCksTyp                           * Checksum type
     C                   Eval      CKBLKNUM = SavBlkNum                         * Block number
     C                   Eval      CKRCDLEN = RcdLen                            * Record length
     C                   Eval      CKDTS = CurDTS                               * Date-time
      * Now, prepare dependent on block/total checksum
     C                   If        SavBlkNum <> 0                               * Block checksum
     C                   Eval      CKCHKSUM = HexHash                           * Block checksum
     C                   Eval      CKRCDSTR = BlkStrRcd                         * Starting record
     C                   Eval      CKRCDEND = BlkEndRcd                         * Ending record
     C                   Else                                                   * Total checksum
     C                   Eval      CKCHKSUM = HexHash                           * Total checksum
     C                   Eval      CKRCDSTR = FilStrRcd                         * Starting record
     C                   Eval      CKRCDEND = FilEndRcd                         * Ending record
     C                   EndIf
     C                   Write     RTVCKS@
     C                   EndSR
