     HDATEDIT(*YMD-)
     F* SOURCE/TARGET DATA SYNCRONIZATION
     FANZTOTL2  IF   E           K DISK
     FQPRINT    O    F  132        PRINTER OFLIND(*INOF)
     D #STMF           c                   Const('*STMF')
     D                 DS
     D  DTE                    1      8
     D  CY                     1      4
     D  M                      5      6
     D  D                      7      8

     D  DTEX           DS
     D  CY2                           4
     D  FIL1                          1    Inz('-')
     D  M2                            2
     D  FIL2                          1    Inz('-')
     D  D2                            2

     D IOBJ            s             74a
     D Count           s              7  0
     D CurDat          s               D

     IANZTR2        01
     C* Initialize and print heading
     C                   TIME                    TIME              6 0          Time of day
     C                   TIME                    CurDat                         Current date
     C                   EXCEPT    HEADNG                                       Print headng
      * Read first 100 records in the ANZTOT2 file and output
     C                   Eval      Count=1
     C                   Read      ANZTR2                                 20     EOF
     C                   DoW       not *In20 and Count<=100
      * Convert date to print format
     C                   MOVEL     CY            CY2
     C                   MOVEL     M             M2
     C                   MOVEL     D             D2
     C                   Eval      Count=Count+1                                Count rcds
     C                   Eval      *In11=*Off
     C                   If        OTYP=#STMF
     C                   Eval      *In11=*On
     C                   Eval      IOBJ=IFSOBJ
     C                   If        IFSOBJ='*FID'
     C                   Eval      IOBJ='*FID '+IFSID
     C                   EndIf
     C                   EndIf
     C                   EXCEPT    DETAIL                                       Print detail
     C   OF              EXCEPT    HEADNG                                       If overflow
     C   OF              Eval      *InOF=*Off                                   Switch off overflow
     C                   Read      ANZTR2                                 20     EOF
     C                   EndDo

     C                   SetOn                                        LR        Set LR

     C     *INZSR        BEGSR
     C                   ENDSR

     OQPRINT    E            HEADNG         1 06
     O                       CurDat              10
     O                       TIME                20 '0 :  :  '
     O                                           50 ' Rocket Software, Inc.'
     O                                           70 'Page'
     O                       PAGE          Z     75
     O          E            HEADNG         1
     O                                           47 'Top Transactions'
     O          E            HEADNG         1
     O                                           45 'By Object'
     O          E            HEADNG         1
     O                                            8 'Library'
     O                                           20 'Object'
     O                                           29 'Type'
     O                                           80 'Date'
     O                                           94 'Hour'
     O                                          114 'Transactions'
     O                                          130 'Size'
     O          E            HEADNG         2
     O                                           11 '__________'
     O                                           24 '__________'
     O                                           33 '________'
     O                                           86 '__________'
     O                                           94 '____'
     O                                          114 '_______________'
     O                                          130 '_______________'
     O          E            DETAIL         1
     O              N11      FLIB                11
     O              N11      FNAM                24
     O              N11      OTYP                33
     O               11      IOBJ                75
     O                       DTEX                86
     O                       HOURX               94
     O                       TOTENT        3    114
     O                       TOTLEN        3    130
