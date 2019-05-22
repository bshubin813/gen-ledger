       IDENTIFICATION DIVISION.
       PROGRAM-ID.   PRTANZFILS.
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
           SELECT ATR-FILE
               ASSIGN       TO DATABASE-ANZFILL2
               ORGANIZATION IS INDEXED
               ACCESS       IS DYNAMIC
               RECORD KEY   IS EXTERNALLY-DESCRIBED-KEY
               FILE STATUS  IS WS-FILE-STATUS.

           SELECT FLD-FILE
               ASSIGN       TO DATABASE-ANZFLDL3
               ORGANIZATION IS INDEXED
               ACCESS       IS DYNAMIC
               RECORD KEY   IS EXTERNALLY-DESCRIBED-KEY
               FILE STATUS  IS WS-FILE-STATUS.

           SELECT PRT-FILE
               ASSIGN       TO FORMATFILE-PRTANZFILS
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS  IS WS-FILE-STATUS.

      /
      ****************************************************************
      * D A T A   D I V I S O N                                      *
      ****************************************************************
       DATA DIVISION.
       FILE SECTION.

       FD  ATR-FILE
           LABEL RECORDS ARE OMITTED.
       01  ATR-REC.
           COPY DDS-ALL-FORMATS OF ANZFILL2.

       FD  FLD-FILE
           LABEL RECORDS ARE OMITTED.
       01  FLD-REC.
           COPY DDS-ALL-FORMATS OF ANZFLDL3.

       FD  PRT-FILE
           LABEL RECORDS ARE OMITTED.
       01  PRT-REC.
           COPY DDS-ALL-FORMATS OF PRTANZFILS.
      /
      ****************************************************************
      * W O R K I N G   S T O R A G E   S E C T I O N                *
      ****************************************************************
       WORKING-STORAGE SECTION.
      *
       01  ERR1-RECD.
           05  ERRFIL             PIC X(10).
           05  ERRSTS             PIC X(2).
      *
       01  ERR2-RECD.
           05  ERRDESC            PIC X(80).
      *
       01  DTL1-RECD.
           05 FILN                       PIC X(10).
           05 LIBN                       PIC X(10).
           05 FILA                       PIC X(6).
           05 UNIQ                       PIC X(1).
           05 MBRS                       PIC X(1).
           05 JOINF                      PIC X(1).
           05 REUSE                      PIC X(1).
           05 RECS                       PIC S9(10).
           05 RECLEN                     PIC S9(5).
           05 JRN                        PIC X(1).
           05 JRNN                       PIC X(10).
           05 JRNL                       PIC X(10).
           05 JRNI                       PIC X(1).

       01  DTL2-RECD.
           05 DESC                       PIC X(11).
           05 FLDSEQ                     PIC S9(4).
           05 FLDN                       PIC X(10).

       01  WS-VARIABLES.
           05 WS-FILE-STATUS             PIC X(2)  VALUE "00".
           05 WS-FIRST-SW                PIC X(1)  VALUE "Y".
           05 LINE-CTR                   PIC S9(2) VALUE 99.
      /
       LINKAGE SECTION.
       01  WS-LIB                        PIC X(10).
       01  WS-TYPE                       PIC X(1).
       01  WS-KEYS                       PIC X(4).
      /
      ****************************************************************
      *   P R O C E D U R E   D I V I S I O N
      ****************************************************************
       PROCEDURE DIVISION  USING WS-LIB WS-TYPE WS-KEYS.

       MAINLINE.
      *
           PERFORM INITIAL-LOGIC.

           PERFORM PRT-ATR THRU PRT-EXIT.

           PERFORM END-OF-JOB.
           EXIT PROGRAM.
           STOP RUN.
      /
       PRT-ATR.
           READ ATR-FILE NEXT
             AT END
                GO TO PRT-EXIT.

           IF  WS-LIB  IS NOT EQUAL TO PFLIB OF ANZFILR
               GO TO PRT-EXIT.

           IF  WS-TYPE           IS EQUAL TO  "U"
           AND UNIQ OF ANZFILR  NOT EQUAL TO  "Y"
               GO TO PRT-ATR.

           IF  WS-TYPE           IS EQUAL TO  "N"
           AND UNIQ OF ANZFILR  NOT EQUAL TO  "N"
               GO TO PRT-ATR.

           MOVE CORRESPONDING ANZFILR     TO  DTL1-RECD.

           IF  MBRS OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO MBRS OF DTL1-RECD.

           IF  UNIQ OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO UNIQ OF DTL1-RECD.

           IF  JOINF OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO JOINF OF DTL1-RECD.

           IF  REUSE OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO REUSE OF DTL1-RECD.

           IF  JRN OF ANZFILR IS EQUAL TO  "N"
               MOVE SPACES TO JRN OF DTL1-RECD
                              JRNN OF DTL1-RECD
                              JRNL OF DTL1-RECD
                              JRNI OF DTL1-RECD.

           IF  LINE-CTR    IS GREATER THAN 55
               WRITE PRT-REC FORMAT IS "HEADER1"
               WRITE PRT-REC FORMAT IS "HEADER2"
               MOVE 6                TO LINE-CTR.

           MOVE CORRESPONDING DTL1-RECD  TO DETAIL1-O.

           WRITE PRT-REC FORMAT IS "DETAIL1".
           ADD 1                         TO  LINE-CTR.

           IF  WS-KEYS       IS NOT EQUAL TO "*YES"
              GO TO PRT-ATR.

           MOVE "Y"                       TO  WS-FIRST-SW.

           MOVE FILN OF DTL1-RECD    TO  FILN    OF ANZFLDR.
           MOVE LIBN OF DTL1-RECD    TO  LIBN    OF ANZFLDR.
           MOVE ZEROES               TO  FLDSEQ  OF ANZFLDR.

           START FLD-FILE
               KEY IS NOT LESS THAN EXTERNALLY-DESCRIBED-KEY
                  INVALID KEY
                     GO TO PRT-ATR.

       PRT-001.
           READ FLD-FILE NEXT
             AT END
                GO TO PRT-ATR.

           IF  FILN OF DTL1-RECD IS NOT EQUAL TO FILN OF ANZFLDR
           OR  LIBN OF DTL1-RECD IS NOT EQUAL TO LIBN OF ANZFLDR
               GO TO PRT-ATR.

           IF  WS-FIRST-SW    IS EQUAL TO  "Y"
               MOVE "N"                TO  WS-FIRST-SW
               MOVE "Key Fields:"      TO  DESC OF DTL2-RECD.

           MOVE CORRESPONDING ANZFLDR     TO  DTL2-RECD.

           IF  LINE-CTR    IS GREATER THAN 55
               WRITE PRT-REC FORMAT IS "HEADER1"
               WRITE PRT-REC FORMAT IS "HEADER2"
               MOVE CORRESPONDING DTL1-RECD TO DETAIL1-O
               WRITE PRT-REC FORMAT IS "DETAIL1"
               MOVE 7                TO LINE-CTR.

           MOVE CORRESPONDING DTL2-RECD  TO DETAIL2-O.

           WRITE PRT-REC FORMAT IS "DETAIL2".
           ADD 1                         TO  LINE-CTR.
           MOVE SPACES                   TO  DESC OF DTL2-RECD.
           GO TO PRT-001.

       PRT-EXIT.
           EXIT.
      /
       PRINT-ERROR.
           IF  LINE-CTR    IS GREATER THAN 55
               WRITE PRT-REC FORMAT IS "HEADER1"
               WRITE PRT-REC FORMAT IS "HEADER2"
               MOVE 6                TO LINE-CTR.

           MOVE CORRESPONDING ERR1-RECD  TO ERR1-O.
           WRITE PRT-REC FORMAT IS "ERR1".
       PRE-EXIT.
           EXIT.
      /
       PRINT-ERROR2.
           IF  LINE-CTR    IS GREATER THAN 55
               WRITE PRT-REC FORMAT IS "HEADER1"
               WRITE PRT-REC FORMAT IS "HEADER2"
               MOVE 6                TO LINE-CTR.

           MOVE CORRESPONDING ERR2-RECD  TO ERR2-O.
           WRITE PRT-REC FORMAT IS "ERR2".
       PR2-EXIT.
           EXIT.
      /
      **************************************************************
      * INITIAL LOGIC routine                                      *
      *                                                            *
      **************************************************************
       INITIAL-LOGIC.


           OPEN INPUT FLD-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "ANZFLDL3"        TO  ERRFIL OF ERR1-RECD
              MOVE WS-FILE-STATUS    TO  ERRSTS OF ERR1-RECD
              PERFORM PRINT-ERROR THRU PRE-EXIT
              PERFORM END-OF-JOB.

           OPEN INPUT ATR-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "ANZFILL2"       TO  ERRFIL OF ERR1-RECD
              MOVE WS-FILE-STATUS    TO  ERRSTS OF ERR1-RECD
              PERFORM PRINT-ERROR THRU PRE-EXIT
              PERFORM END-OF-JOB.

           OPEN OUTPUT PRT-FILE.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              PERFORM END-OF-JOB.

           MOVE WS-LIB               TO  PFLIB   OF ANZFILR.
           MOVE LOW-VALUES           TO  PFFIL   OF ANZFILR.
           MOVE ZEROES               TO  FILSEQ  OF ANZFILR.

           START ATR-FILE
               KEY IS NOT LESS THAN EXTERNALLY-DESCRIBED-KEY
                  INVALID KEY
              MOVE "Entries for Library do not exist" TO ERRDESC
                  OF ERR2-RECD
              PERFORM PRINT-ERROR2 THRU PR2-EXIT
              PERFORM END-OF-JOB.
      /
      **************************************************************
      * END OF JOB routine.                                        *
      *                                                            *
      * The following code handles the end of job processing       *
      **************************************************************
       END-OF-JOB.

           CLOSE FLD-FILE.
           CLOSE ATR-FILE.
           CLOSE PRT-FILE.
