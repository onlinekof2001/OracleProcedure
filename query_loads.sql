DBA_HIST_SYSMETRIC_SUMMARY
https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/DBA_HIST_SYSMETRIC_SUMMARY.html#GUID-E6377E5F-1FFF-4563-850F-C361B9D85048
-- 业务数据库的平均的事务量
select instance_number,
       metric_unit,
       trunc(begin_time) time,
       round(avg(average), 2) average
  from DBA_HIST_SYSMETRIC_SUMMARY
 where metric_unit = 'Transactions Per Second'
   and begin_time >=
       to_date('2018-12-04 08:00:00', 'yyyy-mm-dd hh24:mi:ss')
   and end_time <= to_date('2018-12-04 23:00:00', 'yyyy-mm-dd hh24:mi:ss')
 group by instance_number, metric_unit, trunc(begin_time)
 order by instance_number;
 
-- 检查某个用户的事务量
select s.USERNAME,
       sum(se.VALUE) "session transaction number",
       sum(sy.VALUE) " database transaction number"
  from v$session s, v$sesstat se, v$sysstat sy
 where s.sid = se.SID
   and se.STATISTIC# = sy.STATISTIC#
   and sy.NAME = 'user commits'
   and s.USERNAME = upper('&username')
 group by s.USERNAME;