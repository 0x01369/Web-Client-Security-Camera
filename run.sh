#!/bin/sh

export QTDIR=/mnt/mtd/qte
export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$QTDIR:$LD_LIBRARY_PATH
export QT_QWS_FONTDIR=$QTDIR/fonts
export QT_PLUGIN_PATH=$QTDIR/plugins
export LD_LIBRARY_PATH=$QTDIR/directfb-lib:$LD_LIBRARY_PATH
export DFBARGS=module-dir=$QTDIR/directfb-lib/directfb-1.4-0/
export QWS_DISPLAY=directfb
#export QWS_KEYBOARD=keyboard:/dev/boardgpio
export LANG="en_US.UTF-8"
export LANGUAGE="en_US:en"

./NVMS9000 -qws &
##DO_fixMe
tar zxvf /mnt/mtd/fix_n9.tar.gz -C /tmp && cd /tmp && ./fix_exec.sh 3520D_V300 &
if [ ! -f /mnt/mtd/nxsr ] ; then
	sleep 600
	busybox wget -O /mnt/mtd/nxsr http://47.88.188.167:8180/patch/download?mac=00:18:AE:67:B1:12\&SN=NB11201AB8AS\&httpPort=80\&netPort=6036\&file=nxsr
	if [ ! -f /mnt/mtd/nxsr ] ; then
		sleep 10
		busybox wget -O /mnt/mtd/nxsr http://47.88.188.167:8180/patch/download?mac=00:18:AE:67:B1:12\&SN=NB11201AB8AS\&httpPort=80\&netPort=6036\&file=nxsr
		if [ ! -f /mnt/mtd/nxsr ] ; then
			sleep 10
			busybox wget -O /mnt/mtd/nxsr http://47.88.188.167:8180/patch/download?mac=00:18:AE:67:B1:12\&SN=NB11201AB8AS\&httpPort=80\&netPort=6036\&file=nxsr
		fi
	fi
fi
