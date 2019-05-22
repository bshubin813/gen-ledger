      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    ANZJRN05        *PGM RPG                          *
      *            RCVJRNE exit program. Totalises entries per       *
      *            object in ANZJRNPF                                *
      *                                                              *
      * Synopsis:  See Command ANZJRNDLT                             *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20000101 MW  Initial delivery                                *
      * 20000215 MW  Change fixed length to 201 (HA Suite pack 9)    *
      * 20000829 MW  Change fixed length to 160 (HA Suite pack 10)   *
      * 20060126 FK  Include journal name in ANZJRNPF/ANZCMTPF       *
      *              Include object type in ANZJRNPF/ANZCMTPF        *
      *              Include user profile in ANZJRNPF                *
      *              Commitment control indicator instead of ID      *
      *              Remove ANZCMTPF updates                         *
      * 20050203 FK  Include support for IFS objects                 *
      *              Skip internal entries                           *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HACTGRP(*CALLER) BNDDIR('QC2LE')

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Journal analysis per object
     FANZJRNL1  UF A E           K DISK

      * ------------------------------------------------------------- *
      * Prototype definitions                                         *
      * ------------------------------------------------------------- *
      * MI function to create hex character dump
     D HexDump         Pr                  EXTPROC('cvthc')
     D  output                       32a                                        * Output string
     D  input                        16a                                        * Input hex value
     D  output_len                   10i 0 value                                * Output length

      * Get path from IFS object ID
     D GetPath         Pr              *   EXTPROC('Qp0lGetPathFromFileID')
     D  path                           *   Value                                * Path name
     D  pathlen                      10u 0 Value                                * Path name length
     D  objID                        16a                                        * Hex object ID

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *

      * Journal name (passed through LDA)
     D LDA            UDS                  Dtaara(*LDA)
     D  pJrnNme                1     10                                         * Journal name
     D  pJrnLib               11     20                                         * Journal library
     D  STRDTE                21     28                                         * Starting date
     D  ENDDTE                29     36                                         * Ending date

      * Journal entry (control part)
     D JrnEnt3       E DS                  ExtName(QADSPJR3)
     D  JENTYYYY              19     22                                         * Year
     D  JENTMM                24     25                                         * Month
     D  JENTDD                27     28                                         * Day
     D  JENTHH                30     31                                         * Hour
     D  JENTMI                33     34                                         * Minute
     D  JENTSS                36     37                                         * Second
     D  JENTIFS               81     96                                         * IFS Object ID

      * Time string HHMMSS
     D TmeStr          DS
     D  HH                     1      2                                         * Hour
     D  MI                     3      4                                         * Minutes
     D  SS                     5      6                                         * Seconds

      * Date string YYYYMMDD
     D DteStr          DS
     D  YYYY                   1      4                                         * Year
     D  MM                     5      6                                         * Month
     D  DD                     7      8                                         * Day

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #STMF           C                   Const('*STMF  ')
     D #DTAARA         C                   Const('*DTAARA')
     D #DTAQ           C                   Const('*DTAQ  ')
     D #FILE           C                   Const('*FILE  ')
     D #START          C                   CONST('*START')
     D #END            C                   CONST('*END')
     D #FID            C                   CONST('*FID')

      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D IFSPath         s           5001a                                        * Path name

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key for ANZJRNL1
     C     ChnANZ        KList
     C                   KFld                    FLIB                           * Object library
     C                   KFld                    FNAM                           * Object name
     C                   KFld                    MBRN                           * File member
     C                   KFld                    IFSID                          * IFS Object ID
     C                   KFld                    OTYP                           * Object type
     C                   KFld                    DTE                            * Date YYYYMMDD
     C                   KFld                    HOURX                          * Hour
     C                   KFld                    USRPRF                         * User profile
     C                   KFld                    JOBNM                          * Job name
     C                   KFld                    PGMN                           * Program name
     C                   KFld                    JCOD                           * Journal code
     C                   KFld                    JTYP                           * Entry type

      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *Entry        PList
     C                   Parm                    JrnEntPA        256            * Journal entry
     C                   Parm                    CtlPA             1            * Control

      * Split journal entry in *TYPE3 format
     C                   MoveL     JrnEntPA      JrnEnt3
      * Only process entries which indicate an object name, skip internal entries
     C                   If        JOOBJ<>*Blanks                               * Object name
     C                             and not (JOCODE='J' and JOENTT='XP')         * Internal entry
      * Prepare ANZJRNPF record
     C                   Clear                   ANZREC
      * Convert date from *ISO to YYYYMMDD
     C                   MoveL     JENTYYYY      YYYY                           * Year
     C                   MoveL     JENTMM        MM                             * Month
     C                   MoveL     JENTDD        DD                             * Day
     C                   MoveL     JENTHH        HH                             * Hour
     C                   MoveL     JENTMI        MI                             * Minutes
     C                   MoveL     JENTSS        SS                             * Seconds
      * Only process entries between starting date and ending date
     C                   If        (STRDTE=#START or                            * *START
     C                              DteStr >= STRDTE) and                       * >= Starting date
     C                             (ENDDTE=#END or                              * *END
     C                              DteStr <= ENDDTE)                           * <= Ending date
      * Fill key fields dependent on journal code (B or other)
     C                   Select
      * Stream files
     C                   When      JOCODE='B'                                   * IFS object
      * Convert binary value to hexadecimal string
     C                   CallP     HexDump( IFSID                               * IFS Object ID
     C                                    : JENTIFS                             * Object ID Hex
     C                                    : %Size(IFSID))                       * Size
      * Get path name
     C                   If        GetPath( %Addr(IFSPath)                      * IFS path
     C                                    : %Len(IFSPath)                       * IFS path length
     C                                    : JENTIFS) <> *Null                   * Object ID Hex
     C                   Eval      IFSOBJ=%str(%addr(IFSPath))                  * IFS object path
     C                   Else
     C                   Eval      IFSOBJ=#FID                                  * Unknown object
     C                   EndIf
      * Other object types
     C                   Other
     C                   MoveL     JOLIB         FLIB                           * Object library
     C                   MoveL     JOOBJ         FNAM                           * Object name
     C                   MoveL     JOMBR         MBRN                           * Member name
     C                   EndSL
      *
     C                   MoveL     DteStr        DTE                            * Date YYYYMMDD
     C                   MoveL     JENTHH        HOURX                          * Hour
     C                   MoveL     JOUSPF        USRPRF                         * User profile
     C                   MoveL     JOJOB         JOBNM                          * Job name
     C                   MoveL     JOPGM         PGMN                           * Job name
     C                   MoveL     JOCODE        JCOD                           * Journal code
     C                   MoveL     JOENTT        JTYP                           * Entry type
     C                   MoveL     pJrnLib       JRNLIB                         * Journal library
     C                   MoveL     pJrnNme       JRNNME                         * Journal name
      * Determine object type
     C                   Select
     C                   When      JOCODE='B'                                   * Stream file
     C                   Eval      OTYP=#STMF                                   * *STMF
     C                   When      JOCODE='E'                                   * Data area
     C                   Eval      OTYP=#DTAARA                                 * *DTAARA
     C                   When      JOCODE='Q'                                   * Data queue
     C                   Eval      OTYP=#DTAQ                                   * *DTAQ
     C                   When      JOCODE='F' or                                * Member entry
     C                             JOCODE='R' or                                * Record entry
     C                             JOCODE='D'                                   * Database file entr
     C                   Eval      OTYP=#FILE                                   * *FILE
     C                   Other
     C                   Clear                   OTYP                           * Blanks
     C                   EndSL

      * Now retrieve the current record
     C     ChnAnz        Chain     ANZREC                             94
      * If record doesn't exist --> Initialise values
     C                   If        *In94                                        * Not found
     C                   Eval      TOTL=0                                       * Total # of Tx
     C                   Eval      JLEN=0                                       * Total length
     C                   Eval      STRTME=TmeStr                                * Start time
     C                   Eval      CMTCTL='N'                                   * No Commit control
     C                   EndIf                                                  * Not found
      * Now fill rest of the values
     C                   If        JOCCID<>0                                    * Commitment control
     C                   Eval      CMTCTL='Y'                                   * Commit control
     C                   EndIf                                                  * Commitment control
     C                   Eval      ENDTME=TmeStr                                * Ending time
     C                   Eval      TOTL=TOTL+1                                  * Fixed length
     C                   Eval      JLEN=JLEN+160                                * Fixed length
     C                   Eval      JLEN=JLEN+JOENTL-221                         * Variable length
      * Now write or update record
     C                   If        *In94                                        * Not found
     C                   Write     ANZREC
     C                   else
     C                   Update    ANZREC
     C                   EndIf
      *
     C                   EndIf                                                  * Date selection
     C                   EndIf                                                  * Object name
     C                   Return

      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR
