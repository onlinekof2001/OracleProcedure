set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable nbd  number
COLUMN 1 NEW_VALUE 1
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;

begin
	:nbd :=nvl('&&1','5');
end;
/
set term on
set heading on
column "00:xx" format 9999
column "01:xx" format 9999
column "02:xx" format 9999
column "03:xx" format 9999
column "04:xx" format 9999
column "05:xx" format 9999
column "06:xx" format 9999
column "07:xx" format 9999
column "08:xx" format 9999
column "09:xx" format 9999
column "10:xx" format 9999
column "11:xx" format 9999
column "12:xx" format 9999
column "13:xx" format 9999
column "14:xx" format 9999
column "15:xx" format 9999
column "16:xx" format 9999
column "17:xx" format 9999
column "18:xx" format 9999
column "19:xx" format 9999
column "20:xx" format 9999
column "21:xx" format 9999
column "22:xx" format 9999
column "23:xx" format 9999
	SELECT * FROM 
	(
		SELECT trunc(FIRST_TIME,'ddd') FIRST_TIME
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '00', 1, 0), '99')) "00:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '01', 1, 0), '99')) "01:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '02', 1, 0), '99')) "02:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '03', 1, 0), '99')) "03:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '04', 1, 0), '99')) "04:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '05', 1, 0), '99')) "05:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '06', 1, 0), '99')) "06:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '07', 1, 0), '99')) "07:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '08', 1, 0), '99')) "08:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '09', 1, 0), '99')) "09:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '10', 1, 0), '99')) "10:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '11', 1, 0), '99')) "11:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '12', 1, 0), '99')) "12:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '13', 1, 0), '99')) "13:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '14', 1, 0), '99')) "14:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '15', 1, 0), '99')) "15:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '16', 1, 0), '99')) "16:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '17', 1, 0), '99')) "17:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '18', 1, 0), '99')) "18:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '19', 1, 0), '99')) "19:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '20', 1, 0), '99')) "20:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '21', 1, 0), '99')) "21:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '22', 1, 0), '99')) "22:xx"
		, SUM(TO_NUMBER(DECODE(TO_CHAR(FIRST_TIME, 'HH24'), '23', 1, 0), '99')) "23:xx"
			FROM V$LOG_HISTORY
			   WHERE trunc(first_time,'ddd')>=trunc(sysdate,'ddd')-:nbd
				  GROUP BY trunc(FIRST_TIME,'ddd')
	) 
	  ORDER BY FIRST_TIME ;
  


undef nbd 1
clear col
clear break

clear col
undef 1 2 3 4 5 6 7 8 9