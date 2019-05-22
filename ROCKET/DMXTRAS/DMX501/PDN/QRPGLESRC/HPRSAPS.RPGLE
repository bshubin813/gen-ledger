      * ============================================================ *
      * Object:    HCHKAPS         *PGM RPG                          *
      *            Parses the passed string and inserts an extra     *
      *            apostrophe if the input string contains one. This *
      *            is necessary to let commands process the string   *
      *            properly.                                         *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 19991203 FK  Initial delivery                                *
      * 20020708 FK  Extend length to 2500                           *
      * ============================================================ *
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D TXO             S              1    DIM(2500)                            * Output string
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
     D TEXTPA          DS          2500
     D  TXI                    1   2500
     D                                     DIM(2500)                            * Input string
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *ENTRY        PLIST
     C                   PARM                    TEXTPA
     C                   PARM                    TXTLPA           15 5
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Z-ADD     1             I                 4 0          * TXO Counter
     C                   Z-ADD     1             O                 4 0          * TXO Index
     C                   CLEAR                   TXO
      * Read through entire TXI string
     C     I             DOWLE     TXTLPA
     C     I             ANDLE     2500
      * If input string is quote --> insert extra quote
     C     TXI(I)        IFEQ      ''''                                         * Quote
     C                   MOVEL     TXI(I)        TXO(O)
     C                   ADD       1             O
     C                   ENDIF
      * Now insert current character into output string
     C                   MOVEL     TXI(I)        TXO(O)
     C                   ADD       1             O
     C                   ADD       1             I
     C                   ENDDO
      * Move back variable
     C                   MOVEA     TXO           TEXTPA                         * Text string
      * End program
     C                   RETURN
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *INZSR        BEGSR
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
