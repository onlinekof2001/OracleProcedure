
--alter system kill session '173,7269';
col machine for a10

select 'alter system kill session ''' || s.sid || ',' ||s.serial# || ''' immediate;         ', S.SID,
'kill -9 ' || p.SPID cmd_kill_os,
       s.STATUS,
       s.sql_id,
       s.OSUSER,
       s.USERNAME,
       s.SCHEMANAME,
       s.MACHINE,
       s.PROGRAM,
       LAST_CALL_ET / 60 as last_active
       from  v$session S inner join v$process p on  s.paddr = p.addr
 where  sid =&1 
 order by last_active ;

 
 

select 'alter system kill session ''' || s.sid || ',' ||s.serial# || ''' immediate ; ' cmd_kill, 
       S.SID ,
       'kill -9 ' || p.SPID cmd_kill_os,
       s.STATUS,
       s.LAST_CALL_ET / 60 as last_act_min,
       s.OSUSER,
       s.USERNAME,
       s.SCHEMANAME,
       substr(s.MACHINE,1,30) MACHINE,
       s.PROGRAM program ,
       s.service_name ,
       s.logon_time
       from v$session S inner join v$process p on  s.paddr = p.addr
	    where  sid =&1 
 order by last_active ;