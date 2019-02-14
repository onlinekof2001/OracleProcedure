prompt
prompt
@d_init_variable.sql
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
Prompt | scripts and parameters                                                             | comments                                                            | paramters                                      | 
Prompt | -----------------------------------------------------------------------------------|-------------------------------------------------------------|------------------------------------------------| 
prompt | @d_init_variable.sql                                                               | use this script to initialise some SQPLUS prameter          |                                                |  
prompt |                                                                                    | like set lines, pages, numformat                            |                                                |
prompt | @d_perf                                 2                                          | list the duty scripts to use for a performance probleme     | nb days                                        |  
prompt | @d_sess                                                                            | list the script to use to manage session (kill, ...)        |                                                | 
prompt | @d_recovery_area                                                                   | display information about recovery area                     |                                                | 
prompt | @d_archivelog_hour                      5                                          | list archive log by hour                                    |                                                | 
prompt

set verif on
clear col
undef 1 2 3 4 5 6 7 8 9
