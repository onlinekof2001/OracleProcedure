set feedback off
col param1 noprint new_value startday
col param2 noprint new_value enday

set verify off
set term off
select to_char('&1') param1 from dual;
select to_char('&2') param2 from dual;
set term on

spool '&3' append
select value from v$parameter where name like 'db_unique%';

select distinct msk.tir_num_tiers_tir,
       fls.fst_article_r3,
       msk.msk_reference_operation,
       msk.msk_date_mouvement,
       msk.msk_quantite,
       msk.msk_prix_operation
 from stcom.mouvement_stock msk, masterdatas.flat_structure fls
where msk.nmv_code_nature_mouvement_nmv = '046'
  and msk.msk_date_mouvement between to_date('&&startday.', 'yyyy-mm-dd hh24:mi:ss') and -- Change here
      to_date('&&enday.', 'yyyy-mm-dd hh24:mi:ss') -- Change here
  and fls.elg_num_elt_gestion_elg = msk.elg_num_elt_gestion_elg;
spool off
quit;
