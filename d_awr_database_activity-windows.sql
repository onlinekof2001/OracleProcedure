--alter session set nls_date_format='DD/MM/YY HH24:MI:SS'
WITH 
p AS (
SELECT 
     sysdate - &nbjours                                        /* start date                 */   bsnap ,
     sysdate                                            /* end date                   */   esnap ,
  -- to_date('08/06/08 00:00:00','dd/mm/yy hh24:mi:ss')-0   /* start date                 */   bsnap ,
  -- to_date('08/06/08 23:59:00','dd/mm/yy hh24:mi:ss')-0   /* end date                   */   esnap,
  1                    /* number of snap_id to group */   step 
FROM dual
 ),
 s AS (
SELECT d.NAME DATABASE,
       b.dbid,
       b.instance_number,
       b.snap_id bsnap_id,
       e.snap_id esnap_id,
       b.BEGIN_INTERVAL_TIME bBEGIN_INTERVAL_TIME,
       e.BEGIN_INTERVAL_TIME eBEGIN_INTERVAL_TIME,
        case 
             when  to_number(to_char(b.begin_interval_time, 'HH24'))*60+to_number(to_char(b.begin_interval_time, 'Mi')) between 400 and 1100 then 'day'
             when  to_number(to_char(b.begin_interval_time, 'HH24'))*60+to_number(to_char(b.begin_interval_time, 'Mi'))between 1140 and 1320 then 'mixte'
             when  to_number(to_char(b.begin_interval_time, 'HH24'))*60+to_number(to_char(b.begin_interval_time, 'Mi')) > 1320 then 'night'
            when  to_number(to_char(b.begin_interval_time, 'HH24'))*60+to_number(to_char(b.begin_interval_time, 'Mi')) <480 then 'night'
  end periode,
       bs.stat_name NAME,
       es.VALUE - bs.VALUE valuepersecond
FROM   v$database d,
       p,
       DBA_HIST_SNAPSHOT b,
       DBA_HIST_SNAPSHOT e,
       DBA_HIST_SYSSTAT bs,
       DBA_HIST_SYSSTAT es
WHERE  (b.BEGIN_INTERVAL_TIME BETWEEN p.bsnap AND p.esnap AND MOD(b.snap_id,step) = 0 AND d.dbid = b.dbid)
       AND (b.snap_id = e.snap_id - 1 AND b.dbid = e.dbid AND b.instance_number = e.instance_number)
       AND (b.snap_id = bs.snap_id AND b.dbid = bs.dbid AND b.instance_number = bs.instance_number)
       AND (e.snap_id = es.snap_id AND e.dbid = es.dbid AND e.instance_number = es.instance_number)
       AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
       AND bs.stat_name IN ('redo size', 'redo blocks written', 'session logical reads', 'db block changes', 'physical reads',
        'physical writes', 'user calls', 'parse count (total)', 'parse count (hard)', 'sorts (memory)',
        'sorts (disk)', 'logons cumulative', 'execute count', 'user rollbacks', 'user commits',
        'recursive calls', 'sorts (rows)', 'CPU used by this session', 'db block gets', 'consistent gets','sql execute elapsed time')
 ),
