      * ============================================================ *
      * Object:    TPUTDTS1        *PGM RPG                          *
      *            Writes the current date-time into the TPUTDTS     *
      *            file.                                             *
      *                                                              *
      * Synopsis:  See command.                                      *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20010531 FK  Initial delivery                                *
      * ============================================================ *
     HDATFMT(*ISO)
      * Date-time stamps
     FTPUTDTS   UF A E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Program variables
     D WrkDTS          S               Z                                        * Date-time stamp
     D WrkDat          S               D                                        * Date stamp
     D WrkTim          S               T                                        * Time stamp
      * Time data structure
     D TimeDS          DS            14
     D  DTSVal                 1     14  0                                      * Time/date
     D  TimVal                 1      6  0                                      * Time
     D  DatVal                 7     14  0                                      * Date
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available
      * Binary fields for QMHSNDPM API
     D                 DS
     D  MSGDTL                 1      4B 0                                      * Bytes provided
     D  STCCTRSM               5      8B 0                                      * Bytes provided
      * Message data
     D MSGDTA          DS           512
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
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
      * Entry parameters
     C     *ENTRY        PLIST
     C                   PARM                    KEYPA            10            * Key value
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Retrieve current date/time
     C                   TIME                    DTSVal                         * Time
     C     *ISO          Move      DatVal        WrkDat                         * Date stamp
     C                   Move      TimVal        WrkTim                         * Time stamp
     C                   Move      WrkDat        WrkDTS                         * Date-time stamp
     C                   Move      WrkTim        WrkDTS                         * Date-time stamp
      * Write/update the time stamp
     C     KEYPA         CHAIN     TPUTDTS@                           95
     C     *In95         IfEQ      *On
     C                   MoveL     KEYPA         KEY                            * Key
     C                   MoveL     WrkDTS        DTS                            * Date-time stamp
     C                   Write     TPUTDTS@
     C                   Else
     C                   MoveL     KEYPA         KEY                            * Key
     C                   MoveL     WrkDTS        DTS                            * Date-time stamp
     C                   Update    TPUTDTS@
     C                   Endif
      * End program
     C                   RETURN
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
