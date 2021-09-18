#!/bin/bash
#
############################################################
#
#author :  fu.sky
#date   :  2021-09-18_11:24
#dsc    :
#           1.将scada配置文件中原来的“可用功率”改为“理论功率”
#           2.将scada配置文件中原来的“可用功率*0.956”改为“可用功率”
#
############################################################
#

shName="$0" ; srcInFName="$1" ; inParNum="$#"

tPid=$$
srEdFName="scdCfg_utf8_${tPid}.xml"
#srEdFName=scdCfg_1.xml

tBackFile="${srcInFName}.back.$(date +%Y%m%d)_$$"

resultFile="scdCfg_$(date +%Y%m%d)rst.xml"

tGbkFlag=0

#---------------------------------------- modify 1 “可用功率”改为“理论功率”

querydidval1="FF41FF39020800801030AD000000000000" #1分钟整场可用功率平均值TPS
queryerialNo1="2137"

todidval1="FF41FF390208008010309A000000000000" #1分钟整场理论功率平均值TPS
toserialNo1="2135"  #1分钟整场理论功率平均值TPS
todidName1="1分钟整场理论功率平均值TPS"  #1分钟整场理论功率平均值TPS




#---------------------------------------- modify 2 “可用功率*0.956”改为“可用功率”

querydidval2="FF41FF39020800801030AD000000000000" #1分钟整场可用功率0.956平均值TPS
queryerialNo2="2136"

todidval2="FF41FF39020800801030AD000000000000" #1分钟整场可用功率平均值TPS
toserialNo2="2137"  #1分钟整场可用功率平均值TPS
todidName2="1分钟整场可用功率平均值TPS"  #1分钟整场可用功率平均值TPS
#----------------------------------------




function F_check()
{
    if [ ${inParNum} -lt 1 ];then
        echo -e "\n\t\e[1;31mERROR:\e[0m please input like: ${shName} <scada_cfg_file>\n"
        exit 1
    fi
    if [ ! -e "${srcInFName}" ];then
        echo -e "\n\tERROR: file [ ${srcInFName} ] not exist!\n"
        exit 1
    fi

    needEdFlag=$(sed -n "/^\s*<\s*channels\b/,/^\s*<\s*\/\s*channels\s*>/ {/serialNo\s*=\s*\"2136\"/p}" "${srcInFName}" 2>/dev/null|wc -l)
    if [ ${needEdFlag} -lt 1 ];then
        echo -e "\n\t\e[1;31m 文件[${srcInFName}]不需要修改或已经修改过了!\e[0m\n"
        exit 0
    fi

    tChrSet=$(file --mime-encoding "${srcInFName}"|awk '{print $2}')
    echo -e "\n\t file;[${srcInFName}] encoding is : ${tChrSet}"
    tChrSet="${tChrSet%%-*}"
    if [[ "x${tChrSet}" == "xiso" ]];then
        tGbkFlag=1;
    fi

    baseDir="$(dirname ${srcInFName})"

    srEdFName="${baseDir}/${srEdFName}"
    #if [ ! -e "${srEdFName}" ];then
    #    echo -e "\n\tERROR: file [ ${srEdFName} ] not exist!\n"
    #    exit 1
    #fi

    #tChrSet=$(file --mime-encoding "${srEdFName}"|awk '{print $2}')
    #tChrSet="${tChrSet%%-*}"
    #if [[ "x${tChrSet}" != "xutf" ]];then
    #    echo -e "\n\tERROR:file [ ${srEdFName} ] not utf-8 encoding\n"
    #    exit 2
    #fi

    [ -e "${srEdFName}" ] && rm -rf "${srEdFName}"
    if [[ ${tGbkFlag} -eq 1 ]];then
        echo -e "\n\ticonv -f gbk -t utf-8  \"${srcInFName}\" -o \"${srEdFName}\""
        iconv -f gbk -t utf-8  "${srcInFName}" -o "${srEdFName}"
    else
        echo -e "\n\tcp -a \"${srcInFName}\" \"${srEdFName}\""
        cp -a "${srcInFName}" "${srEdFName}"
    fi

    resultFile="${baseDir}/${resultFile}"

    return 0
}

