SELECT msk.tir_num_tiers_tir,
       SUM(msk.msk_quantite) as ECART_QUANTITE_RELATIVE,
       SUM(abs(msk.msk_quantite)) as ECART_QUANTITE_ABSOLUE,
       SUM(eg.hsg_dernier_prmp_connu * msk.msk_quantite) as ECART_VALEUR_RELATIVE,
       SUM(eg.hsg_dernier_prmp_connu * abs(msk.msk_quantite)) as ECART_VALEUR_ABSOLUE
  FROM stcom.mouvement_stock msk
 INNER JOIN stcom.ecart_qte_prix eqp ON eqp.eqp_last_mvt_id = msk.msk_id
                                     AND eqp.eqp_num_article = msk.elg_num_elt_gestion_elg
                                     AND eqp.eqp_num_tiers_mag = msk.tir_num_tiers_tir
  LEFT OUTER JOIN stcom.historique_stock_eg eg ON eg.tti_num_type_tiers_tir = msk.tti_num_type_tiers_tir
                                        AND eg.tir_num_tiers_tir = msk.tir_num_tiers_tir
                                        AND eg.tir_sous_num_tiers_tir = msk.tir_sous_num_tiers_tir
                                        AND eg.elg_num_elt_gestion_elg = msk.elg_num_elt_gestion_elg
                                        AND eg.tys_type_stock_tys = msk.tys_type_stock_tys
 INNER JOIN masterdatas.flat_structure fs ON fs.elg_num_elt_gestion_elg =  msk.elg_num_elt_gestion_elg
  LEFT OUTER JOIN masterdatas.element_gestion ge ON ge.elg_num_elt_gestion =  msk.elg_num_elt_gestion_elg
 WHERE msk.tir_num_tiers_tir in
       (select t.tir_num_tiers
          from masterdatas.tiers_ref t
         where t.tti_num_type_tiers_tti = 7
           and t.pay_code_pays_pay = 'CN'
           and t.dev_code_devise_dev = 'CNY')
   AND msk.msk_quantite <> 0
   AND msk.msk_flag_stock in ('0', '1', '2', '10')     
   AND ge.nat_num_nature_nat = '2'
   AND msk.nmv_code_nature_mouvement_nmv IN
       ('040', '043', '041', '045', '042')
   AND msk_date_mouvement >= to_timestamp('20170101','yyyymmdd') 
   AND msk_date_mouvement < to_timestamp('20171130','yyyymmdd') 
   AND eg.tys_type_stock_tys = '01'
   AND eg.hsg_date =
       (select max(HSG_DATE)
          from stcom.HISTORIQUE_STOCK_EG
         where TTI_NUM_TYPE_TIERS_TIR = eg.TTI_NUM_TYPE_TIERS_TIR
           and TIR_NUM_TIERS_TIR = eg.TIR_NUM_TIERS_TIR
           and TIR_SOUS_NUM_TIERS_TIR = eg.TIR_SOUS_NUM_TIERS_TIR
           and ELG_NUM_ELT_GESTION_ELG = eg.ELG_NUM_ELT_GESTION_ELG
           and TYS_TYPE_STOCK_TYS = '01'
           and HSG_DATE <= msk.msk_date_mouvement)
 group by msk.tir_num_tiers_tir;
