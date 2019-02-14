    -- param 
--	&1 date début
--	&2 date fin
--      &3 level 
--           3 pas d'entete, pas de texte de requete , uniquement bufferget par hash 
--	     2 entete + buffer get
-- 	     1 buffer get + text
--           pas précisé : tout.
--      &4 nombre de requete à retourner
set verify off
variable silent number
variable nbreq number
variable wwbeg_date varchar2(22)
variable beg_date varchar2(22)
variable  end_date varchar2(22)

set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
COLUMN 1 NEW_VALUE 1
COLUMN 2 NEW_VALUE 2
COLUMN 3 NEW_VALUE 3
COLUMN 4 NEW_VALUE 4
SELECT 1 "1", 2 "2", 3 "3", 4 "4" FROM DUAL WHERE ROWNUM = 0;


begin
	:silent :=nvl('&&3','3');
	:nbreq  :=nvl('&&4','5');
--	dbms_output.put_line ('testtesttest-----------------------------');
	if '&1' = ''
	then
		--select s.begin_interval_time into :beg_date, s.end_interval_time into :end_date from dba_hist_snapshot s where snap_id in (select min(snap_id) from dba_hist_snapshot );
		select s.begin_interval_time-1/24/60/60 , s.end_interval_time+1/24/60/60 into :beg_date, :end_date from dba_hist_snapshot s where snap_id in (select max(snap_id) from dba_hist_snapshot );
	else 
		:beg_date:='&1';
		:end_date:='&2';
	end if;
end;
/
set term off
set verify off
begin
	if :beg_date  = 'help' then	
		dbms_output.put_line ('1st parameters begin date ');
		dbms_output.put_line ('2d  parameters end date ');
		dbms_output.put_line ('3d report level ');
		dbms_output.put_line ('   1 - buffergets list + query list');
		dbms_output.put_line ('   2 - heading + buffergets ');
		dbms_output.put_line ('   3 - buffergets uniquely ');
		dbms_output.put_line ('4d number of sql_id listed ');
  end if;
end;
/



set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 150 linesize 95 newpage 1 recsep off;
set trimspool on trimout on;

alter session set nls_date_format='DD/MM/YY HH24:MI:SS';


column inst_num  heading "Inst Num"  new_value inst_num  format 99999;
column inst_name heading "Instance"  new_value inst_name format a12;
column db_name   heading "DB Name"   new_value db_name   format a12;
column dbid      heading "DB Id"     new_value dbid      format 9999999999 just c;
set term off
set head off
select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
  from v$database d,
       v$instance i;
       

set term on

set head on
set underline on
select d.dbid            database_id
     , d.name            database_name
     , i.instance_number instance_number
     , i.instance_name   instance_name
  from v$database d,
       v$instance i
where	   :silent in (0, 2) or :silent is null;

set underline off
--
--prompt Using dbid for database Id
--prompt Using inst_num for instance number
--
--  Set up the binds for dbid and instance_number

variable dbid       number;
variable inst_num   number;
begin
  :dbid      :=  &&dbid;
  :inst_num  :=  &&inst_num;
end;
/



-- ATTENTION à le snapshot de début:
--    pour le calcul du rapport je prend le snapshot N
--    pour l'affichage je prend le snapshot N-1 pour etre en cohérence avec l'awr.	   
column b_snap_id            new_value b_snap_id format 99999990 heading 'b_Snap Id';
column e_snap_id            new_value e_snap_id format 99999990 heading 'e_Snap Id';
column b_snap_time          new_value b_snap_time  format 99999990 heading 'b_Snaptime';
column e_snap_time          new_value e_snap_time  format 99999990 heading 'e_snap_time';
set head off
set term off
--set term on
select min(ss.snap_id) b_snap_id, max(ss.snap_id) e_snap_id,  to_char(min(ss.END_interval_time),'DD/MM/YY HH24:MI:SS') b_snap_time, to_char(max(ss.end_interval_time),'DD/MM/YY HH24:MI:SS') e_snap_time
from dba_hist_snapshot ss
where ss.end_interval_time between to_date(:beg_date,'DD/MM/YY HH24:MI:SS') and to_date(:end_date,'DD/MM/YY HH24:MI:SS');
--where ss.end_interval_time between to_date('&1','DD/MM/YY HH24:MI:SS') and to_date('&2','DD/MM/YY HH24:MI:SS');


