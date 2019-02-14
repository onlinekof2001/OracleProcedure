column date_start    new_value date_start   format a20 heading 'date_start';
column date_end      new_value date_end     format a20 heading 'date_end';
variable nbj number
set term off
set ver off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
COLUMN 1 NEW_VALUE 1
SELECT 1 "1" FROM DUAL WHERE ROWNUM = 0;


begin
	:nbj :=nvl('&&1',1);
end;
/


set feed off
set verif off
select to_char(sysdate-:nbj/24,'DD/MM/YY hh24')||':00:00' date_start ,to_char(sysdate+1/24,'DD/MM/YY hh24')||':05:00' date_end from dual;
set feed on
@d_init_variable.sql

prompt
prompt ===========> PAST ACTIVITY 
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
Prompt | scripts and parameters                                                             | comments                                                    | paramters                                      | 
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
prompt | @d_awr_database_activity.sql          2                                            | AWR display the past activity of the database               | nb days                                        |  
prompt | @d_awr_database_activity-windows      5                                            | AWR display the past activity of the database  night &. day | nb days                                        | 
--prompt | @d_awr_new_hash_value                                                              |                                                                     |                                                |
prompt | @d_awr_sqlstat              cpu      '&date_start' '&date_end' 3 5   | AWR SQL ordered by CPU time                                 | report type, beg_date, end_date, level, nb qry | 
prompt | @d_awr_sqlstat              reads    '&date_start' '&date_end' 3 5   | AWR SQL ordered by reads                                    | report type, beg_date, end_date, level, nb qry |  
prompt | @d_awr_sqlstat              gets     '&date_start' '&date_end' 3 5   | AWR SQL ordered by Gets                                     | report type, beg_date, end_date, level, nb qry |  
prompt | @d_awr_sqlstat              elapse   '&date_start' '&date_end' 3 5   | AWR SQL ordered by elaps time                               | report type, beg_date, end_date, level, nb qry |  
prompt | @d_awr_hi_execs                      '&date_start' '&date_end' 3 5   | AWR SQL ordered by execs                                    | beg_date , end_date, level, nb query           |  
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
--prompt @awrrptd.sql                   '&date_start' '&date_end' 
--prompt @awrsqrptd.sql                 '&date_start' '&date_end' 'sqlid'
prompt
prompt ===========>  retreive bind variable for a query and others various scripts
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
Prompt | scripts and parameters                                                             | comments                                                    | paramters                                      | 
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
prompt | @d_bind_v                        sqlid                                             | display query replace bind variable by their values         |                                                |
prompt | @d_bind_awr                      sqlid                                             | display query replace bind variable  by their values        |                                                | 
prompt | @d_sqlplanmanagment              sqlid                                             | add the best plan in sql plan baseline                      |                                                |
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------|
prompt | @d_awr_sqlinfo                   sqlid , 5                                         | list performance information about a query                  | sql_id, detail level                           |
prompt | @d_explainplan_awr               sqlid  [planhashvalue]                            | display the explain plan for query                          |                                                |
prompt | @d_sqlstat                       sqlid                                             | list table use by the sql, the last analyse and command to  |                                                |
prompt |                                                                                    | rebuild statistics                                          |                                                |
prompt | @d_sqltxt                        sql_id                                            | display the text of query                                   | sql_id                                         |
prompt | @d_spb_drop                      plan_name                                         | drop a plan from sql plan baseline.                         |                                                |
prompt |                                                                                    | can be use with sqlinfo to drop a bad plan base line        |                                                |
prompt | @d_spb_fixe                      SqlHandle PlanName  [(YES)|NO]                    | fixe or un fixe a spb (by default fixe ON)                  |                                                |
prompt | @d_index                         [owner] table_name                                | display indexes on table, owner is not mandatory            |                                                |
prompt | @d_table                         [owner] table_name                                | display description of the table                            |                                                |
prompt | @d_gather_table schema tablename {exec|noexec} [degree]                            | display or gather the stats for one table and their indexes | schema tablename {exec|noexec} [degree]        |
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------|
prompt
prompt ===========> Current activity 
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
Prompt | scripts and parameters                                                             | comments                                                    | paramters                                      | 
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
prompt | @d_active_sessions                1                                                | list the 10 most consumer query     / hour                  | hour                                           |
prompt | @d_active_sessions_min           .5                                                | list the 10 most consumer query     / 5 min                 | nb hour                                        |
prompt | @d_active_sessions_cpu_min       .5                                                | list the 10 most consumer query cpu  / 5 min                | nb hour                                        |
prompt | @d_transactions                                                                    | list the running transactions                               |                                                |
prompt | @d_locks                                                                           | list the blocking sessions                                  |                                                |
prompt | @d_top_activity                  .5                                                | same than top activity in grid                              | nb hour                                        |
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
prompt
prompt

undef date_start date_end
undef nbj

set verif on
clear col
undef 1 2 3 4 5 6 7 8 9
