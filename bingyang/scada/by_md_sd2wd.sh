#!/bin/bash
#
################################################################################
#
# author : fu.sky
# date   : 2020-01-27
# dsc    : 宾阳风场将湿度与温度的点地址互换
# use    :
#        $0  <scdCfg.xml>
#
#
################################################################################
#

#湿度-> 温度
tsdName="湿度"  ;  twdName="温度"
tsdv[0]="16436" ;  twdv[0]="16441"
tsdv[1]="16437" ;  twdv[1]="16442"
tsdv[2]="16438" ;  twdv[2]="16443"
tsdv[3]="16439" ;  twdv[3]="16444"
tsdv[4]="16440" ;  twdv[4]="16445"

tnum=${#tsdv[*]}

baseDir=$(dirname $0)
sd2wdflag=0

function F_tips()
{
    echo -e "\n\t input like :$0 <scdCfg.xml>  \n"
    return 0
}

if [ $# -lt 1 ];then
    F_tips
    exit 1
fi

inFile="$1"

if [ ! -e "${inFile}" ];then
    echo -e "\n\tERROR: file [ ${inFile} ] not exist!\n"
    exit 2
fi

olyIName="${inFile##*/}"
fEc="$(file --mime-encoding ${inFile}|awk '{print $2}')"
fEc1="${fEc%%-*}"
utfFlag=0

edfile="${olyIName%.*}_utf.${olyIName##*.}"
resultfile="${olyIName%.*}_$$.${olyIName##*.}"

#echo "${edfile},${resultfile}"
#exit 0


function F_cover2utf8()
{
    if [[ "utf" != "${fEc1}" && "iso" != "${fEc1}" ]];then
        echo -e "\n\tERROR:input file[$inFile}] encoding is[${fEc} is not utf-8 nor gbk file\n"
        exit 3
    fi

    local tpdir="${baseDir}/tmp"
    [ ! -d "${tpdir}" ] && mkdir -p "${tpdir}"
    edfile="${tpdir}/${olyIName%.*}_utf.${olyIName##*.}"

    local rstdir="${baseDir}/result"
    [ ! -d "${rstdir}" ] && mkdir -p "${rstdir}"
    resultfile="${rstdir}/${olyIName%.*}_$$.${olyIName##*.}"


    if [ "utf" = "${fEc1}" ];then
        utfFlag=1
        cp ${inFile} ${edfile}
    else
        utfFlag=0
        iconv -f gbk -t utf-8 ${inFile} -o ${edfile}
    fi

    return 0
}

function F_recoverEc()
{
    if [ ${utfFlag} -eq 1 ];then
        cp ${edfile} ${resultfile}
    else
        iconv -f utf-8 -t gbk ${edfile} -o ${resultfile}
    fi

    return 0
}
function F_chgSomeAddrByName()
{
    if [ $# -lt 3 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameters less than 3!\n"
        return 1
    fi

    local addrLikeName="$1"
    local oldVal="$2"
    local newVal="$3"
    
    echo "${addrLikeName} addr modify [$i]: ${oldVal} --> ${newVal}"
    sed -i "/^\s*<pntAddr\s\+.*name\s*=\s*\"[^\"]*${addrLikeName}[^\"]*\"/{s/\"${oldVal}\"/\"${newVal}\"/g}" ${edfile}

    return 0
}

function F_exchangeSdWdAddr()
{
    if [ $# -lt 1 ];then
        echo -e "\n\tERROR:${FUNCNAME}:input parameters less than 1!\n"
        return 1
    fi
    local sd_to_wd_flag="$1"

    local i
    local oldVal
    local newVal
    local addrLikeName

    echo -e "\naddr num=[${tnum}]\n"

    #替换 湿度 的值
    for((i=0;i<${tnum};i++))
    do
        addrLikeName="${tsdName}"

        if [ "${sd_to_wd_flag}" = "1" ];then
            oldVal="${tsdv[$i]}"
            newVal="${twdv[$i]}"
        else
            oldVal="${twdv[$i]}"
            newVal="${tsdv[$i]}"
        fi
        F_chgSomeAddrByName "${addrLikeName}" "${oldVal}" "${newVal}"
    done

    echo "--------------------------------------------------------------------------------"

    #替换 温度 的值
    for((i=0;i<${tnum};i++))
    do
        addrLikeName="${twdName}"

        if [ "${sd_to_wd_flag}" = "1" ];then
            oldVal="${twdv[$i]}"
            newVal="${tsdv[$i]}"
        else
            oldVal="${tsdv[$i]}"
            newVal="${twdv[$i]}"
        fi
        F_chgSomeAddrByName "${addrLikeName}" "${oldVal}" "${newVal}"
    done

    return 0
}

function F_getOption()
{
    local tprompt="
    请输入如下选择项前的数字进行相应操作

        [1] 修改湿度addr类[${tsdv[0]} -> ${twdv[0]}]
            修改温度addr类[${twdv[0]} -> ${tsdv[0]}]

        [2] 修改湿度addr类[${twdv[0]} -> ${tsdv[0]}]
            修改温度addr类[${tsdv[0]} -> ${twdv[0]}]

        [3] 退出!

    您的选择是: "

    local tmpIn
    while((1))
    do
        read -n 1 -p "${tprompt}" tmpIn
        if [[ "x${tmpIn}" != "x1" && "x${tmpIn}" != "x2" && "x${tmpIn}" != "x3" ]];then
            continue
        fi

        echo -e "\n"
        if [ ${tmpIn} -eq 3 ];then
            exit 0
        elif [ ${tmpIn} -eq 1 ];then
            sd2wdflag=1
        else
            sd2wdflag=0
        fi

        #echo ${tmpIn}
        break
    done

    return 0
}

main()
{
    F_getOption

    F_cover2utf8

    F_exchangeSdWdAddr "${sd2wdflag}"   #将湿度与温度addr互换

    F_recoverEc

    echo -e "\n结果文件为: [\e[1;31m${resultfile}\e[0m]\n"

    return 0
}

main

exit 0
