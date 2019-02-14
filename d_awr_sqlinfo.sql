set define on
define numdays = 7
set feed off
set verify off
set head on
set lines 1024 
set long 200000
set longc 200000
alter session set NLS_TIMESTAMP_FORMAT='dd/mm/yy hh24:mi:ss';
alter session set NLS_DATE_FORMAT='dd/mm/yy hh24:mi:ss';
col plan_hash_value for 99999999999 jus r
col begin_interval_time for A15
col end_interval_time for A15
col cpu_time_sec for 99,999.99
col elapsed_time_sec for 999,999.99
col elapsed_time for 999,999,999.99
col SQL_TEXT for A50 WORD_WRAPPED
col SQL_TEXT_T for A200 trunc 
col module for A28 trunc
col opt_mode for A15
col "Reads prX" for 9,999,999.999 
col "EXECS prSnap" for 999,999,999.9 
col "Gets prX" for 999,999,999.99 
col "Sec prX" for 999,999.999 
col "CPUTime prX" for 999,999.99 
col "NUMROWS" for 999,999.9
col "Seconds prX" for 99,999.9999
col cost for 99,999,999.9
col "ms CPUTime prX" for 99,999,999.9
col IOWAIT for 999,999.99
col buffer_gets for 99,999,999,999
col sql_id for a14
col last_used for a15
variable display_level number
col PCT_BUFFER_GETS for 99.99
col PCTREADS for 99.99
col PCT_CPU for 99.99

set colsep "|"
--accept sqlID prompt 'SQLID='
--accept sqlID prompt 'SQLID='


--col p2 noprint new_value p2
--select nvl('&&2',null) p2 from dual;

column sqlId      new_value sqlId
select '&1' sqlid, sysdate from dual;
alter session set NLS_TIMESTAMP_FORMAT='dd/mm/yy hh24:mi';
alter session set NLS_DATE_FORMAT='dd/mm/yy hh24:mi';
---- to avoid prompt for variable is parameter is not pass to script.
COLUMN 2 NEW_VALUE 2
SELECT 0 "2" FROM DUAL WHERE ROWNUM = 0;

begin
	:display_level :=nvl('&&2',0);
end;
/

set lines 200
col SQL_TEXT for A200 WORD_WRAPPED;
--select sql_id,to_char(SQL_TEXT) SQL_TEXT from  DBA_HIST_SQLTEXT where sql_id = lower('&sqlId') and rownum = 1 	 and  ( :display_level<=0 or :display_level is null );
select sql_id,to_char(dbms_lob.substr(SQL_TEXT, 4000,1)) SQL_TEXT from  DBA_HIST_SQLTEXT where sql_id = lower('&sqlId') and rownum = 1 	 and  ( :display_level<=0 or :display_level is null );
select sql_id,SQL_TEXT SQL_TEXT_T from  DBA_HIST_SQLTEXT where sql_id = lower('&sqlId') and rownum = 1 	 and  ( :display_level>0);
set lines 1024

prompt 
prompt 2 : Evolution du profil d''execution
select trunc(snap.begin_interval_time,'dd'),
				plan_hash_value,
						optimizer_mode "OPT_MODE",
						round(avg(optimizer_cost),1) COST,
						module,
            round(avg(executions_delta) 										,0)	"EXECS prSnap",
			round(sum(executions_delta), 0) sum_execs,
/*            round(avg(fetches_delta/executions_delta) 				,0)	"Fetches prX",
*/            round(avg(sorts_delta/executions_delta) 				,0)	"Sorts prX",
            round(avg(disk_reads_delta/executions_delta) 	,0)	"Reads prX",
            round(avg(buffer_gets_delta/executions_delta) 	,0)	"Gets prX",
            round(avg(rows_processed_delta/executions_delta) 								,0)	NUMROWS,
            round(avg(cpu_time_delta/1000/1000/executions_delta) 		,3)	"CPUTime prX",
            round(avg(elapsed_time_delta/1000/1000/executions_delta) ,3)	"Seconds prX",
            round(avg(iowait_delta/executions_delta) 			,0)	"IOWait prX"
          from dba_hist_sqlstat stat, dba_hist_snapshot snap 
         where stat.snap_id = snap.snap_id
         and sql_id = lower('&sqlId')
		 AND executions_delta > 0 
		 and  ( :display_level<=2 or :display_level is null )
				 --and snap.begin_interval_time > add_months (sysdate,-1)
         group by trunc(snap.begin_interval_time,'dd'),plan_hash_value,optimizer_mode,module
