      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONNET1        *PGM                              *
      *            Monitors the current network traffic and writes   *
      *            to an output file.                                *
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
      * 20051216 FK  Initial delivery                                *
      * 20060307 FK  Store addresses without limiting Null           *
      * 20060328 FK  Error when address 192.168.1.11 given           *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HDFTACTGRP(*NO) ACTGRP(*CALLER) BNDDIR('QC2LE')

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Network traffic output file
     FHNETTFC   UF A E           K DISK

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * Retrieve pointer to user space
     D RtvPtrUS        PR                  ExtPgm('QUSPTRUS')
     D  RPUsrSpcQ                    20a   Const
     D  RPPtr                          *
     D  RPErr                     32767a         Options(*NoPass:*VarSize )

      * List network connections
     D LstNetCnn       PR                  ExtProc('QtocLstNetCnn')
     D  LCUsrSpcQ                    20a   Const
     D  LCFmt                         8a   Const
     D  LCCnnQ                       64a   Const
     D  LCCnnQSiz                    10i 0 Const
     D  LCCnnQFmt                     8a   Const
     D  LCErr                     32767a         Options(*VarSize)

      * Convert dotted IP address to IN_ADDR structure
     D INetAddr        PR            10u 0 ExtProc('inet_addr')
     D                                 *   Value options(*String)

      * Convert IN_ADRR structure to dotted IP addess
     D INetNtoA        PR              *   ExtProc('inet_ntoa')
     D                               10u 0 Value

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID

      * Generic header for user space
     D UsrSpc          DS                  Based(xUsrSpc)
     D  USOfsHdr                     10i 0 Overlay(UsrSpc:117)                  * Offset to header
     D  USOfsLst                     10i 0 Overlay(UsrSpc:125)                  * Offset to list sec
     D  USNbrEnt                     10i 0 Overlay(UsrSpc:133)                  * # of list entries
     D  USEntSiz                     10i 0 Overlay(UsrSpc:137)                  * Entry size

      * NCLQ0100 - Qualifier for connection list
     D NCLQ0100        DS
     D  NQCnnTyp                     10a   Inz('*TCP')                          * Connection type
     D  NQRqsTyp                     10a   Inz('*SUBSET')                       * Request type
     D                               12a   Inz(*Allx'00')                       * Filler
     D  NQLclAdrL                    10u 0 Inz(0)                               * Local address low
     D  NQLclAdrU                    10u 0 Inz(0)                               * Local address up
     D  NQLclPortL                   10i 0 Inz(0)                               * Local port low
     D  NQLclPortU                   10i 0 Inz(0)                               * Local port up
     D  NQRmtAdrL                    10u 0 Inz(0)                               * Remote address low
     D  NQRmtAdrU                    10u 0 Inz(0)                               * Remote address up
     D  NQRmtPortL                   10i 0 Inz(0)                               * Remote port low
     D  NQRmtPortU                   10i 0 Inz(0)                               * Remote port up

      * NCNN0100 - Connection list entry
     D NCNN0100        DS                  Based(xLstEnt)
     D  NNRmtAdr                     15a                                        * Remote address
     D                                1a                                        * Reserved
     D  NNRmtAdrB                    10u 0                                      * Remote address bin
     D  NNLclAdr                     15a                                        * Local address
     D                                1a                                        * Reserved
     D  NNLclAdrB                    10u 0                                      * Local address bin
     D  NNRmtPort                    10i 0                                      * Remote port
     D  NNLclPort                    10i 0                                      * Local port
     D  NNTcpStt                     10i 0                                      * TCP state
     D  NNIdlTim                     10i 0                                      * Idle time (ms)
     D  NNBytIn                      20u 0                                      * Bytes in
     D  NNBytOut                     20u 0                                      * Bytes out
     D  NNCnnOpnTyp                  10i 0                                      * Conn. open type
     D  NNCnnTyp                     10a                                        * Connection type
     D                                1a                                        * Reserved

      * Message data
     D MSGDTA          DS           500

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Lcl            c                   Const('*LCL')
     D #Rmt            c                   Const('*RMT')
     D #LclRmt         c                   Const('*LCLRMT')
     D #UsrSpc         c                   Const('HMONNETTFCQTEMP     ')
     D #All            c                   Const('*ALL')
     D #Null           c                   Const(x'00000000000000000000000000')
      * Message values
     D #MSGF           c                   Const('HAUMSG    *LIBL     ')
     D #STATUS         c                   Const('*STATUS')
     D #INFO           c                   Const('*INFO')
     D #DIAG           c                   Const('*DIAG')
     D #ESCAPE         c                   Const('*ESCAPE')
     D #COMP           c                   Const('*COMP')
     D #EXT            c                   Const('*EXT')

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *
      * API parameter values
     D MSGDTLSM        s              9b 0                                      * Message data lengt
     D STCCTRSM        s              9b 0                                      * Stack counter
     D INFLRM          s              9b 0                                      * Information length
     D NBRMQSM         s              9b 0                                      * Number of MSGQ

     D CurDTS          s               z                                        * Current date-time
     D FstTme          s               n                                        * First time
     D NewChl          s               n                                        * New channel start
     D NbrSec          s             10i 0                                      * # of seconds

     D xUsrSpc         s               *                                        * Pointer to UsrSpc
     D xHdrInf         s               *                                        * Header info
     D xLstEnt         s               *                                        * List entry
     D i               s             10i 0                                      * Index
     D PrvLclAdr       s             15a                                        * Previous local adr
     D PrvRmtAdr       s             15a                                        * Previous remote ad
     D PrvPort         s              5  0                                      * Previous port numb
     D PrvDTSM         s               z                                        * Previous date-time
     D PrvBytIn        s             25  0                                      * Previous bytes in
     D PrvBytOut       s             25  0                                      * Previous bytes out
     D PrvBytTot       s             25  0                                      * Previous bytes tot
     D RmtAdr          s             15a                                        * RmtAdr (null-term)
     D RmtAdrNum       s             10u 0                                      * Numeric RmtAdr

      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
      * Key list for positioning to network traffic
     C     PosNet        KList
     C                   KFld                    pSysNam                        * System name
     C                   KFld                    NTADRL                         * Local address
     C                   KFld                    NTADRR                         * Remote address
     C                   KFld                    pPort                          * Port number
     C                   KFld                    pPortLoc                       * Port location
     C                   KFld                    CurDTS                         * Date-time
      * Key list for limiting to network traffic
     C     LimNet        KList
     C                   KFld                    pSysNam                        * System name
     C                   KFld                    NTADRL                         * Local address
     C                   KFld                    NTADRR                         * Remote address
     C                   KFld                    pPort                          * Port number
     C                   KFld                    pPortLoc                       * Port location

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
     C                   Parm                    APIERR                         * API Error

      * Entry parameters
     C     *Entry        Plist
     C                   Parm                    pSysNam           8            * System name
     C                   Parm                    pPort             5 0          * Port number
     C                   Parm                    pPortLoc          7            * Port location
     C                   Parm                    pRmtAdr          15            * Remote address

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Initialisation
     C                   Time                    CurDTS                         * Current date-time
     C                   Clear                   PrvLclAdr                      * Previous local adr
     C                   Clear                   PrvRmtAdr                      * Previous remote ad
     C                   Eval      RmtAdr=%TrimR(pRmtAdr)+#Null                 * Null-terminate
      * If *LCL/*RMT and specific port/address specified --> Let API do selection
     C                   Select
     C                   When      pPortLoc=#Lcl                                * *LCL
     C                   Eval      NQLclPortL=pPort                             * Lower value
     C                   Eval      NQLclPortU=pPort                             * Upper value
     C                   When      pPortLoc=#Rmt                                * *RMT
     C                   Eval      NQRmtPortL=pPort                             * Lower value
     C                   Eval      NQRmtPortU=pPort                             * Upper value
     C                   EndSL
      * If remote address specified --> Let API do selection
     C                   If        pRmtAdr<>#All                                * *ALL
      * Convert dotted decimal to unsigned numeric
     C                   Eval      RmtAdrNum=INetAddr(%Addr(RmtAdr))
     C                   If        RmtAdrNum<>4294967295
     C                   Eval      NQRmtAdrL=RmtAdrNum                          * Lower value
     C                   Eval      NQRmtAdrU=RmtAdrNum                          * Upper value
     C                   EndIf
     C                   EndIf                                                  * *ALL
      * Call API to retrieve list of network connections
     C                   CallP     LstNetCnn(#UsrSpc
     C                                      :'NCNN0100'
     C                                      :NCLQ0100
     C                                      :%Size(NCLQ0100)
     C                                      :'NCLQ0100'
     C                                      :ApiErr)
      * If no error --> Process list entries
     C                   If        AEBytAvl=0
      * Retrieve pointer to user space
     C                   CallP     RtvPtrUS(#UsrSpc
     C                                     :xUsrSpc)
      * Retrieve offset to list section
     C                   Eval      xLstEnt = xUsrSpc + USOfsLst
      * Now process entire list of entries
     C                   Eval      i=1
     C                   DoW       i <= USNbrEnt
      * Only select connection entries that have been established (state=3)
     C                   If        NNTcpStt=3                                   * Established
      * Select dependent on port number, remote address and port location
     C                   Select                                                 * Location/Port
     C                   When      pPortLoc=#LclRmt and                         * *LCLRMT
     C                             (NNLclPort=pPort or NNRmtPort=pPort) and     * Port equal
     C                             (NNRmtAdr=RmtAdr or pRmtAdr=#All)            * Remote address
     C                   ExSR      SRUpdRcd                                     * Update/Add record
     C                   Other                                                  * API has done sel.
     C                   ExSR      SRUpdRcd                                     * Update/Add record
     C                   EndSL                                                  * Location/Port
     C                   EndIf                                                  * Established
      * Prepare for next loop
     C                   Eval      i=i+1
     C                   Eval      xLstEnt=xLstEnt+USEntSiz                     * Advance pointer
     C                   EndDo                                                  * Process list ent
     C                   EndIf                                                  * No error
      * Prepare for next call
     C                   Eval      FstTme = *Off                                * First time
     C                   Return

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   Eval      FstTme = *On                                 * First time
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRUpdRcd - Update record                                            *
      * ------------------------------------------------------------------- *
     C     SRUpdRcd      BegSR
      * If not first time, retrieve previous record
     C                   If        not FstTme and
     C                             (NNLclAdr<>PrvLclAdr or NNRmtAdr<>PrvRmtAdr)
     C                   Eval      NewChl=*Off                                  * New channel
     C                   Eval      NTADRL=%Str(%Addr(NNLclAdr):15)
     C                   Eval      NTADRR=%Str(%Addr(NNRmtAdr):15)
     C     PosNet        SetLL     HNETTFCR
     C     LimNet        ReadPE(N) HNETTFCR                               94
     C                   If        not *In94                                    * Record found
     C                   Eval      PrvDTSM=NTDTSM                               * Date-Time stamp
     C                   Eval      PrvBytIn=NTBYTIN                             * Bytes in
     C                   Eval      PrvBytOut=NTBYTOUT                           * Bytes out
     C                   Eval      PrvBytTot=NTBYTTOT                           * Bytes total
      * This situation can happen if a new channel is started
     C                   Else
     C                   Eval      NewChl=*On                                   * New channel
     C                   EndIf                                                  * Record found
     C                   Eval      PrvLclAdr=NNLclAdr                           * Local address
     C                   Eval      PrvRmtAdr=NNRmtAdr                           * Remote address
     C                   EndIf
      * Prepare values to write/update
     C                   Eval      NTSYSN=pSysNam                               * System name
     C                   Eval      NTADRL=%Str(%Addr(NNLclAdr):15)
     C                   Eval      NTADRR=%Str(%Addr(NNRmtAdr):15)
     C                   Eval      NTPORT=pPort                                 * Port number
     C                   Eval      NTPORTLOC=pPortLoc                           * Port location
     C                   Eval      NTDTSM=CurDTS                                * Date-time measure
     C                   Eval      NTBYTIN=0                                    * Bytes in
     C                   Eval      NTBYTOUT=0                                   * Bytes out
     C                   Eval      NTBYTTOT=0                                   * Bytes total
     C                   Eval      NTITV=0                                      * Interval (s)
     C                   Eval      NTBPSIN=0                                    * In bandw. bps
     C                   Eval      NTBPSOUT=0                                   * Out bandw. bps
     C                   Eval      NTBPSTOT=0                                   * Total bandw. bps
      * Now write/update current record
     C     PosNet        Chain     HNETTFCR                           95
     C                   Eval      NTBYTIN=NTBYTIN+NNBytIn                      * Bytes in
     C                   Eval      NTBYTOUT=NTBYTOUT+NNBytOut                   * Bytes out
     C                   Eval      NTBYTTOT=NTBYTTOT+NNBytIn+NNBytOut           * Bytes total
      * Calculate bps (only if it makes sense to do so)
     C                   If        not FstTme and not NewChl
     C     CurDTS        SubDur    PrvDTSM       NTITV:*S               20      * Interval
     C   20              Eval      NTITV=-1
     C                   If        NTITV>0 and                                  * Prevent div by 0
     C                             NTBYTTOT>=PrvBytTot                          * Not reset
     C                   Eval      NTBPSIN=((NTBYTIN-PrvBytIn)*8)/NTITV         * In bps
     C                   Eval      NTBPSOUT=((NTBYTOUT-PrvBytOut)*8)/NTITV      * Out bps
     C                   Eval      NTBPSTOT=((NTBYTTOT-PrvBytTot)*8)/NTITV      * Total bps
     C                   EndIf
     C                   EndIf                                                  * Calculate
      * Now write/update dependent on indicator
     C   95              Write     HNETTFCR
     C  N95              Update    HNETTFCR
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
     C                   Eval      AEBytPvd=0                                   * Bytes provided
     C                   Z-Add     1024          MSGDTLSM                       * Message data lengt
     C                   Call      'QMHSNDPM'    pSNDPM                         * Send program msg
      * Reset values for next message send
     C                   MoveL     *BLANKS       MSGFSM                         * Message file
     C                   MoveL     *BLANKS       MSGTYPSM                       * Message type
     C                   MoveL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
