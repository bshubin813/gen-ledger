     H*
     H********************************************************************
     H** PROGRAM NAME: XMOD27                                           *
     H**                                                                 *
     H********************************************************************
     H*
     F*
     FQSYSPRT   O    F  132        PRINTER OFLIND(*INOA)
     F*
     D DSPMSG          S             30    DIM(7) CTDATA PERRCD(2)
     D*
     D                 DS
     D  CNT                    1      2  0
     D  SW0                    3      3
     D  PARM1                  4     13
     D  PARM2                 14     17  0
     D  WRKCNT                18     19  0
     I*
     C*
     C                   MOVE      DSPMSG(1)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   MOVEL     *BLANKS       PARM1
     C                   MOVE      *ZERO         PARM2
     C                   DO        10            CNT
     C                   EXSR      CHKCNT
     C                   END
     C                   CALLB     'XMOD25'
     C                   PARM                    PARM1
     C                   PARM                    PARM2
     C     SW0           IFEQ      '1'
     C                   MOVE      DSPMSG(2)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   END
     C     PARM1         IFNE      'CORRECT'
     C                   MOVE      PARM1         OUTMSG           30
     C                   EXCEPT    MSGS
     C                   END
     C                   SETON                                        LR
     C                   RETURN
     C*
     C     CHKCNT        BEGSR
     C     CNT           IFEQ      3
     C     CNT           OREQ      7
     C     CNT           IFEQ      3
     C                   MOVE      DSPMSG(3)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   ELSE
     C                   MOVE      DSPMSG(4)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   END
     C                   ELSE
     C     CNT           DIV       2             WRKCNT
     C                   MULT      2             WRKCNT
     C     CNT           IFEQ      WRKCNT
     C     CNT           IFEQ      0
     C                   MOVE      DSPMSG(5)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   ELSE
     C                   MOVE      DSPMSG(6)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   END
     C                   ELSE
     C                   MOVE      DSPMSG(7)     OUTMSG           30
     C                   EXCEPT    MSGS
     C                   END
     C                   END
     C                   ENDSR
     C*
     O*
     OQSYSPRT   E            MSGS           1
     O                       OUTMSG              31
     OQSYSPRT   E    OA      MSGS           1
     O                                           16 '               '
     O                                           16 '               '
**  DSPMSG
BEGINNING SAMPLE EXECUTION    SOMEBODY TURNED THE SWITCH OFF
COUNT = THREE                 COUNT = SEVEN
COUNT IS ZERO                 COUNT IS EVEN
COUNT IS ODD
