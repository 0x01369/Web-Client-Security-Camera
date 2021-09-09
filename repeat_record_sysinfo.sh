#!/bin/sh

#本脚本用于每30秒调用一次 show_sysinfo.sh ,不再在crond 里调用
# $1 指定间隔秒数
if [ -n "$1" ] ; then
PerSec=$1
else
PerSec=30
fi

while [ true ] ;
do
/mnt/mtd/show_sysinfo.sh >> /mnt/nfs/running.today
sleep $PerSec
done
