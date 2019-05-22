      * ============================================================ *
      * Object:    HSETAUTAF       *PGM RPG                          *
      *            Sets the "Authority Fixed" flag in the HCHKSYNAUT *
      *            file.                                             *
      *                                                              *
      * Synopsis:  See Command HSETAUT.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20021202 FK  Initial delivery                                *
      * 20111223 FK  Remove HA                                       *
      * ============================================================ *
      * Authority differences
     FHCHKSYNAUTUF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list for getting authority record
     C     ChnAut        KList
     C                   KFld                    OAGRPN                         * Group name
     C                   KFld                    OACMPL                         * Compare library
     C                   KFld                    OANAME                         * Object name
     C                   KFld                    OATYPE                         * Object type
     C                   KFld                    OAUSR                          * User
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    OAGRPN                         * Group name
     C                   Parm                    OACMPL                         * Compare library
     C                   Parm                    OANAME                         * Object name
     C                   Parm                    OATYPE                         * Object type
     C                   Parm                    OAUSR                          * User
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Update "Fixed" Flag
     C     ChnAut        Chain     SYNAUT@                            95
     C     *In95         IfEQ      *Off
     C                   MoveL     'Y'           OAFIX                          * Authority fixed
     C                   Update    SYNAUT@
     C                   EndIf

     C                   Return
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
