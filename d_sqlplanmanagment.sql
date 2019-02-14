-- #################################################################################################
-- this script create the better  plan base line  for a sqlid
-- the better plan baseline is the plan with the better response time in th AWS
-- #################################################################################################


set SERVEROUT on

--SELECT * FROM table (DBMS_XPLAN.DISPLAY_SQLSET('temp_sql_tuning_set','690859ngxfq2u'));
set verify off
DECLARE
  st        VARCHAR2(4000);
  SQLID     VARCHAR2(50):='&1';
  plan_hash VARCHAR2(50);
  L_CURSOR  DBMS_SQLTUNE.SQLSET_CURSOR;
  BEGIN_SNAP NUMBER;
  END_SNAP NUMBER;
  MY_PLANS PLS_INTEGER;
BEGIN
  DBMS_OUTPUT.enable;
  SELECT plan_hash_value
  INTO plan_hash
  FROM
    (SELECT hp.plan_hash_value,
      ROUND(AVG(executions_delta),2) EXECS_prSnap,
      ROUND(AVG(cpu_time_delta    /1000/1000/executions_delta) ,3) CPUTime_prX,
      ROUND(AVG(elapsed_time_delta/1000/1000/executions_delta) ,3) Seconds_prX
    FROM dba_hist_sqlstat stat,
      DBA_HIST_SQL_PLAN hp,
      dba_hist_snapshot snap
    WHERE stat.snap_id           = snap.snap_id
    AND hp.sql_id                   =SQLID
    AND executions_delta         > 0
    AND snap.begin_interval_time > add_months (sysdate,-1)
    and HP.PLAN_HASH_VALUE=STAT.PLAN_HASH_VALUE
    GROUP BY hp.plan_hash_value
    ORDER BY 4
    )
  WHERE rownum=1;
  
--  plan_hash:='4087313827';
  DBMS_OUTPUT.PUT_LINE('Plans selected: ' || plan_hash);
  begin
  DBMS_SQLTUNE.drop_sqlset(sqlset_name => 'temp_sql_tuning_set');
  EXCEPTION
  WHEN OTHERS THEN
   NULL;
  END;
  DBMS_SQLTUNE.CREATE_SQLSET(SQLSET_NAME => 'temp_sql_tuning_set',DESCRIPTION => 'sql plan management temporaire');
  SELECT MAX(SNAP_ID)
  INTO END_SNAP
  FROM DBA_HIST_SNAPSHOT
  WHERE END_INTERVAL_TIME >= SYSDATE-1/24;
  SELECT MIN(SNAP_ID)
  INTO BEGIN_SNAP
  FROM DBA_HIST_SNAPSHOT
  WHERE END_INTERVAL_TIME >= SYSDATE-45;
  begin
  OPEN l_cursor FOR SELECT VALUE(p) FROM TABLE (DBMS_SQLTUNE.select_workload_repository ( begin_snap=>begin_snap, end_snap=>end_snap, basic_filter=>'sql_id='''||SQLID||''' and plan_hash_value='''||plan_hash||'''',attribute_list=>'ALL')) p;
  dbms_output.put_line('1');
--  OPEN l_cursor FOR SELECT VALUE(p) FROM TABLE (DBMS_SQLTUNE.select_workload_repository ( begin_snap=>32933, end_snap=>34013, basic_filter=>'sql_id=''8ud2v787favg3'' and plan_hash_value=''156643930''',attribute_list=>'ALL')) p;
  DBMS_OUTPUT.PUT_LINE('SELECT * FROM TABLE (DBMS_SQLTUNE.select_workload_repository ( begin_snap=>'||begin_snap||', end_snap=>'||end_snap||', basic_filter=>''sql_id='''''||SQLID||''''' and plan_hash_value='''''||plan_hash||'''''''));');
  
  DBMS_SQLTUNE.load_sqlset ( sqlset_name => 'temp_sql_tuning_set', populate_cursor => l_cursor);
  MY_PLANS := DBMS_SPM.LOAD_PLANS_FROM_SQLSET( SQLSET_NAME => 'temp_sql_tuning_set',fixed =>'YES');
  exception
  when others then
   DBMS_OUTPUT.PUT_LINE(SQLERRM);
  end;
  DBMS_OUTPUT.PUT_LINE('Number of Plans Plans Loaded: ' || MY_PLANS);
  DBMS_SQLTUNE.drop_sqlset(sqlset_name => 'temp_sql_tuning_set');
END;
/

