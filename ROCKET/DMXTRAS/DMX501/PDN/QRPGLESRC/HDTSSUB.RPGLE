      * ============================================================ *
      * Object:    HDTSSUB         *PGM RPG                          *
      *            Additional program to subtract a number of hours  *
      *            from a date-time stamp. This is used in the       *
      *            sample program XDLTRCVTSB.                        *
      *                                                              *
      * Synopsis:  Parameters passed to this program are:            *
      *            I/O: Date-time stamp    (26)                      *
      *            I  : Number of hours    (3 0)                     *
      *                                                              *
      * ------------------------------------------------------------ *
      *             Changes made to this source                      *
      *             ---------------------------                      *
      *                                                              *
      * Date     Who Description                                     *
      * -------- --- ----------------------------------------------- *
      * 20030717 FK  Initial delivery                                *
      * ============================================================ *
      * ------------------------------------------------------------- *
      * Data structures                                               *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Constants                                                     *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Arrays and tables                                             *
      * ------------------------------------------------------------- *
      * ------------------------------------------------------------- *
      * Other variables                                               *
      * ------------------------------------------------------------- *
     D DTSWY           S               Z                                        * Date-time stamp
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
     C                   Parm                    DTSPA            26            * Date-time stamp
     C                   Parm                    NBRHPA            3 0          * Number of hours
      * ------------------------------------------------------------- *
      * Main line                                                     *
      * ------------------------------------------------------------- *
      * Initialisation
     C                   Clear                   DTSWY                          * Initialise dts
      * Check for validity of passed date
     C                   Test(Z)                 DTSPA                  91      * Check date
     C     *In91         IfEQ      *Off
     C                   Move      DTSPA         DTSWY                          * Date-time stamp
     C                   SubDur    NBRHPA:*Hours DTSWY                          * Subtract # of hrs
     C                   EndIf
      * Return calculated date
     C                   Move      DTSWY         DTSPA                          * Date-time stamp
     C                   Return

      * ------------------------------------------------------------------- *
      * *InzSR - Initialisation subroutine                                  *
      * ------------------------------------------------------------------- *
     C     *InzSR        BegSR
     C                   EndSR

      * ------------------------------------------------------------------- *
      * Compile-time tables                                                 *
      * ------------------------------------------------------------------- *
