      * ============================================================ *
      * Object:    HACTBSF3        *PGM RPG                          *
      *            Retrieves or writes an entry in the HACTBSF       *
      *            file.                                             *
      *                                                              *
      * Synopsis:  See Command HMONBSF                               *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20080213 FK  Initial delivery                                *
      * ============================================================ *
      * Journal positions
     FHACTBSF   UF A E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Rtv            C                   Const('*RTV')
     D #Set            C                   Const('*SET')
     D #NotFound       C                   Const('*NOTFND')
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
     C                   Parm                    pAction           4            * Action
     C                   Parm                    pICGroup         10            * iCluster group
     C                   Parm                    pRcv             10            * Journal receiver
     C                   Parm                    pRcvL            10            * Receiver library
     C                   Parm                    pSeq             20            * Sequence #
     C                   Parm                    pDTS             26            * Sequence timestamp
     C                   Parm                    pRtnCde           7            * Return code
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Clear                   pRtnCde                        * Return code
      * Depending on action, execute
     C                   Select
      * Retrieve the current values
     C                   When      pAction=#Rtv                                 * *RTV
     C     pICGroup      Chain(N)  ACTBSFR                            95
     C                   If        *In95                                        * Record not found
     C                   Eval      pRtnCde=#NotFound                            * Not found
     C                   Else
     C                   Eval      pRcv=ABRCV                                   * Receiver
     C                   Eval      pRcvL=ABRCVL                                 * Receiver library
     C                   Eval      pSeq=ABSEQ                                   * Sequence
     C                   MoveL     ABDTS         pDTS                           * Sequence timestamp
     C                   EndIf
      * Set the current values
     C                   When      pAction=#Set                                 * *SET
     C     pICGroup      Chain     ACTBSFR                            95
     C                   Eval      ABGROUP=pICGroup                             * iCluster group
     C                   Eval      ABRCV=pRcv                                   * Receiver
     C                   Eval      ABRCVL=pRcvL                                 * Receiver library
     C                   Eval      ABSEQ=pSeq                                   * Sequence
     C                   MoveL     pDTS          ABDTS                          * Sequence timestamp
     C                   Time                    ABUPDDTS                       * Updated
     C                   If        *In95                                        * Record not found
     C                   Write     ACTBSFR                                      * Write record
     C                   Else
     C                   Update    ACTBSFR                                      * Update record
     C                   EndIf
     C                   EndSL

     C                   Return
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
