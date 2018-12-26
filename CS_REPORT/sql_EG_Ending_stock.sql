set feedback off
col param2 noprint new_value stocktype
col param1 noprint new_value limitday

set verify off
set term off
select to_char('&1') param1 from dual;
set term on
set verify off
set term off
select to_char('&2') param2 from dual;
set term on

spool '&3' append
select value from v$parameter where name like 'db_unique%';

select /*+ push_subq (@qb1)*/ hse.tir_num_tiers_tir "store_number",
       sum(hse.hsg_quantite_stock * hse.hsg_dernier_prmp_connu) as Stock_value,
       sum(hse.hsg_quantite_stock) Stock_quantity
  from STCOM.historique_stock_eg hse inner join masterdatas.tiers_ref r
    on r.tir_sous_num_tiers = hse.tir_sous_num_tiers_tir
 where hse.tti_num_type_tiers_tir = 7
   and r.dev_code_devise_dev = 'CNY'
   and r.pay_code_pays_pay = 'CN'
   and r.tti_num_type_tiers_tti = 7
   and hse.tys_type_stock_tys = '&&stocktype.' --to change 01 or 08
   and hse.hsg_date = (select /*+ qb_name (qb1)*/ max(hsg_date)
                         from STCOM.historique_stock_eg
                        where tti_num_type_tiers_tir = hse.tti_num_type_tiers_tir
                          and tir_num_tiers_tir = hse.tir_num_tiers_tir
                          and tir_sous_num_tiers_tir = hse.tir_sous_num_tiers_tir
                          and elg_num_elt_gestion_elg = hse.elg_num_elt_gestion_elg
                          and tys_type_stock_tys = '&&stocktype.'
                          and trunc(hsg_date) <= to_date('&&limitday.', 'dd/mm/yy')) -- to change
   and ((1 = 1 and hse.hsg_quantite_stock <> 0) or (1 = 0))
 group by hse.tir_num_tiers_tir;
spool off
