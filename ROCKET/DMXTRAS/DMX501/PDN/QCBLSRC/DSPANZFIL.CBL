       IDENTIFICATION DIVISION.
       PROGRAM-ID.   DSPANZFIL.
       AUTHOR.       DATA MIRROR CORP.
       INSTALLATION. DATA MIRROR CORP.
       DATE-COMPILED.
      *****************************************************************
      *                                                               *
      * Program:  DSPANZFIL                                           *
      * -------                                                       *
      * Version:  1.0                                                 *
      * -------                                                       *
      * Name:     DISPLAY FILE ATTIBUTES                              *
      * ----                                                          *
      * Files:    Screen File          (DSPANZFIL)                    *
      * -----                                                         *
      *                                                               *
      *****************************************************************
      /
      *****************************************************************
      * Change Log:  Mike Warkentin - Jan 20, 2000                    *
      *              Added WS-IND to pass back PF12 or PF3 to         *
      *                    HASTRJRNS                                  *
      *              Added CANCEL-REQUEST-IN12 to handle PF12         *
      *****************************************************************
      /
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER.  IBM-AS400.
       OBJECT-COMPUTER.  IBM-AS400.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT SCREEN-FILE
               ASSIGN       TO WORKSTATION-DSPANZFIL-SI
               ORGANIZATION IS TRANSACTION
               ACCESS       IS DYNAMIC
               RELATIVE KEY IS SUBFILE-RRN
               FILE STATUS  IS SUBFILE-STATUS.

           SELECT ATTR-FILE
               ASSIGN       TO DATABASE-ANZFILL2
               ORGANIZATION IS INDEXED
               ACCESS       IS DYNAMIC
               RECORD KEY   IS EXTERNALLY-DESCRIBED-KEY
               FILE STATUS  IS WS-FILE-STATUS.

      /
      ****************************************************************
      * D A T A   D I V I S O N                                      *
      ****************************************************************
       DATA DIVISION.
       FILE SECTION.

       FD  SCREEN-FILE
           LABEL RECORDS ARE STANDARD.
       01  SCREEN-REC.
           COPY DDS-ALL-FORMATS OF DSPANZFIL.

       FD  ATTR-FILE
           LABEL RECORDS ARE OMITTED.
       01  ATTR-REC.
           COPY DDS-ALL-FORMATS OF ANZFILL2.

      /
      ****************************************************************
      * W O R K I N G   S T O R A G E   S E C T I O N                *
      ****************************************************************
       WORKING-STORAGE SECTION.
      *
      *  SAVE AREA FOR SUBFILE
      *
       01  SUBFILE-DATA.
           03  SUBFILE-CONTROL-FORMAT.
               COPY DDS-SFLCTL   OF DSPANZFIL.
           03  SUBFILE-RECORD-FORMAT.
               COPY DDS-SFLRCD   OF DSPANZFIL.

       01  WS-MSGCTL-FMT.
           COPY DDS-MSGCTL-O        OF DSPANZFIL.
      *
       01  FILE-WS.
           05  SUBFILE-RRN             PIC 9(4)   VALUE 1.
           05  SUBFILE-STATUS          PIC X(2)   VALUE SPACES.
               88  SUBFILE-IS-FULL                VALUE "9M".
           05  DSPREC-RRN              PIC 9(4)   VALUE 1.

       01  ALL-99-INDICATORS.
           05  IN-CONTROL              OCCURS 99 TIMES
                                       PIC 1     INDICATOR 1.
               88  IND-ON-FOR                    VALUE B"1".
               88  IND-OFF-FOR                   VALUE B"0".

       01  INDICATOR-USAGE-LIST.
           05  EXIT-REQUESTED-IN03     PIC 99    VALUE 03.
           05  CANCEL-REQUEST-IN12     PIC 99    VALUE 12.
           05  SELECTION-ERROR         PIC 99    VALUE 30.
           05  DATA-COLOR              PIC 99    VALUE 31.
           05  DISPLAY-DATA-IN40       PIC 99    VALUE 40.
           05  EMPTY-SUBFILE-IN70      PIC 99    VALUE 70.
           05  CLR-MSG                 PIC 99    VALUE 98.
           05  DSP-MSG                 PIC 99    VALUE 99.

       01  WS-DESC                     PIC X(50).
       01  WS-DESC40                   PIC X(40).
       01  WS-RTNCDE                   PIC X(10).
       01  WS-PGM                      PIC X(6).

      **************************************************************
      * DMWMSG    - Send Message Routine
      **************************************************************
      *
       01  WS-MSG.
           05 WS-MSGID                   PIC X(7).
           05 WS-MSGF.
              10 WS-MSGFIL               PIC X(10).
              10 WS-MSGLIB               PIC X(10).
           05 WS-MSGDTA                  PIC X(100).
           05 WS-MSGDTALEN               PIC S9(8) COMP-4 VALUE 0.
           05 WS-MSGTYP                  PIC X(10) VALUE "*INFO".
           05 WS-MSGTYP-DIAG             PIC X(10) VALUE "*DIAG".
           05 WS-MSGTYP-INFO             PIC X(10) VALUE "*INFO".
           05 WS-MSGTYP-ESCAPE           PIC X(10) VALUE "*ESCAPE".
           05 WS-MSGQ                    PIC X(10) VALUE "*".
           05 WS-MSG-NOTIFY-COUNT        PIC S9(5) COMP-3 VALUE 0.
           05 WS-MSG-NOTIFY-MSGID        PIC X(10) VALUE "DMU0185".
           05 WS-MSG-NOTIFY-MSGDTA.
              10 WS-MSGDTA-THRESHOLD     PIC S9(9) COMP-4.
              10 WS-MSGDTA-EXTERNAL      PIC X(10).
           05 WS-MSG-NOTIFY-MSGDTALEN    PIC S9(8) COMP-4 VALUE 14.
           05 WS-MSG-QCOUNT              PIC S9(8) COMP-4 VALUE 1.
           05 WS-CSCTR                   PIC S9(8) COMP-4 VALUE 0.
           05 WS-MSGKEY                  PIC X(4).
           05 WS-ERRCDE.
              10 WS-ERRBYTP              PIC S9(8) COMP-4 VALUE 66.
              10 WS-ERRBYTA              PIC S9(8) COMP-4.
              10 WS-ERRID                PIC X(7).
              10 WS-ERRRES               PIC X(1).
              10 WS-ERRDATA              PIC X(50).
      *
           05 WS-MSGRMV                  PIC X(10) VALUE "*OLD".
      *
       01  WS-MSG-SYSPARM-DATA.
           05 WS-MSGQ-EXTERNAL.
              07 WS-MSGQ-EXTERNAL-NAME   PIC X(10) VALUE SPACES.
              07 WS-MSGQ-EXTERNAL-LIB    PIC X(10) VALUE SPACES.
           05 WS-MSGQ-NOTIFY             PIC X(20) VALUE SPACES.
           05 WS-MSG-NOTIFY-THRESHOLD    PIC 9(5)  VALUE 0.
      *
       01  WS-MSGDTA-FMT.
           05 WS-MD-FILE                 PIC X(10).
           05 WS-MD-KEY                  PIC X(50).

       01  WS-FIELDS.
           05  FILE-FOUND-SW           PIC X.
               88  FILE-FOUND                    VALUE "Y".
               88  FILE-NOT-FOUND                VALUE "N".
           05  SELECTION-SW            PIC X.
           05  WS-ERROR-DETECTED       PIC X.
           05  WS-FINISHED             PIC X     VALUE "N".
           05  CHANGE-SW               PIC X     VALUE "N".
           05  FIRST-SW                PIC X.
           05  SUBFILE-SRN             PIC 99    VALUE 0.
           05  WS-FILE-STATUS          PIC X(2)  VALUE SPACES.
           05  WS-FATAL-ERROR          PIC X     VALUE "N".
           05  WS-BUILD-SW             PIC X     VALUE "Y".
           05  ALL-FILE-SW             PIC X(1)  VALUE "N".
           05  ALL-LIB-SW              PIC X(1)  VALUE "N".
           05  WS-PREV-LIB             PIC X(10).
           05  WS-PREV-FILE            PIC X(10).
           05  WS-PREV-TYPE            PIC X(1).
      /
       LINKAGE SECTION.
       01  WS-IND                      PIC X(2).
      /
      ****************************************************************
      *   P R O C E D U R E   D I V I S I O N
      ****************************************************************
      *
       PROCEDURE DIVISION USING WS-IND.

       MAIN-CONTROL.

           PERFORM INITIAL-LOGIC     THRU  IL-EXIT.
           PERFORM BUILD-RT          THRU  BR-EXIT.

           PERFORM PROCESS-CONTROL   THRU PC-EXIT
                   UNTIL IND-ON-FOR (EXIT-REQUESTED-IN03)
                   OR    IND-ON-FOR (CANCEL-REQUEST-IN12)
                   OR    WS-FINISHED = "Y".

           PERFORM END-OF-JOB-LOGIC  THRU  EOJ-EXIT.
      /
      ****************************************************************
      * P R O C E S S   C O N T R O L                                *
      ****************************************************************
      *
       PROCESS-CONTROL.

      ****
      **  Clear the previously displayed messages.
      ****
           IF WS-FATAL-ERROR = "Y"
               GO TO PC-001.

      ****************************************************************
      * REMOVE MESSAGES VIA RMVMSG API                               *
      ****************************************************************
      *
           MOVE SPACES                 TO  WS-MSGKEY.
           CALL   "QMHRMVPM"        USING  WS-MSGQ
                                           WS-CSCTR
                                           WS-MSGKEY
                                           WS-MSGRMV
                                           WS-ERRCDE.
      *
       PC-001.

      ****
      **  Format and write the screen message control record
      ****
           SET IND-ON-FOR  (DSP-MSG)   TO  TRUE.
           SET IND-OFF-FOR (CLR-MSG)   TO  TRUE.

           WRITE SUBFILE SCREEN-REC FROM WS-MSGCTL-FMT
                 FORMAT IS  "MSGCTL"
                 INDICATORS ARE IN-CONTROL.

           SET IND-OFF-FOR (DSP-MSG)   TO  TRUE.
           SET IND-OFF-FOR (CLR-MSG)   TO  TRUE.

           WRITE SUBFILE SCREEN-REC
                 FORMAT IS "CMDKEY"
                 INDICATORS ARE IN-CONTROL.

           MOVE DSPREC-RRN             TO  DSPREC     OF SFLCTL-O
                                       IN  SUBFILE-CONTROL-FORMAT.
           MOVE WS-PREV-FILE           TO  SRCFIL OF SFLCTL-O
                                       IN  SUBFILE-CONTROL-FORMAT.
           MOVE WS-PREV-LIB            TO  SRCLIB OF SFLCTL-O
                                       IN  SUBFILE-CONTROL-FORMAT.
           MOVE WS-PREV-TYPE           TO  FTYPE  OF SFLCTL-O
                                       IN  SUBFILE-CONTROL-FORMAT.

           WRITE SUBFILE SCREEN-REC FROM SUBFILE-CONTROL-FORMAT
                 FORMAT IS "SFLCTL"
                 INDICATORS ARE IN-CONTROL.

           SET IND-OFF-FOR (SELECTION-ERROR) TO TRUE.

           READ  SUBFILE SCREEN-FILE INTO SUBFILE-CONTROL-FORMAT
                 FORMAT IS "SFLCTL"
                 INDICATORS ARE IN-CONTROL.

           IF  IND-ON-FOR  (EXIT-REQUESTED-IN03)
                MOVE "03"              TO  WS-IND
               GO TO PC-EXIT.

           IF  IND-ON-FOR  (CANCEL-REQUEST-IN12)
                MOVE "12"              TO  WS-IND
               GO TO PC-EXIT.

           IF WS-FATAL-ERROR = "Y"
               GO TO PC-EXIT.

           IF  WS-PREV-FILE NOT EQUAL TO SRCFIL OF SFLCTL-I
                                      IN SUBFILE-CONTROL-FORMAT
           OR  WS-PREV-LIB  NOT EQUAL TO SRCLIB OF SFLCTL-I
                                      IN SUBFILE-CONTROL-FORMAT
           OR  WS-PREV-TYPE NOT EQUAL TO FTYPE  OF SFLCTL-I
                                      IN SUBFILE-CONTROL-FORMAT
               MOVE SRCFIL OF SFLCTL-I IN SUBFILE-CONTROL-FORMAT
                                      TO WS-PREV-FILE
               MOVE SRCLIB OF SFLCTL-I IN SUBFILE-CONTROL-FORMAT
                                      TO WS-PREV-LIB
               MOVE FTYPE  OF SFLCTL-I IN SUBFILE-CONTROL-FORMAT
                                      TO WS-PREV-TYPE
               MOVE "Y"               TO WS-BUILD-SW
               PERFORM REBUILD-RT    THRU  RR-EXIT
               GO TO PC-EXIT.

           IF  IND-ON-FOR   (DISPLAY-DATA-IN40)
               PERFORM PROCESS-SEL THRU PS-EXIT.

       PC-EXIT.
           EXIT.
      /
      ****************************************************************
      *  B U I L D   S U B F I L E                                   *
      ****************************************************************
       BUILD-RT.
           IF WS-BUILD-SW = "N"
               SET IND-OFF-FOR (DISPLAY-DATA-IN40) TO TRUE
               GO TO BR-EXIT.

           MOVE  0                     TO  SUBFILE-RRN.
           MOVE  1                     TO  DSPREC-RRN.

           IF  WS-PREV-LIB IS EQUAL TO SPACES
               MOVE "Y"        TO ALL-LIB-SW
           ELSE
               MOVE "N"        TO ALL-LIB-SW.

           IF  WS-PREV-FILE IS EQUAL TO SPACES
               MOVE "Y"        TO ALL-FILE-SW
           ELSE
               MOVE "N"        TO ALL-FILE-SW.

           MOVE WS-PREV-LIB    TO PFLIB     OF ANZFILR.
           MOVE WS-PREV-FILE   TO PFFIL     OF ANZFILR.
           MOVE ZEROES         TO FILSEQ    OF ANZFILR.
           START ATTR-FILE
             KEY IS NOT LESS THAN EXTERNALLY-DESCRIBED-KEY
             INVALID KEY
               MOVE "DMA0001"          TO  WS-MSGID
               MOVE "START"            TO  WS-MSGDTA
               MOVE 10                 TO  WS-MSGDTALEN
               PERFORM SND-MSG-RTN THRU SMR-EXIT
               MOVE "Y"                    TO  WS-FATAL-ERROR
               MOVE "N"                    TO  WS-BUILD-SW
               GO TO BR-EXIT.

           IF  WS-FILE-STATUS IS NOT EQUAL TO "00"
               MOVE "DMA0001"          TO  WS-MSGID
               MOVE "START"            TO  WS-MSGDTA
               MOVE 10                 TO  WS-MSGDTALEN
               PERFORM SND-MSG-RTN THRU SMR-EXIT
               MOVE "Y"                    TO  WS-FATAL-ERROR
               MOVE "N"                    TO  WS-BUILD-SW
               GO TO BR-EXIT
           END-IF.

           MOVE "Y"               TO  FILE-FOUND-SW.
           PERFORM WRITE-SF           THRU WS-EXIT
              UNTIL   FILE-NOT-FOUND.

           SET IND-OFF-FOR (DISPLAY-DATA-IN40) TO TRUE.
           IF  SUBFILE-RRN IS GREATER THAN ZERO
               SET IND-ON-FOR (DISPLAY-DATA-IN40) TO TRUE.

       BR-EXIT.
           EXIT.
      /
      ****************************************************************
      * W R I T E   S U B F I L E                                    *
      ****************************************************************
       WRITE-SF.
           READ ATTR-FILE NEXT
             AT END
                MOVE "N"               TO  FILE-FOUND-SW
                GO TO WS-EXIT.

           MOVE SPACES                 TO  SELECTION OF SFLRCD
                                       IN  SUBFILE-RECORD-FORMAT.

           IF  ALL-LIB-SW     IS EQUAL TO  "N"
               IF  WS-PREV-LIB IS NOT EQUAL TO PFLIB OF ANZFILR
                   MOVE "N"        TO  FILE-FOUND-SW
                   GO TO WS-EXIT.

           IF  ALL-FILE-SW    IS EQUAL TO  "N"
           AND WS-PREV-FILE   NOT EQUAL TO  PFFIL OF ANZFILR
               MOVE "N"        TO  FILE-FOUND-SW
               GO TO WS-EXIT.

           IF  WS-PREV-TYPE        IS EQUAL TO  "U"
           AND UNIQ OF ANZFILR IS NOT EQUAL TO  "Y"
               GO TO WS-EXIT.

           IF  WS-PREV-TYPE        IS EQUAL TO  "N"
           AND UNIQ OF ANZFILR IS NOT EQUAL TO  "N"
               GO TO WS-EXIT.

           MOVE CORRESPONDING ANZFILR TO SFLRCD
                                       IN SUBFILE-RECORD-FORMAT.

           IF  MBRS OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO MBRS OF SFLRCD IN SUBFILE-RECORD-FORMAT.

           IF  UNIQ OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO UNIQ OF SFLRCD IN SUBFILE-RECORD-FORMAT.

           IF  REUSE OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO REUSE OF SFLRCD IN SUBFILE-RECORD-FORMAT.

           IF  JOINF OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO JOINF OF SFLRCD IN SUBFILE-RECORD-FORMAT.

           IF  JRN OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO JRNN OF SFLRCD IN SUBFILE-RECORD-FORMAT
                              JRNI OF SFLRCD IN SUBFILE-RECORD-FORMAT.

           SET IND-OFF-FOR (SELECTION-ERROR) TO TRUE.
           ADD   1                     TO SUBFILE-RRN.
           WRITE SUBFILE SCREEN-REC
                 FROM SUBFILE-RECORD-FORMAT
                 FORMAT IS "SFLRCD"
                 INDICATORS ARE IN-CONTROL.
       WS-EXIT.
           EXIT.
      /
      ****************************************************************
      *  C L E A R   S U B F I L E                                   *
      ****************************************************************
       CLEAR-RT.
           SET IND-OFF-FOR (DISPLAY-DATA-IN40)  TO TRUE.
           SET IND-ON-FOR (EMPTY-SUBFILE-IN70) TO TRUE.
           WRITE SUBFILE SCREEN-REC FROM SUBFILE-CONTROL-FORMAT
               FORMAT IS "SFLCTL"
               INDICATORS ARE IN-CONTROL.
           SET IND-OFF-FOR (EMPTY-SUBFILE-IN70) TO TRUE.
           SET IND-OFF-FOR (DISPLAY-DATA-IN40)  TO TRUE.
       CR-EXIT.
           EXIT.
      /
      ****************************************************************
      *  R E B U I L D   S U B F I L E                               *
      ****************************************************************
       REBUILD-RT.
           PERFORM CLEAR-RT          THRU  CR-EXIT.
           PERFORM BUILD-RT          THRU  BR-EXIT.

       RR-EXIT.
           EXIT.
      /
      ****************************************************************
      *  NO DATA IN SUBFILE                                          *
      ****************************************************************
       NO-DATA-RT.

      * -- If no data in subfile.

      *        MOVE "Y"  TO  WS-FINISHED.

       ND-EXIT.
           EXIT.
      /
      ****************************************************************
      *  P R O C E S S   S E L E C T I O N S                         *
      ****************************************************************
       PROCESS-SEL.
           MOVE "Y"                    TO  SELECTION-SW.
           PERFORM DO-SELECTION   THRU  DS-EXIT
              UNTIL SELECTION-SW = "N".

       PS-EXIT.
           EXIT.
      ****************************************************************
      * D O   S E L E C T I O N S                                    *
      ****************************************************************
       DO-SELECTION.
           READ  SUBFILE SCREEN-FILE  NEXT MODIFIED
                 INTO SUBFILE-RECORD-FORMAT
                 FORMAT IS "SFLRCD"
                 INDICATORS ARE IN-CONTROL
                    AT END
                    MOVE "N"           TO  SELECTION-SW
                    GO TO DS-EXIT.

           MOVE SUBFILE-RRN            TO  DSPREC-RRN.
           MOVE "N"                    TO  WS-ERROR-DETECTED.
           SET IND-OFF-FOR (SELECTION-ERROR) TO TRUE.

           IF  SELECTION OF SFLRCD IN SUBFILE-RECORD-FORMAT = " "
               GO TO DS-001.

           IF  SELECTION OF SFLRCD IN SUBFILE-RECORD-FORMAT = "5"
           AND KEYYES    OF SFLRCD IN SUBFILE-RECORD-FORMAT = "K"
                CALL "DSPANZFLD"   USING FILN  OF SFLRCD
                                      IN SUBFILE-RECORD-FORMAT
                                         LIBN  OF SFLRCD
                                      IN SUBFILE-RECORD-FORMAT
                ON EXCEPTION
                   MOVE "DMA0051"        TO  WS-MSGID
                   MOVE "DSPANZFLD"      TO  WS-MSGDTA
                   MOVE 10               TO  WS-MSGDTALEN
                   PERFORM SND-MSG-RTN THRU SMR-EXIT
                   SET IND-ON-FOR (SELECTION-ERROR) TO TRUE
                   MOVE "N"              TO  SELECTION-SW
                   MOVE "Y"              TO  WS-ERROR-DETECTED
                NOT EXCEPTION
                   CANCEL "DSPANZFLD"
                END-CALL
             ELSE
           IF  KEYYES    OF SFLRCD IN SUBFILE-RECORD-FORMAT
               IS NOT EQUAL TO "K"
               MOVE "DMA0040"        TO  WS-MSGID
               PERFORM SND-MSG-RTN THRU SMR-EXIT
               SET IND-ON-FOR (SELECTION-ERROR) TO TRUE
               MOVE "N"              TO  SELECTION-SW
               MOVE "Y"              TO  WS-ERROR-DETECTED
             ELSE
               MOVE "DMA0003"        TO  WS-MSGID
               MOVE "DSPANZFIL"      TO  WS-MSGDTA
               MOVE 10               TO  WS-MSGDTALEN
               PERFORM SND-MSG-RTN THRU SMR-EXIT
               SET IND-ON-FOR (SELECTION-ERROR) TO TRUE
               MOVE "N"              TO  SELECTION-SW
               MOVE "Y"              TO  WS-ERROR-DETECTED.



           IF  WS-ERROR-DETECTED = "Y"
               GO TO  DS-001
           END-IF.

           MOVE SPACES                 TO  SELECTION OF SFLRCD
                                       IN  SUBFILE-RECORD-FORMAT.
       DS-001.
           REWRITE SUBFILE SCREEN-REC FROM SUBFILE-RECORD-FORMAT
               FORMAT IS "SFLRCD"
               INDICATORS ARE IN-CONTROL.
       DS-EXIT.
           EXIT.
      /
      **************************************************************
      * DMCSNDMSG - Send Message Routine
      **************************************************************

       SND-MSG-RTN.

           MOVE   "HATMSGF"         TO     WS-MSGFIL
           MOVE   "*LIBL     "      TO     WS-MSGLIB
           CALL   "QMHSNDPM"        USING  WS-MSGID
                                           WS-MSGF
                                           WS-MSGDTA
                                           WS-MSGDTALEN
                                           WS-MSGTYP
                                           WS-MSGQ
                                           WS-CSCTR
                                           WS-MSGKEY
                                           WS-ERRCDE.
      *
           IF WS-MSGQ-EXTERNAL IS NOT EQUAL TO SPACES
              CALL   "QMHSNDM"      USING  WS-MSGID
                                           WS-MSGF
                                           WS-MSGDTA
                                           WS-MSGDTALEN
                                           WS-MSGTYP
                                           WS-MSGQ-EXTERNAL
                                           WS-MSG-QCOUNT
                                           WS-MSGQ-EXTERNAL
                                           WS-MSGKEY
                                           WS-ERRCDE.
      *
           IF WS-MSGTYP IS EQUAL TO WS-MSGTYP-DIAG
              IF WS-MSG-NOTIFY-THRESHOLD IS NOT EQUAL TO ZERO
                 ADD 1                 TO WS-MSG-NOTIFY-COUNT
                 IF WS-MSG-NOTIFY-COUNT IS GREATER THAN OR EQUAL TO
                                          WS-MSG-NOTIFY-THRESHOLD
                    MOVE ZERO          TO WS-MSG-NOTIFY-COUNT
                    IF WS-MSGQ-NOTIFY IS NOT EQUAL TO SPACES
                       MOVE WS-MSG-NOTIFY-THRESHOLD
                                       TO WS-MSGDTA-THRESHOLD
                       MOVE WS-MSGQ-EXTERNAL TO WS-MSGDTA-EXTERNAL
                       CALL "QMHSNDM"  USING  WS-MSG-NOTIFY-MSGID
                                              WS-MSGF
                                              WS-MSG-NOTIFY-MSGDTA
                                              WS-MSG-NOTIFY-MSGDTALEN
                                              WS-MSGTYP-INFO
                                              WS-MSGQ-NOTIFY
                                              WS-MSG-QCOUNT
                                              WS-MSGQ-NOTIFY
                                              WS-MSGKEY
                                              WS-ERRCDE.
      *
           MOVE WS-MSGTYP-INFO         TO WS-MSGTYP.
      *
       SMR-EXIT.
           EXIT.

      /
      **************************************************************
      *   I N I T I A L   L O G I C                                *
      **************************************************************
       INITIAL-LOGIC.

           MOVE SPACES                 TO  WS-MSGCTL-FMT.
           MOVE "DSPANZFIL"            TO  PGMFLD   OF WS-MSGCTL-FMT.
           MOVE ALL B"0"               TO  ALL-99-INDICATORS.
      *
           OPEN  I-O   SCREEN-FILE.

           OPEN  INPUT ATTR-FILE.
           IF WS-FILE-STATUS IS NOT = "00"
               MOVE "DMA0001"          TO  WS-MSGID
               MOVE "ANZFILL2"        TO  WS-MSGDTA
               MOVE 10                 TO  WS-MSGDTALEN
               PERFORM SND-MSG-RTN THRU SMR-EXIT
               MOVE "Y"                    TO  WS-FATAL-ERROR
               MOVE "N"                    TO  WS-BUILD-SW
               GO TO IL-EXIT.

           MOVE  SPACES        TO  WS-PREV-LIB.
           MOVE  SPACES        TO  WS-PREV-FILE.
           MOVE  "A"           TO  WS-PREV-TYPE.

       IL-EXIT.
           EXIT.
      /
      **************************************************************
      *   E N D   O F   J O B   L O G I C                          *
      **************************************************************
       END-OF-JOB-LOGIC.

           CLOSE  SCREEN-FILE.
           CLOSE  ATTR-FILE.

           EXIT PROGRAM.
           STOP RUN.
       EOJ-EXIT.
           EXIT.
