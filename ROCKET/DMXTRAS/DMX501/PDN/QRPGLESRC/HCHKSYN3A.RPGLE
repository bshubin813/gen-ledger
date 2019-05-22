      *CP: DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HCHKSYN3A       *PGM RPG                          *
      *            Retrieves object authorities for all retrieved    *
      *            objects, native and IFS.                          *
      *                                                              *
      * Synopsis:  See Command HCHKSYNTGT.                           *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20050513 FK  Initial delivery                                *
      * 20050526 FK  Locked object not handled properly              *
      * 20051230 FK  Only process objects not excluded (flag)        *
      * 20060301 FK  Properly handle objects in QSYS                 *
      * 20060327 FK  Original object name                            *
      * 20070516 FK  Authority shown as *USE in some cases of USER-D *
      * ============================================================ *

      * ------------------------------------------------------------ *
      * Control keywords                                             *
      * ------------------------------------------------------------ *
     HActGrp(*Caller) DftActGrp(*No)

      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *
      * Object descriptions
     FHCHKSYNOD IF   E           K DISK
      * IFS Object descriptions
     FHCHKSYNID IF   E           K DISK    UsrOpn
      * Object authorities (native)
     FHCHKSYNOA O    E           K DISK
      * Object authorities (IFS)
     FHCHKSYNIA O    E           K DISK    UsrOpn

      * ------------------------------------------------------------- *
      * Prototype definitions                                         *
      * ------------------------------------------------------------- *
      * Prototype for QSYRTVUA (Retrieve User Authorized to an Object)
     D RtvObjAut       PR                  ExtPgm('QSYRTVUA')
     D  RARcvVar                  32767a   Options(*VarSize)                    * Receiver variable
     D  RARcvLen                     10i 0 Const                                * RcvVar length
     D  RAFdbInf                    256a   Options(*VarSize)                    * Feedback info
     D  RAFdbLen                     10i 0 Const                                * Feedback length
     D  RAFmtNam                      8a   Const                                * Format name
     D  RAPth                      5000a   Const Options(*VarSize)              * Object path
     D  RAPthLen                     10i 0 Const                                * Path length
     D  RAApiErr                           Like(ApiErr)

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *

      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D ApiErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(ApiErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data

      * QSYRTVUA Feedback information
     D RAFdbInf        DS
     D  RFBytRtn                     10i 0                                      * Bytes returned
     D  RFBytAvl                     10i 0                                      * Bytes available
     D  RFBytRtnRv                   10i 0                                      * Bytes rtn rcvvar
     D  RFBytAvlRv                   10i 0                                      * Bytes rcv rcvvar
     D  RFNbrAutUsr                  10i 0                                      * Number of users
     D  RFUsrEntLen                  10i 0                                      * Aut user ent len
     D  RFObjOwn                     10a                                        * Object owner
     D  RFObjPgp                     10a                                        * Primary group
     D  RFAutL                       10a                                        * Authorisation list
     D  RFSnsLvl                      1a                                        * Sensitivity level

      * QSYRTVUA record format RTUA0100
     D RTUA0100        DS                  Based( pAutEnt )
     D  UAUsrPrf                     10a                                        * User profile
     D  UAUsrTyp                      1a                                        * User type
     D  UADtaAut                     10a                                        * Data authority
     D  UAAutlMgt                     1a                                        * Autl management
     D  UAObjMgt                      1a                                        * Object management
     D  UAObjExs                      1a                                        * Object existence
     D  UAObjAlt                      1a                                        * Object alter
     D  UAObjRef                      1a                                        * Object reference
     D                               10a                                        * Reserved
     D  UAObjOpr                      1a                                        * Object operational
     D  UADtaRead                     1a                                        * Data read
     D  UADtaAdd                      1a                                        * Data add
     D  UADtaUpd                      1a                                        * Data update
     D  UADtaDlt                      1a                                        * Data delete
     D  UADtaExc                      1a                                        * Data execute
     D                               10a                                        * Reserved

      * Message data
     D MSGDTA          DS          1024
      * Message data for CST0004
     D  LIBMD                  1     10                                         * Library
     D  GRPNMD                11     20                                         * Group

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #Yes            C                   CONST('*YES')
     D #JrnRcv         C                   CONST('*JRNRCV')
     D #QSys           C                   CONST('QSYS')
     D #QSysLib        C                   CONST('/QSYS.LIB')
     D #PathQSys       C                   CONST('/QSYS.LIB/')
     D #PathLib        C                   CONST('.LIB')
     D #Public         C                   CONST('*PUBLIC')
     D #Locked         C                   CONST('*LOCKED')
     D #INC            C                   CONST('*INC')
     D #EXC            C                   CONST('*EXC')
      * Object authorities
     D #AutExclude     C                   CONST('*EXCLUDE')
     D #AutAll         C                   CONST('*ALL')
     D #AutUse         C                   CONST('*USE')
     D #AutChange      C                   CONST('*CHANGE')
     D #AutUsrDef      C                   CONST('USER DEF')
     D #AutAUTL        C                   CONST('*AUTL')
      * Message values
     D #QCPFMSG        C                   CONST('QCPFMSG   *LIBL     ')
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
      * Work variables
     D RARcvVar        S          32767a                                        * Receiver variable
     D RAPath          S           5000a   Varying                              * Full path
     D i               S             10i 0                                      * Index
     D CurDTS          S               z                                        * Current date-time
     D LibSV           S             10a                                        * Saved library

      * API parameter values
     D MSGDTLSM        S              9b 0                                      * Message data lengt
     D STCCTRSM        S              9b 0                                      * Stack counter

      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *

      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * QMHSNDPM - Send program message
     C     pSNDPM        PList
     C                   Parm                    MSGIDSM           7            * Message ID
     C                   Parm                    MSGFSM           20            * Message file
     C                   Parm                    MSGDTA                         * Message data
     C                   Parm                    MSGDTLSM                       * Message data lengt
     C                   Parm                    MSGTYPSM         10            * Message type
     C                   Parm                    STCENTSM         10            * Call stack entry
     C                   Parm                    STCCTRSM                       * Stack counter
     C                   Parm                    MSGKEYSM          4            * Message key
     C                   Parm                    ApiErr                         * API Error

      * Entry parameters
     C     *Entry        PList
     C                   Parm                    pChkIFS           4            * Check IFS?

      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
      * Process native objects
     C                   ExSR      SRPrcNtv                                     * Native records
      * Process IFS Objects?
     C                   If        pChkIFS = #YES                               * *YES
     C                   ExSR      SRPrcIFS                                     * IFS records
     C                   EndIf
      * End program
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrcNtv - Process all native records                               *
      * ------------------------------------------------------------------- *
     C     SRPrcNtv      BegSR
      * Read all records in HCHKSYNOD
     C     *Loval        SetLL     SYNOD@
     C                   Read      SYNOD@                                 95
     C                   DoW       not *In95
      * Only process if object included
     C                   If        ODINC<>#EXC                                  * not *EXC
      * If new library --> Indicate in job log
     C                   If        ODLBNM <> LibSV                              * Changed library
      * Send program message "Retrieving authorities for library ..."
     C                   Eval      MSGIDSM = 'CST0004'                          * Message ID
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   Eval      LIBMD = ODLBNM                               * Library name
     C                   Eval      GRPNMD = ODGRPN                              * Group
     C                   ExSR      SRSNDPM
     C                   Eval      LibSV = ODLBNM                               * Library
     C                   EndIf                                                  * Changed library
      * Compose path name for object only if not *JRNRCV
     C                   If        ODOBTP <> #JrnRcv                            * *JRNRCV object
     C                   Select
     C                   When      ODLBNM<>#QSys
     C                   Eval      RAPath=#PathQSys+%TrimR(ODLBNM)+#PathLib +   * /QSYS.LIB/..
     C                               '/' + %TrimR(ODOBNM) + '.' +
     C                               %TrimR(%Subst(ODOBTP:2))
     C                   When      ODOBNM<>#QSYS or ODOBTP<>'*LIB'              * Not library QSYS
     C                   Eval      RAPath=#PathQSys+                            * /QSYS.LIB/..
     C                               %TrimR(ODOBNM) + '.' +
     C                               %TrimR(%Subst(ODOBTP:2))
     C                   When      ODOBNM=#QSYS and ODOBTP='*LIB'               * Library QSYS
     C                   Eval      RAPath=#QSysLib                              * /QSYS.LIB
     C                   EndSL
      * Retrieve authorities
     C                   ExSR      SRRtvAut
      * Clear authority record for preparation
     C                   Clear                   SYNOA@
      * Prepare fields to write record
     C                   Eval      OAGRPN = ODGRPN                              * Group name
     C                   Eval      OACMPL = ODCMPL                              * Compare library
     C                   Eval      OACMPO = ODCMPO                              * Compare object
     C                   Eval      OALIB = ODLBNM                               * Library
     C                   Eval      OANAME = ODOBNM                              * Object
     C                   Eval      OATGTL = ODTGTL                              * Target library
     C                   Eval      OATYPE = ODOBTP                              * Object type
     C                   Eval      OARTVD = CurDTS                              * Retrieve DTS
      * Write authority record
     C                   ExSR      SRWrtAutNtv
     C                   EndIf                                                  * *JRNRCV object
     C                   EndIf                                                  * Object included
     C                   Read      SYNOD@                                 95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrcIFS - Process all IFS records                                  *
      * ------------------------------------------------------------------- *
     C     SRPrcIFS      BegSR
      * Open files
     C                   Open      HCHKSYNID
     C                   Open      HCHKSYNIA
      * Send program message "Retrieving IFS authorities ..."
     C                   Eval      MSGIDSM = 'CST0014'                          * Message ID
     C                   Eval      MSGTYPSM = #INFO                             * Message type
     C                   ExSR      SRSNDPM
      * Read all records in HCHKSYNID
     C     *Loval        SetLL     SYNID@
     C                   Read      SYNID@                                 95
     C                   DoW       not *In95
      * Only process if object included
     C                   If        IDINC<>#EXC                                  * not *EXC
      * Compose path name
     C                   Eval      RAPath=IDOBJ                                 * IFS path
      * Retrieve authorities
     C                   ExSR      SRRtvAut
      * Clear authority record for preparation
     C                   Clear                   SYNIA@
      * Prepare fields to write record
     C                   Eval      IAGRPN = IDGRPN                              * Group name
     C                   Eval      IATYPE = IDTYPE                              * Object type
     C                   Eval      IAOBJK = IDOBJK                              * Object key
     C                   Eval      IAOBJ = IDOBJ                                * Object
     C                   Eval      IARTVD = CurDTS                              * Retrieve DTS
      * Process outcome of API call
     C                   Select
      * If authorities retrieved successfully, fill fields and write authority record
     C                   When      AEBytAvl = 0                                 * No error
     C                   Eval      i = 1
     C                   Eval      pAutEnt=%Addr(RARcvVar)                      * Basing pointer
     C                   DoW       i <= RFNbrAutUsr                             * # of auth.
      * Convert API values to IFS authorities
     C                   ExSR      SRCvtAutIFS                                  * Convert IFS aut
     C                   Write     SYNIA@                                       * Authority record
      * Process next authority entry
     C                   Eval      i = i + 1
     C                   Eval      pAutEnt=pAutEnt + RFUsrEntLen                * Basing pointer
     C                   EndDo
      * Process locked object
     C                   When      AEMsgID <> *Blanks                           * Object locked
     C                   Eval      IAUSR = #Public                              * *PUBLIC
     C                   Eval      IADTAA = #Locked                             * *LOCKED
     C                   Write     SYNIA@                                       * Authority record
     C                   EndSL
     C                   EndIf                                                  * Object included
     C                   Read      SYNID@                                 95
     C                   EndDo
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRRtvAut - Retrieve authorities for object                          *
      * ------------------------------------------------------------------- *
     C     SRRtvAut      BegSR
      * Retrieve current date-time
     C                   Time                    CurDTS                         * Current date-time
      * Call program to retrieve journal information
     C                   Clear                   ApiErr
     C                   Eval      AEBytPvd = %Len(ApiErr)
     C                   CallP     RtvObjAut( RARcvVar
     C                                      : %Size(RARcvVar)
     C                                      : RAFdbInf
     C                                      : %Size(RAFdbInf)
     C                                      : 'RTUA0100'
     C                                      : RAPath
     C                                      : %Len(RAPath)
     C                                      : ApiErr)
     C                   If        AEMsgID <> *Blanks
     C                   Clear                   RAFdbInf                       * Clear feedback
     C                   Clear                   RARcvVar                       * Clear receiver var
     C                   EndIf
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRWrtAutNtv - Write native authority record                         *
      * ------------------------------------------------------------------- *
     C     SRWrtAutNtv   BegSR
      * Process outcome of API call
     C                   Select
      * If authorities retrieved successfully, fill fields and write authority record
     C                   When      AEBytAvl = 0                                 * No error
     C                   Eval      i = 1
     C                   Eval      pAutEnt=%Addr(RARcvVar)                      * Basing pointer
     C                   DoW       i <= RFNbrAutUsr                             * # of auth.
      * Convert API values to native authorities
     C                   ExSR      SRCvtAutNtv                                  * Convert native aut
     C                   Write     SYNOA@                                       * Authority record
      * Process next authority entry
     C                   Eval      i = i + 1
     C                   Eval      pAutEnt=pAutEnt + RFUsrEntLen                * Basing pointer
     C                   EndDo
      * Process locked object
     C                   When      AEMsgID <> *Blanks                           * Object locked
     C                   Eval      OAUSR = #Public                              * *PUBLIC
     C                   Eval      OAOBJA = #Locked                             * *LOCKED
     C                   Write     SYNOA@                                       * Authority record
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRCvtAutNtv - Convert native authorities                            *
      * ------------------------------------------------------------------- *
     C     SRCvtAutNtv   BegSR
      * Convert high level values
     C                   Eval      OAANAM = RFAutL                              * Authorisation list
     C                   Eval      OAOWN =  RFObjOwn                            * Object owner
      * Fill detail values per user
     C                   Eval      OAUSR = UAUsrPrf                             * User profile
     C                   Eval      OAOPR = ' '
     C                   If        UAObjOpr='1'                                 * Object operational
     C                   Eval      OAOPR = 'X'
     C                   EndIf                                                  * Object operational
     C                   Eval      OAOMGT = ' '
     C                   If        UAObjMgt='1'                                 * Object management
     C                   Eval      OAOMGT = 'X'
     C                   EndIf                                                  * Object operational
     C                   Eval      OAEXS = ' '
     C                   If        UAObjExs='1'                                 * Object existence
     C                   Eval      OAEXS = 'X'
     C                   EndIf                                                  * Object existence
     C                   Eval      OAALT = ' '
     C                   If        UAObjAlt='1'                                 * Object alter
     C                   Eval      OAALT = 'X'
     C                   EndIf                                                  * Object alter
     C                   Eval      OAAMGT = ' '
     C                   If        UAAutlMgt='1'                                * AUTL management
     C                   Eval      OAAMGT = 'X'
     C                   EndIf                                                  * AUTL management
     C                   Eval      OAREF = ' '
     C                   If        UAObjRef='1'                                 * Object reference
     C                   Eval      OAREF = 'X'
     C                   EndIf                                                  * Object reference
     C                   Eval      OAREAD = ' '
     C                   If        UADtaRead='1'                                * Data read
     C                   Eval      OAREAD = 'X'
     C                   EndIf                                                  * Data read
     C                   Eval      OAADD = ' '
     C                   If        UADtaAdd='1'                                 * Data add
     C                   Eval      OAADD = 'X'
     C                   EndIf                                                  * Data add
     C                   Eval      OAUPD = ' '
     C                   If        UADtaUpd='1'                                 * Data update
     C                   Eval      OAUPD = 'X'
     C                   EndIf                                                  * Data update
     C                   Eval      OADLT = ' '
     C                   If        UADtaDlt='1'                                 * Data delete
     C                   Eval      OADLT = 'X'
     C                   EndIf                                                  * Data delete
     C                   Eval      OAEXEC = ' '
     C                   If        UADtaExc='1'                                 * Data execute
     C                   Eval      OAEXEC = 'X'
     C                   EndIf                                                  * Data execute
      * Now determine value of Object Authority
     C                   Select
     C                   When      UADtaAut = #AutAUTL                          * *AUTL
     C                   Eval      OAOBJA = #AutAUTL                            * *AUTL
     C                   When      UAObjOpr='1' and UAObjMgt='1' and            * *ALL authority
     C                             UAObjExs='1' and UAObjAlt='1' and
     C                             UAObjRef='1' and
     C                             UADtaRead='1' and UADtaAdd='1' and
     C                             UADtaUpd='1' and UADtaDlt='1' and
     C                             UADtaExc='1'
     C                   Eval      OAOBJA = #AutAll                             * *ALL
     C                   When      UAObjOpr='1' and                             * *CHANGE authority
     C                             UADtaRead='1' and UADtaAdd='1' and
     C                             UADtaUpd='1' and UADtaDlt='1' and
     C                             UADtaExc='1'
     C                   Eval      OAOBJA = #AutChange                          * *CHANGE
     C                   When      UAObjOpr='1' and UAObjMgt='0' and            * *USE authority
     C                             UAObjExs='0' or UAObjAlt='0' and
     C                             UAObjRef='0' and
     C                             UADtaRead='1' and UADtaAdd='0' and
     C                             UADtaUpd='0' and UADtaDlt='0' and
     C                             UADtaExc='1'
     C                   Eval      OAOBJA = #AutUse                             * *USE
     C                   When      not(UAObjOpr='1' or UAObjMgt='1' or          * *EXCLUDE authority
     C                             UAObjExs='1' or UAObjAlt='1' or
     C                             UAObjRef='1' or
     C                             UADtaRead='1' or UADtaAdd='1' or
     C                             UADtaUpd='1' or UADtaDlt='1' or
     C                             UADtaExc='1')
     C                   Eval      OAOBJA = #AutExclude                         * *EXCLUDE
     C                   Other
     C                   Eval      OAOBJA = #AutUsrDef                          * USER DEF
     C                   EndSL
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRCvtAutIFS - Convert IFS authorities                               *
      * ------------------------------------------------------------------- *
     C     SRCvtAutIFS   BegSR
      * Convert high level values
     C                   Eval      IAANAM = RFAutL                              * Authorisation list
     C                   Eval      IAOWN =  RFObjOwn                            * Object owner
      * Fill detail values per user
     C                   Eval      IAUSR = UAUsrPrf                             * User profile
     C                   Eval      IADTAA = UADtaAut                            * Data authority
     C                   Eval      IAOPR = ' '
     C                   If        UAObjOpr='1'                                 * Object operational
     C                   Eval      IAOPR = 'X'
     C                   EndIf                                                  * Object operational
     C                   Eval      IAOMGT = ' '
     C                   If        UAObjMgt='1'                                 * Object management
     C                   Eval      IAOMGT = 'X'
     C                   EndIf                                                  * Object management
     C                   Eval      IAEXS = ' '
     C                   If        UAObjExs='1'                                 * Object existence
     C                   Eval      IAEXS = 'X'
     C                   EndIf                                                  * Object existence
     C                   Eval      IAALT = ' '
     C                   If        UAObjAlt='1'                                 * Object alter
     C                   Eval      IAALT = 'X'
     C                   EndIf                                                  * Object alter
     C                   Eval      IAAMGT = ' '
     C                   If        UAAutlMgt='1'                                * AUTL management
     C                   Eval      IAAMGT = 'X'
     C                   EndIf                                                  * AUTL management
     C                   Eval      IAREF = ' '
     C                   If        UAObjRef='1'                                 * Object reference
     C                   Eval      IAREF = 'X'
     C                   EndIf                                                  * Object reference
     C                   Eval      IAREAD = ' '
     C                   If        UADtaRead='1'                                * Data read
     C                   Eval      IAREAD = 'X'
     C                   EndIf                                                  * Data read
     C                   Eval      IAADD = ' '
     C                   If        UADtaAdd='1'                                 * Data add
     C                   Eval      IAADD = 'X'
     C                   EndIf                                                  * Data add
     C                   Eval      IAUPD = ' '
     C                   If        UADtaUpd='1'                                 * Data update
     C                   Eval      IAUPD = 'X'
     C                   EndIf                                                  * Data update
     C                   Eval      IADLT = ' '
     C                   If        UADtaDlt='1'                                 * Data delete
     C                   Eval      IADLT = 'X'
     C                   EndIf                                                  * Data delete
     C                   Eval      IAEXEC = ' '
     C                   If        UADtaExc='1'                                 * Data execute
     C                   Eval      IAEXEC = 'X'
     C                   EndIf                                                  * Data execute
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRSNDPM - Send program message                                      *
      * ------------------------------------------------------------------- *
     C     SRSNDPM       BegSR
      * Determine message file value for QMHSNDPM API
     C     MSGFSM        IfEQ      *BLANKS
     C                   MoveL     #HAUMSGF      MSGFSM                         * Default msgf
     C                   EndIf
      * Set default message type
     C     MSGTYPSM      IfEQ      *BLANKS                                      * Message type
     C                   MoveL     #DIAG         MSGTYPSM                       * Message type
     C                   EndIf
      * Determine stack entry/counter value, based on message type
     C                   Select
     C     STCENTSM      WhenNE    *BLANKS                                      * Stack entry
     C     MSGTYPSM      WhenEQ    #STATUS                                      * Status message
     C                   MoveL(P)  #EXT          STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C     MSGTYPSM      WhenEQ    #INFO                                        * Status message
     C                   MoveL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   Other
     C                   MoveL(P)  '*'           STCENTSM                       * Stack entry
     C                   Z-Add     1             STCCTRSM                       * Stack counter
     C                   EndSL
      * Send program message
     C                   Z-Add     15            AEBytPvd                       * Bytes provide
     C                   Z-Add     1024          MSGDTLSM                       * Message data lengt
     C                   Call      'QMHSNDPM'    pSNDPM                         * Send program msg
      * Reset values for next message send
     C                   MoveL     *BLANKS       MSGFSM                         * Message file
     C                   MoveL     *BLANKS       MSGTYPSM                       * Message type
     C                   MoveL     *BLANKS       STCENTSM                       * Stack entry
     C                   Z-Add     0             STCCTRSM                       * Stack counter
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
