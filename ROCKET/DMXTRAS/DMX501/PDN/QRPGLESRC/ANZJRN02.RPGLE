      *CP: DFTACTGRP(*NO) DBGVIEW(*SOURCE)
      * ============================================================ *
      * Object:    ANZJRN02        *PGM RPG                          *
      *            Lists all journal receivers for the specified     *
      *            journal and starts analysis                       *
      *                                                              *
      * Synopsis:  See Command ANZJRNDLT                             *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20060126 FK  Initial delivery                                *
      * ============================================================ *
      * Journal receivers to process
     FANZDLTPF  UF A E           K DISK
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
     D STSNBR          S              1    Dim(5) CTDATA
     D STSNAM          S              8    Dim(5) Alt(STSNBR)
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D ApiErr          DS
     D  BPVDAE                 1      4B 0                                      * Bytes provided
     D  BAVLAE                 5      8B 0                                      * Bytes available

      * Copy in the API data structures for Journal APIs
     D/COPY QSYSINC/QRPGLESRC,QJOURNAL

     D RtvJrnInfo      PR                  ExtProc(
     D                                     'QjoRetrieveJournalInformation')
     D  JIRcvVar                  65535A   Options(*VARSIZE)
     D  JIRcvLen                     10I 0 Const
     D  JIJrnQ                       20A   Const
     D  JIFmtNam                      8A   Const
     D  JIRtvInf                  32767A   Const                                * Info to retrieve
     D                                     Options(*VARSIZE)
     D  JIApiErr                           Like(APIERR)

      * Journal information to retrieve
     D RtvInf          DS
     D  TINbrRcd               1      4B 0 Inz(1)                               * # of Records
     D  TIVarLen1              5      8B 0 Inz(12)                              * Var rcd length
     D  TIVarKey1              9     12B 0 Inz(1)                               * Var rcd key
     D  TIVarDtaL1            13     16B 0 Inz(0)                               * Var data length

      * Key information
     D KeyInfDS        DS         65535
     D  KIKey                  1      4B 0                                      * Key
     D  KIKeyOfs               5      8B 0                                      * Offset to key
     D  KIInfLen               9     12B 0                                      * Info header length
     D  KINbrEnt              13     16B 0                                      * Number of entries
     D  KIEntLen              17     20B 0                                      * Entry length

      * Receiver Header information
     D RcvHdrDS        DS         65535
     D  RHNbrRcv               1      4B 0                                      * # of Receivers
     D  RHTotSiz               5      8B 0                                      * Total size rcv
     D  RHTotSizMlt            9     12B 0                                      * Total size multipl
     D  RHRsv                 13     20                                         * Reserved

      * Receiver information
     D RcvInfDS        DS           128
     D  RIRcvNam               1     10                                         * Receiver name
     D  RIRcvLib              11     20                                         * Receiver library
     D  RIRcvQ                 1     20                                         * Receiver qualifier
     D  RIRcvNbr              21     25                                         * Receiver number
     D  RIAttDte              26     38                                         * Attach Date/Time
     D  RIRcvSts              39     39                                         * Receiver status
     D  RISavDte              40     52                                         * Save Date/Time
     D  RILclSys              53     60                                         * Local system
     D  RISrcSys              61     68                                         * Source system
     D  RIRcvSiz              69     72B 0                                      * Receiver size

      * Starting journal receiver qualifier
     D StrRcvQPA       DS            20
     D  StrRcv                 1     10                                         * Receiver name
     D  StrRcvL               11     20                                         * Receiver library
      * Ending journal receiver qualifier
     D EndRcvQPA       DS            20
     D  EndRcv                 1     10                                         * Receiver name
     D  EndRcvL               11     20                                         * Receiver library

      * Work variables
     D RcvVar          S          65535                                         * Receiver variable

      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #NO             C                   CONST('*NO ')
     D #YES            C                   CONST('*YES')
     D #CURCHAIN       C                   CONST('*CURCHAIN')
     D #CURRENT        C                   CONST('*CURRENT')
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * Limit receivers by journal
     C     LimRcv        KList
     C                   KFld                    JRNNPA                         * Journal name
     C                   KFld                    JRNLPA                         * Journal library
      * Check existence of receiver record
     C     ChkRcv        KList
     C                   KFld                    JRNNPA                         * Journal name
     C                   KFld                    JRNLPA                         * Journal library
     C                   KFld                    JRNRCV                         * Receiver name
     C                   KFld                    JRNRLB                         * Receiver library
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
      * Entry parameters
     C     *Entry        PList
     C                   Parm                    JRNNPA           10            * Journal name
     C                   Parm                    JRNLPA           10            * Journal library
     C                   Parm                    DLTRPA            4            * Delete receiver?
     C                   Parm                    StrRcvQPA                      * Starting receiver
     C                   Parm                    EndRcvQPA                      * Ending receiver
     C                   Parm                    STRDPA            8            * Starting date
     C                   Parm                    ENDDPA            8            * Ending date
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Retrieve chain of receivers and write records
     C                   ExSR      SRRtvChn                                     * Retrieve chain
      * Process all non-processed receivers
     C                   ExSR      SRPrcChn                                     * Process chain
      * End program
     C                   SetOn                                        LR
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRRtvChn - Retrieve receiver chain and write                        *
      * ------------------------------------------------------------------- *
     C     SRRtvChn      BegSR
      * Call program to retrieve journal information
     C                   Clear                   ApiErr
     C                   Z-Add     8             BPVDAE                         * Bytes provided
     C                   CallP     RtvJrnInfo( RcvVar:
     C                                        %Size(RcvVar):
     C                                        JRNNPA + JRNLPA:
     C                                        'RJRN0100':
     C                                        RtvInf:
     C                                        ApiErr)
      * If no error retrieving the journal receivers --> Add records to file
     C     BAVLAE        IfEQ      0                                            * No error
     C                   Eval      QJON0100 = RcvVar                            * RJRN0100
     C                   Eval      KeyInfDS = %subst(RcvVar:QJOOKI+5)
     C                   Eval      RcvHdrDS = %subst(KeyInfDS:KIKeyOfs+1)
      * Retrieve list of receivers and write entries
     C                   Z-Add     1             i                 5 0          * Counter
     C     i             DowLE     RHNbrRcv
     C     i             AndLE     500                                          * Maximum number
     C                   Eval      RcvInfDS = %subst(RcvHdrDS:KIInfLen+
     C                             ((i-1)*KIEntLen) + 1: KIEntLen)
      * Only write entry for receiver that is not currently attached
     C                   If        RIRcvSts<>'1'                                * Attached
      * Handle journal receiver selection
     C                   If        (StrRcv=#CURCHAIN or                         * *CURCHAIN
     C                              RIRcvQ >= StrRcvQPA) and                    * Starting receiver
     C                             (EndRcv=#CURRENT or                          * *CURRENT
     C                              RIRcvQ <= EndRcvQPA)                        * Ending receiver
      * Move retrieved info to file fields
     C                   MoveL     JRNNPA        JRNNME                         * Journal name
     C                   MoveL     JRNLPA        JRNLIB                         * Journal library
     C                   MoveL     RIRcvNam      JRNRCV                         * Receiver name
     C                   MoveL     RIRcvLib      JRNRLB                         * Receiver library
      * Write the record
     C     ChkRcv        SetLL     ANZDLTR                                94
     C                   If        not *In94                                    * Not existent
     C                   MoveL     #NO           PROC                           * Processed?
     C                   Write     ANZDLTR
     C                   EndIf                                                  * Not existent
     C                   EndIf                                                  * Receiver selection
     C                   EndIf                                                  * Attached
     C                   Add       1             i                              * Counter
     C                   EndDo
     C                   EndIf                                                  * No Error
     C                   EndSR

      * ------------------------------------------------------------------- *
      * SRPrcChn - Process receiver chain                                   *
      * ------------------------------------------------------------------- *
     C     SRPrcChn      BegSR
     C     LimRcv        SetLL     ANZDLTR
     C     LimRcv        ReadE     ANZDLTR                                95
     C                   DoW       not *In95
      * If not yet processed --> Do so
     C                   If        PROC=#NO                                     * Not processed
     C                   Call      'ANZJRN03'
     C                   Parm                    JRNNME                         * Journal name
     C                   Parm                    JRNLIB                         * Journal library
     C                   Parm                    JRNRCV                         * Receiver name
     C                   Parm                    JRNRLB                         * Receiver library
      * Indicate that receiver has been processed
     C                   Eval      PROC=#YES                                    * *YES
     C                   Update    ANZDLTR
     C                   EndIf                                                  * Not processed
      * Delete receiver if requested
     C                   If        DLTRPA=#YES                                  * DLTRCV(*YES)
     C                   Call      'ANZJRN04'
     C                   Parm                    JRNRCV                         * Receiver name
     C                   Parm                    JRNRLB                         * Receiver library
     C                   EndIf                                                  * DLTRCV(*YES)
     C     LimRcv        ReadE     ANZDLTR                                95
     C                   EndDo
     C                   EndSR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
**CTDATA STSNBR
1ATTACHED
2ONLINE
3SAVED
4FREED
5PARTIAL
