select rdi.location,
       rdi.slimit,
       (rdi.sused + rdi.scfile),
       rdi.srecl + client.srecl,
       rdi.fcnt
  from x$kccrdi rdi,
       (select sum(recl) srecl
          from (select 0 recl
                  from dual
                union
                select to_number(fblogreclsiz) recl
                  from x$krfblog
                 where rownum = 1
                union
                select sum(case
                             when ceilasm = 1 and rlnam like '+%' then
                              ceil(((rlbct * rlbsz) + 1) / 1048576) * 1048576
                             else
                              rlbct * rlbsz
                           end) recl
                  from x$kccrl,
                       (select /*+ no_merge */
                         ceilasm
                          from x$krasga)
                 where bitand(rlfl2, 64) = 64
                   and (bitand(rlfl2, 4096) = 4096 or
                        bitand(rlfl2, 8192) = 8192)
                   and rlnam is not null)) client