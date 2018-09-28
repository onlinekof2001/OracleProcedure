/*
碎片简单理解就是在大量使用DML操作数据库时，其产生一些不能被再次使用的碎小空间，根据每种不同的碎片他们的产生也是有区别的，主要包涵一下几个层次。
|--disk-level fragmention
|----tablespace-level fragmentation
|------segment-level fragmentation
|--------block-level fragmentation
|----------row-level fragmentation
|----------index leaf block-level fragmentation
通过Oracle自身的function给出对象级碎片整理的意见
*/
set line 180 pages 0
col advice for a110
SELECT 'Segment Advice --------------------------' || chr(10) ||
       'TABLESPACE_NAME : ' || tablespace_name || chr(10) ||
       'SEGMENT_OWNER : ' || segment_owner || chr(10) || 'SEGMENT_NAME : ' ||
       segment_name || chr(10) || 'ALLOCATED_SPACE : ' || allocated_space ||
       chr(10) || 'RECLAIMABLE_SPACE: ' || reclaimable_space || chr(10) ||
       'RECOMMENDATIONS : ' || recommendations || chr(10) ||
       'SOLUTION 1 : ' || c1 || chr(10) || 'SOLUTION 2 : ' || c2 || chr(10) ||
       'SOLUTION 3 : ' || c3 Advice
  FROM TABLE(dbms_space.asa_recommendations('FALSE', 'FALSE', 'FALSE'))

/*
验证通过query_tablespace.sql中的"Query Format 2"获取
*/

/* 表空间级别碎片处理
tablespace Fragmentation,while the fsfi less than 30, it means there are many fragments
*/

SELECT a.tablespace_name,
       trunc(sqrt(max(blocks)/sum(blocks))* (100/sqrt(sqrt(count(blocks)))),2) fsfi 
  FROM dba_free_space  a,dba_tablespaces b
 WHERE a.tablespace_name=b.tablespace_name
   AND b.contents NOT IN ('TEMPORARY','UNDO','SYSAUX')
 GROUP BY A.tablespace_name 
 ORDER BY fsfi;
 
/*
tablespace Fragmentation records, free records in a tablespace, if it is not a serial of free space, then a tablespace might include
 several pieces of free records. 
*/ 

SELECT a.tablespace_name ,count(1)
  FROM dba_free_space a, dba_tablespaces b 
 WHERE a.tablespace_name =b.tablespace_name
   AND b.contents not in('TEMPORARY','UNDO','SYSAUX')
 GROUP BY a.tablespace_name
HAVING count(1) > 20
 ORDER BY 2; 

