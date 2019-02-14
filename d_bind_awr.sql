set serveroutput on
set verify off


---------------------------------------------------------------------------------------------------------------------
----- Auteur : Pascal 
-----
----- for a SQLID, this script display replace the bind variable by their value
-----
----- the bind value are read in AWR TABLES
-----
----- LES LIMITS : 
-----    the query is stocked in a varchar2 (so limited to 4000 char)
-----    to identify a bind variable the script use the ":" before a number.
-----       EXEMPLE 1
-----             select number from test where number=:1
-----           this script will return :
-----             select number from test where number=5
-----       
-----       EXEMPLE 2
-----             select number from test where number=:1 and description='test :1'
-----           this scrip will return A BAD SQL, it replace ("test :1" by "test :5").
-----             select number from test where number=5 and description='test 5'
--------------------------------------------------------------------------------------------------------------------



declare

   cursor cQuery(cp_sqlid varchar2) is 
      select sql_text,sql_id from dba_hist_sqltext where sql_id = cp_sqlid;   
   
   
   type TAnyData is table of SYS.ANYDATA index by pls_integer;
   AValues TAnyData;
   
   type TVarchar is table of varchar2(30) index by pls_integer;
   AStrings TVarchar;

   cursor CValues(cp_sqlid varchar2, cp_snapid number, cp_captured timestamp) is
      select value_anydata, position
        from dba_hist_sqlbind
       where sql_id = cp_sqlid
         and snap_id = cp_snapid
		 and last_captured=cp_captured
      order by snap_id, last_captured, position desc;

   cursor csnap_id (cp_sqlid varchar2) is 
     select * from (select  distinct b.snap_id, last_captured, s.begin_interval_time,s.end_interval_time
        from dba_hist_sqlbind b
             inner join dba_hist_snapshot s on s.snap_id = b.snap_id and s.dbid = b.dbid and s.instance_number = b.instance_number
             where b.sql_id = '&1' and s.begin_interval_time > trunc(sysdate) - 20 order by snap_id desc )
             where rownum<=10 order by snap_id ;

   value_string varchar2(255);          
   v_type sys.anytype;
   rc pls_integer;
   
   Stmt varchar2(32000);
   dest varchar2(32000);
   chunks integer;
   sql_id varchar(15);

   type type_bind is record (
        bindvalue anydata,
        position integer
    );
    
    lg integer;
    var_bind type_bind;
    w_sql_id varchar2(20);
    w_snap_id int;
    var_using varchar2(32000);
    begin_interval timestamp;
    end_interval timestamp;
    captured timestamp;
    var_type varchar(100);

Begin  
   DBMS_OUTPUT.enable(10000000);
   select '&1' into sql_id from  dual ;
   
   open cQuery(sql_id);
   fetch cQuery into Stmt,w_sql_id ;
   close cQuery;
   
   dbms_output.put_line('----------------------------');
   dbms_output.put_line('Originale query :');
   dbms_output.put_line('-'||Stmt);
   dbms_output.put_line(w_sql_id);
   dbms_output.put_line('----------------------------');
   dbms_output.put_line('bind type : if timestamp : timestamp(...), if string :  ''stringvalue'', if number:99999');

   open csnap_id(w_sql_id);
   
   -- boucle sur le snapid par défault, 3 snapid différents.
   loop
     fetch csnap_id into w_snap_id,captured, begin_interval,end_interval;
     exit when csnap_id%notfound;
         dest := stmt;
         open cvalues (w_sql_id, w_snap_id, captured);
         var_using:='';
         -- je lis le bind variable du snapid en cours  
         loop
           fetch cvalues into var_bind;
           exit when cvalues%notfound;
		 -- I evaluate how replace bind variable (number, string time_stamp.   
          if ( var_bind.bindvalue is NULL) 
            then 
               value_string := ''; 
            else
               case anydata.gettype( var_bind.bindvalue, v_type)
                  when 9   then 
                      value_string := '''' || anydata.AccessVarchar2(var_bind.bindvalue) || '''';
--                      var_type := 'string : ';
                  when 2   then 
                      value_string := to_char(anydata.AccessNumber(var_bind.bindvalue));
--                      var_type := 'number:';
                  when 187 then 
                      value_string := 'to_timestamp(''' ||rtrim(to_char(anydata.accesstimestamp(var_bind.bindvalue),'DD/MM/YY HH24-MI-SS')) ||''' , ''DD/MM/YY HH24-MI-SS'')';
--                      var_type:='timestamp:';
                  else 
                      value_string := ' data type not recognise id is ' || anydata.gettypename(var_bind.bindvalue) || '(' || anydata.gettype(var_bind.bindvalue, v_type) || ')';
--                      var_type:='Unknow:';
               end case;
            end if;    
           -- I replace the bind variable by a string.			
            dest := regexp_replace(dest,':' || var_bind.position ,value_string);
		   -- I memorise the values which replace the bind variable.
            var_using:=  ':' || var_bind.position || '=' || value_string ||', '|| var_using  ;
         end loop;
         close cvalues;
         dbms_output.put_line(chr(13));
         dbms_output.put_line('----------------------------');
         dbms_output.put_line(' snapshot id : '||w_snap_id  || '    captured : ' || captured ||' from ' ||to_char(begin_interval,'DD/MM/YY HH24:MM') || ' to ' ||to_char(end_interval,'DD/MM/YY HH24:MM'));
         dbms_output.put_line(' Bind value :'||var_using);
         dbms_output.put_line(' Query with bind value : ');
         dbms_output.put_line(dest);
 end loop;

 close csnap_id;
end;
/

prompt You can use   @d_bind_v  &1   to use v$ view to display current query with bind variable 
undef sqlid
