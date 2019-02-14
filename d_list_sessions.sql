--   list all session on the database
set tab off
--set colsep ";"
set feed off
set hea on
set echo off
set lines 1024
set pages 100
set serveroutput on
set ver off


set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
COLUMN 1 NEW_VALUE 1
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;
set term on 

	
column s.username         			format A12
column commande        				format A13
column machine        				format A15
column s.status          				format A8
column logon        			  	format A14
column command         				format 99
column sid           				format 9999
column serial         				format 99999
column spid           	 			format a10
column terminal       				format A11
column lockwait       				format A8
column program        				format A35   word_wrapped

column last_call_et heading "Last|Call"		 		      format A10
column osuser  for a15
set ver on	
select s.sid
--     , s.serial# serial
	 , substr(s.status,1,8) "s.status"
     --, p.pid 
     , p.spid
     , substr(s.username,1,12) "s.username"
	 , osuser osuser
     , substr(machine,1,15) machine
	 , round(LAST_CALL_ET / 60,1)  as status_min
     , sql_id --,plan_hash_value
	 , prev_sql_id
     , s.command
     , decode(s.command, 1,'Create table'          , 2,'Insert'
                       , 3,'Select'                , 6,'Update'
                       , 7,'Delete'                , 9,'Create index'
                       ,10,'Drop index'            ,11,'Alter index'
                       ,12,'Drop table'            ,13,'Create seq'
                       ,14,'Alter sequence'        ,15,'Alter table'
                       ,16,'Drop sequ.'            ,17,'Grant'
                       ,19,'Create syn.'           ,20,'Drop syn.'
                       ,21,'Create view'           ,22,'Drop view'
                       ,23,'Validate index'        ,24,'create proced.'
                       ,25,'Alter procedure'       ,26,'Lock table'   
                       ,42,'Alter session'         ,44,'Commit'
                       ,45,'Rollback'              ,46,'Savepoint'
                       ,47,'PL/SQL Exec'           ,48,'Set Transaction'
                       ,60,'Alter trigger'         ,62,'Analyse Table'
                       ,63,'Analyse index'         ,71,'Create Snapshot Log'
                       ,72,'Alter Snapshot Log'    ,73,'Drop Snapshot Log'
                       ,74,'Create Snapshot'       ,75,'Alter Snapshot'
                       ,76,'drop Snapshot'         ,85,'Truncate table'
                       , 0,'No command', '? : '||s.command) commande
       , to_char(s.logon_time,'DD-MM-YY HH24:MI') logon
       , floor(s.last_call_et/3600)||':'||
         floor(mod(s.last_call_et,3600)/60)||':'||
         mod(mod(s.last_call_et,3600),60)        last_call_et
       , s.lockwait
       , Substr(s.program,1,25) program
	   , service_name
  from 
       v$session s
     , v$process p
 where  
       s.paddr  =  p.addr
     &1 
 order 
     by s.status desc
      , s.last_call_et desc
  , P.spid
;


clear col
undef 1 2 3 4 5 6 7 8 9 
