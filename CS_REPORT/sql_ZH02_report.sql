spool '&1' append
select value from v$parameter where name like 'db_unique%';

select trim(fs.fst_article_r3 || ',' || ms.msk_date_mouvement || ',' ||
            ms.msk_quantite || ',' || ms.msk_stock_avant_mvt || ',' ||
            ms.msk_user) as csv_column
  from stcom.mouvement_stock ms
 inner join flat_structure fs
    on ms.elg_num_elt_gestion_elg = fs.elg_num_elt_gestion_elg
 where ms.tir_sous_num_tiers_tir = 685
   and to_char(ms.msk_date_mouvement, 'YYYYMMDD') =
       to_char(sysdate, 'YYYYMMDD')
   and ms.nmv_code_nature_mouvement_nmv = '042'
   and ms.msk_quantite < 0
   and ms.tys_type_stock_tys = '01';

spool off
quit;
