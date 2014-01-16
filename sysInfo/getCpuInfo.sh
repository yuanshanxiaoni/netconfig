#!/bin/bash - 
#===============================================================================
#
#          FILE:  getCpuInfo.sh
# 
#         USAGE:  ./getCpuInfo.sh 
# 
#   DESCRIPTION:  获取CPU使用率
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  poorNigga
#       COMPANY:  
#       CREATED:  2011年04月08日 15时50分43秒 CST
#      REVISION:  1
#===============================================================================
set -o nounset                              # Treat unset variables as an error

##echo user nice system idle iowait irq softirq  

CPULOG_1=$(cat /proc/stat | grep 'cpu ' | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')  
SYS_IDLE_1=$(echo $CPULOG_1 | awk '{print $4}')  
Total_1=$(echo $CPULOG_1 | awk '{print $1+$2+$3+$4+$5+$6+$7}')  
 
sleep 3
 
CPULOG_2=$(cat /proc/stat | grep 'cpu ' | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')  
SYS_IDLE_2=$(echo $CPULOG_2 | awk '{print $4}')  
Total_2=$(echo $CPULOG_2 | awk '{print $1+$2+$3+$4+$5+$6+$7}')  
 
SYS_IDLE=`expr $SYS_IDLE_2 - $SYS_IDLE_1`  
 
Total=`expr $Total_2 - $Total_1`  
SYS_USAGE=`expr $SYS_IDLE/$Total*100 |bc -l`  
 
SYS_Rate=`expr 100-$SYS_USAGE |bc -l`  
 
Disp_SYS_Rate=`expr "scale=3; $SYS_Rate/1" |bc`  

echo "CPU Usage : " $Disp_SYS_Rate%  
 
