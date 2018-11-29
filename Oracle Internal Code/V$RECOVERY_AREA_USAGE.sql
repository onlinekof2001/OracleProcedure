select fusg.file_type,
       decode(nvl2(ra.name, ra.space_limit, 0),
              0,
              0,
              round(nvl(fusg.space_used, 0) / ra.space_limit, 4) * 100),
       decode(nvl2(ra.name, ra.space_limit, 0),
              0,
              0,
              round(nvl(fusg.space_reclaimable, 0) / ra.space_limit, 4) * 100),
       nvl2(ra.name, fusg.number_of_files, 0),
       ra.con_id
  from v$recovery_file_dest ra,
       (select 'CONTROL FILE' file_type,
               sum(case
                     when ceilasm = 1 and name like '+%' then
                      ceil(((block_size * file_size_blks) + 1) / 1048576) *
                      1048576
                     else
                      block_size * file_size_blks
                   end) space_used,
               0 space_reclaimable,
               count(*) number_of_files
          from v$controlfile,
               (select /*+ no_merge */
                 ceilasm
                  from x$krasga)
         where is_recovery_dest_file = 'YES' /* CONTROL FILE Part */
        union all
        select 'REDO LOG' file_type,
               sum(case
                     when ceilasm = 1 and member like '+%' then
                      ceil((l.bytes + 1) / 1048576) * 1048576
                     else
                      l.bytes
                   end) space_used,
               0 space_reclaimable,
               count(*) number_of_files
          from (select group#, bytes
                  from v$log
                union
                select group#, bytes
                  from v$standby_log) l,
               v$logfile lf,
               (select /*+ no_merge */
                 ceilasm
                  from x$krasga)
         where l.group# = lf.group#
           and lf.is_recovery_dest_file = 'YES' /* REDO LOG Part */
        union all
        select 'ARCHIVED LOG' file_type,
               sum(al.file_size) space_used,
               sum(case
                     when dl.rectype = 11 then
                      al.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select recid,
                       case
                         when ceilasm = 1 and name like '+%' then
                          ceil(((blocks * block_size) + 1) / 1048576) *
                          1048576
                         else
                          blocks * block_size
                       end file_size
                  from v$archived_log,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and name is not null) al,
               x$kccagf dl
         where al.recid = dl.recid(+)
           and dl.rectype(+) = 11  /* ARCHIVED LOG Part */
        union all
        select 'BACKUP PIECE' file_type,
               sum(bp.file_size) space_used,
               sum(case
                     when dl.rectype = 13 then
                      bp.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select recid,
                       case
                         when ceilasm = 1 and handle like '+%' then
                          ceil((bytes + 1) / 1048576) * 1048576
                         else
                          bytes
                       end file_size
                  from v$backup_piece,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and handle is not null) bp,
               x$kccagf dl
         where bp.recid = dl.recid(+)
           and dl.rectype(+) = 13  /* BACKUP PIECE Part */
        union all
        select 'IMAGE COPY' file_type,
               sum(dc.file_size) space_used,
               sum(case
                     when dl.rectype = 16 then
                      dc.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select recid,
                       case
                         when ceilasm = 1 and name like '+%' then
                          ceil(((blocks * block_size) + 1) / 1048576) *
                          1048576
                         else
                          blocks * block_size
                       end file_size
                  from v$datafile_copy,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and name is not null) dc,
               x$kccagf dl
         where dc.recid = dl.recid(+)
           and dl.rectype(+) = 16  /* IMAGE COPY Part */
        union all
        select 'FLASHBACK LOG' file_type,
               nvl(fl.space_used, 0) space_used,
               nvl(fb.reclsiz, 0) space_reclaimable,
               nvl(fl.number_of_files, 0) number_of_files
          from (select sum(case
                             when ceilasm = 1 and name like '+%' then
                              ceil((fl.bytes + 1) / 1048576) * 1048576
                             else
                              bytes
                           end) space_used,
                       count(*) number_of_files
                  from v$flashback_database_logfile fl,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)) fl,
               (select sum(to_number(fblogreclsiz)) reclsiz from x$krfblog) fb /* FLASHBACK LOG Part */
        union all
        select 'FOREIGN ARCHIVED LOG' file_type,
               sum(rlr.file_size) space_used,
               sum(case
                     when rlr.purgable = 1 then
                      rlr.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select case
                         when ceilasm = 1 and rlnam like '+%' then
                          ceil(((rlbct * rlbsz) + 1) / 1048576) * 1048576
                         else
                          rlbct * rlbsz
                       end file_size,
                       case
                         when bitand(rlfl2, 4096) = 4096 then
                          1
                         when bitand(rlfl2, 8192) = 8192 then
                          1
                         else
                          0
                       end purgable
                  from x$kccrl,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where bitand(rlfl2, 64) = 64
                   and rlnam is not null) rlr  /* FOREIGN ARCHIVED LOG Part */
        union all
        select 'AUXILIARY DATAFILE COPY' file_type,
               sum(adc.file_size) space_used,
               sum(case
                     when adc.purgable = 1 then
                      adc.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select case
                         when ceilasm = 1 and adfcnam like '+%' then
                          ceil(((adfcnblks * adfcbsz) + 1) / 1048576) *
                          1048576
                         else
                          adfcnblks * adfcbsz
                       end file_size,
                       adfcrecl purgable
                  from x$kccadfc /* */,
                       (select /*+ no_merge */ 
                         ceilasm
                          from x$krasga) /* x$krasga 用途不明*/
                 where bitand(adfcflg, 1) = 1
                   and adfcnam is not null) adc  /* AUXILIARY DATAFILE COPY Part */ ) fusg

