#!/bin/sh

#本脚本用于记录hisi3535 解码帧积压的情况(/proc/umap/vdec)

#每次先存到临时文件
VDEC_LOGFILE="/tmp/vdec.log"
#每个通道一个日志文件
CHANNEL_LOG_PREFIX="/mnt/nfs/channel_"
#最多通道数
CNANNEL_MAX=32

# cat /proc/umap/vdec | grep StrmInputMode -A 32
#  ID  TYPE   Prior    MaxW    MaxH   Width  Height   StrmInputMode  Compress   STATE
#   0  H264       5    2688    1944       0       0   FRAME/NOBLOCK         N   START
#  30  H264       5     720     576     704     480   FRAME/  BLOCK         Y   START
#  31  H264       5     720     576     704     480   FRAME/  BLOCK         Y   START

# cat /proc/umap/vdec | grep FrmInVdec -A 32
#  ID  FmNewPic GetFromFm   Discard    UsrSnd    KerSnd    KerRls   MeetEnd   FrmInVdec
#   0         0         0         0         0         0         0         0           0
#  30    164728    164728         0         0    164728    164727    164728          11
#  31    140869    140869         0         0    140869    140867    140870           0

# cat /proc/umap/vdec | grep fps -A 32
#  ID  fps  TimerCnt   BufFLen   DataLen   UsrFLen    UsrLen   ptsBufF   ptsBufU StreamEnd
#   0    0    980839   7839712         0      5088         0        40         0         0
#  30   30    571968    618985         0      5088         0        40         0         0
#  31   14    571711    616924         0      5088         0        40         0         0

nowday=`date +"%F %H:%M:%S"`
cat /proc/umap/vdec > $VDEC_LOGFILE

#取每个通道分辨率
cat $VDEC_LOGFILE | grep StrmInputMode -A 32 | while read line
do
ID=`echo $line | awk '{print $1}'`
if [[ "$ID" != "ID" ]] ; then
echo "@ $nowday" >> ${CHANNEL_LOG_PREFIX}${ID}
Width=`echo $line | awk '{print $6}'`
Height=`echo $line | awk '{print $7}'`
printf "$ID  ${Width}x${Height}" >> ${CHANNEL_LOG_PREFIX}${ID}
fi
done

#取每个通道帧率
cat $VDEC_LOGFILE | grep fps -A 32 | while read line
do
ID=`echo $line | awk '{print $1}'`
if [[ "$ID" != "ID" ]] ; then
fps=`echo $line | awk '{print $2}'`
BufFLen=`echo $line | awk '{print $4}'`
printf "  $fps  $BufFLen" >> ${CHANNEL_LOG_PREFIX}${ID}
fi
done

#取每个通道帧积压
cat $VDEC_LOGFILE | grep FrmInVdec -A 32 | while read line
do
ID=`echo $line | awk '{print $1}'`
if [[ "$ID" != "ID" ]] ; then
FrmInVdec=`echo $line | awk '{print $9}'`
printf "  $FrmInVdec\\n" >> ${CHANNEL_LOG_PREFIX}${ID}
fi
done
