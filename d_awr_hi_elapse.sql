    -- param 
--	&1 date d�but
--	&2 date fin
--      &3 level 
--           3 pas d'entete, pas de texte de requete , uniquement bufferget par hash 
--	     2 entete + buffer get
-- 	     1 buffer get + text
--           pas pr�cis� : tout.
--      &4 nombre de requete � retourner


variable silent number
variable nbreq number
variable wwbeg_date varchar2(22)
variable beg_date varchar2(22)


/* if the 1th parameters is not give I put a default value */
col p1 noprint new_value wwbeg_date
set verify off
set term off
select nvl('&&1','help') p1 from dual;
set term on

begin
	:beg_date:='&&wwbeg_date';
	if :beg_date  = 'help' then	
		dbms_output.put_line ('1st parameters begin date ');
		dbms_output.put_line ('2d  parameters end date ');
		dbms_output.put_line ('report level ');
		dbms_output.put_line ('   1 - buffergets list + query list');
		dbms_output.put_line ('   2 - heading + buffergets ');
		dbms_output.put_line ('   3 - buffergets uniquely ');
  end if;
end;
/

begin
	:silent :=&&3;
	:nbreq :=&4;
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


-- ATTENTION � le snapshot de d�but:
--    pour le calcul du rapport je prend le snapshot N
--    pour l'affichage je prend le snapshot N-1 pour etre en coh�rence avec l'awr.	   
column b_snap_id            new_value b_snap_id format 99999990 heading 'b_Snap Id';
column e_snap_id            new_value e_snap_id format 99999990 heading 'e_Snap Id';
column b_snap_time          new_value b_snap_time  format 99999990 heading 'b_Snaptime';
column e_snap_time          new_value e_snap_time  format 99999990 heading 'e_snap_time';
set head off
set term off

 select min(ss.snap_id) b_snap_id, max(ss.snap_id) e_snap_id,  to_char(min(ss.END_interval_time),'DD/MM/YY HH24:MI:SS') b_snap_time, to_char(max(ss.end_interval_time),'DD/MM/YY HH24:MI:SS') e_snap_time
from dba_hist_snapshot ss
where ss.end_interval_time between to_date('&1','DD/MM/YY HH24:MI:SS') and to_date('&2','DD/MM/YY HH24:MI:SS');

variable b_snap_id        number;
variable e_snap_id        number;
begin
  :b_snap_id       :=  &&b_snap_id;
  :e_snap_id       :=  &&e_snap_id;
end;
/

-- pour les stat sql je travail avec la colonne delta, pour cela je prend le snap_id suivant.
column b_snap_id_delta      new_value b_snap_id_delta    format 99999990 heading 'b_Snap Id';
column b_snap_time_delta    new_value b_snap_time_delta  format 99999990 heading 'b_Snaptime';

select min(ss.snap_id) b_snap_id_delta, min(ss.begin_interval_time) b_snap_time_delta
from dba_hist_snapshot ss
where ss.begin_interval_time >to_date('&1','DD/MM/YY HH24:MI:SS') ;

variable b_snap_id_delta        number;
begin
  :b_snap_id_delta       :=  &&b_snap_id_delta;
end;
/

-- ATTENTION � le snapshot de d�but:
--    pour le calcul du rapport je prend le snapshot N
--    pour l'affichage je prend le snapshot N-1 pour etre en coh�rence avec l'awr.
set term on
set head off
select 'Begin_SNAP_ID END_SNAP_ID BEGIN_SNAP_TIME   END_SNAP_TIME' from dual where	   :silent in (0, 2) or :silent is null;
select '------------- ----------- ----------------- -----------------' from dual where	   :silent in (0, 2) or :silent is null;
SELECT MIN(ss.snap_id) begin_snap_id,
       MAX(ss.snap_id) end_snap_id,
       to_char(MIN(ss.END_interval_time),'DD/MM/YY HH24:MI:SS') begin_snap_time,
       to_char(MAX(ss.end_interval_time),'DD/MM/YY HH24:MI:SS') end_snap_time
FROM   dba_hist_snapshot ss
WHERE  ss.end_interval_time BETWEEN to_date('&1', 'DD/MM/YY HH24:MI:SS') AND
       to_date('&2', 'DD/MM/YY HH24:MI:SS')
and :silent in (0, 2) or :silent is null;       

-- meme requete mais pour memoriser la date et heure donc 
-- SANS TENIR COMPTE DU SILENT
-- PAs de sortie ecran.
set term off
column begin_snap_time new_value begin_snap_time for a18 heading 'begin_snap_time';
column end_snap_time   new_value end_snap_time for a18 heading 'end_snap_time';
SELECT MIN(ss.snap_id) begin_snap_id,
       MAX(ss.snap_id) end_snap_id,
       to_char(MIN(ss.END_interval_time),'DD/MM/YY HH24:MI:SS') begin_snap_time,
       to_char(MAX(ss.end_interval_time),'DD/MM/YY HH24:MI:SS') end_snap_time
FROM   dba_hist_snapshot ss
WHERE  ss.end_interval_time BETWEEN to_date('&1', 'DD/MM/YY HH24:MI:SS') AND
       to_date('&2', 'DD/MM/YY HH24:MI:SS')
;       


set termout off;
column DBTIME     new_value DBTIME format 99999999999999999999990 heading 'DBTIME';
SELECT d.NAME DATABASE,
       bs.dbid,
       bs.instance_number,
       bs.snap_id bsnap_id,
       es.snap_id esnap_id,
       es.value-bs.value   DBTIME
FROM   v$database d,
       dba_hist_sys_time_model bs,
       dba_hist_sys_time_model es
