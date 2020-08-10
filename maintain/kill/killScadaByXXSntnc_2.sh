#!/bin/sh

#############################################################################
#author       :    fushikai
#date         :    20190806
#linux_version:    Red Hat Enterprise Linux Server release 6.7
#dsc          :
#   本脚本实现功能为:查找某个日志文件中是否出现固定的字符语句,如果出现则查看
#       此语句首是否有19/08/06 13:35:40:164.788:CST]字样的时间戳,如果有则把
#       此时间戳与产生日志的进程启动时间比较,如果是在启动进程之后产生的则kill
#       相应的进程
#    
#    
#revision history:
#       fushikai@2019-08-06@created@v0.0.0.1       
#       fushikai@2019-08-07@modify notfount str out error debug@v0.0.0.2       
#
#############################################################################

#软件版本号
versionNo="software version number: v0.0.0.2"

#加载系统环境变量配置
if [ -f /etc/profile ]; then
        . /etc/profile >/dev/null 2>&1
fi
if [ -f ~/.bash_profile ];then
        . ~/.bash_profile >/dev/null 2>&1
fi


#已经有脚本在运行则退出
tmpShPid=$(pidof -x $0)
tmpShPNum=$(echo ${tmpShPid}|awk 'BEGIN {tNum=0;} { if(NF>0){tNum=NF;}} END{print tNum}')
if [ ${tmpShPNum} -gt 1 ]; then
    exit 0
fi


baseDir=$(dirname $0)
logFNDate="$(date '+%Y%m%d')"
logDir="${baseDir}/log"
if [ ! -d "${logDir}" ];then
        mkdir -p "${logDir}"
fi

