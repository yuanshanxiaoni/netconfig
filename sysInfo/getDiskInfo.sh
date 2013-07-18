#!/bin/bash - 
#===============================================================================
#
#          FILE:  getDiskInfo.sh
# 
#         USAGE:  ./getDiskInfo.sh 
# 
#   DESCRIPTION:  获取硬盘使用率
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: YOUR NAME (), 
#       COMPANY: 
#       CREATED: 2011年04月08日 16时53分30秒 CST
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error

# back up
#df -h | awk 'NF==1{printf $0;next}NF{print $0}' | awk 'NR>1{print $1,$(NF-3)}'

total=0
used=0
usage=0

while read line; do
    used=`echo "scale=2; $used + $line" | bc`
done < <(df -k | awk 'NF==1{printf $0;next}NF{print $0}' | awk 'NR>1{print $3}')

usedG=`echo "scale=2; $used / (1024 * 1024)" | bc`

#echo $usedG G

total=`fdisk -l | grep "GB" | awk '{ print $3}'`
#echo "total = $total"

usage=`echo "scale=2; 100 * $usedG / $total " | bc`
echo "Disk Usage : $usage%"
