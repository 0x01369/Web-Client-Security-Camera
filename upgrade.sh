#!/bin/sh

export UpdateStatus=/mnt/mtd/Update.dat
export UpdateFileStatus=/mnt/mtd/UpdateFile.dat
export UpgradePath=/tmp/upgrade/
export UpgradeFilePath=$UpgradePath/upgrade.tar.gz
export PreUpgradeSh=/tmp/upgrade/preupgrade.sh
export UsbPath=/mnt/u

#挂载USB
mount_usb()
{
	cat /proc/partitions | tr -s "[\ ]" | cut -d\  -f5 | tr  "[\n]" "[ ]" > /tmp/dev_tmp
	for dev_name in $(cat /tmp/dev_tmp) ; do
		RESULT=`cat "/sys/block/$dev_name/removable"`
		if [ "$RESULT" = "1" ] ; then
			mkdir $UsbPath
			mount -t vfat -o codepage=936,iocharset=utf8 /dev/${dev_name}1 $UsbPath
			return
	  fi
	done
}

upgrade_by_usb()
{
	insmod /tmp/modules/extdrv/ehci-hcd.ko
	sleep 2
	rm -rf $UsbPath/*
	mount_usb
	sleep 2	
}

#从硬盘读取文件到UpgradePath
upgrade_by_disk()
{
	cd /dev
	for i in `ls sd?` ;
	do
	RESULT=`cat "/sys/block/$i/removable"`
	if [ "$RESULT" = "0" ] ; then
		dd if=/dev/$i of=/tmp/disk_$i.data bs=1 count=4 skip=440 >& /dev/null
		flag=`cat /tmp/disk_$i.data`
		if [ "x$flag" != "xDUMP" ] ; then				
			dd if=/dev/$i of=/tmp/mark_$i.data bs=1 count=4 skip=260 >& /dev/null
			flag=`cat /tmp/mark_$i.data`
			if [ "x$flag" = "xxT" ] ; then
				export DISKNAME=$i
				echo $DISKNAME
				break
			fi					
		fi
	fi
	done
	/mnt/mtd/upgradeFileFromDisk $DISKNAME
}

#升级开始1为usb，2为硬盘
RESULT=`cat "$UpdateStatus"`

echo "RESULT=$RESULT"
rm $UpdateStatus
mkdir $UpgradePath
#mount -t tmpfs tmpfs $UpgradePath

if [ "$RESULT" = "1" ] ; then
	if [ -f $UpdateFileStatus ] ; then
		echo "------------- $UpdateFileStatus exist ---------------"
		
		UPGRADE_FILENAME=`cat "$UpdateFileStatus"`
		rm $UpdateFileStatus
		upgrade_by_usb
		echo "------------- $UPGRADE_FILENAME  ---------------"	
		export UpgradeFilePath=${UsbPath}/${UPGRADE_FILENAME}	 
		echo "------------- $UpgradeFilePath  ---------------"	
	else
		echo "file $UpdateFileStatus not exist"
		return
	fi
	
elif [ "$RESULT" = "2" ] ; then
  upgrade_by_disk	
else
	echo "No need to recovery program from device"	
	#umount $UpgradePath && rm -rf $UpgradePath
	return	
fi

if [ ! -f "$UpgradeFilePath" ]; then
	echo "can not find file $UpgradeFilePath"
	#umount $UpgradePath && rm -rf $UpgradePath
	umount $UsbPath && rm -rf $UsbPath
	reboot
	exit -1;
else
	tar -zxvf "$UpgradeFilePath" -C $UpgradePath
	sleep 2
	cd $UpgradePath
	md5sum -c upgradeCheck.dat
	if [ "$?" != 0 ] ; then 
		echo "$UpgradeFilePath file error md5sum fail"
		#umount $UpgradePath && 
		rm -rf $UpgradePath
		umount $UsbPath
		reboot
		exit -1;
	fi
fi
#升级开始	 
sh ${PreUpgradeSh}

if [  -f $UpgradePath/kvms35n ]; then
echo "upgrade kernel"
fi

if [  -f $UpgradePath/rootfs.tar.gz ]; then
echo "upgrade rootfs"
fi

if [  -f $UpgradePath/qtfs.tar.gz ]; then
echo "upgrade qtfs"
rm -rf /mnt/mtd/qte
cd $UpgradePath
	tar -zxvf qtfs.tar.gz -C /mnt/mtd/
	sleep 5
fi	

if [  -f $UpgradePath/appfs.tar.gz ]; then
echo "upgrade appfs"
cd /mnt/mtd/ && find ./ | grep -v qte | grep -v u| xargs rm -rf	
cd $UpgradePath
	tar -zxvf appfs.tar.gz -C /mnt/mtd/
	sleep 5
fi	

sync				
reboot	
exit -1;
