      * ============================================================ *
      * Object:    HRTVNODST2      *PGM                              *
      *            Retrieves the status of the passed node, in       *
      *            decoupled mode.                                   *
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
      * 20050216 FK  Initial delivery                                *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Nodes (iCluster 2.1+)
     FHINODNN21 IF   E           K DISK

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #ACTIVE         C                   CONST('*ACTIVE')
     D #INACTIVE       C                   CONST('*INACTIVE')
     D #UNKNOWN        C                   CONST('*UNKNOWN')
     D #YES            C                   CONST('*YES')
     D #NO             C                   CONST('*NO')

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *
      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
      * ------------------------------------------------------------ *
      * Parameter lists                                              *
      * ------------------------------------------------------------ *
      * Entry parameters
     C     *Entry        Plist
     C                   Parm                    pNode             8            * Node name
     C                   Parm                    pCurSts          10            * Current status
     C                   Parm                    pLstSts          10            * Last known status
     C                   Parm                    pLsnAct           4            * Listener active

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Initialisation
     C                   Eval      pCurSts = #UNKNOWN                           * *UNKNOWN
     C                   Eval      pLstSts = *Blanks                            * Last known status
     C                   Eval      pLsnAct = #NO                                * Listener active

      * Get specified node
     C     pNode         Chain     HINODNN@                           95
     C                   If        not *In95
      * Try to connect to remote port to see if node is active
     C                   Call      'HRTVNODST3'
     C                   Parm                    NODE                           * Node
     C                   Parm                    LOCNAME                        * Remote host name
     C                   Parm      PORT          PortWY            5 0          * Remote port
     C                   Parm                    pLsnAct                        * Listner active
     C                   Eval      pLstSts = STATUS                             * Last known status
     C                   If        STATUS = #ACTIVE                             * *ACTIVE
     C                             and pLsnAct = #YES                           * Listener active
     C                   Eval      pCurSts = STATUS                             * Current status
     C                   EndIf                                                  * *ACTIVE
     C                   EndIf                                                  * Node found

     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
