-- #######################################################################################################
-- This script list the SQL Statistic like in awr report 
-- It allows 4 types of report 
--    SQL ordered by CPU Time
--    SQL ordered by Gets
--    SQL ordered by Reads
--    SQL ordered by Elapse time
--
-- THE PARAMETERS 
--  1st type of statistics like SQL Statistics in awr report 
--      cpu    : SQL ordered by CPU Time
--      gets   : SQL ordered by Gets
--      reads  : SQL ordered by Reads
--      elapse : SQL ordered by Elpase Time
--  2d parameters begin date 
--  3d  parameters end date 
--  4th report level detail 
--      0 sqltext, report header, column header, stat 
--      1 sqltext, no header 
--      2 report header, column header, stat 
--      3 column header, stats
--      4 stats : no header, ...
--  5th number of sql_id listed 


	set timing off veri off space 1 flush on pause off 
	set echo off feedback off 

----------------------------------------------------------------------
--------  INIT ------------------------------------------------------
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
---- if a parameter is not given, the value is null.
	set term off
    alter session set nls_date_format='DD/MM/YY HH24:MI:SS';
	COLUMN 1 NEW_VALUE 1
	COLUMN 2 NEW_VALUE 2
	COLUMN 3 NEW_VALUE 3
	COLUMN 4 NEW_VALUE 4
	COLUMN 5 NEW_VALUE 5
	SELECT 1 "1", 2 "2", 3 "3", 4 "4" , 1 "5" FROM DUAL WHERE ROWNUM = 0;
	
	set term off
	
	column type_stat            new_value type_stat 
	column beg_date            new_value beg_date 
	column end_date               new_value end_date 
	column silent              new_value silent
	column nbreq              new_value nbreq
	select lower(nvl('&&1','help')) type_stat, nvl('&&2',s.begin_interval_time-5/24/60) beg_date, nvl('&&3',s.end_interval_time+1/24/60/60) end_date, nvl('&&4','3')  silent, nvl('&&5','5') nbreq
	from dba_hist_snapshot s where snap_id in (select max(snap_id) from dba_hist_snapshot );

	set term on
--####################################################################
--####################################################################
--   
	column head_total_stat            new_value head_total_stat 
	column head_pct_total             new_value head_pct_total 
	column head_stat_query            new_value head_stat_query 
	column col_sql_stat               new_value col_sql_stat 
	column sys_stat_name              new_value sys_stat_name

	set term off
	select * from        (select 'physical reads' sys_stat_name, 'reads' head_stat_query, 'Total_read' head_total_stat ,'disk_reads_delta' col_sql_stat,'% total read'  head_pct_total from dual where '&type_stat' ='reads')
	union  select * from (select 'session logical reads' sys_stat_name, 'gets ' head_stat_query, 'Total_gets' head_total_stat ,'buffer_gets_delta' col_sql_stat,'% get'  head_pct_total from dual  where '&type_stat' ='gets')
	union select * from  (select 'DB CPU' sys_stat_name, 'cpu ' head_stat_query, 'Total_cpu' head_total_stat ,'cpu_time_delta' col_sql_stat,'% Total Cpu'  head_pct_total from dual  where  '&type_stat' ='cpu' )
	union select * from  (select 'DBTIME' sys_stat_name, 'elapse ' head_stat_query, 'Dbtime' head_total_stat ,'elapsed_time_delta' col_sql_stat,'% DBTIME'  head_pct_total from dual  where  '&type_stat' ='elapse' )
	;
