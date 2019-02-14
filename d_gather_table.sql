--- List tables/mviews used by a query.
--- Author : Pascal BEN 

--- Parameter : 
---        tab_owner : mandatory
---        tab_name  : mandatory
---        degree    : degree of parallelism (default = DBMS_STATS.DEFAULT_DEGREE)
---        execute   : if <> null, only display the commande
---
--- 
---

set verify  off
set echo off
set feed off

set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable nbh  number
COLUMN 1 NEW_VALUE 1
COLUMN 2 NEW_VALUE 2
COLUMN 3 NEW_VALUE 3
COLUMN 4 NEW_VALUE 4
SELECT '1' "1", '2' "2", '3' "3", '4' "4" FROM DUAL WHERE ROWNUM = 0;

define tab_own=&1 
define tab_name=&2
define execute=&3 ""
define degree=&4 "DBMS_STATS.DEFAULT_DEGREE"


set term on
declare 
    command varchar2(1000);
begin 
    command:='exec DBMS_STATS.GATHER_TABLE_STATS (''&tab_own'',''&tab_name'',degree=>&degree,method_opt=>''FOR ALL COLUMNS SIZE AUTO'',cascade => true,force=>true)';
    if '&execute' = '' then
        dbms_output.put_line ('executing command '||command);
--        exec command;
    else
        dbms_output.put_line ('you can execute command '||command);
    end if;
end;
/


clear col
undef 1 2 3 4 5 6 7 8 9
undef TAB_OWN TAB_NAME DEGREE EXECUTE ACTION command