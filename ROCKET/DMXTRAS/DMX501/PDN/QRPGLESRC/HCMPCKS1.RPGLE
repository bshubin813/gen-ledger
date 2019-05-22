      * ============================================================ *
      * Object:    HCMPCKS1        *PGM RPG                          *
      *            Prints the checksum differences                   *
      *                                                              *
      * Synopsis:  See Command HCMPCKS                               *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20050504 FK  Initial delivery                                *
      * 20050509 FK  File level checksum displays *FILE              *
      * 20050727 FK  IFS file support                                *
      * 20060425 FK  Different target library                        *
      * 20110926 FK  Spooled file attributes must be *MISMATCH       *
      *              if differences found                            *
      * ============================================================ *
     HDatFmt(*YMD)
      * Input file 1
     FHRTVCKS   IF   E           K DISK
      * Input file 2
     FHRTVCKST  IF   E           K DISK    Rename(RTVCKS@:RTVCKST@)
      * Output printer file for report
     FHCMPCKS1P O    E             PRINTER OflInd(*In01)
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Yes            c                   Const('*YES')
     D #No             c                   Const('*NO ')
     D #Ntv            c                   Const('*NTV')
     D #IFS            c                   Const('*IFS')
     D #All            C                   CONST('*ALL')
     D #Match          C                   CONST('Matched')
     D #MisMatch       C                   CONST('MISMATCH ')
     D #NotFound       C                   CONST('NOT FOUND')
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
     D ChrDTS          S             26                                         * Character DTS
     D StrPos          S              5  0                                      * Starting position
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list to match record from HRTVCKS(T)
     C     ChnCKS        KList
     C                   KFld                    CKLIB                          * Library
     C                   KFld                    CKFILE                         * File
     C                   KFld                    CKMBR                          * Member
     C                   KFld                    CKPTHKEY                       * Path key
     C                   KFld                    CKCKSTYP                       * Checksum type
     C                   KFld                    CKBLKNUM                       * Block number
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *Entry        PList
     C                   Parm                    pOutF01L         10            * Outfile 1 lib
     C                   Parm                    pOutF01          10            * Outfile 1
     C                   Parm                    pOutF02L         10            * Outfile 2 lib
     C                   Parm                    pOutF02          10            * Outfile 2
     C                   Parm                    pRecords         10            * Records to print
     C                   Parm                    pDiffFound        4            * Differences found
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise return variables
     C                   Eval      pDiffFound=#No
      * Print checksum report
     C                   ExSR      SRPrtCks                                     * Checksum
      * End program
     C                   SetOn                                        LR

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtCks - Print Checksum report                                    *
      * ------------------------------------------------------------------- *
     C     SRPrtCks      BegSR
      * Print header record
     C                   Write     @CKSHDR                                      * Header
      * Get system name for both input files
     C     *Loval        SetLL     RTVCKS@
     C                   Read      RTVCKS@                                95
     C                   Eval      OUTFSYS01 = CKSYSNAM                         * System 1
     C     *Loval        SetLL     RTVCKST@
     C                   Read      RTVCKST@                               95
     C                   Eval      OUTFSYS02 = CKSYSNAM                         * System 2
     C                   Eval      OUTF01H1 = %TrimR(pOutF01L) + '/' + pOUTF01  * Output file 1
     C                   Eval      OUTF02H1 = %TrimR(pOutF02L) + '/' + pOUTF02  * Output file 2
     C                   Write     @CKSH1P                                      * First Page
      * Print checksum details for native objects
     C                   ExSR      SRPrtNtv                                     * Print native
      * Print checksum details for IFS objects
     C                   ExSR      SRPrtIFS                                     * Print IFS
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtNtv - Print checksum for native objects                        *
      * ------------------------------------------------------------------- *
     C     SRPrtNtv      BegSR
      * Initialisation
     C                   Z-Add     0             NBRNTV                         * # native discrep.
     C                   Move      *On           *In01                          * Write header rcd
      * Read all HRTVCKS records and select
     C     *Loval        SetLL     RTVCKS@
     C                   Read      RTVCKS@                                95
     C     *In95         DowEQ     *Off
     C                   If        CKFSYS = #Ntv                                * *NTV object
      * Show block number or *FILE
     C                   If        CKBLKNUM = 0
     C                   Eval      *In21 = *On                                  * Show *FILE
     C                   Else
     C                   Eval      *In21 = *Off                                 * Show block number
     C                   EndIf
      * Fill system fields in header record
     C                   Eval      STRSYS01 = OUTFSYS01                         * Starting rcd sys
     C                   Eval      ENDSYS01 = OUTFSYS01                         * Ending record sys
     C                   Eval      CKSSYS01 = OUTFSYS01                         * Checksum sys
     C                   Eval      DTSSYS01 = OUTFSYS01                         * DTS sys
     C                   Eval      RLNSYS01 = OUTFSYS01                         * Record length sys
      * Fill compare fields in detail record
     C                   Eval      RCDSTR01 = CKRCDSTR                          * Starting record
     C                   Eval      RCDEND01 = CKRCDEND                          * Ending record
     C                   Eval      CHKSUM01 = CKCHKSUM                          * Checksum
     C                   MoveL     CKDTS         ChrDTS                         * Character DTS
     C                   Eval      DTS01 = %Subst(ChrDTS:1:19)                  * Character DTS
     C                   Eval      RCDLEN01 = CKRCDLEN                          * Record length
      * Now retrieve outfile 2 record
     C     ChnCKS        Chain     RTVCKST@                           94
     C                   If        not *In94                                    * Existing
      * Fill system fields in header record
     C                   Eval      STRSYS02 = OUTFSYS02                         * Starting rcd sys
     C                   Eval      ENDSYS02 = OUTFSYS02                         * Ending record sys
     C                   Eval      CKSSYS02 = OUTFSYS02                         * Checksum sys
     C                   Eval      DTSSYS02 = OUTFSYS02                         * DTS sys
     C                   Eval      RLNSYS02 = OUTFSYS02                         * Record length sys
      * Fill compare fields in detail record
     C                   Eval      *In22=*Off                                   * Don't print tgtlib
     C                   If        CKTGTLIB<>CKLIB                              * Different target l
     C                   Eval      *In22=*On                                    * Print target lib
     C                   Eval      FILE02 = CKFILE                              * File name
     C                   Eval      MBR02 = CKMBR                                * File name
     C                   EndIf                                                  * Different target l
     C                   Eval      RCDSTR02 = CKRCDSTR                          * Starting record
     C                   Eval      RCDEND02 = CKRCDEND                          * Ending record
     C                   Eval      CHKSUM02 = CKCHKSUM                          * Checksum
     C                   MoveL     CKDTS         ChrDTS                         * Character DTS
     C                   Eval      DTS02 = %Subst(ChrDTS:1:19)                  * Character DTS
     C                   Eval      RCDLEN02 = CKRCDLEN                          * Record length
      * If checksum doesn't match --> NOT MATCHING
     C                   If        CHKSUM01 <> CHKSUM02                         * Checksum not match
     C                   Eval      MATCH = #MisMatch
     C                   Eval      pDiffFound=#Yes
     C                   Eval      NBRNTV = NBRNTV + 1                          * # of native discr.
     C                   Else                                                   * Checksum matches
     C                   Eval      MATCH = #Match
     C                   EndIf
     C                   Else                                                   * Non-existing
     C                   Eval      RCDSTR02 = 0                                 * Starting record
     C                   Eval      RCDEND02 = 0                                 * Ending record
     C                   Eval      CHKSUM02 = *Blanks                           * Checksum
     C                   Eval      DTS02 = *Blanks                              * Character DTS
     C                   Eval      RCDLEN02 = 0                                 * Record length
     C                   Eval      MATCH = #NotFound
     C                   Eval      NBRNTV = NBRNTV + 1                          * # of native discr.
     C                   EndIf                                                  Exists?
      * Print detail record?
     C                   If        MATCH <> #Match                              * Mismatch
     C                             or pRecords = #All                           * Print all
      * Write header record (overflow)?
     C     *In01         IfEQ      *On
     C                   Write     @CKSHDR                                      * Report header
     C                   Write     @CKSNTVH                                     * Native header
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Write     @CKSNTVD                                     * Checksum discr.
     C                   EndIf                                                  * Print?
     C                   EndIf                                                  * *NTV object
      * Read next record in primary file
     C                   Read      RTVCKS@                                95
     C                   EndDo
      * Write footer record
     C                   Write     @CKSNTVF                                     * Checksum footer
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrtIFS - Print checksum for IFS objects                           *
      * ------------------------------------------------------------------- *
     C     SRPrtIFS      BegSR
      * Initialisation
     C                   Z-Add     0             NBRIFS                         * # IFS discrep.
     C                   Move      *On           *In01                          * Write header rcd
      * Read all HRTVCKS records and select
     C     *Loval        SetLL     RTVCKS@
     C                   Read      RTVCKS@                                95
     C     *In95         DowEQ     *Off
     C                   If        CKFSYS = #IFS                                * *IFS object
      * Show block number or *FILE
     C                   If        CKBLKNUM = 0
     C                   Eval      *In21 = *On                                  * Show *FILE
     C                   Else
     C                   Eval      *In21 = *Off                                 * Show block number
     C                   EndIf
      * Fill system fields in header record
     C                   Eval      STRSYS01 = OUTFSYS01                         * Starting rcd sys
     C                   Eval      ENDSYS01 = OUTFSYS01                         * Ending record sys
     C                   Eval      CKSSYS01 = OUTFSYS01                         * Checksum sys
     C                   Eval      DTSSYS01 = OUTFSYS01                         * DTS sys
     C                   Eval      RLNSYS01 = OUTFSYS01                         * Record length sys
      * Fill compare fields in detail record
     C                   If        %Len(CKPATH)>40                              * Length > 40
     C                   Eval      StrPos = %Len(CKPATH)-37                     * Last 37 characters
     C                   Eval      IFSFILE = '...' + %Subst(CKPATH:StrPos:37)
     C                   Else
     C                   Eval      IFSFILE = CKPATH                             * Path
     C                   EndIf
     C                   Eval      RCDSTR01 = CKRCDSTR                          * Starting record
     C                   Eval      RCDEND01 = CKRCDEND                          * Ending record
     C                   Eval      CHKSUM01 = CKCHKSUM                          * Checksum
     C                   MoveL     CKDTS         ChrDTS                         * Character DTS
     C                   Eval      DTS01 = %Subst(ChrDTS:1:19)                  * Character DTS
     C                   Eval      RCDLEN01 = CKRCDLEN                          * Record length
      * Now retrieve outfile 2 record
     C     ChnCKS        Chain     RTVCKST@                           94
     C                   If        not *In94                                    * Existing
      * Fill system fields in header record
     C                   Eval      STRSYS02 = OUTFSYS02                         * Starting rcd sys
     C                   Eval      ENDSYS02 = OUTFSYS02                         * Ending record sys
     C                   Eval      CKSSYS02 = OUTFSYS02                         * Checksum sys
     C                   Eval      DTSSYS02 = OUTFSYS02                         * DTS sys
     C                   Eval      RLNSYS02 = OUTFSYS02                         * Record length sys
      * Fill compare fields in detail record
     C                   Eval      RCDSTR02 = CKRCDSTR                          * Starting record
     C                   Eval      RCDEND02 = CKRCDEND                          * Ending record
     C                   Eval      CHKSUM02 = CKCHKSUM                          * Checksum
     C                   MoveL     CKDTS         ChrDTS                         * Character DTS
     C                   Eval      DTS02 = %Subst(ChrDTS:1:19)                  * Character DTS
     C                   Eval      RCDLEN02 = CKRCDLEN                          * Record length
      * If checksum doesn't match --> NOT MATCHING
     C                   If        CHKSUM01 <> CHKSUM02                         * Checksum not match
     C                   Eval      MATCH = #MisMatch
     C                   Eval      pDiffFound=#Yes
     C                   Eval      NBRIFS = NBRIFS + 1                          * # of IFS discr.
     C                   Else                                                   * Checksum matches
     C                   Eval      MATCH = #Match
     C                   EndIf
     C                   Else                                                   * Non-existing
     C                   Eval      RCDSTR02 = 0                                 * Starting record
     C                   Eval      RCDEND02 = 0                                 * Ending record
     C                   Eval      CHKSUM02 = *Blanks                           * Checksum
     C                   Eval      DTS02 = *Blanks                              * Character DTS
     C                   Eval      RCDLEN02 = 0                                 * Record length
     C                   Eval      MATCH = #NotFound
     C                   Eval      NBRIFS = NBRIFS + 1                          * # of IFS discr.
     C                   EndIf                                                  Exists?
      * Print detail record?
     C                   If        MATCH <> #Match                              * Mismatch
     C                             or pRecords = #All                           * Print all
      * Write header record (overflow)?
     C     *In01         IfEQ      *On
     C                   Write     @CKSHDR                                      * Report header
     C                   Write     @CKSIFSH                                     * Native header
     C                   Move      *Off          *In01
     C                   EndIf                                                  * Overflow
      * Write detail record
     C                   Write     @CKSIFSD                                     * Checksum discr.
     C                   EndIf                                                  * Print?
     C                   EndIf                                                  * *IFS object
      * Read next record in primary file
     C                   Read      RTVCKS@                                95
     C                   EndDo
      * Write footer record
     C                   Write     @CKSIFSF                                     * Checksum footer
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
