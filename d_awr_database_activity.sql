/* ----------------------------------------------------------------------------------------------------------------------------- */
/*                                                                                                                               */
/* this script list the activ */
set lines 2048
set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable nbdays  number
COLUMN 1 NEW_VALUE 1
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;
begin
	:nbdays :=nvl('&&1','1');
end;
/
set term on

	
WITH 
p AS (
SELECT 
       sysdate - :nbdays                                        /* start date                 */   bsnap ,
       sysdate                                            /* end date                   */   esnap ,
       1                                                  /* number of snap_id to group */   step
--  to_date('07/06/08 08:00:00','dd/mm/yy hh24:mi:ss')-0  /* start date                 */   bsnap ,
--  to_date('07/07/08 19:00:00','dd/mm/yy hh24:mi:ss')-0  /* end date                   */   esnap ,
FROM dual
 ),
 s AS (
SELECT d.NAME DATABASE,
       b.dbid,
       b.instance_number,
       b.snap_id bsnap_id,
       e.snap_id esnap_id,
       e.begin_INTERVAL_TIME bBEGIN_INTERVAL_TIME,
       e.end_INTERVAL_TIME eend_INTERVAL_TIME,
       bs.stat_name NAME,
       ROUND((es.VALUE - bs.VALUE)
       -- / (to_date(to_char(e.BEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS')- to_date(to_char(b.BEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS')) / 24, 3
       ) valuepersecond
FROM   v$database d,
       p,
       DBA_HIST_SNAPSHOT b,          
       DBA_HIST_SNAPSHOT e,
       DBA_HIST_SYSSTAT bs,
       DBA_HIST_SYSSTAT es
WHERE  (b.end_INTERVAL_TIME BETWEEN p.bsnap AND p.esnap AND MOD(b.snap_id, step) = 0 AND d.dbid = b.dbid)
       AND (b.snap_id = e.snap_id - 1 AND b.dbid = e.dbid AND b.instance_number = e.instance_number)
       AND (b.snap_id = bs.snap_id AND b.dbid = bs.dbid AND b.instance_number = bs.instance_number)
       AND (e.snap_id = es.snap_id AND e.dbid = es.dbid AND e.instance_number = es.instance_number)
       AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
       AND bs.stat_name IN ('redo size', 'redo blocks written', 'session logical reads', 'db block changes', 'physical reads',
        'physical writes', 'user calls', 'parse count (total)', 'parse count (hard)', 'sorts (memory)',
        'sorts (disk)', 'logons cumulative', 'execute count', 'user rollbacks', 'user commits',
        'recursive calls', 'sorts (rows)', 'CPU used by this session', 'db block gets', 'consistent gets','physical writes direct temporary tablespace',
         'Queries parallelized Per Sec','DML statements parallelized Per Sec', 'DDL statements parallelized Per Sec')
union 
SELECT d.NAME DATABASE,
       b.dbid,
       b.instance_number,
       b.snap_id bsnap_id,
       e.snap_id esnap_id,
       e.begin_INTERVAL_TIME bBEGIN_INTERVAL_TIME,
       e.end_INTERVAL_TIME eend_INTERVAL_TIME,
       bs.stat_name NAME,
       ROUND((es.VALUE - bs.VALUE)
       -- / (to_date(to_char(e.BEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS')- to_date(to_char(b.BEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS')) / 24, 3
       ) valuepersecond
FROM   v$database d,
       p,
       DBA_HIST_SNAPSHOT b,          
       DBA_HIST_SNAPSHOT e,
       DBA_HIST_SYS_TIME_MODEL bs,
       DBA_HIST_SYS_TIME_MODEL es
WHERE  (b.end_INTERVAL_TIME BETWEEN p.bsnap AND p.esnap AND MOD(b.snap_id, step) = 0 AND d.dbid = b.dbid)
       AND (b.snap_id = e.snap_id - 1 AND b.dbid = e.dbid AND b.instance_number = e.instance_number)
       AND (b.snap_id = bs.snap_id AND b.dbid = bs.dbid AND b.instance_number = bs.instance_number)
       AND (e.snap_id = es.snap_id AND e.dbid = es.dbid AND e.instance_number = es.instance_number)
       AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
       AND bs.stat_name in ('DB CPU', 'DB time','sql execute elapsed time','RMAN cpu time (backup/restore)') 
 ),
g AS ( 
 SELECT /*+ FIRST_ROWS */ 
 DATABASE,
 bsnap_id,
 esnap_id,
 to_date(to_char(bBEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS') BEGIN_INTERVAL_TIME,
 to_date(to_char(eend_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS') end_INTERVAL_TIME,
  SUM(DECODE( name , 'redo size'     , valuepersecond , 0 ))  redo_size,
  SUM(DECODE( name ,  'session logical reads'    , valuepersecond , 0 ))  logical_reads,
  SUM(DECODE( name ,  'db block changes'    , valuepersecond , 0 ))  block_changes,
  SUM(DECODE( name ,  'physical reads'    , valuepersecond , 0 )) physical_reads ,
  SUM(DECODE( name ,  'physical writes'    , valuepersecond , 0 ))  physical_writes,
  SUM(DECODE( name ,  'physical writes direct temporary tablespace'    , valuepersecond , 0 )) physical_write_temp ,
  SUM(DECODE( name , 'redo blocks written'     , valuepersecond , 0 ))  redo_blocks,
  SUM(DECODE( name ,  'user calls'    , valuepersecond , 0 ))  user_calls,
  SUM(DECODE( name ,  'recursive calls'    , valuepersecond , 0 ))  recursive_calls,
  SUM(DECODE( name ,  'parse count (total)'    , valuepersecond , 0 )) parses ,
  SUM(DECODE( name ,  'parse count (hard)'    , valuepersecond , 0 )) hard_parses ,
  SUM(DECODE( name ,  'sorts (rows)'    , valuepersecond , 0 )) sort_rows ,
  SUM(DECODE( name ,  'sorts (memory)',valuepersecond,'sorts (disk)'  , valuepersecond , 0 ))sorts  ,
  SUM(DECODE( name ,  'logons cumulative'    , valuepersecond , 0 )) logons ,
  SUM(DECODE( name ,  'execute count'    , valuepersecond , 0 )) executes ,
  SUM(DECODE( name ,  'user rollbacks' , valuepersecond,'user commits' , valuepersecond , 0 )) transactions,
  SUM(DECODE( name ,  'user rollbacks'    , valuepersecond , 0 )) rollbacks,
  SUM(DECODE( name ,  'CPU used by this session'    , valuepersecond/10000 , 0 )) cpusecs      ,
   SUM(DECODE( name ,  'db block gets'    , valuepersecond , 0 )) bloget      ,
   SUM(DECODE( name ,  'consistent gets'    , valuepersecond , 0 )) consget      ,
   SUM(DECODE( name ,  'Queries parallelized Per Sec'    , valuepersecond , 0 )) queryparal,
   SUM(DECODE( name ,  'DML statements parallelized Per Sec'    , valuepersecond , 0 )) dmlparal,
   SUM(DECODE( name ,  'DDL statements parallelized Per Sec'    , valuepersecond , 0 )) ddlparal,
   sum(DECODE( name ,  'DB time'    , valuepersecond , 0 )) DB_time,
   sum(DECODE( name ,  'DB CPU'    , valuepersecond , 0 )) DB_CPU,
   sum(DECODE( name ,  'sql execute elapsed time'    , valuepersecond , 0 )) sql_execute_elapsed_time,
   sum(DECODE( name ,  'RMAN cpu time (backup/restore)'    , valuepersecond , 0 )) RMAN_cpu_time_backup_restore
 FROM s
 GROUP BY DATABASE,bsnap_id,esnap_id,to_date(to_char(bBEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS') ,to_date(to_char(eend_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS') 
 ) 
 SELECT to_char(begin_interval_time, 'HH24') snap_timehh24,
 bsnap_id,
        esnap_id,
        BEGIN_INTERVAL_TIME    begin_snap_time,
        end_INTERVAL_TIME      end_snap_time,
        to_char(DB_time/60/1000000 ,'9G999G999G999D90') DB_time_min ,
        to_char(DB_CPU/1000000 ,'9G999G999G999D90') DB_CPU_sec ,  
        TO_CHAR((100*(cpusecs)),'999g999D90')cpu,
        to_char(sql_execute_elapsed_time/1000000 ,'9G999G999G999D90') sql_execute_elapsed_time   ,
        to_char(RMAN_cpu_time_backup_restore/1000000 ,'9G999G999G999D90') RMAN_cpu_time_backup_restore   ,
        to_char(logical_reads,'9G999G999G999D90') logical_reads ,
        to_char(bloget,'999G999G999D90') bloget, 
        to_char(consget,'9G999G999G999D90') consget,
        to_char(physical_reads,'999G999G999D90') physical_reads,
        to_char(redo_blocks,'999G999G999D90') redo_blocks,
        to_char(block_changes,'999G999G999D90') block_changes,
        to_char(physical_writes,'999G999G999D90') physical_writes,
        to_char(physical_write_temp,'999G999G999D90') physical_write_temp,
        to_char(user_calls,'999G999G999D90') user_calls,
        to_char(executes,'999G999G999D90') executes,
        to_char(parses,'999G999G999D90') parses,
        to_char(hard_parses,'999G999G999D90') hard_parses,
        to_char(sorts,'999G999G999D90') sorts,
        to_char(queryparal,'999D90') queryparal,
        to_char(dmlparal,'999D90') dmlparal,
        to_char(ddlparal,'999D90') ddlparal,
        to_char(logons,'999G999G999D90') logons,
        to_char(transactions,'999G999G999D90') transactions, 
         TO_CHAR((100*(block_changes/logical_reads)),'909D90')||'%' changes_per_read, 
         TO_CHAR((100*(recursive_calls/(user_calls+recursive_calls))),'909D90')||'%' recursive, 
        TO_CHAR((100*(rollbacks/transactions)),'909D90')||'%' ROLLBACK, 
        TO_CHAR(DECODE(sorts,0,NULL,(sort_rows/sorts)),'999999') rows_per_sort,
        TO_CHAR((100*(1- physical_reads/logical_reads)),'909D90')||'%' buffer_hit 
FROM g
order by dATABASE, begin_snap_time, end_snap_time
;

	   
	   
	   
undef nbdays

clear col
undef 1 2 3 4 5 6 7 8 9