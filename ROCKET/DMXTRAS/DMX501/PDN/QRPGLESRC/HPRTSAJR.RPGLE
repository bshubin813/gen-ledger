      * ============================================================ *
      * Object:    HPRTSAJR        *PGM RPG                          *
      *            Prints the journal entries output by the HPRTSAJ  *
      *            program.                                          *
      *                                                              *
      * Synopsis:  See Command HPRTSAJ.                              *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 19990708 FK  Initial delivery                                *
      * 20000422 FK  Print column heading on every page              *
      * 20070521 FK  Rename HPRTSAJ$ to HPRTSAJP                     *
      * ============================================================ *
      * Temporary output file for security audit journal entries
     FHPRTSAJ   IF   E             DISK
      * Output printer file
     FHPRTSAJP  O    E             PRINTER OFLIND(*IN01)
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * Entry type and associated message ID
     D JCD             S              4    DIM(100) CTDATA PERRCD(1)
     D MID             S              7    DIM(100) ALT(JCD)
      * Entry types to skip
     D SKT             S              3    DIM(10) CTDATA PERRCD(1)
      * Users to skip
     D SKU             S             10    DIM(10) CTDATA PERRCD(1)
      * Programs to skip
     D SKP             S             10    DIM(20) CTDATA PERRCD(1)
      * Extra information array
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * API-Error data structure
     D APIERR          DS
     D  BPVDAE                 1      4B 0
      * Binary fields for QMHRTVM API
     D                 DS
     D  MSILRM                 1      4B 0
     D  MSDLRM                 5      8B 0
      * Message information for Retrieve message (format RTVM0100)
     D RM0100          DS
     D  BRTNRM                 1      4B 0
     D  BAVLRM                 5      8B 0
     D  LRTNRM                 9     12B 0
     D  LAVLRM                13     16B 0
     D  HRTNRM                17     20B 0
     D  HAVLRM                17     20B 0
     D  RMSGRM                25    157
      * Data structure for external record for HPRTSAJ
     D SAJRCD        E DS                  EXTNAME(HPRTSAJ)
     D  COD3WY                16     18
      * Data structure to hold audit record temporarily
     D SAJRWY          DS           357
      * Data structure to adjust extra information
     D                 DS
     D  EXR                    1     80
     D                                     DIM(80)
     D  EXTRRC                 1     80
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
     D #UPPER          C                   CONST('QCASE256')
     D #ALL            C                   CONST('*ALL')
     D #NONE           C                   CONST('*NONE')
     D #NO             C                   CONST('*NO')
     D #CPF            C                   CONST('QCPFMSG   *LIBL     ')
      * ------------------------------------------------------------- *
      * Key lists                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Parameter lists                                               *
      * ------------------------------------------------------------- *
     C     *ENTRY        PLIST
     C                   PARM                    DAYSPA            3 0          * Age in days
     C                   PARM                    HOURPA            2 0          * Age in hours
     C                   PARM                    USRPPA           10            * User profile
     C                   PARM                    JOBPA            10            * Job
     C                   PARM                    PGMPA            10            * Program
     C                   PARM                    OBJPA            10            * Object
     C                   PARM                    LIBPA            10            * Library
     C                   PARM                    TYPEPA            8            * Object type
     C                   PARM                    SCANPA           20            * Scan string
     C                   PARM                    INCTPA            4            * Include T-ZC
     C                   PARM                    ENTTPA            4            * Entry type
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialise header record
     C                   MOVE      DAYSPA        DAYSHD                         * Age in days
     C                   MOVE      HOURPA        HOURHD                         * Age in hours
     C                   MOVEL     USRPPA        USRPHD                         * User profile
     C                   MOVEL     JOBPA         JOBHD                          * Job
     C                   MOVEL     PGMPA         PGMHD                          * Program
     C                   MOVEL     OBJPA         OBJHD                          * Object
     C                   MOVEL     LIBPA         LIBHD                          * Library
     C                   MOVEL     TYPEPA        TYPEHD                         * Object type
     C                   MOVEL     SCANPA        SCANHD                         * Scan string
     C                   MOVEL     ENTTPA        ENTTHD                         * Journal code
     C                   MOVEL     INCTPA        INCTHD                         * Include T-ZC
      * Print age in days or hours
     C     HOURPA        IFNE      -1                                           * *DAYS
     C                   MOVE      *ON           *IN21                          * Show hours
     C                   ENDIF
      * Convert scan string to uppercase
     C     SCANPA        IFNE      #NONE
     C                   MOVEL     SCANPA        SCANWY           20            * Scan string
     C                   CALL      'QDCXLATE'
     C                   PARM      20            BUFLWY            5 0          * Buffer length
     C                   PARM                    SCANWY                         * Scan string
     C                   PARM      #UPPER        XTBLWY           10            * Translate table
     C                   ENDIF
      * Print report header and first page header
     C                   WRITE     SAJHDR
     C                   WRITE     SAJH1P                                       * First page
     C                   WRITE     SAJHCH                                       * Column headings
      * Process entire MDSPAUD file
     C                   READ      HPRTSAJ@                               95
     C     *IN95         DOWEQ     *OFF
      * Initialise loop
     C                   MOVE      *ON           RCDSLT            1            * Record selected
      * Determine if record must be selected
     C                   EXSR      SRSLRC                                       * Select record
      * Initialise record
     C     RCDSLT        IFEQ      *ON
     C                   EXSR      SRINRC                                       * Initialise record
     C     RCDSLT        IFEQ      *ON
     C                   EXSR      SRPRRC                                       * Print record
     C                   ENDIF
     C                   ENDIF
      * Read next record in sequence
     C                   READ      HPRTSAJ@                               95
     C                   ENDDO
      * Print footer record
     C     *IN01         IFEQ      *ON
     C                   WRITE     SAJHDR
     C                   MOVE      *OFF          *IN01
     C                   ENDIF
     C                   WRITE     SAJFTR
      * End program
     C                   SETON                                        LR
      * ------------------------------------------------------------------- *
      * *INZSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *INZSR        BEGSR
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * SRSLRC - Select record                                              *
      * ------------------------------------------------------------------- *
     C     SRSLRC        BEGSR
      * Determine if journal entry must be skipped (skip journal codes)
     C     COD3WY        LOOKUP    SKT                                    20    * Entry types to ski
     C     *IN20         IFEQ      *ON
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
      * Must T-ZC entries be skipped?
     C     COD3WY        IFEQ      'TZC'                                        * T-ZC entry
     C     INCTPA        ANDEQ     #NO
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
      * Determine if user profile must be skipped (skip user profiles)
     C     SAUSER        LOOKUP    SKU                                    20    * User profiles to s
     C     *IN20         IFEQ      *ON
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
      * Determine if programs must be skipped (skip programs)
     C     SAPGM         LOOKUP    SKP                                    20    * Programs to skip
     C     *IN20         IFEQ      *ON
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
      * Check for matching object name
     C     OBJPA         IFNE      #ALL                                         * *ALL
     C     SAOBJ         ANDNE     OBJPA                                        * Object  name
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
      * Check for matching library name
     C     LIBPA         IFNE      #ALL                                         * *ALL
     C     SALIB         ANDNE     LIBPA                                        * Library name
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
      * Check for matching object type
     C     TYPEPA        IFNE      #ALL                                         * *ALL
     C     SATYPE        ANDNE     TYPEPA                                       * Object type
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
      * Scan for usage on the scan string
     C     SCANPA        IFNE      #NONE
     C                   MOVEL     SAJRCD        SAJRWY                         * Audit record
     C     SCANWY        SCAN      SAJRWY:1                               20
     C     *IN20         IFEQ      *OFF                                         * Not found
     C                   MOVE      *OFF          RCDSLT                         * Record selected
     C                   ENDIF
     C                   ENDIF
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * SRINRC - Initialise record                                          *
      * ------------------------------------------------------------------- *
     C     SRINRC        BEGSR
      * Clear output record
     C                   CLEAR                   SAJDTL
      * Make up 4-character code for output and lookup
     C     COD3WY        CAT       SAENTS        COD4WY            4            * 4-char code
      * Fill output fields
     C                   MOVEL     SADATE        DATERC                         * Date
     C                   MOVEL     SATIME        TIMERC                         * Time
     C                   MOVEL     COD4WY        CODERC                         * Journal code
     C                   MOVEL     SAOBJ         OBJRC                          * Object
     C                   MOVEL     SALIB         LIBRC                          * Library
     C                   MOVEL     SATYPE        TYPERC                         * Type
     C                   MOVEL     SANBR         JOB#RC                         * Job number
     C                   MOVEL     SAUSER        JOBURC                         * Job user
     C                   MOVEL     SAJOB         JOBNRC                         * Job name
     C                   MOVEL     SAPGM         PGMRC                          * Program
     C                   MOVEL     SAUSPF        USPFRC                         * User profile
      * Determine the message ID that is associated with the journal code
     C                   Z-ADD     1             I                 3 0          * Index
     C     COD4WY        LOOKUP    JCD(I)                                 20
     C     *IN20         IFEQ      *ON
      * Move message ID in output field
     C                   MOVEL     MID(I)        MSGIRC                         * Message ID
      * Call API 'Retrieve message'
     C                   CLEAR                   APIERR                         * API Error
     C                   CALL      'QMHRTVM'                            90
     C                   PARM                    RM0100                         * O: Message info
     C                   PARM      157           MSILRM
     C                   PARM      'RTVM0100'    APIFRM            8            * Format name
     C                   PARM                    MSGIRC                         * Message ID
     C                   PARM      #CPF          MSGFRM           20            * Message file
     C                   PARM                    SAJRCD                         * Message data
     C                   PARM      255           MSDLRM                         * Message data lengt
     C                   PARM      '*YES'        MDSVRM           10            * Replace subst. var
     C                   PARM      '*YES'        MHFCRM           10            * Return help fmt ct
     C                   PARM                    APIERR                         * API error
     C     *IN90         IFEQ      *ON
     C                   MOVEL     MSGIRC        EXTRRC
     C                   ELSE
     C                   MOVEL     RMSGRM        EXTRRC
     C                   ENDIF
      * Remove all information after the first &N
     C     '&N'          SCAN      EXTRRC        I                 3 0
     C     I             IFNE      0
     C                   MOVEA     *BLANKS       EXR(I)
     C                   ENDIF
     C                   ENDIF
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * SRPRRC - Print detail record                                        *
      * ------------------------------------------------------------------- *
     C     SRPRRC        BEGSR
      * Print detail record
     C     *IN01         IFEQ      *ON
     C                   WRITE     SAJHDR
     C                   WRITE     SAJHCH                                       * Column headings
     C                   MOVE      *OFF          *IN01
     C                   ENDIF
     C                   WRITE     SAJDTL
     C                   ENDSR
      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
