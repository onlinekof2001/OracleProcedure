create or replace procedure repl_w_model_swap_plan as
	v_row w_model_swap_plan@replica_prdrefc_wmsp%rowtype;
	v_wrow w_model_swap_plan%rowtype;
	v_sql varchar2(2000);
begin
	for v_row in (SELECT * FROM w_model_swap_plan@replica_prdrefc_wmsp p WHERE
				  p.w_msp_dpp_ean IN (3018000996367,3018000837387,3018000866363,3018000671752,3018000678164,3018000713841,3018000771728,3018000905475,3018000922793,3018000837394,3018000726971,3018000728951,3018000728968,3018000837370,3018000905369,3018000724977,3018000726391,3018000731425,3018000764928,3018000845719,3018000919120,3018000710826,3018000845542,3018000972439,3018000609007)) loop
		for v_wrow in (select * from w_model_swap_plan where (W_MSP_COF_REF_CODE_REF||','||W_MSP_DPP_EAN||','||W_MSP_CREATION_DATE) not in (v_row.W_MSP_COF_REF_CODE_REF||','||v_row.W_MSP_DPP_EAN||','||v_row.W_MSP_CREATION_DATE) and rownum < 2) loop
			--dbms_output.put_line(v_row.W_MSP_COF_REF_CODE_REF||','||v_row.W_MSP_DPP_EAN||','||v_row.W_MSP_CREATION_DATE);
			v_sql := 'INSERT INTO w_model_swap_plan values ('''||v_row.W_MSP_COF_REF_CODE_REF||''','''||v_row.W_MSP_DPP_EAN||''','||v_row.W_MSP_IU_CODE||v_row.W_MSP_IU_LABEL||','''||v_row.W_MSP_IU_LABEL||''','||v_row.W_MSP_TECH_FAM||','''||v_row.W_MSP_PURCHASING_GROUP||''','''||v_row.W_MSP_CZ_THIRD||''','||to_char(v_row.W_MSP_CREATION_DATE,'yyyy-mm-dd hh24:mi:ss')||','||to_char(v_row.W_MSP_TECH_UPDATED_DATE,'yyyy-mm-dd hh24:mi:ss')||','||v_row.W_MSP_USER_ID||')';
			dbms_output.put_line(v_sql);
		end loop;
	end loop;
end;
/

 CREATE MATERIALIZED VIEW w_model_swap_plan
  TABLESPACE "PRDREFC_SNAP_DATA"
  BUILD IMMEDIATE
  USING INDEX TABLESPACE "PRDREFC_SNAP_INDEX"
  REFRESH COMPLETE
  AS SELECT *
  FROM w_model_swap_plan@replica_prdrefc_wmsp p
 WHERE p.w_msp_dpp_ean IN (3018000996367,
                           3018000837387,
                           3018000866363,
                           3018000671752,
                           3018000678164,
                           3018000713841,
                           3018000771728,
                           3018000905475,
                           3018000922793,
                           3018000837394,
                           3018000726971,
                           3018000728951,
                           3018000728968,
                           3018000837370,
                           3018000905369,
                           3018000724977,
                           3018000726391,
                           3018000731425,
                           3018000764928,
                           3018000845719,
                           3018000919120,
                           3018000710826,
                           3018000845542,
                           3018000972439,
                           3018000609007);
						   

exec dbms_mview.refresh('prdrefc.w_model_swap_plan');

begin
dbms_scheduler.create_job(job_name=>'J_PRDREFC',job_type=>'PLSQL_BLOCK',
job_action=>'begin
exec dbms_mview.refresh(''prdrefc.w_model_swap_plan''); /* there is an error about this procedure*/
end;',
number_of_arguments=>0,
start_date=>TO_TIMESTAMP_TZ('10-DEC-2018 00.00.00.000000000 AM ASIA/SHANGHAI','DD-MON-RRRR HH.MI.SSXFF AM TZR','NLS_DATE_LANGUAGE=english'), 
repeat_interval=>'FREQ=DAILY;BYHOUR=7,12;BYMINUTE=0;BYSECOND=0', 
end_date=>NULL,
job_class=>'"DEFAULT_JOB_CLASS"', enabled=>FALSE, auto_drop=>FALSE,comments=>'w_model_swap_plan refresh job from tetrixce_proda1odb01');
dbms_scheduler.enable('"J_PRDREFC"');
end;
/

BEGIN
DBMS_SCHEDULER.SET_ATTRIBUTE (
name => 'prdrefc.J_PRDREFC_WMSP',
attribute => 'job_action',
value => 'begin
dbms_mview.refresh(''prdrefc.w_model_swap_plan'');
end;');
END;
/
