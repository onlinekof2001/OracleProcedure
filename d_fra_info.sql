
prompt display information about fra and backup.	
col name for a50

prompt 1-archive log by hour
 SELECT SUM_ARCH.DAY,
         round(SUM_ARCH.GENERATED_MB) GENERATED_MB,
         round(SUM_ARCH_DEL.DELETED_MB) DELETED_MB,
         round(SUM_ARCH.GENERATED_MB - SUM_ARCH_DEL.DELETED_MB ) "REMAINING_MB"
from          
(SELECT TO_CHAR (COMPLETION_TIME, 'DD/MM/YYYY hh24') DAY,
                   SUM (ROUND ( (blocks * block_size) / (1024 * 1024), 2))
                      GENERATED_MB
              FROM V$ARCHIVED_LOG
             WHERE ARCHIVED = 'YES' and completion_time>sysdate -2
          GROUP BY TO_CHAR (COMPLETION_TIME, 'DD/MM/YYYY hh24')) SUM_ARCH,
(SELECT TO_CHAR (COMPLETION_TIME, 'DD/MM/YYYY hh24') DAY,
                   SUM (ROUND ( (blocks * block_size) / (1024 * 1024), 2))
                      DELETED_MB
              FROM V$ARCHIVED_LOG
             WHERE ARCHIVED = 'YES' AND DELETED = 'YES'   and completion_time>sysdate -2
          GROUP BY TO_CHAR (COMPLETION_TIME, 'DD/MM/YYYY hh24')) SUM_ARCH_DEL
  WHERE SUM_ARCH.DAY = SUM_ARCH_DEL.DAY(+)
ORDER BY TO_DATE (day, 'DD/MM/YYYY hh24');  


prompt 2-archive log by day
select trunc(COMPLETION_TIME,'dd') Hour,thread# , round(sum(BLOCKS*BLOCK_SIZE)/1048576) MB,count(*) Archives from v$archived_log
where completion_time >sysdate-20
group by trunc(COMPLETION_TIME,'dd'),thread#  order by 1 ;


prompt 3-inforation about fra 
SELECT name, round(space_limit/1024/1024/1024) space_limit_go, round(SPACE_USED/1024/1024/1024) SPACE_USEDgo, round(SPACE_RECLAIMABLE/1024/1024/1024) SPACE_RECLAIMABLE_go, round(SPACE_USED/space_limit*100) "% used"  FROM V$RECOVERY_FILE_DEST;


prompt how is used the fra
SELECT * FROM V$FLASH_RECOVERY_AREA_USAGE;


prompt 4-last backup

set line 180
col name for A20 trunc
col duration for 999
col status  for a25
col operation for a15
col mbytes_processed for 999,999
SELECT  command_id, object_type,operation, status, round(mbytes_processed) mbytes_processed,   to_char(start_time,'DD/MM/YY HH24:MI:SS') start_time, to_char(end_time,'DD/MM/YY HH24:MI:SS') end_time,
  (end_time - start_time) *  decode( upper('MI'), 'SS', 24*60*60, 'MI', 24*60, 'HH', 24, NULL) Duration, round(rs.OUTPUT_BYTES/1024/1024) output_mb
    from V$RMAN_STATUS rs
  where trunc (start_time) > trunc(sysdate-4)
  and ( 
  (object_type='ARCHIVELOG' and operation='BACKUP') or  
  (object_type='DB FULL' and operation='BACKUP') )
  order by command_id;
  
clear columns;
undef 1 2 3 4 5 6 7 8 9