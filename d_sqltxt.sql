rem ********************************************************************************
rem ********************************************************************************
rem who : pascal BEN
rem
rem FUNCTION
rem   display the query of an SQL_ID
rem
rem
rem ********************************************************************************
rem ********************************************************************************
set verify off
col sql_text for a132 wor;
select '1-' ,sql_id, dbms_lob.substr(sql_text ,3000,1) sql_text from dba_hist_sqltext  where sql_id ='&1'
union 
select '2-', sql_id,dbms_lob.substr(sql_text ,3000,3001) sql_text from dba_hist_sqltext  where sql_id ='&1'
order by 1;

col sql_text clear;
