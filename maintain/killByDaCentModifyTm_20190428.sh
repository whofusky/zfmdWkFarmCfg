#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20190413
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    判断配置的文件toJudgeFile[*]中配置的多个文件修改时间，如果修改时间早于${toWaitModifySec}秒则
#    对程序${pName}进行kill,kill规则如下
#    查询程序${pName}的进程，如果有进程则kill,kill失败尝试用kill -9
#       (1)如果进程kill成功，则会等待程序的启动,如果等待了${maxSeconds}秒后程序没有启来脚本也退出

#    
#revision history:
#       fushikai@20190414@add 获取进程运行时长的相关逻辑
#       fushikai@20190417@modify 判断大于小于时加入等于的条件
#       fushikai@20190417@modify 添加无程序进程直接退出@v0.0.0.4
#       
#
#############################################################################

#软件版本号
versionNo="software version number: v0.0.0.4"

#加载系统环境变量配置
if [ -f /etc/profile ]; then
    . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
    . ~/.bash_profile >/dev/null 2>&1
fi

baseDir=$(dirname $0)
logFNDate="$(date '+%Y%m%d')"
logDir="${baseDir}/log"
if [ ! -d "${logDir}" ];then
    mkdir -p "${logDir}"
fi


#需要kill的程序名
pName="DataCenterForScada"

#配置的需要超过多少时间没有变更则kill程序(配置时间单位为秒)
toWaitModifySec=80
#在kill进程之前是否需要判断进程运行时长的判断：0不需要，1需要
needPidRunTimeFlag=1
#如果需要判断pid运行时长，则至少需要运行多少秒才能kill
tpidRunSeconds=60

#需要根据文件修改时间进行判断的文件名(多个配置多行,且下标依次从0递增)
toBaseDir=/zfmd/wpfs20/datappForScada/log
firstNewFile=$(find ${toBaseDir} -type f|xargs ls -lrt|tail -1|awk '{print $NF}')
toJudgeFile[0]="${firstNewFile}"

#等待启动的最大等待时间
maxSeconds=300


