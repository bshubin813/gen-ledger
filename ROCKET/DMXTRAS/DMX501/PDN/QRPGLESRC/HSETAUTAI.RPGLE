      * ============================================================ *
      * Object:    HSETAUTAI       *PGM RPG                          *
      *            Calls the program to fix IFS authorities, if      *
      *            different. Updates flag if authorities fixed.     *
      *                                                              *
      * Synopsis:  See Command HSETAUT.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20031210 FK  Initial delivery                                *
      * 20050518 FK  Use HCHKSYNIFA file                             *
      * 20111223 FK  Remove HA                                       *
      * ============================================================ *
      * IFS Object differences
     FHCHKSYNIFAUF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
     D IFSObj          S           5000                                         * IFS Object
     D IFSLen          S              5  0                                      * IFS length
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #ALL            C                   CONST('*ALL')
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
     C                   Parm                    GRPNPA           10            * Group name
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Read all records in HCHKSYNIFA and update where necessary
     C     *Loval        SETLL     SYNIFA@
     C                   Read      SYNIFA@                                95
     C     *In95         DowEQ     *Off
      * Call program to update authorities
     C                   Eval      IFSObj=IAOBJ                                 * IFS Object
     C                   Eval      IFSLen=%len(IAOBJ)
     C                   Call      'HSETAUTAI1'
     C                   Parm                    IAMAT                          * Missing auth.
     C                   Parm                    IAMAS                          * Obsolete auth.
     C                   Parm                    IAAD                           * Authority diff.
     C                   Parm                    IAOD                           * Owner difference
     C                   Parm                    IAUSR                          * User
     C                   Parm                    SJOWN                          * Source owner
     C                   Parm                    TJOWN                          * Target owner
     C                   Parm                    SJDTAA                         * Src data aut
     C                   Parm                    TJDTAA                         * Tgt data aut
     C                   Parm                    SJANAM                         * Src auth list
     C                   Parm                    TJANAM                         * Tgt auth list
     C                   Parm                    SJOPR                          * Src operational
     C                   Parm                    TJOPR                          * Tgt operational
     C                   Parm                    SJOMGT                         * Src obj. mgt.
     C                   Parm                    TJOMGT                         * Tgt obj. mgt.
     C                   Parm                    SJEXS                          * Src existence
     C                   Parm                    TJEXS                          * Tgt existence
     C                   Parm                    SJALT                          * Src alter
     C                   Parm                    TJALT                          * Tgt alter
     C                   Parm                    SJREF                          * Src reference
     C                   Parm                    TJREF                          * Tgt reference
     C                   Parm                    SJREAD                         * Src read
     C                   Parm                    TJREAD                         * Tgt read
     C                   Parm                    SJADD                          * Src add
     C                   Parm                    TJADD                          * Tgt add
     C                   Parm                    SJUPD                          * Src update
     C                   Parm                    TJUPD                          * Tgt update
     C                   Parm                    SJDLT                          * Src delete
     C                   Parm                    TJDLT                          * Tgt delete
     C                   Parm                    SJEXEC                         * Src execute
     C                   Parm                    TJEXEC                         * Tgt execute
     C                   Parm                    IAFIX                          * Authority fixed?
     C                   Parm                    IFSLen                         * IFS path length
     C                   Parm                    IFSObj                         * IFS Object
     C                   Update    SYNIFA@
     C                   Read      SYNIFA@                                95
     C                   EndDo

     C                   Return
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
