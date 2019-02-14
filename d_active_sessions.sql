alter session set nls_timestamp_format='DD/MM/YY HH24:MI:SS';    
set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable nbh  number
COLUMN 1 NEW_VALUE 1
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;

begin
	:nbh :=nvl('&&1','5');
end;
/
set term on

break on heure skip 1
select t2.*
from
(
      select  t.*,
       sum( nb)  over ( partition by heure),
       round(nb/ sum( nb)  over ( partition by heure)*100) pct_Activity,
       RANK () over (partition by heure order by nb desc) rank
      from             
      (
          select to_char(trunc(sample_time, 'hh'),'DD/MM/YY hh24:MI:SS') heure,
          sql_id, 
          count(*) nb
          from v$active_session_history
          where sql_id is not null
          and sample_time  between sysdate-:nbh/24 and sysdate
          group by trunc(sample_time, 'hh'), sql_id
          order by trunc(sample_time, 'hh'), count(1) desc
      ) t
      order by heure, rank
) t2
where rank<=10
order  by heure, rank
;

undef nbh 1
clear col
clear break

clear col
undef 1 2 3 4 5 6 7 8 9