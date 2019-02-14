---------------------------------------------------------------------------------------------------
--    Retreive script (SQL_hash_value)                                                              --
---------------------------------------------------------------------------------------------------
--                                                                                        
-- DESCRIPTION OF THE SCRIPT
--   * this script list querys which exist in a first window time and which did not exist in another windows 
--     time
--   * you can use this script to find the new querys after a application upgrade.
--
-- PARAMETERS
--     there is no parameter but you must enter some date :
--        * bnewsnap,   enewsnap   :  
--                first interval, search new  querys in this interval
--        * bexistsnap, eexistsnap :  
--                second interval, remove the querys which already exist in this interval.
--
--
-- UPDATE                       
-- WHAT : short description of the update.                                                           
-- DATE yyyy/mm/dd   WHO : login                                                          
--   Long description of the update.
--
--                                                                                        
-- WHAT : short description of the update.                                                           
-- DATE yyyy/mm/dd   WHO : login                                                          
--   Long description of the update.
---------------------------------------------------------------------------------------------------

alter session set nls_territory=france;
alter session set nls_numeric_characters=", ";



WITH
p AS (
    SELECT
      to_date('14/05/08 08:00','DD/MM/YY HH24:MI')  /* First start date to compare  */        bnewsnap,
      to_date('14/05/08 18:05','DD/MM/YY HH24:MI')  /* first end   date to compare  */        enewsnap,
      to_date('7/05/08 08:00','DD/MM/YY HH24:MI')  /* second start date to compare */        bexistsnap,
      to_date('7/05/08 18:05','DD/MM/YY HH24:MI')  /* second end   date to compare */        eexistsnap
    FROM dual
 )   
    
     select
           es.sql_id                                                                                                       sql_id
         , es.snap_id                                                                                                     end_snap_id
         , to_char(e.begin_interval_time, 'DD/MM/YY HH24:MI:SS')                                                          begin_snap_time
         , to_char(es.executions_delta,'999G999G999')                                                                     execs 
         , to_char(es.buffer_gets_delta,'999G999G999')                                                                    gets
         , to_char(decode(es.executions_delta,0, 0
              , (es.buffer_gets_delta)/ (es.executions_delta)),'999G999G999D9')                                           getspx
         , to_char((es.elapsed_time_delta)/1000000,'999G999G999')                                                         elatsec
         , to_char(decode(es.executions_delta, 0, to_number(null)
               , (es.elapsed_time_delta)/1000)/(es.executions_delta), '999G999G990D9')                                    elapxmsec
         , to_char(es.disk_reads_delta,'999G999G999')                                                                     reads
         , to_char(decode(es.executions_delta,0, to_number(null)
              , (es.disk_reads_delta) / (es.executions_delta)),'999G999G999D9')                                           ReadsPx
         , to_char(es.rows_processed_delta,'999G999G990')                                                                 "rows"
         , to_char(decode(es.executions_delta,0, to_number(null)
              , (es.rows_processed_delta)/ (es.executions_delta)),'999G999G999D9')                                        RowsPx
         , to_char((es.cpu_time_delta)/1000000,'999G999G999')                                                             cputsec
         , to_char(decode(es.executions_delta,0, to_number(null)
               , (es.cpu_time_delta)/1000)/ (es.executions_delta),'999G999G999D9')                                        cputpxmsec
         , to_char(es.sorts_delta,'999G999G990')                                                                          sorts
         , to_char(decode(es.executions_delta, 0, to_number(null)
                                             , es.sorts_delta/ es.executions_delta),'999G999G999')                        sortpx
         , to_char(es.parse_calls_delta,'999G999G990')                                                                    parcall
         , to_char(decode(es.executions_delta ,0, to_number(null)
                                       , es.parse_calls_delta/ es.executions_delta),'999G999G999D9')                    parsepx
         , es.invalidations_delta                                                                                         inval
         , es.version_count                                                                                               vcount
         , to_char(es.sharable_mem/1024,'999G999G999')                                                                  sharememoryKB
      from
            v$database d
         , dba_hist_sqlstat es -- stats$sql_summary es
         , p
         , dba_hist_snapshot e

     where
           (e.begin_interval_time BETWEEN p.bnewsnap AND p.enewsnap AND MOD(e.snap_id,1)=0 AND d.dbid=e.dbid )
       AND (e.snap_id=es.snap_id AND e.dbid=es.dbid AND e.instance_number=es.instance_number)
       and es.sql_id             not in     (SELECT sql_id
                                         FROM   p,
                                                dba_hist_snapshot sns
                                                INNER  JOIN dba_hist_sqlstat sqs ON sns.snap_id = sqs.snap_id 
                                         WHERE  (sns.begin_interval_time BETWEEN p.bexistsnap AND p.eexistsnap)       
                                             )
       and es.executions_delta>0
     order by es.sql_id --e.snap_time;
clear col
undef 1 2 3 4 5 6 7 8 9