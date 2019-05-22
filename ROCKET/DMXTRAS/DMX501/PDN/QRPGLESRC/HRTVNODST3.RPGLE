      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HRTVNODST3      *PGM                              *
      *            Tries to connect to the specified remote port     *
      *            and returns if the connection succeeded.          *
      *                                                              *
      * Synopsis:  N/A.                                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20040621 FK  Initial delivery                                *
      * ============================================================ *
     HACTGRP(*CALLER) BNDDIR('HSKTPRC' : 'QC2LE') EXTBININT(*YES)

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

     D CloTCP          PR            10I 0
     D                               10I 0 Const

     D GetAddrTyp      PR             4                                         * Address type
     D                              100                                         * Host name

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available

      * Binary fields for QMHSNDPM API
     D                 DS
     D  MSGDTL                 1      4B 0                                      * Bytes provided
     D  STCCTRSM               5      8B 0                                      * Bytes provided

      * Message data
     D MSGDTA          DS          1024
      * Message data for RNS0004
     D  NODEMD                 1      8                                         * Node name
     D  HOSTMD                 9    108                                         * Host name

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #ERROR          C                   CONST('ERROR')
     D #YES            C                   CONST('*YES')
     D #NO             C                   CONST('*NO ')

     D #dmcluster      C                   CONST('dmcluster')
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
     D PrtNum          S             10i 0
     D IPAddr          S             15
     D SrvSkt          S             10I 0
     D CliSkt          S             10I 0
     D RtnTCP          S             10I 0
     D SrvNme          S             30
     D RmtHost         S            100

     D ErrStr          S            100    Based( ErrStrPtr )

     D Error           S              1                                         * Error occurred

      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
      * ------------------------------------------------------------ *
      * Parameter lists                                              *
      * ------------------------------------------------------------ *
      * QMHSNDPM - Send program message
     C     $SNDPM        PLIST
     C                   PARM                    MSGIDSM           7            * Message ID
     C                   PARM                    MSGFSM           20            * Message file
     C                   PARM                    MSGDTA                         * Message data
     C                   PARM                    MSGDTL                         * Message data lengt
     C                   PARM                    MSGTYPSM         10            * Message type
     C                   PARM                    STCENTSM         10            * Call stack entry
     C                   PARM                    STCCTRSM                       * Stack counter
     C                   PARM                    MSGKEYSM          4            * Message key
     C                   PARM                    APIERR            8            * API Error
      * Entry parameters
     C     *ENTRY        Plist
     C                   Parm                    pNode             8            * Node
     C                   Parm                    pRmtHost        256            * Remote host name
     C                   Parm                    pRmtPort          5 0          * Remote port
     C                   Parm                    pNodCnn           4            * Connection?

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Initialisation
     C                   Eval      Error = *OFF                                 * Error
     C                   Eval      pNodCnn = #NO                                * Node connected?

      * Get the IP address of the remote host name
     C                   Eval      RmtHost = pRmtHost
     C                   Eval      IPAddr = GetHostIP(RmtHost)
     C                   If        IPAddr = ' '
      * Send diag message "Host not found"
     C                   MOVEL     'RNS0004'     MSGIDSM                        * Message ID
     C                   MOVEL     #DIAG         MSGTYPSM                       * Message type
     C                   Move      pNode         NODEMD                         * Node
     C                   Move      pRmtHost      HOSTMD                         * Host
     C                   EXSR      SRSNDPM
     C                   Eval      Error = *On                                  * Error
     C                   EndIf

      * Open the socket
     C     Error         IfEQ      *OFF
     C                   Eval      CliSkt = OpnTCP
     C                   If        CliSkt = -1
     C     'Open Failed' Dsply
     C                   Eval      Error = *On                                  * Error
     C                   EndIf
     C                   EndIf

      * Connect to the remote socket
     C     Error         IfEQ      *OFF
     C                   Eval      PrtNum = pRmtPort
     C                   Eval      RtnTCP = CnnTCP(CliSkt: IPAddr: 15: PrtNum)
     C                   If        RtnTCP = -1
     C                   Eval      Error = *On                                  * Error
     C                   EndIf
     C                   EndIf

     C                   Eval      RtnTCP = CloTCP(CliSkt)

      * Return if the connection was established
     C     Error         IfEQ      *Off                                         * Error occurred
     C                   Eval      pNodCnn = #YES                               * Connection?
     C                   EndIf
      *
     C                   Return

      * ------------------------------------------------------------------- *
      * SRSNDPM - Send program message                                      *
      * ------------------------------------------------------------------- *
     C     SRSNDPM       BEGSR
      * Determine message file value for QMHSNDPM API
     C     MSGFSM        IFEQ      *BLANKS
     C                   MOVEL     #MSGF         MSGFSM                         * Default msgf
     C                   ENDIF
      * Set default message type
     C     MSGTYPSM      IFEQ      *BLANKS                                      * Message type
     C                   MOVEL     #DIAG         MSGTYPSM                       * Message type
     C                   ENDIF
      * Determine stack entry/counter value, based on message type
     C                   SELECT
     C     STCENTSM      WHENNE    *BLANKS                                      * Stack entry
     C     MSGTYPSM      WHENEQ    #STATUS                                      * Status message
     C                   MOVEL(P)  #EXT          STCENTSM                       * Stack entry
     C                   Z-ADD     0             STCCTRSM                       * Stack counter
     C     MSGTYPSM      WHENEQ    #INFO                                        * Status message
     C                   MOVEL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-ADD     1             STCCTRSM                       * Stack counter
     C                   OTHER
     C                   MOVEL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-ADD     1             STCCTRSM                       * Stack counter
     C                   ENDSL
      * Send program message
     C                   Z-ADD     0             BPVDAE                         * Bytes provide
     C                   Z-ADD     1024          MSGDTL                         * Message data lengt
     C                   CALL      'QMHSNDPM'    $SNDPM                         * Send program msg
      * Reset values for next message send
     C                   MOVEL     *BLANKS       MSGFSM                         * Message file
     C                   MOVEL     *BLANKS       MSGTYPSM                       * Message type
     C                   MOVEL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-ADD     0             STCCTRSM                       * Stack counter
     C                   ENDSR
