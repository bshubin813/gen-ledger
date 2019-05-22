      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HWRKJRN1        *PGM                              *
      *            Shows work-with screen for journals.              *
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
      * 20070424 FK  Initial delivery.                               *
      * 20111220 FK  Remove HA/CDC                                   *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HAlwNull(*USRCTL)

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * List of journals
     FHLSTJRN   IF   E           K DISK    UsrOpn
      * Work-with panel
     FHWRKJRN1D CF   E             WORKSTN
     F                                     SFILE(SFLRCD:#RRN)
     F                                     INFDS(DSPFINF)

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

      * Program status data structure
     D PGMDS          SDS
     D  ##PGM            *PROC                                                  * Procedure name
     D  ##STS            *STATUS                                                * Status code
     D  ##PARMS          *PARMS                                                 * Num passed parms

      * Display file information data structure
     D DSPFINF         DS
     D  CSRLOC               370    371B 0
     D  SFLRRN               378    379B 0

      * Selection fields
     D SLTDS           DS            20

      * Saved selection fields
     D SAVDS           DS            20

      * Message data
     D MSGDTA          DS          1024
      * Message data for WJR0001
     D  MDTSLibs                    275    Overlay(MSGDTA:1)

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

      * Send Program Message
     D RmvPgmMsg       Pr                  ExtPgm('QMHRMVPM')
     D  RMCllStkEnt                  10a   Const                                * Call stack entry
     D  RMCllStkCnt                  10i 0 Const                                * Call stack count
     D  RMMsgKey                      4a   Const                                * Message Key
     D  RMMsgClr                     10a   Const                                * Messages to remove
     D  RMAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #SFLPG          C                   CONST(11)
     D #SFLSZ          C                   CONST(11)
     D #ALL            C                   CONST('*ALL')
     D #YES            C                   CONST('*YES')
      *
      * Message files
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

     D #IC             C                   Const('*iC')
     D #None           C                   Const('*NONE')

     D #QAUDJRN        C                   Const('QAUDJRN')
     D #QSYS           C                   Const('QSYS')

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *
      * API parameter values
     D MSGDTLSM        S              9B 0                                      * Message data lengt
     D STCCTRSM        S              9B 0                                      * Stack counter
     D NBRMQSM         S              9B 0                                      * Number of MSGQ
     D STCCTRRM        S              9B 0                                      * Stack counter

     D CSP             S              4  0                                      * Current Sfl Page
     D Reload          S              1N                                        * Reload subfile
     D DfrCnf          S              1N                                        * Defer confirm
     D FstTme          S              1N                                        * First time
     D RdspSC          S              1N                                        * Redisplay control
     D RcdSlt          S              1N                                        * Record selected
     D Exit            S              1N                                        * Exit request
     D CnlDlt          S              1N                                        * Delete cancelled
     D #RRMax          S              5  0                                      * Maximum RRN
     D SFLPGS          S              5  0                                      * Subfile page size
     D RRNSav          S              5  0                                      * Saved RRN
     D NR              S              5  0                                      * Loaded records

     D i               s             10i 0                                      * Index
     D QAudJrnWY       s             10a   Inz(#QAUDJRN)
     D QSysWY          s             10a   Inz(#QSYS)

      * ------------------------------------------------------------------- *
      * Key lists                                                           *
      * ------------------------------------------------------------------- *
     C     ChnAud        Klist
     C                   KFld                    QSysWY                         * Audit library
     C                   KFld                    QAudJrnWY                      * Audit journal

      * ------------------------------------------------------------------- *
      * Parameter lists                                                     *
      * ------------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    JRNPA            10            * Journal
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    CHKIPA            4            * Check iCluster
     C                   Parm                    ICLIBPA          10            * iCluster library
     C                   Parm                    RTNCDE            7            * Return code

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Perform initial actions
     C                   ExSR      PGINPG
      *
      * Process only if first time entered
      *
     C                   If        FstTme                                       * First time
     C                   Eval      FstTme = *Off                                * First time
      * Perform initial subfile load
     C                   ExSR      SFRLSF
     C                   EndIF

      * Do while no exit requested
     C                   DoW       not Exit                                     * No exit requested
      * Display subfile
     C                   ExSR      SFDPSF
      * Perform actions, regardless of subfile control errors
     C                   ExSR      SCPRNC
      * No exit or reload request, continue processing
     C                   If        not Exit and not Reload
     C
      * Process subfile control
     C                   Eval      *In99 = *Off                                 * General error
     C                   Eval      DfrCnf = *Off                                * Defer confirm
     C                   Eval      RdspSC = *Off                                * Redisplay control
     C                   ExSR      SCPRSC
      * Process subfile records if requested and no errors or reload
     C                   If        not *In99 and                                * General error
     C                             not Reload and                               * Reload subfile
     C                             not RdspSC and                               * Redisplay control
     C                             #RRN <> 0                                    * Subfile not empty
     C                   Eval      CSP = 0                                      * Current subfile rc
     C                   ReadC     SFLRCD                                 96
     C                   DoW       not *In96 and                                * Changed rcd and
     C                             not *In99                                    * No error
     C                   ExSR      SRPRSR
     C                   If        *In99                                        * Error
      * First error detected --> Set current subfile page
     C                   If        CSP = 0                                      * Current subfile p
     C                   Eval      CSP = #RRN                                   * RRN
     C                   EndIf
     C                   Eval      *In84 = *On                                  * SFLNXTCHG
     C                   EndIF
     C                   Update    SFLRCD
      * If current subfile page not set, set to last processed record
     C                   If        CSP = 0                                      * Current subfile p
     C                   Eval      CSP = #RRN                                   * RRN
     C                   EndIf
      * If no error, read next changed
     C                   If        not *In99                                    * No error
     C                   ReadC     SFLRCD                                 96
     C                   EndIf
     C                   EndDo
      * If Current subfile page set --> Set Relative record number
     C                   If        CSP <> 0
     C                   Eval      #RRN = CSP
     C                   EndIf
     C                   EndIf
      * No error, reload or defer confirm -> final processing
     C                   If        not *In99 and                                * General error
     C                             not Reload and                               * Reload subfile
     C                             not DfrCnf and                               * Defer confirm
     C                             not RdspSC                                   * Redisplay control
     C                   ExSR      SRFIPR
     C                   EndIf
     C                   EndIf                                                  * Exit = *OFF
      * Subfile reload requested ?
     C                   If        Reload
     C                   ExSR      SFRLSF
     C                   EndIf                                                  * Reload subfile
     C                   EndDo                                                  * Exit = *OFF
      * Final processing
     C                   ExSR      PGFIPR
      *
     C                   SetOn                                        LR
      * ============================================================= *
      * End of main line - Subroutine section                         *
      * ============================================================= *
      * ------------------------------------------------------------- *
      * Program initialization (initial call)                         *
      * ------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   Eval      FstTme = *On                                 * First time
      * Initialize data structures
     C                   Clear                   SLTDS                          * Sel. fields
     C                   Clear                   SAVDS                          * Saved sel. f.
      * Clear subfile control record
     C                   Clear                   SFLCTL
     C                   EndSR

      * ------------------------------------------------------------- *
      * Program initialization (every call)                           *
      * ------------------------------------------------------------- *
     C     PGINPG        BegSR
      * Initialize fields
     C                   Eval      Exit = *Off                                  * Exit program
     C                   Eval      DfrCnf = *Off                                * Defer confirm
     C                   Eval      Reload = *Off                                * Reload subfile
     C                   Eval      RdspSC = *Off                                * Redisplay control
     C                   Eval      RtnCde = *Blanks                             * Return code
     C                   EndSR

      * ------------------------------------------------------------- *
      * Program final processing                                      *
      * ------------------------------------------------------------- *
     C     PGFIPR        BegSR
     C                   EndSR

      * ------------------------------------------------------------- *
      * Clear subfile                                                 *
      * ------------------------------------------------------------- *
     C     SFCLSF        BegSR
     C                   Write     PNLRCD
     C                   MoveA     '011'         *In(31)
     C                   Write     SFLCTL
     C                   Eval      #RRN = 0                                     * RRN
     C                   Eval      #RRMax = 0                                   * Maximum RRN
     C                   MoveA     '010'         *In(31)
     C                   EndSR

      * ------------------------------------------------------------- *
      * Display subfile                                               *
      * ------------------------------------------------------------- *
     C     SFDPSF        BegSR
     C                   If        #RRN <> 0
     C                   Eval      *In31 = *on                                  * Display subfile
     C                   EndIf
     C                   Write     PNLRCD
     C                   Write     #MSGCTL
     C                   ExFmt     SFLCTL
      * Maintain subfile page where possible
     C                   If        SFLRRN <> 0
     C                   Eval      #RRN = SFLRRN
     C                   EndIf
      * If cursor has been positioned, reset
     C                   Move      *Off          *IN29
      * Clear message subfile
     C                   Clear                   APIErr
     C                   CallP     RmvPgmMsg('*':0:*Blanks:#ALL:APIErr)
     C                   EndSR

      * ------------------------------------------------------------- *
      * Reload subfile                                                *
      * ------------------------------------------------------------- *
     C     SFRLSF        BegSR
      * First close file
     C                   If        %Open(HLSTJRN)
     C                   Close     HLSTJRN
     C                   EndIf
      * Call program to (re-)load contents of HWRKJRN file
     C                   Call      'HWRKJRN1R'
     C                   Parm                    JRNPA                          * Journal
     C                   Parm                    JRNLPA                         * Journal library
     C                   Parm                    CHKIPA                         * Check iCluster
      * Open file
     C                   Open      HLSTJRN
      * Clear subfile
     C                   ExSR      SFCLSF
      * Initialise subfile control
     C                   ExSR      SFINSC
      * Load subfile (# of records: #SFLSZ)
     C                   Eval      Reload = *On                                 * Reload subfile
     C                   ExSR      SRLDPG
     C                   Eval      Reload = *Off                                * Reload subfile
      * Send information message "No data to display" if applicable
     C                   If        #RRMax = 0
     C                   CallP     SndPgmMsg('DMX0021':#HAUMSGF:MsgDta:
     C                                     %len(MsgDta):#INFO:'*':0:
     C                                     MsgKey:APIErr)
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------- *
      * Load subfile page                                             *
      * ------------------------------------------------------------- *
     C     SRLDPG        BegSR
      * Initially load subfile size, subsequent loads only subfile page
     C                   If        Reload
     C                   Eval      SFLPGS = #SFLSZ
     C                   Else
     C                   Eval      SFLPGS = #SFLPG
     C                   EndIf
      * Start writing from highest subfile record number
     C                   Eval      #RRN = #RRMax
     C                   Eval      RRNSAV = 0
      * Start loading the number of specified records
     C                   Eval      NR = 1                                       * Loaded records
     C                   DoW       NR <= SFLPGS
      * Start with QSYS/QAUDJRN if listed
     C                   If        Reload and NR=1                              * First rcd in sfl
     C     ChnAud        Chain     LSTJRNR                            95
     C                   If        *In95                                        * Record not found
     C     *Loval        SetLL     LSTJRNR
     C                   Read      LSTJRNR                                95
     C                   Else
     C     *Loval        SetLL     LSTJRNR                                      * Position for nxt
     C                   EndIf                                                  * Record not found
     C                   Else                                                   * First rcd in sfl
     C                   Read      LSTJRNR                                95
     C                   EndIf                                                  * First rcd in sfl
     C                   If        *In95
     C                   Leave
     C                   EndIf
      * Initialize subfile record
     C                   ExSR      SRINSR
      * Process subfile record selection
     C                   Eval      RcdSlt = *on                                 * Record selected
     C                   ExSR      SRSLSR
     C                   If        RcdSlt
      * Write subfile record
     C                   Eval      NR = NR + 1
     C                   Eval      #RRN = #RRN + 1
     C                   Write     SFLRCD
      * Set cursor to first loaded subfile record
     C                   If        NR = 2
     C                   Eval      RRNSav = #RRN
     C                   Eval      CSP = #RRN
     C                   EndIf
     C                   EndIf                                                  * Record selected
     C                   EndDo                                                  * Subfile page size
      * Save highest subfile record number
     C                   Eval      #RRMax = #RRN
      * Make sure that loaded subfile page is shown
     C                   If        Reload and
     C                             #RRN <> 0
     C                   Eval      #RRN = 1
     C                   EndIf
      * Set cursor to first loaded subfile record
     C                   If        RRNSav <> 0
     C                   Eval      #RRN = RRNSav
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------- *
      * Final processing                                              *
      * ------------------------------------------------------------- *
     C     SRFIPR        BegSR
     C                   Eval      Exit = *On
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process subfile control initialisation                        *
      * ------------------------------------------------------------- *
     C     SFINSC        BegSR
      * Populate subfile control field journal specified
     C                   Eval      SCJRN=%trimR(JRNLPA)+'/'+JRNPA
      * Populate subfile control field with products used
     C                   Eval      SCPRD = *Blanks
     C                   If        CHKIPA=#YES                                  * CHKIC(*YES)
     C                   If        SCPRD<>*Blanks                               * Not empty
     C                   Eval      SCPRD=%TrimR(SCPRD)+', '+#IC                 * Concatenate *iC
     C                   Else
     C                   Eval      SCPRD=#IC                                    * *iC
     C                   EndIf                                                  * Not empty
     C                   EndIf                                                  * CHKIC(*YES)
      * If no product specified, show *NONE
     C                   If        SCPRD=*Blanks                                * Empty
     C                   Eval      SCPRD=#None
     C                   EndIf                                                  * Empty
      * Send information about products in library list
     C                   If        CHKIPA=#YES                                  * CHKIC(*YES)
     C                   CallP     SndPgmMsg('WJR0003':#HAUMSGF:ICLIBPA:
     C                                     10:#INFO:'*':0:
     C                                     MsgKey:APIErr)
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------- *
      * Perform actions, regardless of subfile control errors         *
      * ------------------------------------------------------------- *
     C     SCPRNC        BegSR
     C                   Select
      * Exit
     C                   When      *In03
     C                   Eval      Exit = *On
      * Reload
     C                   When      *In05
     C                   Eval      Reload = *On                                 * Reload subfile
      * Cancel
     C                   When      *In12
     C                   Eval      Exit = *On
      * Command line
     C                   When      *In21
     C                   Call      'QUSCMDLN'
      *
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process subfile control                                       *
      * ------------------------------------------------------------- *
     C     SCPRSC        BEGSR
      * Process command keys before change of selection is detected
     C                   Select
      * Process Home key
     C                   When      *In25                                        * Home
     C                   Eval      RdspSC = *On                                 * Redisplay control
     C                   Eval      *In29 = *On
     C                   Eval      *In25 = *Off                                 * Home key
     C                   EndSL
      * Reset all error indicators for subfile control
      * Have the selection fields been changed ?
     C                   If        SAVDS <> SLTDS
     C                   Eval      Reload = *On                                 * Reload subfile
     C                   Eval      SAVDS = SLTDS
     C                   EndIf
      * Process command keys after check of control fields
     C                   Select
     C                   When      *In28                                        * Page down
     C                   ExSR      SRLDPG
     C                   Eval      RdspSC = *On                                 * Redisplay control
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process subfile record initialisation                         *
      * ------------------------------------------------------------- *
     C     SRINSR        BegSR
     C                   Eval      *In43 = *Off
     C                   Eval      *In84 = *Off
     C                   Eval      OPTISR = *Blanks                             * Subfile option
      * Fill subfile fields according to database fields
     C                   Eval      SRJRN = LJJRN                                * Journal
     C                   Eval      SRJRNL = LJJRNL                              * Journal library
     C                   Eval      SRJRNTYP = LJJRNTYP                          * Journal type
     C                   Eval      SRNBRRCV = LJNBRRCV                          * # of receivers
     C                   Eval      SRTOTSIZGB = LJTOTSIZGB                      * Total size in GB
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process subfile record selection                              *
      * ------------------------------------------------------------- *
     C     SRSLSR        BegSR
      * If loaded record is QSYS/QAUDJRN and not first record in sfl --> skip
     C                   If        SRJRN=#QAUDJRN and SRJRNL=#QSYS and NR<>1    * QAUDJRN/QSYS
     C                   Eval      RcdSlt=*Off                                  * Skip record
     C                   EndIf                                                  * QAUDJRN/QSYS
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process subfile record                                        *
      * ------------------------------------------------------------- *
     C     SRPRSR        BegSR
     C                   Eval      *In43 = *Off                                 * Option error
      * Perform checks
     C                   If        OPTISR <> *Blanks
     C                   Select
      * Process option
     C                   When      OPTISR <> ' '                                * HDLTJRNRCV
     C                   Call      'HWRKJRN1O'                          99
     C                   Parm                    SRJRN                          * Journal
     C                   Parm                    SRJRNL                         * Journal library
     C                   Parm                    CHKIPA                         * Check iCluster
     C                   Parm                    OPTISR                         * Subfile option
      *
     C                   EndSL
      * Handle potential error after option
     C                   If        *In99
     C                   Eval      *In43 = *On
     C                   Else
     C                   Eval      OPTISR = *Blanks
     C                   EndIf
     C                   Eval      DfrCnf = *On                                 * Defer confirm
     C                   EndIf                                                  * Non-blank option
     C                   EndSR

      * ============================================================= *
      * End of standard subroutines - User subroutines section        *
      * ============================================================= *
