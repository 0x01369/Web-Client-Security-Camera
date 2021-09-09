#!/bin/sh

#本脚本用于 1.添加记录SDK空间内存 2.改为每秒统计一次,当与上一次记录相差变化>2MB才记录 3. 如果在60秒内没变化，也记录一次资源情况

#上一次记录时的剩余内存
preFree=4096000
#有多少秒未记录了
timeEsc=0
# 3798M 和 3536/3535 的取值方法不一样
idelSDK=
#平台标记 3798M|3535|3536
PLATFORM=


TITLE="_FLAG_  IPAddr         date        time    CPU_usr CPU_sys CPU_idle CPU_io OSMem_used OSMem_free OSMem_cache OSMem_buf idelSDK AP_pid AP_cpu AP_VSZMem AP_RSSMem AP_FD AP_Sock AP_Thread ifstat_in  ifstat_out ipcEST ipcTotal Csp_RSS  Csp_FD Csp_Sock Csp_Thread BuddyInfo   IO-STAT     _END"
FLAG_START="[iNfO]"
FLAG_END="[InFo]"
TOP_LOG="/tmp/top.$$.log"
IOSTAT_tmp="/tmp/iostat.$$.tmp"
IOSTAT_log="/tmp/iostat.$$.info"
NETSTAT_log="/tmp/netstat.$$.info"

echo "$TITLE"

getIdleSDK_3798M()
{
	local idelSDK=`tail -n 2 /proc/media-mem | head -n 1 | awk '{print $5}'`
	echo $idelSDK
}

getIdleSDK_3536And3535()
{
	local v1=`grep "remain=" /proc/media-mem`
	local v2=${v1#*remain=}
	local idelSDK=${v2%%KB(*}
	echo $idelSDK
}

#判断平台
UNAME_R=`grep productInfo /mnt/mtd/AppPackInfo.ini`
UNAME_R=${UNAME_R#*productInfo=}
case "$UNAME_R" in
3535*)
	PLATFORM="3535"
	;;
3798M*)
	PLATFORM="3798M"
	;;
3536*)
	PLATFORM="3536"
	;;
3521A*)
	PLATFORM="3521A"
	;;
3531A*)
	PLATFORM="3531A"
	;;
3520D_V300*)
	PLATFORM="3520D_V300"
	;;		
esac

if [ "$PLATFORM" = "3798M" ] ; then
		func_idelSDK="getIdleSDK_3798M"
else
		func_idelSDK="getIdleSDK_3536And3535"
fi

#echo $PLATFORM

while true 
do
#echo preFree=$preFree
stmp=`free -k | grep "Mem"`
OSMem_free=`echo $stmp | awk '{print $4}'`

