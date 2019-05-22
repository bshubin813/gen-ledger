      * ============================================================ *
      * Object:    HCHKSYN0A       *PGM RPG                          *
      *            Adds records to HCHKSYNJOB or removes them.       *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20050214 FK  Initial delivery                                *
      * ============================================================ *
      * File to hold job information for submitted jobs
     FHCHKSYNJOBUF A E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#ADD             C                   CONST('*ADD')
     D#RMV             C                   CONST('*RMV')
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
     C                   Parm                    ACTPA             4            * Action *ADD/*RMV
     C                   Parm                    SFRMPA            6            * Submitted from job
     C                   Parm                    JNAMPA           10            * Job name
     C                   Parm                    JUSRPA           10            * Job user
     C                   Parm                    JNBRPA            6            * Job number
     C                   Parm                    GRPNPA           10            * Group name
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Dependent on action, run
     C                   Select
      * Add record for submitted job
     C                   When      ACTPA = #ADD                                 * *ADD
     C                   Eval      SJSFRM = SFRMPA                              * Submitted from
     C                   Eval      SJJNAM = JNAMPA                              * Job name
     C                   Eval      SJJUSR = JUSRPA                              * Job user
     C                   Eval      SJJNBR = JNBRPA                              * Job number
     C                   Eval      SJTGTN = '*ICLUSTER'                         * Target name
     C                   Eval      SJGRPN = GRPNPA                              * Group name
     C                   Write     SYNJOB@
      * Remove all records for submitting job
     C                   When      ACTPA = #RMV                                 * *RMV
     C     SFRMPA        SetLL     SYNJOB@
     C     SFRMPA        ReadE     SYNJOB@                                95
     C                   DoW       not *In95
     C                   Delete    SYNJOB@
     C     SFRMPA        ReadE     SYNJOB@                                95
     C                   EndDo

     C                   EndSL

     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
