/*******************************************************************/
/*  -----------------------------                                  */
/*  DETERMINE FILE ATTRIBUTES                                      */
/*  -----------------------------                                  */
/*   (C) Copyright Rocket Software, Inc. 1997-2012.                */
/*   All rights reserved.                                          */
/*                                                                 */
/* Change log                                                      */
/*                    ROBERT PHILO May 14th 2002                   */
/*                    Replace use of HASETUP data area to find     */
/*                    product libraries with HRTVPRDLIB            */


             PGM        PARM(&FIL &LIB)

 /*******************************************************************/
 /*  User Defined Program Varaiables                                */
 /*******************************************************************/
             DCL        VAR(&LIB) TYPE(*CHAR) LEN(10)
             DCL        VAR(&FIL) TYPE(*CHAR) LEN(10)
             DCL        VAR(&TOOLSLIB) TYPE(*CHAR) LEN(10)
             HRTVPRDLIB UTILLIB(&TOOLSLIB)

 /*******************************************************************/
 /*  SUBMIT THE JOB                                                 */
 /*******************************************************************/

             SBMJOB     CMD(CALL PGM(&TOOLSLIB/ANZFILESA) PARM(&FIL +
                          &LIB)) JOB(ANZFILES) JOBQ(*JOBD) +
                          CURLIB(&TOOLSLIB) LOGCLPGM(*NO)


 ENDPGM:     ENDPGM

