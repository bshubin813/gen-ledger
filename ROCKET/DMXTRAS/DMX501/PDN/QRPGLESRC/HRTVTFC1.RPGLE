      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HRTVNET1        *PGM RPG                          *
      *            Summarises the network traffic and cleans up.     *
      *                                                              *
      * Synopsis:                                                    *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20060307 FK  Initial delivery                                *
      * ============================================================ *
      * Input file
     FHNETTFC   UF   E           K DISK
      * Output file
     FHNETTFCSUMUF A E           K DISK
      * Output printer file
     FHRTVTFCP  O    E             PRINTER OflInd(*In01) UsrOpn
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
     D StrDat          DS            10                                         * Work date
     D  StrDatISO              1     10D   DATFMT(*ISO)
     D  StrDatDD               9     10  0

     D                 DS            26
     D  NTDTSM                         z                                        * DTS
     D  NTDTSMISO              1     10a                                        * Date in ISO
     D  NTDTSMHH              12     13a                                        * Hour
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #All            c                   Const('*ALL')
     D #Day            c                   Const('*DAY')
     D #Hour           c                   Const('*HOUR')
     D #Yes            c                   Const('*YES')

      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D CurDat          s               d   DatFmt(*ISO)
     D StrDTS          s               z
     D EndDTS          s               z
     D ClnDTS          s               z
     D RcdSlt          s               n
     D Hour            s              2  0
     D pPortWY         s              5s 0                                      * Port (parm)
     D NSDATESv        s             10a                                        * Saved date
     D DTS@            s             26a                                        * DTS field

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list to check summary records
     C     ChkSum        KList
     C                   KFld                    pSysNam                        * System name
     C                   KFld                    NTDTSMISO                      * Date
      * Key list to retrieve summary record
     C     ChnSum        KList
     C                   KFld                    pSysNam                        * System name
     C                   KFld                    NSDATE                         * Date
     C                   KFld                    NSHOUR                         * Hour
     C                   KFld                    pLclAdr                        * Local Address
     C                   KFld                    pRmtAdr                        * Remote Address
     C                   KFld                    pPortWY                        * Port number
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *Entry        PList
     C                   Parm                    pSumUnt           5            * Summarisation unit
     C                   Parm                    pNbrUnt           3 0          * Number of units
     C                   Parm                    pRelDat           8            * Relative date
     C                   Parm                    pClnHst           3 0          * Clean history
     C                   Parm                    pPort             5 0          * Port to select
     C                   Parm                    pLclAdr          15            * Local address
     C                   Parm                    pRmtAdr          15            * Remote address
     C                   Parm                    pSysNam           8            * System name
     C                   Parm                    pPrint            4            * Print output?

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Eval      pPortWY=pPort
      * Retrieve current date
     C                   Time                    CurDat                         * Current date
      * Convert special values for date
     C                   Select
      * Calculate starting date in case of *STRCUR
     C                   When      pRelDat='19680827'                           * *STRCUR
     C                   MoveL     CurDat        StrDatISO                      * To DS
     C                   Eval      StrDatDD=1                                   * Day of current mon
      * Calculate starting date in case of *STRPRV
     C                   When      pRelDat='19670827'                           * *STRPRV
     C                   MoveL     CurDat        StrDatISO                      * To DS
     C                   Eval      StrDatDD=1                                   * Day of previous mt
     C                   SubDur    1:*Months     StrDatISO                      * Month - 1
      * Real date was specified
     C                   Other
     C     *ISO0         MoveL     pRelDat       StrDatISO                      * Start date
     C                   EndSL
      * Calculate start, end and clean DTS
     C                   MoveL     StrDatISO     StrDTS                         * Start date
     C                   If        pSumUnt=#Hour                                * *HOUR
     C                   Eval      EndDTS=StrDTS+%Hours(pNbrUnt)                * Add number of hrs
     C                   Eval      EndDTS=EndDTS-%Seconds(1)                    * Subtract 1 second
     C                   Else                                                   * *DAY
     C                   Eval      EndDTS=StrDTS+%Days(pNbrUnt)                 * Add number of days
     C                   Eval      EndDTS=EndDTS-%Seconds(1)                    * Subtract 1 second
     C                   EndIf                                                  * Sum unit
     C                   Eval      ClnDTS=StrDTS-%Months(pClnHst)-              * Clean DTS
     C                             %Seconds(1)
      * Process all records in HNETTFC, write or update HNETTFCSUM
     C     *Loval        SetLL     HNETTFCR
     C                   Read      HNETTFCR                               95
     C                   DoW       not *In95
      * Determine if record must be selected for inclusion in statistics
     C                   Eval      RcdSlt=*On                                   * Record selected
     C                   If        NTSYSN<>pSysNam and pSysNam<>#All            * System match?
     C                   Eval      RcdSlt=*Off                                  * Record not sel.
     C                   EndIf                                                  * System match?
     C                   If        NTADRL<>pLclAdr and pLclAdr<>#All            * Local address matc
     C                   Eval      RcdSlt=*Off                                  * Record not sel.
     C                   EndIf                                                  * Local address matc
     C                   If        NTADRR<>pRmtAdr and pRmtAdr<>#All            * Rmt address match
     C                   Eval      RcdSlt=*Off                                  * Record not sel.
     C                   EndIf                                                  * Rmt address match
     C                   If        NTPORT<>pPort and pPort<>0                   * Port match?
     C                   Eval      RcdSlt=*Off                                  * Record not sel.
     C                   EndIf                                                  * Port match?
      * If record still selected --> Process
     C                   If        RcdSlt                                       * Record selected?
     C                   Select                                                 * Select action
      * If record falls within DTS range and not starting record --> Update summary
     C                   When      NTDTSM>=StrDTS and                           * DTS range
     C                             NTDTSM<=EndDTS and
     C                             NTITV<>0                                     * Starting record
      * Check existence of summary records for this date
     C     ChkSum        SetLL     HSUMTFCR                               94
     C                   If        not *In94
     C                   ExSR      SRGenSum
     C                   EndIf
      * Prepare fields and retrieve summary record
     C                   Eval      NSDATE=NTDTSMISO                             * Measurement date
     C                   If        pSumUnt=#Hour                                * *HOUR
     C                   Eval      NSHOUR=NTDTSMHH                              * Measurement hour
     C                   Else                                                   * DAY
     C                   Eval      NSHOUR='00'                                  * Measurement hour
     C                   EndIf                                                  * Sum unit
     C     ChnSum        Chain     HSUMTFCR                           94
     C                   If        not *In94                                    * Summary record fnd
      * Calculate average and peak bandwidth
     C                   Eval      NSBPSAVG=((NSBPSAVG*NSNBRMSM)+NTBPSTOT)/     * New average
     C                                      (NSNBRMSM+1)
     C                   Eval      NSNBRMSM=NSNBRMSM+1                          * # of measurements
     C                   If        NTBPSTOT>NSBPSPK                             * New peak
     C                   Eval      NSBPSPK=NTBPSTOT                             * Bandwidth
     C                   MoveL     NTDTSM        NSDTSPK                        * Peak DTS
     C                   EndIf                                                  * New peak
     C                   Update    HSUMTFCR
     C                   EndIf                                                  * Found
      * If record older than clean DTS --> Delete
     C                   When      NTDTSM<=ClnDTS                               * Clean DTS
     C                   Delete    HNETTFCR
     C                   EndSL                                                  * Select action
     C                   EndIf                                                  * Record selected?
     C                   Read      HNETTFCR                               95
     C                   EndDo

      * If *PRINT specified --> print report
     C                   If        pPrint=#YES                                  * *PRINT
     C                   ExSR      SRPrtSum
     C                   EndIf                                                  * *PRINT

     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRGenSum - Generate summary record(s) for date                      *
      * ------------------------------------------------------------------- *
     C     SRGenSum      BegSR
     C                   Eval      Hour=0                                       * Hour
     C                   DoW       (pSumUnt=#Hour and Hour<=23) or
     C                             (pSumUnt=#Day and Hour=0)
      * Prepare fields to update summary record
     C                   Clear                   HSUMTFCR
     C                   Eval      NSSYSN=pSysNam                               * System name
     C                   MoveL     NTDTSMISO     NSDATE                         * Date
     C                   MoveL     Hour          NSHOUR                         * Hour
     C                   Eval      NSADRL=pLclAdr                               * Local address
     C                   Eval      NSADRR=pRmtAdr                               * Remote address
     C                   Eval      NSPORT=pPort                                 * Port
     C                   Write     HSUMTFCR
     C                   Eval      Hour=Hour+1                                  * Hour
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtSum - Print Summary records                                    *
      * ------------------------------------------------------------------- *
     C     SRPrtSum      BegSR
      * Initialisation
     C                   Open      HRTVTFCP
     C                   Clear                   NSDATESv                       * Saved NSDATE
      * Print 1st page
     C                   MoveL     StrDatISO     RELDATH1                       * Starting date
     C                   Eval      LCLADRH1=pLCLADR                             * Local address
     C                   Eval      RMTADRH1=pRMTADR                             * Remote address
     C                   Eval      PORTH1=pPort                                 * Port number
     C                   Eval      SYSNAMH1=pSYSNAM                             * System name
     C                   Write     @TFCHDR                                      * Header
     C                   Write     @TFCH1P                                      * First page
     C                   Move      *On           *In01                          * Write header rcd
      * Read all HNETTFCSUM records and print
     C     *Loval        SetLL     HSUMTFCR
     C                   Read      HSUMTFCR                               95
     C     *In95         DowEQ     *Off
      * If new date and summarisation unit *HOUR, print new page
     C                   If        NSDATE<>NSDATESv and pSumUnt=#Hour
     C                   Eval      *In01=*On                                    * Print header
     C                   Eval      NSDATESv=NSDATE
     C                   EndIf
      * Write header record (overflow)?
     C     *In01         IfEQ      *On
     C                   Write     @TFCHDR                                      * Page header
     C                   Write     @TFCSUMH                                     * Summary header
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      *In21=*Off                                   * Don't print peak
     C                   If        NSBPSPK<>0
     C                   Eval      *In21=*On                                    * Print peak
     C                   MoveL     NSDTSPK       DTS@                           * Date-time
     C                   MoveL     DTS@          NSDTSPK@                       * Date-time
     C                   EndIf
     C                   Write     @TFCSUMD                                     * Summary detail
     C                   Read      HSUMTFCR                               95
     C                   EndDo
      * Write footer record
     C     *In01         IfEQ      *On
     C                   Write     @TFCHDR                                      * Page header
     C                   Write     @TFCSUMH                                     * Summary header
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
     C                   Write     @TFCSUMF                                     * Summary footer
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
