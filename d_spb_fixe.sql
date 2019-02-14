SET SERVEROUTPUT ON


---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable w_fixe  varchar2(3)
variable w_sqlh  varchar2(15)
variable w_pn  varchar2(30)
COLUMN 1 NEW_VALUE 1
COLUMN 2 NEW_VALUE 2
COLUMN 3 NEW_VALUE 3
set term off
set verify off
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;
begin
	:w_sqlh :=nvl('&&1','help');
	:w_pn   :=nvl('&&2','help');
	:w_fixe :=nvl('&&3','YES');
end;
/
set term on




DECLARE
  l_plans_altered  PLS_INTEGER;
BEGIN
  if  :w_sqlh = 'help' or :w_pn = 'help'  then 
      dbms_output.put_line ('Script to FIXE or  UNFIXE a Sql Plan Baseline (by default fixe )');
      dbms_output.put_line ('@d_spb_fixe: SQL Handle');
      dbms_output.put_line ('   param 1 : SQL Handle');
      dbms_output.put_line ('   param 2 : plan name');
      dbms_output.put_line ('   param 1 : YES/NO (default : yes)');
  else 
      l_plans_altered := DBMS_SPM.alter_sql_plan_baseline(
        sql_handle      => '&&1',
        plan_name       => '&&2',
        attribute_name  => 'fixed',
        attribute_value => :w_fixe);
  
      if upper(:w_fixe)  = 'YES' 
      then
          DBMS_OUTPUT.put_line('number of plan ENABLE  : ' || l_plans_altered);
      else
          DBMS_OUTPUT.put_line('number of plan DISABLE : ' || l_plans_altered);
      end if;
  end if;
END;
/
undefine 1 2 3 
undef  w_fixe 
