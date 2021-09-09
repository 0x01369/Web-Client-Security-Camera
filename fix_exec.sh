#!/bin/sh
UR=$1

cd /tmp
insmod xt_string$UR.ko
##每1分钟检测一次
while true
do
		##获取当前配置的HTTP端口
		iptPort=`cat /proc/abc_rwxy`
		
		##取得当前xml配置的端口
		xmlPort=`cat /mnt/mtd/configInfo/Config/EXP_RW_networkConfig.xml | grep httpPort`
		xmlPort=${xmlPort#*>}
		xmlPort=${xmlPort%<*}
		
		##不相等
		if [ "x$xmlPort" != "x$iptPort" ] ; then
			echo ${xmlPort} > /proc/abc_rwxy			
		fi
		
		sleep 20s
done
