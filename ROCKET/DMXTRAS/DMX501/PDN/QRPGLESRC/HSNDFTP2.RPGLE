      * ============================================================ *
      * Object:    HSNDFTP2        *PGM RPG                          *
      *            Reads the generated FTP log for errors in         *
      *            the file transfer.                                *
      *                                                              *
      * Synopsis:  See Command HSNDFTP.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20030616 FK  Initial delivery                                *
      * ============================================================ *
     FHFTPSRC   IF   E             DISK    RENAME(HFTPSRC:@HFTPSRC)
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #ERROR          C                   Const('ERROR  ')
     D #UNKNOWN        C                   Const('*UNKNOWN')
     D #HostErr        C                   Const('Cannot find host')
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
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
     C                   Parm                    RTNCPA            7            * Return code
     C                   Parm                    RSNPA            80            * Reason
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Set return code to blanks
     C                   MoveL     *Blanks       RTNCPA                         * Return code
     C                   MoveL(p)  #UNKNOWN      RSNPA                          * Reason
     C                   Move      *Off          TFRWY             1            * Transferred?
     C                   Move      *Off          ERRWY             1            * Transfer error?
      * Read all records
     C                   Read      @HFTPSRC                               95
     C     *In95         DowEQ     *Off
     C     TFRWY         AndEQ     *Off                                         * File transferred
     C     ERRWY         AndEQ     *Off                                         * Transfer error
     C                   Select
      * If "Cannot find host ..." found --> Set variable
     C                   When      %subst(SRCDTA:1:16) = #HostErr
     C                   Move      *On           ERRWY                          * Transfer error
     C                   MoveL     SRCDTA        RSNPA                          * Reason
      * If "530 Log on attempt by user ... rejected" found --> Set variable
     C                   When      %subst(SRCDTA:1:4) = '530 '
     C                   Move      *On           ERRWY                          * Transfer error
     C                   MoveL     SRCDTA        RSNPA                          * Reason
      * If "550 Library ... not found" found --> Set variable
     C                   When      %subst(SRCDTA:1:4) = '550 '
     C                   Move      *On           ERRWY                          * Transfer error
     C                   MoveL     SRCDTA        RSNPA                          * Reason
      * If "250 File transferred successfully" found --> Set variable
     C                   When      %subst(SRCDTA:1:4) = '250 '
     C                   Move      *On           TFRWY                          * Transferred?
     C                   EndSL
     C                   Read      @HFTPSRC                               95
     C                   EndDo
      * Now return if file was transferred ok
     C     TFRWY         IfEQ      *Off
     C     ERRWY         OrEQ      *On
     C                   MoveL     #ERROR        RTNCPA                         * Return code
     C                   EndIf
      * End program
     C                   Seton                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
