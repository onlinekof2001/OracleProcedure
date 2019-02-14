rem ********************************************************************************
rem ********************************************************************************
rem
rem NAME
rem   TRANSACTIONS.SQL
rem
rem FUNCTION
rem   display : 
rem      1) the running transaction
rem      2) the recovering transaction (exemple session killed so not listed in the previous list)
rem
rem
rem ********************************************************************************
rem ********************************************************************************

  
  
clear columns
col username for a20
prompt list of running trascation.
SELECT a.inst_id,a.sid, a.username,a.last_call_et, b.xidusn, b.used_urec, /*b.used_ublk,*/ round((b.used_ublk*8)/1024,2) used_MO, start_time , sysdate, machine
  FROM gv$session a, gv$transaction b
  WHERE a.saddr = b.ses_addr
  and a.inst_id = b.inst_id;

prompt list of recovering transaction (exemple session killed so not listed in the previous list)
select usn, state, undoblockstotal "Total", undoblocksdone "Done", undoblockstotal-undoblocksdone "ToDo", decode(cputime,0,'unknown',
sysdate+(((undoblockstotal-undoblocksdone) / (undoblocksdone / cputime)) / 86400))  "Estimated time to complete" from v$fast_start_transactions;

clear columns