create or replace procedure obs_privs_for_a_user_or_roles(obj varchar2) as
	v_rle dba_roles%rowtype;
	v_usr dba_users%rowtype;
	v_role dba_role_privs%rowtype;
	v_tab dba_tab_privs%rowtype;
	v_rcnt pls_integer;
	v_ucnt pls_integer;
begin
	begin
		select count(1) into v_rcnt from dba_roles where role=upper(obj);
		select count(1) into v_ucnt from dba_users where username=upper(obj);
	end;
	if v_ucnt = 0 and v_rcnt = 0 then
		dbms_output.put_line('Ora-020101 User or Role '||obj||' doesn''t exist');
		for v_rle in (select role from dba_roles where ORACLE_MAINTAINED='N') loop
			dbms_output.put_line('Role: '||v_rle.role);
		end loop;
		for v_usr in (select username from dba_users where ORACLE_MAINTAINED='N') loop
			dbms_output.put_line('User: '||v_usr.username);
		end loop;
	elsif v_ucnt = 1 then
		dbms_output.put_line('The username is '||obj);
		for v_tab in (SELECT GRANTEE,TABLE_NAME,PRIVILEGE FROM DBA_TAB_PRIVS where GRANTEE=obj order by PRIVILEGE) loop
			v_ucnt := v_ucnt + 1;
			dbms_output.put_line( v_ucnt|| '. The username: ' ||v_tab.GRANTEE || ' Privilege are: ' ||v_tab.PRIVILEGE || ' on table ' ||v_tab.TABLE_NAME);
		end loop;	
	else
		dbms_output.put_line('The role is '||obj);
		for v_role in (SELECT GRANTEE,GRANTED_ROLE FROM DBA_ROLE_PRIVS where GRANTEE=obj order by GRANTED_ROLE) loop
			v_rcnt := v_rcnt + 1;
			dbms_output.put_line( v_rcnt|| '. The username: ' ||v_role.GRANTEE || ' Role granted are: ' ||v_role.GRANTED_ROLE);
		end loop;
	end if;
end;
/
	
LEAST({DBInstanceClassMemory/9531392},5000)   6527097 * 856