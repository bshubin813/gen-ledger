      * ============================================================ *
      * Object:    HMRKPOS1        *PGM RPG                          *
      *            Submits the MRKHAPOS/DMMRKPOS commands and keeps  *
      *            the submitted jobs in the HMRKPOS file in QTEMP.  *
      *                                                              *
      * Synopsis:  See Command HMRKPOS.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20030603 FK  Initial delivery                                *
      * 20040319 FK  Only mark positions for local groups iCluster   *
      * 20111222 FK  Remove HA                                       *
      * ============================================================ *
      * iCluster groups by group name
     FHIGRPGN   IF   E           K DISK    USROPN
      * File to hold job information for submitted jobs
     FHMRKPOS   O    E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#ALL             C                   CONST('*ALL')
     D#YES             C                   CONST('*YES')
     D#ICluster        C                   CONST('*ICLUSTER')
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
     C                   Parm                    ICGRPA           10            * iCluster group
     C                   Parm                    SYSNPA            8            * Current system
     C                   Parm                    JOBQPA           20            * Qualified job queu
     C                   Parm                    NBRGPA            5 0          * # of groups
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Z-Add     0             NBRGPA                         * # of groups
     C                   ExSR      SRSbmIC
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *

      * ------------------------------------------------------------------- *
      * SRSbmIC - Submit jobs for iCluster                                  *
      * ------------------------------------------------------------------- *
     C     SRSbmIC       BegSR
     C                   Open      HIGRPGN                                      * Group definitions
      * Process all specified groups or resilient application
     C     *Loval        SetLL     HIGRPGN@
     C                   Read      HIGRPGN@                               95
     C     *IN95         DowEQ     *Off
      * Is the group selected
     C     GROUP         IfEQ      ICGRPA                                       * Same group
     C     APPNAME       OrEQ      ICGRPA                                       * Same resilient app
     C     ICGRPA        OrEQ      #ALL                                         * *ALL
      * Group must have current system as primary system
     C     CURRPRIM      IfEQ      SYSNPA                                       * Current system
      * Submit the job to mark the positions
     C                   Call      'HMRKPOS2'
     C                   Parm                    GROUP                          * Group name
     C                   Parm                    JOBQPA                         * Job queue
     C                   Parm                    JNAMWY           10            * Job name
     C                   Parm                    JUSRWY           10            * Job user
     C                   Parm                    JNBRWY            6            * Job number
      * Write entry to HMRKPOS for submitted job
     C     JNAMWY        IfNE      *Blanks                                      * No job submitted
     C                   MoveL     GROUP         MPGRPN                         * Group name
     C                   MoveL     JNAMWY        MPJNAM                         * Job name
     C                   MoveL     JUSRWY        MPJUSR                         * Job user
     C                   MoveL     JNBRWY        MPJNBR                         * Job number
     C                   Write     MRKPOS@
     C                   Add       1             NBRGPA                         * # of groups
     C                   EndIf                                                  * Job submitted
     C                   EndIf                                                  * Current system
     C                   EndIf                                                  * Group selected
      * Process next group
     C                   Read      HIGRPGN@                               95
     C                   EndDo                                                  * Group
     C                   EndSR
