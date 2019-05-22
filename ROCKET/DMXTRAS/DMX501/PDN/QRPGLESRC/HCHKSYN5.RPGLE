      * ============================================================ *
      * Object:    HCHKSYN5        *PGM RPG                          *
      *            Processes all records in the HCHKSYNOD and        *
      *            HCHKSYNMD files and flags the records that        *
      *            do not match the included objects                 *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20001011 FK  Initial delivery                                *
      * 20001205 FK  Include code for different target library       *
      * 20001217 FK  Handle blanks for compare library               *
      * 20020110 FK  Only remove excludes                            *
      * 20021122 FK  Remove excludes using algorithm instead of file *
      * 20030112 FK  Member records do not get excluded              *
      * 20031004 FK  Get specific attribute for PF/LF                *
      * 20040423 FK  Allow 300 object specifiers per group           *
      * 20050211 FK  Allow 3000 object specifiers per group          *
      *              Specific attribute through QDBRTVFD API         *
      *              Do not check members anymore in separate loop   *
      * 20050517 FK  Change of text                                  *
      * 20051230 FK  Change flag instead of removing records         *
      * 20070918 FK  Remove duplicate entries                        *
      * 20111217 FK  REMOVE HA                                       *
      * 20120322 JMW Allow 5000 object specifiers per group          *
      * 20120323 JMW Increase Library Index field size               *
      * 20120323 JMW Increase Specifier Index field size             *
      * 20120510 JMW Allow 9999 object specifiers per group          *
      * 20120510 JMW Increase Library Index field size               *
      * 20120510 JMW Increase Specifier Index field size             *
      * ============================================================ *
      * Object list
     FHLSTCFGO  IF   E           K DISK
      * Object descriptions
     FHCHKSYNOD UF   E           K DISK
      * Member descriptions
     FHCHKSYNMD UF   E           K DISK    UsrOpn
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available
     D  MSGIDAE                9     15                                         * Message ID

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D#FILE            C                   CONST('*FILE     ')

     D#INC             C                   CONST('*INC')
     D#EXC             C                   CONST('*EXC')
     D#YES             C                   CONST('*YES')
     D#ALL             C                   CONST('*ALL')
     D#NbrEnt          C                   CONST(9999)                          * # of Array entries
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D Lib             S             10    Dim(9999)                            * Libraries
     D Obj             S             10    Dim(9999)                            * Object spec
     D Gen             S              2  0 Dim(9999)                            * Generic position
     D Typ             S             10    Dim(9999)                            * Object type
     D Atr             S             10    Dim(9999)                            * Object attribute
     D Inc             S              1    Dim(9999)                            * Include?
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
     D LibSV           s             10a                                        * Saved library
     D ObjSV           s             10a                                        * Saved object
     D TypeSV          s              8a                                        * Saved type
     D FileSV          s             10a                                        * Saved file
     D MbrSV           s             10a                                        * Saved member
      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Key list limit object specifiers
     C     LimSpc        KList
     C                   KFld                    GRPNPA                         * Group name
      * Key list position to object specifier or limit by library
     C     LimLib        KList
     C                   KFld                    GRPNPA                         * Group name
     C                   KFld                    LIBWY            10            * Library
      * Key list to limit by object
     C     LimObj        KList
     C                   KFld                    GRPNPA                         * Group name
     C                   KFld                    LIBWY            10            * Library
     C                   KFld                    ODOBNM                         * Object name
     C                   KFld                    ODOBTP                         * Object type
      * Key list to limit member list by file
     C     LimFil        KList
     C                   KFld                    GRPNPA                         * Group name
     C                   KFld                    LIBWY                          * Library
     C                   KFld                    MBFILE                         * File name
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    GRPNPA           10            * Group name
     C                   Parm                    CHKMPA            4            * Check members
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Open member file if CHKMBR(*YES)
     C                   If        CHKMPA=#YES                                  * CHKMBR(*YES)
     C                   Open      HCHKSYNMD
     C                   EndIf
      * Fill the array with libraries to check
     C                   Clear                   L                 4 0          * Library index
     C     LimSpc        SetLL     LSTCFGO@
     C     LimSpc        ReadE     LSTCFGO@                               95
     C     *In95         DowEQ     *Off
     C                   Add       1             L                              * Library index
     C                   MoveL     LOLIB         Lib(L)
      * Position to next library
     C                   MoveL     LOLIB         LIBWY                          * Libary
     C     LimLib        SetGT     LSTCFGO@
     C     LimSpc        ReadE     LSTCFGO@                               95
     C                   EndDo

      * Now process all libraries in the array
     C                   Z-Add     1             L                              * Libary index
     C     L             DowLE     #NbrEnt
     C     Lib(L)        AndNE     *Blanks                                      * End
      * Put all object specifiers in the arrays
     C                   Clear                   Obj                            * Object
     C                   Clear                   Gen                            * Generic position
     C                   Clear                   Typ                            * Object type
     C                   Clear                   Atr                            * Object attribute
     C                   Clear                   Inc                            * Include?
     C                   Clear                   s                 4 0          * Specifier index
     C                   Move      *Off          ExcObj            1            * Excludes?
     C                   MoveL     Lib(L)        LIBWY                          * Library
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
     C     LOINCF        IfEQ      'N'                                          * Exclude
     C                   Move      *On           ExcObj                         * Excludes?
     C                   EndIf
     C     LimLib        ReadE     LSTCFGO@                               95
     C                   EndDo                                                  * Library obj spc
      * If there are any excludes --> Process all objects and members
     C     ExcObj        IfEQ      *On                                          * Excludes found
      * Process all objects for the library in question and flag if excluded
     C     LimLib        SetLL     SYNOD@
     C     LimLib        ReadE     SYNOD@                                 95
     C     *In95         DowEQ     *Off
      * Run subroutine to see if the object must be excluded
     C                   ExSR      SRMtcObj                                     * Match object
      * If object excluded --> Flag record (and optionally member records too)
     C     IncObjWY      IfEQ      *Off
     C                   Eval      ODINC=#EXC                                   * *EXC
     C                   Update    SYNOD@
      * If object is a *FILE --> Flag member records in HCHKSYNMD
     C     ODOBTP        IfEQ      #FILE                                        * *FILE
     C     CHKMPA        AndEQ     #YES                                         * CHKMBR(*YES)
     C                   MoveL     ODOBNM        MBFILE                         * File name
     C                   ExSR      SRFlgFil                                     * Flag file record
     C                   EndIf
      * If object not excluded --> Remove record lock
     C                   Else
     C                   Unlock    HCHKSYNOD                            99
     C                   EndIf
      * Read next object
     C     LimLib        ReadE     SYNOD@                                 95
     C                   EndDo
     C                   EndIf                                                  * Excludes found
      * Next library
     C                   Add       1             L                              * Library index
     C                   EndDo                                                  * End of libraries

      * Now, remove all duplicates from the object file
     C                   Clear                   LibSV                          * Saved library
     C                   Clear                   ObjSV                          * Saved object
     C                   Clear                   TypeSV                         * Saved type
     C     LimSpc        SetLL     SYNOD@
     C     LimSpc        ReadE     SYNOD@                                 95
     C                   DoW       not *In95
      * If same library, object and type, remove record
     C                   If        ODCMPL=LibSV and ODCMPO=ObjSV
     C                             and ODOBTP=TypeSV
     C                   Delete    SYNOD@
     C                   EndIf
     C                   Eval      LibSV=ODCMPL                                 * Saved library
     C                   Eval      ObjSV=ODCMPO                                 * Saved object
     C                   Eval      TypeSV=ODOBTP                                * Saved type
     C     LimSpc        ReadE     SYNOD@                                 95
     C                   EndDo
      * Now, remove all duplicates from the member file
     C                   If        CHKMPA=#Yes                                  * CHKMBR(*YES)
     C                   Clear                   LibSV                          * Saved library
     C                   Clear                   FileSV                         * Saved file
     C                   Clear                   MbrSV                          * Saved member
     C     LimSpc        SetLL     SYNMD@
     C     LimSpc        ReadE     SYNMD@                                 95
     C                   DoW       not *In95
      * If same library, file and member, remove record
     C                   If        MBCMPL=LibSV and MBCMPF=FileSV
     C                             and MBNAME=MbrSV
     C                   Delete    SYNMD@
     C                   EndIf
     C                   Eval      LibSV=MBCMPL                                 * Saved library
     C                   Eval      FileSV=MBFILE                                * Saved file
     C                   Eval      MbrSV=MBNAME                                 * Saved member
     C     LimSpc        ReadE     SYNMD@                                 95
     C                   EndDo
     C                   EndIf                                                  * CHKMBR(*YES)

     C                   Seton                                        LR

      * ------------------------------------------------------------------- *
      * SRMtcObj - Match object against object specifiers                   *
      * ------------------------------------------------------------------- *
     C     SRMtcObj      BegSR
      * Assume that the object was included
     C                   Move      *Off          IncObjWY          1            * Include object?
      * Now match the object against all object specifiers
     C                   Z-Add     1             s                              * Specifier index
     C     s             DowLE     #NbrEnt
     C     Obj(s)        AndNE     *Blanks                                      * End of specifiers
      * Assume that object matches the specifier
     C                   Move      *On           ObjSltWY          1            * Object selected
      * Match non-generic object name
     C     Gen(s)        IfEQ      0                                            * Not generic
     C     ODOBNM        AndNE     Obj(s)                                       * Object name
     C     Obj(s)        AndNE     #ALL                                         * *ALL
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf                                                  * Non-generic
      * Match generic object name
     C     Gen(s)        IfNE      0                                            * Generic*
     C                   If        %subst(Obj(s):1:Gen(s)-1) <>                 * Object substring
     C                                %subst(ODOBNM:1:Gen(s)-1)                   matched
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf
     C                   EndIf                                                  * Generic*
      * Match object type
     C     ODOBTP        IfNE      Typ(s)                                       * Object type
     C     Typ(s)        AndNE     #ALL                                         * *ALL
     C                   Move      *Off          ObjSltWY                       * Object selected
     C                   EndIf                                                  * Object type
      * Match object attribute
     C     ODOBAT        IfNE      Atr(s)                                       * Object attribute
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
      * SRFlgFil - Flag file member records for *EXCLUDE                    *
      * ------------------------------------------------------------------- *
     C     SRFlgFil      BegSR
      * Flag all file member records
     C     LimFil        SetLL     SYNMD@
     C     LimFil        ReadE     SYNMD@                                 96
     C     *In96         DowEQ     *Off
     C                   Eval      MBINC=#EXC                                   * *EXC
     C                   Update    SYNMD@
     C     LimFil        ReadE     SYNMD@                                 96
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
