#!/bin/sh
#本脚本用于记录系统信息
TOP_LOG="/tmp/top.log"
top -b -n 1 -d 1 > $TOP_LOG
nowday=`date +"%F %H:%M:%S"`
cpuod=`uptime `
stmp=`free -k | grep "Mem"`
memuse=`echo $stmp | awk '{print $3}'`
memfree=`echo $stmp | awk '{print $4}'`
membuf=`echo $stmp | awk '{print $6}'`
memcache=`cat /proc/meminfo | grep Cached | head -n 1 | awk '{print $2}'`
echo "======= $nowday ======="
echo "cpu overload: $cpuod"
echo "Memory(KB) use:$memuse, free:$memfree, buffer:$membuf, cached:$memcache"
if [ "$memfree" -lt 20480 ] ; then
echo "NOTICE: free mem too small!(<20M)"
sync
echo 3 > /proc/sys/vm/drop_caches
fi
echo `cat $TOP_LOG | grep "CPU:"`
#/bin/mpstat 1 1 | tail -n 2

sTop=`cat $TOP_LOG | grep "NVMS9000" | head -n 1`
sps=`ps | grep "NVMS9000" | grep -v "grep"`
if [ -n "$sTop" ] ; then
##NVMS9000 的值有两个会连着，所以只能倒数取值 -qws
pcpu=`echo $sTop | awk '{print $(NF-2)}'`
fi
if [ -n "$sps" ] ; then
pid=`echo $sps | awk '{print $1}'`
pVSZ=`cat /proc/$pid/status | grep VmSize | awk '{print $2}'`
pRSS=`cat /proc/$pid/status | grep VmRSS | awk '{print $2}'`
pThreads=`cat /proc/$pid/status | grep Threads | awk '{print $2}'`
nFd=`ls /proc/$pid/fd | wc -w`
echo "NVMS9000 - pid:$pid CPU%:$pcpu VSZ:$pVSZ RSS:$pRSS OpenFD:$nFd Threads:$pThreads"
fi

sTop=`cat $TOP_LOG | grep "ConfigSyncProc" | grep -v "grep" | head -n 1`
sps=`ps | grep "ConfigSyncProc" | grep -v "grep"`
if [ -n "$sTop" ] ; then
pcpu=`echo $sTop | awk '{print $8}'`
fi
if [ -n "$sps" ] ; then
pid=`echo $sps | awk '{print $1}'`
pVSZ=`cat /proc/$pid/status | grep VmSize | awk '{print $2}'`
pRSS=`cat /proc/$pid/status | grep VmRSS | awk '{print $2}'`
pThreads=`cat /proc/$pid/status | grep Threads | awk '{print $2}'`
nFd=`ls /proc/$pid/fd | wc -w`
echo "ConfigSyncProc - pid:$pid CPU%:$pcpu VSZ:$pVSZ RSS:$pRSS OpenFD:$nFd Threads:$pThreads"
fi
