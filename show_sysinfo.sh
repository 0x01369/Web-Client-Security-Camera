#!/bin/sh

#本脚本用于生成 嵌入式N9000 系统资源、硬盘IO、网络流量等情况, flag固定为 [iNfO], flag_end 固定为[InFo]

TITLE="_FLAG_  IPAddr         date        time    CPU_usr CPU_sys CPU_idle CPU_io OSMem_used OSMem_free OSMem_cache AP_pid AP_cpu AP_VSZMem AP_RSSMem AP_OpenFD AP_Thread ifstat_in  ifstat_out ipcEST ipcTotal   gmac0  eth0_speed eth0_link  eth0rx_bytes   eth0rx_drop   eth0tx_bytes  eth0tx_drop IO-STAT            TITLE_END"

FLAG_START="[iNfO]"
FLAG_END="[InFo]"
TOP_LOG="/tmp/top.log"
IOSTAT_tmp="/tmp/iostat.tmp"
IOSTAT_log="/tmp/iostat.info"
NETSTAT_log="/tmp/netstat.info"

top -b -n 1 -d 1 > $TOP_LOG
nowday=`date +"%F %H:%M:%S"`
stmp=`free -k | grep "Mem"`
OSMem_used=`echo $stmp | awk '{print $3}'`
OSMem_free=`echo $stmp | awk '{print $4}'`
#OSMem_buf=`echo $stmp | awk '{print $6}'`
OSMem_cache=`grep Cached /proc/meminfo | head -n 1 | awk '{print $2}'`

