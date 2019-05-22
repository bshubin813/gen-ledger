      * ============================================================ *
      * Object:    HENDJRNPF1      *PGM RPG                          *
      *            Determine the attribute (PFSRC or PFDTA) for the  *
      *            given file.                                       *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20050715 FK  Initial release                                 *
      * ============================================================ *
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
     D  MSGIDAE                9     15                                         * Message ID

      * FILD0100 data structure
     D FILD0100        DS          1000
     D  LRTNFD                 1      4B 0                                      * Length dta returne
     D  BPVDFD                 5      8B 0                                      * Bytes provided
     D  ATR1FD                 9      9                                         * Attribute bytes
     D  ATR2FD                10     10                                         * Attribute bytes
     D  RestFD                11     50                                         * Remaining bytes
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#FILE            C                   CONST('*FILE     ')
     D#PFDTA           C                   CONST('PFDTA     ')
     D#PFSRC           C                   CONST('PFSRC     ')
     D#LFDTA           C                   CONST('LF        ')
     D#LFSRC           C                   CONST('LFSRC     ')
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
      * API parameter values
     D RcvVarLen       S              9b 0                                      * Receiver var len

     D AtrWY           S             10a                                        * Attribute
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Parameter list for QDBRTVFD API
     C     pRTVFD        PList
     C                   Parm                    FILD0100                       * FILD0100 format
     C                   Parm      1000          RcvVarLen                      * Rcv Var length
     C                   Parm                    RtnFilFD         20            * Returned file
     C                   Parm      'FILD0100'    FmtFD             8            * Format
     C                   Parm                    FileFD           20            * Qualified file
     C                   Parm      '*FIRST'      RcdFmtFD         10            * Record format
     C                   Parm      '0'           OvrPrcFD          1            * Override processin
     C                   Parm      '*FILETYPE'   SysFD            10            * System
     C                   Parm      '*EXT'        FmtTypFD         10            * Format type
     C                   Parm                    APIERR                         * API Error
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    FILEPA           10            * File
     C                   Parm                    LIBPA            10            * Library
     C                   Parm                    ATRPA            10            * Attribute
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Call API to retrieve file attribute
     C                   Clear                   APIERR
     C                   Eval      BPVDAE = 15                                  * Suppress error
     C                   Eval      FileFD = FILEPA + LIBPA                      * Qualified file
     C                   Call      'QDBRTVFD'    pRTVFD                         * QDBRTVFD API
      * Determine object attribute, dependent on returned attribute
     C                   If        MSGIDAE = ' '                                * No error
     C                   TestB     '2'           ATR1FD                   21    * PF=0/LF=1
     C                   TestB     '4'           ATR1FD                   22    * DTA=0/SRC=1
     C                   Select
     C                   When      not *In21 and not *In22                      * Physical-data
     C                   MoveL     #PFDTA        ATRPA                          * Object attribute
     C                   When      *In21 and not *In22                          * Logical
     C                   MoveL     #LFDTA        ATRPA                          * Object attribute
     C                   When      not *In21 and *In22                          * Physical-source
     C                   MoveL     #PFSRC        ATRPA                          * Object attribute
     C                   When      *In21 and *In22                              * Logical source
     C                   MoveL     #LFSRC        ATRPA                          * Object attribute
     C                   EndSL
     C                   EndIf

     C                   Return

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