documents:
https://blog.dbi-services.com/drilling-down-vrecoveryareausage/
11G
select fusg.file_type,
       decode(nvl2(ra.name, ra.space_limit, 0),
              0,
              0,
              round(nvl(fusg.space_used, 0) / ra.space_limit, 4) * 100),
       decode(nvl2(ra.name, ra.space_limit, 0),
              0,
              0,
              round(nvl(fusg.space_reclaimable, 0) / ra.space_limit, 4) * 100),
       nvl2(ra.name, fusg.number_of_files, 0)
  from v$recovery_file_dest ra,
       (select 'CONTROL FILE' file_type,
               sum(case
                     when ceilasm = 1 and name like '+%' then
                      ceil(((block_size * file_size_blks) + 1) / 1048576) *
                      1048576
                     else
                      block_size * file_size_blks
                   end) space_used,
               0 space_reclaimable,
               count(*) number_of_files
          from v$controlfile,
               (select /*+ no_merge */
                 ceilasm
                  from x$krasga)
         where is_recovery_dest_file = 'YES'
        union all
        select 'REDO LOG' file_type,
               sum(case
                     when ceilasm = 1 and member like '+%' then
                      ceil((l.bytes + 1) / 1048576) * 1048576
                     else
                      l.bytes
                   end) space_used,
               0 space_reclaimable,
               count(*) number_of_files
          from (select group#, bytes
                  from v$log
                union
                select group#, bytes
                  from v$standby_log) l,
               v$logfile lf,
               (select /*+ no_merge */
                 ceilasm
                  from x$krasga)
         where l.group# = lf.group#
           and lf.is_recovery_dest_file = 'YES'
        union all
        select 'ARCHIVED LOG' file_type,
               sum(al.file_size) space_used,
               sum(case
                     when dl.rectype = 11 then
                      al.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select recid,
                       case
                         when ceilasm = 1 and name like '+%' then
                          ceil(((blocks * block_size) + 1) / 1048576) *
                          1048576
                         else
                          blocks * block_size
                       end file_size
                  from v$archived_log,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and name is not null) al,
               x$kccagf dl
         where al.recid = dl.recid(+)
           and dl.rectype(+) = 11
        union all
        select 'BACKUP PIECE' file_type,
               sum(bp.file_size) space_used,
               sum(case
                     when dl.rectype = 13 then
                      bp.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select recid,
                       case
                         when ceilasm = 1 and handle like '+%' then
                          ceil((bytes + 1) / 1048576) * 1048576
                         else
                          bytes
                       end file_size
                  from v$backup_piece,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and handle is not null) bp,
               x$kccagf dl
         where bp.recid = dl.recid(+)
           and dl.rectype(+) = 13
        union all
        select 'IMAGE COPY' file_type,
               sum(dc.file_size) space_used,
               sum(case
                     when dl.rectype = 16 then
                      dc.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select recid,
                       case
                         when ceilasm = 1 and name like '+%' then
                          ceil(((blocks * block_size) + 1) / 1048576) *
                          1048576
                         else
                          blocks * block_size
                       end file_size
                  from v$datafile_copy,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and name is not null) dc,
               x$kccagf dl
         where dc.recid = dl.recid(+)
           and dl.rectype(+) = 16
        union all
        select 'FLASHBACK LOG' file_type,
               nvl(fl.space_used, 0) space_used,
               nvl(fb.reclsiz, 0) space_reclaimable,
               nvl(fl.number_of_files, 0) number_of_files
          from (select sum(case
                             when ceilasm = 1 and name like '+%' then
                              ceil((fl.bytes + 1) / 1048576) * 1048576
                             else
                              bytes
                           end) space_used,
                       count(*) number_of_files
                  from v$flashback_database_logfile fl,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)) fl,
               (select sum(to_number(fblogreclsiz)) reclsiz from x$krfblog) fb
        union all
        select 'FOREIGN ARCHIVED LOG' file_type,
               sum(rlr.file_size) space_used,
               sum(case
                     when rlr.purgable = 1 then
                      rlr.file_size
                     else
                      0
                   end) space_reclaimable,
               count(*) number_of_files
          from (select case
                         when ceilasm = 1 and rlnam like '+%' then
                          ceil(((rlbct * rlbsz) + 1) / 1048576) * 1048576
                         else
                          rlbct * rlbsz
                       end file_size,
                       case
                         when bitand(rlfl2, 4096) = 4096 then
                          1
                         when bitand(rlfl2, 8192) = 8192 then
                          1
                         else
                          0
                       end purgable
                  from x$kccrl,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where bitand(rlfl2, 64) = 64
                   and rlnam is not null) rlr) fusg


