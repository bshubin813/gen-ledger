     HDATEDIT(*YMD-)
     F* SOURCE/TARGET DATA SYNCRONIZATION
     FANZTOTL3  IF   E           K DISK
     FQPRINT    O    F  132        PRINTER OFLIND(*INOF)
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

     D CurDat          s               D

     IANZTR3        01
     C* INITIalize and print heading
     C                   TIME                    TIME              6 0          Time of day
     C                   TIME                    CurDat                         Current date
     C                   EXCEPT    HEADNG                                       Print headng
     C* Read an record and print
     C     READ          TAG                                                    Read a rcd
     C                   READ      ANZTR3                                 20     EOF
     C   20              GOTO      ENDPGM                                       If EOF
     C                   MOVEL     CY            CY2
     C                   MOVEL     M             M2
     C                   MOVEL     D             D2
     C                   ADD       1             COUNT             7 0          Count rcds
     C     COUNT         IFGT      36
     C                   GOTO      ENDPGM
     C                   ELSE
     C                   END
     C                   EXCEPT    DETAIL                                       Print detail
     C   OF              EXCEPT    HEADNG                                       If overflow
     C                   GOTO      READ                                         Loop back
     C* End of program routine
     C     ENDPGM        TAG                                                    End of pgm
     C                   SETON                                        LR        Set LR
     C                   RETURN                                                 Return
     OQPRINT    E            HEADNG         1 06
     O                       CurDat              10
     O                       TIME                20 '0 :  :  '
     O                                           50 ' Rocket Software, Inc.'
     O                                           70 'Page'
     O                       PAGE          Z     75
     O          E            HEADNG         1
     O                                           47 'Top Transactions'
     O          E            HEADNG         1
     O                                           44 'By Program'
     O          E            HEADNG         1
     O                                           17 'Program'
     O                                           34 'Date'
     O                                           53 'Hour'
     O                                           75 'Transactions'
     O                                           91 'Size'
     O          E            HEADNG         2
     O                                           20 '__________'
     O                                           40 '__________'
     O                                           53 '____'
     O                                           75 '_______________'
     O                                           91 '_______________'
     O          E            DETAIL         1
     O                       PGMN                20
     O                       DTEX                40
     O                       HOURX               52
     O                       TOTENT        3     75
     O                       TOTLEN        3     91
