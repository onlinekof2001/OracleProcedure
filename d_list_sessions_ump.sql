-----------------------------------------------------------------------------------------------------
---   d_list_sessions_ump.sql                                                                    ----
-----------------------------------------------------------------------------------------------------
--- list all session on dabases 
--set tab off
set colsep ";"
--set feed off
--set hea off
set echo off
set lines 1024
set pages 5000
set serveroutput on
set ver off

set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
COLUMN 1 NEW_VALUE 1
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;
set term on 

col name for A20 trunc


--@@10g-log_hash_value_lag.sql 3hfrdz3s108fc
column username     heading "Utilis."           			format A15
column commande     heading "Fonction"        				format A13
column status       heading "Etat"            				format A4
column logon        heading "Date|Connexion"			  	format A14
column command      heading "C"               				format 99
column sid          heading "Id"            				format 9999
column serial       heading "Serial#"        				format 99999
column spid         heading "Unix"           	 			format A7
column terminal     heading "Terminal"       				format A11
column lockwait     heading "Lockwait"       				format A8
column program      heading "Programme"      				format A40   word_wrapped
column nb_sess      heading "Nb. Sess."       				format 9999999
column last_call_et heading "Last|Call"	                    format A9
prompt ----------------------------------------------------
prompt
prompt -- pour kill

prompt
prompt --list session by username, machine, program
set ver off
COMPUTE SUM OF nb on report;
break on report
select  
     s.username ,
     s.machine ,
     s.program ,
     count(1) nb
--	 service_name
  from 
       v$session s
     , v$process p
 where  
       s.paddr  =  p.addr
       &&1
group by
       s.username
     , s.machine
     , s.program
order by username, machine, program

/


---
clear compute
clear col
undef 1 2 3 4 5 6 7 8 9