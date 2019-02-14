/* ----------------------------------------------------------------------------------------------------------------------------- */
/*                                                                                                                               */
/* this display the activity of the database like top activity in grid                                                           */
/* it use v$active_session_history                                                                                               */
set lines 2048
set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable nbhours  number
COLUMN 1 NEW_VALUE 1
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;
begin
	:nbhours :=nvl('&&1','1');
end;
/
col nbcpu noprint new_value nbcpu
select value nbcpu from v$parameter where name  ='cpu_count';

set term on




col active_session for a80 trunc hea "active_session (cpu count = &&nbcpu)"
--col active_session for a120 trunc 
col nbsess for 9999D99
set term off
alter session set NLS_TIMESTAMP_tz_FORMAT='dd/mm/yy hh24:mi:ss';
alter session set NLS_DATE_FORMAT='dd/mm/yy hh24:mi:ss';
set term on



select heure h,
regexp_replace(
       case 
            when avg(nbparMin)< 1 then '-'||rpad(' ',80)
            when avg(nbparMin) <= 100 then rpad('*',avg(nbparMin),'*') || rpad(' ',80-avg(nbparmin)) 
            else rpad(' ',avg(nbparMin)-1,'*')||'>' 
       end  ,'(.{'||min(p.value-1)||'})(.)(.*)','\1|\3' ) active_session ,
avg(nbparmin) nbsess
from (
  select  t.*,
         sum( nb)  over ( partition by heure) nbparHeure,
         round(sum( nb)  over ( partition by heure)/1/60,2) nbparMin,
         round(nb/ sum( nb)  over ( partition by heure)*100) pct_Activity,
         RANK () over (partition by heure order by nb desc) rank
        from
        (
            select
              trunc(sample_time, 'mi')  heure,
              nvl(WAIT_CLASS,'Cpu + CpuWait') as WAIT_CLASS,
              count(*) as nb
              ,round(count(*)/1/60,2) nb_ps
            from v$active_session_history
            where
               trunc(sample_time, 'mi')between sysdate-:nbhours/24 and trunc(sysdate,'mi')-1/24/60
            group by trunc(sample_time, 'mi') , nvl(WAIT_CLASS,'Cpu + CpuWait')
            order by trunc(sample_time, 'mi') , count(1) desc
        ) t
        order by heure desc, rank          ),
        (select value from v$parameter where name  ='cpu_count') p
group by heure 
order by heure;
undefine active_session
undefine nbsess