toJugeNum=${#toJudgeFile[*]}
begineStr="start running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"

#判断文件的修改时间是否早于xxx秒之前，返回值：1为早于，0为不早于
function getIsModBeger()
{
    if [ $# -ne 2 ];then
        echo "  Error: function getFnameOnPath input parameters not eq 2!"
        return 1
    fi

    tmpFile=$1
    maxCfgSecs=$2

    if [ ! -e ${tmpFile} ];then
        echo " Error: function getIsModBeger:file[${tmpFile}] does not exist!"
        return 2
    fi
    tSecNum=$(echo "($(date +%s)-$(stat -c %Y ${tmpFile}))"|bc)
    tIsBig=$(echo "${tSecNum}>=${maxCfgSecs}"|bc)

    echo "${tIsBig}"
    return 0

}


#获取pid对应的程序运行时长（单位秒）
function getPidElapsedSec()
{
    if [ $# -ne 1 ];then
        echo "Error:The number of input parameters of function getPidElapsedSec if not equal 1"
        return 1
    fi

    tInPid=$1

    tEtime=$(ps -p ${tInPid} -o etime|tail -1|awk '{print $NF}')
    if [ "${tEtime}" == "ELAPSED" ];then
        echo "Error:pid=[${tInPid}] does not exist!"
        return 9
    fi

    #echo "---tEtime=[${tEtime}]----"
    tColonNum=$(echo "${tEtime}"|awk -F':' '{print NF}')

    #echo "----tColonNum=[${tColonNum}]----"
    if [ ${tColonNum} -eq 2 ];then

        tMinute=$(echo "${tEtime}"|awk -F':' '{print $1}')
        tSecond=$(echo "${tEtime}"|awk -F':' '{print $2}')
        tSumSec=$(echo "(${tMinute} * 60 ) + ${tSecond}"|bc)

        #echo "---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----tSumSec=[${tSumSec}]---tSumSec2=[${tSumSec2}]-----"

    elif [ ${tColonNum} -eq 3 ];then
        tMinute=$(echo "${tEtime}"|awk -F':' '{print $2}')
        tSecond=$(echo "${tEtime}"|awk -F':' '{print $3}')
        tDHorH=$(echo "${tEtime}"|awk -F':' '{print $1}')
        tBarNum=$(echo "${tDHorH}"|awk -F'-' '{print NF}')
        tDay=0
        tHour=0
        if [ ${tBarNum} -eq 1 ];then
            tDay=0
            tHour=${tDHorH}
        elif [ ${tBarNum} -eq 2 ];then
            tDay=$(echo "${tDHorH}"|awk -F'-' '{print $1}')
            tHour=$(echo "${tDHorH}"|awk -F'-' '{print $2}')
        else
            echo "Error1:[${tEtime}] format Error"
            return 2
        fi
        tSumSec=$(echo "(${tDay} * 86400) + (${tHour} * 3600) + (${tMinute} * 60 ) + ${tSecond}"|bc)

        #echo "--tDay=[${tDay}],tHour=[${tHour}]---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----tSumSec=[${tSumSec}]---tSumSec2=[${tSumSec2}]-----"

    else
        echo "Error2:[${tEtime}] format Error"
        return 3
        
    fi

    echo "${tSumSec}"
    return 0

}


function getFnameOnPath() #get the file name in the path string
{
    if [ $# -ne 1 ];then
        echo "  Error: function getFnameOnPath input parameters not eq 1!"
        return 1
    fi

    allName="$1"
    if [ -z "${allName}" ];then
        echo "  Error: function getFnameOnPath input parameters is null!"
        return 2;
    fi

    slashNum=$(echo ${allName}|grep "/"|wc -l)
    if [ ${slashNum} -eq 0 ];then
        echo ${allName}
        return 0
    fi

    fName=$(echo ${allName}|awk -F'/' '{print $NF}')
    echo ${fName}

    return 0
}

shName=$(getFnameOnPath $0)
preShName="${shName%.*}"
logFile="${logDir}/${preShName}${logFNDate}.log"

function writeLog()
{
    timeFlag="$1"
    outMsg="$2"
    if [ ! -e ${logFile} ];then
        echo -e "\n\n*--------------------------------------------------\n*">>${logFile}
        echo -e "*\n*\t${versionNo}\n*">>${logFile}
        echo -e "*\tshell script name: ${shName}\n*">>${logFile}
        echo -e "*\tThe name of the program that the script will\n*\tprocess is: ${pName} \n*">>${logFile}
        echo -e "*--------------------------------------------------\n">>${logFile}
    fi
    if [[ ! -z "${timeFlag}" && ${timeFlag} -eq 3 ]];then
       return 0
    fi

    if [ ${timeFlag} -eq 1 ];then
        echo -e "`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}">>${logFile}
    else
        echo -e "${shName}:${outMsg}">>${logFile}
    fi
    return 0
}

#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    writeLog 0 "+++${tmpShPid}+++++${tmpShPNum}+++"
    writeLog 1 "script [$0] has been running,this run directly exits!"
    exit 0
fi

function killProgram()
{
    tPid=$(pidof ${pName})
    if [ "" = "$tPid" ];then
        writeLog 1 "Program [${pName}] is not running\n"
        return 0
    fi

    kill ${tPid}
    ret=$?
    writeLog 1 "kill ${tPid} return[${ret}]\n"
    if [ ${ret} -ne 0 ];then
        kill -9 ${tPid}
        ret=$?
        if [ ${ret} -ne 0 ];then
            writeLog 1 "kill -9 ${tPid} return[${ret}]\n"
        fi
    fi

    tNewPid=$(pidof ${pName})
    waitSeconds=0
    tmpwait=30
    while [[ ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof ${pName})
        let waitSeconds++
        if [ ${waitSeconds} -gt ${tmpwait} ];then
            break
        fi
    done

    writeLog 1 "waiting for program [${pName}] to exit, waitSeconds=[${waitSeconds}] \n"

    if [ ${waitSeconds} -gt ${tmpwait} ];then
            kill -9 ${tPid}
            writeLog 1 "kill ${tPid} not success and use kill -9 ${tPid} \n"
    fi


    tNewPid=$(pidof ${pName})
    waitSeconds=0
    while [[ -z "${tNewPid}" || ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof ${pName})
        let waitSeconds++
        #writeLog 1 "oldPid=[${tPid}],newPid=[${tNewPid}],waitSeconds=[${waitSeconds}]\n"
        if [ ${waitSeconds} -gt ${maxSeconds} ];then
            break
        fi

    done

    writeLog 1 "waiting for program [${pName}] to start, waitSeconds=[${waitSeconds}]\n"

    if [ ${waitSeconds} -gt ${maxSeconds} ];then
        if [[ ! -z ${tNewPid} && ${tNewPid} -eq ${tPid} ]];then
            kill -9 ${tPid}
            writeLog 1 "kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n"
        else
            writeLog 1 "kill ${tPid} success and  restart ${pName} not success!\n"
        fi
    else
        writeLog 1 "kill ${pName} success and  restart ${pName} success,oldPid=[${tPid}],newPid=[${tNewPid}]\n"
    fi

    return 0
}

writeLog 3 "write versionNo"

isOverFlag=1

tPid=$(pidof ${pName}) 
[ -z "${tPid}" ] && exit 9

if [[ ${needPidRunTimeFlag} -eq 1 && ${tpidRunSeconds} -gt 0 ]];then
    tPid=$(pidof ${pName}) 
    [ -z "${tPid}" ] && exit 9
    retMsg=$(getPidElapsedSec ${tPid})
    ret=$?
    if [ ${ret} -eq 0 ];then
        isOverFlag=$(echo "${tpidRunSeconds}<=${retMsg}"|bc)
        tEtimeStr="--tpidRunSeconds=[${tpidRunSeconds}],pidof ${pName}=[${tPid}],elapsed time[${retMsg}] seconds"
    else
        writeLog 1 "${retMsg}"
    fi
fi

for ((i=0;i<${toJugeNum};i++))
do
    tDoFile=${toJudgeFile[${i}]}
    if [ ! -e ${tDoFile} ];then
        continue
    fi
    retMsg=$(getIsModBeger ${tDoFile} ${toWaitModifySec})
    ret=$? 
    if [ ${ret} -ne 0 ];then
        writeLog 1 "getIsModBeger return error:[${retMsg}]\n"
        continue
    fi
    if [[ ${retMsg} -eq 1 && ${isOverFlag} -eq 1 ]];then
        #kill 程序
        killProgram
        killFlag=1
        break
    fi

done

if [[ ! -z "${killFlag}" && ${killFlag} -eq 1 ]];then
    endStr="End running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"
    if [ ! -z "${tEtimeStr}" ];then
        writeLog 1 "${tEtimeStr}"
    fi
    writeLog 0 "${begineStr}"
    writeLog 0 "${endStr}"
    writeLog 1 "\tscript [ $0 ] runs complete!!\n\n"
fi

exit 0

