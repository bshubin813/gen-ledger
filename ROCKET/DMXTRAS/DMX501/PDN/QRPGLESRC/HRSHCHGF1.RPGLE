      * ============================================================ *
      * Object:    HRSHCHGF1       *PGM RPG                          *
      *            Compares the member change dates of the files     *
      *            in the input files. Passes back a list of files   *
      *            that must be saved.                               *
      *                                                              *
      * Synopsis:  See Command HRSHCHGF                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20010914 FK  Initial delivery                                *
      * 20010919 FK  Allow refresh through HSUSACTF command          *
      * 20011102 FK  Maximum number of objects causes dump           *
      * ============================================================ *
      * Member descriptions (after)
     FHRSHCHGFA IF   E           K DISK
      * Member descriptions (before)
     FHRSHCHGFB IF   E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D ObjLst          S             10    DIM(3000)
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * After-image change date/time stamp
     DAFTDTS           DS
     D  MBCHGC                                                                  * Century
     D  MBCHGD                                                                  * Date
     D  MBCHGT                                                                  * Time
      * Before-image change date/time stamp
     DBFRDTS           DS
     D  BFCHGC                                                                  * Century
     D  BFCHGD                                                                  * Date
     D  BFCHGT                                                                  * Time
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#ALL             C                   CONST('*ALL')
     D#NONE            C                   CONST('*NONE')
     D#SAVF            C                   CONST('*SAVF')
     D#ACT             C                   CONST('*ACT')
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
     IHRSHBFR@
     I              MBCHGC                      BFCHGC                          * Change century
     I              MBCHGD                      BFCHGD                          * Change date
     I              MBCHGT                      BFCHGT                          * Change time
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
     C     ChkMbr        KList
     C                   KFld                    MBLIB                          * Library
     C                   KFld                    MBFILE                         * File
     C                   KFld                    MBNAME                         * Member
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    SAVLPA           10            * Save library
     C                   Parm                    RSHMPA            5            * Refresh method
     C                   Parm                    OBJLPA         3300            * Object list
     C                   Parm                    NBROPA            5 0          * Number of objects
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise
     C                   Clear                   OBJLPA                         * Object list
     C                   Z-Add     0             i                 5 0          * Array index
      * Read all records that conform to the save library specified
     C     SAVLPA        SetLL     HRSHAFT@
     C     SAVLPA        ReadE     HRSHAFT@                               95
     C     *In95         DowEQ     *Off
     C     i             AndNE     9999                                         * Maximum reached
     C     ChkMbr        Chain     HRSHBFR@                           94
     C     *In94         IfEQ      *On                                          * New member
     C     BfrDTS        OrNE      AftDTS                                       * Changed
      * Check if file already in array
     C     MBFILE        LookUp    ObjLst                                 20
     C     *In20         IfEQ      *Off                                         * Not in list
     C     i             IfLT      3000                                         * Maximum
     C                   Add       1             i                              * Index
     C                   MoveL     MBFILE        ObjLst(i)
     C                   Else
     C                   Z-Add     9999          i                              * Array index
     C                   EndIf                                                  * i < 300
     C                   EndIf                                                  * Not in list
     C                   EndIf                                                  * Changed
      * Read next record
     C     SAVLPA        ReadE     HRSHAFT@                               95
     C                   EndDo
      * Fill number of objects
     C                   Z-Add     i             NBROPA                         * Number of objects
      *
     C                   Select
      * If no objects found --> Reutrn *NONE
     C     i             WhenEQ    0                                            * Maximum
     C                   MoveL(p)  #NONE         OBJLPA                         * Object List
      * If maximum reached --> return *ALL
     C     i             WhenGT    300                                          * Maximum
     C     RSHMPA        AndEQ     #SAVF                                        * Save file
     C                   MoveL(p)  #ALL          OBJLPA                         * Object List
      * If refresh method *ACT --> refresh files through HSUSACTF
     C     RSHMPA        WhenEQ    #ACT                                         * Activate
     C     1             Do        NBROPA        i
     C                   Call      'HRSHCHGF2'
     C                   Parm                    SAVLPA                         * Object library
     C                   Parm                    ObjLst(i)                      * Object
     C                   EndDo
      * Else, build parameter
     C                   Other
      * Move first object into list
     C                   MoveL(p)  ObjLst(1)     OBJLPA                         * Object list
     C     2             Do        NBROPA        i
     C                   Cat       ObjLst(i):1   OBJLPA                         * Object list
     C                   EndDo
     C                   EndSL
      * End program
     C                   Seton                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