#DSC:找到某个字符串在某个文件中是否出现，如果出现则把出现字符串前的
#    19/08/04 15:23:59:161.617:CST]时间解析与1970-01-01的秒数返回
function fndTmStmpByStrInFl()
{
    if [ $# -ne 3 ];then
        echo "Error:function fndTmStmpByStrInFl parameters not eq 3"
        return 1
    fi
    local tdoFile="$1"
    local tMaxLinNum="$2"
    local tSearchTxt="$3"

    if [ ! -e "${tdoFile}" ];then

        echo "tdoFile not exits!"
        return 2
    fi

    local tFindTxt=$(tail -"${tMaxLinNum}" "${tdoFile}"|sed -n "/${tSearchTxt}/p" |tail -1)

    if [ -z "${tFindTxt}" ];then
        echo "tFindTxt is null"
        return 2
    fi

    local tFixTime=$(echo "${tFindTxt}"|awk -F']' '{if(NF>=2){print $1}}'|awk -F'[/:]' '{print $1"-"$2"-"$3":"$4":"$5}')
    if [ -z "${tFixTime}" ];then
        echo "tFixTime is null"
        return 3
    fi

    local tFixTmstamp=$(date -d "${tFixTime}" +%s)
    echo "${tFixTmstamp}"

    return 0
}



#获取pid对应的程序运行时长（单位秒）
function getPidElapsedSec()
{
    if [ $# -ne 1 ];then
        echo "Error:The number of input parameters of function getPidElapsedSec if not equal 1"
        return 1
    fi

    local tInPid=$1

    local tEtime=$(ps -p ${tInPid} -o etime|tail -1|awk '{print $NF}')
    if [ "${tEtime}" == "ELAPSED" ];then
        echo "Error:pid=[${tInPid}] does not exist!"
        return 9
    fi

    #echo "---tEtime=[${tEtime}]----"
    local tColonNum=$(echo "${tEtime}"|awk -F':' '{print NF}')

    #echo "----tColonNum=[${tColonNum}]----"
    if [ ${tColonNum} -eq 2 ];then

        local tMinute=$(echo "${tEtime}"|awk -F':' '{print $1}')
        local tSecond=$(echo "${tEtime}"|awk -F':' '{print $2}')
        local tSumSec=$(echo "(${tMinute} * 60 ) + ${tSecond}"|bc)

        #echo "---tMinute=[${tMinute}],tSecond=[${tSecond}]---"
        #echo "----tSumSec=[${tSumSec}]---tSumSec2=[${tSumSec2}]-----"

    elif [ ${tColonNum} -eq 3 ];then
        local tMinute=$(echo "${tEtime}"|awk -F':' '{print $2}')
        local tSecond=$(echo "${tEtime}"|awk -F':' '{print $3}')
        local tDHorH=$(echo "${tEtime}"|awk -F':' '{print $1}')
        local tBarNum=$(echo "${tDHorH}"|awk -F'-' '{print NF}')
        local tDay=0
        local tHour=0
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

    local allName="$1"
    if [ -z "${allName}" ];then
        echo "  Error: function getFnameOnPath input parameters is null!"
        return 2;
    fi

    local slashNum=$(echo ${allName}|grep "/"|wc -l)
    if [ ${slashNum} -eq 0 ];then
        echo ${allName}
        return 0
    fi

    local fName=$(echo ${allName}|awk -F'/' '{print $NF}')
    echo ${fName}

    return 0
}

function writeLog()
{
    local timeFlag="$1"
    local shName="$2"
    local versionNo="$3"
    local pName="$4"

    if [[ ! -z "${timeFlag}" && ${timeFlag} -eq 3 ]];then

        local versionFile="$5"

        echo -e "\n\n*--------------------------------------------------\n*">${versionFile}
        echo -e "*\n*\t${versionNo}\n*">>${versionFile}
        echo -e "*\tshell script name: ${shName}\n*">>${versionFile}
        echo -e "*\tThe name of the program that the script will\n*\tprocess is: ${pName} \n*">>${versionFile}
        echo -e "*--------------------------------------------------\n">>${versionFile}
       return 0
    fi

    local logFile="$5"
    local outMsg="$6"

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


function killProgram()
{
    local logFile="$1"
    local shName="$2"
    local versionNo="$3"
    local pName="$4"
    local maxSeconds="$5"
    local waitFlag="$6"

    local tPid=$(pidof -x ${pName})
    if [ "" = "$tPid" ];then
        writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}" "Program [${pName}] is not running\n"
        return 0
    fi

    kill ${tPid}
    local ret=$?
    writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} return[${ret}]\n"
    if [ ${ret} -ne 0 ];then
        kill -9 ${tPid}
        ret=$?
        if [ ${ret} -ne 0 ];then
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill -9 ${tPid} return[${ret}]\n"
        fi
    fi

    local tNewPid=$(pidof -x ${pName})
    local waitSeconds=0
    local tmpwait=30

    while [[ ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        if [ ${waitSeconds} -gt ${tmpwait} ];then
            break
        fi
    done

    writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "waiting for program [${pName}] to exit, waitSeconds=[${waitSeconds}] \n"

    if [ ${waitSeconds} -gt ${tmpwait} ];then
            kill -9 ${tPid}
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} not success and use kill -9 ${tPid} \n"
    fi
 
    #不需要等待进程重启
    if [[ ${waitFlag} -eq 0 ]];then

        tNewPid=$(pidof -x ${pName}) 
        if [[  ! -z "${tNewPid}" && ${tNewPid} -eq ${tPid} ]];then
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} not success!\n"
            return 0
        else  
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} success!\n"
            return 2
        fi 
    fi

    tNewPid=$(pidof -x ${pName})
    waitSeconds=0
    while [[ -z "${tNewPid}" || ${tNewPid} -eq ${tPid} ]]
    do
        sleep 1
        tNewPid=$(pidof -x ${pName})
        let waitSeconds++
        #writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "oldPid=[${tPid}],newPid=[${tNewPid}],waitSeconds=[${waitSeconds}]\n"
        if [ ${waitSeconds} -gt ${maxSeconds} ];then
            break
        fi

    done

    writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "waiting for program [${pName}] to start, waitSeconds=[${waitSeconds}]\n"

    if [ ${waitSeconds} -gt ${maxSeconds} ];then
        if [[ ! -z ${tNewPid} && ${tNewPid} -eq ${tPid} ]];then
            kill -9 ${tPid}
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} not success and use kill -9 ${tPid}  ---22222 \n"
        else
            writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${tPid} success and  restart ${pName} not success!\n"
        fi
    else
        writeLog 1 "${shName}" "${versionNo}" "${pName}" "${logFile}"  "kill ${pName} success and  restart ${pName} success,oldPid=[${tPid}],newPid=[${tNewPid}]\n"
    fi

    return 0
}