let nDiff="$preFree-$OSMem_free"
let timeEsc="$timeEsc+1"
if [ $nDiff -ge 2048 ] || [ $nDiff -lt -2048 ] || [ $timeEsc -ge 60 ] ; then
	OSMem_used=`echo $stmp | awk '{print $3}'`
	OSMem_buf=`echo $stmp | awk '{print $6}'`
	OSMem_cache=`grep Cached /proc/meminfo -w | awk '{print $2}'`
	
	idelSDK=`$func_idelSDK`
	
	top -b -n 1 -d 1 > $TOP_LOG
	nowday=`date +"%F %H:%M:%S"`
	
	#IPAddr=`ifconfig | grep -v phyeth0 | grep eth0 -A 1 | tail -n 1`
	IPAddr=`ifconfig | grep -v phyeth0 | grep "bond0\|eth0" -A 1 | grep "inet addr"`
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
	else
		AP_cpu="--"
	fi
	if [ -n "$sps" ] ; then
		AP_pid=`echo $sps | awk '{print $1}'`
		AP_VSZMem=`grep VmSize /proc/$AP_pid/status | awk '{print $2}'`
		AP_RSSMem=`grep VmRSS /proc/$AP_pid/status | awk '{print $2}'`
		AP_Thread=`grep Threads /proc/$AP_pid/status | awk '{print $2}'`
		AP_OpenFD=`ls /proc/$AP_pid/fd | wc -w`
		AP_Sock=`ls /proc/$AP_pid/fd -la | grep socket | wc -l`
	else
		AP_pid="--"
		AP_VSZMem="--"
		AP_RSSMem="--"
		AP_Thread="--"
		AP_OpenFD="--"
		AP_Sock="--"
	fi
	
	spsConfig=`ps | grep "ConfigSyncProc" | grep -v "grep"`
	if [ -n "$spsConfig" ] ; then
		Config_pid=`echo $spsConfig | awk '{print $1}'`
		Csp_RSSMem=`grep VmRSS /proc/$Config_pid/status | awk '{print $2}'`
		Csp_Thread=`grep Threads /proc/$Config_pid/status | awk '{print $2}'`
		Csp_OpenFD=`ls /proc/$Config_pid/fd | wc -w`
		Csp_Sock=`ls /proc/$Config_pid/fd -la | grep socket | wc -l`
	else
		Csp_RSSMem="--"
		Csp_Thread="--"
		Csp_OpenFD="--"
		Csp_Sock="--"
	fi
	
	#可能是双网卡(网络容错或多址设定)或POE ，取最大值记录
	ifstat_tmp=`ifstat -S -b 1 1 2>/dev/null | tail -n 1`
	ifstat_in1=`echo $ifstat_tmp | awk '{print $1}'`
	ifstat_in2=`echo $ifstat_tmp | awk '{print $3}'`
	if [ -z "$ifstat_in2" ] ; then
		ifstat_in=$ifstat_in1
	else
		if [ `expr $ifstat_in1 \> $ifstat_in2` -eq 0 ];then
			ifstat_in=$ifstat_in2
		else
			ifstat_in=$ifstat_in1
		fi
	fi
	
	ifstat_out1=`echo $ifstat_tmp | awk '{print $2}'`
	ifstat_out2=`echo $ifstat_tmp | awk '{print $4}'`
	if [ -z "$ifstat_out2" ] ; then
		ifstat_out=$ifstat_out1
	else
		if [ `expr $ifstat_out1 \> $ifstat_out2` -eq 0 ];then
			ifstat_out=$ifstat_out2
		else
			ifstat_out=$ifstat_out1
		fi
	fi
	
	netstat -ntp >$NETSTAT_log 2>/dev/null
  ipcEST=`grep NVMS9000 $NETSTAT_log | grep EST | grep -v 127.0.0.1:4567 | wc -l`
	ipcTotal=`grep NVMS9000 $NETSTAT_log | grep -v 127.0.0.1:4567 | wc -l`
	
	IOSTAT_info=""
	iostat /dev/sd? -t -k 1 2 >$IOSTAT_tmp 2>/dev/null
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
	
	IOSTAT_info=`cat $IOSTAT_log 2>/dev/null`
	BuddyStr=`cat /proc/buddyinfo`
	BuddyStr=${BuddyStr#*Normal}
	BuddyStr=`echo $BuddyStr |sed 's/^[ \t]*//g'`
	BuddyInfo=${BuddyStr//\ /,}
	
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
	[ -z "$idelSDK" ] && idelSDK="--"
	[ -z "$AP_pid" ] && AP_pid="--"
	[ -z "$AP_cpu" ] && AP_cpu="--"
	[ -z "$AP_VSZMem" ] && AP_VSZMem="--"
	[ -z "$AP_RSSMem" ] && AP_RSSMem="--"
	[ -z "$AP_OpenFD" ] && AP_OpenFD="--"
	[ -z "$AP_Sock" ] && AP_Sock="--"
	[ -z "$AP_Thread" ] && AP_Thread="--"
	[ -z "$Csp_RSSMem" ] && Csp_RSSMem="--"
	[ -z "$Csp_OpenFD" ] && Csp_OpenFD="--"
	[ -z "$Csp_Sock" ] && Csp_Sock="--"
	[ -z "$Csp_Thread" ] && Csp_Thread="--"
	[ -z "$ifstat_in" ] && ifstat_in="--"
	[ -z "$ifstat_out" ] && ifstat_out="--"
	[ -z "$ipcEST" ] && ipcEST="--"
	[ -z "$ipcTotal" ] && ipcTotal="--"
	[ -z "$IOSTAT_info" ] && IOSTAT_info="--"
	[ -z "$BuddyInfo" ] && BuddyInfo="--"
	
	#echo "$TITLE"

	echo -n "$FLAG_START "
	printf "%-16s" "$IPAddr "
	printf "%-19s" "$nowday "
	printf "%-8s" " $CPU_usr"
	printf "%-8s" "$CPU_sys"
	printf "%-9s" "$CPU_idle"
	printf "%-8s" "$CPU_io"
	printf "%-11s" "$OSMem_used"
	printf "%-11s" "$OSMem_free"
	printf "%-12s" "$OSMem_cache"
	printf "%-10s" "$OSMem_buf"
	printf "%-10s" "$idelSDK"
	printf "%-7s" "$AP_pid"
	printf "%-7s" "$AP_cpu"
	printf "%-10s" "$AP_VSZMem"
	printf "%-10s" "$AP_RSSMem"
	printf "%-6s" "$AP_OpenFD"
	printf "%-6s" "$AP_Sock"
	printf "%-10s" "$AP_Thread"
	printf "%-12s" "$ifstat_in"
	printf "%-12s" "$ifstat_out"
	printf "%-7s" "$ipcEST"
	printf "%-7s" "$ipcTotal"
	printf "%-10s" "$Csp_RSSMem"
	printf "%-6s" "$Csp_OpenFD"
	printf "%-6s" "$Csp_Sock"
	printf "%-10s" "$Csp_Thread"
	printf "$BuddyInfo $IOSTAT_info $FLAG_END\n"
	
	preFree=$OSMem_free
	timeEsc=0
fi
sleep 1s
done