--####################################################################	

	
----------------------------------------------------------------------
----------------------------------------------------------------------
--------  HELP  ------------------------------------------------------
	set term on
	set verify off
	set serveroutput on
	begin
		if ('&&type_stat'  = 'help'  or '&sys_stat_name' = '')  then
			dbms_output.put_line ('##################################################### ');	
			dbms_output.put_line ('This script list the SQL Statistic like in awr report ');
			dbms_output.put_line ('THE PARAMETERS ');
			dbms_output.put_line ('.  1st type of statistic ');
			dbms_output.put_line ('.      cpu    : SQL ordered by CPU Time');
			dbms_output.put_line ('.      gets   : SQL ordered by Gets');
			dbms_output.put_line ('.      reads  : SQL ordered by Reads');
			dbms_output.put_line ('.      elapse : SQL ordered by elapse time');
			dbms_output.put_line ('.  2d parameters begin date ');
			dbms_output.put_line ('.  3d  parameters end date ');
			dbms_output.put_line ('.  4th report level detail ');
			dbms_output.put_line ('.      0 sqltext, report header, column header, stat ');
			dbms_output.put_line ('.      1 sqltext, no header ');
			dbms_output.put_line ('.      2 report header, column header, stat ');
			dbms_output.put_line ('.      3 column header, stats');
			dbms_output.put_line ('.      4 stats : no header, ...');
			dbms_output.put_line ('.  5th number of sql_id listed ');
			dbms_output.put_line ('##################################################### ');			
	  end if;
	end;
	/
----------------------------------------------------------------------


set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 150 linesize 95 newpage 1 recsep off;
set trimspool on trimout on;



set term on


--####################################################################
--####################################################################
-- read global information in database 
	column inst_num  heading "Inst Num"  new_value inst_num  format 99999;
	column inst_name heading "Instance"  new_value inst_name format a12;
	column db_name   heading "DB Name"   new_value db_name   format a30;
	column dbid      heading "DB Id"     new_value dbid      format 9999999999 just c;
	set term off
	set head off
	select d.dbid            dbid
		 , d.DB_UNIQUE_NAME  db_name
		 , i.instance_number inst_num
		 , i.instance_name   inst_name
	  from v$database d,
		   v$instance i;
		   

	set underline off

	-- I display information if asked
	set term on
	set head on 
	select '&dbid' db_id  ,'&db_name' db_unique_name,'&inst_num' instance_number,'&inst_name' instance_name from dual where    &silent in (0, 2) or &silent is null;
	set underline off

--####################################################################

--####################################################################
--####################################################################
-- Becarefull 
-- for the report I take the number of snapshot : N
-- for the display I take the number of snapshot - 1 ( N-1) to have the same than in AWR.
	set term off

	column b_snap_id            new_value b_snap_id format 99999990 heading 'b_Snap Id';
	column e_snap_id            new_value e_snap_id format 99999990 heading 'e_Snap Id';
	column b_snap_time          new_value b_snap_time  format 99999990 heading 'b_Snaptime';
	column e_snap_time          new_value e_snap_time  format 99999990 heading 'e_snap_time';
	set head off
	select min(ss.snap_id) b_snap_id, max(ss.snap_id) e_snap_id,  to_char(min(ss.END_interval_time),'DD/MM/YY HH24:MI:SS') b_snap_time, to_char(max(ss.end_interval_time),'DD/MM/YY HH24:MI:SS') e_snap_time
	from dba_hist_snapshot ss
	where ss.end_interval_time between to_date('&&beg_date','DD/MM/YY HH24:MI:SS') and to_date('&&end_date','DD/MM/YY HH24:MI:SS');

	set term on
	set head on
	select &&b_snap_id BEGIN_SNAP_ID   ,&&e_snap_id  END_SNAP_ID,'&b_snap_time' BEGIN_SNAP_TIME,'&e_snap_time' END_SNAP_TIME from dual where     &&silent in (0, 2) or &&silent is null;
--####################################################################




--####################################################################
--####################################################################
	set term off
	
	-- for the sql stat I use the delta column, and so I must take the previous snapshot.
	-- pour les stat sql je travail avec la colonne delta, pour cela je prend le snap_id suivant.
	column b_snap_id_delta            new_value b_snap_id_delta format 99999990 heading 'b_snap_id_delta Id';
	select min(ss.snap_id) b_snap_id_delta 
		from dba_hist_snapshot ss
		where ss.begin_interval_time >to_date('&beg_date','DD/MM/YY HH24:MI:SS') ;
--####################################################################

/*
memo
'physical reads' sys_stat
'session logical reads' s
'DB CPU' sys_stat_name, '
*/

