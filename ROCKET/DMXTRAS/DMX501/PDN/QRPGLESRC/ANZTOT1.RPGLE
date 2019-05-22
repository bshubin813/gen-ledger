     HDECEDIT('0.') DATEDIT(*YMD-) DATFMT(*ISO)
     F* SOURCE/TARGET DATA SYNCRONIZATION
     FANZTOT1   IF   E           K DISK
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
     C* INITIalize and print heading
     C                   TIME                    TIME              6 0          Time of day
     C                   TIME                    CurDat                         Current date
     C*                    EXCPTHEADNG                     Print headng
     C* Read an record and print
     C     READ          TAG                                                    Read a rcd
     C                   READ      ANZTR1                                 20     EOF
     C   20              GOTO      ENDPGM                                       If EOF
     C                   ADD       1             COUNT             7 0          Count rcds
     C     TOTLEN        Div       943718.40     FILD1            10 5
     C     TOTLEN        Div       1887436.80    FILD2            10 5
     C     TOTLEN        Div       3774873.60    FILD3            10 5
     C     TOTLEN        Div       7549747.20    FILD4            10 5
     C     TOTLEN        Div       15099494.40   FILD5            10 5
     C     TOTLEN        Div       377487360.00  FILD6            10 5
     C                   MOVEL     CY            CY2
     C                   MOVEL     M             M2
     C                   MOVEL     D             D2
     C     PRVDTE        IFNE      DTE
     C                   MOVEL     DTE           PRVDTE
     C                   EXCEPT    HEADNG
     C                   EXCEPT    DETAIL
     C                   GOTO      READ
     C                   END
     C                   EXCEPT    DETAIL                                       Print detail
     C   OF              EXCEPT    HEADNG                                       If overflow
     C                   GOTO      READ                                         Loop back
     C* End of program routine
     C     ENDPGM        TAG                                                    End of pgm
     C                   SETON                                        LR        Set LR
     C                   RETURN                                                 Return
     ****************************************************************
     C     *INZSR        BEGSR
     C                   MOVEL     *BLANKS       PRVDTE            8
     C                   ENDSR
      *************************************************************
     OQPRINT    E            HEADNG         1 06
     O                       CurDat              10
     O                       TIME                20 '0 :  :  '
     O                                           80 ' Rocket Software, Inc.'
     O                                          120 'Page'
     O                       PAGE          Z    125
     O          E            HEADNG         1
     O                                           77 'Journal Analysis'
     O          E            HEADNG         1
     O                                           72 'Report'
     O          E            HEADNG         1
     O                                            4 'Date'
     O                                           15 'Hour'
     O                                           33 'Database'
     O                                           52 'Bytes Per'
     O                                           65 '256 kbps'
     O                                           78 '512 kbps'
     O                                           91 '  1 Mbps'
     O                                          104 '  2 Mbps'
     O                                          117 '  4 Mbps'
     O                                          130 '100 Mbps'
     O          E            HEADNG         1
     O                                           33 'Changes'
     O                                           52 'Hour'
     O                                           65 '% Line'
     O                                           78 '% Line'
     O                                           91 '% Line'
     O                                          104 '% Line'
     O                                          117 '% Line'
     O                                          130 '% Line'
     O          E            HEADNG         1
     O                                           10 '__________'
     O                                           15 '____'
     O                                           33 '_______________'
     O                                           52 '_______________'
     O                                           65 '___________'
     O                                           78 '___________'
     O                                           91 '___________'
     O                                          104 '___________'
     O                                          117 '___________'
     O                                          130 '___________'
     O          E            DETAIL         1
     O                       DTEX                10
     O                       HOURX               14
     O                       TOTENT        1     33
     O                       TOTLEN        1     52
     O                       FILD1         1     65
     O                       FILD2         1     78
     O                       FILD3         1     91
     O                       FILD4         1    104
     O                       FILD5         1    117
     O                       FILD6         1    130
