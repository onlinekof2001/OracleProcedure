
--alter session set nls_date_format='DD/MM/YY HsH24:MI:SS'

WITH
p AS (
SELECT
   sysdate-30                                /* start date                 */   bsnap ,
   sysdate-0                                 /* end date                   */   esnap,
   '&1'                                      /* sqlid                      */   sql_id
FROM dual
 )
     select
           es.sql_id,
           e.snap_id                                                                                                      end_snap_id,
           to_char(e.begin_interval_time, 'DD/MM/YY HH24:MI:SS')                                                          end_snap_time,
           to_char(e.end_interval_time, 'DD/MM/YY HH24:MI:SS')                                                            end_snap_time,
           es.plan_hash_value                                                                                             Plan_hashv 
         ,  to_char(es.executions_delta,'999G999G999')                                                                    Execs 
         , decode(es.executions_delta, 0, null,to_char(es.buffer_gets_delta/es.executions_delta,'9g999G999G999D9'))       GetsPx
         , decode(es.executions_delta, 0, null,to_char(es.rows_processed_delta/es.executions_delta,'999G999G999D9'))      RowsPx
         , decode(es.executions_delta, 0, null,to_char(es.disk_reads_delta/es.executions_delta,'999G999G999D9'))          ReadsPx
         , decode(es.executions_delta, 0, null,to_char(es.cpu_time_delta/1000/es.executions_delta,'999G999G999D9') )      Cputpxmsec
         , decode(es.executions_delta, 0, null,to_char(es.elapsed_time_delta/1000/1000/es.executions_delta,'999G999G990D999'))   ElapsPxSsec     
         , to_char(es.rows_processed_delta,'999G999G990')                                                                 "rows"
        , case es.rows_processed_delta  
                when  0 then '0'
                else  to_char(es.buffer_gets_delta/es.rows_processed_delta,'999G999G999D9')                              
           END                                                                                                            GetsProw
        , case es.rows_processed_delta  
                when  0 then '0'
                else  to_char(es.disk_reads_delta/es.rows_processed_delta,'999G999G999D9')                              
           END                                                                                                            ReadsProw
         ,  to_char(es.buffer_gets_delta,'9G999G999G999')                                                                 Gets
         , to_char(es.disk_reads_delta,'999G999G999')                                                                     Reads
         , to_char(es.cpu_time_delta/1000000,'999G999G999')                                                               Cputsec
         , to_char(es.elapsed_time_delta/1000000,'999G999G999')                                                           ElatSec
         , to_char(es.sorts_delta,'999G999G990')                                                                          sorts
         , decode(es.executions_delta, 0, null,es.sorts_delta/es.executions_delta)                                        sortpx
         , to_char(es.parse_calls_delta)                                                                                  Parsecall
         , es.invalidations_delta                                                                                         inval
         , es.version_count                                                                                               vcount
             , to_char(es.sharable_mem/1024,'999G999G999')                                                                sharememoryKB
      from
           v$database d
         , dba_hist_sqlstat  es
         , p
         , DBA_HIST_SNAPSHOT e
     where 
           (d.dbid           = e.dbid ) 
       AND (e.snap_id=es.snap_id AND e.dbid=es.dbid AND e.instance_number=es.instance_number)
       and (es.sql_id        = p.sql_id)
       AND e.begin_INTERVAL_TIME >bsnap
       and  e.end_INTERVAL_TIME<esnap
     order by e.begin_interval_time
;
clear col
undef 1 2 3 4 5 6 7 8 9