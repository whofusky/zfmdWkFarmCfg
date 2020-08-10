#!/bin/sh

#20190516
#zhuanghe backrun  MeteoServer 


debugFlag=0

baseDir=$(dirname $0)
initDir="${PWD}"
tHostName="${HOSTNAME}"
echo "baseDir=[${baseDir}],initDir=[${initDir}],tHostName=[${tHostName}]"

#tHostName="WorkStation"
#hostname: MeteoServer   PredictServer1 PredictServer2 ScadaServer WorkStation

# 
function ECHO_DO()
{
    cmd="$*"
    echo "[$USER@$HOSTNAME $PWD] $cmd"
    if [[ -z "${debugFlag}" || ${debugFlag} -ne 1 ]];then
        $cmd
    fi
    return 0
}

tYMD=$(date +%Y%m%d)
ttDirP=/zfmd
ttDir=/zfmd/wpfs20

if [ "${tHostName}" == "MeteoServer" ];then

    msyskeeper=MeteoServer/syskeeper2000
    mmete=MeteoServer/mete
    mstart=MeteoServer/startup
    if [ ! -d "${msyskeeper}" ];then
        ECHO_DO "mkdir -p ${msyskeeper}"
    fi

    ECHO_DO "cp -r ${ttDirP}/syskeeper2000/*onfig*  ${msyskeeper}" 

    if [ ! -d "${mmete}" ];then
        ECHO_DO "mkdir -p ${mmete}" 
    fi

    ECHO_DO "cp -r ${ttDir}/mete/sh ${mmete}"
    ECHO_DO "cp -r ${ttDir}/mete/cfg ${mmete}"
    ECHO_DO "cp -r ${ttDir}/mete/bin ${mmete}"
    ECHO_DO "cp -r ${ttDir}/startup MeteoServer"
   
    ECHO_DO "tar -zcvf ${tHostName}${tYMD}.tar.gz MeteoServer"

    ECHO_DO "rm -rf MeteoServer "


elif  [ "${tHostName}" == "PredictServer1" ];then
    tsyskeeper=${tHostName}/syskeeper2000
    if [ ! -d "${tsyskeeper}" ];then
        ECHO_DO "mkdir -p ${tsyskeeper}"
    fi
    ECHO_DO "cp -r ${ttDirP}/syskeeper2000/*onfig*  ${tsyskeeper}" 


    if [ ! -d "${tHostName}" ];then
        ECHO_DO "mkdir -p ${tHostName}"
    fi
    ECHO_DO "cp -r ${ttDir}/startup ${tHostName}"
    ECHO_DO "tar -zcvf ${tHostName}${tYMD}.tar.gz ${tHostName}"
    ECHO_DO "rm -rf ${tHostName} "

    echo ""

elif  [ "${tHostName}" == "PredictServer2" ];then
    tsyskeeper=${tHostName}/syskeeper2000
    if [ ! -d "${tsyskeeper}" ];then
        ECHO_DO "mkdir -p ${tsyskeeper}"
    fi
    ECHO_DO "cp -r ${ttDirP}/syskeeper2000/*onfig*  ${tsyskeeper}" 

    if [ ! -d "${tHostName}" ];then
        ECHO_DO "mkdir -p ${tHostName}"
    fi
    ECHO_DO "cp -r ${ttDir}/startup ${tHostName}"
    ECHO_DO "tar -zcvf ${tHostName}${tYMD}.tar.gz ${tHostName}"
    ECHO_DO "rm -rf ${tHostName} "

    echo ""

elif  [ "${tHostName}" == "ScadaServer" ];then
    tscadadir=${tHostName}/scada
    if [ ! -d "${tscadadir}" ];then
        ECHO_DO "mkdir -p ${tscadadir}"
    fi
    if [ ! -d "${tHostName}" ];then
        ECHO_DO "mkdir -p ${tHostName}"
    fi
    ECHO_DO "cp -r ${ttDir}/scada/CommSubsystem ${tscadadir}"
    ECHO_DO "cp -r ${ttDir}/scada/unit*.xml ${tscadadir}"
    ECHO_DO "cp -r ${ttDir}/scada/trylog/version.txt ${tscadadir}"


    ECHO_DO "cp -r ${ttDir}/startup ${tHostName}"
    ECHO_DO "tar -zcvf ${tHostName}${tYMD}.tar.gz ${tHostName}"
    ECHO_DO "rm -rf ${tHostName} "

    echo ""

elif  [ "${tHostName}" == "WorkStation" ];then
    if [ ! -d "${tHostName}" ];then
        ECHO_DO "mkdir -p ${tHostName}"
    fi
    ECHO_DO "cp -r ${ttDir}/startup ${tHostName}"
    ECHO_DO "tar -zcvf ${tHostName}${tYMD}.tar.gz ${tHostName}"
    ECHO_DO "rm -rf ${tHostName} "

    echo ""
else
    echo -e "\n\tError: hostname [ ${tHostName} ] is not recognized!!\n"

fi

echo -e "\n\t${tHostName}:script [$0] execution completed !!\n"


exit 0
