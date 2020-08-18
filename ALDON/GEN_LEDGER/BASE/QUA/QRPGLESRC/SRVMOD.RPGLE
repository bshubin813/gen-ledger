     H*
     H********************************************************************
     H** PROGRAM NAME: DEMOSRV2                                          *
     H**                                                                 *
     H********************************************************************
     H*
     D*
     D                 DS
     D  CNT                    1      2  0
     D  SW0                    3      3
     D  WRKCNT                18     19  0
     I*
     C*
     C     *ENTRY        PLIST
     C                   PARM                    PARM1            10
     C                   PARM                    PARM2             4
     C*
     C     PARM2         IFGT      *ZERO
     C                   MOVEL     'ERROR'       PARM1
     C                   ELSE
     C                   MOVEL     'CORRECT'     PARM1
     C                   END
     C                   RETURN
