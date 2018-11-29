CREATE TABLE T_HINT01 as select * from dba_objects where object_id < 10000;
CREATE TABLE T_HINT02 as select * from dba_objects where object_id < 9000;

ANALYZE TABLE T_HINT01 COMPUTE STATISTICS;
ANALYZE TABLE T_HINT02 COMPUTE STATISTICS;

--对两张表进行等值连接, CBO解析器将两张表进行生产Hash表, 进行Hash Join.
select h01.object_id from t_hint01 h01,(select object_id from t_hint02) h02 where h01.object_id = h02.object_id;

Execution Plan
----------------------------------------------------------
Plan hash value: 3241826045

-------------------------------------------------------------------------------
| Id  | Operation          | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |          |  8959 | 53754 |    69   (0)| 00:00:01 |
|*  1 |  HASH JOIN         |          |  8959 | 53754 |    69   (0)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| T_HINT02 |  8959 | 26877 |    33   (0)| 00:00:01 |
|   3 |   TABLE ACCESS FULL| T_HINT01 |  9811 | 29433 |    36   (0)| 00:00:01 |
-------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("H01"."OBJECT_ID"="OBJECT_ID")

Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
        838  consistent gets
          0  physical reads
          0  redo size
     156279  bytes sent via SQL*Net to client
       7090  bytes received via SQL*Net from client
        599  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
       8959  rows processed

-- 对上面查询进行变形, 内容放到where子句中进行过滤. 可以看到执行计划中使用了视图合并查询
select h01.object_id from t_hint01 h01,(select object_id from t_hint02) h02 where h01.object_id = h02.object_id;
-- 与下面加了hint的结果一致, 不嵌套查询. 都是单独的对两张表进行查询.
select object_id from t_hint01 h01 where exists (select /*+ unnest*/ object_id from t_hint02 h02 where h02.object_id = h01.object_id); 

Execution Plan
----------------------------------------------------------
Plan hash value: 2411585024

--------------------------------------------------------------------------------
| Id  | Operation           | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |          |  8830 |   137K|    69   (0)| 00:00:01 |
|*  1 |  HASH JOIN SEMI     |          |  8830 |   137K|    69   (0)| 00:00:01 |
|   2 |   TABLE ACCESS FULL | T_HINT01 |  9811 | 29433 |    36   (0)| 00:00:01 |
|   3 |   VIEW              | VW_SQ_1  |  8959 |   113K|    33   (0)| 00:00:01 |
|   4 |    TABLE ACCESS FULL| T_HINT02 |  8959 | 26877 |    33   (0)| 00:00:01 |
--------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("ITEM_1"="H01"."OBJECT_ID")

Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
        838  consistent gets
          0  physical reads
          0  redo size
     156279  bytes sent via SQL*Net to client
       7090  bytes received via SQL*Net from client
        599  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
       8959  rows processed

/* 使用嵌套查询Hint, 可以看到查询中FILTER操作, 该操作类似于NESTED LOOP 单独维护一个Hash table, 举例：
   如果h01.object_id = 1, 对于h02表满足select object_id from t_hint02 h02 where h02.object_id = 1, 则子查询输入输出对,即为(1 (h01.object_id),h02.object_id).
   接着h01.object_id = 2, 满足h02表条件, 集子查询输出输出对为(2, h02.object_id). 此后如h01中有重复值, CBO已知对应的输入输出的结果集，因此直接省略全表扫描h02. 
   这就是FILTER的作用, 相较NESTED LOOP其省去对重复值的一次全表扫描操作成本更低. 但Hash table是有大小限制的, 如果占满, 则后续的FILTER与NESTED LOOP效果一样. 
   由此可见, 当外部查询传输给子查询的字段的选择度越低时, FILTER效率越优.
 */
 
select object_id from t_hint01 h01 where exists (select /*+ no_unnest*/ object_id from t_hint02 h02 where h02.object_id = h01.object_id);  

Execution Plan
----------------------------------------------------------
Plan hash value: 1392711037

-------------------------------------------------------------------------------
| Id  | Operation          | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |          |     1 |     3 |   162K  (1)| 00:32:31 |
|*  1 |  FILTER            |          |       |       |            |          |
|   2 |   TABLE ACCESS FULL| T_HINT01 |  9811 | 29433 |    36   (0)| 00:00:01 |
|*  3 |   TABLE ACCESS FULL| T_HINT02 |     1 |     3 |    33   (0)| 00:00:01 |
-------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter( EXISTS (SELECT /*+ NO_UNNEST */ 0 FROM "T_HINT02" "H02"
              WHERE "H02"."OBJECT_ID"=:B1))
   3 - filter("H02"."OBJECT_ID"=:B1)

Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
     639767  consistent gets
          0  physical reads
          0  redo size
     156279  bytes sent via SQL*Net to client
       7090  bytes received via SQL*Net from client
        599  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
       8959  rows processed

-- 和嵌套循环查询进行比较, 看到FILTER性能上的明显区别, 且consistent gets一致读小于嵌套循环查询 

select /*+ use_nl(h01 h02)*/ h01.object_id from t_hint01 h01,(select object_id from t_hint02) h02 where h01.object_id = h02.object_id;  

Execution Plan
----------------------------------------------------------
Plan hash value: 3677829310

-------------------------------------------------------------------------------
| Id  | Operation          | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |          |  8959 | 53754 |   309K  (1)| 01:01:51 |
|   1 |  NESTED LOOPS      |          |  8959 | 53754 |   309K  (1)| 01:01:51 |
|   2 |   TABLE ACCESS FULL| T_HINT02 |  8959 | 26877 |    33   (0)| 00:00:01 |
|*  3 |   TABLE ACCESS FULL| T_HINT01 |     1 |     3 |    35   (3)| 00:00:01 |
-------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - filter("H01"."OBJECT_ID"="OBJECT_ID")

Statistics
----------------------------------------------------------
         55  recursive calls
          0  db block gets
    1166013  consistent gets
          0  physical reads
          0  redo size
     156279  bytes sent via SQL*Net to client
       7090  bytes received via SQL*Net from client
        599  SQL*Net roundtrips to/from client
         10  sorts (memory)
          0  sorts (disk)
       8959  rows processed

-- 验证选择度低的字段查询, FILTER的性能优势. 选用object_type(只有20类型,重复值高)作为连接条件, consistent gets明显减少. 
select object_id from t_hint01 h01 where exists (select /*+ no_unnest*/ object_id from t_hint02 h02 where h02.object_type = h01.object_type); 

Execution Plan
----------------------------------------------------------
Plan hash value: 1392711037

-------------------------------------------------------------------------------
| Id  | Operation          | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |          |   491 |  4419 |    76   (0)| 00:00:01 |
|*  1 |  FILTER            |          |       |       |            |          |
|   2 |   TABLE ACCESS FULL| T_HINT01 |  9811 | 88299 |    36   (0)| 00:00:01 |
|*  3 |   TABLE ACCESS FULL| T_HINT02 |     2 |    12 |     2   (0)| 00:00:01 |
-------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter( EXISTS (SELECT /*+ NO_UNNEST */ 0 FROM "T_HINT02" "H02"
              WHERE "H02"."OBJECT_TYPE"=:B1))
   3 - filter("H02"."OBJECT_TYPE"=:B1)

Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
       1596  consistent gets
          0  physical reads
          0  redo size
     170415  bytes sent via SQL*Net to client
       7684  bytes received via SQL*Net from client
        653  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
       9779  rows processed

-- 思考使用场景：