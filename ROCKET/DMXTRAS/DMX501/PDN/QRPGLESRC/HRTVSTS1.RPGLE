      * ============================================================ *
      * Object:    HRTVSTS         *PGM RPG                          *
      *            Returns the status of the passed iCluster group   *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20000404 FK  Initial delivery                                *
      * 20000705 FK  Use logical files                               *
      * 20010623 FK  Start from beginning of file in HUPID           *
      *              *APY process consists of TUP and OTAR           *
      * 20040506 FK  *RCV doesn't return status of receive jobs      *
      *              Also include *SND for groups that don't have a  *
      *              QAUDJRN scraper                                 *
      *              HADDAS job nog checked for *SND                 *
      *              Optimise to stop when first process found       *
      * 20111217 FK  Remove HA                                       *
      * ============================================================ *
      * Targets defined in HA Suite
     FHUTGTTI   IF   E           K DISK
      * Targets defined in HA Suite (by name)
     FHUTGTTN   IF   E           K DISK
      * Groups defined in HA Suite
     FHUGRPGI   IF   E           K DISK
      * Target/Group combinations
     FHUFGTTG   IF   E           K DISK
      * Target/Group/Data journal combinations
     FHUDGTTG   IF   E           K DISK
      * Target Status file (not keyed)
     FHUPID     IF   E             DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available
      * Receiver variable for QUSRJOBI format JOBI0100
     D JOBI0100        DS            86
     D  BYTRTNJI                      9B 0                                      * Bytes returned
     D  BYTAVLJI                      9B 0                                      * Bytes available
     D  JOBNAMJI                     10                                         * Job name
     D  JOBUSRJI                     10                                         * Job user
     D  JOBNBRJI                      6                                         * Job number
     D  JOBINTJI                     16                                         * Job internal id
     D  JOBSTSJI                     10                                         * Job status
     D  JOBTYPJI                      1                                         * Job type
     D  JOBSUBJI                      1                                         * Job subtype
     D  JOBRSVJI                      2                                         * Job reserved
     D  JOBRUNJI                      9B 0                                      * Job run priority
     D  JOBTIMJI                      9B 0                                      * Job time slice
     D  JOBDWTJI                      9B 0                                      * Job default wait
     D  JOBPRGJI                     10                                         * Job purge
      * Binary fields for QMHSNDPM API
     D                 DS
     D  MSGDTL                 1      4B 0                                      * Bytes provided
     D  STCCTRSM               5      8B 0                                      * Bytes provided
      * Binary fields for QUSRJOBI API
     D                 DS
     D  JIRCVL                 1      4B 0                                      * Receiver var len
      * Message data
     D MSGDTA          DS           512
      * Message data for MIF0004
     D  TGTNMD                 1     10                                         * Target name
     D  GRPNMD                11     20                                         * Group name
     D  IFSPMD                21    276                                         * IFS path
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #ANY            C                   CONST('*ANY')
     D #SND            C                   CONST('*SND')
     D #RCV            C                   CONST('*RCV')
     D #APY            C                   CONST('*APY')
     D #MON            C                   CONST('*MON')
     D #INT            C                   CONST('*INT')
     D #ACTIVE         C                   CONST('*ACTIVE')
     D #INACTIVE       C                   CONST('*INACTIVE')
     D #ERROR          C                   CONST('*ERROR')
      * Message values
     D #MSGF           C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #DIAG           C                   CONST('*DIAG')
     D #EXT            C                   CONST('*EXT')
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Target/group combinations
     C     LIMGT         KLIST
     C                   KFLD                    TGTID                          * Target identifier
     C                   KFLD                    GRPID                          * Group identifier
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * QMHSNDPM - Send program message
     C     $SNDPM        PLIST
     C                   PARM                    MSGIDSM           7            * Message ID
     C                   PARM                    MSGFSM           20            * Message file
     C                   PARM                    MSGDTA                         * Message data
     C                   PARM                    MSGDTL                         * Message data lengt
     C                   PARM                    MSGTYPSM         10            * Message type
     C                   PARM                    STCENTSM         10            * Call stack entry
     C                   PARM                    STCCTRSM                       * Stack counter
     C                   PARM                    MSGKEYSM          4            * Message key
     C                   PARM                    APIERR            8            * API Error
      * QUSRJOBI - Retrieve job information
     C     $RTVJI        PLIST
     C                   PARM                    JOBI0100                       * Receiver variable
     C                   PARM      86            JIRCVL                         * Receiver var len
     C                   PARM      'JOBI0100'    JIFMT             8            * Format name
     C                   PARM                    JIJOBQ           26            * Qualified job name
     C                   PARM                    JIJOBI           16            * Internal job id
     C                   PARM                    APIERR            8            * API Error
      * Entry parameters
     C     *ENTRY        PLIST
     C                   PARM                    GRPNPA           10            * Group name
     C                   PARM                    PRCPA             4            * Process to check
     C                   PARM                    JNAMPA           10            * Job name
     C                   PARM                    JUSRPA           10            * Job user
     C                   PARM                    JNBRPA            6            * Job number
     C                   PARM                    STSPA            10            * Status
     C                   PARM                    RTNCDE            7            * Return code
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   MOVEL     *BLANKS       RTNCDE                         * Return code
     C                   CLEAR                   JNAMPA                         * Job name
     C                   CLEAR                   JUSRPA                         * Job user
     C                   CLEAR                   JNBRPA                         * Job number
     C                   MOVEL     #ERROR        STSPA                          * Status
     C                   MOVE      *OFF          FNDWY             1            * Target/group found
     C                   MOVE      *OFF          ACTWY             1            * Active
      *
      * Determine activity of processes on SOURCE?
      *
     C     PRCPA         IFEQ      #SND                                         * Send
     C     PRCPA         OREQ      #ANY                                         * Any process
      * Read all records in the HUFGTTG file
     C     *LOVAL        SETLL     HUFGTTG@
     C                   READ      HUFGTTG@                               95
     C     *IN95         DOWEQ     *OFF
     C     ACTWY         AndNE     *On
     C     STATUS        IFNE      1                                            * Not idle
      * Retrieve the Target
     C     TGTID         CHAIN     HUTGTTI@                           94
     C     *IN94         IFEQ      *OFF
      * Retrieve the Group
     C     GRPID         CHAIN     HUGRPGI@                           94
     C     *IN94         IFEQ      *OFF
      * Is the target/group viable for selection
     C     GRPNPA        IFEQ      #ANY                                         * *ANY
     C     GRPNAME       OREQ      GRPNPA                                       * Selected
      * There is at least on combination of target/group
     C                   MOVE      *ON           FNDWY                          * Target/group found
      * Check that the target/group is active for MRJOBID
     C                   MOVEL     MRJOBID       JOBIWY           16            * Job identifier
     C                   EXSR      SRCKAC                                       * Check activity
      * If active --> Set general status value
     C     TGACWY        IFEQ      *ON                                          * Active
     C                   MOVE      *ON           ACTWY                          * Target/group activ
      * If MRJOBID not active --> check status of DASJOBID
     C                   ELSE
      * Check that the target/group is active for DASJOBID
     C                   MOVEL     DASJOBID      JOBIWY           16            * Job identifier
     C                   EXSR      SRCKAC                                       * Check activity
      * If active --> Set general status value
     C     TGACWY        IFEQ      *ON                                          * Active
     C                   MOVE      *ON           ACTWY                          * Target/group activ
     C                   ENDIF                                                  * Active
     C                   ENDIF                                                  * Active
     C                   ENDIF                                                  * Group selected
     C                   ENDIF                                                  * Group found
     C                   ENDIF                                                  * Target found
     C                   ENDIF                                                  * Group not idle
     C                   READ      HUFGTTG@                               95
     C                   ENDDO
      * Check data journal scraper processes (process all records in HADGT)
     C     ACTWY         IfNE      *On                                          * Still not active
     C     *LOVAL        SETLL     HUDGTTG@
     C                   READ      HUDGTTG@                               95
     C     *IN95         DOWEQ     *OFF
     C     ACTWY         AndNE     *On
      * Retrieve the Target
     C     TGTID         CHAIN     HUTGTTI@                           94
     C     *IN94         IFEQ      *OFF
      * Retrieve the Group
     C     GRPID         CHAIN     HUGRPGI@                           94
     C     *IN94         IFEQ      *OFF
      * Is the target/group viable for selection
     C     GRPNPA        IFEQ      #ANY                                         * *ANY
     C     GRPNAME       OREQ      GRPNPA                                       * Selected
      * There is at least on combination of target/group
     C                   MOVE      *ON           FNDWY                          * Target/group found
      * Check that the target/group is active for SFPJOBID
     C                   MOVEL     SFPJOBID      JOBIWY           16            * Job identifier
     C                   EXSR      SRCKAC                                       * Check activity
      * If active --> Set general status value
     C     TGACWY        IFEQ      *ON                                          * Active
     C                   MOVE      *ON           ACTWY                          * Target/group activ
      * If SFPJOBID not active --> check status of DJSJOBID
     C                   ELSE
      * Check that the target/group is active for DJSJOBID
     C                   MOVEL     DJSJOBID      JOBIWY           16            * Job identifier
     C                   EXSR      SRCKAC                                       * Check activity
      * If active --> Set general status value
     C     TGACWY        IFEQ      *ON                                          * Active
     C                   MOVE      *ON           ACTWY                          * Target/group activ
     C                   ENDIF                                                  * Active
     C                   ENDIF                                                  * Active
     C                   ENDIF                                                  * Group selected
     C                   ENDIF                                                  * Group found
     C                   ENDIF                                                  * Target found
     C                   READ      HUDGTTG@                               95
     C                   ENDDO
     C                   EndIf                                                  * Not Active
     C                   ENDIF                                                  * Send process
      *
      * Determine activity of apply processes
      *
     C     ACTWY         IfNE      *On                                          * Still not active
     C     PRCPA         IFEQ      #APY                                         * Apply
     C     PRCPA         OREQ      #ANY                                         * Any process
      * Read all records in the HUPID file
     C     1             SETLL     HUPID@
     C                   READ      HUPID@                                 95
     C     *IN95         DOWEQ     *OFF
     C     ACTWY         AndNE     *On
      * Is the target/group viable for selection
     C     GRPNPA        IFEQ      #ANY                                         * *ANY
     C     GRPNAME       OREQ      GRPNPA                                       * Selected
      * Only process records for processes OTAR and TUP
     C     PIDPRC        IFEQ      'OTAR'                                       * Object apply
     C     PIDPRC        OREQ      'TUP'                                        * Apply process
      * There is at least on combination of target/group
     C                   MOVE      *ON           FNDWY                          * Target/group found
      * Check that the target/group is active for PID
     C                   MOVEL     PID           JOBIWY           16            * Job identifier
     C                   EXSR      SRCKAC                                       * Check activity
      * If active --> Set general status value
     C     TGACWY        IFEQ      *ON                                          * Active
     C                   MOVE      *ON           ACTWY                          * Target/group activ
     C                   ENDIF                                                  * Active
     C                   ENDIF                                                  * ORCV or TUP prc
     C                   ENDIF                                                  * Group selected
     C                   READ      HUPID@                                 95
     C                   ENDDO
     C                   ENDIF                                                  * Apply process
     C                   EndIf                                                  * Not Active
      *
      * Determine activity of receive processs
      *
     C     ACTWY         IfNE      *On                                          * Still not active
     C     PRCPA         IFEQ      #RCV                                         * Receive
     C     PRCPA         OREQ      #ANY                                         * Any process
      * Read all records in the HUPID file
     C     1             SETLL     HUPID@
     C                   READ      HUPID@                                 95
     C     *IN95         DOWEQ     *OFF
     C     ACTWY         AndNE     *On
      * Is the target/group viable for selection
     C     GRPNPA        IFEQ      #ANY                                         * *ANY
     C     GRPNAME       OREQ      GRPNPA                                       * Selected
      * Only process records for processes OTAR and TUP
     C     PIDPRC        IFEQ      'ORCV'                                       * Object receive
     C     PIDPRC        OREQ      'DASR'                                       * Receive for DAS
     C     PIDPRC        OREQ      'SFPR'                                       * Receive for SFP
     C     PIDPRC        OREQ      'DJSR'                                       * Receive for DJS
      * There is at least on combination of target/group
     C                   MOVE      *ON           FNDWY                          * Target/group found
      * Check that the target/group is active for PID
     C                   MOVEL     PID           JOBIWY           16            * Job identifier
     C                   EXSR      SRCKAC                                       * Check activity
      * If active --> Set general status value
     C     TGACWY        IFEQ      *ON                                          * Active
     C                   MOVE      *ON           ACTWY                          * Target/group activ
     C                   ENDIF                                                  * Active
     C                   ENDIF                                                  * ORCV or TUP prc
     C                   ENDIF                                                  * Group selected
     C                   READ      HUPID@                                 95
     C                   ENDDO
     C                   ENDIF                                                  * Apply process
     C                   EndIf                                                  * Not Active
      *
      * Return parameters based on what has been found
      *
     C     FNDWY         IFEQ      *ON                                          * Target/group found
     C     ACTWY         IFEQ      *ON                                          * Active
     C                   MOVEL(P)  #ACTIVE       STSPA                          * Status
     C                   ELSE
     C                   MOVEL(P)  #INACTIVE     STSPA                          * Status
     C                   ENDIF
     C                   ELSE
     C                   MOVEL(P)  #ERROR        STSPA                          * Status
     C                   MOVEL     'RST0001'     RTNCDE                         * Return code
     C                   ENDIF
      * End program
     C                   RETURN
      * ------------------------------------------------------------------- *
      * SRCKAC - Check target/group is active                               *
      * ------------------------------------------------------------------- *
     C     SRCKAC        BEGSR
      * Initialise
     C                   MOVE      *OFF          TGACWY            1            * Target group act.
      * Check that the MRJOBID is active
     C                   Z-ADD     8             BPVDAE                         * Bytes provided
     C                   MOVEL     #INT          JIJOBQ                         * Qualified job ID
     C                   MOVEL     JOBIWY        JIJOBI                         * Internal job ID
     C                   CALL      'QUSRJOBI'    $RTVJI                         * Retrieve job info
     C     BAVLAE        IFEQ      0                                            * Bytes available
     C                   MOVEL     JOBNAMJI      JNAMPA                         * Job name
     C                   MOVEL     JOBUSRJI      JUSRPA                         * Job user
     C                   MOVEL     JOBNBRJI      JNBRPA                         * Job number
     C     JOBSTSJI      IFEQ      #ACTIVE                                      * Status = *ACTIVE
     C                   MOVE      *ON           TGACWY            1            * Target group act.
     C                   ENDIF                                                  * Job active
     C                   ENDIF                                                  * Job exists
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * SRSNDPM - Send program message                                      *
      * ------------------------------------------------------------------- *
     C     SRSNDPM       BEGSR
      * Determine message file value for QMHSNDPM API
     C     MSGFSM        IFEQ      *BLANKS
     C                   MOVEL     #MSGF         MSGFSM                         * Default msgf
     C                   ENDIF
      * Set default message type
     C     MSGTYPSM      IFEQ      *BLANKS                                      * Message type
     C                   MOVEL     #DIAG         MSGTYPSM                       * Message type
     C                   ENDIF
      * Determine stack entry/counter value, based on message type
     C                   SELECT
     C     STCENTSM      WHENNE    *BLANKS                                      * Stack entry
     C     MSGTYPSM      WHENEQ    #STATUS                                      * Status message
     C                   MOVEL(P)  #EXT          STCENTSM                       * Stack entry
     C                   Z-ADD     0             STCCTRSM                       * Stack counter
     C                   OTHER
     C                   MOVEL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-ADD     1             STCCTRSM                       * Stack counter
     C                   ENDSL
      * Send program message
     C                   Z-ADD     0             BPVDAE                         * Bytes provide
     C                   Z-ADD     512           MSGDTL                         * Message data lengt
     C                   CALL      'QMHSNDPM'    $SNDPM                         * Send program msg
      * Reset values for next message send
     C                   MOVEL     *BLANKS       MSGFSM                         * Message file
     C                   MOVEL     *BLANKS       MSGTYPSM                       * Message type
     C                   MOVEL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-ADD     0             STCCTRSM                       * Stack counter
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
