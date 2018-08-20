/*
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


/* 表级别碎片处理 
enable row movement 开启行迁移功能
保持HWM的情况下，重新整理数据
回缩表与降低HWM
回缩表相关索引，降低HWM
@?/rdbms/admin/utlrp.sql 重新编译失效对象
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
				   AND B.TABLESPACE_NAME = '&tbsp_name.'	
			  	   AND D.OWNER = B.TABLE_OWNER
			  	   AND D.TABLE_NAME = B.TABLE_NAME
			  	   AND A.PARTITION_NAME = B.PARTITION_NAME), 
			   (SELECT TABLESPACE_NAME F_TABLESPACE_NAME,MAX(BYTES)  MAX_FREE_SPACE 
			      FROM SYS.DBA_FREE_SPACE
                 WHERE TABLESPACE_NAME = '&tbsp_name.'				  
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
                   and SEGMENT_NAME = TABLE_NAME
                   and SEGMENT_TYPE = 'TABLE'
                   AND B.TABLESPACE_NAME = C.NAME
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
                 GROUP BY TABLESPACE_NAME)
         WHERE F_TABLESPACE_NAME = O_TABLESPACE_NAME
           AND GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) /
                              GREATEST(NVL(HWM, 1), 1)),
                              2),
                        0) > 25
           AND OWNER not in ('SYS', 'SYSTEM', 'DBSNMP', 'SYSMAN', 'XDB')
           AND BLOCKS > 128
         ORDER BY 10 DESC, 1 ASC, 2 ASC);




