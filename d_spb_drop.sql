----- ######################################################### 
----- Auteur : Pascal
-----
-----  delete a sql plan baseline
-----
----- #########################################################



set verify off
DECLARE
 i NATURAL;
BEGIN
  i := dbms_spm.drop_sql_plan_baseline(plan_name => '&&1');
  dbms_output.put_line('number of Sql Plan Baseline dropped :' ||i);
END;
/
undefine 2
undefine 1