function myjudgeKill()
{
    if [ $# -ne 4 ];then
        echo "Error:fuction myjudgeKill input parameters not eq 4"
        return 1
    fi
        
    local tdoFile="$1"
    local tMaxLinNum="$2"
    local tSearchTxt="$3"
    local pName="$4"

    local tPid=$(pidof -x ${pName}) 

    #killFlag 1:代表需要kill,0:代表不需要kill
    local killFlag=0

    local retMsg
    local retStat

    [ -z "${tPid}" ] && echo ${killFlag} && return 0

    #获取特定字样出现的时间
    #fndTmStmpByStrInFl "${tdoFile}" "${tMaxLinNum}" "${tSearchTxt}"
    retMsg=$(fndTmStmpByStrInFl "${tdoFile}" "${tMaxLinNum}" "${tSearchTxt}")
    retStat=$?
    #echo "--------retStat=[${retStat}]"
    if [ ${retStat} -eq 1 ];then
        echo ${retMsg}
        return ${retStat}
    elif [[ ${retStat} -eq 2 || ${retStat} -eq 3 ]];then
        echo "${killFlag}"
        return 0
    fi


    local ftmstmp=${retMsg}

    #获取pid对应的程序运行时长（单位秒）
    retMsg=$(getPidElapsedSec ${tPid})
    retStat=$?
    [ ${retStat} -ne 0 ] && echo ${retMsg} && return ${retStat}
    local prunSnds=${retMsg}

    local curTmStmp=$(date +%s)

    #killFlag 1:代表需要kill,0:代表不需要kill
    killFlag=$(echo "${curTmStmp} - ${prunSnds} < ${ftmstmp}"|bc)

    echo ${killFlag}
    return 0
}


shName=$(getFnameOnPath $0)
preShName="${shName%.*}"
logFile="${logDir}/${preShName}${logFNDate}.log"
versionFile="${baseDir}/version_${preShName}.txt"
#pName="ftmptest.sh"
pName="CommSubsystem_2"

#waitFlag是否等待杀死的进程重启,0:不等等,1:等待
waitFlag=1
#如果等待杀死的进程重启最多等待的时间（单位秒)
maxSeconds=300


#tdoFile="${baseDir}/scada.txt"
tdoFile="/zfmd/wpfs20/scada2/trylog/scada.txt"
tMaxLinNum=100000

#tSearchTxt="popQ() CAN'T pop data from Queue, ErrorCode"
tSearchTxt="popQ() CAN'T pop data from Queue, ErrorCode"

#echo "versionFile=[${versionFile}]"

wtLogFlag=1                                                
if [ -e "${versionFile}" ];then                            
    tvNum=$(sed -n "/${versionNo}/p" ${versionFile}|wc -l) 
    if [ ${tvNum} -gt 0 ];then                             
        wtLogFlag=0                                        
    fi                                                     
fi                                                         
[ ${wtLogFlag} -eq 1 ] && writeLog 3 "${shName}" "${versionNo}" "${pName}" "${versionFile}" "write versionNo"     

tPid=$(pidof -x ${pName})                                                                                                                                     
[ -z "${tPid}" ] && exit 9 

#myjudgeKill "${tdoFile}" "${tMaxLinNum}" "${tSearchTxt}" "${pName}"
#exit 0
retMsg=$(myjudgeKill "${tdoFile}" "${tMaxLinNum}" "${tSearchTxt}" "${pName}")
retStat=$?
if [ ${retStat} -eq 0 ];then
    #echo "---retMsg=[${retMsg}]--"
    if [[ ! -z "${retMsg}" && ${retMsg} -eq 1 ]];then
        retMsg=$(killProgram "${logFile}" "${shName}" "${versionNo}" "${pName}" "${maxSeconds}" "${waitFlag}")
        retStat=$?
    fi
fi


exit 0


