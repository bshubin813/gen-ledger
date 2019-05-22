      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONJOB1        *PGM                              *
      *            Read passed data queue and update the HMONJOB     *
      *            file with job status etc.                         *
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
      * 20050619 FK  Initial delivery                                *
      * 20050708 FK  Don't update ACTIVE to JOBQ or OUTQ to ACT/JOBQ *
      *              Write entry for current job when started/ended  *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HACTGRP(*CALLER)

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Monitored jobs on the system
     FHMONJOB   UF A E           K DISK

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * Convert date-time
     D CvtDT           PR                  ExtPgm('QWCCVTDT')
     D  CDInpFmt                     10a   Const
     D  CDInpVar                     17a   Const  Options(*VarSize)
     D  CDOutFmt                     10a   Const
     D  CDOutVar                     20a          Options(*VarSize)
     D  CDApiErr                     15a

      * Receive data queue entry
     D RcvDtaQe        Pr                  ExtPgm('QRCVDTAQ')
     D  RQName                       10a   Const                                * Data queue name
     D  RQLib                        10a   Const                                * Data queue lib
     D  RQDtaLen                      5p 0                                      * Data length
     D  RQDta                     32767a          Options(*VarSize)             * Data queue entry
     D  RQWait                        5p 0 Const                                * Wait time
     D  RQKeyOrder                    2a   Const  Options(*NoPass )             * Key order
     D  RQKeyLen                      3p 0 Const  Options(*NoPass )             * Key length
     D  RQKey                       256a   Const  Options(*VarSize: *NoPass)    * Key
     D  RQSndInLg                     3p 0 Const  Options(*NoPass)              * Send info length
     D  RQSndInfo                    44a          Options(*VarSize: *Nopass)    * Send info

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D ApiErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(ApiErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID

      * Data queue entry format for job notification message
     D NTFY0100        DS
     D  NYMsgId                      10a                                        * Message identifier
     D  NYMsgFmt                      2a                                        * Message format
     D  NYJobI                       16a                                        * Internal Job ID
     D  NYQualJob                    26a                                        * Qualified job
     D   NYJobNam                    10a   Overlay(NYQualJob:1)                 * Job name
     D   NYJobUsr                    10a   Overlay(NYQualJob:*Next)             * Job user
     D   NYJobNbr                     6a   Overlay(NYQualJob:*Next)             * Job number
     D  NYQualJobQ                   20a                                        * Qualified JobQ
     D   NYJobQ                      10a   Overlay(NYQualJobQ:1)                * Job queue
     D   NYJobQL                     10a   Overlay(NYQualJobQ:*Next)            * Job queue lib
     D  NYJobQueDts                   8a                                        * Job queued DTS
     D  NYJobStrDts                   8a                                        * Job started DTS
     D  NYJobEndDts                   8a                                        * Job ended DTS
     D  NYRsv01                       2a                                        * Reserved
     D  NYJobEndSev                  10i 0                                      * Job end severity
     D  NYJobPrcTim                  20i 0                                      * Job processing tim
     D  NYRsv02                      32a                                        * Reserved

      * Message data
     D MSGDTA          DS          1024

      * ------------------------------------------------------------ *
      * Constants                                                    *
      * ------------------------------------------------------------ *
     D #YES            C                   CONST('*YES')
     D #ALL            C                   CONST('*ALL      ')
     D #Stars          C                   CONST('******')
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
     D Error           s               n                                        * Error occurred
     D ShutDown        s               n                                        * Shutdown requested
     D FirstRun        s               n                                        * First run

     D DtqELen         s              5  0                                      * Entry length
     D MsgKey          s              4                                         * Message key
     D JobDts          s              8a                                        * Job DTS
     D JobCvtDts       s             20a   Inz(*All'0')                         * Converted DTS
     D DTS             S               Z                                        * Date-time stamp
     D CurDTS          S               Z                                        * Current date-time
     D DTS@            S             26                                         * Date-time stamp
     D i               s             10i 0                                      * Counter

     D DqKey           S              4    Inz('0000')                          * Data queue key
     D DqSndInfo       s              1a                                        * Send info

      * ------------------------------------------------------------ *
      * Key lists                                                    *
      * ------------------------------------------------------------ *
     C     ChnJob        KList
     C                   KFld                    pSysNam                        * System name
     C                   KFld                    NYJobNam                       * Job name
     C                   KFld                    NYJobUsr                       * Job user
     C                   KFld                    NYJobNbr                       * Job number

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
     C                   Parm                    pJobNam          10            * Current job name
     C                   Parm                    pJobUsr          10            * Current job user
     C                   Parm                    pJobNbr           6            * Current job number
     C                   Parm                    pDtaQ            10            * Data queue
     C                   Parm                    pDtaQL           10            * Data queue library

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *

      * If first run, write entry for this job
     C                   If        FirstRun                                     * First run
     C                   ExSR      SRUpdCur
     C                   Eval      FirstRun = *Off
     C                   EndIf                                                  * First run

      * Continue to process data queue entries until shutdown requested
     C                   Eval      i = 1
     C                   Eval      ShutDown = *Off                              * Not ended
     C                   DoW       not ShutDown                                 * No shutdown reques
     C                             and       i < 600                            * 1 hour
      * Receive data queue entry
     C                   CallP(e)  RcvDtaQe( pDtaQ                              * Data queue
     C                                     : pDtaQL                             * Data queue library
     C                                     : DtqELen                            * Entry length
     C                                     : NTFY0100                           * NTFY0100 message
     C                                     : 6                                  * Wait time
     C                                     : 'GT'                               * Greater then
     C                                     : %Size(DqKey)                       * Key length
     C                                     : DqKey                              * Key
     C                                     : 0                                  * Send info length
     C                                     : DqSndInfo                          * Send info
     C                                     )
      * If entry actually received, process
     C                   If        DtqELen > 0                                  * Entry received
      * Process notification entry
     C                   ExSR      SRPrcNfy
     C                   EndIf
      * Reset values for next call
     C                   Reset                   DqKey
      * Check if job shutdown was requested
     C                   ShtDn                                        50
     C                   If        *In50
     C                   Eval      ShutDown = *On
     C                   EndIf
     C                   Eval      i = i+1
     C                   EndDo                                                  * Shutdown request

      * If shut down, update entry for this job
     C                   If        ShutDown                                     * Shutdown
     C                   ExSR      SRUpdCur
     C                   EndIf                                                  * First run

     C                   Return

      * ------------------------------------------------------------ *
      * *InzSR - Initialisation subroutine                           *
      * ------------------------------------------------------------ *
     C     *InzSR        BegSR
     C                   Eval      FirstRun = *On                               * First run
     C                   EndSR

      * ------------------------------------------------------------ *
      * SRUpdCur - Update entry for current job                      *
      * ------------------------------------------------------------ *
     C     SRUpdCur      BegSR
      * Fill key fields with current job's key
     C                   Eval      NYJobNam = pJobNam                           * Job name
     C                   Eval      NYJobUsr = pJobUsr                           * Job user
     C                   Eval      NYJobNbr = #Stars                            * Job number
      * Retrieve current record (to lock)
     C     ChnJob        Chain     MONJOB@                            96
     C                   If        *In96
     C                   Clear                   MONJOB@
     C                   EndIf
      * Fill fields
     C                   Eval      MJSYSN = pSysNam                             * System name
     C                   Eval      MJJNAM = NYJobNam                            * Job name
     C                   Eval      MJJUSR = NYJobUsr                            * Job user
     C                   Eval      MJJNBR = NYJobNbr                            * Job number
     C                   Time                    MJRCHG                         * Record changed
      * Convert remainder of fields (dependent on First Run or Shutdown
     C                   Select
      * Job has just been started
     C                   When      FirstRun                                     * First run
     C                   Eval      MJJSTS = #ACTIVE                             * *ACTIVE
     C                   Eval      MJJACT = MJRCHG                              * Job became active
     C                   Clear                   MJJEND                         * Job ended
      * Shutdown request has been posed
     C                   When      ShutDown                                     * Shutdown requested
     C                   Eval      MJJSTS = #OUTQ                               * *OUTQ
     C                   Eval      MJJEND = MJRCHG                              * Job ended
     C                   EndSL
      * Now update or write record
     C                   If        *In96                                        * Not found
     C                   Write     MONJOB@
     C                   Else
     C                   Update    MONJOB@
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------ *
      * SRPrcNfy - Process job notification message                  *
      * ------------------------------------------------------------ *
     C     SRPrcNfy      BegSR
      * Retrieve current record (to lock)
     C     ChnJob        Chain     MONJOB@                            96
     C                   If        *In96
     C                   Clear                   MONJOB@
     C                   EndIf
      * Fill fields
     C                   Eval      MJSYSN = pSysNam                             * System name
     C                   Eval      MJJNAM = NYJobNam                            * Job name
     C                   Eval      MJJUSR = NYJobUsr                            * Job user
     C                   Eval      MJJNBR = NYJobNbr                            * Job number
     C                   Time                    MJRCHG                         * Record changed
      * Convert remainder of fields (dependent on status)
     C                   Select
      * Job is in job queue
     C                   When      DqKey = '0004'                               * Job queue
     C                   If        MJJSTS <> #ACTIVE and MJJSTS <> #OUTQ        * Not higher status
     C                   Eval      MJJSTS = #JOBQ                               * *JOBQ
     C                   EndIf                                                  * Not higher status
     C                   Eval      JobDts = NYJobQueDts                         * DTS job queued
     C                   ExSR      SRCvtDts
     C                   Eval      MJJBQN = NYJobQ                              * Job queue
     C                   Eval      MJJBQL = NYJobQL                             * Job queue library
     C                   Eval      MJJJBQ = DTS                                 * DTS job queued
      * Job has become active
     C                   When      DqKey = '0001'                               * Active
     C                   If        MJJSTS <> #OUTQ                              * Not higher status
     C                   Eval      MJJSTS = #ACTIVE                             * *ACTIVE
     C                   EndIf                                                  * Not higher status
     C                   Eval      JobDts = NYJobStrDts                         * DTS job started
     C                   ExSR      SRCvtDts
     C                   Eval      MJJACT = DTS                                 * DTS job started
      * Job has finished
     C                   When      DqKey = '0002'                               * Ended
     C                   Eval      MJJSTS = #OUTQ                               * *OUTQ
     C                   Eval      JobDts = NYJobEndDts                         * DTS job started
     C                   ExSR      SRCvtDts
     C                   Eval      MJJEND = DTS                                 * DTS job started
     C                   Eval      MJESEV = NYJobEndSev                         * Job end severity
     C                   Eval      MJPTIM = NYJobPrcTim                         * Job processing tim
     C                   EndSL
      * Now update or write record
     C                   If        *In96                                        * Not found
     C                   Write     MONJOB@
     C                   Else
     C                   Update    MONJOB@
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------ *
      * SRCvtDts - Convert date-time stamp                           *
      * ------------------------------------------------------------ *
     C     SRCvtDts      BegSR
      * Convert system date-time to date-time stamp
     C                   Eval      AEBytPvd = 15                                * Suppress error
     C                   CallP     CvtDT( '*DTS'                                * Source format
     C                                   : JobDts                               * Job date-time
     C                                   : '*YYMD'                              * Target format
     C                                   : JobCvtDts                            * Converted date-tim
     C                                   : ApiErr                               * API Error
     C                                   )
     C                   If        AEMsgId = *Blanks                            * No error
     C                   Eval      DTS@ = %subst(JobCvtDts:1:4) + '-' +
     C                                    %subst(JobCvtDts:5:2) + '-' +
     C                                    %subst(JobCvtDts:7:2) + '-' +
     C                                    %subst(JobCvtDts:9:2) + '.' +
     C                                    %subst(JobCvtDts:11:2) + '.' +
     C                                    %subst(JobCvtDts:13:2) + '.' +
     C                                    %subst(JobCvtDts:15:6)
     C                   MoveL     DTS@          DTS                            * Date-time stemp
     C                   Else
     C                   Clear                   DTS                            * Date-time stamp
     C                   EndIf
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

