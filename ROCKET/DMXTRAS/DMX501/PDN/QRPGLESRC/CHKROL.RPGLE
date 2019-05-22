      * ============================================================ *
      * Object:    CHKROL          *PGM RPG                          *
      *            Changes the role of all that do not have a role   *
      *            set yet.                                          *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 2000???? ??  Initial delivery                                *
      * 20020531 FK  Use logical file because changed OMFTGT         *
      * ============================================================ *
     FHUTGTTI   IF   E             DISK

     C     READ          TAG
     C                   READ      HUTGTTI@                               98
     C   98              GOTO      ENDPGM
     C     TGTID         IFEQ      0
     C                   GOTO      READ
     C                   ENDIF
     C     HAROLE        IFEQ      ' '
     C*    ROLETSTMP     ANDEQ     0
     C                   MOVEL     TGTNAME       TARGET           10
     C                   CALL      'CHGTGT'
     C                   PARM                    TARGET
     C                   ENDIF
     C                   GOTO      READ
     C     ENDPGM        TAG
     C                   SETON                                        LR
     C                   RETURN
