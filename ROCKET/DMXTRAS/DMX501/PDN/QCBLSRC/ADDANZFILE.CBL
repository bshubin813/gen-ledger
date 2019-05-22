       IDENTIFICATION DIVISION.
       PROGRAM-ID.   ADDANZFILE.
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

           SELECT ATTR-FILE
               ASSIGN       TO DATABASE-ANZFILL1
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

       FD  ATTR-FILE
           LABEL RECORDS ARE OMITTED.
       01  ATTR-REC.
           COPY DDS-ALL-FORMATS OF ANZFILL1.
      /
      ****************************************************************
      * W O R K I N G   S T O R A G E   S E C T I O N                *
      ****************************************************************
       WORKING-STORAGE SECTION.
      *
       01 ATTR-UPD-SW                  PIC X(1).
          88 ATTR-UPD-OK               VALUE "Y".
          88 ATTR-UPD-NOT-OK           VALUE "N".

       01  WS-ATTR-REC.
           COPY DDS-ALL-FORMATS OF ANZFILL1.
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
           05 WS-FILE-SEQ                PIC S9(4)  VALUE 1.
      /
       LINKAGE SECTION.
       01  WS-FILE                       PIC X(10).
       01  WS-LIB                        PIC X(10).
       01  WS-ATR                        PIC X(6).
       01  WS-MBRS                       PIC X(1).
       01  WS-JRN                        PIC X(1).
       01  WS-JRNNME                     PIC X(10).
       01  WS-JRNLIB                     PIC X(10).
       01  WS-JRNIM                      PIC X(1).
       01  WS-SEQ                        PIC S9(4) COMP-3.
       01  WS-UNIQUE                     PIC X(1).
       01  WS-RECORDS                    PIC S9(10) COMP-3.
       01  WS-JOIN                       PIC X(1).
       01  WS-PF-FILE                    PIC X(10).
       01  WS-PF-LIB                     PIC X(10).
       01  WS-REUSE                      PIC X(1).
       01  WS-RECLEN                     PIC S9(5) COMP-3.
       01  WS-KEYYES                     PIC X(1).
      /
      ****************************************************************
      *   P R O C E D U R E   D I V I S I O N
      ****************************************************************
       PROCEDURE DIVISION      USING WS-FILE
                                     WS-LIB
                                     WS-ATR
                                     WS-MBRS
                                     WS-JRN
                                     WS-JRNNME
                                     WS-JRNLIB
                                     WS-JRNIM
                                     WS-SEQ
                                     WS-UNIQUE
                                     WS-RECORDS
                                     WS-JOIN
                                     WS-PF-FILE
                                     WS-PF-LIB
                                     WS-REUSE
                                     WS-RECLEN
                                     WS-KEYYES.
       MAINLINE.
      *
           PERFORM INITIAL-LOGIC.

           PERFORM UPDATE-RECORD THRU UR-EXIT.

           PERFORM END-OF-JOB.
      /
       UPDATE-RECORD.

           MOVE WS-FILE                   TO  FILN OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-PF-FILE                TO  PFFIL OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-LIB                    TO  LIBN OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-PF-LIB                 TO  PFLIB OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-ATR                    TO  FILA OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-MBRS                   TO  MBRS OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-JRN                    TO  JRN OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-JRNNME                 TO  JRNN OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-JRNLIB                 TO  JRNL OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-JRNIM                  TO  JRNI OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-RECORDS                TO  RECS OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-JOIN                   TO  JOINF OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-REUSE                  TO  REUSE OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-RECLEN                 TO  RECLEN OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-KEYYES                 TO  KEYYES OF ANZFILR
                                              OF WS-ATTR-REC.
           IF  WS-UNIQUE     IS NOT EQUAL TO  "Y"
               MOVE "N"                   TO  WS-UNIQUE.
           MOVE WS-UNIQUE                 TO  UNIQ OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-SEQ                    TO  FILSEQ OF ANZFILR
                                              OF WS-ATTR-REC.
           MOVE WS-ATTR-REC          TO  ATTR-REC.

           WRITE ATTR-REC.
           IF WS-FILE-STATUS IS NOT EQUAL TO "00"
              MOVE "DMA0010"    TO  WS-MSGID
              MOVE "ANZFILL1"   TO  WS-MSGDTA
              MOVE 10           TO  WS-MSGDTALEN
              PERFORM SND-MSG-RTN THRU SMR-EXIT
              GO TO UR-EXIT.

       UR-EXIT.
           EXIT.
      /
      **************************************************************
      * INITIAL LOGIC routine                                      *
      *                                                            *
      * This routine opens the Journal ID and Journal Status files.*
      **************************************************************
       INITIAL-LOGIC.

              OPEN I-O   ATTR-FILE.
              IF WS-FILE-STATUS IS NOT EQUAL TO "00"
                 MOVE "ANZFILL1"        TO  WS-MSGDTA
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

           CLOSE ATTR-FILE.
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
