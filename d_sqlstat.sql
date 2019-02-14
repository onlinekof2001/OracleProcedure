--- List tables/mviews used by a query.
--- Author : Pascal BEN 

--- Parameter : 
---        sql_id : mandatory
---        plan_hash_value  :  optional. if you 
---
--- to find tables used by a sql_id, it use the plan in awr.

--- in case of you don't give the plan_hash_value :
---    because dba_hist_sql_plan can have more than one plan for sql_id and so different owner for one table, you can have the table for each owner.
---    exemple : 
---       1 january, 
---             + we create a table md0015ASTCOM.table1
---             + we create a synonym in stcom to table md0015ASTCOM.table1.
---       2 january,
---             + we create a table md0000STCOM.table1
---             + we create a synonym in stcom to table md0000STCOM.table1.
---       3 januray 
---             + if you use this script, you will display the table MD0015ASTCOM.TABLE1 and the table MD0000STCOM.TABLE1.
---

set verify  off
set echo off
set feed off



---- to avoid prompt for variable is parameter is not pass to script.
COLUMN 2 NEW_VALUE 2
SELECT 0 "2" FROM DUAL WHERE ROWNUM = 0;
variable plan_hash_value char(15);
begin
  :plan_hash_value :=nvl('&&2',0);
  
end;
/
column sqlId      new_value sqlId
col plan_hash_value for a20 
select '&1' sqlid,   :plan_hash_value plan_hash_value ,sysdate from dual;
column num_rows for 999,999,999,999
column mosize for 99,999.99
column owner for a30
column cmd_index for a60
column cmd_table for a60 
column cmd_stat for a80 heading "@d_gather_table schema tablename {exec/noexec} [degree]"
-----------------------------------------------------------------------
col    table_name for a31

with    table_list as 
(select sql_id,  options,  
    case operation 
      WHEN  'INDEX'  then 'Index -> Table'
      ELSE  operation
    end  ope,
    case operation 
      when 'INDEX' then table_owner
      else object_owner
    end owner,
    case operation 
      when 'INDEX' then table_name
      else object_name
    end table_name
 from dba_hist_sql_plan
  left outer join dba_indexes on operation='INDEX' and object_owner=owner and object_name=index_name 
 where sql_id = '&sqlid' 
    and object_name is not
    null),
taille as    
    (select seg.owner , segment_name,sum(bytes) bit_size from dba_segments  seg inner join table_list on  seg.owner=table_list.owner and seg.segment_name=table_list.table_name
    group by seg.owner , segment_name
    )
select t.owner, t.table_name , avg(dt.num_rows) num_rows,   min(dt.last_analyzed) last_analyzed, ts.stale_stats ,
trunc(bytes/1024/1024) mosize,
'@d_index ' || t.owner ||' '||t.table_name CMD_INDEX,
'@d_table ' || t.owner ||' '||t.table_name CMD_TABLE,
'@d_gather_table ' || t.owner ||' '||t.table_name ||' execute null' CMD_STAT 
from table_list    t
inner join dba_tables dt on dt.owner=t.owner and dt.table_name=t.table_name
inner join dba_segments seg on  seg.owner=t.owner and seg.segment_name=t.table_name
left outer join dba_tab_statistics ts on  ts.owner=t.owner and ts.table_name=t.table_name
group by t.owner, t.table_name,bytes,ts.stale_stats
order by t.owner, t.table_name;



 
   

undefine sqlid

clear col
undef 1 2 3 4 5 6 7 8 9

