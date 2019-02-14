/* script so reiniatlise sqlplus system variable */

set appinfo  OFF
set arraysize 15
set autocommit OFF
set autoprint OFF
set autorecovery OFF
set autotrace OFF
set blockterminator "." 
set cmdsep OFF
set colsep " "
set concat "." 
set copycommit 0
set COPYTYPECHECK  ON
set define "&" 
set describe DEPTH 1 LINENUM OFF INDENT ON
set echo OFF
set editfile "afiedt.buf"
set embedded OFF
set errorlogging  OFF
set escape OFF
set escchar OFF
set exitcommit ON
set FEEDBACK  6 

set flagger OFF
set flush ON
set heading ON
set headsep "|" 
set linesize 80
set loboffset 1
set logsource ""
set long 80
set longchunksize 80

set markup HTML OFF HEAD "<style type='text/css'> body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#f7f7e7; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} h1 {font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px;-
set } h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} a {font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;}</style><title>SQL*Plus Report</title>" BODY "" TABLE "border='1' width='90%' align='center' summary='Script output'" SPOOL OFF ENTMAP ON PREFORMAT OFF

set newpage 1
set null ""
set numformat ""
set numwidth 10
set pagesize 14
set PAUSE OFF
set recsep WRAP
set recsepchar " "
set serveroutput OFF
set shiftinout INVISIBLE
set showmode OFF
set sqlblanklines OFF
set sqlcase MIXED
set sqlcontinue "> "
set sqlnumber ON
set sqlpluscompatibility 11.2.0
set sqlprefix "#" 
SET SQLPROMPT '&_CONNECT_IDENTIFIER> '
set sqlterminator ";"


set suffix "sql"
set tab ON
set termout ON
set time OFF
set timing OFF
set trimout ON
set trimspool OFF
set underline "-" 
set verify ON
set wrap on
set xquery BASEURI "" CONTEXT "" NODE DEFAULT ORDERING DEFAULT


-- specifics :
set term off 
set pages 1024
set lines 1024
set serverout on
set long 1000
set longc 1000
alter session set nls_date_format='YYYY/MM/DD HH24:MI:SS';
alter session set nls_timestamp_format='YYYY/MM/DD HH24:MI:SS';
alter session set nls_timestamp_tz_format='YYYY/MM/DD HH24:MI:SS TZH:TZM';


col new_prompt new_value  new_prompt
select db_unique_name new_prompt from v$database;
set sqlprompt '&new_prompt> '
clear col 

undef new_prompt
set term on