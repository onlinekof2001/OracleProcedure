--- List tables/mviews used by a query.
--- Author : Pascal BEN 

--- Parameter : 
---        owner/table_name  : if 2 parameters : owner else table_name 
---        table_name :   
---
--- list the index and statistics for a table 
--- if you have only one parameter , it is the name of the table_name


set verify off

set term off
---- to avoid prompt for variable is parameter is not pass to script. do not replace value in parameter .
variable nbh  number
COLUMN 1 NEW_VALUE 1
COLUMN 2 NEW_VALUE 2
COLUMN 3 NEW_VALUE 3
COLUMN 4 NEW_VALUE 4
SELECT '1' "1", '2' "2", '3' "3", '4' "4" FROM DUAL WHERE ROWNUM = 0;
set term off
variable tab_own varchar2(30)
variable tab_nam varchar2(30)
begin
	:tab_own :=nvl('&&1','a');
	:tab_nam :=nvl('&&2','');
	if :tab_nam is null 
	then 
	    :tab_nam := :tab_own;
		:tab_own  :='';
	end if;
	dbms_output.put_line('/'||:tab_own ||'-'||:tab_nam||'/');
end;
/
set term on
break on name skip 1
col column_name format a30  
col info  format a100 heading 'index_name(comp,colstat,buff,uniq,part)'
col num_rows for 999G999G999G999D9
col table_name format a40
col table_owner format a40
col owner format a30

-- display information about partionning
select name , column_position, column_name from sys.dba_part_key_columns 
where     ((owner = upper(:tab_own) and name  = upper(:tab_nam) ) or ((:tab_nam ='' or :tab_nam is null) and name =upper(:tab_own)))
order by column_position;


-- display information about table
--break on info skip 5


select owner , table_name, num_rows , last_analyzed , 
   (select trunc(sum(bytes)/1024/1024) MB 
     from dba_segments 
     where (owner  =upper(:tab_own)    and segment_name  = upper(:tab_nam) ) or (:tab_own is null    and segment_name  = upper(:tab_nam) )
   ) MB  
   from dba_tables  
   where    (owner = upper(:tab_own)    and table_name  = upper(:tab_nam)) or (:tab_own is null and table_name =upper(:tab_nam));
clear break


clear break
-- display information about indexes
--break on info  skip 1
break on table_owner on info  skip 1
select ind.table_owner table_owner,ind.index_name || ' (' || lower(ind.compression )|| '-' ||prefix_length || ' , ' || lower(ind.buffer_pool )|| ' , ' || lower(ind.uniqueness )|| ' , ' || lower(ind.partitioned )|| ')' 
as info, col.column_name , '(' || 
(    select decode(tcol.num_buckets,1,'-',null,'-','Stat' )
     from dba_tab_columns tcol
	 where ind.owner       = tcol.owner
       and ind.table_name  = tcol.table_name
       and col.column_name = tcol.COLUMN_NAME
)	 
|| ')' stat,mb,
ind.num_rows
  from dba_ind_columns col, dba_indexes ind --, dba_tab_columns tcol
  , (select owner, segment_name,  trunc(sum(bytes)/1024/1024) MB from  dba_segments se 	 group by owner, segment_name)  seg
 where ind.index_name  = col.index_name
   and ind.table_name  = col.table_name
   and ind.owner       = col.index_owner
   and ((col.table_owner = upper(:tab_own) and ind.table_name  = upper(:tab_nam) ) 	 or  (:tab_own is null and ind.table_name =upper(:tab_nam)))
   --and ((col.table_owner = upper(:tab_own) and ind.table_name  = upper(:tab_nam) ) ) 
   --and ((col.table_owner = upper(:tab_own) and ind.table_name  = upper(:tab_nam) ) or (:tab_nam is null and ind.table_name =upper(:tab_own:))
   and seg.segment_name=col.index_name
   and seg.owner=col.index_owner
order by 1,2,column_position;

col stat_etendue for a400
set long 132
select owner, extension stat_etendue 	from dba_stat_extensions where (owner=upper(:tab_own)  and table_name =upper(:tab_nam)) or (:tab_own is null  and table_name =upper(:tab_nam))  ; 
--order by 1



clear col
clear break
undef 1 2 3 4 5 6 7 8 9
