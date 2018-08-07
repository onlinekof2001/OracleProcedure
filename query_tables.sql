/*
Query all tables in a specific tablespace, and order by the size of those tables
*/

COL OWNER FOR A30
COL TABLE_NAME FOR A30

SELECT TABLE_NAME,
       OWNER,BLOCKS*8192/(1024*1024*1024) "SIZE(GB)" 
  FROM DBA_TABLES 
 WHERE TABLESPACE_NAME='&tbsp'
 ORDER BY BLOCKS DESC;