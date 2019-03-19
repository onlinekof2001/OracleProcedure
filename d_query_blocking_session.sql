select s.username,p.pid,s.sid,s.serial#,s.sql_id,s.blocking_session from v$session s,v$process p where s.paddr=p.addr and s.program='rtidm1tom40_CADISP_PRD_AS' and s.username='CADISP';
https://blog.csdn.net/tomorrow_is_better/article/details/72772495

-- 创建sql tuning任务
DECLARE
  my_task_name VARCHAR2(30);
BEGIN
    my_task_name :=DBMS_SQLTUNE.CREATE_TUNING_TASK(
    sql_id => '5xw3ntd9w5prx',
    scope => 'COMPREHENSIVE',
    time_limit => 60,
    task_name => 'test_sql_tuning_task2',
    description => 'Task to tune a query');
    DBMS_SQLTUNE.EXECUTE_TUNING_TASK(task_name => 'test_sql_tuning_task2');
END;


SET LONG 10000
SET LONGCHUNKSIZE 1000
SET LINESIZE 100
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('test_sql_tuning_task2')
FROM DUAL;

alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss'
grant advisor to  DBA_MONITER;
col task_name for a30
col ADVISOR_NAME for a30
select task_name,ADVISOR_NAME,STATUS,EXECUTION_END from dba_advisor_tasks order by execution_end;

select 
  /* "|chr(13)||chr(10)"为windows平台的换行符，假设是linux等其他平台，请用"chr(10)"取代 */
 'Task name     :'||f.task_name||chr(10)||  
 'Segment name  :'||o.attr2    ||chr(10)||
 'Sement type   :'||o.type     ||chr(10)||
 'partition name:'||o.attr3    ||chr(10)||
 'Message       :'||f.message  ||chr(10)||
 'More info     :'||f.more_info TASK_ADVICE
 from dba_advisor_findings f,dba_advisor_objects o
where o.task_id=f.task_id
  and o.object_id=f.object_id
  and f.task_name = 'SYS_AUTO_SPCADV_46091802032019'
order by f.task_name;


select dbms_sqltune.report_tuning_task('test_sql_tuning_task2') from dual;

EXEC  DBMS_MVIEW.REFRESH('MD0000.PARAMETRES_DETAIL','C',PARALLELISM=>4,ATOMIC_REFRESH=>FALSE); 
EXEC  DBMS_MVIEW.REFRESH('MD0000.PARAMETRES_MASTERDATAS','C',PARALLELISM=>4,ATOMIC_REFRESH=>FALSE); 
EXEC  DBMS_MVIEW.REFRESH('MD0000.ZONE_DEVISE','C',PARALLELISM=>4,ATOMIC_REFRESH=>FALSE); 
EXEC  DBMS_MVIEW.REFRESH('MD0000.GOOD_AND_SERVICES','C',PARALLELISM=>4,ATOMIC_REFRESH=>FALSE);

TASK_ADVICE
--------------------------------------------------------------------------------
Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :IDX01_AUDIT_WEBSERVICES
Sement type   :INDEX
partition name:
Message       :Perform shrink, estimated savings is 68125050 bytes.
More info     :Allocated Space:377487360: Used Space:309362310: Reclaimable Space :68125050:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :DISPATCH_PARAMETER
Sement type   :TABLE
partition name:
Message       :Enable row movement of the table CADISP.DISPATCH_PARAMETER and pe
rform shrink, estimated savings is 3031151783 bytes.
More info     :Allocated Space:4939841536: Used Space:1908689753: Reclaimable Space :3031151783:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :DISPATCH_INFO
Sement type   :TABLE
partition name:
Message       :Enable row movement of the table CADISP.DISPATCH_INFO and perform shrink, estimated savings is 980815253 bytes.
More info     :Allocated Space:2552233984: Used Space:1571418731: Reclaimable Space :980815253:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :AUDIT_WEBSERVICES
Sement type   :TABLE
partition name:
Message       :Enable row movement of the table WEBSERV.AUDIT_WEBSERVICES and pe
rform shrink, estimated savings is 93994591 bytes.
More info     :Allocated Space:411041792: Used Space:317047201: Reclaimable Space :93994591:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :PK_AUDIT_WBS
Sement type   :INDEX
partition name:
Message       :Perform shrink, estimated savings is 39268681 bytes.
More info     :Allocated Space:209715200: Used Space:170446519: Reclaimable Spac
e :39268681:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :IDX09_DISPATCH_INFO
Sement type   :INDEX
partition name:
Message       :Perform shrink, estimated savings is 153590290 bytes.
More info     :Allocated Space:536870912: Used Space:383280622: Reclaimable Space :153590290:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :IDX10_DISPATCH_INFO
Sement type   :INDEX
partition name:
Message       :Perform shrink, estimated savings is 243672583 bytes.
More info     :Allocated Space:461373440: Used Space:217700857: Reclaimable Space :243672583:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :IDX02_DISPATCH_INFO
Sement type   :INDEX
partition name:
Message       :Perform shrink, estimated savings is 239336901 bytes.
More info     :Allocated Space:463470592: Used Space:224133691: Reclaimable Space :239336901:

Task name     :SYS_AUTO_SPCADV_24102223022019
Segment name  :IDX08_DISPATCH_INFO
Sement type   :INDEX
partition name:
Message       :Perform shrink, estimated savings is 359766730 bytes.
More info     :Allocated Space:1031798784: Used Space:672032054: Reclaimable Space :359766730:
alter index CADISP.IDX08_DISPATCH_INFO rebuild online parallel 4 nologging; 



[oracle@rtdkm1odb50 /u01/app/oracle/diag/rdbms/tetrix01_rtdkm1odb50/tetrix01/trace]$ iostat -m -d /dev/dm-7 1 10
Linux 2.6.32-573.22.1.el6.x86_64 (rtdkm1odb50.hosting.as)       03/02/2019      _x86_64_        (4 CPU)

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7             65.57         2.84         0.45  223990395   35384949

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2652.00      1320.85         0.00       1320          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2671.00      1328.78         0.00       1328          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2713.00      1351.44         0.00       1351          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2725.00      1356.80         0.00       1356          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2692.00      1338.89         0.00       1338          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2623.00      1307.09         0.00       1307          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2611.00      1298.33         0.00       1298          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2661.00      1323.72         0.00       1323          0

Device:            tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
dm-7           2693.00      1338.14         0.00       1338          0

https://www.cnblogs.com/xwdreamer/p/3897580.html




SELECT
  'alter database datafile '''||a.file_name||''' autoextend on next 256M maxsize '||floor(greatest(a.maxbytes,a.bytes)/(1024*1024))||'M;',
  'alter database datafile '''||a.file_name||''' resize '||decode(CEIL((NVL(b.hwm, 2)*blksize)/(1024*1024)),1,2,CEIL((NVL(b.hwm, 2)*blksize)/(1024*1024)))||'M;'
FROM DBA_DATA_FILES a,
( SELECT file_id, MAX( block_id + blocks - 1 ) hwm FROM DBA_EXTENTS GROUP BY file_id ) b,
( SELECT TO_NUMBER( value ) blksize FROM V$PARAMETER WHERE name = 'db_block_size' )
WHERE a.file_id = b.file_id(+)
and CEIL(blocks*blksize/(1024*1024)) - CEIL((NVL(hwm,1)*blksize)/(1024*1024)) > 16
and upper(a.file_name) not like '%SYSTEM%'
and upper(a.file_name) not like '%UNDO%';