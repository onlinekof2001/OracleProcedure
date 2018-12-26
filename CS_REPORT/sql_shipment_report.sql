set feedback off
col param1 noprint new_value orga

set verify off
set term off
select to_char('&1') param1 from dual;

set term on

spool '&2' append

set wrap off

select value from v$parameter where name like 'db_unique%';
select 'ORGA,ORDNUM,PO_NUMBER,CODE,ITEMCODE,SHIPPEDQTY,ORDER_STATUS,ORDER_TYPE,ORDER_PROCESS,SHIPMENT_ORIGIN,LASTSHIPMENTDATE,LASTDELIVERYDATE,ACTUALSHIPMENTDATE,CREATION_DATE,UPDATE_DATE,CUSTOMER_THIRD_TYPE,CUSTOMER_THIRD_NUM,SUPPLIER_THIRD_TYPE,SUPPLIER_THIRD_NUM,SUB_CONTRACTOR_THIRD_TYPE,SUB_CONTRACTOR_THIRD_NUM,ORDER_ORIGIN,ORDER_CURRENCY,ORDER_CUSTOMER_RESPONSIBLE,ORDER_SUPPLIER_RESPONSIBLE,ORDER_RESPONSIBLE,ORDER_EXPORT_TAXE_RATE,ORDER_ROYALTIES_RATE,RODCODE,ORDER_SUB_STATUS,ORDER_SUPPLIER_CURRENCY,PRODUCTION_LINE_STOCK,ORDER_PURCHASE_CURRENCY,SHIPMENT_UPDATER,SHIPMENT_COMPLEMENT,SHIPMENT_USER_PROFIL,SHIPMENT_INVOICE_NUMBER,EXPORT_PRICE,CESSION_PRICE,PURCHASE_PRICE,LABOR_PRICE,SUPPLIER_BOM_PRICE,MAC_PRICE,EXWORK_COST,FOB_COST,SUPPLIER_PROD_COST,SUPPLIER_DEPRECIATION,SUPPLIER_OTHER_COST,SUPPLIER_DUTY_COST,SUPPLIER_TRUCKING,REPACK,CAM,VAT,POST_DISPATCH,CUSTOMER_COST,INTER_TRANSPORT_COST,OTHER_COSTS,TRUCKING,CURRENCIES,EXCHANGE_RATE' from dual;
select trim(ORGA || ',' || ORDNUM || ',' || PO_NUMBER || ',' || CODE || ',' ||
            ITEMCODE || ',' || SHIPPEDQTY || ',' || ORDER_STATUS || ',' ||
            ORDER_TYPE || ',' || ORDER_PROCESS || ',' || SHIPMENT_ORIGIN || ',' ||
            LASTSHIPMENTDATE || ',' || LASTDELIVERYDATE || ',' ||
            ACTUALSHIPMENTDATE || ',' || CREATION_DATE || ',' ||
            UPDATE_DATE || ',' || CUSTOMER_THIRD_TYPE || ',' ||
            CUSTOMER_THIRD_NUM || ',' || SUPPLIER_THIRD_TYPE || ',' ||
            SUPPLIER_THIRD_NUM || ',' || SUB_CONTRACTOR_THIRD_TYPE || ',' ||
            SUB_CONTRACTOR_THIRD_NUM || ',' || ORDER_ORIGIN || ',' ||
            ORDER_CURRENCY || ',' || ORDER_CUSTOMER_RESPONSIBLE || ',' ||
            ORDER_SUPPLIER_RESPONSIBLE || ',' || ORDER_RESPONSIBLE || ',' ||
            ORDER_EXPORT_TAXE_RATE || ',' || ORDER_ROYALTIES_RATE || ',' ||
            RODCODE || ',' || ORDER_SUB_STATUS || ',' ||
            ORDER_SUPPLIER_CURRENCY || ',' || PRODUCTION_LINE_STOCK || ',' ||
            ORDER_PURCHASE_CURRENCY || ',' || SHIPMENT_UPDATER || ',' ||
            SHIPMENT_COMPLEMENT || ',' || SHIPMENT_USER_PROFIL || ',' ||
            SHIPMENT_INVOICE_NUMBER || ',' || EXPORT_PRICE || ',' ||
            CESSION_PRICE || ',' || PURCHASE_PRICE || ',' || LABOR_PRICE || ',' ||
            SUPPLIER_BOM_PRICE || ',' || MAC_PRICE || ',' || EXWORK_COST || ',' ||
            FOB_COST || ',' || SUPPLIER_PROD_COST || ',' ||
            SUPPLIER_DEPRECIATION || ',' || SUPPLIER_OTHER_COST || ',' ||
            SUPPLIER_DUTY_COST || ',' || SUPPLIER_TRUCKING || ',' || REPACK || ',' || CAM || ',' || VAT || ',' ||
            POST_DISPATCH || ',' || CUSTOMER_COST || ',' ||
            INTER_TRANSPORT_COST || ',' || OTHER_COSTS || ',' || TRUCKING || ',' ||
            CURRENCIES || ',' || EXCHANGE_RATE)
  from (select extractData.*,
               case
                 when extractData.order_purchase_currency =
                      extractData.order_currency then
                  extractData.order_purchase_currency || ' to ' ||
                  extractData.order_currency
                 else
                  exchangeRates.currency1 || ' to ' ||
                  exchangeRates.currency2
               end as currencies,
               case
                 when extractData.order_purchase_currency =
                      extractData.order_currency then
                  1
                 else
                  exchangeRates.rate
               end as exchange_rate
          from (select dataVal.orga,
                       dataVal.ordNum,
                       dataVal.poNum po_number,
                       dataVal.shiCode code,
                       dataVal.itemCode,
                       dataVal.shippedQty,
                       case
                         when dataVal.ordStatus = 'NV' then
                          'Not Validated'
                         when dataVal.ordStatus = 'V' then
                          'Validated'
                         when dataVal.ordStatus = 'AS' then
                          'Available for Shipement'
                         when dataVal.ordStatus = 'S' then
                          'Shipped'
                         when dataVal.ordStatus = 'R' then
                          'Received'
                         when dataVal.ordStatus = 'CP' then
                          'Closed in Production'
                         when dataVal.ordStatus = 'C' then
                          'Closed'
                         else
                          dataVal.ordStatus
                       end as order_status,
                       case
                         when dataVal.ordType = 'R' then
                          'Replenishment'
                         when dataVal.ordType = 'I' then
                          'Implantation'
                         when dataVal.ordType = 'P' then
                          'Inter-Dpp'
                         when dataVal.ordType = 'S' then
                          'Purchase-order'
                         when dataVal.ordType = 'E' then
                          'External-Sale'
                         when dataVal.ordType = 'K' then
                          'Prod-Order'
                         else
                          null
                       end as order_type,
                       case
                         when dataVal.ordProcess = 'B' then
                          'Trading'
                         when dataVal.ordProcess = 'M' then
                          'Manufactured'
                         when dataVal.ordProcess = 'S' then
                          'Stock-Sale'
                         else
                          null
                       end as order_process,
                       case
                         when dataVal.shiOrigin = 'TMS' then
                          'TMS'
                         when dataVal.shiOrigin = 'UTR' then
                          'Shipment to reception'
                         when dataVal.shiOrigin = 'CAP' then
                          'CAPE'
                         when dataVal.shiOrigin = 'STL' then
                          'PRODCOM'
                         else
                          null
                       end as shipment_origin,
                       dataVal.lsd lastShipmentDate,
                       dataVal.ldd lastDeliveryDate,
                       dataVal.ash actualShipmentDate,
                       dataVal.creationDate creation_date,
                       dataVal.shiRecDate update_date,
                       dataVal.tcustomer customer_third_type,
                       dataVal.third_customer customer_third_num,
                       dataVal.tsupplier supplier_third_type,
                       dataVal.third_supplier supplier_third_num,
                       dataVal.tsub_contractor sub_contractor_third_type,
                       dataVal.third_sub_contractor sub_contractor_third_num,
                       dataVal.orderOrigin order_origin,
                       dataVal.orderCurrency order_currency,
                       dataVal.ordCusResp order_customer_responsible,
                       dataVal.ordSupResp order_supplier_responsible,
                       dataVal.ordResp order_responsible,
                       dataVal.ordExportTaxeRate order_export_taxe_rate,
                       dataVal.ordRoyaltiesRate order_royalties_rate,
                       dataVal.rodCode rodCode,
                       dataVal.ordSubStatus order_sub_status,
                       dataVal.orderSupplierCurrency order_supplier_currency,
                       dataVal.plineStock production_line_stock,
                       dataVal.ordPurchaseCurrency order_purchase_currency,
                       dataVal.shiUpdater shipment_updater,
                       dataVal.shiComplement shipment_complement,
                       dataVal.shiUserProfil shipment_user_profil,
                       dataVal.shiInvoiceNum shipment_invoice_number,
                       sum((dataVal.shippedQty * prices.exportPrice)) export_price,
                       sum((dataVal.shippedQty * prices.cessionPrice)) cession_price,
                       sum((dataVal.shippedQty * prices.purchasePrice)) purchase_price,
                       sum((dataVal.shippedQty * prices.laborPrice)) labor_price,
                       sum((dataVal.shippedQty * prices.supplierBomPrice)) supplier_bom_price,
                       sum((dataVal.shippedQty * prices.macPrice)) mac_price,
                       sum((dataVal.shippedQty * prices.exworkCost)) exwork_cost,
                       sum((dataVal.shippedQty * prices.fobCost)) fob_cost,
                       sum((dataVal.shippedQty * prices.supplierPrd)) supplier_prod_cost,
                       sum((dataVal.shippedQty * prices.supplierDepreciation)) supplier_depreciation,
                       sum((dataVal.shippedQty * prices.supplierOtherCost)) supplier_other_cost,
                       sum((dataVal.shippedQty * prices.supplierDutyCost)) supplier_duty_cost,
                       sum((dataVal.shippedQty * prices.supplierTrucking)) supplier_trucking,
                       sum((dataVal.shippedQty * prices.repack)) repack,
                       sum((dataVal.shippedQty * prices.cam)) cam,
                       sum((dataVal.shippedQty * prices.vat)) vat,
                       sum((dataVal.shippedQty * prices.postDispatch)) post_dispatch,
                       sum((dataVal.shippedQty * prices.customerCost)) customer_cost,
                       sum((dataVal.shippedQty * prices.interTransportCost)) inter_transport_cost,
                       sum((dataVal.shippedQty * prices.offOther)) other_costs,
                       sum((dataVal.shippedQty * prices.offTrucking)) trucking
                  from (select ordShi.shiCode,
                               ordShi.ordType,
                               ordShi.ordProcess,
                               ordShi.orga,
                               ordShi.ordNum,
                               ordShi.ordLineNum,
                               ordShi.shippedQty,
                               ordShi.internCode,
                               ordShi.orderCurrency,
                               max(ordVal.valCode) lastCodeVal,
                               ordShi.tcustomer,
                               ordShi.third_customer,
                               ordShi.tsupplier,
                               ordShi.third_supplier,
                               ordShi.tsub_contractor,
                               ordShi.third_sub_contractor,
                               ordShi.tfinal_destination,
                               ordShi.third_final_destination,
                               ordShi.creationDate,
                               ordShi.department,
                               ordShi.shipmentDate shiRecDate,
                               ordShi.orderOrigin,
                               ordVal.poNum,
                               ordVal.itemCode,
                               ordShi.ordStatus,
                               ordShi.ordCusResp,
                               ordShi.ordSupResp,
                               ordShi.ordResp,
                               ordShi.pline,
                               ordShi.plineDel,
                               ordShi.ordComment,
                               ordShi.ordSlsSupplier,
                               ordShi.ordExportTaxeRate,
                               ordShi.ordRoyaltiesRate,
                               ordShi.rodCode,
                               ordShi.ordSubStatus,
                               ordShi.orderSupplierCurrency,
                               ordShi.plineStock,
                               ordShi.ordPurchaseCurrency,
                               ordShi.orderInvoiceNumber,
                               ordShi.shiUpdater,
                               ordShi.shiComplement,
                               ordShi.shiUserProfil,
                               ordShi.shiInvoiceNum,
                               ordShi.shiOrigin,
                               ordShi.containerCode,
                               ordShi.loadingPort,
                               ordShi.unloadingPort,
                               ordShi.supplierPackaging,
                               ordShi.netWeight,
                               ordShi.brutWeight,
                               ordShi.volume,
                               ordShi.transportType,
                               ordShi.firstBoxNumber,
                               ordShi.lasBoxNumber,
                               ordShi.transportCode,
                               ordShi.mvtExtCode,
                               ordShi.incotermNum,
                               ordShi.csd,
                               ordShi.cdd,
                               ordShi.esd,
                               ordShi.edd,
                               ordShi.lsd,
                               ordShi.ldd,
                               ordShi.ash,
                               ordShi.orderCreationAuthor,
                               ordShi.pickingDate,
                               ordShi.productionBeginDate,
                               ordShi.chd,
                               ordShi.supplierPriceDate,
                               ordShi.czad,
                               ordShi.ezad,
                               ordShi.azad,
                               ordShi.productionEndDate,
                               ordShi.lrhd,
                               ordShi.remRateTmp,
                               ordShi.oafcost,
                               ordShi.oafcur
                          from (select sh.shh_shipment_code shiCode,
                                       sh.org_num_organization_org orga,
                                       sh.ord_order_number_ord ordNum,
                                       sh.shh_order_line_number ordLineNum,
                                       sh.elp_element_prod_num_elp internCode,
                                       sh.shh_creation_date creationDate,
                                       sh.shh_shipment_date shipmentDate,
                                       sum(sh.shh_shipped_qty) shippedQty,
                                       sh.shh_user_profile shiUserProfil,
                                       sh.shh_shipment_invoice_number shiInvoiceNum,
                                       sh.rst_shipment_tool_code_rst shiOrigin,
                                       sd.shd_container_code containerCode,
                                       sd.shd_loading_port loadingPort,
                                       sd.shd_unloading_port unloadingPort,
                                       sd.shd_supplier_packaging supplierPackaging,
                                       sd.shd_net_weight netWeight,
                                       sd.shd_brut_weight brutWeight,
                                       sd.shd_volume volume,
                                       sd.shd_transport_type transportType,
                                       sd.shd_first_box_number firstBoxNumber,
                                       sd.shd_last_box_number lasBoxNumber,
                                       sd.shd_transport_code transportCode,
                                       sd.shd_movement_external_code mvtExtCode,
                                       o.ost_order_status_ost ordStatus,
                                       o.otp_order_type_otp ordType,
                                       o.opc_order_process_opc ordProcess,
                                       o.ord_customer_order_flag ordSell,
                                       o.ord_origin orderOrigin,
                                       o.ord_remuneration_rate remuneration,
                                       o.tpt_thi_par_num_typ_cus tcustomer,
                                       o.tpr_third_par_num_cus third_customer,
                                       o.tpt_thi_par_num_typ_sup tsupplier,
                                       o.tpr_third_par_num_sup third_supplier,
                                       o.tpt_thi_par_num_typ_pli tsub_contractor,
                                       o.tpr_third_par_num_pli third_sub_contractor,
                                       o.tpt_thi_par_num_typ_del tfinal_destination,
                                       o.tpr_third_par_num_del third_final_destination,
                                       o.ord_currency orderCurrency,
                                       o.rem_remuneration_mode_rem remunerationMode,
                                       o.ord_customer_responsible ordCusResp,
                                       o.ord_supplier_responsible ordSupResp,
                                       o.ord_order_responsible ordResp,
                                       o.pli_code_prod_line_pli pline,
                                       o.pli_code_prod_line_del plineDel,
                                       o.ord_po_comment ordComment,
                                       o.ord_sale_on_stock_supplier ordSlsSupplier,
                                       o.ord_export_taxe_rate ordExportTaxeRate,
                                       o.ord_royalties_rate ordRoyaltiesRate,
                                       o.rod_code rodCode,
                                       o.ord_order_sub_status_oss ordSubStatus,
                                       o.ord_inv_supplier_cur orderSupplierCurrency,
                                       o.pli_code_prod_line_stk plineStock,
                                       o.ord_purchase_currency ordPurchaseCurrency,
                                       o.ord_invoice_number orderInvoiceNumber,
                                       oll.oll_department department,
                                       ouhShi.Ouh_Order_Updater_Profile shiUpdater,
                                       ouhShi.Ouh_Order_Updates_Complement shiComplement,
                                       o.inc_num_incoterm_inc incotermNum,
                                       o.ord_contractual_shipment_date csd,
                                       o.ord_contractual_delivery_date cdd,
                                       o.ord_expected_shipment_date esd,
                                       o.ord_expected_delivery_date edd,
                                       o.ord_last_shipment_date lsd,
                                       o.ord_last_delivery_date ldd,
                                       o.ord_actual_supplier_handover ash,
                                       o.ord_creation_author orderCreationAuthor,
                                       o.ord_picking_date pickingDate,
                                       o.ord_production_begin_date productionBeginDate,
                                       o.ord_contractual_handover_date chd,
                                       o.ord_supplier_price_date supplierPriceDate,
                                       o.ord_contractual_zad czad,
                                       o.ord_estimated_zad ezad,
                                       o.ord_actual_zone_arrival_date azad,
                                       o.ord_production_end_date productionEndDate,
                                       o.ord_last_real_handover_date lrhd,
                                       o.ord_remuneration_rate_tmp remRateTmp,
                                       old.old_air_freight_cost oafcost,
                                       old.old_air_freight_currency oafcur
                                  from edb.shipment_header sh
                                 inner join edb.shipment_details sd
                                    on sd.org_num_organization_shh =
                                       sh.org_num_organization_org
                                   and sd.shh_shipment_code_shh =
                                       sh.shh_shipment_code
                                 inner join orders.orders o
                                    on o.org_num_organization_org =
                                       sh.org_num_organization_org
                                   and o.ord_order_number =
                                       sh.ord_order_number_ord
                                 inner join orders.order_line_levels oll
                                    on oll.org_num_organization_oln =
                                       sh.org_num_organization_org
                                   and oll.ord_order_number_oln =
                                       sh.ord_order_number_ord
                                   and oll.oln_order_line_number_oln =
                                       sh.shh_order_line_number
                                  left join orders.order_line_detail old
                                    on old.org_num_organization_oln =
                                       oll.org_num_organization_oln
                                   and old.ord_order_number_oln =
                                       oll.ord_order_number_oln
                                   and old.oln_order_line_number_oln =
                                       oll.oln_order_line_number_oln
                                  left join edb.order_updates_header ouhShi
                                    on ouhShi.Org_Num_Organization_Org =
                                       sh.org_num_organization_org
                                   and ouhShi.Ouh_Order_Updates_Code =
                                       sh.shh_shipment_code
                                   and ouhShi.Ord_Order_Number_Ord =
                                       sh.ord_order_number_ord
                                   and ouhShi.Ret_Event_Type_Code_Ret =
                                       sh.ret_event_type_code_ret
                                 where sh.org_num_organization_org = (&&orga.)
                                   and sh.shh_active_flag = 'Y'
                                   and sh.shh_shipment_anomaly_flag = 'N'
                                   and sh.ret_event_type_code_ret = 'SHI_SHI'
                                   and sh.shh_shipment_date between
                                       to_date('01/10/2017 00:00:01',
                                               'dd/mm/yyyy HH24:mi:ss') and
                                       to_date('30/09/2018 23:59:59',
                                               'dd/mm/yyyy HH24:mi:ss')
                                   and o.ost_order_status_ost in
                                       ('S', 'R', 'C', 'CP')
                                   and o.ord_origin in ('ECC', 'APO')
                                 group by sh.shh_shipment_code,
                                          sh.org_num_organization_org,
                                          sh.ord_order_number_ord,
                                          sh.shh_order_line_number,
                                          sh.elp_element_prod_num_elp,
                                          sh.shh_creation_date,
                                          sh.shh_shipment_date,
                                          sh.shh_user_profile,
                                          sh.shh_shipment_invoice_number,
                                          sh.rst_shipment_tool_code_rst,
                                          sd.shd_container_code,
                                          sd.shd_loading_port,
                                          sd.shd_unloading_port,
                                          sd.shd_supplier_packaging,
                                          sd.shd_net_weight,
                                          sd.shd_brut_weight,
                                          sd.shd_volume,
                                          sd.shd_transport_type,
                                          sd.shd_first_box_number,
                                          sd.shd_last_box_number,
                                          sd.shd_transport_code,
                                          sd.shd_movement_external_code,
                                          o.ost_order_status_ost,
                                          o.otp_order_type_otp,
                                          o.opc_order_process_opc,
                                          o.ord_customer_order_flag,
                                          o.ord_origin,
                                          o.ord_remuneration_rate,
                                          o.tpt_thi_par_num_typ_cus,
                                          o.tpr_third_par_num_cus,
                                          o.tpt_thi_par_num_typ_sup,
                                          o.tpr_third_par_num_sup,
                                          o.tpt_thi_par_num_typ_pli,
                                          o.tpr_third_par_num_pli,
                                          o.tpt_thi_par_num_typ_del,
                                          o.tpr_third_par_num_del,
                                          o.ord_currency,
                                          o.rem_remuneration_mode_rem,
                                          oll.oll_department,
                                          o.ord_customer_responsible,
                                          o.ord_supplier_responsible,
                                          o.ord_order_responsible,
                                          o.pli_code_prod_line_pli,
                                          o.pli_code_prod_line_del,
                                          o.ord_po_comment,
                                          o.ord_sale_on_stock_supplier,
                                          o.ord_export_taxe_rate,
                                          o.ord_royalties_rate,
                                          o.rod_code,
                                          o.ord_order_sub_status_oss,
                                          o.ord_inv_supplier_cur,
                                          o.pli_code_prod_line_stk,
                                          o.ord_purchase_currency,
                                          o.ord_invoice_number,
                                          o.inc_num_incoterm_inc,
                                          o.ord_contractual_shipment_date,
                                          o.ord_contractual_delivery_date,
                                          o.ord_expected_shipment_date,
                                          o.ord_expected_delivery_date,
                                          o.ord_last_shipment_date,
                                          o.ord_last_delivery_date,
                                          o.ord_actual_supplier_handover,
                                          o.ord_creation_author,
                                          o.ord_picking_date,
                                          o.ord_production_begin_date,
                                          o.ord_contractual_handover_date,
                                          o.ord_supplier_price_date,
                                          o.ord_contractual_zad,
                                          o.ord_estimated_zad,
                                          o.ord_actual_zone_arrival_date,
                                          o.ord_production_end_date,
                                          o.ord_last_real_handover_date,
                                          o.ord_remuneration_rate_tmp,
                                          ouhShi.Ouh_Order_Updater_Profile,
                                          ouhShi.Ouh_Order_Updates_Complement,
                                          old.old_air_freight_cost,
                                          old.old_air_freight_currency) ordShi
                         inner join (select ouh.org_num_organization_org  orga,
                                           ouh.ouh_order_updates_code    valCode,
                                           ouh.ord_order_number_ord      ordNum,
                                           ouh.ouh_order_line_number     ordLineNum,
                                           ouh.elp_element_prod_num_item internCode,
                                           lce.cof_ref_code_ref          itemCode,
                                           ouh.ouh_purchase_order_number poNum
                                      from edb.order_updates_header ouh
                                     inner join prdref.link_codif_element lce
                                        on lce.elp_element_prod_num_elg =
                                           ouh.elp_element_prod_num_item
                                     inner join (select ouh2.org_num_organization_org orga,
                                                       ouh2.ord_order_number_ord ordNum,
                                                       ouh2.ouh_order_line_number ordLineNum,
                                                       ouh2.elp_element_prod_num_item internCode,
                                                       max(ouh2.ouh_purchase_order_number) poNum
                                                  from edb.order_updates_header ouh2
                                                 where ouh2.ret_event_type_code_ret =
                                                       'ORD_VAL'
                                                   and ouh2.org_num_organization_org =
                                                       (&&orga.)
                                                 group by ouh2.org_num_organization_org,
                                                          ouh2.ord_order_number_ord,
                                                          ouh2.ouh_order_line_number,
                                                          ouh2.elp_element_prod_num_item) maxPo
                                        on maxPo.orga =
                                           ouh.org_num_organization_org
                                       and maxPo.ordNum =
                                           ouh.ord_order_number_ord
                                       and maxPo.ordLineNum =
                                           ouh.ouh_order_line_number
                                       and maxPo.internCode =
                                           ouh.elp_element_prod_num_item
                                       and maxPo.poNum =
                                           ouh.ouh_purchase_order_number
                                     where ouh.ret_event_type_code_ret =
                                           'ORD_VAL'
                                       and ouh.org_num_organization_org =
                                           (&&orga.)) ordVal
                            on ordVal.Orga = ordShi.Orga
                           and ordVal.ordNum = ordShi.ordNum
                           and ordVal.ordLineNum = ordShi.ordLineNum
                           and ordVal.internCode = ordShi.internCode
                         group by ordShi.shiCode,
                                  ordShi.orga,
                                  ordShi.ordNum,
                                  ordShi.ordLineNum,
                                  ordShi.shippedQty,
                                  ordShi.ordStatus,
                                  ordShi.internCode,
                                  ordShi.ordType,
                                  ordShi.ordProcess,
                                  ordShi.tcustomer,
                                  ordShi.third_customer,
                                  ordShi.tsupplier,
                                  ordShi.third_supplier,
                                  ordShi.tsub_contractor,
                                  ordShi.third_sub_contractor,
                                  ordShi.tfinal_destination,
                                  ordShi.third_final_destination,
                                  ordShi.department,
                                  ordShi.creationDate,
                                  ordShi.shipmentDate,
                                  ordVal.poNum,
                                  ordShi.orderOrigin,
                                  ordVal.itemCode,
                                  ordShi.orderCurrency,
                                  ordShi.ordCusResp,
                                  ordShi.ordSupResp,
                                  ordShi.ordResp,
                                  ordShi.pline,
                                  ordShi.plineDel,
                                  ordShi.ordComment,
                                  ordShi.ordSlsSupplier,
                                  ordShi.ordExportTaxeRate,
                                  ordShi.ordRoyaltiesRate,
                                  ordShi.rodCode,
                                  ordShi.ordSubStatus,
                                  ordShi.orderSupplierCurrency,
                                  ordShi.plineStock,
                                  ordShi.ordPurchaseCurrency,
                                  ordShi.orderInvoiceNumber,
                                  ordShi.shiUpdater,
                                  ordShi.shiComplement,
                                  ordShi.shiUserProfil,
                                  ordShi.shiInvoiceNum,
                                  ordShi.shiOrigin,
                                  ordShi.containerCode,
                                  ordShi.loadingPort,
                                  ordShi.unloadingPort,
                                  ordShi.supplierPackaging,
                                  ordShi.netWeight,
                                  ordShi.brutWeight,
                                  ordShi.volume,
                                  ordShi.transportType,
                                  ordShi.firstBoxNumber,
                                  ordShi.lasBoxNumber,
                                  ordShi.transportCode,
                                  ordShi.mvtExtCode,
                                  ordShi.incotermNum,
                                  ordShi.csd,
                                  ordShi.cdd,
                                  ordShi.esd,
                                  ordShi.edd,
                                  ordShi.lsd,
                                  ordShi.ldd,
                                  ordShi.ash,
                                  ordShi.orderCreationAuthor,
                                  ordShi.pickingDate,
                                  ordShi.productionBeginDate,
                                  ordShi.chd,
                                  ordShi.supplierPriceDate,
                                  ordShi.czad,
                                  ordShi.ezad,
                                  ordShi.azad,
                                  ordShi.productionEndDate,
                                  ordShi.lrhd,
                                  ordShi.remRateTmp,
                                  ordShi.oafcost,
                                  ordShi.oafcur) dataVal
                  left join (select ah.oev_event_code_oev codeVal,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('EXPORT_PRICE') then
                                      ah.amh_amount_value
                                   end as exportPrice,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('CESS_PRICE') then
                                      ah.amh_amount_value
                                   end as cessionPrice,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('PURCH_PRICE') then
                                      ah.amh_amount_value
                                   end as purchasePrice,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_LABOR') then
                                      ah.amh_amount_value
                                   end as laborPrice,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_BOM') then
                                      ah.amh_amount_value
                                   end as supplierBomPrice,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_BOM_PRMP') then
                                      ah.amh_amount_value
                                   end as macPrice,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('REF_EXW') then
                                      ah.amh_amount_value
                                   end as exworkCost,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('REF_FOB_COST') then
                                      ah.amh_amount_value
                                   end as fobCost,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_PRD') then
                                      ah.amh_amount_value
                                   end as supplierPrd,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_DEPREC') then
                                      ah.amh_amount_value
                                   end as supplierDepreciation,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_OTHER') then
                                      ah.amh_amount_value
                                   end as supplierOtherCost,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_DUTY') then
                                      ah.amh_amount_value
                                   end as supplierDutyCost,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('SUP_TRUCKING') then
                                      ah.amh_amount_value
                                   end as supplierTrucking,
                                   case
                                     when ah.atp_amount_type_atp in ('REPACK') then
                                      ah.amh_amount_value
                                   end as repack,
                                   case
                                     when ah.atp_amount_type_atp in ('CAM') then
                                      ah.amh_amount_value
                                   end as cam,
                                   case
                                     when ah.atp_amount_type_atp in ('VAT') then
                                      ah.amh_amount_value
                                   end as vat,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('POST_DISP') then
                                      ah.amh_amount_value
                                   end as postDispatch,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('REF_CUS_COST') then
                                      ah.amh_amount_value
                                   end as customerCost,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('COMPUT_INTTR') then
                                      ah.amh_amount_value
                                   end as interTransportCost,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('OFF_OTHER') then
                                      ah.amh_amount_value
                                   end as offOther,
                                   case
                                     when ah.atp_amount_type_atp in
                                          ('OFF_TRUCKING') then
                                      ah.amh_amount_value
                                   end as offTrucking
                              from edb.amount_historic ah
                             where ah.org_num_organization_oev = (&&orga.)) prices
                    on prices.codeVal = dataVal.lastCodeVal
                 group by dataVal.orga,
                          dataVal.ordNum,
                          dataVal.shiCode,
                          dataVal.shippedQty,
                          dataVal.ordStatus,
                          dataVal.ordType,
                          dataVal.ordProcess,
                          dataVal.tcustomer,
                          dataVal.third_customer,
                          dataVal.tsupplier,
                          dataVal.third_supplier,
                          dataVal.tsub_contractor,
                          dataVal.third_sub_contractor,
                          dataVal.tfinal_destination,
                          dataVal.third_final_destination,
                          dataVal.department,
                          dataVal.shiRecDate,
                          dataVal.creationDate,
                          dataVal.poNum,
                          dataVal.orderOrigin,
                          dataVal.itemCode,
                          dataVal.orderCurrency,
                          dataVal.ordCusResp,
                          dataVal.ordSupResp,
                          dataVal.ordResp,
                          dataVal.pline,
                          dataVal.plineDel,
                          dataVal.ordComment,
                          dataVal.ordSlsSupplier,
                          dataVal.ordExportTaxeRate,
                          dataVal.ordRoyaltiesRate,
                          dataVal.rodCode,
                          dataVal.ordSubStatus,
                          dataVal.orderSupplierCurrency,
                          dataVal.plineStock,
                          dataVal.ordPurchaseCurrency,
                          dataVal.shiOrigin,
                          dataVal.shiUpdater,
                          dataVal.shiComplement,
                          dataVal.shiUserProfil,
                          dataVal.shiInvoiceNum,
                          dataVal.containerCode,
                          dataVal.loadingPort,
                          dataVal.unloadingPort,
                          dataVal.supplierPackaging,
                          dataVal.netWeight,
                          dataVal.brutWeight,
                          dataVal.volume,
                          dataVal.transportType,
                          dataVal.firstBoxNumber,
                          dataVal.lasBoxNumber,
                          dataVal.transportCode,
                          dataVal.mvtExtCode,
                          dataVal.incotermNum,
                          dataVal.csd,
                          dataVal.cdd,
                          dataVal.esd,
                          dataVal.edd,
                          dataVal.lsd,
                          dataVal.ldd,
                          dataVal.ash,
                          dataVal.orderCreationAuthor,
                          dataVal.pickingDate,
                          dataVal.productionBeginDate,
                          dataVal.chd,
                          dataVal.supplierPriceDate,
                          dataVal.czad,
                          dataVal.ezad,
                          dataVal.azad,
                          dataVal.productionEndDate,
                          dataVal.lrhd,
                          dataVal.remRateTmp,
                          dataVal.oafcost,
                          dataVal.oafcur) extractData
          left join (select rer.org_num_organization_org orga,
                           rer.cur_currency_code_fst    currency1,
                           rer.cur_currency_code_snd    currency2,
                           rer.rer_date_begin           date_begin,
                           rer.rer_date_end             date_end,
                           rer.rer_rate_exchange        rate,
                           rer.rer_flag_active          active
                      from prdadm.ref_exchange_rate rer
                     where rer.org_num_organization_org = (&&orga.)) exchangeRates
            on exchangeRates.orga = extractData.orga
           and exchangeRates.currency1 = extractData.order_currency
           and exchangeRates.currency2 = extractData.order_purchase_currency
           and exchangeRates.active = 'Y'
           and extractData.update_date between exchangeRates.date_begin and
               exchangeRates.date_end) tab;
spool off
quit;
