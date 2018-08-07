BREAK ON REPORT
COMPUT SUM OF tbsp_size ON REPORT
compute SUM OF used ON REPORT
compute SUM OF free ON REPORT

COL tbspname FORMAT a30 HEADING 'Tablespace Name'
COL tbsp_size FORMAT 999,999,999 HEADING 'Size|(MB)'
COL used FORMAT 999,999,999 HEADING 'Used|(MB)'
COL free FORMAT 999,999,999 HEADING 'Free|(MB)'
COL pct_used FORMAT 999,999 HEADING '% Used'
SET PAGES 300

SELECT df.tablespace_name tbspname,
       sum(df.bytes) / 1024 / 1024 tbsp_size,
       nvl(sum(e.used_bytes) / 1024 / 1024, 0) used,
       nvl(sum(f.free_bytes) / 1024 / 1024, 0) free,
       nvl((sum(e.used_bytes) * 100) / sum(df.bytes), 0) pct_used
  FROM DBA_DATA_FILES df,
       (SELECT file_id, SUM(nvl(bytes, 0)) used_bytes
          FROM dba_extents
         GROUP BY file_id) e,
       (SELECT MAX(bytes) free_bytes, file_id
          FROM dba_free_space
         GROUP BY file_id) f
WHERE e.file_id(+) = df.file_id
   AND df.file_id = f.file_id(+)
GROUP BY df.tablespace_name
ORDER BY 5 DESC;


/*
The format should like this way
                                       Size         Used         Free
Tablespace Name                        (MB)         (MB)         (MB)   % Used
------------------------------ ------------ ------------ ------------ --------
TWXXX_0058_INDEX                     70,864       69,653        1,066       98
TWXXX_0043_DATA                     270,668      263,848        4,425       97
TWXXX_0011_INDEX                    182,846      178,189        3,989       97
TWXXX_0043_INDEX                     58,544       56,945        1,596       97
TWXXX_00BE_DATA                     130,076      126,456        2,934       97
                               ------------ ------------ ------------
sum                               2,112,388    2,005,788       74,315
*/

SET LINE 300
COL TABLESPACE_NAME FOR A15
COL FILE_NAME FOR A75
SELECT tablespace_name,file_id,
       100 * (sum_max - sum_alloc + nvl(sum_free, 0)) / sum_max AS free_rate,
       (sum_max - sum_alloc + nvl(sum_free, 0)) / 1024 / 1024 AS free_size,
       (sum_max - nvl(sum_free, 0)) / 1024 / 1024 as used_size,
       sum_max / 1024 / 1024 as max_size,
       100 * nvl(sum_free, 0) / sum_alloc As actual_free_rate,
       nvl(sum_free, 0) / 1024 / 1024 as actual_free,
       (sum_alloc - nvl(sum_free, 0)) / 1024 / 1024 as actual_used,
       sum_alloc / 1024 / 1024 as actual_max,
       file_name
  FROM (SELECT tablespace_name,
               file_id,
               sum(bytes) AS sum_alloc,
               sum(decode(maxbytes, 0, bytes, maxbytes)) AS sum_max,
               file_name
          FROM dba_data_files where tablespace_name = '&tbsp_name'
         GROUP BY tablespace_name, file_name, file_id),
       (SELECT tablespace_name AS fs_ts_name,
               file_id as file_ts_id,
               sum(bytes) AS sum_free
          FROM dba_free_space
         GROUP BY tablespace_name, file_id)
WHERE file_id = file_ts_id(+)
order by 2, 3; 

/*
table space Fragmentation,while the fsfi less than 30, it means there are many fragments
*/

SELECT a.tablespace_name,
       trunc(sqrt(max(blocks)/sum(blocks))* (100/sqrt(sqrt(count(blocks)))),2) fsfi 
  FROM dba_free_space  a,dba_tablespaces b
 WHERE a.tablespace_name=b.tablespace_name
   AND b.contents NOT IN ('TEMPORARY','UNDO','SYSAUX')
 GROUP BY A.tablespace_name 
 ORDER BY fsfi;
 
/*
table space Fragmentation records, free records in a tablespace, if it is not a serial free space, then a tablespace might include several free records. 
*/ 
SELECT a.tablespace_name ,count(1)
  FROM dba_free_space a, dba_tablespaces b 
 WHERE a.tablespace_name =b.tablespace_name
   AND b.contents not in('TEMPORARY','UNDO','SYSAUX')
 GROUP BY a.tablespace_name
HAVING count(1) >20
 ORDER BY 2; 
