      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONJOBP1       *PGM                              *
      *            Purges records from HMONJOB file older than the   *
      *            specified number of days (update date).           *
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
      * 20050708 FK  Initial delivery                                *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Monitored jobs on the system
     FHMONJOB   UF   E           K DISK

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D ApiErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(ApiErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID

      * Message data
     D MSGDTA          DS          1024

      * ------------------------------------------------------------ *
      * Constants                                                    *
      * ------------------------------------------------------------ *
      * Job statuses
     D #JOBQ           C                   CONST('*JOBQ  ')
     D #ACTIVE         C                   CONST('*ACTIVE')
     D #OUTQ           C                   CONST('*OUTQ  ')
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
     D MSGDTLSM        s              9b 0                                      * Message data lengt
     D STCCTRSM        s              9b 0                                      * Stack counter
     D NBRMQSM         s              9b 0                                      * Number of MSGQ

      * Miscellaneous
     D DTS             S               Z                                        * Date-time stamp
     D CurDTS          S               Z                                        * Current date-time
     D PrgDTS          S               Z                                        * Purge date-time

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
     C                   Parm                    ApiErr                         * API Error

      * Entry parameters
     C     *Entry        Plist
     C                   Parm                    pSysNam           8            * System name
     C                   Parm                    pPrgAge           5 0          * Purge age
     C                   Parm                    pNbrDlt           9 0          * # of deleted

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
     C                   Eval      pNbrDlt = 0                                  # of deleted records
     C                   Time                    CurDts
     C     CurDts        SubDur    pPrgAge:*D    PrgDts                         * Purge DTS
     C     pSysNam       SetLL     MONJOB@
     C     pSysNam       ReadE     MONJOB@                                95
     C                   DoW       not *In95
     C                   If        MJJSTS = #OUTQ                               * Ended job
     C                             and MJRCHG < PrgDts                          * Older than prgdat
     C                   Delete    MONJOB@
     C                   Eval      pNbrDlt = pNbrDlt + 1                        # of deleted records
     C                   EndIf
     C     pSysNam       ReadE     MONJOB@                                95
     C                   EndDo

     C                   SetOn                                        LR

      * ------------------------------------------------------------ *
      * *InzSR - Initialisation subroutine                           *
      * ------------------------------------------------------------ *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------ *
      * SRSNDPM - Send program message                               *
      * ------------------------------------------------------------ *
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
     C                   Z-Add     0             AEBytPvd                       * Bytes provide
     C                   Z-Add     1024          MSGDTLSM                       * Message data lengt
     C                   Call      'QMHSNDPM'    pSNDPM                         * Send program msg
      * Reset values for next message send
     C                   MoveL     *BLANKS       MSGFSM                         * Message file
     C                   MoveL     *BLANKS       MSGTYPSM                       * Message type
     C                   MoveL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   EndSR

