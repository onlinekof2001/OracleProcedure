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
1. 先看自连接查询执行计划
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
                          and tys_type_stock_tys = '01'
                          and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
 group by hse.tir_num_tiers_tir;
 
Execution Plan
----------------------------------------------------------
Plan hash value: 347253727

-----------------------------------------------------------------------------------------------------------
| Id  | Operation                | Name                   | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT         |                        |     1 |    99 |       |   184K  (1)| 00:37:00 |
|   1 |  SORT AGGREGATE          |                        |     1 |    99 |       |            |          |
|*  2 |   HASH JOIN              |                        |   967K|    91M|    79M|   184K  (1)| 00:37:00 |
|   3 |    VIEW                  | VW_SQ_1                |  1077K|    66M|       | 67595   (2)| 00:13:32 |
|   4 |     HASH GROUP BY        |                        |  1077K|    31M|    49M| 67595   (2)| 00:13:32 |
|*  5 |      INDEX FAST FULL SCAN| PK_HISTORIQUE_STOCK_EG |  1077K|    31M|       | 58406   (2)| 00:11:41 |
|*  6 |    TABLE ACCESS FULL     | HISTORIQUE_STOCK_EG    |    19M|   627M|       | 71226   (1)| 00:14:15 |
-----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("HSE"."HSG_DATE"="MAX(HSG_DATE)" AND "ITEM_1"="HSE"."TTI_NUM_TYPE_TIERS_TIR" AND
              "ITEM_2"="HSE"."TIR_NUM_TIERS_TIR" AND "ITEM_3"="HSE"."TIR_SOUS_NUM_TIERS_TIR" AND
              "ITEM_4"="HSE"."ELG_NUM_ELT_GESTION_ELG")
   5 - filter(TRUNC(INTERNAL_FUNCTION("HSG_DATE"))<=TO_DATE('31/07/18','dd/mm/yy') AND
              "TTI_NUM_TYPE_TIERS_TIR"=7 AND "TYS_TYPE_STOCK_TYS"='01')
   6 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND
              "HSE"."TYS_TYPE_STOCK_TYS"='01')   
	   
/* 执行计划3有VIEW关键字，联想到视图合并的概念。这里看到的执行计划是5->4->3先做，并保持结果"原样" 再与外部HISTORIQUE_STOCK_EG联结时，
要对HISTORIQUE_STOCK_EG进行全表扫描，效率低，尝试改写语句进行视图合并看看。
*/   	

select hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value
  from STCOM.historique_stock_eg hse,
       (select max(hsg_date) hsg_date,
	           tti_num_type_tiers_tir,
			   tir_num_tiers_tir,
			   tir_sous_num_tiers_tir,
			   elg_num_elt_gestion_elg
          from stcom.historique_stock_eg
		 group by tti_num_type_tiers_tir,tir_num_tiers_tir,tir_sous_num_tiers_tir,elg_num_elt_gestion_elg) subq_view,
 where hse.tti_num_type_tiers_tir = subq_view.tti_num_type_tiers_tir
   and hse.tir_num_tiers_tir = subq_view.tir_num_tiers_tir
   and hse.tir_sous_num_tiers_tir = subq_view.tir_sous_num_tiers_tir
   and hse.elg_num_elt_gestion_elg = subq_view.elg_num_elt_gestion_elg
   and hse.hsg_date = subq_view.hsg_date
   and hse.tti_num_type_tiers_tir = 7
   and hse.tys_type_stock_tys = '01' --to change 01 or 08
   and trunc(hse.hsg_date) <= to_date('31/07/18', 'dd/mm/yy') -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
 group by hse.tir_num_tiers_tir;   

Execution Plan
----------------------------------------------------------
Plan hash value: 671692866

-----------------------------------------------------------------------------------------------------------
| Id  | Operation                | Name                   | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT         |                        |    37 |  1110 |       |   191K  (1)| 00:38:14 |
|   1 |  HASH GROUP BY           |                        |    37 |  1110 |       |   191K  (1)| 00:38:14 |
|   2 |   VIEW                   | VM_NWVW_1              |   967K|    27M|       |   191K  (1)| 00:38:14 |
|   3 |    HASH GROUP BY         |                        |   967K|    73M|    88M|   191K  (1)| 00:38:14 |
|*  4 |     HASH JOIN            |                        |   967K|    73M|    59M|   173K  (1)| 00:34:39 |
|*  5 |      TABLE ACCESS FULL   | HISTORIQUE_STOCK_EG    |   967K|    47M|       | 71918   (2)| 00:14:24 |
|*  6 |      INDEX FAST FULL SCAN| PK_HISTORIQUE_STOCK_EG |    21M|   575M|       | 57493   (1)| 00:11:30 |
-----------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   4 - access("HSE"."TTI_NUM_TYPE_TIERS_TIR"="TTI_NUM_TYPE_TIERS_TIR" AND
              "HSE"."TIR_NUM_TIERS_TIR"="TIR_NUM_TIERS_TIR" AND
              "HSE"."TIR_SOUS_NUM_TIERS_TIR"="TIR_SOUS_NUM_TIERS_TIR" AND
              "HSE"."ELG_NUM_ELT_GESTION_ELG"="ELG_NUM_ELT_GESTION_ELG")
   5 - filter("HSE"."HSG_QUANTITE_STOCK"<>0 AND TRUNC(INTERNAL_FUNCTION("HSE"."HSG_DATE"))<=TO_DATE
              ('31/07/18','dd/mm/yy') AND "HSE"."TTI_NUM_TYPE_TIERS_TIR"=7 AND "HSE"."TYS_TYPE_STOCK_TYS"='01')
   6 - filter("TTI_NUM_TYPE_TIERS_TIR"=7)
   