--####################################################################
--####################################################################
-- I read the statistics for the global instance
-- I use the snap_id begin and end display by awr.
-- I read the total_disk read for the period.
		set term on
		variable total_interval_stat        number;
		variable total_physical_read        number;
		variable total_logical_read         number;
		variable total_db_cpu               number;
		variable total_db_time              number;
		declare 
			test varchar2(2);
			v_eval   varchar2(10);
			v_msg    VARCHAR(20);
		begin
        	SELECT es.value-bs.value    into :total_physical_read
				FROM   v$database d,
					   DBA_HIST_SYSSTAT bs,
					   DBA_HIST_SYSSTAT es
				WHERE  
						(bs.snap_id = &&b_snap_id AND bs.dbid = &&dbid  AND bs.instance_number = &inst_num)
					   AND (es.snap_id = &&e_snap_id AND es.dbid = &&dbid  AND es.instance_number = &inst_num)
					   AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
					   and bs.stat_name ='physical reads';
					   
        	SELECT es.value-bs.value    into :total_logical_read
				FROM   v$database d,
					   DBA_HIST_SYSSTAT bs,
					   DBA_HIST_SYSSTAT es
				WHERE  
						(bs.snap_id = &&b_snap_id AND bs.dbid = &&dbid  AND bs.instance_number = &inst_num)
					   AND (es.snap_id = &&e_snap_id AND es.dbid = &&dbid  AND es.instance_number = &inst_num)
					   AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
					   and bs.stat_name ='session logical reads'; 
            SELECT 
				(es.value-bs.value)/1000000  cpu into :total_db_cpu
				FROM   v$database d,
					   dba_hist_sys_time_model bs,
					   dba_hist_sys_time_model es
				WHERE  
						(bs.snap_id = &&b_snap_id AND bs.dbid = &&dbid  AND bs.instance_number = &inst_num)
					   AND (es.snap_id = &&e_snap_id AND es.dbid = &&dbid  AND es.instance_number = &inst_num)
					   AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
					   and bs.stat_name ='DB CPU';
            SELECT 
				(es.value-bs.value)/1000000  cpu into :total_db_time
				FROM   v$database d,
					   dba_hist_sys_time_model bs,
					   dba_hist_sys_time_model es
				WHERE  
						(bs.snap_id = &&b_snap_id AND bs.dbid = &&dbid  AND bs.instance_number = &inst_num)
					   AND (es.snap_id = &&e_snap_id AND es.dbid = &&dbid  AND es.instance_number = &inst_num)
					   AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
					   and bs.stat_name ='DB time';
 
		
			case  '&type_stat'
				when 'gets'      then :total_interval_stat := :total_logical_read;
				when 'reads'     then :total_interval_stat := :total_physical_read;
				when 'cpu'       then :total_interval_stat := :total_db_cpu;
				when 'elapse'    then :total_interval_stat := :total_db_time;
				else null;
			end case;
		end;
		/			

--####################################################################





--####################################################################
--####################################################################
-- PAGE SETTING
set term off
-- when  silent ( 0, 1 ) or null , I display  sqltext column  and add a break
-- else I nopri
column sqltxt_col            new_value sqltxt_col 
column break_fmt            new_value break_fmt  
select 
  case 
   when &&silent in (0,1) or &&silent is null then ' pri'
   else ' nopri'
  end sqltxt_col,
  case 
   when &&silent in (0,1) or &&silent is null then ' on Sql_ID skip 1 '
   else ' on none skip 1'
  end break_fmt
from dual;

col sqltext  &sqltxt_col;
break &break_fmt 


-- I print don't print HEADING column if silent=4
---
column heading     new_value heading heading 'heading';
select 
  case &&silent
   when 4 then ' heading off'
   else ' heading on newpage 1'
  end heading
from dual;
set termout on;
set &heading

--####################################################################


--####################################################################
--####################################################################
-- Display statistics
set underline off;
set term on


col &head_stat_query  for 99G999G999G999D99
col "executions"  for 999G999G999
col "&type_stat per Exec" for 9G999G999D99
col "%Total"  for 999D00
col "CPU Times" for 99990G00
col "Elapsed Time"  for 999G999D00
col &head_total_stat for 999G999G999G999D999
col module  for a20 trunc
--set head on  lines 1024
set underline on
-- I list the query with stat

