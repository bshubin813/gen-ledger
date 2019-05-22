      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HWRKALR2        *PGM                              *
      *            Add alert destination                             *
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
      * 20050127 FK  Initial delivery.                               *
      * 20060102 FK  New fields for character set                    *
      * 20070810 FK  *EMAIL is default                               *
      * ============================================================ *
      * ================================================================= *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Alert destinations
     FHMONALRU  IF A E           K DISK
     F                                     INFDS(DBFINF)
      * Display file
     FHWRKALR2D CF   E             WORKSTN
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
     D #MSGQ           C                   CONST('*MSGQ')                       * Message queue
     D #EMAIL          C                   CONST('*EMAIL')                      * E-Mail
     D #ALL            C                   CONST('*ALL')                        * *ALL
     D #LIBL           C                   CONST('*LIBL')                       * *LIBL
     D #USASCII        C                   CONST('us-ascii')                    * us-ascii
     D #7BIT           C                   CONST('7bit')                        * 7-bit encoding

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

     D DBFRRNPA        S              9  0                                      * DBF RRN
     D RtnCdePA        S              7                                         * Return code

     D FstTme          S              1N                                        * First time
     D Exit            S              1N                                        * Exit request
     D Reload          S              1N                                        * Reload subfile
     D DfrCnf          S              1N                                        * Defer confirm

      * ------------------------------------------------------------------- *
      * Key lists                                                           *
      * ------------------------------------------------------------------- *
      * Chain to HMONALRU
     C     ChnALR        KList
     C                   KFld                    UTLIDRC                        * Utility ID
     C                   KFld                    UTLALRRC                       * Utility alert
     C                   KFld                    DSTTYPRC                       * Destination type
     C                   KFld                    ALALRDST                       * Alert destination

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

      * Entry parameter list
     C     *Entry        PList
     C                   Parm                    RtnCdePA                       * Return code

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
     C                   EndIf                                                  * First time
      * Load record
     C                   ExSR      RCLDRC

      *
      * Do while no exit requested
      *
      * Do while no exit requested
     C                   DoW       not Exit                                     * No exit requested
     C                             or DfrCnf                                    * Confirm deferred
     C                   Eval      *In99 = *Off                                 * General error
     C                   Eval      DfrCnf = *Off                                * Defer confirme
      * Display record
     C                   ExSR      RCDPRC
      * Perform actions, regardless of errors
     C                   ExSR      RCPRNC
      * Check record
     C                   ExSR      RCCKRC
      * No exit or reload request, continue processing
     C                   If        not *In99 and                                * General error
     C                             not Reload and                               * Reload subfile
     C                             not Exit                                     * Exit requested
      * Process record
     C                   ExSR      RCPRRC
      * Final processing for record
     C                   If        not DfrCnf                                   * Defer confirm
     C                   ExSR      RCFIPR
     C                   EndIf                                                  * Defer confirm
     C                   EndIf                                                  * Exit/reload
     C                   EndDo                                                  * Exit = *OFF
      * Final processing
     C                   ExSR      PGFIPR
      *
     C                   Seton                                        LR

      * ============================================================= *
      * End of main line - Subroutine section                         *
      * ============================================================= *

      * ------------------------------------------------------------- *
      * Program initialization (initial call)                         *
      * ------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   Eval      FstTme = *On                                 * First time
     C                   EndSR

      * ------------------------------------------------------------- *
      * Program initialization (every call)                           *
      * ------------------------------------------------------------- *
     C     PGINPG        BegSR
      * Initialize fields
     C                   Eval      Exit = *Off                                  * Exit program
     C                   Eval      DfrCnf = *Off                                * Defer confirm
     C                   Eval      Reload = *Off                                * Reload subfile
     C                   Eval      RtnCdePA = *Blanks                           * Return code
     C                   EndSR

      * ------------------------------------------------------------- *
      * Program final processing                                      *
      * ------------------------------------------------------------- *
     C     PGFIPR        BegSR
     C                   EndSR

      * ------------------------------------------------------------- *
      * Display record                                                *
      * ------------------------------------------------------------- *
     C     RCDPRC        BegSR
     C                   Write     #MSGCTL
     C                   ExFMT     PNLRCD
      * Clear message subfile
     C                   ExSR      SRCLPM
     C                   EndSR

      * ------------------------------------------------------------- *
      * Load record                                                   *
      * ------------------------------------------------------------- *
     C     RCLDRC        BegSR
      * Initialise display indicators
     C                   Eval      *In41 = *Off                                 * MSGQ error
     C                   Eval      *In42 = *Off                                 * E-Mail error
     C                   Select
      * Get database record (if required)
      * Initialise screen fields if record must be added
     C                   When      '1' = '1'
     C                   Eval      UTLIDRC = #ALL                               * Utility ID
     C                   Eval      UTLALRRC = #ALL                              * Utility alert
     C                   Eval      DSTTYPRC = #EMAIL                            * Destination type
     C                   Eval      MSGQRC = *Blanks                             * Message queue
     C                   Eval      MSGQLRC = #LIBL                              * Queue library
     C                   Eval      EMAILRC = *Blanks                            * E-Mail address
     C                   Eval      EMLCHRRC=#USASCII                            * Character set
     C                   Eval      EMLCTERC=#7BIT                               * Contents Transf
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------- *
      * Final processing for record                                   *
      * ------------------------------------------------------------- *
     C     RCFIPR        BegSR
     C                   Eval      RtnCdePA =*Blanks                            * Return code
     C                   Eval      Exit = *On                                   * Exit
     C                   EndSR

      * ------------------------------------------------------------- *
      * Perform actions, regardless of subfile control errors         *
      * ------------------------------------------------------------- *
     C     RCPRNC        BegSR
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
      * Check record                                                  *
      * ------------------------------------------------------------- *
     C     RCCKRC        BegSR
      * Check required fields, dependent on destination type
     C                   Select
      * Message queue
     C                   When      DSTTYPRC = #MSGQ                             * *MSGQ
     C                   Eval      ALALRDST = MSGQRC + MSGQLRC                  * Message queue
     C                   If        MSGQRC = *Blanks
      * Send error message "MSGQ is required"
     C                   Eval      MSGIDSM = 'WAL0011'                          * Message ID
     C                   Eval      MSGFSM = #MSGF                               * Message file
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      STCENTSM = '*'                               * Stack entry
     C                   Eval      STCCTRSM = 0                                 * Stack counter
     C                   ExSR      SRSNDPM
     C                   Eval      *In41 = *On                                  * MSGQ error
     C                   Eval      *In99 = *On                                  * Error
     C                   EndIf
      * E-Mail address
     C                   When      DSTTYPRC = #EMAIL                            * *EMAIL
     C                   Eval      ALALRDST = %TrimR(EMAILRC)                   * E-Mail address
     C                   If        EMAILRC = *Blanks
      * Send error message "EMAIL is required"
     C                   Eval      MSGIDSM = 'WAL0012'                          * Message ID
     C                   Eval      MSGFSM = #MSGF                               * Message file
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      STCENTSM = '*'                               * Stack entry
     C                   Eval      STCCTRSM = 0                                 * Stack counter
     C                   ExSR      SRSNDPM
     C                   Eval      *In42 = *On                                  * E-Mail error
     C                   Eval      *In99 = *On                                  * Error
     C                   EndIf
     C                   EndSL
      * If no error yet, check if record already exists
     C                   If        not *In99                                    * Error
     C     ChnALR        SetLL     HMONALRUR                              96
     C                   If        *In96                                        * Record exists
      * Send error message "Record already exists"
     C                   Eval      MSGIDSM = 'WAL0013'                          * Message ID
     C                   Eval      MSGFSM = #MSGF                               * Message file
     C                   Eval      MSGTYPSM = #DIAG                             * Message type
     C                   Eval      STCENTSM = '*'                               * Stack entry
     C                   Eval      STCCTRSM = 0                                 * Stack counter
     C                   ExSR      SRSNDPM
     C                   Eval      *In99 = *On                                  * Error
     C                   EndIf
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------- *
      * Process record                                                *
      * ------------------------------------------------------------- *
     C     RCPRRC        BegSR
      * Process record dependent passed subfile option
     C                   Select
     C                   When      '1' = '1'                                    * Add
     C                   Eval      ALUTLID = UTLIDRC                            * Utility ID
     C                   Eval      ALUTLALR = UTLALRRC                          * Utility alert
     C                   Eval      ALDSTTYP = DSTTYPRC                          * Destination type
     C                   Eval      ALEMLCHR = EMLCHRRC                          * Character set
     C                   Eval      ALEMLCTE = EMLCTERC                          * CTE
     C                   Write     HMONALRUR
     C                   EndSL
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
