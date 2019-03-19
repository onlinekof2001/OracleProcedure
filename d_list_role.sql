set verify off
set line 180
--to avoid prompt for variables
COLUMN 1 NEW_VALUE 1
COLUMN 2 NEW_VALUE 2
select '1' "1",'2' "2" from dual where rownum=0;
--role and privs
variable own_name varchar2(30)
variable own_grte varchar2(30)

set term on
set serveroutput on
begin
        :own_name := nvl('&&1','SELECT');
		:own_grte := nvl('&&2','');
        if :own_name <> 'SELECT' or :own_name <> 'MODEIFY'
        then
            dbms_output.put_line('Owner prefix name should be SELECT_ | MODEIFY_');
        end if;
end;
/
col GRANTEE format a25
col GRANTED_ROLE format a30

--display all roles in database
select grantee,granted_role from dba_role_privs where granted_role like '%'||:own_name||'%' and grantee=:own_grte;

select location_info_id from ship_inventory si inner join ship_order_info soi on si.id=soi.inventory_id

 CONSTRAINT fkbv64on478v61p3xlo3fntlj09 FOREIGN KEY (inventory_id)
      REFERENCES ship_inventory (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
alter table ship_order_info drop constraint fkbv64on478v61p3xlo3fntlj09;
alter table ship_order_info disable trigger all;

update ship_order_info a set inventory_id=b.location_info_id from ship_inventory b where b.id=a.inventory_id;
alter table ship_order_info rename inventory_id to location_info_id;
alter table ship_order_info add constraint fk_ship_ord_inf_inventoryid foreign key(location_info_id) references ship_location_info(id) match full on delete cascade on update cascade;

select count(*) from transaction_detail where td_date > sysdate - 1;
select t.* from transaction_detail td left outer join transaction t on t.transact_id = td.transact_id where td.td_date > to_date('2019-02-26','YY-MM-DD')
SELECT distinct tl.*, td.td_date from TRANSACTION_DETAIL td INNER JOIN TRANSACTION_LOGS tl ON tl.TD_ID = td.TD_ID WHERE td.td_date > to_date('2019-02-26','YY-MM-DD')

SELECT t.* from TRANSACTION_DETAIL td INNER JOIN TRANSACTION t ON t.transact_id = td.transact_id WHERE td.td_date > to_date('2019-02-26','YY-MM-DD')

ALTER TABLE public.app_req_param
  ADD CONSTRAINT fk01_app_req_param FOREIGN KEY (ar_id)
      REFERENCES public.app_request (ar_id) 

export LD_LIBRARY_PATH=/u01/app/oracle/product/1120/db11g01/lib/:$LD_LIBRARY_PAT
export ORACLE_HOME=/u01/app/oracle/product/1120/db11g01
export PATH=/u01/app/oracle/product/1120/db11g01/bin:$PATH



select  tl.* from TRANSACTION tr
inner join TRANSACTION_DETAIL td
on tr.TRANSACT_ID = td.TRANSACT_ID
inner join TRANSACTION_LOGS tl
on tl.TD_ID = td.TD_ID where td.td_date > to_date('2019-02-26','YY-MM-DD');

select drc.owner,drc.name,to_char(dm.last_refresh_date,'yyyy-mm-dd hh24:mi:ss') from dba_refresh_children drc,dba_mviews dm where dm.mview_name=drc.name and dm.owner=drc.owner and rname='R_MD0000STCOM';

select 'EXEC DBMS_MVIEW.REFRESH('''||drc.owner||'.'||drc.name||''',''' || SUBSTR(dm.LAST_REFRESH_TYPE, 1, 1) || ''',PARALLELISM=>4);' from dba_refresh_children drc,dba_mviews dm where dm.mview_name=drc.name and dm.owner=drc.owner and rname='R_MD0000STCOM';



select job_action,next_run_date,state from dba_scheduler_jobs where job_name='J_MD0000STCOM';

 27110666:
Open port for onepay data migration project

Errors in file /u01/app/oracle/diag/rdbms/tetrix02_rtdkm1odb04/tetrix02/trace/tetrix02_rvwr_12290.trc  (incident=66948):
ORA-00494: enqueue [CF] held for too long (more than 900 seconds) by 'inst 1, osid 12259'
Incident details in: /u01/app/oracle/diag/rdbms/tetrix02_rtdkm1odb04/tetrix02/incident/incdir_66948/tetrix02_rvwr_12290_i66948.trc
Thu Feb 28 16:40:15 2019
Killing enqueue blocker (pid=12259) on resource CF-00000000-00000000 by (pid=12290)
 by killing session 2.1
Killing enqueue blocker (pid=12259) on resource CF-00000000-00000000 by (pid=12290)
 by terminating the process
RVWR (ospid: 12290): terminating the instance due to error 2103


(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = cnprdbx-01.epay-net.org)(PORT = 1530))) (CONNECT_DATA = (SID = EPAYPRO)))