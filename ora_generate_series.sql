create or replace type series_num is object
( n number);
/
create or replace type numbers_table is table of series_num;
/
-- Function body.
-- Created by ytt.
-- 2015/12/9
create or replace function ora_generate_series
(
f_start_num number := 1, -- Start number.
f_end_num number,  -- Finish number.
f_step_num number := 1 -- Step.
)
return numbers_table pipelined
is 
  list numbers_table := numbers_table();
  i number := 0;
  j number := 1;
begin
  i := f_start_num;
  j := 1;
  -- Increase nested table‘s size.
  list.extend(f_end_num);
  -- Loop begin.
  while i <= f_end_num loop
  -- Initlization.
    list(j) := series_num(null);
    list(j).n := i;
    pipe row(list(j));
    i := i + f_step_num;
    j := j + 1;
  end loop;
  return;
end;
/