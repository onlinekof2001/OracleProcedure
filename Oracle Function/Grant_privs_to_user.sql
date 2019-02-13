create or replace procedure grant_priv_to_user(opt varchar2) as
	v_role dba_roles%rowtype;
	v_user dba_users%rowtype;
	v_tab dba_tables%rowtype;
	v_dml varchar2(100);
	v_sch varchar2(100);
	v_sql varchar2(4000);
	v_cnt pls_integer;
begin
	/*this scripts is designing for grant privileges to users, the first if block is when someone didn't give any options */
	if opt is null then
		raise_application_error(-20306, 'Missing opitons, the option should be [lst_role|<SELECT_SCHEMA>|<MODIFY_SCHEMA>]
		SELECT_SCHEMA is for select only
		MODIFY_SCHEMA is for update,insert,delete.
		');
	elsif lower(opt) = 'lst_role' then
	/*list role with prefix SELECT_ and MODIFY_*, oracle_maintained only useful after 12c/
	FOR v_role in (select role from dba_roles where oracle_maintained='N') loop
		dbms_output.put_line(v_role.role);
	end loop;
	elsif regexp_like(upper(opt),'^(SELECT_|MODIFY_)') then
	begin
		select count(1) into v_cnt from dba_roles where role=upper(opt);
	end;
	v_dml := upper(substr(opt,0,instr(opt,'_',1)-1));
	v_sch := upper(substr(opt,instr(opt,'_',1)+1));
	if v_cnt = 0 then
		v_sql := 'CREATE ROLE ' || opt ;
		dbms_output.put_line(v_sql||' has been created');
	end if;
		if v_dml = 'SELECT' then
			FOR v_tab in (select table_name from dba_tables where owner in (upper(''||v_sch||''))) loop
				v_sql := 'GRANT SELECT on '|| v_tab.table_name||' to '|| upper(opt);
				execute immediate v_sql;
			end loop;
		elsif v_dml = 'MODIFY' then
			FOR v_tab in (select table_name from dba_tables where owner in (upper(''||v_sch||''))) loop
				v_sql := 'GRANT UPDATE,INSERT,DELETE on '|| v_tab.table_name||' to '|| upper(opt);
				execute immediate v_sql;
			end loop;
		else
			dbms_output.put_line(opt||' is not match the rules');
		end if;
	/*FOR v_user in (select username from dba_users where username in (upper(''||acoun||''))) loop
		FOR v_role in (select role from dba_roles where role like upper(priv)||'%') loop		
			v_sql:= 'grant '|| v_role.role ||' to '|| v_user.username;
			dbms_output.put_line(v_sql);
			-- execute immediate v_sql;
		end loop;
	end loop;*/
	end if;
	exception
		when no_data_found then
			dbms_output.put_line('There is no tables inside the schema'||v_sch);
end;
/
