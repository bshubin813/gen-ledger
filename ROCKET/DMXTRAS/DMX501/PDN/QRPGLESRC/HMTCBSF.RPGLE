      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HMTCBSF         *PGM RPG                          *
      *            Matches an object against the object specifiers   *
      *            in the HLSTCFGI file. Returns if the object is    *
      *            included or excluded according to the object      *
      *            specifiers.                                       *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20080214 FK  Initial delivery                                *
      * 20111217 FK  REMOVE HA                                       *
      * ============================================================ *
      * IFS Object list
     FHLSTCFGI  IF   E           K DISK
      * ------------------------------------------------------------- *
      * Data structures and work fields                               *
      * ------------------------------------------------------------- *
     D IFSOBJPA        S           5000    Varying                              * Object name
     D ObjKey          S            500                                         * Object (key)
     D ObjNam          S           5000                                         * Object name
     D IncObjWY        S               n                                        * Include?
     D ObjSltWY        S               n                                        * Selected?
     D TGTNSV          S             10a                                        * Saved target
     D GRPNSV          S             10a                                        * Saved group
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Yes            C                   CONST('*YES')
     D #No             C                   CONST('*NO')
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
     C                   Parm                    IFSOBJPA                       * IFS object
     C                   Parm                    INCPA             4            * Included?
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   MoveL     #NO           INCPA                          * Included?
      * Must the array with object specifiers be re-filled?
     C                   If        GRPNPA<>GRPNSV                               * Different group
     C                   ExSR      SRFilArr                                     * Fill arrays
     C                   EndIf
      * Check if IFS object matches scope
     C                   Eval      ObjNam=IFSOBJPA
     C                   ExSR      SRMtcObj                                     * Match object
      * Fill return parameter
     C     IncObjWY      IfEQ      *Off
     C                   MoveL     #NO           INCPA                          * Included?
     C                   Else
     C                   MoveL     #YES          INCPA                          * Included?
     C                   EndIf

     C                   Return

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
      * Initialise "saved" variables
     C                   Clear                   GRPNSV                         * Saved group
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRFilArr - Fill array with object specifiers                        *
      * ------------------------------------------------------------------- *
     C     SRFilArr      BegSR
      * Put all object specifiers in the arrays
     C                   Clear                   Obj                            * Object spec
     C                   Clear                   Gen                            * Generic position
     C                   Clear                   Inc                            * Include?
     C                   Clear                   s                 4 0          * Specifier index
     C     LimSpc        SetLL     LSTCFGI@
     C     LimSpc        ReadE     LSTCFGI@                               95
     C     *In95         DowEQ     *Off                                         * Library obj spc
      * Move selection fields to array
     C                   Add       1             s                              * Specifier index
     C                   Eval      Obj(s)=%subst(LIBASE:1:%len(LIBASE)-1) +
     C                                    LIREL
     C     '*'           Scan      Obj(s):2      Gen(s)                         * Generic position
     C                   MoveL     LIINCF        Inc(s)                         * Include?
     C     LimSpc        ReadE     LSTCFGI@                               95
     C                   EndDo                                                  * Library obj spc
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRMtcObj - Match object against object specifiers                   *
      * ------------------------------------------------------------------- *
     C     SRMtcObj      BegSR
      * Convert the object name to uppercase
     C                   Call      'QDCXLATE'
     C                   Parm      5000          StrLenWY          5 0          * String length
     C                   Parm                    ObjNam                         * IFS object name
     C                   Parm      'QCASE256'    CvtTblWY         10            * Conversion table
      * Assume that the object was included
     C                   Move      *Off          IncObjWY                       * Include object?
      * Now match the object against all object specifiers
     C                   Z-Add     1             s                              * Specifier index
     C                   DoW       s <= %elem(Obj)
     C                             and Obj(s) <> *Blanks                        * End of specifiers
      * Assume that object matches the specifier
     C                   Move      *On           ObjSltWY                       * Object selected
     C                   Select
      * Match non-generic object name
     C                   When      Gen(s)=0 and ObjNam<>Obj(s)                  * Not generic
     C                   Move      *Off          ObjSltWY                       * Object selected
      * Match generic object name
     C                   When      Gen(s)<>0                                    * Generic*
     C                   If        %subst(Obj(s):1:Gen(s)-1) <>                 * Object substring
     C                                %subst(ObjNam:1:Gen(s)-1)                   matched
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf
     C                   EndSL
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
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
