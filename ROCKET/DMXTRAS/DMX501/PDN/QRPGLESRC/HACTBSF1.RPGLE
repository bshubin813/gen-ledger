      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONBSF1        *PGM RPG                          *
      *            Splits the retrieved journal entry and calls the  *
      *            program to activate the IFS object if necessary.  *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20080213 FK  Initial delivery                                *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
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
     D  APAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * Sleep for microseconds
     D uSleep          Pr            10i 0 ExtProc('usleep')
     D                               10u 0 Value                                * Microseconds

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * *TYPE4 Journal entry
     D pJrnE4          DS
     D  JESeq                  6     15                                         * Sequence number
     D  JECde                 16     16                                         * Journal code
     D  JETyp                 17     18                                         * Entry type
     D  JEDTS                 19     44                                         * timestamp
     D  JEDTS19               19     37                                         * timestamp 19 dgt
     D  JENRRcv              171    180                                         * NR - Next receiver
     D  JENRRcvLib           181    190                                         * NR - Rcv library
     D  JEObjTyp             192    199                                         * Object type
     D  JEZCLen              888    889b 0                                      * IFS Path length
     D  JEZCPath             890   5887                                         * IFS Path
     D  JECOLen              958    959b 0                                      * IFS Path length
     D  JECOPath             960   5957                                         * IFS Path

      * RCVJRNE control parameter
     D pRcvJECtl       DS
     D  JCJrnE                 1      1                                         * Journal entry pass
     D  JCJrnAdl               2      2                                         * Additional JrnE
     D  JCJrn3                 3      3                                         * 3rd byte

      * LDA work area to transfer data between CL and RPG program
     D pLDA            DS                  DTAARA(*LDA)
     D  pTgtNam                1     10                                         * Target name
     D  pICGroup              11     20                                         * iCluster group
     D  pActTZC               21     24                                         * Activate T-ZC
     D  pAudTCO               25     28                                         * Audit T-CO
     D  pActTCO               29     32                                         * Activate T-CO
     D  pDelay@               33     35                                         * Delay
     D  pRcv                  36     45                                         * Receiver
     D  pRcvL                 46     55                                         * Receiver

      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data

      * Message data
     D MsgDts          DS

      * Work variables
     D MsgKey          s              4a                                        * Message key
     D IFSAct          s               n                                        * Activate?
     D IFSActPath      s           5000a   Varying                              * Activate path
     D IFSActSv        s           5000a   Varying                              * Saved activate pat
     D JEDTS19Sv       s             19a                                        * Saved DTS
     D JEDTS@          s               z                                        * JE timestamp
     D i               s             10i 0                                      * Counter
     D NewRcv          s             10                                         * New receiver
     D NewRcvLib       s             10                                         * New receiver lib
     D CurRcv          s             10                                         * Current rcv
     D CurRcvLib       s             10                                         * Current rcv lib
     D ActionWY        s              4                                         * Action
     D JESeq20         s             20                                         * 20-digit sequence
     D RtnCde          s              7                                         * Return code

     D TGTNWY          s             10a                                        * Target
     D GRPNWY          s             10a                                        * Group
     D IncWY           s              4a                                        * Include?
     D pDelay          s              3  0                                      * Delay in seconds
     D CurDTS          s               z                                        * Current timestamp
     D ChkDTS          s               z                                        * Check timestamp

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Set            c                   Const('*SET')

     D #Yes            c                   Const('*YES')
     D #No             c                   Const('*NO')
     D #ICluster       c                   Const('*ICLUSTER')

     D #STMF           c                   Const('*STMF')
     D #DIR            c                   Const('*DIR')

      * Commit journal position to file
     D #CmtPos         c                   Const(100)

      * Message values
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

      * ------------------------------------------------------------- *
      * Input specifications                                          *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    pJrnE4                         * *TYPE4 journal ent
     C                   Parm                    pRcvJECtl                      * RCVJRNE control

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Process entry if entry passed
     C                   If        JCJrnE = '1'                                 * Entry passed

     C                   Select

     C                   When      JECde='T'                                    * Object change
     C                   Eval      IFSAct=*Off
     C                   Select
      * Is the entry a T-CO entry that potentially requires action?
     C                   When      (JETyp='CO' and
     C                                (pActTCO=#YES or pAudTCO=#YES) and
     C                                (JEObjTyp=#STMF or JEObjTyp=#DIR))
     C                   Eval      IFSAct=*On
     C                   Eval      IFSActPath=%subst(JECOPath:1:JECOLen)
      * Is the entry a T-ZC entry that potentially requires action?
     C                   When      (JETyp='ZC' and pActTZC=#YES)
     C                             and (JEObjTyp=#STMF or JEObjTyp=#DIR)
     C                   Eval      IFSAct=*On
     C                   Eval      IFSActPath=%subst(JEZCPath:1:JEZCLen)
     C                   EndSL
      * If object in selection, check whether in scope
     C                   If        IFSAct                                       * Selected?
      * Call program that checks if the BSF object is in scope
     C                   Call      'HMTCBSF'
     C                   Parm                    pICGroup                       * Group
     C                   Parm                    IFSActPath                     * IFS object
     C                   Parm                    IncWY                          * Included?
      * In scope?
     C                   If        IncWY=#YES                                   * In scope
     C                   Eval      IFSAct=*On                                   * Activate
     C                   Else
     C                   Eval      IFSAct=*Off                                  * Ignore
     C                   EndIf                                                  * In scope
     C                   EndIf                                                  * Selected?
      * Now handle object if all criteria met
     C                   If        IFSAct and (IFSActPath<>IFSActSv             * Activate?
     C                             or JEDTS19<>JEDTS19Sv)                       * different second
      * Potentially, delay the job...
     C                   If        pDelay<>0                                    * Delay specified
     C                   ExSR      SRDelay                                      * Delay before send
     C                   EndIf
      * Activate object
     C                   Call      'HACTBSF2'
     C                   Parm                    pTgtNam                        * Target
     C                   Parm                    pICGroup                       * Group
     C                   Parm                    JETyp                          * Entry type
     C                   Parm                    pActTZC                        * Activate T-ZC
     C                   Parm                    pAudTCO                        * Audit T-CO
     C                   Parm                    pActTCO                        * Activate T-CO
     C                   Parm                    IFSActPath
     C                   Eval      IFSActSv=IFSActPath
     C                   Eval      JEDTS19Sv=JEDTS19
     C                   EndIf                                                  * Activate?

      * Process J journal entries
     C                   When      JECde='J'
      * If next receiver indicated --> only store the next receiver name
     C                   If        JETyp = 'NR'
     C                   Eval      NewRcv=JENRRcv                               * New receiver
     C                   Eval      NewRcvLib=JENRRcvLib                         * New receiver lib
     C                   EndIf
      * If previous receiver indicated --> update status in file
     C                   If        JETyp = 'PR'
     C                   Eval      CurRcv=NewRcv                                * New receiver
     C                   Eval      CurRcvLib=NewRcvLib                          * New receiver lib
     C                   Eval      i = #CmtPos                                  * Re-initiate progra
      * Indicate new receiver in job log
     C                   Reset                   APIErr                         * API Error
     C                   CallP     SndPgmMsg('MBS0003':#HAUMSGF:CurRcv+CurRcvLib
     C                                     :20:#INFO:'*':1:
     C                                     MsgKey:APIErr)
     C                   EndIf
     C                   EndSL
     C                   Eval      i=i+1
     C                   EndIf                                                  * Entry passed?
      * Check if job ended
     C                   ShtDn                                        99
      * Write current position to data area if commit or no additional entries
     C                   If        (JCJrnE = '1' and i>=#CmtPos) or             * Entry passed
     C                             JCJrnE='3' or *In99                          * No more entry
      * Update position file
     C                   Eval      JESeq20='0000000000'+JESeq                   * 20-digit sequence
     C                   Call      'HACTBSF3'
     C                   Parm      #Set          ActionWY
     C                   Parm                    pICGroup
     C                   Parm                    CurRcv                         * Current receiver
     C                   Parm                    CurRcvLib                      * Receiver library
     C                   Parm                    JESeq20                        * Sequence number
     C                   Parm                    JEDTS                          * J/E timestamp
     C                   Parm                    RtnCde                         * Return code
     C                   Eval      i = 0
     C                   EndIf
      * If job is to be shut down --> end receiving process
     C                   If        *In99
     C                   Eval      JCJrnE='9'                                   * End RCVJRNE
     C                   EndIf

     C                   Return

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   Eval      i = 0
     C                   In        pLDA
     C                   Eval      CurRcv=pRcv                                  * New receiver
     C                   Eval      CurRcvLib=pRcvL                              * New receiver lib
     C                   Move      pDelay@       pDelay                         * Delay in seconds
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRDelay - Delay the job until time reached                          *
      * ------------------------------------------------------------------- *
     C     SRDelay       BegSR
     C                   MoveL     JEDTS         JEDTS@
     C     JEDTS@        AddDur    pDelay:*s     ChkDTS                         * Add duration
     C                   Time                    CurDTS
     C                   DoW       CurDTS<ChkDTS
     C                             and not *In99
     C                   CallP     usleep(200000)                               * Sleep 0.2 seconds
     C                   Shtdn                                        99
     C                   Time                    CurDTS
     C                   EndDo
     C                   EndSR
