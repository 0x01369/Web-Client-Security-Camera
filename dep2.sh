#!/bin/sh

modprobe nfs

#rm /mnt/mtd/preupgrade.sh
#rm /mnt/mtd/productcheck

#telnetd &

export mac=$(cat /etc/init.d/mac.dat)
/mnt/mtd/flashParam -r 0
if [ $? -eq 0 ]; then
export mac=$(cat /tmp/flashparam)
fi
ifconfig eth0 down
ifconfig eth0 hw ether $mac
ifconfig eth0 up

ifconfig lo up
route add -net 224.0.0.0 netmask 240.0.0.0 dev eth0

mount -t usbfs none /proc/bus/usb                                 

STMMAC_IRQNUM=`grep 'stmmaceth' /proc/interrupts | cut -c 2,3`
echo 2 > /proc/irq/$STMMAC_IRQNUM/smp_affinity
echo 2 > /proc/sys/net/ipv4/tcp_syn_retries

/mnt/mtd/setTZ
hwclock -s
#/mnt/mtd/softVersion

##等待OS识别U盘转储盘
Wait_DumpDiskIntoOS()
{
  n=0
	while [ 1 ] ; do
		ls /sys/block -la | grep -q "hiusb-ehci.0"
		[ $? -eq 0 ] && break
		sleep 1s
		let "n+=1"
		if [ $n -gt 5 ] ; then
		  echo "NOTICE:timeout for find DumpDisk"
			break
		fi
	done
	echo "Wait_DumpDiskIntoOS done."
}

Do_copyConfig()
{
	cp /mnt/nfs/configInfo/Config/OR_* /mnt/mtd/configInfo/Config/
	cp /mnt/nfs/configInfo/factoryConfig/OR_* /mnt/mtd/configInfo/factoryConfig/
	
	diff /mnt/nfs/configInfo/Config/EXP_RW_DeviceInfo.xml /mnt/mtd/default/EXP_RW_DeviceInfo.xml > /dev/null
	if [ $? -ne 0 ]; then
		cp /mnt/nfs/configInfo/Config/EXP_RW_DeviceInfo.xml /mnt/mtd/default/
		cp /mnt/nfs/configInfo/Config/EXP_RW_DeviceInfo.xml /mnt/mtd/configInfo/Config/
	fi	
	echo "Do_copyConfig ."
}

Do_For_Test()
{
	rm -rf /mnt/nfs/*
	##这里需要设置IP以便挂载nfs
	##ifconfig eth0 192.168.1.201 netmask 255.255.255.0
	##sleep 5
	##mount -t nfs -o intr,nolock,timeo=3,tcp,soft,rsize=1024,wsize=1024 192.168.1.80:/f/nfs_dir /mnt/nfs
	##sleep 5
	##Do_copyConfig
	
	Wait_DumpDiskIntoOS
	cd /mnt/mtd && ./findDumpDisk.sh
	if [ "$?" -eq "0" ] ; then
		#程序崩溃时生成corefile
		ulimit -c unlimited
		echo 1 > /proc/sys/kernel/core_uses_pid
		echo "/mnt/nfs/core-%e-%p-%t" > /proc/sys/kernel/core_pattern
		test -d .debug || ln -s /mnt/nfs/debuginfo .debug
		#syslogd -s 102400
		#klogd
		#test -d /var/spool/cron/crontabs || mkdir -p /var/spool/cron/crontabs
		#crontab /mnt/mtd/cron_file_debug
		#crond
		#setsid /mnt/mtd/repeat_record_sysinfo.sh 60 &
		setsid /mnt/mtd/getSysInfoV2.sh>>/mnt/nfs/sysinfo.log  &
	fi
}

if [ ! -f /mnt/mtd/configInfo/factoryConfig/OR_factoryConfig.xml ]; then
Do_For_Test
fi

cd /mnt/mtd && ./run.sh &
