       IDENTIFICATION DIVISION.
       PROGRAM-ID.   ADDANZFLD.
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
           SELECT FLD-FILE
               ASSIGN       TO DATABASE-ANZFLDL1
               ORGANIZATION IS INDEXED
               ACCESS       IS DYNAMIC
               RECORD KEY   IS EXTERNALLY-DESCRIBED-KEY
               FILE STATUS  IS WS-FILE-STATUS.

           SELECT ACCP-FILE
               ASSIGN       TO DATABASE-ANZFILC
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS  IS WS-FILE-STATUS.

      /
      ****************************************************************
      * D A T A   D I V I S O N                                      *
      ****************************************************************
       DATA DIVISION.
       FILE SECTION.

       FD  FLD-FILE
           LABEL RECORDS ARE OMITTED.
       01  FLD-REC.
           COPY DDS-ALL-FORMATS OF ANZFLDL1.

       FD  ACCP-FILE
           LABEL RECORDS ARE OMITTED.
       01  ACCP-REC.
           COPY DDS-ALL-FORMATS OF ANZFILC.
      /
      ****************************************************************
      * W O R K I N G   S T O R A G E   S E C T I O N                *
      ****************************************************************
       WORKING-STORAGE SECTION.
      *
       01  WS-ATTR-REC.
           COPY DDS-ALL-FORMATS OF ANZFLDL1.
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
           05 WS-SEQ                     PIC S9(4).
      /
       LINKAGE SECTION.
       01  WS-FILE                       PIC X(10).
       01  WS-LIB                        PIC X(10).
       01  WS-UNIQUE                     PIC X(1).
       01  WS-JOIN                       PIC X(1).
      /
      ****************************************************************
      *   P R O C E D U R E   D I V I S I O N
      ****************************************************************
       PROCEDURE DIVISION  USING WS-FILE WS-LIB WS-UNIQUE WS-JOIN.

       MAINLINE.
      *
           PERFORM INITIAL-LOGIC.

           PERFORM READ-ACCP THRU ACP-EXIT.

           PERFORM END-OF-JOB.
      /
       READ-ACCP.
           READ ACCP-FILE NEXT
             AT END
                GO TO ACP-EXIT.

           MOVE APJOIN OF QWHFDACP    TO  WS-JOIN.
           MOVE APUNIQ OF QWHFDACP    TO  WS-UNIQUE.

           MOVE WS-FILE                   TO  FILN OF ANZFLDR
                                              OF WS-ATTR-REC.
           MOVE WS-LIB                    TO  LIBN OF ANZFLDR
                                              OF WS-ATTR-REC.
           MOVE APKEYF OF QWHFDACP        TO  FLDN OF ANZFLDR
                                              OF WS-ATTR-REC.
           MOVE APKEYN OF QWHFDACP        TO  FLDSEQ OF ANZFLDR
                                              OF WS-ATTR-REC.
           IF  APFTYP OF QWHFDACP IS EQUAL TO  "L"
               MOVE APBOF  OF QWHFDACP    TO  PFFIL OF ANZFLDR
                                              OF WS-ATTR-REC
               MOVE APBOL  OF QWHFDACP    TO  PFLIB OF ANZFLDR
                                              OF WS-ATTR-REC
           ELSE
               MOVE WS-FILE               TO  PFFIL OF ANZFLDR
                                              OF WS-ATTR-REC
               MOVE WS-LIB                TO  PFLIB OF ANZFLDR
                                              OF WS-ATTR-REC.
           MOVE WS-SEQ                    TO  FILSEQ OF ANZFLDR
                                              OF WS-ATTR-REC.
           MOVE WS-ATTR-REC          TO  FLD-REC.
           ADD 1                     TO  WS-SEQ.

           WRITE FLD-REC.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "DMA0010"    TO  WS-MSGID
              MOVE "ANZFLDL1"   TO  WS-MSGDTA
              MOVE 10           TO  WS-MSGDTALEN
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              GO TO ACP-EXIT.

           GO TO READ-ACCP.

       ACP-EXIT.
           EXIT.
      /
      **************************************************************
      * INITIAL LOGIC routine                                      *
      *                                                            *
      **************************************************************
       INITIAL-LOGIC.

           MOVE 1 TO WS-SEQ.
           MOVE "Y" TO WS-FIRST-SW.
           OPEN I-O   FLD-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "ANZFLDF1"        TO  WS-MSGDTA
              MOVE 10                TO  WS-MSGDTALEN
              MOVE "DMA0007"         TO  WS-MSGID
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              PERFORM END-OF-JOB.

           OPEN INPUT ACCP-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "ANZFILC  "       TO  WS-MSGDTA
              MOVE 10                TO  WS-MSGDTALEN
              MOVE "DMA0007"         TO  WS-MSGID
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              PERFORM END-OF-JOB.

      /
      **************************************************************
      * END OF JOB routine.                                        *
      *                                                            *
      * The following code handles the end of job processing       *
      **************************************************************
       END-OF-JOB.

           CLOSE FLD-FILE.
           CLOSE ACCP-FILE.
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
