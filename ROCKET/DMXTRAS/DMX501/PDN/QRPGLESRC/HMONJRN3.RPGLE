      *CP: ALWNULL(*USRCTL) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMONJRN3        *PGM RPG                          *
      *            Processes the HJRNLAG file and reports replic-    *
      *            ation lags greater than the allowed lag           *
      *                                                              *
      * Synopsis:  See Command HMONJRNLAG.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20020911 FK  Initial delivery                                *
      * 20031006 FK  Send messages for measurement type only         *
      * ============================================================ *
      * Journal replication lag by System name, date/time, journal
     FHJRNLAGDJ IF   E           K DISK
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

      * Binary fields for QMHSNDPM API
     D                 DS
     D  MSGDTL                 1      4B 0                                      * Message data lengt
     D  STCCTRSM               5      8B 0                                      * Stack counter

      * Binary fields for QMHSNDM API
     D                 DS
     D  NBRMQSM                1      4B 0                                      * Number of MSGQ

      * Message data
     D MsgDta          DS          1024
      * Message data for MJL0006, MJL0008 and MJL0009
     D  JRNNMD                       10    Overlay(MsgDta:1)                    * Journal name
     D  JRNLMD                       10    Overlay(MsgDta:*Next)                * Journal library
     D  LAGMMD                       10i 0 Overlay(MsgDta:*Next)                * Lag in minutes
     D  ALWLMD                       10i 0 Overlay(MsgDta:*Next)                * Allowed lag
     D  DTSMMD                       26    Overlay(MsgDta:*Next)                * Measurement dts
     D  JE2RMD                       10    Overlay(MsgDta:*Next)                * J/E 2 receiver
     D  JE2LMD                       10    Overlay(MsgDta:*Next)                * J/E 2 receiver lib
     D  JE2SMD                       20    Overlay(MsgDta:*Next)                * J/E 2 sequence
     D  JE2TMD                       26    Overlay(MsgDta:*Next)                * J/E 2 date-time
     D  JE1RMD                       10    Overlay(MsgDta:*Next)                * J/E 1 receiver
     D  JE1LMD                       10    Overlay(MsgDta:*Next)                * J/E 1 receiver lib
     D  JE1SMD                       20    Overlay(MsgDta:*Next)                * J/E 1 sequence
     D  JE1TMD                       26    Overlay(MsgDta:*Next)                * J/E 1 date-time
     D  TGTNMD                       10    Overlay(MsgDta:*Next)                * Target name
     D  GRPNMD                       10    Overlay(MsgDta:*Next)                * Group name

      * ------------------------------------------------------------ *
      * Variables                                                    *
      * ------------------------------------------------------------ *
     D DTSMWY          S               Z                                        * Date-Time stamp

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * Message values
     D #MSGF           C                   CONST('HAUMSG    *LIBL     ')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #STATUS         C                   CONST('*STATUS')

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     PosLag        KList
     C                   KFld                    SYSNPA                         * System name
     C                   KFld                    TYPMPA                         * Measurement type
     C                   KFld                    DTSMWY                         * Measurement dts
     C     LimLag        KList
     C                   KFld                    SYSNPA                         * System name
     C                   KFld                    TYPMPA                         * Measurement type
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
      * QMHSNDM - Send nonprogram message
     C     $SNDM         PLIST
     C                   PARM                    MSGIDSM           7            * Message ID
     C                   PARM                    MSGFSM           20            * Message file
     C                   PARM                    MSGDTA                         * Message data
     C                   PARM                    MSGDTL                         * Message data lengt
     C                   PARM                    MSGTYPSM         10            * Message type
     C                   PARM                    MSGQSM           20            * Qualified MSGQ
     C                   PARM      1             NBRMQSM                        * Number of MSGQ
     C                   PARM      *Blanks       RPYQSM           20            * Reply MSGQ
     C                   PARM                    MSGKEYSM          4            * Message key
     C                   PARM                    APIERR            8            * API Error

      * Entry parameters
     C     *Entry        PList
     C                   Parm                    SYSNPA            8            * System name
     C                   Parm                    TYPMPA            4            * Measurement type
     C                   Parm                    DTSMPA           26            * Measurement dts
     C                   Parm                    ALRMPA           20            * Alert message queu
     C                   Parm                    ALWLPA            4 0          * Allowed repl. lag
     C                   Parm                    ALWSPA            4 0          * Allowed send lag
     C                   Parm                    ALWAPA            4 0          * Allowed apply lag

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Move      DTSMPA        DTSMWY                         * Date-Time stamp
      * Process all records for system/measurement type/measurement dts
     C     PosLag        SetLL     HJRNLAG@
     C     LimLag        ReadE     HJRNLAG@                               95
     C     *In95         DowEQ     *Off
     C                   Select
      * If total lag in minutes greater than allowed lag --> send alerts
     C     JLLAGM        WhenGT    ALWLPA                                       * Allowed lag
     C                   MoveL     'MJL0006'     MSGIDSM                        * Message ID
     C                   MoveL     ALRMPA        MSGQSM                         * Message queue
      * Fill message data
     C                   MoveL     JLJRNN        JRNNMD                         * Journal name
     C                   MoveL     JLJRNL        JRNLMD                         * Journal library
     C                   MoveL     JLDTSM        DTSMMD                         * Measurement dts
     C                   Z-Add     JLLAGM        LAGMMD                         * Lag in minutes
     C                   Z-Add     ALWLPA        ALWLMD                         * Allowed lag
     C                   MoveL     JLAPYR        JE2RMD                         * Apply receiver
     C                   MoveL     JLAPYL        JE2LMD                         * Apply receiver lib
     C                   Move      JLAPYS        JE2SMD                         * Apply sequence
     C                   MoveL     JLAPYT        JE2TMD                         * Apply date-time
     C                   MoveL     JLLSTR        JE1RMD                         * Last receiver
     C                   MoveL     JLLSTL        JE1LMD                         * Last receiver lib
     C                   Move      JLLSTS        JE1SMD                         * Last sequence
     C                   MoveL     JLLSTT        JE1TMD                         * Last date-time
     C                   MoveL     JLTGTN        TGTNMD                         * Target name
     C                   MoveL     JLGRPN        GRPNMD                         * Group name
     C                   ExSR      SRSNDM                                       * Send nonprogram ms
     C                   ExSR      SRSNDPM                                      * Send program msg
      * If send lag in minutes greater than allowed lag --> send alerts
     C     TYPMPA        WhenEQ    '*HST'                                       * History record
     C     JLSNDM        AndGT     ALWSPA                                       * Allowed send lag
     C     ALWSPA        AndNE     0                                            * Ignore send lag
     C     JLRTNC        AndEQ     *Blanks                                      * No error
     C                   MoveL     'MJL0008'     MSGIDSM                        * Message ID
     C                   MoveL     ALRMPA        MSGQSM                         * Message queue
      * Fill message data
     C                   MoveL     JLJRNN        JRNNMD                         * Journal name
     C                   MoveL     JLJRNL        JRNLMD                         * Journal library
     C                   MoveL     JLDTSM        DTSMMD                         * Measurement dts
     C                   Z-Add     JLSNDM        LAGMMD                         * Send lag in minute
     C                   Z-Add     ALWSPA        ALWLMD                         * Allowed send lag
     C                   MoveL     JLSRCR        JE2RMD                         * Sent receiver
     C                   MoveL     JLSRCL        JE2LMD                         * Sent receiver lib
     C                   Move      JLSRCS        JE2SMD                         * Sent sequence
     C                   MoveL     JLSRCT        JE2TMD                         * Sent date-time
     C                   MoveL     JLLSTR        JE1RMD                         * Last receiver
     C                   MoveL     JLLSTL        JE1LMD                         * Last receiver lib
     C                   Move      JLLSTS        JE1SMD                         * Last sequence
     C                   MoveL     JLLSTT        JE1TMD                         * Last date-time
     C                   MoveL     JLTGTN        TGTNMD                         * Target name
     C                   MoveL     JLGRPN        GRPNMD                         * Group name
     C                   ExSR      SRSNDM                                       * Send nonprogram ms
     C                   ExSR      SRSNDPM                                      * Send program msg
      * If apply lag in minutes greater than allowed lag --> send alerts
     C     TYPMPA        WhenEQ    '*HST'                                       * History record
     C     JLAPYM        AndGT     ALWAPA                                       * Allowed apply lag
     C     ALWAPA        AndNE     0                                            * Ignore apply lag
     C     JLRTNC        AndEQ     *Blanks                                      * No error
     C                   MoveL     'MJL0009'     MSGIDSM                        * Message ID
     C                   MoveL     ALRMPA        MSGQSM                         * Message queue
      * Fill message data
     C                   MoveL     JLJRNN        JRNNMD                         * Journal name
     C                   MoveL     JLJRNL        JRNLMD                         * Journal library
     C                   MoveL     JLDTSM        DTSMMD                         * Measurement dts
     C                   Z-Add     JLAPYM        LAGMMD                         * Apply lag in minut
     C                   Z-Add     ALWAPA        ALWLMD                         * Allowed apply lag
     C                   MoveL     JLAPYR        JE2RMD                         * Apply receiver
     C                   MoveL     JLAPYL        JE2LMD                         * Apply receiver lib
     C                   Move      JLAPYS        JE2SMD                         * Apply sequence
     C                   MoveL     JLAPYT        JE2TMD                         * Apply date-time
     C                   MoveL     JLSRCR        JE1RMD                         * Sent receiver
     C                   MoveL     JLSRCL        JE1LMD                         * Sent receiver lib
     C                   Move      JLSRCS        JE1SMD                         * Sent sequence
     C                   MoveL     JLSRCT        JE1TMD                         * Sent date-time
     C                   MoveL     JLTGTN        TGTNMD                         * Target name
     C                   MoveL     JLGRPN        GRPNMD                         * Group name
     C                   ExSR      SRSNDM                                       * Send nonprogram ms
     C                   ExSR      SRSNDPM                                      * Send program msg
     C                   EndSL
      * Read next record
     C     LimLag        ReadE     HJRNLAG@                               95
     C                   EndDo

      * End program
     C                   Return
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *INZSR        BegSR
     C                   EndSR

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
     C     MSGTYPSM      WHENEQ    #INFO                                        * Status message
     C                   MOVEL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-ADD     0             STCCTRSM                       * Stack counter
     C                   OTHER
     C                   MOVEL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-ADD     1             STCCTRSM                       * Stack counter
     C                   ENDSL
      * Send program message
     C                   Z-ADD     8             BPVDAE                         * Bytes provide
     C                   Z-ADD     1024          MSGDTL                         * Message data lengt
     C                   CALL      'QMHSNDPM'    $SNDPM                         * Send program msg
      * Reset values for next message send
     C                   MOVEL     *BLANKS       MSGFSM                         * Message file
     C                   MOVEL     *BLANKS       MSGTYPSM                       * Message type
     C                   MOVEL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-ADD     0             STCCTRSM                       * Stack counter
     C                   ENDSR

      * ------------------------------------------------------------------- *
      * SRSNDM - Send nonprogram message                                    *
      * ------------------------------------------------------------------- *
     C     SRSNDM        BEGSR
      * Determine message file value for QMHSNDM API
     C     MSGFSM        IFEQ      *BLANKS
     C                   MOVEL     #MSGF         MSGFSM                         * Default msgf
     C                   ENDIF
      * Set default message type
     C     MSGTYPSM      IFEQ      *BLANKS                                      * Message type
     C                   MOVEL     #DIAG         MSGTYPSM                       * Message type
     C                   ENDIF
      * Send nonprogram message
     C                   Z-ADD     8             BPVDAE                         * Bytes provide
     C                   Z-ADD     1024          MSGDTL                         * Message data lengt
     C                   CALL      'QMHSNDM'     $SNDM                          * Send program msg
      * Reset values for next message send
     C                   MOVEL     *BLANKS       MSGFSM                         * Message file
     C                   MOVEL     *BLANKS       MSGTYPSM                       * Message type
     C                   ENDSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