variable b_snap_id        number;
variable e_snap_id        number;
begin
  :b_snap_id       :=  &&b_snap_id;
  :e_snap_id       :=  &&e_snap_id;
end;
/

set term off

-- pour les stat sql je travail avec la colonne delta, pour cela je prend le snap_id suivant.
column b_snap_id_delta      new_value b_snap_id_delta    format 99999990 heading 'b_Snap Id';
column b_snap_time_delta    new_value b_snap_time_delta  format 99999990 heading 'b_Snaptime';



select min(ss.snap_id) b_snap_id_delta, min(ss.begin_interval_time) b_snap_time_delta
from dba_hist_snapshot ss
where ss.begin_interval_time >to_date(:beg_date,'DD/MM/YY HH24:MI:SS') ;
--where ss.begin_interval_time >to_date('&1','DD/MM/YY HH24:MI:SS') ;

variable b_snap_id_delta        number;
begin
  :b_snap_id_delta       :=  &&b_snap_id_delta;
end;
/

-- ATTENTION à le snapshot de début:
--    pour le calcul du rapport je prend le snapshot N
--    pour l'affichage je prend le snapshot N-1 pour etre en cohérence avec l'awr.
set term on


set head off
select 'Begin_SNAP_ID END_SNAP_ID BEGIN_SNAP_TIME   END_SNAP_TIME' from dual where	   :silent in (0, 2) or :silent is null;
select '------------- ----------- ----------------- -----------------' from dual where	   :silent in (0, 2) or :silent is null;
SELECT MIN(ss.snap_id) begin_snap_id,
       MAX(ss.snap_id) end_snap_id,
       to_char(MIN(ss.END_interval_time),'DD/MM/YY HH24:MI:SS') begin_snap_time,
       to_char(MAX(ss.end_interval_time),'DD/MM/YY HH24:MI:SS') end_snap_time
FROM   dba_hist_snapshot ss
WHERE  ss.end_interval_time BETWEEN to_date(:beg_date, 'DD/MM/YY HH24:MI:SS') AND
       to_date(:end_date, 'DD/MM/YY HH24:MI:SS')
and :silent in (0, 2) or :silent is null;       



-- I read the total_disk read for the period.
set termout off;
column disk_read     new_value disk_read format 99999999999999999999990 heading 'disk_read';
SELECT d.NAME DATABASE,
       bs.dbid,
       bs.instance_number,
       bs.snap_id bsnap_id,
       es.snap_id esnap_id,
       es.value-bs.value   disk_read
FROM   v$database d,
       DBA_HIST_SYSSTAT bs,
       DBA_HIST_SYSSTAT es
WHERE  
        (bs.snap_id = :b_snap_id AND bs.dbid = &&dbid  AND bs.instance_number = :inst_num)
       AND (es.snap_id = :e_snap_id AND es.dbid = &&dbid  AND es.instance_number = :inst_num)
       AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
       and bs.stat_name ='physical reads'
        ;
       
variable disk_read        number;
begin
  :disk_read       :=  &&disk_read;
end;
/

column noheading     new_value noheading heading 'noheading';

select case :silent
   when 4 then ' heading off'
   else ' heading on newpage 1'
end noheading
from dual;

set termout on;

set &noheading
set underline off;

col aa format a1024 heading '                                                    CPU     Elapsed| Buffer Gets    Executions   Gets per Exec  %Total Time (s) Time (s)  Sql_Id        ToTal B Get |--------------- ------------ -------------- ------ -------- --------- ------------- ---------------' 
col sqltext heading ''
column hv noprint;
column tbg noprint;



break on none skip 1;
-- dbid = &&dbid
-- db_name=TETRIX02
-- inst_num = 1
-- inst_name = tetrix02
-- b_snap_id = 644
-- e_snap_id = 644
-- nb gest   = 139669002

 --Reads    Executions  Reads per Exec  %Total Time (s) Time (s)  Sql_Id        ToTal Reads
