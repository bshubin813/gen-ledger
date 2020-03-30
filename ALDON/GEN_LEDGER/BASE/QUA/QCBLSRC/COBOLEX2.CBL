       IDENTIFICATION DIVISION.
       PROGRAM-ID.  MULTIPLIER.
       AUTHOR.  MICHAEL COUGHLAN.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  NUM1                                PIC 9  VALUE ZEROS.
       01  NUM2                                PIC 9  VALUE ZEROS.
       01  RESULT                              PIC 99 VALUE ZEROS.
       PROCEDURE DIVISION.
           DISPLAY "ENTER FIRST NUMBER (1 DIGIT)"
           ACCEPT NUM1
           DISPLAY "ENTER SECOND NUMBER (1 DIGIT)"
           ACCEPT NUM2
           MULTIPLY NUM1 BY NUM2 GIVING RESULT.
           DISPLAY "RESULT IS = ", RESULT.
           STOP RUN.