function F_edit()
{
    #sed -n '/^\s*<\s*channels\b/,/^\s*<\s*\/\s*channels\s*>/ {/FF41FF39020800801030AD000000000000/{/2136/p}}' "${srEdFName}"

    echo -e "\n\t modify phytype cfg serialNo=${queryerialNo1} :"
    echo -e "\t\t serialNo: ${queryerialNo1} --> ${toserialNo1}"
    echo -e "\t\t didVal  : ${querydidval1} --> ${todidval1}"
    echo -e "\t\t didName : ${todidName1}"

    sed -i "/^\s*<\s*channels\b/,/^\s*<\s*\/\s*channels\s*>/ {/serialNo\s*=\s*\"${queryerialNo1}\"/{s/serialNo\s*=\s*\"${queryerialNo1}\"/serialNo=\"${toserialNo1}\"/g;s/didVal\s*=\s*\"${querydidval1}\"/didVal=\"${todidval1}\"/g;s/didName\s*=\s*\"[^\"]*\"/didName=\"${todidName1}\"/g}}" "${srEdFName}"

    echo -e "\n\t modify phytype cfg serialNo=${queryerialNo2} :"
    echo -e "\t\t serialNo: ${queryerialNo2} --> ${toserialNo2}"
    echo -e "\t\t didVal  : ${querydidval2} --> ${todidval2}"
    echo -e "\t\t didName : ${todidName2}"

    sed -i "/^\s*<\s*channels\b/,/^\s*<\s*\/\s*channels\s*>/ {/serialNo\s*=\s*\"${queryerialNo2}\"/{s/serialNo\s*=\s*\"${queryerialNo2}\"/serialNo=\"${toserialNo2}\"/g;s/didVal\s*=\s*\"${querydidval2}\"/didVal=\"${todidval2}\"/g;s/didName\s*=\s*\"[^\"]*\"/didName=\"${todidName2}\"/g}}" "${srEdFName}"

    echo -e "\n\t modify phytype cfg scalFactor=0.956 to scalFactor=1\n"
    sed -i "/^\s*<\s*channels\b/,/^\s*<\s*\/\s*channels\s*>/ {s/scalFactor\s*=\s*\"0.956\"/scalFactor=\"1\"/g}" "${srEdFName}"

    [ -e "${resultFile}" ] && rm -rf "${resultFile}"
    if [ ${tGbkFlag} -eq 1 ];then
        echo -e "\n\ticonv -f utf-8 -t gbk \"${srEdFName}\" -o \"${resultFile}\""
        iconv -f utf-8 -t gbk "${srEdFName}" -o "${resultFile}"
        retstat=$?
    else
        echo -e "\n\tcp -a \"${srEdFName}\" \"${resultFile}\""
        cp -a "${srEdFName}" "${resultFile}"
        retstat=$?
    fi

    if [[ ${retstat} -eq 0 && -e "${srEdFName}" ]];then
        echo -e "\n\trm -rf \"${srEdFName}\""
        rm -rf "${srEdFName}"

        if [ -e "${tBackFile}" ];then
            echo -e "\n\trm -rf \"${tBackFile}\""
            rm -rf "${tBackFile}"
        fi

        echo -e "\n\t\e[1;31mbackup\e[0m file:${srcInFName} --> file:${tBackFile}\n"
        cp -a "${srcInFName}" "${tBackFile}"

        cp -a "${resultFile}" "${srcInFName}"
        [ $? -eq 0 ] && rm -rf "${resultFile}"

        echo -e "\n\t\e[1;31mEdit the ${srcInFName} file successfully\e[0m \n"
    fi


    return 0
}

main()
{
    F_check
    F_edit

    return 0
}

main
exit 0
