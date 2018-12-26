#!/bin/bash

for i in tetrix02_rtdkm1odb07 tetrix02_rtdkm1odb08 tetrix02_rtdkm1odb09
do
function varified_connect(){
    /usr/bin/sqlplus64 -S -L oraexploit/judehey@$i <<EOF
quit;
EOF
    if [ $? != 0 ]
    then
        if [[ ${i:0-3:1} =~ [bB] ]]
        then
            counects=$(echo $i | awk 'BEGIN{FS=OFS=""}$(NF-2)="t"')
        else
            counects=$(echo $i | awk 'BEGIN{FS=OFS=""}$(NF-2)="b"')
        fi
    else
        connects=$i
    fi
}
varified_connect
done
