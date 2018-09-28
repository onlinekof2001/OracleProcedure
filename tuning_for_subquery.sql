select hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value
  from STCOM.historique_stock_eg hse 
 inner join md0000stcom.tiers_ref r
	on r.tir_sous_num_tiers = hse.tir_sous_num_tiers_tir
 where hse.tti_num_type_tiers_tir = 7
   and r.dev_code_devise_dev = 'CNY'
   and r.pay_code_pays_pay = 'CN'
   and r.tti_num_type_tiers_tti = 7
   and hse.tys_type_stock_tys = '01' --to change 01 or 08
   and hse.hsg_date = (select max(hsg_date)
                         from stcom.historique_stock_eg
                        where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                          and tir_num_tiers_tir = hse.tir_num_tiers_tir
                          and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                          and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                          and tys_type_stock_tys = '01'
                          and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
 group by hse.tir_num_tiers_tir;

Execution Plan
----------------------------------------------------------
Plan hash value: 1927259289

---------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name                   | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |                        |     2 |    60 |   144K  (1)| 00:19:18 |
|   1 |  HASH GROUP BY                       |                        |     2 |    60 |   144K  (1)| 00:19:18 |
|   2 |   VIEW                               | VM_NWVW_2              |     2 |    60 |   144K  (1)| 00:19:18 |
|*  3 |    FILTER                            |                        |       |       |            |          |
|   4 |     HASH GROUP BY                    |                        |     2 |   220 |   144K  (1)| 00:19:18 |
|   5 |      NESTED LOOPS                    |                        |  1001 |   107K|   144K  (1)| 00:19:18 |
|*  6 |       HASH JOIN                      |                        | 17972 |  1386K| 90698   (1)| 00:12:06 |
|   7 |        MAT_VIEW ACCESS BY INDEX ROWID| TIERS_REF              |    35 |   945 |    11   (0)| 00:00:01 |
|*  8 |         INDEX RANGE SCAN             | IDX02_TTI_PAY_DEV      |    35 |       |     3   (0)| 00:00:01 |
|*  9 |        TABLE ACCESS FULL             | HISTORIQUE_STOCK_EG    |    19M|   959M| 90601   (1)| 00:12:05 |
|* 10 |       INDEX RANGE SCAN               | PK_HISTORIQUE_STOCK_EG |     1 |    31 |     3   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - filter("HSE"."HSG_DATE"=MAX("HSG_DATE"))
   6 - access("R"."TIR_SOUS_NUM_TIERS"="HSE"."TIR_SOUS_NUM_TIERS_TIR")
   8 - access("R"."TTI_NUM_TYPE_TIERS_TTI"=7 AND "R"."PAY_CODE_PAYS_PAY"='CN' AND
              "R"."DEV_CODE_DEVISE_DEV"='CNY')
   9 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND
              "HSE"."TYS_TYPE_STOCK_TYS"='01')
  10 - access("TTI_NUM_TYPE_TIERS_TIR"=7 AND "TIR_NUM_TIERS_TIR"="HSE"."TIR_NUM_TIERS_TIR" AND
              "TIR_SOUS_NUM_TIERS_TIR"="HSE"."TIR_SOUS_NUM_TIERS_TIR" AND
              "ELG_NUM_ELT_GESTION_ELG"="HSE"."ELG_NUM_ELT_GESTION_ELG" AND "TYS_TYPE_STOCK_TYS"='01')
       filter(TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy'))
  
/* 执行计划顺序是 8->7->9, 索引扫描TIERS_REF表获得记录集再与HISTORIQUE_STOCK_EG关联获取结果集后，最后与子查询中的HISTORIQUE_STOCK_EG关联，
聚合计算满足max()条件的结果集。关键消耗时间查询在9，这里全表扫描获取19M数据，怎么能减少这部分的消耗成为关键！
1. 先看自连接查询执行计划(我这里做了一个变形，子查询和外部查询都用了相同的字段tys_type_stock_tys，取值也一样。)
*/   

select hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value
  from STCOM.historique_stock_eg hse 
 where hse.tti_num_type_tiers_tir = 7
   and hse.tys_type_stock_tys = '01' --to change 01 or 08
   and hse.hsg_date = (select max(hsg_date)
                         from stcom.historique_stock_eg
                        where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                          and tir_num_tiers_tir = hse.tir_num_tiers_tir
                          and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                          and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                          and tys_type_stock_tys = hse.tys_type_stock_tys
                          and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
 group by hse.tir_num_tiers_tir;
 
Execution Plan
----------------------------------------------------------
Plan hash value: 3726287240

-----------------------------------------------------------------------------------------------------------
| Id  | Operation                | Name                   | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT         |                        |    37 |  2701 |       |   195K  (1)| 00:39:06 |
|   1 |  HASH GROUP BY           |                        |    37 |  2701 |       |   195K  (1)| 00:39:06 |
|*  2 |   HASH JOIN              |                        |  1007K|    70M|    48M|   195K  (1)| 00:39:06 |
|   3 |    VIEW                  | VW_SQ_1                |  1122K|    35M|       | 69855   (2)| 00:13:59 |
|   4 |     HASH GROUP BY        |                        |  1122K|    33M|    51M| 69855   (2)| 00:13:59 |
|*  5 |      INDEX FAST FULL SCAN| PK_HISTORIQUE_STOCK_EG |  1122K|    33M|       | 60282   (2)| 00:12:04 |
|*  6 |    TABLE ACCESS FULL     | HISTORIQUE_STOCK_EG    |    20M|   768M|       | 73528   (1)| 00:14:43 |
-----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("HSE"."HSG_DATE"="MAX(HSG_DATE)" AND "ITEM_1"="HSE"."TTI_NUM_TYPE_TIERS_TIR" AND
              "ITEM_2"="HSE"."TIR_NUM_TIERS_TIR" AND "ITEM_3"="HSE"."TIR_SOUS_NUM_TIERS_TIR" AND
              "ITEM_4"="HSE"."ELG_NUM_ELT_GESTION_ELG" AND "ITEM_5"="HSE"."TYS_TYPE_STOCK_TYS")
   5 - filter(TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy') AND
              "TTI_NUM_TYPE_TIERS_TIR"=7 AND "TYS_TYPE_STOCK_TYS"='01')
   6 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND
              "HSE"."TYS_TYPE_STOCK_TYS"='01')

			  
/* 执行计划3有VIEW关键字，联想到视图合并的概念。这里看到的执行计划是5->4->3先做，并保持结果"原样" 再与外部HISTORIQUE_STOCK_EG联结时，
要对HISTORIQUE_STOCK_EG进行全表扫描，效率低。
*/   	

select hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value
  from STCOM.historique_stock_eg hse 
 where hse.tti_num_type_tiers_tir = 7
   and hse.tys_type_stock_tys = '01' --to change 01 or 08
   and hse.hsg_date = (select /*+ MERGE*/ max(hsg_date)
                         from stcom.historique_stock_eg
                        where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                          and tir_num_tiers_tir = hse.tir_num_tiers_tir
                          and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                          and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                          and tys_type_stock_tys = hse.tys_type_stock_tys
                          and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
 group by hse.tir_num_tiers_tir;

Execution Plan
----------------------------------------------------------
Plan hash value: 1083579351

------------------------------------------------------------------------------------------------------------
| Id  | Operation                 | Name                   | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT          |                        |    37 |  1110 |       |   197K  (1)| 00:39:27 |
|   1 |  HASH GROUP BY            |                        |    37 |  1110 |       |   197K  (1)| 00:39:27 |
|   2 |   VIEW                    | VM_NWVW_1              |  1779 | 53370 |       |   197K  (1)| 00:39:27 |
|*  3 |    FILTER                 |                        |       |       |       |            |          |
|   4 |     HASH GROUP BY         |                        |  1779 |   144K|       |   197K  (1)| 00:39:27 |
|*  5 |      HASH JOIN            |                        |  1122K|    88M|    46M|   197K  (1)| 00:39:27 |
|*  6 |       INDEX FAST FULL SCAN| PK_HISTORIQUE_STOCK_EG |  1122K|    33M|       | 60282   (2)| 00:12:04 |
|*  7 |       TABLE ACCESS FULL   | HISTORIQUE_STOCK_EG    |    20M|   999M|       | 73528   (1)| 00:14:43 |
------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - filter("HSE"."HSG_DATE"=MAX("HSG_DATE"))
   5 - access("HSE"."TTI_NUM_TYPE_TIERS_TIR"="TTI_NUM_TYPE_TIERS_TIR" AND
              "HSE"."TIR_NUM_TIERS_TIR"="TIR_NUM_TIERS_TIR" AND
              "HSE"."TIR_SOUS_NUM_TIERS_TIR"="TIR_SOUS_NUM_TIERS_TIR" AND
              "HSE"."ELG_NUM_ELT_GESTION_ELG"="ELG_NUM_ELT_GESTION_ELG" AND
              "HSE"."TYS_TYPE_STOCK_TYS"="TYS_TYPE_STOCK_TYS")
   6 - filter(TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy') AND
              "TTI_NUM_TYPE_TIERS_TIR"=7 AND "TYS_TYPE_STOCK_TYS"='01')
   7 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND
              "HSE"."TYS_TYPE_STOCK_TYS"='01')

   
/* 强制视图合并后的执行计划效率反而更差了
*/ 

select hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value
  from STCOM.historique_stock_eg hse,
       md0000stcom.tiers_ref r 
 where hse.tti_num_type_tiers_tir = 7
   and r.dev_code_devise_dev = 'CNY'
   and r.pay_code_pays_pay = 'CN'
   and r.tti_num_type_tiers_tti = 7
   and hse.tys_type_stock_tys = '01' --to change 01 or 08
   and hse.hsg_date = (select /*+ MERGE*/ max(hsg_date)
                         from stcom.historique_stock_eg
                        where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                          and tir_num_tiers_tir = hse.tir_num_tiers_tir
                          and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                          and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                          and tys_type_stock_tys = '01'
                          and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
   and r.tir_sous_num_tiers = hse.tir_sous_num_tiers_tir(+)
 group by hse.tir_num_tiers_tir;

Execution Plan
----------------------------------------------------------
Plan hash value: 4087537689

---------------------------------------------------------------------------------------------------------------
| Id  | Operation                            | Name                   | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                     |                        |     2 |    60 |   125K  (1)| 00:25:04 |
|   1 |  HASH GROUP BY                       |                        |     2 |    60 |   125K  (1)| 00:25:04 |
|   2 |   VIEW                               | VM_NWVW_1              |     2 |    60 |   125K  (1)| 00:25:04 |
|*  3 |    FILTER                            |                        |       |       |            |          |
|   4 |     HASH GROUP BY                    |                        |     2 |   220 |   125K  (1)| 00:25:04 |
|   5 |      NESTED LOOPS                    |                        |  1001 |   107K|   125K  (1)| 00:25:04 |
|*  6 |       HASH JOIN                      |                        | 17972 |  1386K| 71361   (1)| 00:14:17 |
|   7 |        MAT_VIEW ACCESS BY INDEX ROWID| TIERS_REF              |    35 |   945 |    11   (0)| 00:00:01 |
|*  8 |         INDEX RANGE SCAN             | IDX02_TTI_PAY_DEV      |    35 |       |     3   (0)| 00:00:01 |
|*  9 |        TABLE ACCESS FULL             | HISTORIQUE_STOCK_EG    |    19M|   959M| 71294   (1)| 00:14:16 |
|* 10 |       INDEX RANGE SCAN               | PK_HISTORIQUE_STOCK_EG |     1 |    31 |     3   (0)| 00:00:01 |
---------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   3 - filter("HSE"."HSG_DATE"=MAX("HSG_DATE"))
   6 - access("HSE"."TIR_SOUS_NUM_TIERS_TIR"="R"."TIR_SOUS_NUM_TIERS")
   8 - access("R"."TTI_NUM_TYPE_TIERS_TTI"=7 AND "R"."PAY_CODE_PAYS_PAY"='CN' AND
              "R"."DEV_CODE_DEVISE_DEV"='CNY')
   9 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND
              "HSE"."TYS_TYPE_STOCK_TYS"='01')
  10 - access("TTI_NUM_TYPE_TIERS_TIR"=7 AND "HSE"."TIR_NUM_TIERS_TIR"="TIR_NUM_TIERS_TIR" AND
              "HSE"."TIR_SOUS_NUM_TIERS_TIR"="TIR_SOUS_NUM_TIERS_TIR" AND
              "HSE"."ELG_NUM_ELT_GESTION_ELG"="ELG_NUM_ELT_GESTION_ELG" AND "TYS_TYPE_STOCK_TYS"='01')
       filter(TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy'))	  

/* 尝试子查询解嵌套直接优化，通过提示PUSH_SUBQ/NO_PUSH_SUBQ将子查询提前进行评估
*/

select /*+ PUSH_SUBQ (@qb1)*/ hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value
  from STCOM.historique_stock_eg hse 
 inner join md0000stcom.tiers_ref r
	on r.tir_sous_num_tiers = hse.tir_sous_num_tiers_tir
 where hse.tti_num_type_tiers_tir = 7
   and r.dev_code_devise_dev = 'CNY'
   and r.pay_code_pays_pay = 'CN'
   and r.tti_num_type_tiers_tti = 7
   and hse.tys_type_stock_tys = '01' --to change 01 or 08
   and hse.hsg_date = (select /*+ qb_name (qb1)*/ max(hsg_date)
                         from stcom.historique_stock_eg
                        where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                          and tir_num_tiers_tir = hse.tir_num_tiers_tir
                          and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                          and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                          and tys_type_stock_tys = '01'
                          and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
 group by hse.tir_num_tiers_tir;
 
Execution Plan
----------------------------------------------------------
Plan hash value: 4219159819

------------------------------------------------------------------------------------------------------------
| Id  | Operation                         | Name                   | Rows  | Bytes | Cost (%CPU)| Time     |
------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                  |                        |    29 |  1595 | 71270   (1)| 00:14:16 |
|   1 |  HASH GROUP BY                    |                        |    29 |  1595 | 71270   (1)| 00:14:16 |
|*  2 |   FILTER                          |                        |       |       |            |          |
|*  3 |    HASH JOIN                      |                        |    29 |  1595 | 71265   (1)| 00:14:16 |
|   4 |     MAT_VIEW ACCESS BY INDEX ROWID| TIERS_REF              |    35 |   525 |    11   (0)| 00:00:01 |
|*  5 |      INDEX RANGE SCAN             | IDX02_TTI_PAY_DEV      |    35 |       |     3   (0)| 00:00:01 |
|*  6 |     TABLE ACCESS FULL             | HISTORIQUE_STOCK_EG    | 31303 |  1222K| 71254   (1)| 00:14:16 |
|   7 |    SORT AGGREGATE                 |                        |     1 |    31 |            |          |
|   8 |     FIRST ROW                     |                        |     1 |    31 |     4   (0)| 00:00:01 |
|*  9 |      INDEX RANGE SCAN (MIN/MAX)   | PK_HISTORIQUE_STOCK_EG |     1 |    31 |     4   (0)| 00:00:01 |
------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter("HSE"."HSG_DATE"= (SELECT /*+ PUSH_SUBQ QB_NAME ("QB1") */ MAX("HSG_DATE") FROM
              "STCOM"."HISTORIQUE_STOCK_EG" "HISTORIQUE_STOCK_EG" WHERE "TYS_TYPE_STOCK_TYS"='01' AND
              "ELG_NUM_ELT_GESTION_ELG"=:B1 AND "TIR_SOUS_NUM_TIERS_TIR"=:B2 AND "TIR_NUM_TIERS_TIR"=:B3 AND
              "TTI_NUM_TYPE_TIERS_TIR"=:B4 AND TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy'
              )))
   3 - access("R"."TIR_SOUS_NUM_TIERS"="HSE"."TIR_SOUS_NUM_TIERS_TIR")
   5 - access("R"."TTI_NUM_TYPE_TIERS_TTI"=7 AND "R"."PAY_CODE_PAYS_PAY"='CN' AND
              "R"."DEV_CODE_DEVISE_DEV"='CNY')
   6 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND
              "HSE"."TYS_TYPE_STOCK_TYS"='01')
   9 - access("TTI_NUM_TYPE_TIERS_TIR"=:B1 AND "TIR_NUM_TIERS_TIR"=:B2 AND
              "TIR_SOUS_NUM_TIERS_TIR"=:B3 AND "ELG_NUM_ELT_GESTION_ELG"=:B4 AND "TYS_TYPE_STOCK_TYS"='01')
       filter(TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy'))
	   
/* 添加提示后，发现子查询步骤9->8->7被推进到了外部优先查询, 这里嵌套查询两张表使用了绑定变量合并成一个查询。尝试子查询分解
以下思路均不对, 效果更差。
*/

with
    t1 as 
	(select hse.tir_num_tiers_tir STORE_NUMBER,
            sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as STOCK_VALUE,
			hse.tir_sous_num_tiers_tir
       from STCOM.historique_stock_eg hse 
      where hse.tti_num_type_tiers_tir = 7
        and hse.tys_type_stock_tys = '01'
        and hse.hsg_date = (select max(hsg_date)
                              from stcom.historique_stock_eg
                             where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                               and tir_num_tiers_tir = hse.tir_num_tiers_tir
                               and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                               and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                               and tys_type_stock_tys = hse.tys_type_stock_tys							
                               and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
        and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
      group by hse.tir_num_tiers_tir,hse.tir_sous_num_tiers_tir
    ),
	t2 as
	(select tir_sous_num_tiers
   	   from md0000stcom.tiers_ref r
	  where r.dev_code_devise_dev = 'CNY'
        and r.pay_code_pays_pay = 'CN'
        and r.tti_num_type_tiers_tti = 7
	)
select t1.STORE_NUMBER,
       t1.STOCK_VALUE
  from t1,t2
  where t1.tir_sous_num_tiers_tir = t2.tir_sous_num_tiers;
 
Execution Plan
----------------------------------------------------------
Plan hash value: 4034270401

--------------------------------------------------------------------------------------------------------------------
| Id  | Operation                         | Name                   | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                  |                        |   930 | 93000 |       |   143K  (2)| 00:28:42 |
|   1 |  HASH GROUP BY                    |                        |   930 | 93000 |       |   143K  (2)| 00:28:42 |
|*  2 |   HASH JOIN                       |                        |   930 | 93000 |       |   143K  (2)| 00:28:42 |
|*  3 |    HASH JOIN                      |                        | 18616 |  1218K|       | 73598   (1)| 00:14:44 |
|   4 |     MAT_VIEW ACCESS BY INDEX ROWID| TIERS_REF              |    36 |   972 |       |    11   (0)| 00:00:01 |
|*  5 |      INDEX RANGE SCAN             | IDX02_TTI_PAY_DEV      |    36 |       |       |     3   (0)| 00:00:01 |
|*  6 |     TABLE ACCESS FULL             | HISTORIQUE_STOCK_EG    |    20M|   768M|       | 73528   (1)| 00:14:43 |
|   7 |    VIEW                           | VW_SQ_1                |  1122K|    35M|       | 69855   (2)| 00:13:59 |
|   8 |     HASH GROUP BY                 |                        |  1122K|    33M|    51M| 69855   (2)| 00:13:59 |
|*  9 |      INDEX FAST FULL SCAN         | PK_HISTORIQUE_STOCK_EG |  1122K|    33M|       | 60282   (2)| 00:12:04 |
--------------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("HSE"."HSG_DATE"="MAX(HSG_DATE)" AND "ITEM_1"="HSE"."TTI_NUM_TYPE_TIERS_TIR" AND
              "ITEM_2"="HSE"."TIR_NUM_TIERS_TIR" AND "ITEM_3"="HSE"."TIR_SOUS_NUM_TIERS_TIR" AND
              "ITEM_4"="HSE"."ELG_NUM_ELT_GESTION_ELG" AND "ITEM_5"="HSE"."TYS_TYPE_STOCK_TYS")
   3 - access("HSE"."TIR_SOUS_NUM_TIERS_TIR"="TIR_SOUS_NUM_TIERS")
   5 - access("R"."TTI_NUM_TYPE_TIERS_TTI"=7 AND "R"."PAY_CODE_PAYS_PAY"='CN' AND
              "R"."DEV_CODE_DEVISE_DEV"='CNY')
   6 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND
              "HSE"."TYS_TYPE_STOCK_TYS"='01')
   9 - filter(TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy') AND
              "TTI_NUM_TYPE_TIERS_TIR"=7 AND "TYS_TYPE_STOCK_TYS"='01')