/*
通过resize的方式减少表空间级别的HWM线。
*/
select /*+ ordered use_hash(a,c) */
 'alter database datafile ''' || a.file_name || ''' resize ' ||
 round(a.filesize - (a.filesize - c.hwmsize - 100) * 0.8) || 'M;',
 a.filesize,
 c.hwmsize
  from (select file_id, file_name, round(bytes / 1024 / 1024) filesize
          from dba_data_files) a,
       (select file_id, round(max(block_id) * 8 / 1024) HWMsize
          from dba_extents
         group by file_id) c
 where a.file_id = c.file_id
   and a.filesize - c.hwmsize > 100; 
 

/* 表级别碎片处理 
enable row movement 开启行迁移功能
保持HWM的情况下，重新整理数据
回缩表与降低HWM
回缩表相关索引，降低HWM
@?/rdbms/admin/utlrp.sql 重新编译失效对象
此方法空间收缩优于数据增长，碎片清理不彻底
*/

SELECT 'alter table '||OWNER||'.'||TABLE_NAME||' enable row movement;'||chr(10)||'alter table '||OWNER||'.'||TABLE_NAME||' shrink space compact;'||chr(10)||'alter table '||OWNER||'.'||TABLE_NAME||' shrink space;'||chr(10)||'alter table '||OWNER||'.'||TABLE_NAME||' shrink space cascade;'||chr(10)|| 'alter table '||OWNER||'.'||TABLE_NAME||' disable row movement;'
  FROM (SELECT OWNER, SEGMENT_NAME TABLE_NAME, SEGMENT_TYPE,  GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS,0)/GREATEST(NVL(HWM,1),1) ), 2), 0) WASTE_PER,  ROUND(BYTES/1024, 2) TABLE_KB, NUM_ROWS,  BLOCKS, EMPTY_BLOCKS, HWM HIGHWATER_MARK, AVG_USED_BLOCKS,  CHAIN_PER, EXTENTS, MAX_EXTENTS, ALLO_EXTENT_PER,  DECODE(GREATEST(MAX_FREE_SPACE - NEXT_EXTENT, 0), 0,'N','Y') CAN_EXTEND_SPACE,  NEXT_EXTENT, MAX_FREE_SPACE,  O_TABLESPACE_NAME TABLESPACE_NAME
          FROM (SELECT A.OWNER OWNER, A.SEGMENT_NAME, A.SEGMENT_TYPE, A.BYTES,  B.NUM_ROWS, A.BLOCKS BLOCKS, B.EMPTY_BLOCKS EMPTY_BLOCKS,  A.BLOCKS - B.EMPTY_BLOCKS - 1 HWM,  DECODE( ROUND((B.AVG_ROW_LEN * NUM_ROWS * (1 + (PCT_FREE/100)))/C.BLOCKSIZE, 0),  0, 1,  ROUND((B.AVG_ROW_LEN * NUM_ROWS * (1 + (PCT_FREE/100)))/C.BLOCKSIZE, 0)  ) + 2 AVG_USED_BLOCKS,  ROUND(100 * (NVL(B.CHAIN_CNT, 0)/GREATEST(NVL(B.NUM_ROWS, 1), 1)), 2) CHAIN_PER,  ROUND(100 * (A.EXTENTS/A.MAX_EXTENTS), 2) ALLO_EXTENT_PER,A.EXTENTS EXTENTS,  A.MAX_EXTENTS MAX_EXTENTS, B.NEXT_EXTENT NEXT_EXTENT, B.TABLESPACE_NAME O_TABLESPACE_NAME 
	              FROM SYS.DBA_SEGMENTS A,  SYS.DBA_TABLES B,  SYS.TS$ C  
			     WHERE A.OWNER =B.OWNER
   			       AND SEGMENT_NAME = TABLE_NAME 
			  	   AND SEGMENT_TYPE = 'TABLE' 
			  	   AND B.TABLESPACE_NAME = C.NAME 
				   AND B.TABLESPACE_NAME = '&tbsp_name'	
			    UNION ALL 
			    SELECT A.OWNER OWNER, SEGMENT_NAME || '.' || B.PARTITION_NAME, SEGMENT_TYPE, BYTES,  B.NUM_ROWS, A.BLOCKS BLOCKS, B.EMPTY_BLOCKS EMPTY_BLOCKS,  A.BLOCKS - B.EMPTY_BLOCKS - 1 HWM,  DECODE( ROUND((B.AVG_ROW_LEN * B.NUM_ROWS * (1 + (B.PCT_FREE/100)))/C.BLOCKSIZE, 0),  0, 1,  ROUND((B.AVG_ROW_LEN * B.NUM_ROWS * (1 + (B.PCT_FREE/100)))/C.BLOCKSIZE, 0)  ) + 2 AVG_USED_BLOCKS,  ROUND(100 * (NVL(B.CHAIN_CNT,0)/GREATEST(NVL(B.NUM_ROWS, 1), 1)), 2) CHAIN_PER,  ROUND(100 * (A.EXTENTS/A.MAX_EXTENTS), 2) ALLO_EXTENT_PER, A.EXTENTS EXTENTS,  A.MAX_EXTENTS MAX_EXTENTS, B.NEXT_EXTENT,  B.TABLESPACE_NAME O_TABLESPACE_NAME 
			      FROM SYS.DBA_SEGMENTS A,  SYS.DBA_TAB_PARTITIONS B,  SYS.TS$ C,  SYS.DBA_TABLES D 
			     WHERE A.OWNER = B.TABLE_OWNER 
			       AND SEGMENT_NAME = B.TABLE_NAME 
			  	   AND SEGMENT_TYPE = 'TABLE PARTITION' 
			  	   AND B.TABLESPACE_NAME = C.NAME 
			  	   AND D.OWNER = B.TABLE_OWNER
			  	   AND D.TABLE_NAME = B.TABLE_NAME
			  	   AND A.PARTITION_NAME = B.PARTITION_NAME), 
			   (SELECT TABLESPACE_NAME F_TABLESPACE_NAME,MAX(BYTES)  MAX_FREE_SPACE 
			      FROM SYS.DBA_FREE_SPACE
                 WHERE TABLESPACE_NAME = '&tbsp_name'				  
			     GROUP BY TABLESPACE_NAME)
         WHERE F_TABLESPACE_NAME = O_TABLESPACE_NAME
           AND GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0)/GREATEST(NVL(HWM, 1), 1) ), 2), 0) > 25
           AND OWNER not in  ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB') 
           AND BLOCKS > 128
         ORDER BY 10 DESC, 1 ASC, 2 ASC);

		 
col TABLESPACE_NAME for a20
col SUM_SPACE(M) for a18
col USED_SPACE(M) for a18
col FREE_SPACE(M) for a18
col USED_RATE(%) for a18

SELECT D.TABLESPACE_NAME,  
       SPACE || 'M' "SUM_SPACE(M)",  
       BLOCKS "SUM_BLOCKS",  
       SPACE - NVL (FREE_SPACE, 0) || 'M' "USED_SPACE(M)",  
       ROUND ( (1 - NVL (FREE_SPACE, 0) / SPACE) * 100, 2) || '%'  
       "USED_RATE(%)",  
       FREE_SPACE || 'M' "FREE_SPACE(M)"
  FROM (SELECT TABLESPACE_NAME,
               ROUND (SUM (BYTES) / (1024 * 1024), 2) SPACE,
			   SUM (BLOCKS) BLOCKS
		  FROM DBA_DATA_FILES
		 GROUP BY TABLESPACE_NAME) D,
		(SELECT TABLESPACE_NAME,
		        ROUND (SUM (BYTES) / (1024 * 1024), 2) FREE_SPACE
		   FROM DBA_FREE_SPACE
		  GROUP BY TABLESPACE_NAME) F
		  WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
		  UNION ALL
		 SELECT D.TABLESPACE_NAME,
		        SPACE || 'M' "SUM_SPACE(M)",
		        BLOCKS SUM_BLOCKS,
		        USED_SPACE || 'M' "USED_SPACE(M)",
		        ROUND (NVL (USED_SPACE, 0) / SPACE * 100, 2) || '%' "USED_RATE(%)",
		        NVL (FREE_SPACE, 0) || 'M' "FREE_SPACE(M)"
		   FROM (SELECT TABLESPACE_NAME,
		                ROUND (SUM (BYTES) / (1024 * 1024), 2) SPACE, 
		                SUM (BLOCKS) BLOCKS
		           FROM DBA_TEMP_FILES 
		          GROUP BY TABLESPACE_NAME) D, 
		        (SELECT TABLESPACE_NAME,
		                ROUND (SUM (BYTES_USED) / (1024 * 1024), 2) USED_SPACE,
		                ROUND (SUM (BYTES_FREE) / (1024 * 1024), 2) FREE_SPACE
		           FROM V$TEMP_SPACE_HEADER 
		          GROUP BY TABLESPACE_NAME) F
		  WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
		  ORDER BY 1; 

/*
整理数据增长优于空间收缩， 碎片清理彻底
*/
		 
SELECT 'alter table ' || OWNER || '.' || TABLE_NAME || ' move;'
  FROM (SELECT OWNER,
               SEGMENT_NAME TABLE_NAME,
               SEGMENT_TYPE,
               GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) /
                              GREATEST(NVL(HWM, 1), 1)),
                              2),
                        0) WASTE_PER,
               ROUND(BYTES / 1024, 2) TABLE_KB,
               NUM_ROWS,
               BLOCKS,
               EMPTY_BLOCKS,
               HWM HIGHWATER_MARK,
               AVG_USED_BLOCKS,
               CHAIN_PER,
               EXTENTS,
               MAX_EXTENTS,
               ALLO_EXTENT_PER,
               DECODE(GREATEST(MAX_FREE_SPACE - NEXT_EXTENT, 0), 0, 'N', 'Y') CAN_EXTEND_SPACE,
               NEXT_EXTENT,
               MAX_FREE_SPACE,
               O_TABLESPACE_NAME TABLESPACE_NAME
          FROM (SELECT A.OWNER OWNER,
                       A.SEGMENT_NAME,
                       A.SEGMENT_TYPE,
                       A.BYTES,
                       B.NUM_ROWS,
                       A.BLOCKS BLOCKS,
                       B.EMPTY_BLOCKS EMPTY_BLOCKS,
                       A.BLOCKS - B.EMPTY_BLOCKS - 1 HWM,
                       DECODE(ROUND((B.AVG_ROW_LEN * NUM_ROWS *
                                    (1 + (PCT_FREE / 100))) / C.BLOCKSIZE,
                                    0),
                              0,
                              1,
                              ROUND((B.AVG_ROW_LEN * NUM_ROWS *
                                    (1 + (PCT_FREE / 100))) / C.BLOCKSIZE,
                                    0)) + 2 AVG_USED_BLOCKS,
                       ROUND(100 * (NVL(B.CHAIN_CNT, 0) /
                             GREATEST(NVL(B.NUM_ROWS, 1), 1)),
                             2) CHAIN_PER,
                       ROUND(100 * (A.EXTENTS / A.MAX_EXTENTS), 2) ALLO_EXTENT_PER,
                       A.EXTENTS EXTENTS,
                       A.MAX_EXTENTS MAX_EXTENTS,
                       B.NEXT_EXTENT NEXT_EXTENT,
                       B.TABLESPACE_NAME O_TABLESPACE_NAME
                  FROM SYS.DBA_SEGMENTS A, SYS.DBA_TABLES B, SYS.TS$ C
                 WHERE A.OWNER = B.OWNER
                   AND SEGMENT_NAME = TABLE_NAME
                   AND SEGMENT_TYPE = 'TABLE'
                   AND B.TABLESPACE_NAME = C.NAME
				   AND B.TABLESPACE_NAME = '&tbsp_name'
                UNION ALL
                SELECT A.OWNER OWNER,
                       SEGMENT_NAME || '.' || B.PARTITION_NAME,
                       SEGMENT_TYPE,
                       BYTES,
                       B.NUM_ROWS,
                       A.BLOCKS BLOCKS,
                       B.EMPTY_BLOCKS EMPTY_BLOCKS,
                       A.BLOCKS - B.EMPTY_BLOCKS - 1 HWM,
                       DECODE(ROUND((B.AVG_ROW_LEN * B.NUM_ROWS *
                                    (1 + (B.PCT_FREE / 100))) / C.BLOCKSIZE,
                                    0),
                              0,
                              1,
                              ROUND((B.AVG_ROW_LEN * B.NUM_ROWS *
                                    (1 + (B.PCT_FREE / 100))) / C.BLOCKSIZE,
                                    0)) + 2 AVG_USED_BLOCKS,
                       ROUND(100 * (NVL(B.CHAIN_CNT, 0) /
                             GREATEST(NVL(B.NUM_ROWS, 1), 1)),
                             2) CHAIN_PER,
                       ROUND(100 * (A.EXTENTS / A.MAX_EXTENTS), 2) ALLO_EXTENT_PER,
                       A.EXTENTS EXTENTS,
                       A.MAX_EXTENTS MAX_EXTENTS,
                       B.NEXT_EXTENT,
                       B.TABLESPACE_NAME O_TABLESPACE_NAME
                  FROM SYS.DBA_SEGMENTS       A,
                       SYS.DBA_TAB_PARTITIONS B,
                       SYS.TS$                C,
                       SYS.DBA_TABLES         D
                 WHERE A.OWNER = B.TABLE_OWNER
                   and SEGMENT_NAME = B.TABLE_NAME
                   and SEGMENT_TYPE = 'TABLE PARTITION'
                   AND B.TABLESPACE_NAME = C.NAME
                   AND D.OWNER = B.TABLE_OWNER
                   AND D.TABLE_NAME = B.TABLE_NAME
                   AND A.PARTITION_NAME = B.PARTITION_NAME),
               (SELECT TABLESPACE_NAME F_TABLESPACE_NAME,
                       MAX(BYTES) MAX_FREE_SPACE
                  FROM SYS.DBA_FREE_SPACE
				 WHERE TABLESPACE_NAME = '&tbsp_name'
                 GROUP BY TABLESPACE_NAME)
         WHERE F_TABLESPACE_NAME = O_TABLESPACE_NAME
           AND GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) /
                              GREATEST(NVL(HWM, 1), 1)),
                              2),
                        0) > 25
           AND OWNER not in ('SYS', 'SYSTEM', 'DBSNMP', 'SYSMAN', 'XDB')
           AND BLOCKS > 128
         ORDER BY 10 DESC, 1 ASC, 2 ASC);

/*
Rebuild index for those tables
*/
		 
select 'alter index ' || OWNER || '.' || segment_name ||
       ' rebuild nologgin online;'
  from (select *
          from SYS.DBA_SEGMENTS
         where segment_type = 'INDEX'
           AND TABLESPACE_NAME = '&tbsp_name'); 

/* 索引级别的碎片整理
在线重建

*/
select 'analyze index '||segment_name||' validate structure;'
  from dba_segments
 where segment_type = 'INDEX'
   and owner not in ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB');
   
select height, blocks, lf_blks, lf_rows, br_blks, br_rows, del_lf_rows
  from index_stats

SELECT 'alter index ' || owner || '.' || segment_name ||
       ' rebuild nologgin online;'
  FROM (SELECT COUNT(*), owner, segment_name, t.tablespace_name
          FROM dba_extents t
         WHERE t.segment_type = 'INDEX'
           AND t.owner NOT IN ('SYS', 'SYSTEM', 'DBSNMP', 'SYSMAN', 'XDB')
           AND t.tablespace_name = '&tbsp_name'
         GROUP BY owner, segment_name, t.tablespace_name
        HAVING COUNT(*) > 10
         ORDER BY COUNT(*) DESC);  
  