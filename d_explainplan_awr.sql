

---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable planhashvalue number
COLUMN 2 NEW_VALUE 2
SELECT 2 "2" FROM DUAL WHERE ROWNUM = 0;
set term on

begin
        :planhashvalue :=nvl('&&2',null);
end;
/
select '&&1' c1, :planhashvalue pl from dual;
select * from table(dbms_xplan.DISPLAY_AWR('&1', :planhashvalue ,null,'advanced'));

undef 1 2 3 4 
undef planhashvalue
