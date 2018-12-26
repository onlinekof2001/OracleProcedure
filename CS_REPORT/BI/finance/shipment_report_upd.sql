-- shipment_report_upd.sql for finance BI shipment_report_upd
select ''||tr.tti_num_type_tiers_tti||','||tr.tir_num_tiers||','||lce.cof_ref_code_ref||','||tr.tir_nom_tiers||','||oo.tpr_third_par_num_pli||','||replace(trSupp.tir_nom_tiers,',','')||','||srd.SRD_NUM_ORGANIZATION_ORG||','||srd.SRD_YEAR||','||srd.SRD_MONTH||','||srd.SRD_CURRENCY||','||srd.SRD_LINE_NUMBER||','||srd.SRD_ORDER_NUMBER||','||srd.SRD_PO_ORDER_NUMBER||','||srd.SRD_EXTERNAL_ORDER_NUMBER||','||srd.SRD_EXTERNAL_ITEM_CODE||','||srd.SRD_ELEMENT_PROD_NUM||','||replace(srd.SRD_ITEM_LABEL,',','.')||','||srd.SRD_THI_PAR_NUM_TYP_CUS||','||srd.SRD_THIRD_PAR_NUM_CUS||','||srd.SRD_SUB_THIRD_PAR_NUM_CUS||','||srd.SRD_CUSTOMER_NAME||','||srd.SRD_THI_PAR_NUM_TYP_SUP||','||srd.SRD_THIRD_PAR_NUM_SUP||','||srd.SRD_SUB_THIRD_PAR_NUM_SUP||','||srd.SRD_SUPPLIER_NAME||','||srd.SRD_SHIPMENT_DATE||','||srd.SRD_DEPARTMENT_NUMBER||','||srd.SRD_SHIPPED_QTY||','||srd.SRD_ORIGINAL_CURRENCY||','||srd.SRD_INVOICE_PRICE||','||srd.SRD_SUPPLIER_PROD_COST||','||srd.SRD_FOB_COST||','||srd.SRD_REMUNERATION_AMOUNT||','||srd.SRD_REMUNERATION_RATE||','||srd.SRD_REMUNERATION_MODE||','||srd.SRD_TOTAL_CUSTOMER_PRICE||','||srd.SRD_INTERNAT_TRANSPORT||','||srd.SRD_CUSTOM_COST||','||srd.SRD_VAL_FORCE_GAP||','||srd.SRD_EXWORK_COST||','||srd.SRD_SUPPLIER_BOM_COST||','||srd.SRD_SUPPLIER_LABOR_COST||','||srd.SRD_QUOTA_SALES_COST||','||srd.SRD_BUSINESS_SALES_COST||','||srd.SRD_OTHER_SALES_COST||','||srd.SRD_VAT||','||srd.SRD_CAM||','||srd.SRD_LOCAL_TRANSPORT_COST||','||srd.SRD_TOTAL_PROD_COST||','||srd.SRD_CESSION_PRICE||','||srd.SRD_DEPRECIATION_COST||','||srd.SRD_CARTON_COST||','||srd.SRD_TRUCKING_COST||','||srd.SRD_DUTY_COST||','||srd.SRD_OTHER_COST||','||srd.SRD_POST_DISPATCH_COST||','||srd.SRD_REPACKING_COST||','||srd.SRD_ROYALTIES_FOR_IMPORT||','||srd.SRD_EXPORT_PRICE||','||srd.SRD_EXPORT_PRICE_CURRENCY||','||srd.SRD_TAXES_FOR_EXPORT||','||srd.SRD_NATURE||','||srd.SRD_SHIPMENT_CODE||','||srd.SRD_TECH_CREATION_DATE||','||srd.SRD_TECH_UPDATE_DATE||','||srd.SRD_IE_PRICE||','||srd.SRD_IE_CURRENCY||''
       from edb.shipment_report_detail srd
full join masterdatas.tiers_ref@tetrix02_bditm1odb01 tr
     on srd.srd_num_organization_org = tr.org_num_organisation_eln
        and tr.niv_num_niveau_eln = 4
        and tr.tti_num_type_tiers_tti = 21
        and tr.eln_num_elt_niveau_eln = srd.srd_department_number
        join orders.orders oo on oo.ord_order_number = srd.srd_order_number
full join masterdatas.tiers_ref@tetrix02_bditm1odb01 trSupp on trSupp.tir_num_tiers = oo.tpr_third_par_num_pli
     and trSupp.tti_num_type_tiers_tti = oo.tpt_thi_par_num_typ_pli
join prdref.element_prod ep on ep.elp_element_prod_num = srd.srd_element_prod_num
join prdref.link_codif_element lce on lce.elp_element_prod_num_elg = ep.elp_element_prod_num_mod
     and lce.tpt_thi_par_num_typ_ref = 46
     and lce.tpr_third_par_num_ref = 1
where 1=1
and srd.srd_year = to_char(sysdate-10,'yyyy')
and srd.srd_month  = to_char(sysdate-10,'mm')
and srd.srd_currency = 'CNY'
AND SRD.SRD_NUM_ORGANIZATION_ORG in (66,74,78,82,106,103,111,119,127,129,120,121);