order by 1
/

prompt 
prompt 3 :  &numdays derniers jours : Profil d''execution
select e.begin_interval_time,
       e.end_interval_time,
       es.plan_hash_value,
       /*
       extract (day from e.begin_interval_time) day,
       extract (month from e.begin_interval_time) month,
       extract (year from e.begin_interval_time) year,
       */
       executions_delta EXECS,
			 PARSE_CALLS_DELTA parse,
       /*
                      round(executions_delta/60,2) EXECS_MIN,
                      round(executions_delta/3600,2) EXECS_SEC,
       */
       round((sorts_delta / executions_delta), 0) "SORTS prX",
       round((disk_reads_delta / executions_delta), 0) "Reads prX",
       round((buffer_gets_delta / executions_delta), 0) "GETS prX",
       round((rows_processed_delta / executions_delta), 0) NUMROWS,
       round((cpu_time_delta / executions_delta / 1000), 3) "ms CPUTime prX",
       round((elapsed_time_delta / executions_delta / 1000 /1000), 3) "Seconds prX",
       round((iowait_delta / executions_delta), 0) "IOWait prX"
  from dba_hist_sqlstat es, DBA_HIST_SNAPSHOT e
 where (e.snap_id = es.snap_id AND e.dbid = es.dbid AND
       e.instance_number = es.instance_number)
   AND sql_id = lower('&sqlId')
   AND executions_delta > 0 
   and e.begin_interval_time > (sysdate - &numdays)
   and  ( :display_level<=3 or :display_level is null )
 order by 1 
/



prompt 
prompt 4 : &numdays derniers jours : Consommation globale

select
  s.begin_interval_time,
  s.end_interval_time,
  plan_hash_value,
  sql.executions_delta execs,
  sql.PARSE_CALLS_DELTA parse,
  sql.sorts_delta sorts,
  sql.disk_reads_delta disk_reads,
  sql.buffer_gets_delta buffer_gets,
  sql.apwait_delta apwait,
  sql.ccwait_delta ccwait,
  sql.cpu_time_delta/ 1000000 cpu_time_sec,
  sql.elapsed_time_delta / 1000000 elapsed_time_sec ,
  sql.iowait_delta/ 1000000 iowait,
  nvl(decode(executions_delta,0,0,round(elapsed_time_delta/1000/1000/executions_delta ,3)),0) "Seconds prX"
from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.begin_interval_time > (sysdate - &numdays)
and
   sql_id = lower('&sqlId')
   and  ( :display_level<=4 or :display_level is null )
order by
  s.begin_interval_time
;

prompt 
prompt 5 : Global last month
select plan_hash_value,
						optimizer_mode "OPT_MODE",
						round(avg(optimizer_cost),1) COST,
						module,
            round(avg(executions_delta) 										,2)	"EXECS prSnap",
