      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HSETPOS1        *PGM RPG                          *
      *            Processes all records in HAPID and calls program  *
      *            to set positions based on selections              *
      *                                                              *
      * Synopsis:  See Command HSETPOS.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20070427 FK  Initial delivery                                *
      * 20111220 FK  Remove HA                                       *
      * ============================================================ *
      * HA/iC - Journals being received/applied
     FHUPIDTGJ  IF   E           K DISK

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data

      * Parameter data structures
     D JrnQPA          DS                                                       * Journal qualified
     D  JrnPA                        10a                                        * Journal
     D  JrnLPA                       10a                                        * Journal library

      * Message data
     D MsgDta          DS           500
      * Message data for LJR0001/LJR0002/LJR0003
     D  MDJrn                        10a   Overlay(MsgDta:1)                    * Journal name
     D  MDJrnL                       10a   Overlay(MsgDta:11)                   * Journal library

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
     D  SPAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * Message values
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

     D #ALL            c                   CONST('*ALL')

      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D MsgKey          s              4a                                        * Message key

     D NbrPos          s              5p 0                                      * # of positions
     D JrnSeq1         s             20  0                                      * Sequence + 1
     D JrnSeq@         s             20a                                        * Sequence
     D JrnSeq1@        s             20a                                        * Sequence + 1

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
     C                   Parm                    GRPIPA           10            * iCluster group
     C                   Parm                    ACTPA             4            * Action
     C                   Parm                    JRNQPA                         * Journal qualified
     C                   Parm                    RtnCdePA          7            * Return code
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Clear                   RtnCdePA
      * Process all active journals journals
     C     *Loval        SetLL     HUPID@
     C                   Read      HUPID@                                 95
     C                   DoW       not *In95
     C                   If        (GRPNAME=GRPIPA or GRPIPA=#ALL)              * iCluster ok
     C                   If        (((JRNNAME=JrnPA and JRNLIB=JrnLPA) or       * Journal ok
     C                               JrnPA=#ALL) and
     C                              (PIDPRC='TUP' or PIDPRC='OTAR'))            * Apply process
     C                   Eval      NbrPos=NbrPos + 1
      * Prepare journal sequence for passing to program
     C                   Move      LASTPOS       JrnSeq@                        * Last position
     C                   Eval      JrnSeq1=LASTPOS+1                            * Last position + 1
     C                   Move      JrnSeq1       JrnSeq1@                       * Last position + 1
      * Call program to check/set journal position
     C                   Call      'HSETPOS3'
     C                   Parm                    GRPNAME                        * Group
     C                   Parm                    ACTPA                          * Action
     C                   Parm                    JRNNAME                        * Journal
     C                   Parm                    JRNLIB                         * Journal library
     C                   Parm                    RCVNAME                        * Receiver
     C                   Parm                    RCVLIB                         * Receiver library
     C                   Parm                    JrnSeq@                        * Sequence
     C                   Parm                    JrnSeq1@                       * Sequence + 1
     C                   Parm                    RtnCde            7            * Return code
      * If error --> pass to calling program
     C                   If        RtnCde <> *Blanks                            * Error
     C                   Eval      RtnCdePA=RtnCde                              * Return code
     C                   EndIf                                                  * Error
     C                   EndIf                                                  * Journal/apply
     C                   EndIf                                                  * HA/iC ok
      * Process next entry
     C                   Read      HUPID@                                 95
     C                   EndDo
     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
