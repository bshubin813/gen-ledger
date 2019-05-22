     H*
     H********************************************************************
     H** PROGRAM NAME: XMOD25                                    *
     H**                                                                 *
     H********************************************************************
     H*
     F*
     FQSYSPRT   O    F  132        PRINTER OFLIND(*INOA)
     F*
     D DSPMSG          S             30    DIM(4) CTDATA PERRCD(2)
     D*
     D                 DS
     D  CNT                    1      2  0 INZ
     D  WRKCNT                18     19  0 INZ
     I*
     C                   MOVE      DSPMSG(1)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   DO        10            CNT
     C                   EXSR      CHKCNT
     C                   END
     C                   SETON                                        LR
     C                   RETURN
     C*
     C     CHKCNT        BEGSR
     C     CNT           DIV       2             WRKCNT
     C                   MULT      2             WRKCNT
     C     CNT           IFEQ      WRKCNT
     C     CNT           IFEQ      0
     C                   MOVE      DSPMSG(2)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   ELSE
     C                   MOVE      DSPMSG(3)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   END
     C                   END
     C   LR              MOVE      DSPMSG(4)     OUTMSG           30
     C   LR              EXCEPT    MSGS
     C                   ENDSR
     O*
     OQSYSPRT   E            MSGS           1
     O                       OUTMSG              31
     OQSYSPRT   E    OA      MSGS           1
     O                                           16 '               '
     O                                           16 '               '
**  DSPMSG
BEGINNING SAMPLE EXECUTION    COUNT IS ZERO
COUNT IS EVEN                 LR IS ON