/* 视图合并后的执行计划效率没有发生显著的改变, 对HISTORIQUE_STOCK_EG表的查询又全表扫描变成了全索引快速扫描, 从执行计划的时间上看消耗差不多。
但是加上tiers_ref后从执行计划上看，性能有所改善。 
*/ 

select hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value
  from STCOM.historique_stock_eg hse,
       (select max(hsg_date) hsg_date,
	           tti_num_type_tiers_tir,
			   tir_num_tiers_tir,
			   tir_sous_num_tiers_tir,
			   elg_num_elt_gestion_elg
          from stcom.historique_stock_eg
		 where tys_type_stock_tys = '01' 
		   and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')
		 group by tti_num_type_tiers_tir,tir_num_tiers_tir,tir_sous_num_tiers_tir,elg_num_elt_gestion_elg) subq_view,
		 md0000stcom.tiers_ref r
 where hse.tti_num_type_tiers_tir = subq_view.tti_num_type_tiers_tir
   and hse.tir_num_tiers_tir = subq_view.tir_num_tiers_tir
   and hse.tir_sous_num_tiers_tir = subq_view.tir_sous_num_tiers_tir
   and hse.elg_num_elt_gestion_elg = subq_view.elg_num_elt_gestion_elg
   and hse.hsg_date = subq_view.hsg_date
   and hse.tir_sous_num_tiers_tir = r.tir_sous_num_tiers
   and r.dev_code_devise_dev = 'CNY'
   and r.pay_code_pays_pay = 'CN'
   and r.tti_num_type_tiers_tti = 7
   and hse.tti_num_type_tiers_tir = 7
   and hse.tys_type_stock_tys = '01' --to change 01 or 08
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
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
*/

with
    t1 as 
	(select tir_num_tiers_tir,hsg_quantite_stock,hsg_dernier_prmp_connu,tir_sous_num_tiers_tir
       from STCOM.historique_stock_eg hse 
      where hse.tti_num_type_tiers_tir = 7
        and hse.tys_type_stock_tys = '01'
        and hse.hsg_date = (select max(hsg_date)
                              from stcom.historique_stock_eg
                             where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                               and tir_num_tiers_tir = hse.tir_num_tiers_tir
                               and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                               and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                               and tys_type_stock_tys = '01'
                               and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')) -- to change
        and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
    ),
	t2 as
	(select tir_sous_num_tiers
   	   from md0000stcom.tiers_ref r
	  where r.dev_code_devise_dev = 'CNY'
        and r.pay_code_pays_pay = 'CN'
        and r.tti_num_type_tiers_tti = 7
	)
select t1.tir_num_tiers_tir "store_number",
       sum(t1.hsg_quantite_stock * t1.hsg_dernier_prmp_connu) as Stock_value
  from t1,t2
 group by t1.tir_num_tiers_tir;
 
 
with
    t1 as 
	(select tir_num_tiers_tir,hsg_quantite_stock,hsg_dernier_prmp_connu,tir_sous_num_tiers_tir,hsg_date
       from STCOM.historique_stock_eg hse 
	  inner join md0000stcom.tiers_ref r
     	 on r.tir_sous_num_tiers = hse.tir_sous_num_tiers_tir
      where r.dev_code_devise_dev = 'CNY'
        and r.pay_code_pays_pay = 'CN'
        and r.tti_num_type_tiers_tti = 7
		and hse.tti_num_type_tiers_tir = 7
        and hse.tys_type_stock_tys = '01'
        and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
    ),
	t2 as
	(select max(hsg_date) hsg_date,
	        tti_num_type_tiers_tir,
			tir_num_tiers_tir,
			tir_sous_num_tiers_tir,
			elg_num_elt_gestion_elg
       from stcom.historique_stock_eg
	  where tys_type_stock_tys = '01'
        and trunc(hsg_date) <= to_date('31/07/18', 'dd/mm/yy')
	  group by tti_num_type_tiers_tir,tir_num_tiers_tir,tir_sous_num_tiers_tir,elg_num_elt_gestion_elg
	)
select t1.tir_num_tiers_tir "store_number",
       sum(t1.hsg_quantite_stock * t1.hsg_dernier_prmp_connu) as Stock_value
  from t1,t2
  where t1.hsg_date = (select max(hsg_date)
                              from t2
                             where tti_num_type_tiers_tir = t2.tti_num_type_tiers_tir
                               and tir_num_tiers_tir = t2.tir_num_tiers_tir
                               and tir_sous_num_tiers_tir = t2.tir_sous_num_tiers_tir
                               and elg_num_elt_gestion_elg = t2.elg_num_elt_gestion_elg)
 group by t1.tir_num_tiers_tir;