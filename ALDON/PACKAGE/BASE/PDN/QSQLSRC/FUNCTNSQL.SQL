CREATE FUNCTION &LIB/FUNCTN_SQL
   (I_YMD DECIMAL(7,0))
   RETURNS DATE
   LANGUAGE SQL
   SPECIFIC FUNCTN_SQL
   BEGIN
   DECLARE F_OUTPUT DATE;
   DECLARE F_TEST INTEGER;
-- DECLARE CONTINUE HANDLER FOR SQL EXCEPTION
--   SET F_TEST=1;
     SET F_TEST =0;
     SET F_OUTPUT = DATE(
     SUBSTR(CHAR(19000000 + I_YMD),5,2) ||'/'||
     SUBSTR(CHAR(19000000 + I_YMD),7,2) ||'/'||
     SUBSTR(CHAR(19000000 + I_YMD),1,4)
     );
   IF F_TEST=0 THEN
     RETURN F_OUTPUT;
   ELSE
     RETURN NULL;
   END IF;
   END
