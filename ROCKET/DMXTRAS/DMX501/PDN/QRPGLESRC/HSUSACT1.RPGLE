      * ============================================================ *
      * Object:    HSUSACT1        *PGM RPG                          *
      *            Reads all records in the HAMOBJ file and calls    *
      *            the HSUSACT2 program to suspend or activate the   *
      *            given file.                                       *
      *                                                              *
      * Synopsis:  See Command HSUSACTF.                             *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20000410 FK  Initial delivery                                *
      * 20000422 FK  Also allow logical files to be suspended/act.   *
      * 20000705 FK  Process through logical file                    *
      * 20010113 FK  Error if target is not Primary role             *
      * 20020626 FK  Do not search for target/group if already spec. *
      * 20030605 FK  Enable for iCluster                             *
      * 20030711 FK  Wrong field checked for *ALLSUS                 *
      *              Allow library selection with *ALLSUS            *
      * 20111224 FK  Remove HA                                       *
      * ============================================================ *
      * Mirrored objects (source)
     FHUMOBOL   IF   E           K DISK
      * Targets defined in HA Suite
     FHUTGTTI   IF   E           K DISK
      * Groups defined in HA Suite
     FHUGRPGI   IF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * File qualifier
     D FILQPA          DS            20
     D  FILNPA                       10
     D  FILLPA                       10
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
      * Binary fields for QMHSNDPM API
     D                 DS
     D  MSGDTL                 1      4B 0                                      * Bytes provided
     D  STCCTRSM               5      8B 0                                      * Bytes provided
      * Message data
     D MSGDTA          DS           256
      * Message data for message SAF0005
     D  FILQMD                 1     20                                         * Qualified file
     D  TGTNMD                21     30                                         * Target name
     D  GRPNMD                31     40                                         * Group name
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #ACT            C                   CONST('*ACT')
     D #SUS            C                   CONST('*SUS')
     D #YES            C                   CONST('*YES')
     D #NO             C                   CONST('*NO ')
     D #ALLSUS         C                   CONST('*ALLSUS')
     D #NONE           C                   CONST('*NONE')
     D #ICLUSTER       C                   CONST('*ICLUSTER')
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
      * Key list for reading the HAMOBJ records
     C     LIMHAM        KLIST
     C                   KFLD                    FILNPA                         * File name
     C                   KFLD                    FILLPA                         * File library
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * QMHSNDPM - Send program message
     C     @SNDPM        PLIST
     C                   PARM                    MSGIDSM           7            * Message ID
     C                   PARM                    MSGFSM           20            * Message file
     C                   PARM                    MSGDTA                         * Message data
     C                   PARM                    MSGDTL                         * Message data lengt
     C                   PARM                    MSGTYPSM         10            * Message type
     C                   PARM                    STCENTSM         10            * Call stack entry
     C                   PARM                    STCCTRSM                       * Stack counter
     C                   PARM                    MSGKEYSM          4            * Message key
     C                   PARM                    APIERR            8            * API Error
      * Entry parameters
     C     *ENTRY        PLIST
     C                   PARM                    FILQPA           20            * File qualified
     C                   PARM                    ACTPA             4            * Action
     C                   PARM                    RFSHPA            4            * Refresh?
     C                   PARM                    ICGRPA           10            * iCluster group
     C                   PARM                    ICLIPA           10            * iCluster library
     C                   PARM                    RTNCDE            7            * Return code
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Z-Add     0             NBRPWY            3 0          * Number processed
     C                   MoveL     *BLANKS       RTNCDE                         * Return code
      * Read all records in HAMOBJ and process
     C     FILNPA        IfEQ      #ALLSUS
     C                   Read      HUMOBOL@                               95
     C                   Else
     C     LIMHAM        SetLL     HUMOBOL@
     C     LIMHAM        ReadE     HUMOBOL@                               95
     C                   EndIf
     C     *IN95         DowEQ     *OFF
      * Only process the records for which file and library are the same or suspended
     C     FILNPA        IfEQ      OBJNAME                                      * Name
     C     FILLPA        AndEQ     OBJLIB                                       * Library
     C     OBJTYPE       AndEQ     'DB-FILE'                                    * DB File
     C     FILNPA        OrEQ      #ALLSUS                                      * *ALLSUS
     C     FILLPA        AndEQ     OBJLIB                                       * Library
     C     STATE         ANDEQ     'SUS'                                        * Suspended
     C     OBJTYPE       AndEQ     'DB-FILE'                                    * DB File
     C     FILNPA        OrEQ      #ALLSUS                                      * *ALLSUS
     C     FILLPA        AndEQ     *Blanks                                      * Library
     C     STATE         ANDEQ     'SUS'                                        * Suspended
     C     OBJTYPE       AndEQ     'DB-FILE'                                    * DB File
      * Get Group name if required
     C     GRPID         Chain     HUGRPGI                            94        * Get Group
      * Suspend or activate file
     C     RTNCDE        IfEQ      *BLANKS                                      * No error
     C                   Call      'HSUSACT2'
     C                   Parm                    GRPNAME                        * Group name
     C                   Parm                    OBJNAME                        * Object name
     C                   Parm                    OBJLIB                         * Object library
     C                   Parm                    ACTPA                          * Action
     C                   Parm                    RFSHPA                         * Refresh?
     C                   Parm                    ICLIPA                         * iCluster library
     C                   Parm                    RTNCDE                         * Return code
     C                   Add       1             NBRPWY                         * Number processed
     C                   EndIf                                                  * No error
     C                   EndIf
     C     FILNPA        IfEQ      #ALLSUS
     C                   Read      HUMOBOL@                               95
     C                   Else
     C     LIMHAM        ReadE     HUMOBOL@                               95
     C                   EndIf
     C                   EndDo
      * If number of processed 0 --> return error message
     C     NBRPWY        IfEQ      0
     C                   MoveL     'SAF0002'     RTNCDE
     C                   EndIf
      * End program
     C                   SetOn                                        LR
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
     C                   Z-ADD     256           MSGDTL                         * Message data lengt
     C                   CALL      'QMHSNDPM'    @SNDPM                         * Send program msg
      * Reset values for next message send
     C                   MOVEL     *BLANKS       MSGFSM                         * Message file
     C                   MOVEL     *BLANKS       MSGTYPSM                       * Message type
     C                   MOVEL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-ADD     0             STCCTRSM                       * Stack counter
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
