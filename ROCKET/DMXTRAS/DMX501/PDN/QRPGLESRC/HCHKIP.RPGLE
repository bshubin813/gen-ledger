      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HCHKIP          *PGM RPG                          *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20071205 FK  Initial delivery                                *
      * ============================================================ *
     HDatEdit(*YMD) DftActGrp(*No) ActGrp(*Caller)

      * ------------------------------------------------------------- *
      * Files                                                         *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D V4StkSts        s              1    Dim(5) CtData
     D V4StkStsNam     s             10    Dim(5) Alt(V4StkSts)
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Copy in the API data structures for Network status APIs
     D/COPY QSYSINC/QRPGLESRC,QTOCNETSTS

      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data

      * Message data
     D MsgDta          DS           500

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * Retrieve TCP/IP attributes
     D RtvTCPA         Pr                  ExtProc('QtocRtvTCPA')
     D  RTRcvVar                  65535a   Options(*VARSIZE)
     D  RTRcvLen                     10i 0 Const
     D  RTFmt                         8a   Const                                * Format
     D  RTAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D CurDTS          s               z                                        * Current timestamp
     D ActDTS          s               z                                        * Activity timestamp
     D x               s              2  0                                      * Array index
     D StkSts          s              1                                         * Stack status
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    pIPV4STS         10            * IP V4 Status
     C                   Parm                    pActDTS          26            * Active since DTS
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Reset                   ActDTS                         * Activity timestamp
     C                   Time                    CurDTS                         * Current timestamp
      * Now call API to retrieve TCP/IP attributes
     C                   Reset                   APIErr                         * API Error
     C                   CallP     RtvTCPA(QTOA0100:
     C                                     %Size(QTOA0100):
     C                                     'TCPA0100':
     C                                     APIErr)
      * Determine status
     C                   Eval      x=1                                          * Array index
     C                   Move      QTOPIPSS      StkSts                         * Stack status char
     C     StkSts        LookUp    V4StkSts(x)                            20
     C                   If        *In20                                        * Found
     C                   MoveL(p)  V4StkStsNam(x)pIPV4STS                       * IP V4 Status
      * If IP active, determine since when
     C                   If        QTOPIPSS=1                                   * Active
     C     CurDTS        SubDur    QTOHLA:*s     ActDTS                 99
     C                   EndIf                                                  * Active
     C                   MoveL     ActDTS        pActDTS                        * Activity DTS
     C                   EndIf                                                  * Found
     C                   Return
**CtData V4StkSts
0*INACTIVE
1*ACTIVE
2*STARTING
3*ENDIMMED
4*ENDCNTRLD
