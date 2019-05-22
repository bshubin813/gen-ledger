      * ============================================================ *
      * Object:    HCHKSYN4B       *PGM RPG                          *
      *            Prints the reports that show the discrepancies.   *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT                            *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20021202 FK  Initial delivery                                *
      * 20050518 FK  IFS authorities                                 *
      * 20060328 FK  Print indicator for different target library    *
      * 20061025 FK  Print page numbers                              *
      * 20070903 FK  Include library report                          *
      * 20070918 FK  Also mark if different library for *LIB         *
      * 20070919 FK  Return number of discrepancies                  *
      * ============================================================ *
     HDatFmt(*YMD)
      * ------------------------------------------------------------ *
      * Files defined                                                *
      * ------------------------------------------------------------ *
      * Input file for Object Differences
     FHCHKSYNOBJIF   E           K DISK
      * Input file for Member Differences
     FHCHKSYNMBRIF   E           K DISK    UsrOpn
      * Input file for Authority Differences
     FHCHKSYNAUTIF   E           K DISK    UsrOpn
      * Input file for IFS Object Differences
     FHCHKSYNIFSIF   E           K DISK    UsrOpn
      * Input file for IFS Authority Differences
     FHCHKSYNIFAIF   E           K DISK    UsrOpn
      * Input file for Library descriptions
     FHCHKSYNLD IF   E           K DISK    UsrOpn
      * Output printer file for Object Differences
     FHCHKSYNPO O    E             PRINTER OflInd(*In01)
      * Output printer file for Member Differences
     FHCHKSYNPM O    E             PRINTER OflInd(*In02) UsrOpn
      * Output printer file for Authority Differences
     FHCHKSYNPA O    E             PRINTER OflInd(*In03) UsrOpn
      * Output printer file for IFS Object Differences
     FHCHKSYNPI O    E             PRINTER OflInd(*In04) UsrOpn
      * Output printer file for IFS Authority Differences
     FHCHKSYNPJ O    E             PRINTER OflInd(*In05) UsrOpn
      * Output printer file for Library report
     FHCHKSYNPL O    E             PRINTER OflInd(*In06) UsrOpn
      * Output printer file for Difference Summary
     FHCHKSYNPS O    E             PRINTER OflInd(*In07)
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Split object in parts of 80 characters
     D ObjDS           DS                                                       * Object
     D   ObjPrt                      80    Dim(63)
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Jobrun         C                   CONST('*JOBRUN0')
     D #MDY            C                   CONST('*MDY0   ')
     D #YMD            C                   CONST('*YMD0   ')
      *
     D #ALL            C                   CONST('*ALL')
     D #YES            C                   CONST('*YES')
     D #NO             C                   CONST('*NO')
     D #LOCK           C                   CONST('*LOCK')
     D #AFTER          C                   CONST('*AFTER')
     D #BOTH           C                   CONST('*BOTH')
     D #LOCKED         C                   CONST('*LOCKED')
     D #ICLUSTER       C                   CONST('*ICLUSTER')
     D #MRKSTR         C                   CONST('*MRKSTR')
      * Member / File types
     D #PFDTA          C                   CONST('PFDTA')
     D #PFSRC          C                   CONST('PFSRC')
     D #LFDTA          C                   CONST('LF   ')
     D #LFSRC          C                   CONST('LFSRC')
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
     D  IAOBJSV        S           5000a   Varying                              * Saved object
     D  i              S             10i 0                                      * Index
     D  NbrElm         S             10i 0                                      * # of elements
      *
     D DatFmt          S              8                                         * Date format
     D ChrDat          S              6                                         * Character date
     D ChrTim          S              6                                         * Character time
     D ChrDTS          S             26                                         * Character DTS
     D CvtDat          S               D                                        * Conversion date
     D CvtTim          S               T                                        * Conversion time
     D CvtDTS          S               Z                                        * Conversion DTS
     D RtvDTS          S               Z                                        * Retrieve DTS
     D ChkDTS          S               Z                                        * Check DTS
     D AgeDay          S              9  0                                      * Age in days
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *Entry        PList
     C                   Parm                    ICGRPA           10            * iCluster group
     C                   Parm                    MRKSPA            4            * Marked string
     C                   Parm                    IGNIPA            5 0          * Ignore interval
     C                   Parm                    OUTFPA            4            * Output file?
     C                   Parm                    CHKMPA            4            * Check members?
     C                   Parm                    CHKIPA            4            * Check IFS?
     C                   Parm                    CHKAPA            4            * Check authorities
     C                   Parm                    CHKLPA            4            * Check libraries?
     C                   Parm                    DSCOPA            1            * Object discrepanci
     C                   Parm                    DSCMPA            1            * Member discrepanci
     C                   Parm                    DSCAPA            1            * Auth. discrepancie
     C                   Parm                    DSCIPA            1            * IFS discrepancies
     C                   Parm                    DSCJPA            1            * IFS auth. discr.
     C                   Parm                    NBRDPA            9 0          * Number of discr.
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise return variables
     C                   Move      *Off          DSCOPA                         * Object discrepanci
     C                   Move      *Off          DSCMPA                         * Member discrepanci
     C                   Move      *Off          DSCAPA                         * Auth. discrepancie
     C                   Move      *Off          DSCIPA                         * IFS discrepancies
     C                   Move      *Off          DSCJPA                         * IFS auth. discr.
     C                   Eval      NBRDPA=0                                     * Number of discr.
      * Print Summary Header
     C                   ExSR      SRPrtSum                                     * Difference Summary
      * Print Object Discrepancies
     C                   ExSR      SRPrtObj                                     * Object discrepanc
      * Print Member Discrepancies
     C     CHKMPA        IfEQ      #YES                                         * CHKMBR(*YES)
     C                   ExSR      SRPrtMbr                                     * Member discrepanc
     C                   EndIf
      * Print Authority Discrepancies
     C     CHKAPA        IfEQ      #YES                                         * CHKAUT(*YES)
     C                   ExSR      SRPrtAut                                     * Authority diff.
     C                   EndIf
      * Print IFS Object Discrepancies
     C     CHKIPA        IfEQ      #YES                                         * CHKIFS(*YES)
     C                   ExSR      SRPrtIFS                                     * IFS differences
     C                   EndIf
      * Print IFS Object Discrepancies
     C     CHKIPA        IfEQ      #YES                                         * CHKIFS(*YES)
     C     CHKAPA        AndEQ     #YES                                         * CHKAUT(*YES)
     C                   ExSR      SRPrtIFA                                     * IFS auth. differen
     C                   EndIf
      * Print Libraries report?
     C     CHKLPA        IfEQ      #YES                                         * CHKLIB(*YES)
     C                   ExSR      SRPrtLib                                     * Libraries
     C                   EndIf
      * Return number of errors found
     C                   Eval      NBRDPA=NBRMOT+NBRMOS+NBRJD+NBRNJ+NBRNM+
     C                                    NBRMMT+NBRMMS+NBRMD+
     C                                    NBRMAT+NBRMAS+NBRAD+NBROD+
     C                                    NBRMIT+NBRMIS+NBRID+
     C                                    NBRIMAT+NBRIMAS+NBRIAD+NBRIOD+
     C                                    NBRLNE
      * End program
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtSum - Print Difference Summary                                 *
      * ------------------------------------------------------------------- *
     C     SRPrtSum      BegSR
      * Print header record
     C                   Eval      PAGENBR=1                                    * Page number
     C                   Write     @SUMHDR                                      * Header
      * Prepare for printing of 1st page
     C                   Z-Add     IGNIPA        IGNIH1                         * Ignore interval
     C                   Eval      GRPNH1 = ICGRPA                              * iCluster group
      * Print marked string?
     C                   Eval      MRKSH1 = MRKSPA                              * Marked string
     C                   Eval      *In21 = *Off
     C                   If        GRPNH1 = #MRKSTR
     C                   Eval      *In21 = *On
     C                   EndIf
     C                   Write     @SUMH1P                                      * First Page
     C                   ENDSR

      * ------------------------------------------------------------------- *
      * SRPrtObj - Print Object Discrepancies                               *
      * ------------------------------------------------------------------- *
     C     SRPrtObj      BegSR
      * Print header record
     C                   Eval      PAGENBR=1                                    * Page number
     C                   Write     @OBJHDR                                      * Header
      * Prepare for printing of 1st page
     C                   Z-Add     IGNIPA        IGNIH1                         * Ignore interval
     C                   Eval      GRPNH1 = ICGRPA                              * iCluster group
      * Print marked string?
     C                   Eval      MRKSH1 = MRKSPA                              * Marked string
     C                   Eval      *In21 = *Off
     C                   If        GRPNH1 = #MRKSTR
     C                   Eval      *In21 = *On
     C                   EndIf
     C                   Write     @OBJH1P                                      * First Page
      * Print Object Discrepancies --> Missing Objects on Target
     C                   ExSR      SRPrtMOT                                     * Missing Objects
      * Print Object Discrepancies --> Obsolete Objects on Target
     C                   ExSR      SRPrtMOS                                     * Obsolete Objects
      * Print Object Discrepancies --> Journal differences
     C                   ExSR      SRPrtJD                                      * Journal Difference
      * Print Object Discrepancies --> Non-journalled files
     C                   ExSR      SRPrtNJ                                      * Non-journalled
      * Print Object Discrepancies --> Non-mirrored data objects
     C                   ExSR      SRPrtNM                                      * Non-mirrored
     C                   ENDSR

      * ------------------------------------------------------------------- *
      * SRPrtMbr - Print Member Discrepancies                               *
      * ------------------------------------------------------------------- *
     C     SRPrtMbr      BegSR
      * Open the required files
     C                   Open      HCHKSYNMBR
     C                   Open      HCHKSYNPM
      * Print header record
     C                   Eval      PAGENBR=1                                    * Page number
     C                   Write     @MBRHDR                                      * Header
      * Prepare for printing of 1st page
     C                   Z-Add     IGNIPA        IGNIH1                         * Ignore interval
     C                   Eval      GRPNH1 = ICGRPA                              * iCluster group
      * Print marked string?
     C                   Eval      MRKSH1 = MRKSPA                              * Marked string
     C                   Eval      *In21 = *Off
     C                   If        GRPNH1 = #MRKSTR
     C                   Eval      *In21 = *On
     C                   EndIf
     C                   Write     @MBRH1P                                      * First Page
      * Print Member Discrepancies --> Missing Members on Target
     C                   ExSR      SRPrtMMT                                     * Missing Members
      * Print Member Discrepancies --> Obsolete Members on Target
     C                   ExSR      SRPrtMMS                                     * Obsolete Members
      * Print Member Discrepancies --> Member differences
     C                   ExSR      SRPrtMD                                      * Member Differences
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtAut - Print Authority Discrepancies                            *
      * ------------------------------------------------------------------- *
     C     SRPrtAut      BegSR
      * Open the required files
     C                   Open      HCHKSYNAUT
     C                   Open      HCHKSYNPA
      * Print header record
     C                   Eval      PAGENBR=1                                    * Page number
     C                   Write     @AUTHDR                                      * Header
      * Prepare for printing of 1st page
     C                   Z-Add     IGNIPA        IGNIH1                         * Ignore interval
     C                   Eval      GRPNH1 = ICGRPA                              * iCluster group
      * Print marked string?
     C                   Eval      MRKSH1 = MRKSPA                              * Marked string
     C                   Eval      *In21 = *Off
     C                   If        GRPNH1 = #MRKSTR
     C                   Eval      *In21 = *On
     C                   EndIf
     C                   Write     @AUTH1P                                      * First Page
      * Print Auth. Discrepancies --> Missing Auth. on Target
     C                   ExSR      SRPrtMAT                                     * Missing Auth.
      * Print Auth. Discrepancies --> Obsolete Auth. on Target
     C                   ExSR      SRPrtMAS                                     * Obsolete Auth.
      * Print Auth. Discrepancies --> Auth. differences
     C                   ExSR      SRPrtAD                                      * Auth. Differences
      * Print Auth. Discrepancies --> Owner differences
     C                   ExSR      SRPrtOD                                      * Owner Difference
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtIFS - Print IFS Object Discrepancies                           *
      * ------------------------------------------------------------------- *
     C     SRPrtIFS      BegSR
      * Open the required files
     C                   Open      HCHKSYNIFS
     C                   Open      HCHKSYNPI
      * Print header record
     C                   Eval      PAGENBR=1                                    * Page number
     C                   Write     @IFSHDR                                      * Header
      * Prepare for printing of 1st page
     C                   Z-Add     IGNIPA        IGNIH1                         * Ignore interval
     C                   Eval      GRPNH1 = ICGRPA                              * iCluster group
      * Print marked string?
     C                   Eval      MRKSH1 = MRKSPA                              * Marked string
     C                   Eval      *In21 = *Off
     C                   If        GRPNH1 = #MRKSTR
     C                   Eval      *In21 = *On
     C                   EndIf
     C                   Write     @IFSH1P                                      * First Page
      * Print IFS Object Discrepancies --> Missing Objects on Target
     C                   ExSR      SRPrtMIT                                     * Missing IFS Obj
      * Print IFS Object Discrepancies --> Obsolete Objects on Target
     C                   ExSR      SRPrtMIS                                     * Obsolete IFS Obj
      * Print IFS Object Discrepancies --> IFS Object differences
     C                   ExSR      SRPrtID                                      * IFS Obj. Diff.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtIFA - Print IFS authority discrepancies                        *
      * ------------------------------------------------------------------- *
     C     SRPrtIFA      BegSR
      * Open the required files
     C                   Open      HCHKSYNIFA
     C                   Open      HCHKSYNPJ
      * Print header record
     C                   Eval      PAGENBR=1                                    * Page number
     C                   Write     @IFAHDR                                      * Header
      * Prepare for printing of 1st page
     C                   Z-Add     IGNIPA        IGNIH1                         * Ignore interval
     C                   Eval      GRPNH1 = ICGRPA                              * iCluster group
      * Print marked string?
     C                   Eval      MRKSH1 = MRKSPA                              * Marked string
     C                   Eval      *In21 = *Off
     C                   If        GRPNH1 = #MRKSTR
     C                   Eval      *In21 = *On
     C                   EndIf
     C                   Write     @IFAH1P                                      * First Page
      * Print IFS Authority Discrepancies --> Missing authorities
     C                   ExSR      SRPrtIMAT                                    * Missing IFS auth.
      * Print IFS Authority Discrepancies --> Obsolete authorities
     C                   ExSR      SRPrtIMAS                                    * Obsolete IFS auth.
      * Print IFS Authority Discrepancies --> Authority differences
     C                   ExSR      SRPrtIAD                                     * IFS auth. differen
      * Print IFS Authority Discrepancies --> Owner differences
     C                   ExSR      SRPrtIOD                                     * IFS auth. differen
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMOT - Print Missing Objects on Target                          *
      * ------------------------------------------------------------------- *
     C     SRPrtMOT      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMOT                         * # of Missing Obj
     C                   Move      *On           *In01                          * Write header rcd
      * Read all HCHKSYNOBJ records and select
     C     *Loval        SetLL     SYNOBJ@
     C                   Read      SYNOBJ@                                95
     C     *In95         DowEQ     *Off
     C     ODMOT         IfEQ      'Y'                                          * Missing object
      * Write header record (overflow)?
     C     *In01         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJMOTH                                     * Missing object hdr
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        ODCMPL<>ODLBNM or ODCMPO<>ODOBNM             * Different target?
     C                             or ODCMPL<>ODTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @OBJMOTD                                     * Missing object dtl
     C                   Add       1             NBRMOT                         * # of Missing obj.
     C                   Move      *On           DSCOPA                         * Object discrepanci
     C                   EndIf                                                  * Missing object
     C                   Read      SYNOBJ@                                95
     C                   EndDo
      * Write footer record
     C     *In01         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJMOTH                                     * Missing object hdr
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
     C                   Write     @OBJMOTF                                     * Missing object
      * Print the summary also
     C                   Write     @SUMMOTF                                     * Missing object
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMOS - Print Obsolete Objects on Target                         *
      * ------------------------------------------------------------------- *
     C     SRPrtMOS      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMOS                         * # of Obsolete Obj
     C                   Move      *On           *In01                          * Write header rcd
      * Read all HCHKSYNOBJ records and select
     C     *Loval        SetLL     SYNOBJ@
     C                   Read      SYNOBJ@                                95
     C     *In95         DowEQ     *Off
     C     ODMOS         IfEQ      'Y'                                          * Obsolete object
      * Write header record (overflow)?
     C     *In01         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJMOSH                                     * Obsolete object hd
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        ODCMPL<>ODLBNM or ODCMPO<>ODOBNM             * Different target?
     C                             or ODCMPL<>ODTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @OBJMOSD                                     * Obsolete object dt
     C                   Add       1             NBRMOS                         * # of Obsolete obj.
     C                   Move      *On           DSCOPA                         * Object discrepanci
     C                   EndIf                                                  * Obsolete object
     C                   Read      SYNOBJ@                                95
     C                   EndDo
      * Write footer record
     C     *In01         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJMOSH                                     * Obsolete object hd
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
     C                   Write     @OBJMOSF                                     * Obsolete object
      * Print the summary also
     C                   Write     @SUMMOSF                                     * Obsolete object
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtJD - Print Journal Differences                                 *
      * ------------------------------------------------------------------- *
     C     SRPrtJD       BegSR
      * Initialisation
     C                   Z-Add     0             NBRJD                          * # of Journal Diff.
     C                   Z-Add     0             NBRJDL                         * # of JD locked
     C                   Move      *On           *In02                          * Write header rcd
      * Read all HCHKSYNOBJ records and select
     C     *Loval        SetLL     SYNOBJ@
     C                   Read      SYNOBJ@                                95
     C     *In95         DowEQ     *Off
      * Check journal difference
     C     ODJD          IfEQ      'Y'                                          * Journal Difference
      * Write header record (overflow)?
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJJDH                                      * Journal diff. hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
      * Fill calculated fields
      * Fill journal status
     C                   Select
     C                   When      SOJRST='0'                                   * Not journalled
     C                   MoveL(p)  #NO           SOJRST@                        * Journal status
     C                   When      SOJRST='1'                                   * Journalled
     C                   MoveL(p)  #YES          SOJRST@                        * Journal status
     C                   Other                                                  * Locked/Damaged
     C                   MoveL(p)  #LOCK         SOJRST@                        * Journal status
     C                   EndSL
     C                   Select
     C                   When      TOJRST='0'                                   * Not journalled
     C                   MoveL(p)  #NO           TOJRST@                        * Journal status
     C                   When      TOJRST='1'                                   * Journalled
     C                   MoveL(p)  #YES          TOJRST@                        * Journal status
     C                   Other                                                  * Locked/Damaged
     C                   MoveL(p)  #LOCK         TOJRST@                        * Journal status
     C                   EndSL
      * Fill journal images
     C                   Select
     C                   When      SOJRIM='0'                                   * After images
     C                   MoveL(p)  #AFTER        SOJRIM@                        * Journal images
     C                   When      SOJRIM='1'                                   * Both images
     C                   MoveL(p)  #BOTH         SOJRIM@                        * Journal images
     C                   EndSL
     C                   Select
     C                   When      TOJRIM='0'                                   * After images
     C                   MoveL(p)  #AFTER        TOJRIM@                        * Journal images
     C                   When      TOJRIM='1'                                   * Both images
     C                   MoveL(p)  #BOTH         TOJRIM@                        * Journal images
     C                   EndSL
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        ODCMPL<>ODLBNM or ODCMPO<>ODOBNM             * Different target?
     C                             or ODCMPL<>ODTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @OBJJDD                                      * Journal diff. dtl
     C                   If        (SOOBLK='0' and TOOBLK='0')
     C                   Add       1             NBRJD                          * # of journal Diff.
     C                   Else
     C                   Add       1             NBRJDL                         * # of JD lock
     C                   EndIf
     C                   Move      *On           DSCOPA                         * Object discrepanci
     C                   EndIf                                                  * Journal diff.
     C                   Read      SYNOBJ@                                95
     C                   EndDo
      * Write footer record
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Member header
     C                   Write     @OBJJDH                                      * Journal diff. hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
     C                   Write     @OBJJDF                                      * Journal diff.
      * Print the summary also
     C                   Write     @SUMJDF                                      * Journal diff.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtNJ - Non-journalled objects                                    *
      * ------------------------------------------------------------------- *
     C     SRPrtNJ       BegSR
      * Initialisation
     C                   Z-Add     0             NBRNJ                          * # of Non-journalle
     C                   Z-Add     0             NBRNJL                         * # of NJ locked
     C                   Move      *On           *In02                          * Write header rcd
      * Read all HCHKSYNOBJ records and select
     C     *Loval        SetLL     SYNOBJ@
     C                   Read      SYNOBJ@                                95
     C     *In95         DowEQ     *Off
      * Check journal difference
     C     ODNJ          IfEQ      'Y'                                          * Non-journalled
      * Write header record (overflow)?
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJNJH                                      * Non-journal. hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
      * Fill journal status
     C                   Select
     C                   When      SOJRST='0'                                   * Not journalled
     C                   MoveL(p)  #NO           SOJRST@                        * Journal status
     C                   When      SOJRST='1'                                   * Journalled
     C                   MoveL(p)  #YES          SOJRST@                        * Journal status
     C                   Other                                                  * Locked/Damaged
     C                   MoveL(p)  #LOCK         SOJRST@                        * Journal status
     C                   EndSL
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        ODCMPL<>ODLBNM or ODCMPO<>ODOBNM             * Different target?
     C                             or ODCMPL<>ODTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @OBJNJD                                      * Non-journal. dtl
     C                   If        SOOBLK='0'
     C                   Add       1             NBRNJ                          * # of non-journal
     C                   Else
     C                   Add       1             NBRNJL                         * # of NJ lock
     C                   EndIf
     C                   Move      *On           DSCOPA                         * Object discrepanci
     C                   EndIf                                                  * Non-journal
     C                   Read      SYNOBJ@                                95
     C                   EndDo
      * Write footer record
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJNJH                                      * Non-journal. hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
     C                   Write     @OBJNJF                                      * Non-journal
      * Print the summary also
     C                   Write     @SUMNJO                                      * Non-journal
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtNM - Non-mirrored data objects                                 *
      * ------------------------------------------------------------------- *
     C     SRPrtNM       BegSR
      * Initialisation
     C                   Z-Add     0             NBRNM                          * # of Non-mirrored
     C                   Move      *On           *In02                          * Write header rcd
      * Read all HCHKSYNOBJ records and select
     C     *Loval        SetLL     SYNOBJ@
     C                   Read      SYNOBJ@                                95
     C     *In95         DowEQ     *Off
      * Check non-mirrored
     C     ODNM          IfEQ      'Y'                                          * Non-mirrored
      * Write header record (overflow)?
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJNMH                                      * Non-mirror hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
      * Fill journal status
     C                   Select
     C                   When      SOJRST='0'                                   * Not journalled
     C                   MoveL(p)  #NO           SOJRST@                        * Journal status
     C                   When      SOJRST='1'                                   * Journalled
     C                   MoveL(p)  #YES          SOJRST@                        * Journal status
     C                   Other                                                  * Locked/Damaged
     C                   MoveL(p)  #LOCK         SOJRST@                        * Journal status
     C                   EndSL
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        ODCMPL<>ODLBNM or ODCMPO<>ODOBNM             * Different target?
     C                             or ODCMPL<>ODTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @OBJNMD                                      * Non-mirror dtl
     C                   Add       1             NBRNM                          * # of non-mirror
     C                   Move      *On           DSCOPA                         * Object discrepanci
     C                   EndIf                                                  * Non-journal
     C                   Read      SYNOBJ@                                95
     C                   EndDo
      * Write footer record
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @OBJHDR                                      * Object header
     C                   Write     @OBJNMH                                      * Non-mirror hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
     C                   Write     @OBJNMF                                      * Non-mirror ftr
      * Print the summary also
     C                   Write     @SUMNMO                                      * Non-mirror
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMMT - Print Missing Members on Target                          *
      * ------------------------------------------------------------------- *
     C     SRPrtMMT      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMMT                         * # of Missing Mbr
     C                   Move      *On           *In02                          * Write header rcd
      * Read all HCHKSYNMBR records and select
     C     *Loval        SetLL     SYNMBR@
     C                   Read      SYNMBR@                                95
     C     *In95         DowEQ     *Off
     C     MBMMT         IfEQ      'Y'                                          * Missing member
      * Write header record (overflow)?
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @MBRHDR                                      * Member header
     C                   Write     @MBRMMTH                                     * Missing member hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        MBCMPL<>MBLIB or MBCMPF<>MBFILE              * Different target?
     C                             or MBCMPL<>MBTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   ExSR      SRRtvMT                                      * Retrieve mbr type
     C                   Write     @MBRMMTD                                     * Missing member dtl
     C                   Add       1             NBRMMT                         * # of Missing mbr.
     C                   Move      *On           DSCMPA                         * Member discrepanci
     C                   EndIf                                                  * Missing member
     C                   Read      SYNMBR@                                95
     C                   EndDo
      * Write footer record
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @MBRHDR                                      * Member header
     C                   Write     @MBRMMTH                                     * Missing member hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
     C                   Write     @MBRMMTF                                     * Missing member
      * Print the summary also
     C                   Write     @SUMMMTF                                     * Missing member
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMMS - Print Obsolete Members on Target                         *
      * ------------------------------------------------------------------- *
     C     SRPrtMMS      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMMS                         * # of Obsolete Mbr
     C                   Move      *On           *In02                          * Write header rcd
      * Read all HCHKSYNMBR records and select
     C     *Loval        SetLL     SYNMBR@
     C                   Read      SYNMBR@                                95
     C     *In95         DowEQ     *Off
     C     MBMMS         IfEQ      'Y'                                          * Obsolete member
      * Write header record (overflow)?
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @MBRHDR                                      * Member header
     C                   Write     @MBRMMSH                                     * Obsolete member hd
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        MBCMPL<>MBLIB or MBCMPF<>MBFILE              * Different target?
     C                             or MBCMPL<>MBTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   ExSR      SRRtvMT                                      * Retrieve mbr type
     C                   Write     @MBRMMSD                                     * Obsolete member dt
     C                   Add       1             NBRMMS                         * # of Obsolete mbr.
     C                   Move      *On           DSCMPA                         * Member discrepanci
     C                   EndIf                                                  * Obsolete member
     C                   Read      SYNMBR@                                95
     C                   EndDo
      * Write footer record
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @MBRHDR                                      * Member header
     C                   Write     @MBRMMSH                                     * Obsolete member hd
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
     C                   Write     @MBRMMSF                                     * Obsolete member
      * Print the summary also
     C                   Write     @SUMMMSF                                     * Obsolete member
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMD - Print Member Differences                                  *
      * ------------------------------------------------------------------- *
     C     SRPrtMD       BegSR
      * Initialisation
     C                   Z-Add     0             NBRMD                          * # of Member Diff.
     C                   Z-Add     0             NBRMDL                         * # of MD locked
     C                   Move      *On           *In02                          * Write header rcd
      * Read all HCHKSYNMBR records and select
     C     *Loval        SetLL     SYNMBR@
     C                   Read      SYNMBR@                                95
     C     *In95         DowEQ     *Off
     C     MBMD          IfEQ      'Y'                                          * Member Difference
      * Write header record (overflow)?
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @MBRHDR                                      * Member header
     C                   Write     @MBRMDH                                      * Member diff. hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        MBCMPL<>MBLIB or MBCMPF<>MBFILE              * Different target?
     C                             or MBCMPL<>MBTGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   ExSR      SRRtvMT                                      * Retrieve mbr type
     C                   Write     @MBRMDD                                      * Member diff. dtl
     C                   If        (SMLOCK='N' and TMLOCK='N')
     C                   Add       1             NBRMD                          * # of member Diff.
     C                   Else
     C                   Add       1             NBRMDL                         * # of MD lock
     C                   EndIf
     C                   Move      *On           DSCMPA                         * Member discrepanci
     C                   EndIf                                                  * Member diff.
     C                   Read      SYNMBR@                                95
     C                   EndDo
      * Write footer record
     C     *In02         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @MBRHDR                                      * Member header
     C                   Write     @MBRMDH                                      * Member diff. hdr
     C                   Move      *Off          *In02
     C                   EndIf                                                  * Overflow
     C                   Write     @MBRMDF                                      * Member difference
      * Print the summary also
     C                   Write     @SUMMDF                                      * Member difference
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMAT - Print Missing Auth. on Target                            *
      * ------------------------------------------------------------------- *
     C     SRPrtMAT      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMAT                         * # of Missing Aut
     C                   Z-Add     0             NBRMATL                        * # of MA locked
     C                   Move      *On           *In03                          * Write header rcd
      * Read all HCHKSYNAUT records and select
     C     *Loval        SetLL     SYNAUT@
     C                   Read      SYNAUT@                                95
     C     *In95         DowEQ     *Off
     C     OAMAT         IfEQ      'Y'                                          * Missing auth.
      * Write header record (overflow)?
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Auth. header
     C                   Write     @AUTMATH                                     * Missing auth. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        OACMPL<>OALIB or OACMPO<>OANAME              * Different target?
     C                             or OACMPL<>OATGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @AUTMATD                                     * Missing auth. dtl
     C                   If        SAOBJA<>#LOCKED
     C                   Add       1             NBRMAT                         * # of Missing auth.
     C                   Else
     C                   Add       1             NBRMATL                        * # of MA lock
     C                   EndIf
     C                   Move      *On           DSCAPA                         * Auth. discrepancie
     C                   EndIf                                                  * Missing auth.
     C                   Read      SYNAUT@                                95
     C                   EndDo
      * Write footer record
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Auth. header
     C                   Write     @AUTMATH                                     * Missing auth. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
     C                   Write     @AUTMATF                                     * Missing auth.
      * Print the summary also
     C                   Write     @SUMMATF                                     * Missing auth.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMAS - Print Obsolete Auth. on Target                           *
      * ------------------------------------------------------------------- *
     C     SRPrtMAS      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMAS                         * # of Obsolete Aut
     C                   Z-Add     0             NBRMASL                        * # of OA locked
     C                   Move      *On           *In03                          * Write header rcd
      * Read all HCHKSYNAUT records and select
     C     *Loval        SetLL     SYNAUT@
     C                   Read      SYNAUT@                                95
     C     *In95         DowEQ     *Off
     C     OAMAS         IfEQ      'Y'                                          * Obsolete auth.
      * Write header record (overflow)?
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Auth. header
     C                   Write     @AUTMASH                                     * Obsolete auth. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        OACMPL<>OALIB or OACMPO<>OANAME              * Different target?
     C                             or OACMPL<>OATGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @AUTMASD                                     * Obsolete auth. dtl
     C                   If        TAOBJA<>#LOCKED
     C                   Add       1             NBRMAS                         * # of Obsolete aut.
     C                   Else
     C                   Add       1             NBRMASL                        * # of OA lock
     C                   EndIf
     C                   Move      *On           DSCAPA                         * Auth. discrepancie
     C                   EndIf                                                  * Obsolete auth.
     C                   Read      SYNAUT@                                95
     C                   EndDo
      * Write footer record
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Auth. header
     C                   Write     @AUTMASH                                     * Obsolete auth. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
     C                   Write     @AUTMASF                                     * Obsolete auth.
      * Print the summary also
     C                   Write     @SUMMASF                                     * Obsolete auth.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtAD - Print Auth. Differences                                   *
      * ------------------------------------------------------------------- *
     C     SRPrtAD       BegSR
      * Initialisation
     C                   Z-Add     0             NBRAD                          * # of Auth. Diff.
     C                   Z-Add     0             NBRADL                         * # of AD lock
     C                   Move      *On           *In03                          * Write header rcd
      * Read all HCHKSYNAUT records and select
     C     *Loval        SetLL     SYNAUT@
     C                   Read      SYNAUT@                                95
     C     *In95         DowEQ     *Off
     C     OAAD          IfEQ      'Y'                                          * Auth. Difference
      * Write header record (overflow)?
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Auth. header
     C                   Write     @AUTADH                                      * Auth. diff. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        OACMPL<>OALIB or OACMPO<>OANAME              * Different target?
     C                             or OACMPL<>OATGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @AUTADD                                      * Auth. diff. dtl
     C                   If        (SAOBJA<>#LOCKED and TAOBJA<>#LOCKED)
     C                   Add       1             NBRAD                          * # of auth. diff.
     C                   Else
     C                   Add       1             NBRADL                         * # of AD lock
     C                   EndIf
     C                   Move      *On           DSCAPA                         * Auth. discrepancie
     C                   EndIf                                                  * Member diff.
     C                   Read      SYNAUT@                                95
     C                   EndDo
      * Write footer record
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Auth. header
     C                   Write     @AUTADH                                      * Auth. diff. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
     C                   Write     @AUTADF                                      * Auth. difference
      * Print the summary also
     C                   Write     @SUMADF                                      * Auth. difference
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtOD - Owner Differences                                         *
      * ------------------------------------------------------------------- *
     C     SRPrtOD       BegSR
      * Initialisation
     C                   Z-Add     0             NBROD                          * # of Owner diff.
     C                   Z-Add     0             NBRODL                         * # of Owner lock
     C                   Move      *On           *In03                          * Write header rcd
     C                   MoveL     *Blanks       GRPNSV           10            * Saved group
     C                   MoveL     *Blanks       LIBSV            10            * Saved library
     C                   MoveL     *Blanks       NAMESV           10            * Saved object
     C                   MoveL     *Blanks       TYPESV            8            * Saved object type
      * Read all HCHKSYNAUT records and select
     C     *Loval        SetLL     SYNAUT@
     C                   Read      SYNAUT@                                95
     C     *In95         DowEQ     *Off
      * Only process once for every object
     C     OAGRPN        IfNE      GRPNSV                                       * Saved group
     C     OALIB         OrNE      LIBSV                                        * Saved library
     C     OANAME        OrNE      NAMESV                                       * Saved object
     C     OATYPE        OrNE      TYPESV                                       * Saved object type
      * Check owner difference
     C     OAOD          IfEQ      'Y'                                          * Owner difference
      * Write header record (overflow)?
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Authority header
     C                   Write     @AUTODH                                      * Owner diff. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
      * Print indicator for different target library
     C                   Eval      DIFTWY=' '                                   * Different target l
     C                   If        OACMPL<>OALIB or OACMPO<>OANAME              * Different target?
     C                             or OACMPL<>OATGTL                            * Different target?
     C                   Eval      DIFTWY='*'
     C                   EndIf                                                  * Different target?
      * Write detail record
     C                   Write     @AUTODD                                      * Owner diff. dtl
     C                   If        (SAOWN<>#LOCKED and TAOWN<>#LOCKED)
     C                   Add       1             NBROD                          * # of owner diff.
     C                   Else
     C                   Add       1             NBRODL                         * # of OD lock
     C                   EndIf
     C                   Move      *On           DSCAPA                         * Auth. discrepancie
     C                   EndIf                                                  * Owner diff.
     C                   EndIf                                                  * Changed group
      * Update saved values
     C                   MoveL     OAGRPN        GRPNSV                         * Saved group
     C                   MoveL     OALIB         LIBSV                          * Saved library
     C                   MoveL     OANAME        NAMESV                         * Saved object
     C                   MoveL     OATYPE        TYPESV                         * Saved object type
     C                   Read      SYNAUT@                                95
     C                   EndDo
      * Write footer record
     C     *In03         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @AUTHDR                                      * Authority header
     C                   Write     @AUTODH                                      * Owner diff. hdr
     C                   Move      *Off          *In03
     C                   EndIf                                                  * Overflow
     C                   Write     @AUTODF                                      * Owner Difference
      * Print the summary also
     C                   Write     @SUMODF                                      * Owner Difference
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMIT - Print Missing IFS Objects on Target                      *
      * ------------------------------------------------------------------- *
     C     SRPrtMIT      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMIT                         * # of Missing Aut
     C                   Move      *On           *In04                          * Write header rcd
      * Read all HCHKSYNIFS records and select
     C     *Loval        SetLL     SYNIFS@
     C                   Read      SYNIFS@                                95
     C     *In95         DowEQ     *Off
     C     IDMIT         IfEQ      'Y'                                          * Missing IFS Obj.
      * Write header record (overflow)?
     C     *In04         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFSHDR                                      * IFS Object hdr
     C                   Write     @IFSMITH                                     * Missing IFS Obj hd
     C                   Move      *Off          *In04
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      OBJMITD = IDOBJ
     C                   Write     @IFSMITD                                     * Missing IFS O dtl
     C                   Add       1             NBRMIT                         * # of IFS Objects
     C                   Move      *On           DSCIPA                         * IFS discrepancies
     C                   EndIf                                                  * Missing IFS Obj.
     C                   Read      SYNIFS@                                95
     C                   EndDo
      * Write footer record
     C     *In04         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFSHDR                                      * IFS Object hdr
     C                   Write     @IFSMITH                                     * Missing IFS Obj hd
     C                   Move      *Off          *In04
     C                   EndIf                                                  * Overflow
     C                   Write     @IFSMITF                                     * Missing IFS Obj.
      * Print the summary also
     C                   Write     @SUMMITF                                     * Missing IFS Obj.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtMIS - Print Obsolete IFS Objects on Target                     *
      * ------------------------------------------------------------------- *
     C     SRPrtMIS      BegSR
      * Initialisation
     C                   Z-Add     0             NBRMIS                         * # of Obsolete Aut
     C                   Move      *On           *In04                          * Write header rcd
      * Read all HCHKSYNIFS records and select
     C     *Loval        SetLL     SYNIFS@
     C                   Read      SYNIFS@                                95
     C     *In95         DowEQ     *Off
     C     IDMIS         IfEQ      'Y'                                          * Obsolete IFS Obj.
      * Write header record (overflow)?
     C     *In04         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFSHDR                                      * IFS Object hdr
     C                   Write     @IFSMISH                                     * Obsolete IFS Obj h
     C                   Move      *Off          *In04
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      OBJMISD = IDOBJ
     C                   Write     @IFSMISD                                     * Obsolete IFS O dtl
     C                   Add       1             NBRMIS                         * # of IFS Objects
     C                   Move      *On           DSCIPA                         * IFS discrepancies
     C                   EndIf                                                  * Missing IFS Obj.
     C                   Read      SYNIFS@                                95
     C                   EndDo
      * Write footer record
     C     *In04         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFSHDR                                      * IFS Object hdr
     C                   Write     @IFSMISH                                     * Obsolete IFS Obj h
     C                   Move      *Off          *In04
     C                   EndIf                                                  * Overflow
     C                   Write     @IFSMISF                                     * Obsolete IFS Obj.
      * Print the summary also
     C                   Write     @SUMMISF                                     * Obsolete IFS Obj.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtID - Print IFS Object Differences                              *
      * ------------------------------------------------------------------- *
     C     SRPrtID       BegSR
      * Initialisation
     C                   Z-Add     0             NBRID                          * # of IFS Differenc
     C                   Move      *On           *In04                          * Write header rcd
      * Read all HCHKSYNIFS records and select
     C     *Loval        SetLL     SYNIFS@
     C                   Read      SYNIFS@                                95
     C     *In95         DowEQ     *Off
     C     IDID          IfEQ      'Y'                                          * IFS Object diff.
      * Write header record (overflow)?
     C     *In04         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFSHDR                                      * IFS Object hdr
     C                   Write     @IFSIDH                                      * IFS Object diff.
     C                   Move      *Off          *In04
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      OBJIDD = IDOBJ
     C                   Write     @IFSIDD                                      * IFS Object diff.
     C                   Add       1             NBRID                          * # of IFS Objects
     C                   Move      *On           DSCIPA                         * IFS discrepancies
     C                   EndIf                                                  * IFS Object diff.
     C                   Read      SYNIFS@                                95
     C                   EndDo
      * Write footer record
     C     *In04         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFSHDR                                      * IFS Object hdr
     C                   Write     @IFSIDH                                      * IFS Object diff.
     C                   Move      *Off          *In04
     C                   EndIf                                                  * Overflow
     C                   Write     @IFSIDF                                      * IFS Object diff.
      * Print the summary also
     C                   Write     @SUMIDF                                      * IFS Object diff.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtIMAT - Print Missing IFS auth.                                 *
      * ------------------------------------------------------------------- *
     C     SRPrtIMAT     BegSR
      * Initialisation
     C                   Clear                   IAOBJSV                        * Saved object
     C                   Z-Add     0             NBRIMAT                        * # of Missing IFS a
     C                   Move      *On           *In05                          * Write header rcd
      * Read all HCHKSYNIFA records and select
     C     *Loval        SetLL     SYNIFA@
     C                   Read      SYNIFA@                                95
     C     *In95         DowEQ     *Off
     C     IAMAT         IfEQ      'Y'                                          * Missing auth.
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      *In22 = *Off                                 * Don't print object
      * Handle printing of new object
     C                   If        IAOBJ <> IAOBJSV                             * New object
     C                   Eval      *In21 = *On                                  * Print target/group
     C                   Eval      *In22 = *On                                  * Print object
      * Split object into parts of 80 characters
     C                   Eval      ObjDS = IAOBJ                                * IFS object
     C                   Eval      NbrElm = %Div(%Len(IAOBJ):80)+1              * # of elements
     C                   Eval      i = 1
     C                   DoW       i <= NbrElm
     C                   Eval      IAOBJ@ = ObjPrt(i)                           * Object part
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAMATH                                     * Missing auth. hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAMATD                                     * Missing auth. dtl
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      i = i + 1
     C                   EndDo
     C                   Eval      IAOBJSV = IAOBJ                              * Saved object
     C                   EndIf                                                  * New object
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAMATH                                     * Missing auth. hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      *In22 = *Off                                 * Don't print object
     C                   Write     @IFAMATD                                     * Missing auth. dtl
     C                   Add       1             NBRIMAT                        * # of Missing auth.
     C                   Move      *On           DSCJPA                         * IFS auth. discr.
     C                   EndIf                                                  * Missing auth.
     C                   Read      SYNIFA@                                95
     C                   EndDo
      * Write footer record
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAMATH                                     * Missing auth. hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAMATF                                     * Missing auth.
      * Print the summary also
     C                   Write     @SUMIMAT                                     * Missing IFS auth.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtIMAS - Print Obsolete IFS auth.                                *
      * ------------------------------------------------------------------- *
     C     SRPrtIMAS     BegSR
      * Initialisation
     C                   Clear                   IAOBJSV                        * Saved object
     C                   Z-Add     0             NBRIMAS                        * # of Obs. IFS auth
     C                   Move      *On           *In05                          * Write header rcd
      * Read all HCHKSYNIFA records and select
     C     *Loval        SetLL     SYNIFA@
     C                   Read      SYNIFA@                                95
     C     *In95         DowEQ     *Off
     C     IAMAS         IfEQ      'Y'                                          * Obsolete IFS auth.
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      *In22 = *Off                                 * Don't print object
      * Handle printing of new object
     C                   If        IAOBJ <> IAOBJSV                             * New object
     C                   Eval      *In21 = *On                                  * Print target/group
     C                   Eval      *In22 = *On                                  * Print object
      * Split object into parts of 80 characters
     C                   Eval      ObjDS = IAOBJ                                * IFS object
     C                   Eval      NbrElm = %Div(%Len(IAOBJ):80)+1              * # of elements
     C                   Eval      i = 1
     C                   DoW       i <= NbrElm
     C                   Eval      IAOBJ@ = ObjPrt(i)                           * Object part
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAMASH                                     * Obsolete auth. hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAMASD                                     * Obsolete auth. dtl
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      i = i + 1
     C                   EndDo
     C                   Eval      IAOBJSV = IAOBJ                              * Saved object
     C                   EndIf                                                  * New object
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAMASH                                     * Obsolete auth. hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      *In22 = *Off                                 * Don't print object
     C                   Write     @IFAMASD                                     * Obsolete auth. dtl
     C                   Add       1             NBRIMAS                        * # of Obsolete auth
     C                   Move      *On           DSCJPA                         * IFS auth. discr.
     C                   EndIf                                                  * Missing auth.
     C                   Read      SYNIFA@                                95
     C                   EndDo
      * Write footer record
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAMASH                                     * Obsolete auth. hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAMASF                                     * Obsolete auth.
      * Print the summary also
     C                   Write     @SUMIMAS                                     * Obsolete IFS auth.
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtIAD - Print IFS auth. differences                              *
      * ------------------------------------------------------------------- *
     C     SRPrtIAD      BegSR
      * Initialisation
     C                   Clear                   IAOBJSV                        * Saved object
     C                   Z-Add     0             NBRIAD                         * # of IFS auth. dif
     C                   Move      *On           *In05                          * Write header rcd
      * Read all HCHKSYNIFA records and select
     C     *Loval        SetLL     SYNIFA@
     C                   Read      SYNIFA@                                95
     C     *In95         DowEQ     *Off
     C     IAAD          IfEQ      'Y'                                          * IFS auth. dif
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      *In22 = *Off                                 * Don't print object
      * Handle printing of new object
     C                   If        IAOBJ <> IAOBJSV                             * New object
     C                   Eval      *In21 = *On                                  * Print target/group
     C                   Eval      *In22 = *On                                  * Print object
      * Split object into parts of 80 characters
     C                   Eval      ObjDS = IAOBJ                                * IFS object
     C                   Eval      NbrElm = %Div(%Len(IAOBJ):80)+1              * # of elements
     C                   Eval      i = 1
     C                   DoW       i <= NbrElm
     C                   Eval      IAOBJ@ = ObjPrt(i)                           * Object part
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAADH                                      * IFS auth. dif hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAADD                                      * IFS auth. dif dtl
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      i = i + 1
     C                   EndDo
     C                   Eval      IAOBJSV = IAOBJ                              * Saved object
     C                   EndIf                                                  * New object
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAADH                                      * IFS auth. dif hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      *In22 = *Off                                 * Don't print object
     C                   Write     @IFAADD                                      * IFS auth. dif dtl
     C                   Add       1             NBRIAD                         * # of auth. dif
     C                   Move      *On           DSCJPA                         * IFS auth. discr.
     C                   EndIf                                                  * Missing auth.
     C                   Read      SYNIFA@                                95
     C                   EndDo
      * Write footer record
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAADH                                      * IFS auth. dif hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAADF                                      * IFS auth. dif ftr
      * Print the summary also
     C                   Write     @SUMIAD                                      * IFS auth. dif sum
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtIOD - Print IFS owner differences                              *
      * ------------------------------------------------------------------- *
     C     SRPrtIOD      BegSR
      * Initialisation
     C                   Clear                   IAOBJSV                        * Saved object
     C                   Z-Add     0             NBRIOD                         * # of IFS owner dif
     C                   Move      *On           *In05                          * Write header rcd
      * Read all HCHKSYNIFA records and select
     C     *Loval        SetLL     SYNIFA@
     C                   Read      SYNIFA@                                95
     C     *In95         DowEQ     *Off
     C     IAOD          IfEQ      'Y'                                          * IFS owner dif
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      *In22 = *Off                                 * Don't print object
      * Handle printing of new object
     C                   If        IAOBJ <> IAOBJSV                             * New object
     C                   Eval      *In21 = *On                                  * Print target/group
     C                   Eval      *In22 = *On                                  * Print object
      * Split object into parts of 80 characters
     C                   Eval      ObjDS = IAOBJ                                * IFS object
     C                   Eval      NbrElm = %Div(%Len(IAOBJ):80)+1              * # of elements
     C                   Eval      i = 1
     C                   DoW       i <= NbrElm
     C                   Eval      IAOBJ@ = ObjPrt(i)                           * Object part
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAODH                                      * IFS owner dif hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAODD                                      * IFS owner dif dtl
     C                   Eval      *In21 = *Off                                 * Don't print tgt/gr
     C                   Eval      i = i + 1
     C                   EndDo
     C                   Eval      IAOBJSV = IAOBJ                              * Saved object
     C                   EndIf                                                  * New object
      * Write header record (overflow)?
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAODH                                      * IFS owner dif hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Eval      *In22 = *Off                                 * Don't print object
     C                   Write     @IFAODD                                      * IFS auth. dif dtl
     C                   Add       1             NBRIOD                         * # of IFS owner dif
     C                   Move      *On           DSCJPA                         * IFS auth. discr.
     C                   EndIf                                                  * IFS owner dif
     C                   Read      SYNIFA@                                95
     C                   EndDo
      * Write footer record
     C     *In05         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @IFAHDR                                      * Auth. header
     C                   Write     @IFAODH                                      * IFS owner dif hdr
     C                   Move      *Off          *In05
     C                   EndIf                                                  * Overflow
     C                   Write     @IFAODF                                      * IFS owner dif ftr
      * Print the summary also
     C                   Write     @SUMIOD                                      * IFS owner dif sum
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRRtvMT - Retrieve member type                                      *
      * ------------------------------------------------------------------- *
     C     SRRtvMT       BegSR
     C                   Select
     C     MBFTYP        WhenEQ    'P'                                          * Physical
     C     MBDTAT        AndEQ     'D'                                          * Data
     C                   MoveL     #PFDTA        MBTYPE                         * Member type
     C     MBFTYP        WhenEQ    'P'                                          * Physical
     C     MBDTAT        AndEQ     'S'                                          * Data
     C                   MoveL     #PFSRC        MBTYPE                         * Member type
     C     MBFTYP        WhenEQ    'L'                                          * Physical
     C     MBDTAT        AndEQ     'D'                                          * Data
     C                   MoveL     #LFDTA        MBTYPE                         * Member type
     C     MBFTYP        WhenEQ    'L'                                          * Physical
     C     MBDTAT        AndEQ     'S'                                          * Data
     C                   MoveL     #LFSRC        MBTYPE                         * Member type
     C                   Other
     C     MBFTYP        Cat       MBDTAT:1      MBTYPE                         * Member type
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtLib - Print Library report                                     *
      * ------------------------------------------------------------------- *
     C     SRPrtLib      BegSR
      * Open files for library checking
     C                   Open      HCHKSYNLD
     C                   Open      HCHKSYNPL
      * Print header record
     C                   Eval      PAGENBR=1                                    * Page number
     C                   Write     @LIBHDR                                      * Header
      * Prepare for printing of 1st page
     C                   Z-Add     IGNIPA        IGNIH1                         * Ignore interval
     C                   Eval      GRPNH1 = ICGRPA                              * iCluster group
      * Print marked string?
     C                   Eval      MRKSH1 = MRKSPA                              * Marked string
     C                   Eval      *In21 = *Off
     C                   If        GRPNH1 = #MRKSTR
     C                   Eval      *In21 = *On
     C                   EndIf
     C                   Write     @LIBH1P                                      * First Page
      * Print Library report --> Non-existing libraries in configuration
     C                   ExSR      SRPrtLNE                                     * Non-existing
      * Print Library report --> Non-configured libraries on system
     C                   ExSR      SRPrtLNR                                     * Non-configured
     C                   ENDSR

      * ------------------------------------------------------------------- *
      * SRPrtLNE - Non-existing libraries in configuration                  *
      * ------------------------------------------------------------------- *
     C     SRPrtLNE      BegSR
      * Initialisation
     C                   Z-Add     0             NBRLNE                         * # of Non-existing
     C                   Move      *On           *In01                          * Write header rcd
      * Read all HCHKSYNLD records and select
     C     *Loval        SetLL     SYNLD@
     C                   Read      SYNLD@                                 95
     C     *In95         DowEQ     *Off
     C     LDLEXS        IfEQ      #NO                                          * Non-existing
      * Write header record (overflow)?
     C     *In01         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @LIBHDR                                      * Library header
     C                   Write     @LIBLNEH                                     * Non-existing hdr
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Write     @LIBLNED                                     * Non-existing dtl
     C                   Add       1             NBRLNE                         * # of Non-existing
     C                   EndIf                                                  * Non-existing
     C                   Read      SYNLD@                                 95
     C                   EndDo
      * Write footer record
     C                   Write     @LIBLNEF                                     * Non-existing
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtLNR - Non-configured libraries created last month              *
      * ------------------------------------------------------------------- *
     C     SRPrtLNR      BegSR
      * Initialisation
     C                   Z-Add     0             NBRLNR                         * # of Non-reference
     C                   Move      *On           *In06                          * Write header rcd
      * Read all HCHKSYNLD records and select
     C     *Loval        SetLL     SYNLD@
     C                   Read      SYNLD@                                 95
     C     *In95         DowEQ     *Off
     C     LDLREF        IfEQ      #NO                                          * Non-referenced
     C     ODOBOW        AndNE     'DMCLUSTER'                                  * Owned by iCluster
      * Convert Source Creation date to timestamp
     C                   MoveL     #MDY          DatFmt                         * Date format
     C                   MoveL     ODCDAT        ChrDat                         * Character date
     C                   MoveL     ODCTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        ChkDTS                         * Creation DTS
      * Convert Retrieve date to timestamp
     C                   MoveL     #Jobrun       DatFmt                         * Date format
     C                   MoveL     ODDDAT        ChrDat                         * Character date
     C                   MoveL     ODDTIM        ChrTim                         * Character time
     C                   ExSR      SRCvtDTS                                     * Convert
     C                   Move      CvtDTS        RtvDTS                         * Retrieve DTS
      * Calculate difference between retrieve date and creation date-time
     C     RtvDts        SubDur    ChkDts        AgeDay:*D                      * Difference days
     C     AgeDay        IfLT      0
     C                   Mult      -1            AgeDay
     C                   EndIf
     C                   If        AgeDay <= 31                                 * Younger 1 month
      * Write header record (overflow)?
     C     *In06         IfEQ      *On
     C                   Eval      PAGENBR=PAGENBR+1                            * Page number
     C                   Write     @LIBHDR                                      * Library header
     C                   Write     @LIBLNRH                                     * Non-referenced hdr
     C                   Move      *Off          *In06
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   MoveL     ChkDTS        ChrDTS                         * Character DTS
     C                   MoveL     ChrDTS        LBCDTS                         * Create DTS
     C                   Write     @LIBLNRD                                     * Non-referenced dtl
     C                   Add       1             NBRLNR                         * # of Non-reference
     C                   EndIf                                                  * Younger 1 month
     C                   EndIf                                                  * Non-referenced
     C                   Read      SYNLD@                                 95
     C                   EndDo
      * Write footer record
     C                   Write     @LIBLNRF                                     * Non-referenced
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRCvtDTS - Convert string date-time to date, time & DTS fields      *
      * ------------------------------------------------------------------- *
     C     SRCvtDTS      BegSR
     C                   Clear                   CvtDat                         * Convert date
     C                   Clear                   CvtTim                         * Convert time
     C                   Clear                   CvtDTS                         * Convert timestamp
      * Convert the date dependent on date format
     C                   Select
      * Convert dates in *JOBRUN format
     C     DatFmt        WhenEQ    #Jobrun                                      * *JOBRUN0
     C     *JOBRUN0      Test(D)                 ChrDat                 91      * Check date
     C     *In91         IfEQ      *On                                          * Erroneous date
     C                   Clear                   CvtDat                         * Convert date
     C                   Else
     C     *JOBRUN0      Move      ChrDat        CvtDat                         * Convert date
     C                   EndIf
      * Convert dates in *MDY format
     C     DatFmt        WhenEQ    #MDY                                         * *MDY0
     C     *MDY0         Test(D)                 ChrDat                 91      * Check date
     C     *In91         IfEQ      *On                                          * Erroneous date
     C                   Clear                   CvtDat                         * Convert date
     C                   Else
     C     *MDY0         Move      ChrDat        CvtDat                         * Convert date
     C                   EndIf
      * Convert dates in *YMD format
     C     DatFmt        WhenEQ    #YMD                                         * *YMD0
     C     *YMD0         Test(D)                 ChrDat                 91      * Check date
     C     *In91         IfEQ      *On                                          * Erroneous date
     C                   Clear                   CvtDat                         * Convert date
     C                   Else
     C     *YMD0         Move      ChrDat        CvtDat                         * Convert date
     C                   EndIf
     C                   EndSL
      * Convert the time
     C     *HMS0         Test(T)                 ChrTim                 91      * Check time
     C     *In91         IfEQ      *On                                          * Erroneous time
     C                   Clear                   CvtTim                         * Convert date
     C                   Else
     C     *HMS0         Move      ChrTim        CvtTim                         * Convert time
     C                   EndIf
      * Move date and time field into DTS
     C                   Move      CvtDat        CvtDTS                         * Convert DTS
     C                   Move      CvtTim        CvtDTS                         * Convert DTS
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
