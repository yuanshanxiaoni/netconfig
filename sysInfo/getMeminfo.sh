#!/bin/bash - 
#===============================================================================
#
#          FILE:  getMeminfo.sh
# 
#         USAGE:  ./getMeminfo.sh 
# 
#   DESCRIPTION:  获取内存使用率
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: poornigga
#       COMPANY: 
#       CREATED: 2011年04月08日 15时57分07秒 CST
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error

count=0
total=0
unused=0
usage=0

while read memi; do
    if [ $count -eq 0 ]; then
        total=$memi
    elif [ $count -eq 1 ]; then
        unused=$memi
    else
        unused=0
    fi
    count=`expr $count + 1`
done < <(cat /proc/meminfo | grep "Mem" | awk '{print $2}')

usage=`echo "scale=2; 100 * ( $total - $unused ) / $total " | bc `
echo "Mem Usage : $usage%"