IPAddr=`ifconfig | grep -v phyeth0 | grep eth0 -A 1 | tail -n 1`
IPAddr=${IPAddr#*addr:}
IPAddr=${IPAddr% Bcast*}

#去掉%，不然用printf出错
CPULine=`grep "CPU:" $TOP_LOG`
CPU_usr=`echo $CPULine | awk '{print $2}'`
CPU_usr=${CPU_usr%%%*}
CPU_sys=`echo $CPULine | awk '{print $4}'`
CPU_sys=${CPU_sys%%%*}
CPU_idle=`echo $CPULine | awk '{print $8}'`
CPU_idle=${CPU_idle%%%*}
CPU_io=`echo $CPULine | awk '{print $10}'`
CPU_io=${CPU_io%%%*}
#echo $CPU_usr  $CPU_sys $CPU_idle $CPU_io

sTop=`grep "NVMS9000" $TOP_LOG | head -n 1`
sps=`ps | grep "NVMS9000" | grep -v "grep"`
if [ -n "$sTop" ] ; then
##NVMS9000 的值有两个会连着，所以只能倒数取值 -qws
AP_cpu=`echo $sTop | awk '{print $(NF-2)}'`
fi
if [ -n "$sps" ] ; then
AP_pid=`echo $sps | awk '{print $1}'`
AP_VSZMem=`grep VmSize /proc/$AP_pid/status | awk '{print $2}'`
AP_RSSMem=`grep VmRSS /proc/$AP_pid/status | awk '{print $2}'`
AP_Thread=`grep Threads /proc/$AP_pid/status | awk '{print $2}'`
AP_OpenFD=`ls /proc/$AP_pid/fd | wc -w`
fi

ifstat_tmp=`ifstat -S -b 1 1 | tail -n 1`
ifstat_in=`echo $ifstat_tmp | awk '{print $1}'`
ifstat_out=`echo $ifstat_tmp | awk '{print $2}'`

netstat -ntp >$NETSTAT_log 2>/dev/null
ipcEST=`grep NVMS9000 $NETSTAT_log | grep EST | grep -v 127.0.0.1:4567 | wc -l`
ipcTotal=`grep NVMS9000 $NETSTAT_log | grep -v 127.0.0.1:4567 | wc -l`
gmac0=`grep gmac0 /proc/interrupts | awk '{print $2}'`
eth0_speed=`cat /sys/class/net/eth0/speed`
eth0_link=`cat /sys/class/net/eth0/carrier`
eth0rx_bytes=`cat /sys/class/net/eth0/statistics/rx_bytes`
eth0rx_drop=`cat /sys/class/net/eth0/statistics/rx_dropped`
eth0tx_bytes=`cat /sys/class/net/eth0/statistics/tx_bytes`
eth0tx_drop=`cat /sys/class/net/eth0/statistics/tx_dropped`

IOSTAT_info=""
iostat /dev/sd? -t -k 1 2 > $IOSTAT_tmp
nLine=`cat $IOSTAT_tmp | wc -l`
let nLine/=2
tail -n $nLine $IOSTAT_tmp | grep Device -A 10 | while read line
do
	devName=`echo $line | awk '{print $1}'`
	if [ "$devName" == "Device:" ] || [ -z "$line" ] ; then
	 continue
	fi
	#跳过U盘
	removable=`cat /sys/block/$devName/removable`
	if [ $removable -eq 1 ]; then
		continue
	fi
	
	ReadRate=`echo $line | awk '{print $3}'`
	WriteRate=`echo $line | awk '{print $4}'`
	sInfo="$devName[R- $ReadRate : W- $WriteRate ]"
	sTmpInfo="$IOSTAT_info"
	IOSTAT_info="${sTmpInfo} ${sInfo}"
	echo "$IOSTAT_info" > $IOSTAT_log
done

IOSTAT_info=`cat $IOSTAT_log`

##输出， 如果是空的，需要用"--" 占位
[ -z "$IPAddr" ] && IPAddr="--"
[ -z "$nowday" ] && nowday="-- --"
[ -z "$CPU_usr" ] && CPU_usr="--"
[ -z "$CPU_sys" ] && CPU_sys="--"
[ -z "$CPU_idle" ] && CPU_idle="--"
[ -z "$CPU_io" ] && CPU_io="--"
[ -z "$OSMem_used" ] && OSMem_used="--"
[ -z "$OSMem_free" ] && OSMem_free="--"
[ -z "$OSMem_cache" ] && OSMem_cache="--"
[ -z "$OSMem_buf" ] && OSMem_buf="--"
[ -z "$AP_pid" ] && AP_pid="--"
[ -z "$AP_cpu" ] && AP_cpu="--"
[ -z "$AP_VSZMem" ] && AP_VSZMem="--"
[ -z "$AP_RSSMem" ] && AP_RSSMem="--"
[ -z "$AP_OpenFD" ] && AP_OpenFD="--"
[ -z "$AP_Thread" ] && AP_Thread="--"
[ -z "$ifstat_in" ] && ifstat_in="--"
[ -z "$ifstat_out" ] && ifstat_out="--"
[ -z "$ipcEST" ] && ipcEST="--"
[ -z "$ipcTotal" ] && ipcTotal="--"
[ -z "$IOSTAT_info" ] && IOSTAT_info="--"
[ -z "$gmac0" ] && gmac0="--"
[ -z "$eth0_speed" ] && eth0_speed="--"
[ -z "$eth0_link" ] && eth0_link="--"
[ -z "$eth0rx_bytes" ] && eth0rx_bytes="--"
[ -z "$eth0rx_drop" ] && eth0rx_drop="--"
[ -z "$eth0tx_bytes" ] && eth0tx_bytes="--"
[ -z "$eth0tx_drop" ] && eth0tx_drop="--"
echo "$TITLE"

echo -n "$FLAG_START  $IPAddr $nowday "
printf "%-8s" "$CPU_usr"
printf "%-8s" "$CPU_sys"
printf "%-9s" "$CPU_idle"
printf "%-8s" "$CPU_io"
printf "%-11s" "$OSMem_used"
printf "%-11s" "$OSMem_free"
printf "%-12s" "$OSMem_cache"
#printf "%-10s" "$OSMem_buf"
printf "%-7s" "$AP_pid"
printf "%-7s" "$AP_cpu"
printf "%-10s" "$AP_VSZMem"
printf "%-10s" "$AP_RSSMem"
printf "%-10s" "$AP_OpenFD"
printf "%-10s" "$AP_Thread"
printf "%-12s" "$ifstat_in"
printf "%-12s" "$ifstat_out"
printf "%-7s" "$ipcEST"
printf "%-7s" "$ipcTotal"
printf "%-12s" "$gmac0"
printf "%-12s" "$eth0_speed"
printf "%-8s" "$eth0_link"
printf "%-14s" "$eth0rx_bytes"
printf "%-14s" "$eth0rx_drop"
printf "%-14s" "$eth0tx_bytes"
printf "%-10s" "$eth0tx_drop"
printf "$IOSTAT_info $FLAG_END\n"
