----- ######################################################### 
----- Auteur : Pascal
-----
-----  list the locks on a database
-----
----- and list the blocking locks on a database
----- #########################################################

set lines 400

set wrap on
set trim on

col usr heading 'user' for a30
col username heading 'user' for a30
col b heading 'type' for A8
col sid heading 'sid' for A10
col ltype for A2
col machine for A17 trunc
col program for A20 trunc
col lmode for A15
col text for A50 trunc
col kill for a60
col obj heading 'obj' for A120
set head on
set echo off
set pagesize 500

prompt detail
select   s.inst_id,(lpad(' ',DECODE(request,0,0,5))||S.username) "USR",
          decode(request,0,'BLOQUEUR','WAITEUR') "B",
          to_char(L.SID) "SID",
          id1,
          id2,
	  S.machine ,
	  S.program ,
	  L.TYPE "LTYPE",
          substr(decode(LMODE,0,'0 : NONE_____',2,'2 : Row Share',4,'4 : Share__',6,'6 : Exclusive',to_char(lmode)),1,15) "LMODE",
          REQUEST ,
         -- txt.SQL_TEXT "text",
          l.ctime/60,
		  'alter system kill session '''||s.sid||','||serial#||''';' kill,
		  'SELECT * FROM ' ||o.owner ||'.'||o.object_name ||' WHERE rowid =  DBMS_ROWID.ROWID_CREATE(1, '||s.ROW_WAIT_OBJ#||', '||s.ROW_WAIT_FILE# ||', '||s.ROW_WAIT_BLOCK#||', '||s.ROW_WAIT_ROW#||');' obj
		  from gv$lock L,gv$session S
		  left outer join dba_objects o on object_id=ROW_WAIT_OBJ#
		  --, V$SQLAREA TXT
          WHERE L.sid = s.sid and L.inst_id=s.inst_id
         -- and S.SQL_HASH_VALUE = TXT.HASH_VALUE(+)
         -- and S.SQL_ADDRESS = txt.ADDRESS(+)
          AND id1 IN (SELECT id1 FROM gV$LOCK WHERE lmode = 0)
order by l.ctime/60 desc;
set lines 1024
	
col sid clear
prompt hierarchique
select 
(lpad(' ',LEVEL)||username) "USR",
a.* 
from (select username, sid, blocking_session,  MACHINE ,PROGRAM ,'alter system kill session '''||sid||','||serial#||''';' kill,  
    round(seconds_in_wait/60,1) minute_in_wait,  nvl(sql_id,0), sql_address,  wait_class, event, p1, p2, p3
	from v$session
	where blocking_session_status = 'VALID'
	OR sid IN (select blocking_session
	from v$session where blocking_session_status = 'VALID')) a
	start with blocking_session is null
	connect by prior sid=blocking_session;
	
	
clear columns