g AS ( 
 SELECT /*+ FIRST_ROWS */ 
 DATABASE,
--  bsnap_id,
  min(to_date(to_char(bBEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS')) min_BEGIN_INTERVAL_TIME,
  max(to_date(to_char(bBEGIN_INTERVAL_TIME ,'DD/MM/YY HH24:MI:SS'),'DD/MM/YY HH24:MI:SS')) max_BEGIN_INTERVAL_TIME,
  min(bsnap_id) minbsnapid,
  max(bsnap_id) maxbsnapid,
  periode,
  SUM(DECODE( name , 'redo size' 	  , valuepersecond , 0 ))  redo_size,
  SUM(DECODE( name , 'redo blocks written' 	  , valuepersecond , 0 ))  redo_blocks,
  SUM(DECODE( name ,  'session logical reads'	  , valuepersecond , 0 ))  logical_reads,
  SUM(DECODE( name ,  'db block changes'	  , valuepersecond , 0 ))  block_changes,
  SUM(DECODE( name ,  'physical reads'	  , valuepersecond , 0 )) physical_reads ,
  SUM(DECODE( name ,  'physical writes'	  , valuepersecond , 0 ))  physical_writes,
  SUM(DECODE( name ,  'user calls'	  , valuepersecond , 0 ))  user_calls,
   SUM(DECODE( name ,  'recursive calls'	  , valuepersecond , 0 ))  recursive_calls,
  SUM(DECODE( name ,  'parse count (total)'	  , valuepersecond , 0 )) parses ,
  SUM(DECODE( name ,  'parse count (hard)'	  , valuepersecond , 0 )) hard_parses ,
  SUM(DECODE( name ,  'sorts (rows)'	  , valuepersecond , 0 )) sort_rows ,
  SUM(DECODE( name ,  'sorts (memory)',valuepersecond,'sorts (disk)'  , valuepersecond , 0 ))sorts  ,
  SUM(DECODE( name ,  'logons cumulative'	  , valuepersecond , 0 )) logons ,
  SUM(DECODE( name ,  'execute count'	  , valuepersecond , 0 )) executes ,
  SUM(DECODE( name ,  'user rollbacks' , valuepersecond,'user commits' , valuepersecond , 0 )) transactions,
  SUM(DECODE( name ,  'user rollbacks'	  , valuepersecond , 0 )) rollbacks,
  SUM(DECODE( name ,  'CPU used by this session'	  , valuepersecond/100000 , 0 )) cpusecs      ,
   SUM(DECODE( name ,  'db block gets'	  , valuepersecond , 0 )) bloget      ,
   SUM(DECODE( name ,  'consistent gets'	  , valuepersecond , 0 )) consget, 
   sum(decode(name, 'sql execute elapsed time' , valuepersecond,0)) elapse     
 FROM s
 GROUP BY DATABASE,periode
 ) 
 SELECT 
--        bsnap_id,
--        BEGIN_INTERVAL_TIME    snap_time,
--        to_char(begin_interval_time, 'HH24:MI') heure,
        min_BEGIN_INTERVAL_TIME,
        max_BEGIN_INTERVAL_TIME,
        minbsnapid,
        maxbsnapid,
        periode ,
        elapse,
        to_char(executes,'999G999G999D90') executes,
        to_char(logical_reads,'9G999G999G999D90') logical_reads ,
        to_char(((cpusecs)),'999g999D90') cpu, 		
        0 TestElpaseTotal,
        0 ActiveSession,
        to_char(physical_reads,'999G999G999D90') physical_reads,
        to_char(user_calls,'999G999G999D90') user_calls,
        to_char(bloget,'999G999G999D90') bloget, 
        to_char(consget,'9G999G999G999D90') consget,
        to_char(redo_blocks,'999G999G999D90') redo_blocks,
        to_char(block_changes,'999G999G999D90') block_changes,
        to_char(physical_writes,'999G999G999D90') physical_writes,
        to_char(parses,'999G999G999D90') parses,
        to_char(hard_parses,'999G999G999D90') hard_parses,
        to_char(sorts,'999G999G999D90') sorts,
        to_char(logons,'999G999G999D90') logons,
        to_char(transactions,'999G999G999D90') transactions, 
     		to_char((100*(block_changes/logical_reads)),'909D90')||'%' changes_per_read, 
     		to_char((100*(recursive_calls/(user_calls+recursive_calls))),'909D90')||'%' recursive, 
    		to_char((100*(rollbacks/transactions)),'909D90')||'%' ROLLBACK, 
    		to_char(DECODE(sorts,0,NULL,(sort_rows/sorts)),'999999') rows_per_sort,
     		to_char((100*(1- physical_reads/logical_reads)),'909D90')||'%' buffer_hit 
FROM g
order by periode;



clear col
undef 1 2 3 4 5 6 7 8 9
