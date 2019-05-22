      ************************************************************
      * OBJCOUNTS2 Object Counts Report.
      *
      * CHANGE LOG: Mar 14, 2001 M. Warkentin
      *             Add 1 byte to each of FS, OS, TS
      *             (used to be 11, now 12) for big shops
      ************************************************************
      *
      * Library Descriptions
     FOBJCNTAL  IF   E           K DISK
     F                                     RENAME(QLIDOBJD:RECA)
      *
      * Object count & size info.
     FOBJCNTBL  IF   E           K DISK
     F                                     RENAME(QLIDOBJD:RECB)
      *
      * Printer Output
     FQSYSPRT   O    F  132        PRINTER
      ***********************************************************
      * Clear sumary total fields
      *
     C                   CLEAR                   FCT                            File Count  Tot
     C                   CLEAR                   FST                            File Size   Tot
     C                   CLEAR                   OCT                            File Count  Tot
     C                   CLEAR                   OST                            File Size   Tot
     C                   CLEAR                   TCT                            Total Count Tot
     C                   CLEAR                   TST                            Total Size  Tot
     C     *ENTRY        PLIST
     C                   PARM                    S                10            System
     C                   EXCEPT    HED
      ***********************************************************
      * Read each library in OBJCNT1 and then summarise OBJCNT2
      * to show file/object counts and sizes
      *
     C                   READ      RECA                                   99
     C     *IN99         DOWNE     '1'
     C                   MOVE      ODOBNM        LIB              10
     C                   MOVEL     ODOBTX        TXT              35
     C                   Z-ADD     *ZERO         FC                7 0          File Count
     C                   Z-ADD     *ZERO         FS               12 0          File Size
     C                   Z-ADD     *ZERO         OC                7 0          File Count
     C                   Z-ADD     *ZERO         OS               12 0          File Size
     C                   Z-ADD     *ZERO         TC                7 0          Total Count
     C                   Z-ADD     *ZERO         TS               12 0          Total Size
      * Sumarise object
     C     LIB           CHAIN     RECB                               99
     C     *IN99         DOWNE     '1'
      *
     C     ODOBTP        IFEQ      '*FILE'
     C     ODOBAT        ANDEQ     'PF'
     C                   ADD       1             FC
     C                   ADD       ODOBSZ        FS
     C                   ELSE
     C                   ADD       1             OC
     C                   ADD       ODOBSZ        OS
     C                   END
      * Totals
     C                   ADD       1             TC
     C                   ADD       ODOBSZ        TS
     C     LIB           READE     RECB                                   99
     C                   END
     C                   EXCEPT    LIN
      * Final Tots
     C                   ADD       FC            FCT               7 0
     C                   ADD       FS            FST              12 0
     C                   ADD       OC            OCT               7 0
     C                   ADD       OS            OST              12 0
     C                   ADD       TC            TCT               7 0
     C                   ADD       TS            TST              12 0
      *
     C                   READ      RECA                                   99
     C                   END
      *
     C                   EXCEPT    SUM
      *
     C                   SETON                                        LR
     C                   RETURN
      ****************************************************************
     OQSYSPRT   T    LR                     1  1
     O          E            HED         1
     O                                         +  1 'Object'
     O                                         +  1 'Counts'
     O                                         +  1 '(OBJCOUNTS)'
     O                       UDATE         Y   +  2
     O                       S                 +  2
     O          E            HED         1
     O          E            HED         1
     O                                         +  1 '         '
     O                                         +  2 ' Physical'
     O                                         +  7 ' Physical'
     O                                         +  2 '    Other'
     O                                         +  7 '    Other'
     O                                         +  2 '    Total'
     O                                         +  7 '    Total'
     O          E            HED         1
     O                                         +  1 '         '
     O                                         +  2 '     File'
     O                                         +  7 '     File'
     O                                         +  2 '   Object'
     O                                         +  7 '   Object'
     O                                         +  2 ' File/Obj'
     O                                         +  7 ' File/Obj'
     O          E            HED         1
     O                                         +  1 'Library  '
     O                                         +  2 '    Count'
     O                                         +  7 'Size-byts'
     O                                         +  2 '    Count'
     O                                         +  7 'Size-byts'
     O                                         +  2 '    Count'
     O                                         +  7 'Size-byts'
     O                                         +  2 'Description'
     O          E            HED         1
     O          E            LIN         1
     O                       LIB               +  1
     O                       FC            J   +  1
     O                       FS            J   +  1
     O                       OC            J   +  1
     O                       OS            J   +  1
     O                       TC            J   +  1
     O                       TS            J   +  1
     O                       TXT               +  1
     O          E            SUM         2
     O                       FCT           J   + 12
     O                       FST           J   +  1
     O                       OCT           J   +  1
     O                       OST           J   +  1
     O                       TCT           J   +  1
     O                       TST           J   +  1
