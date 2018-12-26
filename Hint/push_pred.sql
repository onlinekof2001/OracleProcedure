/* 前提了解Mergeable view和Unmergeable view 
 The optimizer can merge a view into a referencing query block when the view has one or more base tables, provided the view does not contain:
    set operators (UNION, UNION ALL, INTERSECT, MINUS) 
    a CONNECT BY clause 
    a ROWNUM pseudocolumn
    aggregate functions (AVG, COUNT, MAX, MIN, SUM) in the select list
 When a view contains one of the following structures, it can be merged into a referencing query block only if complex view merging is enabled (as described below):
    a GROUP BY clause
    a DISTINCT operator in the select list
 View merging is not possible for a view that has multiple base tables if it is on the right side of an outer join. 
 If a view on the right side of an outer join has only one base table, however, the optimizer can use complex view merging even if an expression in the view can return a non-null value for a NULL. See "Views in Outer Joins" for more information.

 https://blogs.oracle.com/optimizer/optimizer-transformations:-view-merging-part-1 
 https://docs.oracle.com/database/121/TGSQL/tgsql_transform.htm#TGSQL209 
 
 其中提到基于多张表构成的视图放在外连接右边查询时, 无法进行视图合并, 可以看到以下两个语句的查询执行计划一致，都将子查询转换成了VIEW
 */
 
create table t_hint03 as select * from dba_objects where object_id < 7000;
create or replace view h_view as select h03.* from t_hint03 h03,t_hint02 h02 where h02.object_id = h03.object_id;
-- 索引必须存在
* create index idx_obj_id on t_hint03(object_id);

select h_v.object_name from t_hint01 h01,(select h03.* from t_hint03 h03,t_hint02 h02 where h02.object_id = h03.object_id) h_v where h01.object_id = h_v.object_id(+);
or
select h_v.object_name from t_hint01 h01,h_view h_v where h01.object_id = h_v.object_id(+);

Execution Plan
----------------------------------------------------------
Plan hash value: 3039741533

---------------------------------------------------------------------------------
| Id  | Operation            | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |          |  9811 |   785K|    96   (2)| 00:00:02 |
|*  1 |  HASH JOIN OUTER     |          |  9811 |   785K|    96   (2)| 00:00:02 |
|   2 |   TABLE ACCESS FULL  | T_HINT01 |  9811 | 29433 |    36   (0)| 00:00:01 |
|   3 |   VIEW               |          |  7507 |   579K|    59   (0)| 00:00:01 |
|*  4 |    HASH JOIN         |          |  7507 |   601K|    59   (0)| 00:00:01 |
|   5 |     TABLE ACCESS FULL| T_HINT02 |  8959 | 26877 |    33   (0)| 00:00:01 |
|   6 |     TABLE ACCESS FULL| T_HINT03 |  7507 |   579K|    26   (0)| 00:00:01 |
---------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("H01"."OBJECT_ID"="H_V"."OBJECT_ID"(+))
   4 - access("H02"."OBJECT_ID"="H03"."OBJECT_ID")

Note
-----
   - dynamic sampling used for this statement (level=2)

Statistics
----------------------------------------------------------
         76  recursive calls
          0  db block gets
        941  consistent gets
          6  physical reads
          0  redo size
     259604  bytes sent via SQL*Net to client
       7717  bytes received via SQL*Net from client
        656  SQL*Net roundtrips to/from client
         14  sorts (memory)
          0  sorts (disk)
       9811  rows processed

--通过merge hint强制转化的视图进行合并失效.
select /*+ merge(h_v)*/ h_v.object_name from t_hint01 h01,(select h03.* from t_hint03 h03,t_hint02 h02 where h02.object_id = h03.object_id) h_v where h01.object_id = h_v.object_id(+);

Execution Plan
----------------------------------------------------------
Plan hash value: 3039741533

---------------------------------------------------------------------------------
| Id  | Operation            | Name     | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------
|   0 | SELECT STATEMENT     |          |  9811 |   785K|    96   (2)| 00:00:02 |
|*  1 |  HASH JOIN OUTER     |          |  9811 |   785K|    96   (2)| 00:00:02 |
|   2 |   TABLE ACCESS FULL  | T_HINT01 |  9811 | 29433 |    36   (0)| 00:00:01 |
|   3 |   VIEW               |          |  7507 |   579K|    59   (0)| 00:00:01 |
|*  4 |    HASH JOIN         |          |  7507 |   601K|    59   (0)| 00:00:01 |
|   5 |     TABLE ACCESS FULL| T_HINT02 |  8959 | 26877 |    33   (0)| 00:00:01 |
|   6 |     TABLE ACCESS FULL| T_HINT03 |  7507 |   579K|    26   (0)| 00:00:01 |
---------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - access("H01"."OBJECT_ID"="H_V"."OBJECT_ID"(+))
   4 - access("H02"."OBJECT_ID"="H03"."OBJECT_ID")

Note
-----
   - dynamic sampling used for this statement (level=2)

Statistics
----------------------------------------------------------
         72  recursive calls
          0  db block gets
       1059  consistent gets
          0  physical reads
          0  redo size
     259604  bytes sent via SQL*Net to client
       7717  bytes received via SQL*Net from client
        656  SQL*Net roundtrips to/from client
         14  sorts (memory)
          0  sorts (disk)
       9811  rows processed

