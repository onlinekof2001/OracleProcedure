col cmd_kill for a55
col sid for 99999
col status for a15
col last_active_minutes for 999999.99
col osuser for a15
col username for a15
col schemaname for a15
col MACHINE  for a25  truncate
col program for a35 truncate
col service_name for a30  
col cmd_kill_os for a18
col status_min for 99999.999
col sql_id  for a14

 set colsep "|"

--set numf 999999.99
select 'alter system kill session ''' || s.sid || ',' ||s.serial# || ''' immediate ; ' cmd_kill, 
       S.SID ,
       'kill -9 ' || p.SPID cmd_kill_os,
       s.STATUS,
       s.LAST_CALL_ET / 60 as status_min,
	   s.sql_id,
       s.OSUSER,
       s.USERNAME,
       s.SCHEMANAME,
       s.MACHINE,
       s.PROGRAM program ,
       s.service_name ,
       s.logon_time
       from v$session S inner join v$process p on  s.paddr = p.addr
 where  sql_id='&1'
 order by service_name, status_min desc;

 undef 1
clear col
--set numf ""
 ---------------------