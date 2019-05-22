      *CP: ALWNULL(*USRCTL)
      * ============================================================ *
      * Object:    HMONJRN2        *PGM RPG                          *
      *            Writes a replication lag entry in the HJRNLAG     *
      *            file.                                             *
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
      * 20021029 FK  System name to 8 characters                     *
      * 20031002 FK  Extend number of parameters                     *
      * 20070502 FK  Support for 20-digit sequence numbers           *
      * ============================================================ *
      * Journal replication lag by System name, Journal, date/time
     FHJRNLAG   O    E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Error          C                   '*ERROR'
     D #TotLag         C                   '*TOTLAG'
     D #SndLag         C                   '*SNDLAG'
     D #ApyLag         C                   '*APYLAG'
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *Entry        PList
     C                   Parm                    SYSNPA            8            * System name
     C                   Parm                    TYPMPA            4            * Measurement type
     C                   Parm                    TGTNPA           10            * Target name
     C                   Parm                    GRPNPA           10            * Group name
     C                   Parm                    JRNNPA           10            * Journal name
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    DTSMPA           26            * Measurement dts
     C                   Parm                    LSTRPA           10            * Last receiver
     C                   Parm                    LSTLPA           10            * Last receiver lib
     C                   Parm                    LSTSPA           20            * Last sequence #
     C                   Parm                    LSTTPA           26            * Last dts
     C                   Parm                    SRCRPA           10            * Apply receiver
     C                   Parm                    SRCLPA           10            * Apply receiver lib
     C                   Parm                    SRCSPA           20            * Apply sequence #
     C                   Parm                    SRCTPA           26            * Apply dts
     C                   Parm                    APYRPA           10            * Apply receiver
     C                   Parm                    APYLPA           10            * Apply receiver lib
     C                   Parm                    APYSPA           20            * Apply sequence #
     C                   Parm                    APYTPA           26            * Apply dts
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Clear output record
     C                   Clear                   HJRNLAG@
      * Ignore records that have an invalid last entry date/time
     C     LSTTPA        IfNE      *Blanks
      * Move parameter fields to output record
     C                   MoveL     SYSNPA        JLSYSN                         * System name
     C                   MoveL     TYPMPA        JLTYPM                         * Measurement type
     C                   MoveL     TGTNPA        JLTGTN                         * Target name
     C                   MoveL     GRPNPA        JLGRPN                         * Group name
     C                   MoveL     JRNNPA        JLJRNN                         * Journal name
     C                   MoveL     JRNLPA        JLJRNL                         * Journal library
     C                   Move      DTSMPA        JLDTSM                         * Measurement dts
     C                   MoveL     LSTRPA        JLLSTR                         * Last receiver
     C                   MoveL     LSTLPA        JLLSTL                         * Last receiver lib
     C                   Move      LSTSPA        JLLSTS                         * Last sequence #
     C                   Move      LSTTPA        JLLSTT                         * Last dts
      * If Source journal entry known, also write
     C     SRCTPA        IfNE      *Blanks
     C                   MoveL     SRCRPA        JLSRCR                         * Source receiver
     C                   MoveL     SRCLPA        JLSRCL                         * Source receiver li
     C                   Move      SRCSPA        JLSRCS                         * Source sequence #
     C                   Move      SRCTPA        JLSRCT                         * Source dts
     C                   Else
     C                   Eval      %Nullind(JLSRCT)=*On                         * Source dts
     C                   EndIf
      * If Apply journal entry known, also write
     C     APYTPA        IfNE      *Blanks
     C                   MoveL     APYRPA        JLAPYR                         * Apply receiver
     C                   MoveL     APYLPA        JLAPYL                         * Apply receiver lib
     C                   Move      APYSPA        JLAPYS                         * Apply sequence #
     C                   Move      APYTPA        JLAPYT                         * Apply dts
     C                   Else
     C                   Eval      %Nullind(JLAPYT)=*On                         * Apply dts
     C                   EndIf
      * Calculate send replication lag if valid
     C     SRCTPA        IfNE      *Blanks
     C     JLLSTT        SubDur    JLSRCT        JLSNDM:*MN             99      * Send lag
     C     *In99         IfEQ      *On
     C                   Z-Add     0             JLSNDM                         * Send lag
     C                   MoveL(p)  #SndLag       JLRTNC                         * Return code
     C                   EndIf
     C                   EndIf
      * Calculate apply replication lag if valid
     C     SRCTPA        IfNE      *Blanks
     C     JLSRCT        SubDur    JLAPYT        JLAPYM:*MN             99      * Apply lag
     C     *In99         IfEQ      *On
     C                   Z-Add     0             JLAPYM                         * Apply lag
     C                   MoveL(p)  #ApyLag       JLRTNC                         * Return code
     C                   EndIf
     C                   EndIf
      * Calculate total replication lag
     C     APYTPA        IfNE      *Blanks
     C     JLLSTT        SubDur    JLAPYT        JLLAGM:*MN             99      * Lag in minutes
     C     *In99         IfEQ      *On
     C                   Z-Add     *Hival        JLLAGM                         * Lag in minutes
     C                   MoveL(p)  #TotLag       JLRTNC                         * Return code
     C                   EndIf
     C                   Else
     C                   MoveL(p)  #TotLag       JLRTNC                         * Return code
     C                   EndIf
     C                   Write     HJRNLAG@
     C                   EndIf                                                  * Valid Last date-ti
      * End program
     C                   Return
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *INZSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
