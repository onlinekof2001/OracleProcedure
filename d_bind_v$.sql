SET SERVEROUTPUT ON FORMAT WORD_WRAPPED

---------------------------------------------------------------------------------------------------------------------
----- Auteur : Pascal 
-----
----- for a SQLID, this script display replace the bind variable by their value
-----
----- the bind value are read in V$ TABLES
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
  --- cursor use to read the sql_text. 
   cursor cQuery(cp_sqlid varchar2) is 
      select sql_text,sql_id from dba_hist_sqltext where sql_id = cp_sqlid;   
   
   
   type TAnyData is table of SYS.ANYDATA index by pls_integer;
   AValues TAnyData;
   
   type TVarchar is table of varchar2(30) index by pls_integer;
   AStrings TVarchar;

   
   -- cursor to read the bind value
    cursor CValues(cp_sqlid varchar2, cp_child_number number) is
      select value_anydata, position
        from v$sql_bind_capture
       where sql_id = cp_sqlid
         and child_number=cp_child_number 
      order by position desc;
   
    
  cursor csnap_id (cp_sqlid varchar2) is   
    select distinct b.CHILD_NUMBER from v$sql_bind_capture b
  where sql_id =cp_sqlid;
    
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
    w_child_number int;
    var_using varchar2(32000);
Begin  
   DBMS_OUTPUT.enable(10000000);
   select '&1' into sql_id from  dual ;
   
   open cQuery(sql_id);
   fetch cQuery into Stmt,w_sql_id ;
   close cQuery;
   
   dbms_output.put_line('ok'); 
   dbms_output.put_line('----------------------------');
   dbms_output.put_line('Originale query :');
   dbms_output.put_line('----------------------------');
   dbms_output.put_line('-'||Stmt);
   dbms_output.put_line(w_sql_id);
   open csnap_id(w_sql_id);
   
   -- boucle sur le snapid par défault, 3 snapid différents.
   loop
     fetch csnap_id into w_child_number;
     exit when csnap_id%notfound;
         dest := stmt;
         open cvalues (w_sql_id, w_child_number);
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
                  when 9   then value_string := '''' || anydata.AccessVarchar2(var_bind.bindvalue) || '''';
                  when 2   then value_string := to_char(anydata.AccessNumber(var_bind.bindvalue));

                  when 187 then value_string := 'to_timestamp(''' ||rtrim(to_char(anydata.accesstimestamp(var_bind.bindvalue),'DD/MM/YY HH24-MI-SS')) ||''' , ''DD/MM/YY HH24-MI-SS'')';
                  else value_string := ' data type not recognise id is ' || anydata.gettypename(var_bind.bindvalue) || '(' || anydata.gettype(var_bind.bindvalue, v_type) || ')';
               end case;
            end if;         
			-- I replace the bind variable by a string.
            dest := regexp_replace(dest,':' || var_bind.position ,value_string);
			-- I memorise the values which replace the bind variable.
            var_using:=  value_string ||','|| var_using  ;
         end loop;
         close cvalues;
         dbms_output.put_line('');
         dbms_output.put_line('----------------------------');
         dbms_output.put_line(' child number : '||w_child_number);
         dbms_output.put_line(' Bind value :'||var_using);
         dbms_output.put_line(dest);
 end loop;

 close csnap_id;
end;
/