col reads  for 99G999G999G999
col "executions"  for 999G999G999
col "Reads per Exec" for 9G999G999G999
col "%Total"  for 999D0
col "CPU Times" for 99990G00
col "Elapsed Time"  for 999G999D00
col Total_read for 99G999G999G999
set head on  lines 1024
set underline on
-- I list only the stats
select *
  from ( 
  select 	b.disk_read reads ,b.executions  Executions ,
			nvl(decode(b.executions,0,-1,b.disk_read  /b.executions),0)  "Reads per Exec" ,100*(b.disk_read/:disk_read) "%Total" , b.cpu_time/1000000 "CPU Times" , 
			b.elapsed_time/1000000 "Elapsed Time" , b.sql_id Sql_ID, :disk_read Total_read , b.sql_id hv
         from 
              (sELECT  sql_id, disk_read, executions, elapsed_time, CPU_TIME
              FROM   (SELECT 
                          sql_id ,sum(b.disk_reads_delta) disk_read, sum(b.executions_delta) executions, 
                          sum(elapsed_time_delta) elapsed_time, sum(CPU_TIME_DELTA) cpu_time, min(b.module) "module"
                          FROM  dba_hist_sqlstat b
                          WHERE  instance_number = :inst_num
                             AND dbid = :dbid
                             AND snap_id BETWEEN :b_snap_id_delta AND :e_snap_id
                          group by sql_id
                          ORDER  BY SUM(b.disk_reads_delta) DESC
                      )
              WHERE  rownum <= :nbreq
              ) b
            , dba_hist_sqltext     st 
        where st.dbid              = :dbid
          and b.sql_id             = st.sql_id 
)
where rownum < 8000
;
/*
set head on

col aa format a1024 heading '                                                    CPU     Elapsed|       Reads    Executions  Reads per Exec  %Total Time (s) Time (s)  Sql_Id        ToTal Reads |--------------- ------------ -------------- ------ -------- --------- ------------- ---------------' 
set lines 105
select *
  from ( 
  select   lpad(to_char(b.disk_read ,'99999999999'   )
                        ,15) ||' '||
                    lpad(to_char(b.executions  ,'999999999')
                        ,12) ||' '||            
--                    lpad(to_char(b.disk_read /b.executions ,'9999999999')
					lpad(to_char(nvl(decode(b.executions,0,-1,b.disk_read  /b.executions),0) ,'9999999999')
                        ,14) ||' '||
                    lpad(to_char(100*(b.disk_read/:disk_read),'990.0')
                        , 6) ||' '||
                    lpad(to_char(b.cpu_time/1000000, '99990.00')
                        , 8) || ' ' ||
                    lpad(to_char(b.elapsed_time/1000000, '999990.00')
                        ,9)  || ' ' ||
                    lpad(b.sql_id
                        ,13) ||' '|| 
                    lpad(to_char(:disk_read,'99999999999')  
                        ,15) aa
            , b.sql_id hv
         from 
              (sELECT  sql_id, disk_read, executions, elapsed_time, CPU_TIME
              FROM   (SELECT 
                          sql_id ,sum(b.disk_reads_delta) disk_read, sum(b.executions_delta) executions, 
                          sum(elapsed_time_delta) elapsed_time, sum(CPU_TIME_DELTA) cpu_time, min(b.module) "module"
                          FROM  dba_hist_sqlstat b
                          WHERE  instance_number = :inst_num
                             AND dbid = :dbid
                             AND snap_id BETWEEN :b_snap_id_delta AND :e_snap_id
                          group by sql_id
                          ORDER  BY SUM(b.disk_reads_delta) DESC
                      )
              WHERE  rownum <= :nbreq
              ) b
            , dba_hist_sqltext     st 
        where st.dbid              = :dbid
          and b.sql_id             = st.sql_id 
)
where rownum < 8000
;

*/




