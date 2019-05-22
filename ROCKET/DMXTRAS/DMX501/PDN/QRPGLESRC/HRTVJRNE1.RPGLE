      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    HRTVJRNE1       *PGM RPG                          *
      *            Retrieves the journal entry according to the      *
      *            passed parameters                                 *
      *                                                              *
      * Synopsis:  See Command HRTVJRNE                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20070425 FK  Initial delivery                                *
      * ============================================================ *
      * ------------------------------------------------------------- *
      * Control specifications                                        *
      * ------------------------------------------------------------- *
     HBndDir('QC2LE')

      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * Copy in the API data structures for Journal APIs
     D/COPY QSYSINC/QRPGLESRC,QJOURNAL

      * API-Error data structure
     D APIErr          DS
     D  AEBytPvd                     10i 0 Inz(%Size(APIErr))                   * Bytes provided
     D  AEBytAvl                     10i 0                                      * Bytes available
     D  AEMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  AEMsgDta                    256a                                        * Message data
      * API-Error data structure for SndPgmMsg
     D SPAPIErr        DS
     D  SPBytPvd                     10i 0 Inz(%Size(SPAPIErr))                 * Bytes provided
     D  SPBytAvl                     10i 0                                      * Bytes available
     D  SPMsgID                       7a                                        * Message ID
     D                                1a                                        * Reserved
     D  SPMsgDta                    256a                                        * Message data

      * Journal information to retrieve
     D JIRtvInf        DS
     D  TINbrRcd               1      4B 0                                      * # of Records
     D  TIVarLen1              5      8B 0                                      * Var rcd length
     D  TIVarKey1              9     12B 0                                      * Var rcd key
     D  TIVarDtaL1            13     16B 0                                      * Var data length

      * Key information
     D KeyInfDS        DS         65535
     D  KIKey                  1      4B 0                                      * Key
     D  KIKeyOfs               5      8B 0                                      * Offset to key
     D  KIInfLen               9     12B 0                                      * Info header length
     D  KINbrEnt              13     16B 0                                      * Number of entries
     D  KIEntLen              17     20B 0                                      * Entry length

      * Journal entry receiver variable
     D JERcvVar        DS                  Align
     D  JHJrnHdr
     D   JHBytRtn                    10i 0 Overlay(JHJrnHdr:1)                  * Bytes returned
     D   JHOfsHdrJrnE                10i 0 Overlay(JhJrnHdr:*Next)              * Offset to header
     D   JHNbrEntRtv                 10i 0 Overlay(JhJrnHdr:*Next)              * Number of ent
     D   JHConInd                     1a   Overlay(JhJrnHdr:*Next)              * Contination ind
     D   JHConStrRcv                 10a   Overlay(JhJrnHdr:*Next)              * Cont. jrn rcv
     D   JHConStrLib                 10a   Overlay(JhJrnHdr:*Next)              * Cont. rcv lib
     D   JHConSeqNbr                 20s 0 Overlay(JhJrnHdr:*Next)              * Cont. seq nbr
     D                               11a   Overlay(JhJrnHdr:*Next)              * Reserved
     D  JEData                    32767a                                        * Entry data

      * Journal entry header
     D JEEntHdr        DS                  Based(pEntHdr)
     D  JEOfsNxtHdr                  10u 0                                      * Ofs to next hdr
     D  JEOfsNulValI                 10u 0                                      * Ofs to Null val
     D  JEOfsEntDta                  10u 0                                      * Ofs to entry dta
     D  JEOfsTrnId                   10u 0                                      * Ofs to tx id
     D  JEOfsLglUoW                  10u 0                                      * Ofs to Lgl UoW
     D  JEOfsRcvInf                  10u 0                                      * Ofs to Rcv info
     D  JESeqNbr                     20u 0                                      * Sequence number
     D  JETimStp                     20u 0                                      * Timestamp
     D  JETimStpC                     8a   Overlay(JETimStp)                    * Timestamp
     D  JEThrId                      20u 0                                      * Thread ID
     D  JESysSeqNbr                  20u 0                                      * System seq nbr
     D  JECntRrn                     20u 0                                      * Relative rcd nbr
     D  JECmtCclId                   20u 0                                      * Commit cycle ID
     D  JEPtrHdl                     10u 0                                      * Pointer handle
     D  JERmtPort                     5u 0                                      * Remote port
     D  JEArmNbr                      5u 0                                      * Arm number
     D  JEPgmLibAsp                   5u 0                                      * Program lib ASP #
     D  JERmtAdr                     16a                                        * Remote address
     D  JEJrnCde                      1a                                        * Journal code
     D  JEEntTyp                      2a                                        * Entry type
     D  JEJobNam                     10a                                        * Job name
     D  JEUsrNam                     10a                                        * User name
     D  JEJobNbr                      6a                                        * Job number
     D  JEPgmNam                     10a                                        * Program name
     D  JEPgmLib                     10a                                        * Program library
     D  JEPgmLibAspDv                10a                                        * Program lib ASP nm
     D  JEObject                     30a                                        * Object
     D  JEUsrPrf                     10a                                        * User profile
     D  JEJrnId                      10a                                        * Journal ID
     D  JEAdrFam                      1a                                        * Address family
     D  JESysNam                      8a                                        * System name
     D  JEIndFlg                      1a                                        * Indicator flag
     D  JEObjNamInd                   1a                                        * Object name ind
     D  JEBitFld                      1a                                        * Indicator bits
     D  JERsv                         9a                                        * Reserved

      * Journal entry receiver info
     D JERcvInf        DS                  Based(pRcvInf)
     D  JRRcvNam                     10a                                        * Receiver name
     D  JRRcvLib                     10a                                        * Receiver lib
     D  JRRcvLibAspDv                10a                                        * Receiver ASP dev
     D  JRRcvLibAspNb                 5i 0                                      * Receiver ASP #

      * Parameter data structures
     D JrnQPA          DS                                                       * Journal qualified
     D  JrnPA                        10a                                        * Journal
     D  JrnLPA                       10a                                        * Journal library

     D JrnRcvQPA       DS                                                       * Receiver qualified
     D  JrnRcvPA                     10a                                        * Receiver
     D  JrnRcvLPA                    10a                                        * Receiver library

      * Message data
     D MsgDta          DS           500

      * ------------------------------------------------------------ *
      * Variable length records for key selection                    *
      * ------------------------------------------------------------ *
      * Number of variable length records passed
     D JrnEntRtv       DS
     D  JENbrVarRcd                  10i 0                                      * Number of var rcd
      * Variable record 1 - Receiver range
     D JrnVarR01       DS
     D  JvR01RcdLen                  10i 0 Inz(%Size(JrnVarR01))
     D  JvR01Key                     10i 0 Inz(1)
     D  JvR01DtaLen                  10i 0 Inz(%Size(JvR01Dta))
     D  JvR01Dta                     40a   Inz('*CURCHAIN')
     D   JvR01StrRcv                 10a   Overlay(JvR01Dta:1)
     D   JvR01StrLib                 10a   Overlay(JvR01Dta:*Next)
     D   JvR01EndRcv                 10a   Overlay(JvR01Dta:*Next)
     D   JvR01EndLib                 10a   Overlay(JvR01Dta:*Next)
      * Variable record 2 - From Large sequence
     D JrnVarR02       DS
     D  JvR02RcdLen                  10i 0 Inz(%Size(JrnVarR02))
     D  JvR02Key                     10i 0 Inz(2)
     D  JvR02DtaLen                  10i 0 Inz(%Size(JvR02Dta))
     D  JvR02Dta                     20a
      * Variable record 3 - From Time
     D JrnVarR03       DS
     D  JvR03RcdLen                  10i 0 Inz(%Size(JrnVarR03))
     D  JvR03Key                     10i 0 Inz(3)
     D  JvR03DtaLen                  10i 0 Inz(%Size(JvR03Dta))
     D  JvR03Dta                     26a
      * Variable record 6 - Number of entries
     D JrnVarR06       DS
     D  JvR06RcdLen                  10i 0 Inz(%Size(JrnVarR06))
     D  JvR06Key                     10i 0 Inz(6)
     D  JvR06DtaLen                  10i 0 Inz(%Size(JvR06Dta))
     D  JvR06Dta                     10i 0 Inz(1)

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
      * Send Program Message
     D SndPgmMsg       Pr                  ExtPgm('QMHSNDPM')
     D  SPMsgID                       7a   Const                                * Message ID
     D  SPMsgF                       20a   Const                                * Message file
     D  SPMsgDta                    512a   Const Options(*Varsize)              * Message data
     D  SPMsgDtaLen                  10i 0 Const                                * Message data len
     D  SPMsgTyp                     10a   Const                                * Message type
     D  SPCllStkEnt                  10a   Const                                * Call stack entry
     D  SPCllStkCnt                  10i 0 Const                                * Call stack count
     D  SPMsgKey                      4a                                        * Message Key
     D  SPAPIErr                  32767a         Options(*NoPass:*VarSize )     * API Error

      * Retrieve journal information
     D RtvJrnInfo      Pr                  ExtProc(
     D                                     'QjoRetrieveJournalInformation')
     D  JIRcvVar                  65535A   Options(*VARSIZE)
     D  JIRcvLen                     10I 0 Const
     D  JIJrnQ                       20A   Const
     D  JIFmtNam                      8A   Const
     D  JIRtvInf                  32767A   Const                                * Info to retrieve
     D                                     Options(*VARSIZE)
     D  JIApiErr                           Like(APIErr)

      * Retrieve journal receiver information
     D RtvRcvInfo      Pr                  ExtProc(
     D                                     'QjoRtvJrnReceiverInformation')
     D  RIRcvVar                  65535a   Options(*VARSIZE)                    * Receiver variable
     D  RIRcvLen                     10i 0 Const                                * RcvVar length
     D  RIRcvQ                       20a   Const                                * Receiver name
     D  RIFmtNam                      8a   Const                                * Format
     D  RIApiErr                           Like(APIErr)

      * Retrieve journal entry
     D RtvJrnEntry     Pr                  ExtProc(
     D                                     'QjoRetrieveJournalEntries')
     D  JERcvVar                  65535A   Options(*VARSIZE)
     D  JERcvLen                     10I 0 Const
     D  JEJrnQ                       20A   Const
     D  JEFmtNam                      8A   Const
     D  JEVarRcd                  32767A   Const Options(*VARSIZE)              * Variable records
     D  JIApiErr                           Like(APIErr)

      * Convert date-time format
     D CvtDT           Pr                  ExtPgm('QWCCVTDT')
     D  CDInpFmt                     10a   Const                                * Input format
     D  CDInpVar                     17a   Const  Options( *VarSize )           * Input var
     D  CDOutFmt                     10a   Const                                * Output format
     D  CDOutVar                     17a          Options( *VarSize )           * Output var
     D  CDError                      10i 0 Const                                * Error code

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * Message values
     D #CPFMSGF        C                   CONST('QCPFMSG   *LIBL     ')
     D #HAUMSGF        C                   CONST('HAUMSG    *LIBL     ')
     D #STATUS         C                   CONST('*STATUS')
     D #INFO           C                   CONST('*INFO')
     D #DIAG           C                   CONST('*DIAG')
     D #ESCAPE         C                   CONST('*ESCAPE')
     D #COMP           C                   CONST('*COMP')
     D #EXT            C                   CONST('*EXT')

     D#Current         c                   Const('*CURRENT')
     D#CurChain        c                   Const('*CURCHAIN')
     D#Last            c                   Const('*LAST')

      * ------------------------------------------------------------- *
      * Work variables                                                *
      * ------------------------------------------------------------- *
     D JIRcvVar        s          65535                                         * Receiver variable
     D RIRcvVar        s          65535                                         * Receiver variable

     D VarRcd          s          32767a                                        * Var rcd selected
     D VarRcdLen       s             10i 0                                      * Var rcd length

     D JEDts           s             17a                                        * Journal entry DTS
     D JEDtsZ          s               z                                        * Journal entry DTS

     D MsgKey          s              4a                                        * Message key
     D i               s             10i 0                                      * Index
     D j               s             10i 0                                      * Index
     D x               s             10i 0                                      * Index

     D Error           s               n                                        * Error occurred

      * ------------------------------------------------------------- *
      * Record format - field renames                                 *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    JrnQPA                         * Journal
     C                   Parm                    JrnRcvQPA                      * Journal receiver
     C                   Parm                    FromEntPA        20            * From entry
     C                   Parm                    FromTimePA       26            * From time
     C                   Parm                    NbrEntPA          5 0          * # of entries
     C                   Parm                    RtnRcvPA         10            * Return receiver
     C                   Parm                    RtnRcvLPA        10            * Return rcv lib
     C                   Parm                    RtnSeqPA         20            * Return sequence
     C                   Parm                    RtnEntDTSPA      26            * Return timestamp
     C                   Parm                    RtnJrnCdePA       1            * Return journal cde
     C                   Parm                    RtnEntTypPA       2            * Return entry type
     C                   Parm                    RtnCde            7            * Return code
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialistion
     C                   Clear                   RtnCde
     C                   Eval                    Error=*Off
      * First retrieve journal information
     C                   Eval      TINbrRcd=0                                   * # of keys
      * Now call API to retrieve journal information
     C                   Reset                   APIErr                         * API Error
     C                   Eval      AEBytPvd=%size(APIErr)                       * Do not issue error
     C                   CallP     RtvJrnInfo( JIRcvVar:
     C                                        %Size(JIRcvVar):
     C                                        JrnQPA:
     C                                        'RJRN0100':
     C                                        JIRtvInf:
     C                                        APIErr)
      * If no error, keep information for retrieval of journal receiver info
     C                   If        AEBytAvl=0                                   * RtvJrnInfo ok
     C                   Eval      QJON0100 = JIRcvVar                          * RJRN0100
      * If FROMENTLRG(*LAST), determine last entry of attached journal receiver
     C                   If        FromEntPA=#Last                              * *LAST
     C                   Reset                   APIErr                         * API Error
     C                   Eval      AEBytPvd=%size(APIErr)                       * Do not issue error
     C                   CallP     RtvRcvInfo( RIRcvVar:
     C                                        %Size(RIRcvVar):
     C                                        QJOAJRN + QJOAJRLN:               * Attached receiver
     C                                        'RRCV0100':
     C                                        APIErr)
     C                   If        AEBytAvl=0                                   * RtvRcvInfo ok
     C                   Eval      QJOV0100 = RIRcvVar                          * RRCV0100
     C                   Else                                                   * RtvRcvInfo ok
     C                   Eval      Error=*On                                    * Issue error
     C                   EndIf                                                  * RtvRcvInfo ok
     C                   EndIf                                                  * *LAST
     C                   Else                                                   * RtvJrnInfo ok
     C                   Eval      Error=*On                                    * Issue error
     C                   EndIf                                                  * RtvJrnInfo ok
      * Prepare keys by which journal entries will be selected
     C                   If        not Error                                    * No error so far
      * Receiver selection (always)
     C                   Eval      JENbrVarRcd=1                                * # of variable rcd
     C                   Reset                   JrnVarR01                      * Variable len rcd
     C                   Eval      JvR01StrRcv=JrnRcvPA                         * Starting receiver
     C                   Eval      JvR01StrLib=JrnRcvLPA                        * Starting rcv lib
     C                   If        JrnRcvPA<>#Current and JrnRcvPA<>#Curchain   * Not special value
     C                   Eval      JvR01EndRcv=JrnRcvPA                         * Ending receiver
     C                   Eval      JvR01EndLib=JrnRcvLPA                        * Ending rcv lib
     C                   EndIf
     C                   Eval      VarRcd=JrnVarR01                             * Variable record
     C                   Eval      VarRcdLen=JvR01RcdLen                        * Var rcd len
      * Starting large sequence number (if not *LAST)
     C                   If        FromTimePA=*Blanks and FromEntPA<>#Last      * Str time not ent
     C                   Eval      JENbrVarRcd=JENbrVarRcd+1                    * # of variable rcd
     C                   Eval      JvR02Dta=FromEntPA                           * Starting sequence
     C                   Eval      VarRcd=%subst(VarRcd:1:VarRcdLen)+JrnVarR02  * Variable record
     C                   Eval      VarRcdLen=VarRcdLen+JvR02RcdLen              * Var rcd len
     C                   EndIf                                                  * Str time not ent
      * Starting large sequence number (if *LAST)
     C                   If        FromTimePA=*Blanks and FromEntPA=#Last       * *LAST
     C                   Eval      JENbrVarRcd=JENbrVarRcd+1                    * # of variable rcd
     C                   Eval      JvR02Dta=QJOLSNL                             * Last seq long
     C                   Eval      VarRcd=%subst(VarRcd:1:VarRcdLen)+JrnVarR02  * Variable record
     C                   Eval      VarRcdLen=VarRcdLen+JvR02RcdLen              * Var rcd len
     C                   EndIf                                                  * Str time not ent
      * Starting time
     C                   If        FromTimePA<>*Blanks                          * Str time entered
     C                   Eval      JENbrVarRcd=JENbrVarRcd+1                    * # of variable rcd
     C                   Eval      JvR03Dta=FromTimePA                          * Starting time
     C                   Eval      VarRcd=%subst(VarRcd:1:VarRcdLen)+JrnVarR03  * Variable record
     C                   Eval      VarRcdLen=VarRcdLen+JvR03RcdLen              * Var rcd len
     C                   EndIf                                                  * Str time entered
      * Number of entries (always)
     C                   Eval      JENbrVarRcd=JENbrVarRcd+1                    * # of variable rcd
     C                   Eval      JvR06Dta=NbrEntPA                            * # of entries
     C                   Eval      VarRcd=%subst(VarRcd:1:VarRcdLen)+JrnVarR06  * Variable record
     C                   Eval      VarRcdLen=VarRcdLen+JvR06RcdLen              * Var rcd len
      * Now call API to retrieve journal entry
     C                   Reset                   APIErr                         * API Error
     C                   Eval      AEBytPvd=%size(APIErr)                       * Do not issue error
     C                   CallP     RtvJrnEntry(JERcvVar:
     C                                        %Size(JERcvVar):
     C                                        JrnQPA:
     C                                        'RJNE0200':
     C                                        JrnEntRtv + VarRcd:
     C                                        APIErr)
      * If no error, return info, else return code
     C                   If        AEBytAvl=0                                   * No error
     C                   Eval      pEntHdr=%addr(JERcvVar)+JHOfsHdrJrnE
      * Return fields
     C                   Eval      pRcvInf=pEntHdr + JEOfsRcvInf
     C                   Eval      RtnRcvPA=JRRcvNam                            * Receiver
     C                   Eval      RtnRcvLPA=JRRcvLib                           * Receiver library
     C                   MoveL     JESeqNbr      RtnSeqPA                       * Return sequence
     C                   Eval      RtnJrnCdePA=JEJrnCde                         * Return journal cde
     C                   Eval      RtnEntTypPA=JEEntTyp                         * Return entry type
      * Calculate timestamp
     C                   CallP     CvtDT('*DTS':JETimStpC:'*YYMD':JEDts:0)
     C                   Eval      JEDtsZ=%timestamp(JEDts+'000':*ISO0)
     C                   MoveL     JEDtsZ        RtnEntDTSPA                    * J/E timestamp
     C                   Else
     C                   Eval      Error=*On                                    * Issue error
     C                   EndIf                                                  * No error
     C                   EndIf                                                  * No error so far
      * If error occurred somewhere, issue and return code
     C                   If        Error                                        Error occurred
      * Send message with error
     C                   Eval      RtnCde=AEMsgID                               * Message ID of err
     C                   Reset                   SPAPIErr                       * API Error
     C                   Eval      AEBytPvd=%size(SPAPIErr)                     * Do not issue error
     C                   CallP     SndPgmMsg(AEMsgID:#CPFMSGF:AEMsgDta:
     C                                     %len(AEMsgDta):#ESCAPE:'*':2:
     C                                     MsgKey:SPAPIErr)
     C                   EndIf                                                  Error occurred

     C                   Return

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
