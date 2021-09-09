#/bin/sh

##本脚本查找用于dump core的硬盘，并挂载到 /mnt/nfs
MNTPOINT=/mnt/nfs

cd /dev
for i in `ls sd?` ;
do
	dd if=/dev/$i of=/tmp/disk_$i.data bs=1 count=4 skip=440 >& /dev/null
	flag=`cat /tmp/disk_$i.data`
	if [ "x$flag" == "xDUMP" ] ; then
		umount $MNTPOINT >& /dev/null
		
		##要挂载的分区
		DUMP_PARTITION=/dev/${i}1
		
		printf "\33[32mfind a disk($i) for dump core!\33[0m\n"
		/sbin/fsck.vfat -a -v $DUMP_PARTITION
		mount -o errors=continue $DUMP_PARTITION $MNTPOINT
		if [ "$?" -eq "0" ] ; then
			#主动写文件到转储分区，以便验证是否只读挂载
			echo "test file" > $MNTPOINT/testfile && sync
			rm -rf $MNTPOINT/testfile
			sync && sleep 2
			#判断是不是rw挂载
			ss=`mount | grep "$DUMP_PARTITION" | grep "rw,"`
			[ -n "$ss" ] && printf "\33[32mmount $DUMP_PARTITION to $MNTPOINT OK!\33[0m\n" && exit 0
		fi
		#如果转储硬盘挂载失败，或者变为只读了，那么停止继续启动
		printf "\33[31mmount $DUMP_PARTITION to $MNTPOINT fail, or as readonly filesystem!\33[0m\n"
		printf "Press Enter to continue...\n"
		read n
	fi
	rm /tmp/disk_$i.data
done

exit 2
