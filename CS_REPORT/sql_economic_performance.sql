set feedback off
col param1 noprint new_value limitday
col param2 noprint new_value stocktype

set verify off
set term off
select to_char('&1') param1 from dual;
select to_char('&2') param2 from dual;
set term on

spool '&3' append
select value from v$parameter where name like 'db_unique%';

select en1.tir_sous_num_tiers_tir as store,
       en1.hsn_date as dates,
       en1.hsn_quantite_stock as qty,
       en1.hsn_valeur_prht as "CP Values",
       en1.hsn_valeur_pvttc as "Retail Price Value",
       en1.hsn_valeur_pvht as "Sale price without tax"
  from stcom.historique_stock_en en1
 where concat(en1.tir_num_tiers_tir, en1.hsn_date) in
       (select concat(a.tir_num_tiers_tir, a.MAX_Date)
          from (select en.tir_num_tiers_tir, max(en.hsn_date) as MAX_Date
                  from stcom.historique_stock_en en
                 where en.org_num_organisation_eln = 2
                   and en.niv_num_niveau_eln = 6
                   and en.eln_num_elt_niveau_eln = 1
                   and en.tir_num_tiers_tir in
                       (select tr.tir_num_tiers
                          from md0000stcom.tiers_ref tr
                         where tr.tti_num_type_tiers_tti = 7
                           and tr.pay_code_pays_pay = 'CN'
                           and tr.dev_code_devise_dev = 'CNY'
                        -- and tr.tir_num_tiers=1270
                        )
                   and en.tys_type_stock_tys = '&&stocktype.'
                   and to_char(en.hsn_date, 'YYYYMMDD') <= '&&limitday.' -- Change Here
                 group by en.tir_num_tiers_tir) a)
   and en1.tys_type_stock_tys = '&&stocktype.'
   and en1.org_num_organisation_eln = 2
   and en1.niv_num_niveau_eln = 6
   and en1.eln_num_elt_niveau_eln = 1
   and en1.tir_sous_num_tiers_tir not in (588,906,915,758,1374,948,911,1201,1215,965,975);
spool off
quit;
