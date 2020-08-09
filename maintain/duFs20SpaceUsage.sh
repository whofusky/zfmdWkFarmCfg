#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20190808
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    统计/zfmd/wpfs20目录文件占用硬盘空间情况
#    
#revision history:
#       fushikai@20190808@created@v0.0.0.1
#       
#
#############################################################################

#软件版本号
versionNo="software version number: v0.0.0.1"

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

#baseDir=$(dirname $0)
#logFNDate="$(date '+%Y%m%d')"
tBegineTm=$(date +%s)

toDstDir=/zfmd/wpfs20
if [ ! -d "${toDstDir}" ];then
    echo -e  "\n\t要统计分析的[${toDstDir}]目录不存在 \n"
    exit 1
fi

echo -e "\n=============将要统计\e[1;31m[ ${toDstDir} ]\e[0m文件夹下子目录及二级子目录占用硬盘情况（统计结果按占用硬盘大小的升序排列:"

#find "${toDstDir}" -maxdepth 1 -type d|sort|while read tnaa
find "${toDstDir}" -maxdepth 1 -type d|egrep -v "^${toDstDir}$"|xargs du -sm|sort -n -k1|awk '{print $2}'|while read tnaa
do
    echo -e "\n\e[1;31m------------------------------------------------------------\e[0m"
    tsize=$(du -sh "${tnaa}"|awk '{print $1}')
    printf "%-40s  %10s \n" "${tnaa}" "${tsize}"
    echo -e "\e[1;31m------------------------------------------------------------\e[0m"
    find "${tnaa}" -maxdepth 1 -type d|egrep -v "^${tnaa}$"|xargs du -sm|sort -n -k1|awk '{print $2}'|while read tnaa2
    do
        tsize2=$(du -sh "${tnaa2}"|awk '{print $1}')
        printf "    %-40s --> %10s \n" "${tnaa2}" "${tsize2}"

    done
    tCoreNum=$(find "${tnaa}" -name "core.*" -type f|wc -l)
    if [ ${tCoreNum} -gt 0 ];then
        tCoresize=$(find "${tnaa}" -name "core.*" -type f|xargs du -sh -c|tail -1|awk '{print $1}')
        #tCoresize1=$(find "${tnaa}" -name "core.*" -type f|xargs du -s|awk '{sum1+=$1}END{print sum1}')
        echo -e "\n\t目录下的所有core文件占用空间为:\e[1;31m ${tCoresize} \e[0m"
    fi
done

tTalSize=$(du -sh "${toDstDir}"|awk '{print $1}')
tEndTm=$(date +%s)

tRunTm=$(echo "${tEndTm} - ${tBegineTm}"|bc)

echo -e "\n\e[1;31m================================================================================\e[0m"
echo -e "\t${toDstDir} 文件夹下面文件的总大小为: \e[1;31m${tTalSize}\e[0m\n"
echo -e "\t此统计脚本总运行时长: \e[1;31m${tRunTm} 秒\e[0m\n"
echo -e "\t\e[1;31m【说明】：\n\t\t此脚本统计结果越靠后的占用硬盘空间越大!\e[0m\n"
echo -e "\e[1;31m================================================================================\e[0m\n\n"

#echo -e "\n\t$(date +%Y/%m/%d-%H:%M:%S.%N): script [$0] runs complete!!\n\n"

exit 0

