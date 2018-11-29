CREATE OR REPLACE TRIGGER "ORA"."TRG_LOGIN_AUDIT"
AFTER LOGON ON DATABASE
DECLARE
  errcode number;
  errmsg varchar2(2000);
  v_program varchar2(60);
  v_machine varchar2(60);

BEGIN
    /*
    *******************************************************************************

    NAME
      LOGON_AUDIT trigger

    Copyright (c) 2006.

    FUNCTION
      This triggers log all connexions into login_hitory table

    DEPENDENCIES
            TABLE : ORA.LOGIN_HISTORY
            TABLE : ORA.ERR_LOG

    MODIFIED
            Bastien CATTEAU - ALL4IT - 2005 - v1.0  - Creation
            Bastien CATTEAU - ALL4IT - 2005 - v1.01 - Excluding TLA% machine logging.
    *******************************************************************************

    */

    select program
            into v_program
            from v$session
            where audsid = sys_context('USERENV', 'SESSIONID');

    select upper(sys_context('USERENV','HOST'))
            into v_machine
            from dual ;

    /*IF v_machine not like 'TLA%' THEN     */
            insert into login_history (username, osuser, program, machine, date_login)
                    values (sys_context('USERENV','SESSION_USER'),
                                                    sys_context('USERENV','OS_USER'),
                                                    v_program,
                                                    v_machine,
                                                    sysdate);
    /*ELSE
            v_machine not like 'TLA%' THEN
    End If;*/

EXCEPTION
        WHEN others THEN
                errcode := sqlcode;
    errmsg := sqlerrm;
    dbms_output.put_line(errmsg);
    insert into err_log (module,errcode,errmsg) values ('ORA.TRG_LOGIN_AU
DIT', errcode , errmsg);
END logon_audit_trigger ;
ALTER TRIGGER "ORA"."TRG_LOGIN_AUDIT" DISABLE


CREATE OR REPLACE TRIGGER "ORA"."LOGON_AUDIT_TRIGGER"
after logon on database
begin
    insert into stats$user_log values(
       user,
       sys_context('userenv','sessionid'),
       sys_context('userenv','host'),
       null,
       null,
       null,
       sysdate,
       to_char(sysdate, 'hh24:mi:ss'),
       null,
       null,
       null
    );
end;
ALTER TRIGGER "ORA"."LOGON_AUDIT_TRIGGER" DISABLE

CREATE OR REPLACE TRIGGER "ORA"."LOGOFF_AUDIT_TRIGGER" before
logoff on database begin
    -- ***************************************************
    -- update the last action accessed
    -- ***************************************************
    update
    stats$user_log
    set
    last_action = (select action from sys.v_$session where
    sys_context('userenv','sessionid') = audsid)
    where
    sys_context('userenv','sessionid') = session_id;
    --***************************************************
    -- update the last program accessed
    -- ***************************************************
    update
    stats$user_log
    set
    last_program = (select program from sys.v_$session where
    sys_context('userenv','sessionid') = audsid)
    where
    sys_context('userenv','sessionid') = session_id;
    -- ***************************************************
    -- update the last module accessed
    -- ***************************************************
    update
    stats$user_log
    set
    last_module = (select module from sys.v_$session where
    sys_context('userenv','sessionid') = audsid)
    where
    sys_context('userenv','sessionid') = session_id;
    -- ***************************************************
    -- update the logoff day
    -- ***************************************************
    update
       stats$user_log
    set
       logoff_day = sysdate
    where
       sys_context('userenv','sessionid') = session_id;
    -- ***************************************************
    -- update the logoff time
    -- ***************************************************
    update
       stats$user_log
    set
       logoff_time = to_char(sysdate, 'hh24:mi:ss')
    where
       sys_context('userenv','sessionid') = session_id;
    -- ***************************************************
    -- compute the elapsed minutes
    -- ***************************************************
    update
    stats$user_log
    set
    elapsed_minutes =
    round((logoff_day - logon_day)*1440)
    where
    sys_context('userenv','sessionid') = session_id;
end;
ALTER TRIGGER "ORA"."LOGOFF_AUDIT_TRIGGER" DISABLE


CREATE OR REPLACE TRIGGER "ORA"."SERVICES_STARTUP"
 AFTER STARTUP ON DATABASE
 declare role VARCHAR(30);
 BEGIN
    SELECT DATABASE_ROLE INTO role FROM V$DATABASE;
    if role = 'PRIMARY' THEN
        for c in( SELECT name FROM dba_services minus select name from v$active_services)
        loop
          dbms_service.start_service(c.name);
        end loop;
    END if;
EXCEPTION
    WHEN OTHERS THEN
    begin
     sys.dbms_system.ksdwrt(2,to_char(sysdate,'Dy Mon dd HH24:MI:SS YYYY')||'  error msg='||sqlerrm);
     dbms_output.put_line('Trigger ora.services_startup Error :  Dy Mon dd HH24:MI:SS YYYY msg='||sqlerrm);
    end;
end services_startup;
ALTER TRIGGER "ORA"."SERVICES_STARTUP" DISABLE

CREATE OR REPLACE TRIGGER "ORA"."LOGON_DENIED_TO_ALERT_TRIGGER"
after servererror on database
declare
    message varchar2(120);
    IP varchar2(15);
    os_user varchar2(80);
begin
    select sys_context('userenv','ip_address') into IP from dual;
    select sys_context('userenv','os_user') into os_user from dual;
        IF (ora_is_servererror(1017)) THEN
        message:= to_char(sysdate,'Dy Mon dd HH24:MI:SS YYYY')||' logon denied from '||IP||' '||os_user;
        sys.dbms_system.ksdwrt(2,message);
        END IF;
end;
