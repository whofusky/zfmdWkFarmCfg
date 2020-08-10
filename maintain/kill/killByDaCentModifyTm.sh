#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20190413
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#    �ж����õ��ļ�toJudgeFile[*]�����õĶ���ļ��޸�ʱ�䣬����޸�ʱ������${toWaitModifySec}����
#    �Գ���${pName}����kill,kill��������
#    ��ѯ����${pName}�Ľ��̣�����н�����kill,killʧ�ܳ�����kill -9
#       (1)�������kill�ɹ������ȴ����������,����ȴ���${maxSeconds}������û�������ű�Ҳ�˳�

#    
#revision history:
#       fushikai@20190414@add ��ȡ��������ʱ��������߼�
#       fushikai@20190417@modify �жϴ���С��ʱ������ڵ�����
#       fushikai@20190417@modify ����޳������ֱ���˳�@v0.0.0.4
#       fushikai@20190409@modify �汾���ļ����µ����ļ�@v0.0.0.5
#       
#
#############################################################################

#����汾��
versionNo="software version number: v0.0.0.5"

#����ϵͳ������������
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


#��Ҫkill�ĳ�����
pName="DataCenterForScada"

#���õ���Ҫ��������ʱ��û�б����kill����(����ʱ�䵥λΪ��)
toWaitModifySec=80
#��kill����֮ǰ�Ƿ���Ҫ�жϽ�������ʱ�����жϣ�0����Ҫ��1��Ҫ
needPidRunTimeFlag=1
#�����Ҫ�ж�pid����ʱ������������Ҫ���ж��������kill
tpidRunSeconds=60

#��Ҫ�����ļ��޸�ʱ������жϵ��ļ���(������ö���,���±����δ�0����)
toBaseDir=/zfmd/wpfs20/datappForScada/log
firstNewFile=$(find ${toBaseDir} -type f|xargs ls -lrt|tail -1|awk '{print $NF}')
toJudgeFile[0]="${firstNewFile}"

#�ȴ����������ȴ�ʱ��
maxSeconds=300


toJugeNum=${#toJudgeFile[*]}
begineStr="start running time:$(date +%Y/%m/%d-%H:%M:%S.%N)"

#�ж��ļ����޸�ʱ���Ƿ�����xxx��֮ǰ������ֵ��1Ϊ���ڣ�0Ϊ������
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


#��ȡpid��Ӧ�ĳ�������ʱ������λ�룩
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
versionFile="${baseDir}/version_${preShName}.txt"

function writeLog()
{
    timeFlag="$1"
    outMsg="$2"
    if [[ ! -z "${timeFlag}" && ${timeFlag} -eq 3 ]];then
        echo -e "\n\n*--------------------------------------------------\n*">${versionFile}
        echo -e "*\n*\t${versionNo}\n*">>${versionFile}
        echo -e "*\tshell script name: ${shName}\n*">>${versionFile}
        echo -e "*\tThe name of the program that the script will\n*\tprocess is: ${pName} \n*">>${versionFile}
        echo -e "*--------------------------------------------------\n">>${versionFile}
       return 0
    fi

    if [ ! -e ${logFile} ];then
        echo -e "\n\n*--------------------------------------------------\n*">>${logFile}
        echo -e "*\n*\t${versionNo}\n*">>${logFile}
        echo -e "*\tshell script name: ${shName}\n*">>${logFile}
        echo -e "*\tThe name of the program that the script will\n*\tprocess is: ${pName} \n*">>${logFile}
        echo -e "*--------------------------------------------------\n">>${logFile}
    fi

    if [ ${timeFlag} -eq 1 ];then
        echo -e "`date +%Y/%m/%d-%H:%M:%S.%N`:${shName}:${outMsg}">>${logFile}
    else
        echo -e "${shName}:${outMsg}">>${logFile}
    fi
    return 0
}

#�Ѿ��нű����������˳�
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

wtLogFlag=1
if [ -e "${versionFile}" ];then
    tvNum=$(sed -n "/${versionNo}/p" ${versionFile}|wc -l)
    if [ ${tvNum} -gt 0 ];then
        wtLogFlag=0
    fi
fi
[ ${wtLogFlag} -eq 1 ] && writeLog 3 "write versionNo"

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
        #kill ����
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

