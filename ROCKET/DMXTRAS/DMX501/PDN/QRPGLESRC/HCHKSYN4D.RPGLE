      * ============================================================ *
      * Object:    HCHKSYN4D       *PGM                              *
      *            Gets directory entry description and SMTP address *
      *            for specified user profile.                       *
      *                                                              *
      * Synopsis:  N/A.                                              *
      *                                                              *
      * Creation:  CRTBNDRPG                                         *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20070919 FK  Initial delivery (copied from HMONHAL1B)        *
      * ============================================================ *
      **-- Header specifications:  --------------------------------------**
     H Option(*SrcStmt) DftActGrp(*No) ActGrp(*Caller)
      * ------------------------------------------------------------ *
      * Files                                                        *
      * ------------------------------------------------------------ *

      * ------------------------------------------------------------ *
      * Data structures                                              *
      * ------------------------------------------------------------ *
      * Program status data structure
     D PgmSts         SDs
     D  PsJobUsr                     10a   Overlay( PgmSts: 254 )
     D  PsCurUsr                     10a   Overlay( PgmSts: 358 )

      * API Error data structure
     D ApiError        Ds
     D  AeBytPrv                     10i 0 Inz( %Size( ApiError ))
     D  AeBytAvl                     10i 0 Inz
     D  AeMsgId                       7a
     D                                1a
     D  AeMsgDta                    128a

      *
      * Parameters for QOKSCHD API
      *
      * Request variable SREQ0100
     D Sreq0100        Ds
     D  SrCcsId                      10i 0 Inz( 0 )
     D  SrChrSet                     10i 0 Inz
     D  SrCodPag                     10i 0 Inz
     D  SrWldCrd                      4a   Inz
     D  SrCvtRcv                      1a   Inz( '0' )
     D  SrSchDta                      1a   Inz( '0' )
     D  SrRunVfy                      1a   Inz( '1' )
     D  SrConHdl                      1a   Inz( '0' )
     D  SrRscHdl                     16a   Inz
     D  SrSrqFmt                      8a   Inz( 'SREQ0101' )
     D  SrSrqOfs                     10i 0 Inz( 110 )
     D  SrSrqNbrElm                  10i 0 Inz
     D  SrRtnFmt                      8a   Inz( 'SREQ0103' )
     D  SrRtnOfs                     10i 0 Inz( 100 )
     D  SrRtnNbrElm                  10i 0 Inz( 1 )
     D  SrRcvFmt                      8a   Inz( 'SRCV0101' )
     D  SrRcvNbrElm                  10i 0 Inz( 1 )
     D  SrUsrFmt                      8a   Inz( 'SRCV0111' )
     D  SrOrdFmt                      8a   Inz
     D  SrOrdRtnOpt                   1a   Inz( '0' )
     D                                3a
     D  Sr0103                             Like( Sreq0103 )
     D  Sr0101                             Like( Sreq0101 )

      * Request variable SREQ0101
     D Sreq0101        Ds                  Inz
     D  S1Entry                            Dim( 2 )
     D  S1EntLen                     10i 0 Inz( %Size( S1Entry ))
     D                                     Overlay( S1Entry: 1 )
     D  S1CmpVal                      1a   Inz( '1' )
     D                                     Overlay( S1Entry: *Next )
     D  S1FldNam                     10a   Overlay( S1Entry: *Next )
     D  S1PrdId                       7a   Inz( '*IBM' )
     D                                     Overlay( S1Entry: *Next )
     D  S1DtaCas                      1a   Overlay( S1Entry: *Next )
     D                                1a   Overlay( S1Entry: *Next )
     D  S1ValLen                     10i 0 Inz( %Size( S1ValMtc ))
     D                                     Overlay( S1Entry: *Next )
     D  S1ValMtc                     10a   Overlay( S1Entry: *Next )

      * Request variable SREQ0103 for SMTP information
     D Sreq0103        Ds
     D  S3SpcRtn                     10a   Inz( '*SMTP' )

      * Request variable SREQ0103 for SYSDIR information
     D Sreq0103DIR     Ds
     D  S3SpcRtnDir                  10a   Inz( '*SYSDIR' )

      * Receive variable SRCV0100
     D Srcv0100        Ds         32767
     D  R00BytRtn                    10i 0
     D  R00OrdFldOfs                 10i 0
     D  R00UsrEntOfs                 10i 0
     D  R00DirEntNbr                 10i 0
     D  R00ConHdl                     1a
     D  R00RscHdl                    16a
     D  R00UsrMtcAry                       Like( Srcv0101 )

      * Receive variable SRCV0101
     D Srcv0101        Ds                  Based( pSrcv0101 )
     D  R01UsrDtaLen                 10i 0
     D  R01RtnNbrFld                 10i 0

      * Receive variable SRCV0111
     D Srcv0111        Ds                  Based( pSrcv0111 )
     D  R11FldNam                    10a
     D  R11PrdId                      7a
     D                                3a
     D  R11CcsId                     10i 0
     D  R11CodPag                    10i 0
     D  R11RtnFldLen                 10i 0

     D Srcv0111v       Ds                  Based( pSrcv0111v )
     D  R11RtnFld                   256a

      * ------------------------------------------------------------ *
      * Local variables and constants                                *
      * ------------------------------------------------------------ *
     D SmtpDmn         s            256a   Varying
     D SmtpUsrId       s             64a   Varying
     D UserDesc        s             50a   Varying
      **
     D At              c                   '@'

      * ------------------------------------------------------------ *
      * Prototype definitions                                        *
      * ------------------------------------------------------------ *
     D SchDir          Pr                  Extpgm( 'QOKSCHD' )
     D  SdRcvVar                                 Like( Srcv0100)
     D  SdRcvVarLen                  10i 0 Const
     D  SdFmtNam                      8a   Const
     D  SdFunction                   10a   Const
     D  SdKeepTmpRsc                  1a   Const
     D  SdRqsVar                           Const Like( Sreq0100 )
     D  SdRqsVarLen                  10i 0 Const
     D  SdRqsFmtNam                   8a   Const
     D  SdError                       8a

      * ------------------------------------------------------------ *
      * Parameter lists                                              *
      * ------------------------------------------------------------ *
      * Entry parameter list
     C     *Entry        PList
     C                   Parm                    PxUser           10            * User ID
     C                   Parm                    PxSMTP          256            * SMTP Address
     C                   Parm                    PxUserDesc       50            * User description

      * ------------------------------------------------------------ *
      * Main line                                                    *
      * ------------------------------------------------------------ *
      * Convert *CURRENT for user to current user
     C                   If        PxUser      = '*CURRENT'
     C                   Eval      PxUser      = PsCurUsr
     C                   EndIf
      * Initialisation
     C                   Eval      SrSrqNbrElm = 1
     C                   Eval      S1ValMtc(1) = PxUser
     C                   Eval      S1FldNam(1) = 'USER   '
     C                   Eval      PxSMTP=*Blanks
     C                   Eval      PxUserDesc=*Blanks

      * Get SMTP Information for user profile
     C                   Eval      Sr0103      = Sreq0103
     C                   Eval      Sr0101      = Sreq0101
     C                   Callp     SchDir( Srcv0100
     C                                   : %size( Srcv0100 )
     C                                   : 'SRCV0100'
     C                                   : '*SEARCH'
     C                                   : '0'
     C                                   : Sreq0100
     C                                   : %Size( Sreq0100 )
     C                                   : 'SREQ0100'
     C                                   : ApiError
     C                                   )
      **
     C                   If        AeBytAvl     >  0          Or
     C                             R00DirEntNbr =  0
      **
     C                   Eval      PxSMTP = *Blanks
      **
     C                   Else
     C                   Eval      pSrcv0101    =  %Addr( Srcv0100 ) +
     C                                             R00UsrEntOfs
     C                   Eval      pSrcv0111    =  pSrcv0101         +
     C                                             %Size( Srcv0101 )
      **
     C                   Do        R01RtnNbrFld
      **
     C                   Eval      pSrcv0111v   =  pSrcv0111         +
     C                                             %Size( Srcv0111 )
      **
     C                   Select
     C                   When      R11FldNam    =  'SMTPUSRID'
     C                   Eval      SmtpUsrId    =  %Subst( R11RtnFld
     C                                                   : 1
     C                                                   : R11RtnFldLen )
      **
     C                   When      R11FldNam    =  'SMTPDMN'
     C                   Eval      SmtpDmn      =  %Subst( R11RtnFld
     C                                                   : 1
     C                                                   : R11RtnFldLen )
     C                   EndSl
      **
     C                   Eval      pSrcv0111    =  pSrcv0111         +
     C                                             %Size( Srcv0111 ) +
     C                                             R11RtnFldLen
     C                   EndDo
     C
     C                   EndIf

      ** Get Directory information for user
     C                   Eval      Sr0103      = Sreq0103DIR
     C                   Eval      Sr0101      = Sreq0101
      **
     C                   Callp     SchDir( Srcv0100
     C                                   : %size( Srcv0100 )
     C                                   : 'SRCV0100'
     C                                   : '*SEARCH'
     C                                   : '0'
     C                                   : Sreq0100
     C                                   : %Size( Sreq0100 )
     C                                   : 'SREQ0100'
     C                                   : ApiError
     C                                   )
      **
     C                   If        AeBytAvl     >  0          Or
     C                             R00DirEntNbr =  0
      **
     C                   Eval      PxUserDesc = *Blanks
      **
     C                   Else
     C                   Eval      pSrcv0101    =  %Addr( Srcv0100 ) +
     C                                             R00UsrEntOfs
     C                   Eval      pSrcv0111    =  pSrcv0101         +
     C                                             %Size( Srcv0101 )
      **
     C                   Do        R01RtnNbrFld
      **
     C                   Eval      pSrcv0111v   =  pSrcv0111         +
     C                                             %Size( Srcv0111 )
      **
     C                   Select
     C                   When      R11FldNam    =  'USRD'
     C                   Eval      UserDesc     =  %Subst( R11RtnFld
     C                                                   : 1
     C                                                   : R11RtnFldLen )
     C                   EndSl
      **
     C                   Eval      pSrcv0111    =  pSrcv0111         +
     C                                             %Size( Srcv0111 ) +
     C                                             R11RtnFldLen
     C                   EndDo
      * Return retrieved values (if valid)
     C                   If        SmtpUsrId<>*Blanks and
     C                               SmtpDmn<>*Blanks
     C                   Eval      PxSMTP = SmtpUsrId+At+SmtpDmn
     C                   Eval      PxUserDesc = UserDesc
     C                   EndIf
     C
     C                   EndIf
      **
     C                   Return
