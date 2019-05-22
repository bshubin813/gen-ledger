      * ============================================================ *
      * Object:    HMTCOBJ         *PGM RPG                          *
      *            Matches an object against the object specifiers   *
      *            in the HLSTCFGO file. Returns if the object is    *
      *            included or excluded according to the object      *
      *            specifiers.                                       *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20030114 FK  Initial delivery (copied from HCHKSYN5)         *
      * 20111217 FK  REMOVE HA                                       *
      * ============================================================ *
      * Object specifiers
     FHLSTCFGO  IF   E           K DISK
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#ALL             C                   CONST('*ALL')
     D#YES             C                   CONST('*YES')
     D#NO              C                   CONST('*NO ')
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D Lib             S             10    Dim(1000)                            * Libraries
     D Obj             S             10    Dim(1000)                            * Object spec
     D Gen             S              2  0 Dim(1000)                            * Generic position
     D Typ             S             10    Dim(1000)                            * Object type
     D Atr             S             10    Dim(1000)                            * Object attribute
     D Inc             S              1    Dim(1000)                            * Include?
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list to limit object specifiers by library
     C     LimLib        KList
     C                   KFld                    GRPNPA                         * Group name
     C                   KFld                    LIBPA                          * Library
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    GRPNPA           10            * Group name
     C                   Parm                    LIBPA            10            * Library
     C                   Parm                    OBJPA            10            * Object
     C                   Parm                    OBJTPA            8            * Object type
     C                   Parm                    OBJAPA           10            * Object attribute
     C                   Parm                    INCPA             4            * Included?
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   MoveL     #NO           INCPA                          * Included?
      * Must the array with object specifiers be re-filled?
     C     GRPNPA        IfNE      GRPNSV                                       * Saved group
     C     LIBPA         OrNE      LIBSV                                        * Saved library
     C                   ExSR      SRFilArr                                     * Fill arrays
     C                   EndIf
      * Run subroutine to see if the object must be excluded
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
     C                   Clear                   GRPNSV           10            * Saved group
     C                   Clear                   LIBSV            10            * Saved library
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRFilArr - Fill array with object specifiers                        *
      * ------------------------------------------------------------------- *
     C     SRFilArr      BegSR
      * Initialise arrays with object specifiers
     C                   Clear                   Obj                            * Object
     C                   Clear                   Gen                            * Generic position
     C                   Clear                   Typ                            * Object type
     C                   Clear                   Atr                            * Object attribute
     C                   Clear                   Inc                            * Include?
     C                   Clear                   s                 5 0          * Specifier index
     C     LimLib        SetLL     LSTCFGO@
     C     LimLib        ReadE     LSTCFGO@                               95
     C     *In95         DowEQ     *Off                                         * Library obj spc
      * Move selection fields to array
     C                   Add       1             s                              * Specifier index
     C                   MoveL     LOOBJ         Obj(s)                         * Object
     C     '*'           Scan      LOOBJ:2       Gen(s)                         * Generic position
     C                   MoveL     LOOBJT        Typ(s)                         * Object type
     C                   MoveL     LOOBJA        Atr(s)                         * Object attribute
     C                   MoveL     LOINCF        Inc(s)                         * Include?
     C     LimLib        ReadE     LSTCFGO@                               95
     C                   EndDo                                                  * Library obj spc
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRMtcObj - Match object against object specifiers                   *
      * ------------------------------------------------------------------- *
     C     SRMtcObj      BegSR
      * Assume that the object was excluded
     C                   Move      *Off          IncObjWY          1            * Include object?
      * Now match the object against all object specifiers
     C                   Z-Add     1             s                              * Specifier index
     C                   DoW       s <= %elem(Obj) and Obj(s) <> *Blanks
      * Assume that object matches the specifier
     C                   Move      *On           ObjSltWY          1            * Object selected
      * Match non-generic object name
     C     Gen(s)        IfEQ      0                                            * Not generic
     C     OBJPA         AndNE     Obj(s)                                       * Object name
     C     Obj(s)        AndNE     #ALL                                         * *ALL
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf                                                  * Non-generic
      * Match generic object name
     C     Gen(s)        IfNE      0                                            * Generic*
     C                   If        %subst(Obj(s):1:Gen(s)-1) <>                 * Object substring
     C                                %subst(OBJPA:1:Gen(s)-1)                    matched
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf
     C                   EndIf                                                  * Generic*
      * Match object type
     C     OBJTPA        IfNE      Typ(s)                                       * Object type
     C     Typ(s)        AndNE     #ALL                                         * *ALL
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf                                                  * Object type
      * Match object attribute
     C     OBJAPA        IfNE      Atr(s)                                       * Object attribute
     C     Atr(s)        AndNE     #ALL                                         * *ALL
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf                                                  * Object attribute
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
