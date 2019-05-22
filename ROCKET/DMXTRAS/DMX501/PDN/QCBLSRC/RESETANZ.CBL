       IDENTIFICATION DIVISION.
       PROGRAM-ID.   RESETANZ.
       AUTHOR.       DATA MIRROR CORP.
       INSTALLATION. DATA MIRROR CORP.
       DATE-COMPILED.
      *****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-AS400.
       OBJECT-COMPUTER. IBM-AS400.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ANZ-FILE
               ASSIGN       TO DATABASE-ANZFILL2
               ORGANIZATION IS INDEXED
               ACCESS       IS DYNAMIC
               RECORD KEY   IS EXTERNALLY-DESCRIBED-KEY
               FILE STATUS  IS WS-FILE-STATUS.

           SELECT FLD-FILE
               ASSIGN       TO DATABASE-ANZFLDL2
               ORGANIZATION IS INDEXED
               ACCESS       IS DYNAMIC
               RECORD KEY   IS EXTERNALLY-DESCRIBED-KEY
                     WITH DUPLICATES
               FILE STATUS  IS WS-FILE-STATUS.

      /
      ****************************************************************
      * D A T A   D I V I S O N                                      *
      ****************************************************************
       DATA DIVISION.
       FILE SECTION.

       FD  ANZ-FILE
           LABEL RECORDS ARE OMITTED.
       01  ANZ-REC.
           COPY DDS-ALL-FORMATS OF ANZFILL2.

       FD  FLD-FILE
           LABEL RECORDS ARE OMITTED.
       01  FLD-REC.
           COPY DDS-ALL-FORMATS OF ANZFLDL2.
      /
      ****************************************************************
      * W O R K I N G   S T O R A G E   S E C T I O N                *
      ****************************************************************
       WORKING-STORAGE SECTION.
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

       01  WS-VARIABLES.
           05 WS-FILE-STATUS             PIC X(2)  VALUE "00".
           05 WS-FIRST-SW                PIC X(1)  VALUE "Y".

      /
       LINKAGE SECTION.
       01  WS-PF-FILE                    PIC X(10).
       01  WS-PF-LIB                     PIC X(10).
      /
      ****************************************************************
      *   P R O C E D U R E   D I V I S I O N
      ****************************************************************
       PROCEDURE DIVISION USING WS-PF-FILE WS-PF-LIB.

       MAINLINE.
      *
           PERFORM INITIAL-LOGIC  THRU INIT-EXIT.

           PERFORM READ-PF THRU PF-EXIT.

           PERFORM END-OF-JOB.
      /
       READ-PF.
           MOVE WS-PF-FILE                 TO PFFIL OF ANZFILR.
           MOVE WS-PF-LIB                  TO PFLIB OF ANZFILR.
           MOVE ZEROES                     TO FILSEQ OF ANZFILR.
           START ANZ-FILE
               KEY IS NOT LESS THAN EXTERNALLY-DESCRIBED-KEY
               INVALID KEY
                  GO TO PF-EXIT.

       PF-0001.
           READ ANZ-FILE NEXT
             AT END
                GO TO PF-0002.

           IF  PFFIL OF ANZFILR IS NOT EQUAL TO WS-PF-FILE
           OR  PFLIB OF ANZFILR IS NOT EQUAL TO WS-PF-LIB
                GO TO PF-0002.

           DELETE ANZ-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "DMA0010"    TO  WS-MSGID
              MOVE "ANZFILL2"   TO  WS-MSGDTA
              MOVE 10           TO  WS-MSGDTALEN
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              GO TO PF-EXIT.

           GO TO PF-0001.

       PF-0002.
           MOVE WS-PF-FILE                 TO PFFIL OF ANZFLDR.
           MOVE WS-PF-LIB                  TO PFLIB OF ANZFLDR.
           MOVE ZEROES                     TO FILSEQ OF ANZFLDR.
           START FLD-FILE
               KEY IS NOT LESS THAN EXTERNALLY-DESCRIBED-KEY
               INVALID KEY
                  GO TO PF-EXIT.

       PF-0003.
           READ FLD-FILE NEXT
             AT END
                GO TO PF-EXIT.

           IF  PFFIL OF ANZFLDR IS NOT EQUAL TO WS-PF-FILE
           OR  PFLIB OF ANZFLDR IS NOT EQUAL TO WS-PF-LIB
                GO TO PF-EXIT.

           DELETE FLD-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "DMA0010"    TO  WS-MSGID
              MOVE "ANZFLDL2"   TO  WS-MSGDTA
              MOVE 10           TO  WS-MSGDTALEN
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              GO TO PF-EXIT.

           GO TO PF-0002.

       PF-EXIT.
           EXIT.
      /
      **************************************************************
      * INITIAL LOGIC routine                                      *
      *                                                            *
      * This routine opens the Journal ID and Journal Status files.*
      **************************************************************
       INITIAL-LOGIC.

           OPEN I-O   ANZ-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "ANZFILL2"        TO  WS-MSGDTA
              MOVE 10                TO  WS-MSGDTALEN
              MOVE "DMA0001"         TO  WS-MSGID
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              PERFORM END-OF-JOB.

           OPEN I-O   FLD-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "ANZFLDL2"        TO  WS-MSGDTA
              MOVE 10                TO  WS-MSGDTALEN
              MOVE "DMA0007"         TO  WS-MSGID
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              PERFORM END-OF-JOB.

       INIT-EXIT.
           EXIT.

      /
      **************************************************************
      * END OF JOB routine.                                        *
      *                                                            *
      * The following code handles the end of job processing       *
      **************************************************************
       END-OF-JOB.

           CLOSE ANZ-FILE
                 FLD-FILE.
           STOP RUN.
      /
      **************************************************************
      * SEND MESSAGE ROUTINE                                       *
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
