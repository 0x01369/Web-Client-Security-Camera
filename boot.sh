#!/bin/sh
rm /var/* -rf
mkdir /var/run
mkdir /var/lock

#mkdir /tmp
#mount -t tmpfs tmpfs /tmp
#mkdir /run
#mount -t tmpfs tmpfs /run

export MTDBLOCK5_CONFIG_DIR=/mnt/mtd/configInfo
export CONFIG_DIR=/mnt/mtd/configInfo/Config
export FACTORY_CONFIG_DIR=/mnt/mtd/configInfo/factoryConfig
export DEFAULT_CONFIG_DIR=/mnt/mtd/default
export MTDBLOCK_LOG_DIR=/mnt/mtd/log

export LD_LIBRARY_PATH=/mnt/mtd/:$LD_LIBRARY_PATH
export QTDIR=/mnt/mtd/qte
export LD_LIBRARY_PATH=$QTDIR/directfb-lib:$LD_LIBRARY_PATH


#koæ˜¯å¦ä¸ºå‹ç¼©æ–‡ä»¶
if [ -f /mnt/mtd/modules.tar.lzma ]; then
cp /mnt/mtd/modules.tar.lzma /tmp/
cd /tmp/ && unlzma modules.tar.lzma && tar -xvf modules.tar && rm -rf modules.tar
export MODULES_PATH=/tmp/modules
else
export MODULES_PATH=/mnt/mtd/modules
fi

#å‡çº§
export UpgradeSh=/mnt/mtd/upgrade.sh
export UpdateStatus=/mnt/mtd/Update.dat
if [ -f $UpdateStatus ] ; then
	sh ${UpgradeSh}
	if [ $? -ne 0 ]; then
		echo "need reboot"
		exit -1;
	fi
fi

#æ­£å¸¸å¯åŠ¨

cd /mnt/mtd/ 
. ./mount_mtdblock.sh

echo "now start mount block"

if [ ! -d $MTDBLOCK5_CONFIG_DIR ]; then
	mkdir $MTDBLOCK5_CONFIG_DIR		
fi

if [ "x$CONFIG_MTDBLOCK" = "x" ] ; then
	echo "config umount"
else
	mount -t jffs2 $CONFIG_MTDBLOCK $MTDBLOCK5_CONFIG_DIR
fi

if [ ! -d $MTDBLOCK_LOG_DIR ]; then
	mkdir $MTDBLOCK_LOG_DIR
fi

if [ "x$LOG_MTDBLOCK" = "x" ] ; then
	echo "log umount"
else
	mount -t jffs2 $LOG_MTDBLOCK $MTDBLOCK_LOG_DIR
fi

if [ ! -d $FACTORY_CONFIG_DIR ]; then
	mkdir $FACTORY_CONFIG_DIR
fi

if [ ! -d $CONFIG_DIR ]; then
	mkdir $CONFIG_DIR
fi

#å‡ºå‚é…ç½®ä¸å…¨ï¼Œ è®¾å¤‡ä¸å¯åŠ¨
if [  -f $FACTORY_CONFIG_DIR/OR_factoryConfig.xml ]; then

	if [ ! -f $FACTORY_CONFIG_DIR/OR_systemInfo.xml ]; then
		echo "$FACTORY_CONFIG_DIR/OR_systemInfo.xml not exist"
		exit
	fi
	
	if [ ! -f $FACTORY_CONFIG_DIR/OR_runParameter.xml ]; then
		echo "file $FACTORY_CONFIG_DIR/OR_runParameter.xml not exist"
		exit
	fi
	
	#å‡çº§åç¬¬ä¸€æ¬¡å¯åŠ¨,å°†å·¥å‚é…ç½®è®¾ç½®è¿›é»˜è®¤é…ç½®
	if [ ! -f /mnt/mtd/checkConfig ]; then
		echo " ------------ setFactoryConfigToDefault --------"
		cd /mnt/mtd/ && ./setFactoryConfigToDefault
	fi

#å½“å‡ºå‚é…ç½®ä¸å­˜åœ¨æ—¶å¤„ç†OR_systemInfo.xml OR_runParameter.xml
else 
	#ä¸‹ä¸¤æ–‡ä»¶ä¸å­˜åœ¨åˆ™æ‹·è´ï¼Œå­˜åœ¨åˆ™æ¯”è¾ƒ	
	if [ ! -f $FACTORY_CONFIG_DIR/OR_systemInfo.xml ]; then
		cp $DEFAULT_CONFIG_DIR/OR_systemInfo.xml $FACTORY_CONFIG_DIR
	else
		diff $DEFAULT_CONFIG_DIR/OR_systemInfo.xml $FACTORY_CONFIG_DIR/OR_systemInfo.xml > /dev/null
		if [ $? -ne 0 ]; then
			cp $DEFAULT_CONFIG_DIR/OR_systemInfo.xml $FACTORY_CONFIG_DIR
		fi
	fi	
	
	if [ ! -f $FACTORY_CONFIG_DIR/OR_runParameter.xml ]; then
		cp $DEFAULT_CONFIG_DIR/OR_runParameter.xml $FACTORY_CONFIG_DIR
	else
		diff $DEFAULT_CONFIG_DIR/OR_runParameter.xml $FACTORY_CONFIG_DIR/OR_runParameter.xml > /dev/null
		if [ $? -ne 0 ]; then
			cp $DEFAULT_CONFIG_DIR/OR_runParameter.xml $FACTORY_CONFIG_DIR
		fi
	fi	
fi


#ç©ºæ¿ç¬¬ä¸€æ¬¡å¯åŠ¨æ—¶é…ç½®ç‰ˆæœ¬å·æ–‡ä»¶ä¸å­˜åœ¨
if [ ! -f $FACTORY_CONFIG_DIR/OR_configVersionInfo.xml ]; then
	cp $DEFAULT_CONFIG_DIR/OR_configVersionInfo.xml $FACTORY_CONFIG_DIR
fi	

#å¦‚æœéœ€è¦æ¢å¤å‡ºå‚è®¾ç½®
if [ -f /mnt/mtd/log/restoreCFG ] || [ -f /mnt/mtd/restoreCFG ] ; then
	echo "restore factory settings by boot.sh."
	cd $CONFIG_DIR/ && find ./ |grep -v OR_foreverInfo.xml | xargs rm -rf
	#rm -rf $CONFIG_DIR/*
	rm -rf /mnt/mtd/log/*
	rm -rf /etc/resolv.conf
	rm -f /mnt/mtd/restoreCFG
else
	##å¦‚æœæ•°æ®åº“æ–‡ä»¶å·²æŸåï¼Œé‚£ä¹ˆåˆ é™¤æ•°æ®åº“ï¼ˆä¸‹é¢ä¼šæ‹·è´é»˜è®¤æ•°æ®åº“æ–‡ä»¶ï¼‰
	for dbfile in configInfo/Config/SystemDb.db3 log/AbnormalLog.db3 log/SysLog.db3
	do
		if [ -f /mnt/mtd/$dbfile.malformed ] ; then
			nErrTime=`cat /mnt/mtd/$dbfile.malformed`
			echo "/mnt/mtd/$dbfile is malformed, errTimes=$nErrTime"
			if [ "$nErrTime" -ge 2 ] ; then
				mv /mnt/mtd/$dbfile /mnt/mtd/$dbfile.bak
				rm -f /mnt/mtd/$dbfile.malformed
			fi
		fi
	done	
fi

#é»˜è®¤é…ç½®ä¸configä¸‹é…ç½®å¤„ç†
filelist=`ls ${DEFAULT_CONFIG_DIR}`
for file in $filelist
do
	if [ "$file" = "OR_systemInfo.xml" ]; then
		echo "$file nothing to do "
	elif [ "$file" = "OR_runParameter.xml" ]; then
		echo "$file nothing to do "	
	elif [ "$file" = "OR_configVersionInfo.xml" ]; then
		echo "$file nothing to do "
	elif [ "$file" = "OR_clientConfig.xml" ]; then
		echo "$file nothing to do "	
	elif [ "$file" = "OR_configParameter.xml" ]; then
		diff $DEFAULT_CONFIG_DIR/OR_configParameter.xml $FACTORY_CONFIG_DIR/OR_configParameter.xml > /dev/null
		if [ $? -ne 0 ]; then
			cp $DEFAULT_CONFIG_DIR/OR_configParameter.xml $FACTORY_CONFIG_DIR
		fi
	else
		if [ ! -f $CONFIG_DIR/$file ]; then
			echo $file		
			cp -rf $DEFAULT_CONFIG_DIR/$file $CONFIG_DIR
		fi
	fi
done

diff $DEFAULT_CONFIG_DIR/OR_funcpane.xml $CONFIG_DIR/OR_funcpane.xml > /dev/null
if [ $? -ne 0 ]; then
	cp $DEFAULT_CONFIG_DIR/OR_funcpane.xml $CONFIG_DIR
fi

diff $DEFAULT_CONFIG_DIR/data.db $CONFIG_DIR/data.db > /dev/null
if [ $? -ne 0 ]; then
	cp $DEFAULT_CONFIG_DIR/data.db $CONFIG_DIR
fi

diff $DEFAULT_CONFIG_DIR/OR_supportLanguageInfo.xml $CONFIG_DIR/OR_supportLanguageInfo.xml > /dev/null
if [ $? -ne 0 ]; then
	cp $DEFAULT_CONFIG_DIR/OR_supportLanguageInfo.xml $CONFIG_DIR
fi

if [  -f $DEFAULT_CONFIG_DIR/OR_defaultHardwareSpecifications.xml ]; then
	diff $DEFAULT_CONFIG_DIR/OR_defaultHardwareSpecifications.xml $CONFIG_DIR/OR_defaultHardwareSpecifications.xml > /dev/null
	if [ $? -ne 0 ]; then
		cp $DEFAULT_CONFIG_DIR/OR_defaultHardwareSpecifications.xml $CONFIG_DIR
	fi
fi

if [ ! -f /etc/resolv.conf ]; then
	cp $DEFAULT_CONFIG_DIR/resolv.conf /etc/
fi



#å‡çº§åç¬¬ä¸€æ¬¡å¯åŠ¨
if [ ! -f /mnt/mtd/checkConfig ]; then
	cd $MODULES_PATH && ./load_before -i
	cd /mnt/mtd/ && ./ConfigAdapter 1
	cd $MODULES_PATH && ./load_before -r
	touch /mnt/mtd/checkConfig
	
	#webç«¯logoå®šåˆ¶
	if [ -f $FACTORY_CONFIG_DIR/LoginContent.png ]; then
		cp $FACTORY_CONFIG_DIR/LoginContent.png /mnt/mtd/Web/Css/Pictures/Login/LoginContent.png
	fi
	
	if [ -f $FACTORY_CONFIG_DIR/appName.png ]; then
		cp $FACTORY_CONFIG_DIR/appName.png /mnt/mtd/Web/Css/Pictures/appName.png
	fi
	
	if [ -f $FACTORY_CONFIG_DIR/favicon.ico ]; then
		cp $FACTORY_CONFIG_DIR/favicon.ico /mnt/mtd/Web/favicon.ico
	fi
	
fi
#å¯¼å…¥é…ç½®
if [ -f /mnt/mtd/IMPORT_TMP_WEB_CONFIG.data ]; then
	cd $MODULES_PATH && ./load_before -i
	cd /mnt/mtd/ && ./ConfigAdapter 2
	cd $MODULES_PATH && ./load_before -r
fi

cd $MODULES_PATH && ./load -i
sleep 1
#é˜²æ­¢koå ç”¨å†…å­˜
if [ -f /mnt/mtd/modules.tar.lzma ]; then
####æ‰“åŒ…çš„æ—¶å€™å°±è¦å¤„ç†å¥½ï¼Œä¸èƒ½å†æ¯æ¬¡å¯åŠ¨æ—¶æ‹·è´ï¼ŒFlashç»ä¸èµ·é¢‘ç¹å†™
#mkdir /mnt/mtd/modules
#cp /tmp/modules/hifb.ko /mnt/mtd/modules/hifb.ko
#sync
rm -rf /tmp/modules
fi

/mnt/mtd/dep2.sh

#å¦‚æœæœªç»è¿‡å‡ºå‚é…ç½®ï¼Œé»˜è®¤å¯åŠ¨telnetd
if [ ! -f $FACTORY_CONFIG_DIR/OR_factoryConfig.xml ]; then
	telnetd
fi
