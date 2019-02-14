--- list information about table
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

col column_name format a30
col name format a40
col table_name format a40
col table_owner format a40
col owner format a40
col num_rows format 999G999G999G999
col column_name format a30 heading 'name (col_stat)'
col info  format a100 heading 'name(comp,colstat,buff,uniq,part)'

set term on
--define tab_own = &&1
--define tab_nam = &&2

--select :tab_own,:tab_nam from dual;

break on schema_name skip 1


-- display partition information
select name aptse, column_position, column_name from sys.dba_part_key_columns 
where     ((owner = upper(:tab_own) and name  = upper(:tab_nam) ) or ((:tab_nam ='' or :tab_nam is null) and name =upper(:tab_own)))
order by column_position;

-- display table information
select owner , table_name, num_rows , last_analyzed , 
   (select trunc(sum(bytes)/1024/1024) MB 
     from dba_segments 
     where (owner  =upper(:tab_own)    and segment_name  = upper(:tab_nam) ) or (:tab_own is null    and segment_name  = upper(:tab_nam) )
   ) MB  
   from dba_tables  
   where    (owner = upper(:tab_own)    and table_name  = upper(:tab_nam)) or (:tab_own is null and table_name =upper(:tab_nam));
   

-- display column information
col default_value for a20
col comments      for a30
col data_type     for a25
col data_type_ext for a25
col nullable for a10

select col.owner as schema_name,
       --col.table_name, 
       col.column_name, 
		case when data_type = 'CHAR'     then      data_type||'('||col.char_length||decode(char_used,'B',' BYTE','C',' CHAR',null)||')'    
			when data_type = 'VARCHAR'  then      data_type||'('||col.char_length||decode(char_used,'B',' BYTE','C',' CHAR',null)||')'    
			when data_type = 'VARCHAR2' then      data_type||'('||col.char_length||decode(char_used,'B',' BYTE','C',' CHAR',null)||')'    
			when data_type = 'NCHAR'    then      data_type||'('||col.char_length||decode(char_used,'B',' BYTE','C',' CHAR',null)||')'    
			when data_type = 'NUMBER' then      
					case when col.data_precision is null and col.data_scale is null then          'NUMBER' 
					when col.data_precision is null and col.data_scale is not null then          'NUMBER(38,'||col.data_scale||')' 
					else           data_type||'('||col.data_precision||','||col.data_SCALE||')'      end    
			when data_type = 'NVARCHAR' then      data_type||'('||col.char_length||decode(char_used,'B',' BYTE','C',' CHAR',null)||')'    
			when data_type = 'NVARCHAR2' then     data_type||'('||col.char_length||decode(char_used,'B',' BYTE','C',' CHAR',null)||')'    
			else      data_type   
		end data_type,
       col.nullable nullable, 
       col.data_default as default_value,
	   NUM_DISTINCT, 
col.DENSITY, 
col.NUM_NULLS,
col.LAST_ANALYZED,
col.SAMPLE_SIZE,
col.HISTOGRAM,
comments
  from all_tables tab
       inner join all_tab_columns col 
           on col.owner = tab.owner 
          and col.table_name = tab.table_name          
       left join all_col_comments comm
           on col.owner = comm.owner
          and col.table_name = comm.table_name 
          and col.column_name = comm.column_name 
       where 
   ((col.owner = upper(:tab_own) and col.table_name  = upper(:tab_nam) ) 	 or  (:tab_own is null and col.table_name =upper(:tab_nam)))
 order by col.owner,
       col.table_name, 
	   COLUMN_ID;

	   
col stat_etendue for a400
set long 132
select owner, extension stat_etendue 	from dba_stat_extensions where (owner=upper(:tab_own)  and table_name =upper(:tab_nam)) or (:tab_own is null  and table_name =upper(:tab_nam))  order by owner; 
--order by 1

prompt Additionals  commands : @d_index 

clear break
undefine tab_own
undefine tab_nam
clear col
undef 1 2 3 4 5 6 7 8 9
