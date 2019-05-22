      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HWRKALR1        *PGM                              *
      *            Shows work-with screen for alert destinations.    *
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
      * 20050125 FK  Initial delivery.                               *
      * 20050127 FK  Add delete subfile                              *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Alert destinations (no key)
     FHMONALR   UF   E             DISK
      * Alert destinations (keyed)
     FHMONALRU  IF   E           K DISK
     F                                     INFDS(DBFINF)
      * Work-with panel
     FHWRKALR1D CF   E             WORKSTN
     F                                     SFILE(SFLRCD:#RRN)
     F                                     SFILE(DLTRCD:#RRNDLT)
     F                                     INFDS(DSPFINF)

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Program status data structure
     D PGMDS          SDS
     D  ##PGM            *PROC                                                  * Procedure name
     D  ##STS            *STATUS                                                * Status code
     D  ##PARMS          *PARMS                                                 * Num passed parms

      * Display file information data structure
     D DSPFINF         DS
     D  CSRLOC               370    371B 0
     D  SFLRRN               378    379B 0

      * Database file information data structure
     D DBFINF          DS
     D  DBFRRN               397    400I 0                                      * DBF RRN

      * Selection fields
     D SLTDS           DS            20
     D  UTLIDSC                1     10                                         * Utlity ID

      * Saved selection fields
     D SAVDS           DS            20
     D  UTLIDSV                1     10                                         * Saved utlity ID

      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available

      * Message data
     D MSGDTA          DS          1024
     D  DUMMY                  1      1
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #SFLPG          C                   CONST(12)
     D #SFLSZ          C                   CONST(12)
     D #MSGQ           C                   CONST('*MSGQ')                       * Message queue
     D #EMAIL          C                   CONST('*EMAIL')                      * E-Mail
     D #ALL            C                   CONST('*ALL')                        * *ALL
      *
      * Message files
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
     D #RRMaxDlt       S              5  0                                      * Max. delete RRN
     D SFLPGS          S              5  0                                      * Subfile page size
     D RRNSav          S              5  0                                      * Saved RRN
     D NR              S              5  0                                      * Loaded records
     D RtnCde          S              7                                         * Return code

      * ------------------------------------------------------------------- *
      * Parameter lists                                                     *
      * ------------------------------------------------------------------- *
      * Parameter list for QMHRMVPM API
     C     pRMVPM        PList
     C                   Parm                    MSGQRM           10            * Call message queue
     C                   Parm                    STCCTRRM                       * Call stack counter
     C                   Parm                    MSGKEYRM          4            * Message key
     C                   Parm                    MSGRMVRM         10            * Messages to remove
     C                   Parm                    APIERR                         * API Error

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
     C                   Parm                    APIERR            8            * API Error

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
      * If records selected for delete --> process
     C                   If        #RRMaxDlt <> 0 and                           * Records deleted
     C                             not Reload                                   * Reload subfile
      * Display
     C                   ExSR      SFDPSFDL
      * Check if ctions, regardless of subfile control errors
     C                   ExSR      SCPRNCDL
      * If delete not cancelled, process
     C                   If        not CnlDlt                                   * Delete cancelled
     C                   ReadC     DLTRCD                                 96
     C                   DoW       not *In96                                    * Changed rcd
     C                   ExSR      SRPRSRDL                                     * Delete record
     C                   ReadC     DLTRCD                                 96
     C                   EndDo
     C                   EndIf                                                  * Delete cancelled
     C                   Eval      Reload = *On                                 * Reload subfile
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
      * Clear delete subfile                                          *
      * ------------------------------------------------------------- *
     C     SFCLSFDL      BegSR
     C                   Write     PNLRCD
     C                   MoveA     '011'         *In(36)
     C                   Write     DLTCTL
     C                   Eval      #RRNDlt = 0                                  * RRN
     C                   Eval      #RRMaxDlt = 0                                * Max. dlt sfl
     C                   MoveA     '010'         *In(36)
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
     C                   ExSR      SRCLPM
     C                   EndSR

      * ------------------------------------------------------------- *
      * Display delete subfiles                                       *
      * ------------------------------------------------------------- *
     C     SFDPSFDL      BegSR
     C                   Eval      CnlDlt = *Off                                * Cancel delete
     C                   If        #RRMaxDlt <> 0
     C                   Eval      *In36 = *On                                  * Display subfile
     C                   EndIf
     C                   Write     PNLDLT
     C                   ExFmt     DLTCTL
     C                   EndSR

      * ------------------------------------------------------------- *
      * Reload subfile                                                *
      * ------------------------------------------------------------- *
     C     SFRLSF        BegSR
      * Clear subfile
     C                   ExSR      SFCLSF
      * Clear delete subfile
     C                   ExSR      SFCLSFDL
      * Position to database record
     C     UTLIDSC       SetLL     HMONALRUR
      * Load subfile (# of records: #SFLSZ)
     C                   Eval      Reload = *On                                 * Reload subfile
     C                   ExSR      SRLDPG
     C                   Eval      Reload = *Off                                * Reload subfile
      * Send information message "No data to display" if applicable
     C                   If        #RRMax = 0
     C                   Eval      MSGIDSM = 'DMX0021'                          * Message ID
     C                   Eval      MSGFSM = #MSGF                               * Message file
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   Eval      STCENTSM = '*'                               * Stack entry
     C                   Eval      STCCTRSM = 0                                 * Stack counter
     C                   ExSR      SRSNDPM
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
     C                   Read      HMONALRUR                              95
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
      * Perform actions, regardless of subfile control errors         *
      * ------------------------------------------------------------- *
     C     SCPRNC        BegSR
     C                   Select
      * Exit
     C                   When      *In03
     C                   Eval      Exit = *On
      * Reload
     C                   When      *In05
     C                   Eval      Reload = *On
      * Cancel
     C                   When      *In12
     C                   Eval      Exit = *On
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------- *
      * Perform actions for delete subfile, no check control          *
      * ------------------------------------------------------------- *
     C     SCPRNCDL      BegSR
     C                   Select
      * Exit
     C                   When      *In03
     C                   Eval      CnlDlt = *On
      * Cancel
     C                   When      *In12
     C                   Eval      CnlDlt = *On
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
      * Process F6 key
     C                   When      *In06                                        * Add new
     C                   ExSR      USCK06
     C                   Eval      Reload = *On                                 * Reload subfile
     C                   ENDSL
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
     C                   Eval      DBFRRNSR = DBFRRN                            * RRN
     C                   Eval      UTLIDSR = ALUTLID                            * Utility ID
     C                   Eval      UTLALRSR = ALUTLALR                          * Utility alert
     C                   Eval      DSTTYPSR = ALDSTTYP                          * Destination type
      * Show alert destination based on destination type
     C                   Select
     C                   When      DSTTYPSR = #MSGQ                             * Message queue
     C                   Eval      ALRDSTSR =
     C                             %TrimR(%Subst(ALALRDST:11)) +
     C                             '/' + %TrimR(%Subst(ALALRDST:1:10))
     C                   Other                                                  * Other destination
     C                   Eval      ALRDSTSR = ALALRDST                          * Alert destination
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process subfile record selection                              *
      * ------------------------------------------------------------- *
     C     SRSLSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process subfile record                                        *
      * ------------------------------------------------------------- *
     C     SRPRSR        BegSR
     C                   Eval      *In43 = *Off                                 * Option error
      * Perform checks
     C                   If        OPTISR <> *Blanks
     C                   Select
      * Process delete
     C                   When      OPTISR = '4'                                 * Delete
      * Write record to delete subfile
     C                   Eval      *In85 = *On                                  * Sfl next change
     C                   Eval      #RRNDlt = #RRNDlt + 1                        * Current sfl rcd
     C                   Eval      #RRMaxDlt = #RRMaxDlt + 1                    * Max. sfl dlt
     C                   Write     DLTRCD                                       * Write dlt sfl rcd
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

      * ------------------------------------------------------------- *
      * Process delete subfile record                                 *
      * ------------------------------------------------------------- *
     C     SRPRSRDL      BegSR
     C     DBFRRNSR      Chain     HMONALRR                           94
     C  N94              Delete    HMONALRR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRCLPM - Clear program messages                                     *
      * ------------------------------------------------------------------- *
     C     SRCLPM        BegSR
      * Clear all messages from previous queue
     C                   Eval      MSGQRM = '*'                                 * Message queue
     C                   Eval      STCCTRRM = 0                                 * Stack counter
     C                   Eval      MSGRMVRM = #ALL                              * Messages to remove
     C                   Eval      MSGKEYRM = *Blanks                           * Message key
     C                   Clear                   APIERR
     C                   Call      'QMHRMVPM'    pRMVPM
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSNDPM - Send program message                                      *
      * ------------------------------------------------------------------- *
     C     SRSNDPM       BegSR
      * Determine message file value for QMHSNDPM API
     C     MSGFSM        IfEQ      *Blanks
     C                   MoveL     #MSGF         MSGFSM                         * Default msgf
     C                   EndIf
      * Set default message type
     C     MSGTYPSM      IfEQ      *Blanks                                      * Message type
     C                   MoveL     #DIAG         MSGTYPSM                       * Message type
     C                   EndIf
      * Determine stack entry/counter value, based on message type
     C                   SelecT
     C     STCENTSM      WhenNE    *Blanks                                      * Stack entry
     C     MSGTYPSM      WhenEQ    #STATUS                                      * Status message
     C                   MoveL(P)  #EXT          STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C     MSGTYPSM      WhenEQ    #INFO                                        * Status message
     C                   MoveL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-Add     1             STCCTRSM                       * Stack counter
     C                   Other
     C                   MoveL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-Add     1             STCCTRSM                       * Stack counter
     C                   EndSL
      * Send program message
     C                   Z-Add     0             BPVDAE                         * Bytes provide
     C                   Z-Add     1024          MSGDTLSM                       * Message data lengt
     C                   Call      'QMHSNDPM'    pSNDPM                         * Send program msg
      * Reset values for next message send
     C                   MoveL     *BLANKS       MSGFSM                         * Message file
     C                   MoveL     *BLANKS       MSGTYPSM                       * Message type
     C                   MoveL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   EndSR

      * ============================================================= *
      * End of standard subroutines - User subroutines section        *
      * ============================================================= *
      * ------------------------------------------------------------- *
      * USCK06 - Process command key 06                               *
      * ------------------------------------------------------------- *
     C     USCK06        BegSR
     C                   Call      'HWRKALR2'
     C                   Parm                    RtnCde                         * Return code
     C                   EndSR
