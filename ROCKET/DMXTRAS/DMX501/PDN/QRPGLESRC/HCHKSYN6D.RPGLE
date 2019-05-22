      * ============================================================ *
      * Object:    HCHKSYN6D       *PGM RPG                          *
      *            Processes all records in the HCHKSYNID file and   *
      *            removes the IFS objects that must be excluded.    *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20020523 FK  Initial delivery                                *
      * 20021204 FK  Remove excludes using algorithm instead of file *
      * 20030117 FK  Allow more object specifiers for IFS            *
      * 20051230 FK  Change flag instead of removing records         *
      * 20080206 FK  Allow 3000 object specifiers for IFSS           *
      * 20111217 FK  REMOVE HA                                       *
      * ============================================================ *
      * IFS Object list
     FHLSTCFGI  IF   E           K DISK
      * IFS Object descriptions
     FHCHKSYNID UF   E           K DISK
      * ------------------------------------------------------------- *
      * Data structures and work fields                               *
      * ------------------------------------------------------------- *
     D ObjKey          S            500                                         * Object (key)
     D ObjNam          S           5000                                         * Object name
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#INC             C                   CONST('*INC')
     D#EXC             C                   CONST('*EXC')
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D Obj             S           5000    Dim(3000)                            * Object spec
     D Gen             S              4  0 Dim(3000)                            * Generic position
     D Inc             S              1    Dim(3000)                            * Include?
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list limit object specifiers
     C     LimSpc        KList
     C                   KFld                    GRPNPA                         * Group name
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    GRPNPA           10            * Group name
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Put all object specifiers in the arrays
     C                   Clear                   Obj                            * Object spec
     C                   Clear                   Gen                            * Generic position
     C                   Clear                   Inc                            * Include?
     C                   Clear                   s                 4 0          * Specifier index
     C                   Move      *Off          ExcObj            1            * Excludes?
     C     LimSpc        SetLL     LSTCFGI@
     C     LimSpc        ReadE     LSTCFGI@                               95
     C     *In95         DowEQ     *Off                                         * Library obj spc
      * Move selection fields to array
     C                   Add       1             s                              * Specifier index
     C                   Eval      Obj(s)=%subst(LIBASE:1:%len(LIBASE)-1) +
     C                                    LIREL
     C     '*'           Scan      Obj(s):2      Gen(s)                         * Generic position
     C                   MoveL     LIINCF        Inc(s)                         * Include?
     C     LIINCF        IfEQ      'N'                                          * Exclude
     C                   Move      *On           ExcObj                         * Excludes?
     C                   EndIf
     C     LimSpc        ReadE     LSTCFGI@                               95
     C                   EndDo                                                  * Library obj spc
      * If there are any excludes --> Process all IFS objects
     C     ExcObj        IfEQ      *On                                          * Excludes found
      * Process all IFS objects for the target/group and remove if excluded
     C     LimSpc        SetLL     SYNID@
     C     LimSpc        ReadE     SYNID@                                 95
     C     *In95         DowEQ     *Off
      * Run subroutine to see if the object must be excluded
     C                   ExSR      SRMtcObj                                     * Match object
      * If IFS object must be flagged --> Flag record
     C     IncObjWY      IfEQ      *Off
     C                   ExSR      SRDltObj                                     * Delete object rcd
     C                   EndIf
     C     LimSpc        ReadE     SYNID@                                 95
     C                   EndDo
     C                   EndIf                                                  * Excludes found

     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *

      * ------------------------------------------------------------------- *
      * SRMtcObj - Match object against object specifiers                   *
      * ------------------------------------------------------------------- *
     C     SRMtcObj      BegSR
      * Convert the object name to uppercase
     C                   Eval      ObjNam=IDOBJK
     C                   Call      'QDCXLATE'
     C                   Parm      5000          StrLenWY          5 0          * String length
     C                   Parm                    ObjNam                         * IFS object name
     C                   Parm      'QCASE256'    CvtTblWY         10            * Conversion table
      * Assume that the object was included
     C                   Move      *Off          IncObjWY          1            * Include object?
      * Now match the object against all object specifiers
     C                   Z-Add     1             s                              * Specifier index
     C                   DoW       s <= %elem(Obj)
     C                             and Obj(s) <> *Blanks                        * End of specifiers
      * Assume that object matches the specifier
     C                   Move      *On           ObjSltWY          1            * Object selected
      * Match non-generic object name
     C     Gen(s)        IfEQ      0                                            * Not generic
     C     ObjNam        AndNE     Obj(s)                                       * Object name
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf                                                  * Non-generic
      * Match generic object name
     C     Gen(s)        IfNE      0                                            * Generic*
     C                   If        %subst(Obj(s):1:Gen(s)-1) <>                 * Object substring
     C                                %subst(ObjNam:1:Gen(s)-1)                   matched
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf
     C                   EndIf                                                  * Generic*
      * If Object still selected --> Determine if exclude/include
     C     ObjSltWY      IfEQ      *On                                          * Object selected
      * Exclude or Include object
     C     Inc(s)        IfEQ      'N'                                          * *EXCLUDE
     C                   Move      *Off          IncObjWY                       * Exclude object!!
     C                   Else
     C                   Move      *On           IncObjWY                       * Include object!!
     C                   EndIf                                                  * *EXC/*INC
     C                   EndIf                                                  * Object selected
      * Process next object specifier
     C                   Add       1             s                              * Specifier index
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRDltObj - Flag IFS object record                                   *
      * ------------------------------------------------------------------- *
     C     SRDltObj      BegSR
      * Flag IFS object
     C                   Eval      IDINC=#EXC                                   * *EXC
     C                   Update    SYNID@
     C                   EndSR
