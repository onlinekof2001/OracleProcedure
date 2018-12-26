#!/bin/bash
if [ -f /etc/issue ]
then 
    usage=$(df -Ph | grep -E 'data1|index1' | awk '{print $5}') 
else
    usage=$(df -Pg | grep -E 'data1|index1' | awk '{print $5}')
fi
