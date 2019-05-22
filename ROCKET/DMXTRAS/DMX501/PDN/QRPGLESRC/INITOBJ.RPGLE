      * ============================================================ *
      * Object:    INITOBJ         *PGM RPG                          *
      *            Initialise objects in a group for replication.    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20010718 CE  Initial delivery                                *
      * 20020531 FK  Use files in QTEMP to prevent level check V3R6  *
      * ============================================================ *
      * Target definitions by target ID
     FHUTGTTI   IF   E           K DISK
      * Group definitions by group ID
     FHUGRPGI   IF   E           K DISK
      * Groups for target by target ID, Group ID
     FHUFGTTG   IF   E           K DISK

     C     *LOVAL        SETLL     HUFGTTG@                               99
     C     READ          TAG
     C                   READ      HUFGTTG@                               98
     C   98              GOTO      ENDPGM
     C     TGTID         IFEQ      0
     C     GRPID         OREQ      0
     C                   GOTO      READ
     C                   ENDIF
     C     TGTID         CHAIN     HUTGTTI@                           97
     C   97              GOTO      ENDPGM
     C                   MOVEL     TGTNAME       TARGET           10
     C     GRPID         CHAIN     HUGRPGI@                           96
     C                   MOVEL     GRPNAME       GROUP            10
     C   96              GOTO      ENDPGM
     C     TARGET        IFNE      *BLANKS
     C     GROUP         ANDNE     *BLANKS
     C                   CALL      'INITGRP'
     C                   PARM                    TARGET
     C                   PARM                    GROUP
     C                   ENDIF
     C                   GOTO      READ
     C     ENDPGM        TAG
     C                   SETON                                        LR
     C                   RETURN
