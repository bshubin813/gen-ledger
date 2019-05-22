      *CC:CRTRPGMOD
      *CC:CRTSRVPGM EXPORT(*ALL) BNDDIR(QC2LE)
      * ============================================================ *
      * Object:    HSKTPRC         *SRVPGM                           *
      *            Provides the sockets procedures that clients      *
      *            and server programs can use.                      *
      *                                                              *
      * Synopsis:  N/A.                                              *
      *                                                              *
      * Creation:  CRTRPGMOD                                         *
      *            CRTSRVPGM EXPORT(*ALL) BNDDIR(QC2LE)              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20000807 FK  Initial delivery                                *
      * 20000817 FK  Split Listen and Accept functions               *
      * 20000821 FK  New procedure to get IP address for host        *
      * 20010108 FK  Variable length for string in SndTCP            *
      * 20040622 FK  Also return IP address if *IP address type      *
      * ============================================================ *

     H NoMain
     H BndDir('QC2LE')

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *

     D GetAddrTyp      PR             5
     D  HostName                    100    Const

     D GetHostIP       PR            15
     D  HostName                    100    Const

     D GetPort         PR            10i 0
     D  PrtNme                       30    Const

     D OpnTCP          PR            10i 0

     D BndTCP          PR            10i 0
     D  Socket                       10i 0 Const
     D  Port                         10i 0 Const
     D  Len                          10i 0 Const
     D  pSktAdr                        *

     D AcpTCP          PR            10i 0
     D  Socket                       10i 0 Const
     D  pSktAdr                        *

     D CnnTCP          PR            10i 0
     D  Socket                       10i 0 Const
     D  IP                           15
     D  IPLen                         2  0 Const
     D  Port                          4  0 Const

     D SndTCP          PR            10i 0
     D  Socket                       10i 0 Const
     D  Data                        600

     D RcvTCP          PR            10i 0
     D  Socket                       10i 0 Const
     D  Data                        600

     D CloTCP          PR            10i 0
     D  Socket                       10i 0 Const

     D GveDS           PR            10i 0
     D  JobID                        20
     D  Socket                       10i 0 Const

     D TkeDS           PR            10i 0
     D  JobID                        20

      * Variables
     D Null            C                   Const(x'00')

      * ------------------------------------------------------------ *
      * Any: Get Address type for Host (*IP/*HOST)                   *
      * ------------------------------------------------------------ *
     P GetAddrTyp      B                   EXPORT

     D GetAddrTyp      PI             5
     D HostName                     100    Const

     D HostDS          DS           100
     D  HostArr                       1    Dim(100)                             * Host name

     D HostAdrTyp      S              5                                         * Address type
     D AdrLen          S              3  0                                      * Address length

      * Constants
     D #Null           C                   Const(x'00')
     D #IP             C                   Const('*IP  ')
     D #HOST           C                   Const('*HOST')

     C                   Eval      HostDS = HostName                            * Host name
     C                   Eval      AdrLen = %len(%trimr(HostDS))

      * If length of host name is longer than 15 characters --> not IP Address
     C                   If        AdrLen > 15
     C                   Eval      HostAdrTyp = #HOST                           * Host name
     C                   Else
     C                   Eval      HostDS = HostName                            * Host name
     C                   Eval      HostAdrTyp = #IP                             * IP Address
     C     1             Do        AdrLen        i                 2 0
     C                   If        (HostArr(i)<'0' or HostArr(i)>'9') and
     C                                 HostArr(i)<>'.'
     C                   Eval      HostAdrTyp = #HOST                           * Host name
     C                   EndIf
     C                   EndDo
     C                   EndIf
     C                   Return    HostAdrTyp

     PGetAddrTyp       E

      * ------------------------------------------------------------ *
      * Any: Get IP Address (quad) for Host                          *
      * ------------------------------------------------------------ *
     P GetHostIP       B                   EXPORT

     D GetHostIP       PI            15
     D HostName                     100    Const

      * External procedure gethostbyname()
     D get_host        PR              *   Extproc('gethostbyname')
     D                                 *   Value

      * External procedure inet_ntoa()
     D inet_ntoa       PR              *   Extproc('inet_ntoa')
     D                               10u 0 Value

     D GetAddrTyp      PR             5                                         * Address type
     D                              100                                         * Host name

      * Structure to receive Retrieved host entry
     D HostEnt         DS                  BASED(pHostEnt)
     D  pHostName                      *
     D  ppHostAls                      *
     D  AdrTyp                       10I 0
     D  AdrLen                       10I 0
     D  ppIP                           *

      * Array of pointers to 32-bit IP addresses
     D pAdrLst         S               *   Dim(10)
     D                                     Based(ppAdrLst)

     D IPAdr           S             10u 0 Based(pIPAdr)                        * 32-bit IP address

     D QadDS           DS            15
     D  QadArr                        1    Dim(15)                              * Quad IP address

     D  QadAdr         S             15    Based(pQadAdr)                       * Quad IP address

     D tmpHost         S            100                                         * Null-term Host
     D HostAdrTyp      S              5                                         * Address type

      * Constants
     D #IP             C                   Const('*IP  ')
     D #HOST           C                   Const('*HOST')
     D #Null           C                   Const(x'00')

      * Initialisation
     C*                  Alloc     15            pQadAdr                        * ONLY VALID WITH
     C*                  Eval      QadAdr = *Blanks                             * OS/400 V3R7 AND UP

      * Determine type of passed host address (*IP/*HOST)
     c                   Eval      tmpHost=HostName
     C                   Eval      HostAdrTyp=GetAddrTyp(tmpHost)

     C                   Select
      * First 15 characters is IP address if address type = *IP
     C                   When      HostAdrTyp = #IP                             * *IP
     C                   Eval      QadDS = %Subst(HostName:1:15)                * IP address

      * Get Host name if address type = *HOST
     C                   When      HostAdrTyp = #HOST                           * *HOST
     C     HostName      Cat       #Null:0       tmpHost                        * Host name
     C                   Eval      pHostEnt = get_host(%addr(tmpHost))
     C     pHostEnt      IfNE      *NULL
     C                   Eval      ppAdrLst = ppIP
     C                   Eval      pIPAdr = pAdrLst(1)
     C                   Eval      pQadAdr = inet_ntoa(IPAdr)
     C                   Eval      QadDS = QadAdr
     C     1             Do        15            i                 2 0
     C     QadArr(i)     IfEQ      #Null
     C                   Eval      QadArr(i) = ' '
     C                   EndIf
     C                   EndDo
     C                   Else
     C                   Eval      QadDS = *Blanks
     C                   EndIf
     C                   EndSL

     C                   Return    QadDS

     PGetHostIP        E

      * ------------------------------------------------------------ *
      * Any: Get Port number for Service name                        *
      * ------------------------------------------------------------ *
     P GetPort         B                   EXPORT

     D GetPort         PI            10i 0
     D PrtNme                        30    Const

      * External procedure getservbyname()
     D get_serv        PR              *   Extproc('getservbyname')
     D                                 *   Value
     D                                 *   Value

      * Structure to receive Retrieved service table entry
     D ServEnt         DS                  BASED(pServEnt)
     D  pServName                      *
     D  ppServAls                      *
     D  PrtNum                       10I 0
     D  pProt                          *

     D tmpPort         S             30                                         * Null-term Service
     D #tcp            S              3

      * Constants
     D #Null           C                   Const(x'00')

      * First, terminate the passed service name with a Null
     C                   Eval      #tcp = 'tcp'
     C     PrtNme        Cat       #Null:0       tmpPort                        * Service name

      * Get Service entry
     C                   Eval      pServEnt = get_serv(%addr(tmpPort):
     C                                                 %addr(#tcp))
     C     pServEnt      IfEQ      *NULL
     C                   Return    -1
     C                   Else
     C                   Return    PrtNum
     C                   EndIf

     PGetPort          E

      * ------------------------------------------------------------ *
      * Server: Open Socket                                          *
      * ------------------------------------------------------------ *
     P OpnTCP          B                   EXPORT
     D OpnTCP          PI            10i 0

     D SrvSD           S             10i 0
     D OpnSkt          PR            10i 0 EXTPROC('socket')
     D                               10i 0 Value
     D                               10i 0 Value
     D                               10i 0 Value

     C                   Eval      SrvSD = OpnSkt(2:1:0)                        * Open socket
     C                   Return    SrvSD                                        * Socket descriptor

     POpnTCP           E

      * ------------------------------------------------------------ *
      * Server: Bind and Listen                                      *
      * ------------------------------------------------------------ *
     P BndTCP          B                         EXPORT

     D BndTCP          PI            10i 0
     D SrvSD                         10i 0 Const                                * Server descriptor
     D iport                         10i 0 Const                                * Port number
     D qlen                          10i 0 Const                                * Listen queue lengt
     D pSktAdr                         *                                        * Ptr to SktAdr

     D StrErr          PR              *   ExtProc( 'strerror' )
     D  Dummy                         1    Options( *Omit )

     D SktAdr          DS                  BASED(pSktAdr)                       * Socket address
     D  #family                       5i 0                                      * Address family
     D  #port                         5u 0                                      * Port number
     D  #ip                          10u 0                                      * Local IP address
     D  #zero                         8                                         * Zeroes

     D Size            S             10i 0                                      * Size of SktAdr
     D RtnCde          S             10i 0                                      * Return code
     D ClnSD           S             10i 0                                      * Client descriptor

     D OptVal          S             10I 0 Inz( 1 )
     D OptValPtr       S               *   Inz( %Addr( OptVal ) )
     D LenOptVal       S             10I 0 Inz( %Size( OptVal ) )

     D Bind            PR            10i 0 Extproc('bind')
     D                               10i 0 Value
     D                                 *   Value
     D                               10i 0 Value

     D Listen          PR            10i 0 Extproc('listen')
     D                               10i 0 Value
     D                               10i 0 Value

     D Accept          PR            10i 0 Extproc('accept')
     D                               10i 0 Value
     D                                 *   Value
     D                                 *   Value

     D SetSockOpt      PR            10I 0 ExtProc('setsockopt')
     D  Sckt                         10I 0 Value
     D  Level                        10I 0 Value
     D  Opt                          10I 0 Value
     D  OptValPtr                      *   Value
     D  OptValLen                    10I 0 Value

     D ErrStr          S            100    Based( ErrStrPtr )

      * Allow socket descriptor to be reuseable
     C                   Eval      RtnCde   = SetSockOpt( SrvSD:
     C                                                    -1:
     C                                                    55:
     C                                                    OptValPtr:
     C                                                    LenOptVal )

     C                   Eval      #family = 2
     C                   Eval      #port = iport
     C                   Eval      #ip   = 0
     C                   Move      *ALLx'00'     #zero

     C                   Eval      Size = %size(pSktAdr)
      * Bind
     C                   Eval      RtnCde = Bind(SrvSD:pSktAdr:Size)
     C                   If        RtnCde =  -1
     C                   Eval      ErrStrPtr = StrErr( *Omit )
     C                   Eval      ErrStr = ErrStr
     C                   Return    -1
     C                   Endif

      * Listen
     C                   Eval      RtnCde = Listen(SrvSD:qlen)
     C                   If        RtnCde = -1
     C                   Return    -1
     C                   Endif

     C                   Return    RtnCde

     P BndTCP          E

      * ------------------------------------------------------------ *
      * Server: Accept incoming requests                             *
      * ------------------------------------------------------------ *
     P AcpTCP          B                         EXPORT

     D AcpTCP          PI            10i 0
     D SrvSD                         10i 0 Const
     D pSktAdr                         *

     D SktAdr          DS                  BASED(pSktAdr)
     D  #family                       5i 0
     D  #port                         5u 0
     D  #ip                          10u 0
     D  #zero                         8

     D Size            S             10i 0

     D ClnSD           S             10i 0

     D Accept          PR            10i 0 Extproc('accept')
     D                               10i 0 Value
     D                                 *   Value
     D                                 *   Value

     C                   Eval      Size = %size(SktAdr)

      * Accept
     C                   Eval      ClnSD = Accept(SrvSD:pSktAdr:%addr(Size))
     C                   Return    ClnSD

     P AcpTCP          E

      * ------------------------------------------------------------ *
      * Client: Connect Socket                                       *
      * ------------------------------------------------------------ *
     P CnnTCP          B                   Export
     D CnnTCP          PI            10i 0
     D  RetSD                        10i 0 Const
     D  rmtIP                        15
     D  rmtIPlen                      2  0 Const
     D  rmtport                       4  0 Const

     D RtnCde          S             10i 0
     D size            S             10i 0
     D addr            S               *

     D addr1           DS
     d  #family                       5i 0
     d  #port                         5u 0
     d  #ip                          10u 0
     d  #zero                         8

     D Connect         PR            10i 0 Extproc('connect')
     d                               10i 0 Value
     d                                 *   Value
     d                               10i 0 Value

     D inet_addr       PR            10u 0 Extproc('inet_addr')
     d                                 *   Value

     D  tmpIP          S             16

     C                   Eval      tmpIP=rmtIP+null

     C                   Eval      #ip = inet_addr(%addr(tmpIP))
     C                   Eval      #port = rmtport
     C                   Move      *ALLx'00'     #zero
     C                   Eval      #family = 2
     C                   Eval      addr = %addr(addr1)
     C                   Eval      size = %size(addr)

     C                   Eval      RtnCde = Connect(RetSD:addr:size)

     C                   Return    RtnCde
     P CnnTCP          E

      * ------------------------------------------------------------ *
      * Any   : Send message through socket                          *
      * ------------------------------------------------------------ *
     P SndTCP          B                   Export

     D SndTCP          PI            10i 0
     d  RetSD                        10i 0 Const
     d  Sndstr                      600

     d RtnCde          S             10i 0
     d flag            S             10i 0
     d Sndstrlen       S             10i 0 Inz(600)
     d addr            S               *

     D Send            PR            10i 0 Extproc('send')
     d                               10i 0 Value
     d                                 *   Value
     d                               10i 0 Value
     d                               10i 0 Value

     C                   Eval      flag = 0
     c                   Eval      RtnCde = Send(RetSD:%addr(SndStr):Sndstrlen:
     c                                           flag)
     c                   Return    RtnCde

     P SndTCP          E

      * ------------------------------------------------------------ *
      * Any   : Receive message through socket                       *
      * ------------------------------------------------------------ *
     P RcvTCP          B                   Export

     D RcvTCP          PI            10i 0
     d  RetSD                        10i 0 Const
     d  Rcvstr                      600

     d RtnCde          S             10i 0
     d Rcvstrlen       S             10i 0 Inz(600)
     d addr            S               *
     d flag            S             10i 0

     D recv            PR            10i 0 Extproc('recv')
     d                               10i 0 Value
     d                                 *   Value
     d                               10i 0 Value
     d                               10i 0 Value

     c                   Eval      flag = 0
     c                   Eval      RtnCde = recv(RetSD:%addr(Rcvstr):Rcvstrlen:
     c                                           flag)
     c                   Return    RtnCde

     P RcvTCP          E

      * ------------------------------------------------------------ *
      * Any   : Close socket                                         *
      * ------------------------------------------------------------ *
     P CloTCP          B                   Export
     D CloTCP          PI            10i 0
     d  RetSD                        10i 0 Const

     d RtnCde          S             10i 0
     D closkt          PR            10i 0 Extproc('close')
     d                               10i 0 Value
      * Close
     c                   Eval      RtnCde = Closkt(RetSD)
     c                   Return    RtnCde
     P CloTCP          E

      * ------------------------------------------------------------ *
      * Any   : Give descriptor                                      *
      * ------------------------------------------------------------ *

     P GveDS           B                   Export

     D GveDS           PI            10i 0
     d  tgt_jobid                    20
     d  sD                           10i 0 Const

     d #bpos           S              2  0
     d RtnCde          S             10i 0
     d addr            S               *
     D giveds          PR            10i 0 Extproc('givedescriptor')
     d                               10i 0 Value
     d                                 *   Value

     c     ' '           Scan      tgt_jobid     #bpos
     c                   Eval      %subst(tgt_jobid:#bpos:1) = X'00'
     c                   Eval      addr = %addr(tgt_jobid)
     c                   Eval      RtnCde = giveds(sD:addr)

     c                   Return    RtnCde

     P GveDS           E

      * ------------------------------------------------------------ *
      * Any   : Take descriptor                                      *
      * ------------------------------------------------------------ *

     P TkeDS           B                   Export

     D TkeDS           PI            10i 0
     d  src_jobid                    20

     d #bpos           S              2  0
     d sD              S             10i 0
     d addr            S               *
     D Takeds          PR            10i 0 Extproc('takedescriptor')
     d                                 *   value

     c     ' '           Scan      src_jobid     #bpos
     c                   Eval      %subst(src_jobid:#bpos:1) = X'00'

     c                   Eval      addr = %addr(src_jobid)
     c                   Eval      sD = Takeds(addr)

     c                   Return    sD
     P TkeDS           E
