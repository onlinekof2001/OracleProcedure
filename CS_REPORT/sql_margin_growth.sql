set feedback off
col param1 noprint new_value curbegin
col param2 noprint new_value curend
col param3 noprint new_value lastbegin
col param4 noprint new_value lastend

set verify off
set term off
select to_char('&1') param1 from dual;
set term on
set verify off
set term off
select to_char('&2') param2 from dual;
set term on

set verify off
set term off
select to_char('&3') param3 from dual;
set term on
set verify off
set term off
select to_char('&4') param4 from dual;
set term on

spool '&5' append
select value from v$parameter where name like 'db_unique%';

SELECT HCN_MAG,
    TO_NUMBER(DECODE(SUM(HCN_CA), 0, NULL, SUM(HCN_CA))) * 1 AS CA,
    TO_NUMBER(DECODE(SUM(OLD_CA), 0, NULL, SUM(OLD_CA))) * 1 AS OLD_CA,
    (TO_NUMBER(DECODE(SUM(HCN_CA), 0, NULL, SUM(HCN_CA))) * 1 -
    TO_NUMBER(DECODE(SUM(OLD_CA), 0, NULL, SUM(OLD_CA))) * 1) /
    TO_NUMBER(DECODE(SUM(OLD_CA), 0, NULL, SUM(OLD_CA))) * 1 as PERCENT_CA,
    TO_NUMBER(DECODE(SUM(HCN_QUANTITE), 0, NULL, SUM(HCN_QUANTITE))) AS QTE,
    TO_NUMBER(DECODE(SUM(OLD_QTE), 0, NULL, SUM(OLD_QTE))) AS OLD_QTE,
    (TO_NUMBER(DECODE(SUM(HCN_QUANTITE), 0, NULL, SUM(HCN_QUANTITE))) -
    TO_NUMBER(DECODE(SUM(OLD_QTE), 0, NULL, SUM(OLD_QTE)))) /
    TO_NUMBER(DECODE(SUM(OLD_QTE), 0, NULL, SUM(OLD_QTE))) as PERCENT_QTE,
    TO_NUMBER(DECODE(SUM(HCN_MARGE), 0, NULL, SUM(HCN_MARGE))) * 1 AS MARGE,
    TO_NUMBER(DECODE(SUM(OLD_MARGE), 0, NULL, SUM(OLD_MARGE))) * 1 AS OLD_MARGE,
    (TO_NUMBER(DECODE(SUM(HCN_MARGE), 0, NULL, SUM(HCN_MARGE))) * 1 -
    TO_NUMBER(DECODE(SUM(OLD_MARGE), 0, NULL, SUM(OLD_MARGE)))) /
    TO_NUMBER(DECODE(SUM(OLD_MARGE), 0, NULL, SUM(OLD_MARGE))) as PERCENT_MARGE,
    TO_NUMBER(DECODE(SUM(PCT_MARGE), 0, NULL, SUM(PCT_MARGE))) * 100 AS PCT_MARGE,
    TO_NUMBER(DECODE(SUM(CLIENTS), 0, NULL, SUM(CLIENTS))) AS CLIENTS,
    TO_NUMBER(DECODE(SUM(OLD_CLIENTS), 0, NULL, SUM(OLD_CLIENTS))) AS OLD_CLIENTS,
    (TO_NUMBER(DECODE(SUM(CLIENTS), 0, NULL, SUM(CLIENTS)))-TO_NUMBER(DECODE(SUM(OLD_CLIENTS), 0, NULL, SUM(OLD_CLIENTS))))/ TO_NUMBER(DECODE(SUM(OLD_CLIENTS), 0, NULL, SUM(OLD_CLIENTS))) as PERCENT_CLIENTS,
    TO_NUMBER(DECODE(SUM(STOCK), 0, NULL, SUM(STOCK))) / 1 AS STOCK
  FROM (SELECT TIR_NUM_TIERS_TIR as HCN_MAG,
            SUM(HCN_CA) AS HCN_CA,
            SUM(HCN_QUANTITE) AS HCN_QUANTITE,
            SUM(HCN_MARGE) AS HCN_MARGE,
            AVG(HCN_RANG) AS HCN_RANG,
            SUM(HCN_MARGE) /
            TO_NUMBER(DECODE(SUM(HCN_CA), 0, NULL, SUM(HCN_CA))) AS PCT_MARGE,
            0 AS CLIENTS,
            0 AS OLD_CA,
            0 AS OLD_MARGE,
            0 AS OLD_CLIENTS,
            0 AS OLD_QTE,
            0 AS STOCK
        FROM stcom.HISTORIQUE_CA_EN
        WHERE TTI_NUM_TYPE_TIERS_TIR = 7
        AND TIR_NUM_TIERS_TIR in
            (select t.tir_num_tiers
                from masterdatas.tiers_ref t, masterdatas.magasin_ref m
                where t.tti_num_type_tiers_tti = 7
                and t.pay_code_pays_pay = 'CN'
                and t.dev_code_devise_dev = 'CNY'
                and t.tti_num_type_tiers_tti = m.tti_num_type_tiers_tir
                and t.tir_num_tiers = m.tir_num_tiers_tir
                and to_char(m.mar_date_ouverture, 'yyyymmdd') <= to_char(SYSDATE,'YYYYMMDD'))
        AND ELN_NUM_ELT_NIVEAU_ELN = 1
        AND ORG_NUM_ORGANISATION_ELN = 2
          AND NIV_NUM_NIVEAU_ELN = 6
        AND to_char(hcn_date, 'yyyymmdd') between '&&curbegin.' and '&&curend.' -- CHANGE here 
        group by TIR_NUM_TIERS_TIR
        UNION
        SELECT TIR_NUM_TIERS_TIR as HCN_MAG,
            0 AS HCN_CA,
            0 AS HCN_QUANTITE,
            0 AS HCN_MARGE,
            0 AS HCN_RANG,
            0 AS PCT_MARGE,
            0 AS CLIENTS,
            SUM(HCN_CA) AS OLD_CA,
            SUM(HCN_MARGE) AS OLD_MARGE,
            0 AS OLD_CLIENTS,
            SUM(HCN_QUANTITE) AS OLD_QTE,
            0 AS STOCK
        FROM stcom.HISTORIQUE_CA_EN
        WHERE TTI_NUM_TYPE_TIERS_TIR = 7
        AND TIR_NUM_TIERS_TIR in
            (select t.tir_num_tiers
                from masterdatas.tiers_ref t, masterdatas.magasin_ref m
                where t.tti_num_type_tiers_tti = 7
                and t.pay_code_pays_pay = 'CN'
                and t.dev_code_devise_dev = 'CNY'
                and t.tti_num_type_tiers_tti = m.tti_num_type_tiers_tir
                and t.tir_num_tiers = m.tir_num_tiers_tir
                and to_char(m.mar_date_ouverture, 'yyyymmdd') <= to_char(SYSDATE,'YYYYMMDD'))
        AND ELN_NUM_ELT_NIVEAU_ELN = 1
        AND ORG_NUM_ORGANISATION_ELN = 2
        AND NIV_NUM_NIVEAU_ELN = 6
        AND to_char(hcn_date, 'yyyymmdd') between '&&lastbegin.' AND '&&lastend.' -- CHANGE here 
        group by TIR_NUM_TIERS_TIR
        UNION
        SELECT TIR_NUM_TIERS_TIR as HCN_MAG,
            0 AS HCN_CA,
            0 AS HCN_QUANTITE,
            0 AS HCN_MARGE,
            0 AS HCN_RANG,
            0 AS PCT_MARGE,
            SUM(hln_nombre_clients) AS CLIENTS,
            0 AS OLD_CA,
            0 AS OLD_MARGE,
            0 AS OLD_CLIENTS,
            0 AS OLD_QTE,
            0 AS STOCK
        FROM stcom.HISTORIQUE_CLIENT_EN
        WHERE TTI_NUM_TYPE_TIERS_TIR = 7
        AND TIR_NUM_TIERS_TIR in
            (select t.tir_num_tiers
                from masterdatas.tiers_ref t, masterdatas.magasin_ref m
                where t.tti_num_type_tiers_tti = 7
                and t.pay_code_pays_pay = 'CN'
                and t.dev_code_devise_dev = 'CNY'
                and t.tti_num_type_tiers_tti = m.tti_num_type_tiers_tir
                and t.tir_num_tiers = m.tir_num_tiers_tir
                and to_char(m.mar_date_ouverture, 'yyyymmdd') <= to_char(SYSDATE,'YYYYMMDD'))
        AND ELN_NUM_ELT_NIVEAU_ELN = 1
        AND ORG_NUM_ORGANISATION_ELN = 2
        AND NIV_NUM_NIVEAU_ELN = 6
        AND to_char(hln_date, 'yyyymmdd') between '&&curbegin.' and '&&curend.' -- CHANGE here 
        group by TIR_NUM_TIERS_TIR
        UNION
        SELECT TIR_NUM_TIERS_TIR as HCN_MAG,
            0 AS HCN_CA,
            0 AS HCN_QUANTITE,
            0 AS HCN_MARGE,
            0 AS HCN_RANG,
            0 AS PCT_MARGE,
            0 AS CLIENTS,
            0 AS OLD_CA,
            0 AS OLD_MARGE,
            SUM(hln_nombre_clients) AS OLD_CLIENTS,
            0 AS OLD_QTE,
            0 AS STOCK
        FROM stcom.HISTORIQUE_CLIENT_EN
        WHERE TTI_NUM_TYPE_TIERS_TIR = 7
        AND TIR_NUM_TIERS_TIR in
            (select t.tir_num_tiers
                from masterdatas.tiers_ref t, masterdatas.magasin_ref m
                where t.tti_num_type_tiers_tti = 7
                and t.pay_code_pays_pay = 'CN'
                and t.dev_code_devise_dev = 'CNY'
                and t.tti_num_type_tiers_tti = m.tti_num_type_tiers_tir
                and t.tir_num_tiers = m.tir_num_tiers_tir
                and to_char(m.mar_date_ouverture, 'yyyymmdd') <= to_char(SYSDATE,'YYYYMMDD'))
        AND ELN_NUM_ELT_NIVEAU_ELN = 1
        AND ORG_NUM_ORGANISATION_ELN = 2
        AND NIV_NUM_NIVEAU_ELN = 6
        AND to_char(hln_date, 'yyyymmdd') between '&&lastbegin.'  and   '&&lastend.' -- CHANGE here 
        group by TIR_NUM_TIERS_TIR
        UNION
        SELECT TIR_NUM_TIERS_TIR as HCN_MAG,
            0 AS HCN_CA,
            0 AS HCN_QUANTITE,
            0 AS HCN_MARGE,
            0 AS HCN_RANG,
            0 AS PCT_MARGE,
            0 AS CLIENTS,
            0 AS OLD_CA,
            0 AS OLD_MARGE,
            0 AS OLD_CLIENTS,
            0 AS OLD_QTE,
            SUM(hsn_valeur_pvttc) AS STOCK
        FROM stcom.HISTORIQUE_STOCK_EN
        WHERE TTI_NUM_TYPE_TIERS_TIR = 7
        AND TIR_NUM_TIERS_TIR in
            (select t.tir_num_tiers
                from masterdatas.tiers_ref t, masterdatas.magasin_ref m
                where t.tti_num_type_tiers_tti = 7
                and t.pay_code_pays_pay = 'CN'
                and t.dev_code_devise_dev = 'CNY'
                and t.tti_num_type_tiers_tti = m.tti_num_type_tiers_tir
                and t.tir_num_tiers = m.tir_num_tiers_tir
                and to_char(m.mar_date_ouverture, 'yyyymmdd') <= to_char(SYSDATE,'YYYYMMDD'))
        AND ELN_NUM_ELT_NIVEAU_ELN = 1
        AND ORG_NUM_ORGANISATION_ELN = 2
        AND NIV_NUM_NIVEAU_ELN = 6
        AND TYS_TYPE_STOCK_TYS = '01'
        AND HSN_DATE =
            (SELECT MAX(HSN_DATE)
                FROM stcom.HISTORIQUE_STOCK_EN
                WHERE TTI_NUM_TYPE_TIERS_TIR = 7
                AND TIR_NUM_TIERS_TIR in
                    (select t.tir_num_tiers
                        from masterdatas.tiers_ref   t,
                             masterdatas.magasin_ref m
                        where t.tti_num_type_tiers_tti = 7
                        and t.pay_code_pays_pay = 'CN'
                        and t.dev_code_devise_dev = 'CNY'
                        and t.tti_num_type_tiers_tti =
                            m.tti_num_type_tiers_tir
                        and t.tir_num_tiers = m.tir_num_tiers_tir
                        and to_char(m.mar_date_ouverture, 'yyyymmdd') <=
                             to_char(SYSDATE,'YYYYMMDD'))
                AND ELN_NUM_ELT_NIVEAU_ELN = 1
                AND ORG_NUM_ORGANISATION_ELN = 2
                AND NIV_NUM_NIVEAU_ELN = 6
                AND tys_type_stock_tys = '01'
                AND to_char(HSN_DATE, 'yyyymmdd') <= '&&curend.'  -- CHANGE here 
                /* AND HSN_DATE <= to_date('20180601' , 'DD/MM/YYYY')*/
                )
        group by TIR_NUM_TIERS_TIR
        UNION
        SELECT TIR_NUM_TIERS_TIR as HCN_MAG,
            0 AS HCN_CA,
               0 AS HCN_QUANTITE,
            0 AS HCN_MARGE,
            0 AS HCN_RANG,
            0 AS PCT_MARGE,
            0 AS CLIENTS,
            0 AS OLD_CA,
            0 AS OLD_MARGE,
            0 AS OLD_CLIENTS,
            0 AS OLD_QTE,
            SUM(hsn_valeur_pvttc) AS STOCK
        FROM stcom.HISTORIQUE_STOCK_EN
        WHERE TTI_NUM_TYPE_TIERS_TIR = 7
        AND TIR_NUM_TIERS_TIR in
            (select t.tir_num_tiers
                from masterdatas.tiers_ref t, masterdatas.magasin_ref m
                where t.tti_num_type_tiers_tti = 7
                and t.pay_code_pays_pay = 'CN'
                and t.dev_code_devise_dev = 'CNY'
                and t.tti_num_type_tiers_tti = m.tti_num_type_tiers_tir
                and t.tir_num_tiers = m.tir_num_tiers_tir
                and to_char(m.mar_date_ouverture, 'yyyymmdd') <= to_char(SYSDATE,'YYYYMMDD'))
        AND ELN_NUM_ELT_NIVEAU_ELN = 1
        AND ORG_NUM_ORGANISATION_ELN = 2
        AND NIV_NUM_NIVEAU_ELN = 6
        AND TYS_TYPE_STOCK_TYS = '03'
        AND HSN_DATE =
            (SELECT MAX(HSN_DATE)
                FROM stcom.HISTORIQUE_STOCK_EN
                WHERE TTI_NUM_TYPE_TIERS_TIR = 7
                AND TIR_NUM_TIERS_TIR in
                    (select t.tir_num_tiers
                        from masterdatas.tiers_ref   t,
                               masterdatas.magasin_ref m
                        where t.tti_num_type_tiers_tti = 7
                        and t.pay_code_pays_pay = 'CN'
                        and t.dev_code_devise_dev = 'CNY'
                        and t.tti_num_type_tiers_tti =
                            m.tti_num_type_tiers_tir
                        and t.tir_num_tiers = m.tir_num_tiers_tir
                        and to_char(m.mar_date_ouverture, 'yyyymmdd') <=
                            to_char(SYSDATE,'YYYYMMDD'))
                AND ELN_NUM_ELT_NIVEAU_ELN = 1
                AND ORG_NUM_ORGANISATION_ELN = 2
                AND NIV_NUM_NIVEAU_ELN = 6
                AND tys_type_stock_tys = '03'
                AND to_char(HSN_DATE, 'yyyymmdd') <= '&&curend.' -- CHANGE here 
                /*AND HSN_DATE <= to_date('20180601' , 'DD/MM/YYYY')*/
                )
        group by TIR_NUM_TIERS_TIR)
 group by HCN_MAG
 order by HCN_MAG asc --PERFECO;
quit;