set lines 250


SELECT stat.* 
FROM   (SELECT c.&col_sql_stat                                                                    &head_stat_query, 
               c.executions_delta                                                                 Executions, 
               Nvl(Decode(c.executions_delta, 0, -1, c.&col_sql_stat / c.executions_delta), 0)    "&type_stat per Exec", 
               100 * ( c.&col_sql_stat / :total_interval_stat )                                   "&head_pct_total",
--               c.cpu_time_delta                                                                 "CPU Times", 
               c.elapsed_time_delta                                                               "Elapsed Time", 
               c.sql_id                                                                           Sql_ID, 
               :total_interval_stat                                                               &head_total_stat, 
               '&b_snap_time'                                                                     begin_interval, 
               '&e_snap_time'                                                                     end_interval,
			   module,
               '@d_sqlinfo ' ||c.sql_id || ' 5 '                                                  cmd,
               Replace(dbms_lob.Substr(sql_text, 4000, 1), Chr(9), ' ')                           sqltext 
        FROM   (SELECT sql_id, 
                       disk_reads_delta   , 
                       buffer_gets_delta  ,
                       executions_delta   , 
                       elapsed_time_delta , 
                       cpu_time_delta    ,
                       module					   
                FROM   (SELECT sql_id, 
                               SUM(b.disk_reads_delta)          disk_reads_delta, 
                               sum(b.buffer_gets_delta)         buffer_gets_delta,
                               SUM(b.executions_delta)          executions_delta, 
                               SUM(elapsed_time_delta)/ 1000000 elapsed_time_delta, 
                               SUM(cpu_time_delta)/1000000      cpu_time_delta, 
                               Min(b.MODULE)           module 
                        FROM   dba_hist_sqlstat b 
                        WHERE  instance_number = &inst_num 
                               AND dbid = &&dbid 
                               AND snap_id BETWEEN &&b_snap_id_delta AND 
                                                   &&e_snap_id 
                        GROUP  BY sql_id 
                        ORDER  BY SUM(b.&col_sql_stat) DESC) 
                WHERE  ROWNUM <= &nbreq) c, 
               dba_hist_sqltext st 
        WHERE  st.dbid = &dbid 
               AND c.sql_id = st.sql_id) stat
WHERE  ROWNUM < 8000 ;


undef 1 2 3 4 5 6 7 8 9 
clear columns
clear break

undef TYPE_STAT
undef BEG_DATE
undef END_DATE
undef SILENT
undef NBREQ
undef SYS_STAT_NAME
undef HEAD_STAT_QUERY
undef HEAD_TOTAL_STAT
undef HEAD_PCT_TOTAL
undef COL_SQL_STAT
undef DBID
undef DB_NAME
undef INST_NUM
undef INST_NAME
undef B_SNAP_ID
undef E_SNAP_ID
undef B_SNAP_TIME
undef E_SNAP_TIME
undef B_SNAP_ID_DELTA
undef DBTIME
undef SQLTXT_COL
undef BREAK_FMT
undef HEADING



/* Note perso

column on awr report

	Elapsed Time (s)    
	Executions  
	Elapsed Time per Exec (s)      
	%Total                          elapse / dbtime*100
											 -------
	%CPU                            cpu/elapse *100
	%IO                             user io time/elapse *100


	CPU Time (s)    
	Executions  
	CPU per Exec (s)    
	%Total                          cpu /total db cpu*100
	Elapsed Time (s)                elapse time of the query
	%CPU                            cpu/elapse *100
	%IO                             user io time/elapse *100 

	
	Buffer Gets 
	Executions  
	Gets per Exec   
	%Total                          bgquery/bg instance*100
	Elapsed Time (s)                elapse time
	%CPU                            cpu/elapse *100
	%IO                             user io time/elapse *100


	Physical Reads  
	Executions  
	Reads per Exec  
	%Total                          readQuery/total read
	Elapsed Time (s)    
	%CPU                            cpu/elapse *100
	%IO                             user io time/elapse *100


*/