-- 通过push_pred hint 强制谓语推进. 可以看到VIEW PUSHED PREDICATE, 执行计划中视图(h_v)合并查询, 转变成嵌套查询 h03的结果一层层推进到h01中, 从查询效果来看推进后的结果未必优于视图查询
select /*+ push_pred(h_v)*/ h_v.object_name from t_hint01 h01,(select h03.* from t_hint03 h03,t_hint02 h02 where h02.object_id = h03.object_id) h_v where h01.object_id = h_v.object_id(+);

Execution Plan
----------------------------------------------------------
Plan hash value: 3221194107

---------------------------------------------------------------------------------------------
| Id  | Operation                      | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT               |            |  9811 |   680K|   344K  (1)| 01:08:56 |
|   1 |  NESTED LOOPS OUTER            |            |  9811 |   680K|   344K  (1)| 01:08:56 |
|   2 |   TABLE ACCESS FULL            | T_HINT01   |  9811 | 29433 |    36   (0)| 00:00:01 |
|   3 |   VIEW PUSHED PREDICATE        |            |     1 |    68 |    35   (0)| 00:00:01 |
|   4 |    NESTED LOOPS                |            |     1 |    82 |    35   (0)| 00:00:01 |
|   5 |     NESTED LOOPS               |            |     1 |    82 |    35   (0)| 00:00:01 |
|*  6 |      TABLE ACCESS FULL         | T_HINT02   |     1 |     3 |    33   (0)| 00:00:01 |
|*  7 |      INDEX RANGE SCAN          | IDX_OBJ_ID |     1 |       |     1   (0)| 00:00:01 |
|   8 |     TABLE ACCESS BY INDEX ROWID| T_HINT03   |     1 |    79 |     2   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   6 - filter("H02"."OBJECT_ID"="H01"."OBJECT_ID")
   7 - access("H03"."OBJECT_ID"="H01"."OBJECT_ID")
       filter("H02"."OBJECT_ID"="H03"."OBJECT_ID")

Note
-----
   - dynamic sampling used for this statement (level=2)

Statistics
----------------------------------------------------------
          7  recursive calls
          0  db block gets
    1170622  consistent gets
         15  physical reads
          0  redo size
     259604  bytes sent via SQL*Net to client
       7717  bytes received via SQL*Net from client
        656  SQL*Net roundtrips to/from client
          2  sorts (memory)
          0  sorts (disk)
       9811  rows processed

-- 但对于这种明确的视图连接,且带有特定结果过滤的情况, 不需要加push_pred, merge等提示, CBO自己进行视图的合并推进查询
select /*+ push_pred(h_view)*/h01.object_name from t_hint01 h01,h_view h_v where h01.object_id = h_v.object_id(+) and h01.object_id=999;

Elapsed: 00:00:00.02

Execution Plan
----------------------------------------------------------
Plan hash value: 557110784

------------------------------------------------------------------------------------------------
| Id  | Operation                         | Name       | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                  |            |     1 |    23 |    72   (2)| 00:00:01 |
|   1 |  NESTED LOOPS OUTER               |            |     1 |    23 |    72   (2)| 00:00:01 |
|*  2 |   TABLE ACCESS FULL               | T_HINT01   |     1 |    21 |    36   (0)| 00:00:01 |
|   3 |   VIEW PUSHED PREDICATE           | H_VIEW     |     1 |     2 |    36   (3)| 00:00:01 |
|   4 |    SORT UNIQUE                    |            |     1 |   210 |    36   (3)| 00:00:01 |
|*  5 |     FILTER                        |            |       |       |            |          |
|   6 |      MERGE JOIN CARTESIAN         |            |     1 |   210 |    35   (0)| 00:00:01 |
|*  7 |       TABLE ACCESS FULL           | T_HINT02   |     1 |     3 |    33   (0)| 00:00:01 |
|   8 |       BUFFER SORT                 |            |     1 |   207 |     2   (0)| 00:00:01 |
|   9 |        TABLE ACCESS BY INDEX ROWID| T_HINT03   |     1 |   207 |     2   (0)| 00:00:01 |
|* 10 |         INDEX RANGE SCAN          | IDX_OBJ_ID |     1 |       |     1   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("H01"."OBJECT_ID"=999)
   5 - filter("H01"."OBJECT_ID"=999)
   7 - filter("H02"."OBJECT_ID"=999 AND "H02"."OBJECT_ID"="H01"."OBJECT_ID")
  10 - access("H03"."OBJECT_ID"="H01"."OBJECT_ID")
       filter("H03"."OBJECT_ID"=999)

Note
-----
   - dynamic sampling used for this statement (level=2)

Statistics
----------------------------------------------------------
         41  recursive calls
          0  db block gets
        630  consistent gets
          0  physical reads
          0  redo size
        553  bytes sent via SQL*Net to client
        523  bytes received via SQL*Net from client
          2  SQL*Net roundtrips to/from client
          6  sorts (memory)
          0  sorts (disk)
          1  rows processed
