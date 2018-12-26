col Active_Flag for a11
col Tax_Type for a8
col Sale_Flag for a9
col Barcode_1 for a15
col Alternate_Code for a15
col Class_ID for a8
col Color_Highlight for a16
col Supplier_ID for a12
col Reorder_Quantity for a17
col Track_Expiry for a13
col Warranty_Duration for a18
col Duration_Type for a14
col Category_1 for a11
col Category_2 for a11
col Category_3 for a11
col Category_4 for a11
col Category_5 for a11
col Category_6 for a11
SELECT DISTINCT code_article.cof_code_fournisseur mst_product_05,
                DECODE(lib_modele.lit_libelle_long,
                       '',
                       lib_modele2.lit_libelle_long,
                       lib_modele.lit_libelle_long) || ' / ' ||
                DECODE(lib_grille.lit_libelle_long,
                       '',
                       lib_grille2.lit_libelle_long,
                       lib_grille.lit_libelle_long) Product_Name,
                '1' Active_Flag,
                'MODEL: ' || code_modele.cof_code_fournisseur ||
                ' / FAMI: ' ||
                DECODE(lib_famille.lit_libelle_long,
                       '',
                       lib_famille2.lit_libelle_long,
                       lib_famille.lit_libelle_long) Memo,
                '0' Tax_Type,
                '1' Sale_Flag,
                'PCS'Unit_of_Measure_ID,
                NVl(pu.pri_valeur_prix,cpp.cpr_vente_ttc)DMI_Price_Per_Piece,
                cpp.cpr_vente_ttc Stcom_Cost_Per_Piece,
                m.mrq_libelle_marque || '_' ||
                DECODE(lib_modele.lit_libelle_long,
                       '',
                       lib_modele2.lit_libelle_long,
                       lib_modele.lit_libelle_long) Generic_Name,
                cp.cop_code_physique Barcode_1,'' Barcode_1,'' Barcode_1, '' Alternate_Code, '0' Product_Type,
                'BASE' Class_ID, '0' Color_Highlight, '0' Supplier_ID, '0' Reorder_Quantity,
                '0' Track_Expiry, '0' Track_Warranty, '0' Warranty_Duration, '' Duration_Type,
                '' Category_1,'' Category_2,'' Category_3,'' Category_4,'' Category_5,'' Category_6
  FROM md0000stcom.element_gestion article
 INNER JOIN md0000stcom.codification_fournisseur code_article ON code_article.elg_num_elt_gestion_elg =
                                                                 article.elg_num_elt_gestion
                                                             AND code_article.cof_flag_referenceur = '1'
 INNER JOIN md0000stcom.codification_fournisseur code_modele ON code_modele.elg_num_elt_gestion_elg =
                                                                article.elg_num_elt_gestion_mod
                                                            AND code_modele.cof_flag_referenceur = '1'
  LEFT OUTER JOIN md0000stcom.declinaison_article dca ON article.elg_num_elt_gestion =
                                                         dca.elg_num_elt_gestion_elg
  LEFT OUTER JOIN md0000stcom.declinaison_modele dcm ON dcm.tgr_num_type_grille_grl =
                                                        dca.tgr_num_type_grille_vag
                                                    AND dcm.elg_num_elt_gestion_elg =
                                                        article.elg_num_elt_gestion_mod
  LEFT OUTER JOIN md0000stcom.val_grille vag ON vag.tti_num_type_tiers_grl =
                                                dca.tti_num_type_tiers_vag
                                            AND vag.tir_num_tiers_grl =
                                                dca.tir_num_tiers_vag
                                            AND vag.tir_sous_num_tiers_grl =
                                                dca.tir_sous_num_tiers_vag
                                            AND vag.vag_val_grille =
                                                dca.vag_val_grille_vag
                                            AND vag.tgr_num_type_grille_grl =
                                                dcm.tgr_num_type_grille_grl
  LEFT OUTER JOIN md0000stcom.libelle_traduction lib_grille ON lib_grille.tlb_typ_libelle_lib =
                                                               vag.tlb_typ_libelle_lib
                                                           AND lib_grille.lib_num_libelle_lib =
                                                               vag.lib_num_libelle_lib
                                                           AND lib_grille.lan_code_langue_lan = 'en'
  LEFT OUTER JOIN md0000stcom.libelle_traduction lib_grille2 ON lib_grille2.tlb_typ_libelle_lib =
                                                                vag.tlb_typ_libelle_lib
                                                            AND lib_grille2.lib_num_libelle_lib =
                                                                vag.lib_num_libelle_lib
                                                            AND lib_grille2.lan_code_langue_lan = 'EN'
 INNER JOIN md0000stcom.libelle_modele lib_mod ON lib_mod.elg_num_elt_gestion_elg =
                                                  article.elg_num_elt_gestion_mod
                                              AND lib_mod.tlb_typ_libelle_lib =
                                                  'LMO'
  LEFT OUTER JOIN md0000stcom.libelle_traduction lib_modele ON lib_modele.tlb_typ_libelle_lib =
                                                               lib_mod.tlb_typ_libelle_lib
                                                           AND lib_modele.lib_num_libelle_lib =
                                                               lib_mod.lib_num_libelle_lib
                                                           AND lib_modele.lan_code_langue_lan = 'en'
  LEFT OUTER JOIN md0000stcom.libelle_traduction lib_modele2 ON lib_modele2.tlb_typ_libelle_lib =
                                                                lib_mod.tlb_typ_libelle_lib
                                                            AND lib_modele2.lib_num_libelle_lib =
                                                                lib_mod.lib_num_libelle_lib
                                                            AND lib_modele2.lan_code_langue_lan = 'EN'
 INNER JOIN md0000stcom.detail_elt_gestion d_model ON d_model.elg_num_elt_gestion_elg =
                                                      article.elg_num_elt_gestion_mod
 INNER JOIN md0000stcom.marque m ON m.mrq_num_marque =
                                    d_model.mrq_num_marque_mrq
 INNER JOIN md0000stcom.rattachement_modele rattach ON rattach.elg_num_elt_gestion_elg =
                                                       article.elg_num_elt_gestion_mod
                                                   AND rattach.org_num_organisation_eln = 2
  Left outer join md0000stcom.prix_unit_vente pu on pu.TIR_NUM_TIERS_VEND = 64 -- PH
                                                 and pu.TTI_NUM_TYPE_TIERS_VEND = 15
                                                 and pu.ELG_NUM_ELT_GESTION_UMA =
                                                     article.elg_num_elt_gestion
                                                 and pu.PRI_DATE_DEBUT <
                                                     sysdate
                                                 and pu.PRI_DATE_FIN >
                                                     sysdate
                                                 and pu.TPR_NUM_TYPE_PRIX_TPR = 1
 inner join stcom.current_prices_pos cpp on article.elg_num_elt_gestion =
                                            cpp.elg_num_elt_gestion_uma
                                        and cpp.tir_num_tiers_tir = 1516
                                        and cpp.cpr_date_maj_technique >
                                            sysdate - 7
  LEFT OUTER JOIN md0000stcom.elt_niveau famille ON famille.org_num_organisation_niv =
                                                    rattach.org_num_organisation_eln
                                                AND famille.niv_num_niveau_niv =
                                                    rattach.niv_num_niveau_eln
                                                AND famille.eln_num_elt_niveau =
                                                    rattach.eln_num_elt_niveau_eln
  LEFT OUTER JOIN md0000stcom.libelle_traduction lib_famille ON lib_famille.tlb_typ_libelle_lib =
                                                                famille.tlb_typ_libelle_lib
                                                            AND lib_famille.lib_num_libelle_lib =
                                                                famille.lib_num_libelle_lib
                                                            AND lib_famille.lan_code_langue_lan = 'en'
  LEFT OUTER JOIN md0000stcom.libelle_traduction lib_famille2 ON lib_famille2.tlb_typ_libelle_lib =
                                                                 famille.tlb_typ_libelle_lib
                                                             AND lib_famille2.lib_num_libelle_lib =
                                                                 famille.lib_num_libelle_lib
                                                             AND lib_famille2.lan_code_langue_lan = 'EN'
  join md0000stcom.codification_physique cp on cp.elg_num_elt_gestion_elg =
                                               article.elg_num_elt_gestion
                                           and cp.cop_code_principal = 1
                                           and cp.cop_type_cop = 0
 WHERE dca.DEC_TYP_DECLINAISON = 0
 and dca.tgr_num_type_grille_vag <> 423;