** Journal code and entry types with their associated message IDs  (JCD/MID)
TAFACPI2246      Object authority failure
TAFBCPI2268      Blocked instruction violation
TAFCCPI2250      Program validation value error during restore
TAFDCPI2247      Object domain violation
TAFJCPI2248      SBMJOB and not authorized to user in JOBD
TAFSCPI2249      Signon requested using default user profile
TAFPCPI2270      Profile handle specified on QWTSETP not valid
TAFRCPI2274      Read only storage violation
TCAACPI2253      Object authority change
TCPACPI2266      User profile created, changed or restored
TCONCPI2277      Create of a new object
TCORCPI2278      Create of an object with REPLACE(*YES)
TDOACPI2263      Object deleted
TDSACPI2267      DST Security Officer password reset
TJDACPI2264      Create/change of a JOBD with a user profile
TNAACPI2257      Network attribute changed
TOMMCPI2281      Move object
TOMRCPI2282      Rename object
TORNCPI2279      Restore object of a new object
TORECPI2280      Restore object over previously existing object
TOWACPI2254      Object owner change
TPAACPI2255      CHGPGM used to adopt a user profile
TRAACPI2261      Restore object and authority changed
TSEACPI2265      Routing entry changed in subsystem
TRJACPI2259      Restore of a JOBD containing a user profile
TROACPI2260      Restore of object and ownership change
TRPACPI2258      Restore of a program that adopts
TRUACPI2262      Restore authority for a user profile
TPWPCPI2251      Invalid password entered
TPWUCPI2252      Invalid user ID entered
TSVACPI2256      System value changed
TCDCCPF9898      Command Usage
** Entry types to skip (SKE)
TSF              Spooled file
TZR              Contents read
** Users to skip (SKU)
QSPLJOB
QSYS
QSVCDRCTR
QTCP
QTMHHTTP
** Programs to skip (SKP)
QZCSRVSD
QZDSTSND
QZDASOINIT
QZRCSRVSD
QPWFSERVSD
QNPSERVD
QZHQSRVD
QZSCSRVS
QZSCSRVSD
QZSOSGND
QZSOSMAPD
QZSOSIGN
