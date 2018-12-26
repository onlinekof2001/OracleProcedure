spool '&1' append
select value from v$parameter where name like 'db_unique%';

select egm.tir_sous_num_tiers_tir as stores,
       count(distinct fs.eln_num_elt_niveau_fam) as total_family
  from stcom.elt_gestion_magasin egm inner join masterdatas.tiers_ref tr 
    on egm.tir_sous_num_tiers_tir = tr.tir_sous_num_tiers
       inner join masterdatas.flat_structure fs
    on egm.elg_num_elt_gestion_elg = fs.elg_num_elt_gestion_elg
 where tr.pay_code_pays_pay = 'CN' -- China
   and tr.dev_code_devise_dev = 'CNY'
   and egm.pgs_type_planification_pgs = 01 -- Carried
 group by egm.tir_sous_num_tiers_tir
 order by egm.tir_sous_num_tiers_tir;
spool off
quit;