/*            round(avg(fetches_delta/executions_delta) 				,0)	"Fetches prX",
*/            
			round(avg(sorts_delta/executions_delta) 				,2)	"Sorts prX",
            round(avg(disk_reads_delta/executions_delta) 	,2)	"Reads prX",
            round(avg(buffer_gets_delta/executions_delta) 	,2) "Gets prX",
            round(avg(rows_processed_delta/executions_delta) ,2)	NUMROWS,
            round(avg(decode(executions_delta,0,0,cpu_time_delta/1000/1000/executions_delta)) 		,3) "CPUTime prX",
            round(avg(decode(executions_delta,0,0,elapsed_time_delta/1000/1000/executions_delta)) ,3)	"Seconds prX",
            round(avg(decode(executions_delta,0,0,iowait_delta/executions_delta/ 1000000)) 			,3)	"IOWait prX",
			--round((1 -  round(avg(decode(executions_delta,0,0,disk_reads_delta/executions_delta),2) / ( (round(avg(disk_reads_delta/executions_delta),2)) + round(avg(buffer_gets_delta/executions_delta) 	,2))) *100,2) "Cache Hit Ratio %",
			--round((1 -  round(avg(decode(executions_delta,0,0,disk_reads_delta/executions_delta),2) / ( (round(avg(disk_reads_delta/executions_delta),2)) + round(avg(buffer_gets_delta/executions_delta) 	,2))) *100,2) "Cache Hit Ratio %",
			max(begin_interval_time) last_used,
			SQL_PROFILE
          from dba_hist_sqlstat stat, dba_hist_snapshot snap 
         where stat.snap_id = snap.snap_id
         and sql_id = lower('&sqlId')
			   AND executions_delta > 0 
				 and snap.begin_interval_time > add_months (sysdate,-1)
		 and  ( :display_level<=5 or :display_level is null )
         group by plan_hash_value,optimizer_mode,module,SQL_PROFILE
order by 1
/


prompt 
prompt En cache 
set term off
column col_plan_base_line  NEW_VALUE col_plan_base_line
select case  when substr(VERSION,1,2)<= 10 then '''                              ''' else 'sql_plan_baseline'  end col_plan_base_line from v$instance ;
set term on
clear compute
break on report 
break on report on plan_hash_value  skip 1
compute sum label  'Totals' of EXECS on plan_hash_value
compute sum label  'Totals general ' of EXECS on report


select sql_id,plan_hash_value,CHILD_NUMBER,
          --  optimizer "OPT_MODE",
            optimizer_cost COST,
            executions  "EXECS",
            fetches    "Fetches",
            sorts  "Sorts",
            disk_reads  "Reads",
            buffer_gets "buffer_gets",
            rows_processed NUMROWS,
            cpu_time"CPUTime ",
      elapsed_time/1000/1000 "elapsed_time",
      --round(elapsed_time/1000/1000/executions,4) "SecPerX" ,
	  decode(executions,0,-1,round(elapsed_time/1000/1000/executions,4)) "Seconds prX" ,
      &&col_plan_base_line sql_plan_baseline,
      (select count(1) from v$session sess where sess.SQL_ID='&sqlId' and sess.status='ACTIVE' and sess.SQL_CHILD_NUMBER=gv$sql.CHILD_NUMBER) active,
      (select count(1) from v$active_session_history sessh where sessh.SQL_ID='&sqlId' and sessh.SAMPLE_TIME>sysdate-1/24/60  ) nbactive1min,
      'exec sys.DBMS_SHARED_POOL.PURGE ('''|| address ||',' ||  hash_value || ''',''C'');' flush_sqlid
      /*
            user_io_wait_time  "IOWait"*/
      from gv$sql
         -- from gv$sqlstats stat
     -- inner join gv$sql s on s.sql_id=stat.sql_id
      -- inner join v$sql_plan pln on pln.plan_hash_value=stat.plan_hash_value 
         where sql_id = lower('&sqlId')
         --AND executions > 0 
order by 1,2 ;
clear compute
clear break




col modified for a15 
col created for a15
prompt 
prompt list profile sql
select  name, category, p.status, type, p.force_matching, p.created, p.last_modified modified from dba_sql_profiles p 
where signature=(select DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE (sql_text => s.sql_text) from  DBA_HIST_SQLTEXT  s where sql_id = lower('&sqlId') );

col creator for a10 trunc
col last_executed for a15
col enabled for a5
col fixed for a4
col reprod|uced for a11
col autopurge for a8
col accepte for a7
col executions  for 9,999,999 
col plan_hash_value for a11
col plan_name for a31 
prompt 
prompt list des plan baseline pour &sqlId
select  substr((select * from table(dbms_xplan.DISPLAY_SQL_PLAN_BASELINE(sql_handle, plan_name,'BASIC')) where PLAN_TABLE_OUTPUT like 'Plan hash value%'),17,50) plan_hash_value,
creator, plan_name, origin,last_executed, accepted, enabled, fixed, reproduced, autopurge,  executions ,created, last_modified modified, sql_handle,
case fixed when  'YES' then '@d_spb_fixe ' ||sql_handle || ' ' || plan_name || ' NO'
else '@d_spb_fixe ' ||sql_handle || ' ' || plan_name || 'YES'
END fixe_plan
from dba_sql_plan_baselines b  
where signature=(select DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE (sql_text => s.sql_text) from  DBA_HIST_SQLTEXT  s where sql_id = lower('&sqlId') ) ;

undefine display_level 

prompt Additionals  commands : @d_sqlinfo &sqlId 5     @d_sqlstat &sqlId     @d_kill_sql &sqlId    @d_sqltxt &sqlId     @d_explainplan_awr &sqlId     @d_bind_awr &sqlId     @d_sqlplanmanagment  &sqlId
prompt 
prompt 
set verify on
set feed on

clear col
undef 1 2 3 4 5 6 7 8 9

