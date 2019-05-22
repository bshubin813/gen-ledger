      * ============================================================ *
      * Object:    HSNDFTP1        *PGM RPG                          *
      *            Generates an FTP script which is used to send     *
      *            a save file to the remote system.                 *
      *                                                              *
      * Synopsis:  See Command HSNDFTP.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20010624 FK  Initial delivery                                *
      * 20020307 FK  Create save file with description               *
      * ============================================================ *
     FHFTPSRC   O    E             DISK    RENAME(HFTPSRC:@HFTPSRC)
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
     DSVFQPA           DS            20
     D Savf                    1     10                                         * Save file
     D SavfL                  11     20                                         * Save file library
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Variables                                                     *
      * ------------------------------------------------------------- *
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
     C                   Parm                    SVFQPA                         * Save file qual
     C                   Parm                    TEXTPA           50            * Description
     C                   Parm                    RMTHPA          100            * Remote host
     C                   Parm                    UPRFPA           10            * User profile
     C                   Parm                    UPWDPA           10            * User password
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Make up qualified name for save file
     C     SavfL         Cat(p)    '/':0         SavfQ            21            * Save file qual
     C                   Cat       Savf:0        SavfQ                          * Save file qual
      * Write user <user> <password>
     C     UPRFPA        Cat(p)    UPWDPA:1      SRCDTA
     C                   Write     @HFTPSRC
      * Write bin
     C                   MoveL(p)  'bin'         SRCDTA
     C                   Write     @HFTPSRC
      * Write quote rcmd crtsavf <savf> text('<text>')
     C     'quote rcmd'  CAT(p)    'crtsavf':1   SRCDTA
     C                   CAT(p)    SavfQ:1       SRCDTA
     C                   CAT(p)    'text(''':1   SRCDTA
     C                   CAT(p)    TEXTPA:0      SRCDTA
     C                   CAT(p)    ''')':0       SRCDTA
     C                   Write     @HFTPSRC
      * Write put <savf> <savf>
     C     'put'         CAT(p)    SavfQ:1       SRCDTA
     C                   CAT(p)    SavfQ:1       SRCDTA
     C                   Write     @HFTPSRC
      * Write quit
     C                   MoveL(p)  'quit'        SRCDTA
     C                   Write     @HFTPSRC
      * End program
     C                   Seton                                        LR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