WHERE  
        (bs.snap_id = :b_snap_id AND bs.dbid = &&dbid  AND bs.instance_number = :inst_num)
       AND (es.snap_id = :e_snap_id AND es.dbid = &&dbid  AND es.instance_number = :inst_num)
       AND (bs.stat_id = es.stat_id AND bs.stat_name = es.stat_name)
       and bs.stat_name ='DB time'
        ;
       
variable DBTIME        number;
begin
  :DBTIME       :=  &&DBTIME;
end;
/


column noheading     new_value noheading heading 'noheading';

select case :silent
   when 4 then ' heading off'
   else ' heading on newpage 1'
end noheading
from dual;

set termout on        
/* 
    suppression Call STATPACK to calculate certain statistics
*/




set termout on;
--set heading on newpage 1;
set &noheading
set underline off;
--set echo on
 --l aa format a1024 heading '                                                    CPU     Elapsed|      ELapse    Executions   elapse p Exec  %Total Time (s) Time (s)  Sql_Id            DB time sec  begin snap time   end snap time|--------------- ------------ -------------- ------ -------- --------- ------------- --------------- ----------------- -----------------' 
col aa format a1024 heading '                                               %     CPU     Elapsed|      ELapse    Executions   elapse p Exec  DBtime Time (s) Time (s)  Sql_Id            DB time sec  begin snap time   end snap time|--------------- ------------ -------------- ------ -------- --------- ------------- --------------- ----------------- -----------------' 
col sqltext heading ''
column hv noprint;
column tbg noprint;



break on none skip 1;

--prompt 1

-- dbid = &&dbid
-- db_name=TETRIX02
-- inst_num = 1
-- inst_name = tetrix02
-- b_snap_id = 644
-- e_snap_id = 644
-- nb gest   = 139669002

--set head off

set lines 140
select *
  from ( 
  select   lpad(to_char(b.elapsed_time /1000000,'99999999999'   )
                        ,15) ||' '||
                    lpad(to_char(b.executions  ,'999999999')
                        ,12) ||' '||            
                    lpad(to_char(b.elapsed_time/1000000 /b.executions ,'9999999.99')
                        ,14) ||' '||
                    lpad(to_char(100*(b.elapsed_time/:DBTIME),'990.0')
                        , 6) ||' '||
                    lpad(to_char(b.cpu_time/1000000, '99990.00')
                        , 8) || ' ' ||
                    lpad(to_char(b.elapsed_time/1000000, '999990.00')
                        ,9)  || ' ' ||
                    lpad(b.sql_id
                        ,13) ||' '|| 
                    lpad(to_char(:DBTIME/1000000,'99999999999')  
                        ,15) || ' ' ||
                    '&begin_snap_time' || ' ' ||
                    '&end_snap_time'  
                        aa
            , b.sql_id hv
         from 
              (sELECT  sql_id, buffer_gets, executions, elapsed_time, CPU_TIME
              FROM   (SELECT 
                          sql_id ,sum(b.buffer_gets_delta) buffer_gets, sum(b.executions_delta) executions, 
                          sum(elapsed_time_delta) elapsed_time, sum(CPU_TIME_DELTA) cpu_time, min(b.module) "module"
                          FROM  dba_hist_sqlstat b
                          WHERE  instance_number = :inst_num
                             AND dbid = :dbid
                             AND snap_id BETWEEN :b_snap_id_delta AND :e_snap_id
                          group by sql_id
                          ORDER  BY sum(elapsed_time_delta) DESC
                      )
              WHERE  rownum <= :nbreq
              ) b
            , dba_hist_sqltext     st 
        where st.dbid              = :dbid
          and b.sql_id             = st.sql_id 
)
where rownum < 8000
;






-- &&dbid = 2537019693
-- db_name=TETRIX02
-- inst_num = 1
-- inst_name = tetrix02
-- &&b_snap_id = 645
-- &&e_snap_id = 646
-- &&gets   = 139669002
-- :silent  =1
-- :nbreq = 5
break on hv skip 1;

set lines 140
select *
  from ( 
  select   lpad(to_char(b.elapsed_time/1000000 ,'99,999,999,999'   )
                        ,15) ||' '||
                    lpad(to_char(b.executions/100000  ,'999,999,999')
                        ,12) ||' '||            
                    lpad(to_char(b.elapsed_time/1000000 /b.executions ,'9,999,999,999')
                        ,14) ||' '||
                    lpad(to_char(100*(b.elapsed_time/:DBTIME),'990.0')
                        , 6) ||' '||
                    lpad(to_char(b.cpu_time/1000000, '99990.00')
                        , 8) || ' ' ||
                    lpad(to_char(b.elapsed_time/1000000, '999990.00')
                        ,9)  || ' ' ||
                    lpad(b.sql_id
                        ,13) ||' '|| 
                    lpad(to_char(:DBTIME/1000000,'9,999,999,999')
                        ,15) aa
            , replace(dbms_lob.substr(sql_text,4000,1),chr(9),' ') sqltext
            , b.sql_id hv
         from 
              (sELECT  sql_id, buffer_gets, executions, elapsed_time, CPU_TIME
              FROM   (SELECT 
                          sql_id ,sum(b.buffer_gets_delta) buffer_gets, sum(b.executions_delta) executions, 
                          sum(elapsed_time_delta) elapsed_time, sum(CPU_TIME_DELTA) cpu_time, min(b.module) "module"
                          FROM  dba_hist_sqlstat b
                          WHERE  instance_number = :inst_num
                             AND dbid = :dbid
                             AND snap_id BETWEEN :b_snap_id_delta AND :e_snap_id
                          group by sql_id
                          ORDER  BY sum(elapsed_time_delta) DESC
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


undef dbid    inst_num silent nbreq wwbeg_date beg_date b_snap_id e_snap_id b_snap_id_delta gets
clear col
undef 1 2 3 4 5 6 7 8 9