-- Details(查看归档可回收):
set linesize 200 pagesize 1000
column file_type format a15
column file_name format a85
select file_type,
       name file_name,
       space_used/1048576 Mbytes,
       CASE
         WHEN space_reclaimable >= space_used THEN
          'YES'
         ELSE
          'NO'
       END reclaimable,
       completion_time
  FROM (select 'CONTROL FILE' file_type,
               name,
               CAST(NULL AS DATE) completion_time,
               (case
                 when ceilasm = 1 and name like '+%' then
                  ceil(((block_size * file_size_blks) + 1) / 1048576) *
                  1048576
                 else
                  block_size * file_size_blks
               end) space_used,
               0 space_reclaimable,
               1 number_of_files
          from v$controlfile,
               (select /*+ no_merge */
                 ceilasm
                  from x$krasga)
         where is_recovery_dest_file = 'YES'
        union all
        select 'ARCHIVED LOG' file_type,
               name,
               completion_time,
               (al.file_size) space_used,
               (case
                 when dl.rectype = 11 then
                  al.file_size
                 else
                  0
               end) space_reclaimable,
               1 number_of_files
          from (select recid,
                       name,
                       completion_time,
                       case
                         when ceilasm = 1 and name like '+%' then
                          ceil(((blocks * block_size) + 1) / 1048576) *
                          1048576
                         else
                          blocks * block_size
                       end file_size
                  from v$archived_log,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and name is not null) al,
               x$kccagf dl
         where al.recid = dl.recid(+)
           and dl.rectype(+) = 11
        union all
        select 'BACKUP PIECE' file_type,
               handle,
               completion_time,
               (bp.file_size) space_used,
               (case
                 when dl.rectype = 13 then
                  bp.file_size
                 else
                  0
               end) space_reclaimable,
               1 number_of_files
          from (select recid,
                       handle,
                       completion_time,
                       case
                         when ceilasm = 1 and handle like '+%' then
                          ceil((bytes + 1) / 1048576) * 1048576
                         else
                          bytes
                       end file_size
                  from v$backup_piece,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and handle is not null) bp,
               x$kccagf dl
         where bp.recid = dl.recid(+)
           and dl.rectype(+) = 13
        union all
        select 'IMAGE COPY' file_type,
               name,
               completion_time,
               (dc.file_size) space_used,
               (case
                 when dl.rectype = 16 then
                  dc.file_size
                 else
                  0
               end) space_reclaimable,
               1 number_of_files
          from (select recid,
                       name,
                       completion_time,
                       case
                         when ceilasm = 1 and name like '+%' then
                          ceil(((blocks * block_size) + 1) / 1048576) *
                          1048576
                         else
                          blocks * block_size
                       end file_size
                  from v$datafile_copy,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where is_recovery_dest_file = 'YES'
                   and name is not null) dc,
               x$kccagf dl
         where dc.recid = dl.recid(+)
           and dl.rectype(+) = 16
        union all
        select 'FLASHBACK LOG' file_type,
               name,
               first_time,
               nvl(fl.space_used, 0) space_used,
               nvl(fb.reclsiz, 0) space_reclaimable,
               nvl(fl.number_of_files, 0) number_of_files
          from (select name,
                       first_time,
                       (case
                         when ceilasm = 1 and name like '+%' then
                          ceil((fl.bytes + 1) / 1048576) * 1048576
                         else
                          bytes
                       end) space_used,
                       1 number_of_files
                  from v$flashback_database_logfile fl,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)) fl,
               (select sum(to_number(fblogreclsiz)) reclsiz from x$krfblog) fb
        union all
        select 'FOREIGN ARCHIVED LOG' file_type,
               rlnam,
               CAST(NULL AS DATE),
               (rlr.file_size) space_used,
               (case
                 when rlr.purgable = 1 then
                  rlr.file_size
                 else
                  0
               end) space_reclaimable,
               1 number_of_files
          from (select rlnam,
                       case
                         when ceilasm = 1 and rlnam like '+%' then
                          ceil(((rlbct * rlbsz) + 1) / 1048576) * 1048576
                         else
                          rlbct * rlbsz
                       end file_size,
                       case
                         when bitand(rlfl2, 4096) = 4096 then
                          1
                         when bitand(rlfl2, 8192) = 8192 then
                          1
                         else
                          0
                       end purgable
                  from x$kccrl,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where bitand(rlfl2, 64) = 64
                   and rlnam is not null) rlr) fusg