-- &&dbid = 2537019693
-- db_name=TETRIX02
-- inst_num = 1
-- inst_name = tetrix02
-- &&b_snap_id = 645
-- &&e_snap_id = 646
-- &&gets   = 139669002
-- :silent  =1
-- :nbreq = 5
-- I list the query with stat
break on hv skip 1;
set lines 120
select *
  from ( 
  select 	b.disk_read reads ,b.executions  Executions ,
			nvl(decode(b.executions,0,-1,b.disk_read  /b.executions),0)  "Reads per Exec" ,100*(b.disk_read/:disk_read) "%Total" , b.cpu_time/1000000 "CPU Times" , 
			b.elapsed_time/1000000 "Elapsed Time" , b.sql_id Sql_ID, :disk_read Total_read 
			, replace(dbms_lob.substr(sql_text,4000,1),chr(9),' ') sqltext, b.sql_id hv
         from 
              (sELECT  sql_id, disk_read, executions, elapsed_time, CPU_TIME
              FROM   (SELECT 
                          sql_id ,sum(b.disk_reads_delta) disk_read, sum(b.executions_delta) executions, 
                          sum(elapsed_time_delta) elapsed_time, sum(CPU_TIME_DELTA) cpu_time, min(b.module) "module"
                          FROM  dba_hist_sqlstat b
                          WHERE  instance_number = :inst_num
                             AND dbid = :dbid
                             AND snap_id BETWEEN :b_snap_id_delta AND :e_snap_id
                          group by sql_id
                          ORDER  BY SUM(b.disk_reads_delta) DESC
                      )
              WHERE  rownum <= :nbreq
              ) b
            , dba_hist_sqltext     st 
        where st.dbid              = :dbid
          and b.sql_id             = st.sql_id 
)
where rownum < 8000 and (:silent in (0,1) or :silent is null)
;
/*
set lines 100
select *
  from ( 
  select   lpad(to_char(b.disk_read ,'99,999,999,999'   )
                        ,15) ||' '||
                    lpad(to_char(b.executions  ,'999,999,999')
                        ,12) ||' '||            
					lpad(to_char(decode(b.executions,0,-1,b.disk_read /b.executions)  ,'9,999,999,999')
                        ,14) ||' '||
                    lpad(to_char(100*(b.disk_read/:disk_read),'990.0')
                        , 6) ||' '||
                    lpad(to_char(b.cpu_time/1000000, '99990.00')
                        , 8) || ' ' ||
                    lpad(to_char(b.elapsed_time/1000000, '999990.00')
                        ,9)  || ' ' ||
                    lpad(b.sql_id
                        ,13) ||' '|| 
                    lpad(to_char(:disk_read,'9,999,999,999')
                        ,15) aa
            , replace(dbms_lob.substr(sql_text,4000,1),chr(9),' ') sqltext
            , b.sql_id hv
         from 
              (sELECT  sql_id, disk_read, executions, elapsed_time, CPU_TIME
              FROM   (SELECT 
                          sql_id ,sum(b.disk_reads_delta) disk_read, sum(b.executions_delta) executions, 
                          sum(elapsed_time_delta) elapsed_time, sum(CPU_TIME_DELTA) cpu_time, min(b.module) "module"
                          FROM  dba_hist_sqlstat b
                          WHERE  instance_number = :inst_num
                             AND dbid = :dbid
                             AND snap_id BETWEEN :b_snap_id_delta AND :e_snap_id
                          group by sql_id
                          ORDER  BY SUM(b.disk_reads_delta) DESC
                      )
              WHERE  rownum <= :nbreq
              ) b
            , dba_hist_sqltext     st 
        where st.dbid              = :dbid
          and b.sql_id             = st.sql_id 
)
where rownum < 8000
and (:silent in (0,1) or :silent is null)
;
*/

undef 1 2 3 4;
--unDEFINE DBID  DB_NAME  silent nbreq wwbeg_date beg_date INST_NUM  INST_NAME  B_SNAP_ID  E_SNAP_ID  B_SNAP_TIME  E_SNAP_TIME   B_SNAP_ID_DELTA   B_SNAP_TIME_DELTA   DISK_READ   NOHEADING   DATE_END ;

set underline on recsep wrap feedback on echo off  head on trimspool on trimout on;


undef dbid    inst_num silent nbreq wwbeg_date beg_date b_snap_id e_snap_id b_snap_id_delta gets
clear col
undef 1 2 3 4 5 6 7 8 9