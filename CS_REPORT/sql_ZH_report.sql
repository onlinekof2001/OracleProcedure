spool '&1' append
select value from v$parameter where name like 'db_unique%';

select fs.fst_article_r3 as article, hsg.hsg_quantite_stock as stock, cpp.cpr_vente_ttc as price
from STCOM.historique_stock_eg hsg 
inner join MD0000STCOM.flat_structure fs on fs.elg_num_elt_gestion_elg = hsg.elg_num_elt_gestion_elg 
inner join stcom.current_prices_pos cpp on fs.elg_num_elt_gestion_elg = cpp.elg_num_elt_gestion_uma
where hsg.tti_num_type_tiers_tir = 7
and hsg.tir_num_tiers_tir = 685
and hsg.tir_sous_num_tiers_tir = 685
and cpp.tti_num_type_tiers_tir = 7
and cpp.tir_num_tiers_tir = 685
and cpp.tir_sous_num_tiers_tir = 685
and fs.eln_num_elt_niveau_uni not in (14,89,90) -- atelier, agencement, services
and fs.eln_num_elt_niveau_ssr not in (1962,2699) -- munitions 
and fs.eln_num_elt_niveau_fam not in (5152,10773) -- commande directe, vide
and hsg_flag_actif = 'Y'
and tys_type_stock_tys = '01'
and hsg_quantite_stock >0;

spool off
quit;

