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

select rna_date_creation,
       s.obl_id_objet_obd,
       s.tir_num_tiers_mag,
       obld.obd_code_article_fournisseur,
       s.rna_qte_rectif,
       obld.obd_quantite_article,
       obld.obd_quantite_article_confirme,
       obld.obd_prix_reception
  from stcom.rectif_navette s, stcom.objet_logistique_detail obld
 where s.rna_date_creation between to_date('&&startday.', 'yyyy-mm-dd hh24:mi:ss') and -- Change here
       to_date('&&enday.', 'yyyy-mm-dd hh24:mi:ss')  -- Change here
   and obld.obl_id_objet_obl = s.obl_id_objet_obd
   and obld.obd_num_ligne = s.obd_num_ligne_obd;
spool off
quit;
