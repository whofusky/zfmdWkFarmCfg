#!/bin/bash

#date:2020-05-17
#author:fusk
#Desc:临时处理高龙山测风塔把某个层高替换成另一个层高的配置处理脚本
#
#    此脚本现在的逻辑是把测风塔90层高的点替换成70的点地址，并将乘法系统*1.12
#    如果要实现其他的逻辑需要对此脚本进行一些修改处理
#


tInLNum=1
if [ $# -ne ${tInLNum} ];then
    echo -e "\n\t\e[1;31mERROR\e[0m: $0 in paramas num not eq ${tInLNum}  !\n"
    echo -e "\n\tusage: $0 <scada_cfg_file>\n"
    exit 1
fi

baseDir=$(dirname $0)

#需要修改的配置文件名
tDofile=$1
if [ ! -e "${tDofile}" ];then
    echo -e "\n\t\e[1;31mERROR\e[0m: file [${tDofile}] not exist!\n"
    exit 1
fi

#对配置文件进行编码方式进行识别,此脚本处理的文件编码为utf-8
tcharset=$(file --mime-encoding ${tDofile} |awk  '{print $2}')
tcharset="${tcharset%%-*}" 
tDofileUtf="${tDofile%.*}_tmpDo_utf8.${tDofile##*.}"

if [ "${tcharset}" == "iso" ];then
    if [ -e "${tDofileUtf}" ];then
        rm -rf "${tDofileUtf}"
    fi
    iconv -f gbk -t utf8 "${tDofile}" -o "${tDofileUtf}"
else
    cp "${tDofile}" "${tDofileUtf}"
fi


echo -e "\n\t tDofileUtf=[${tDofileUtf}]\n"

tHaveLN_file1="${baseDir}/have_ln_1.txt"

#生成方式处理的临时文件
egrep -n "(^\s*<\s*[/]*\s*phyObjVal\b|^\s*<\s*dataId\b|^\s*<\s*pntAddr\b|^\s*<\s*[/]*\s*channel\b)" ${tDofileUtf}>${tHaveLN_file1}

#对临时文件中尽量去掉冗余的内容
tHaveChnNo=0
tRealChnNo=$(echo "(${tHaveChnNo}+1)*2"|bc)
echo "tRealChnNo=[${tRealChnNo}]"
i=0
for it in $(egrep -n "\s*<\s*[/]*\s*channel\b" ${tHaveLN_file1}|awk -F':' '{print $1}')
do
    #echo "${it}"
    if [ ${tRealChnNo} -eq ${i} ];then
        break
    fi
    let i++
    
done
#echo "it=[${it}]"
sed -i "${it},$ d"  ${tHaveLN_file1}


function F_prtEchoNdVl()
{
    local inNum=2
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    local tKey="$1"
    local tmpStr="$2"
    
    tmpStr=$(echo "${tmpStr}"|awk -F'[><]' '{for(i=1;i<=NF;i++){if($i ~/'${tKey}'/){print $(i+1);break;}}}')
    echo "${tmpStr}"

    return 0
}


function F_prtfindKeyVal()
{
    local inNum=2
    local thisFName="${FUNCNAME}"
    if [ $# -ne ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function ${thisFName} in paramas num not eq ${inNum}!\n"
        return 1
    fi
    
    local tKey="$1"
    local tmpStr="$2"
    
    #echo -e "${tmpStr}"|awk -F'[= "]'  '{for(i=1;i<=NF;i++){if($i ~/'${tKey}'/ ){print $(i+2);break;} }}'
    #tDidName=$(sed -n "${tDidLinNo} p" ${tcfgFile}|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/(name|didName)/){print $(i+1);break;}}}')
    echo -e "${tmpStr}"|sed 's/\(\s\+=\s*\|=\s\+\)/=/g'|awk -F'"' '{for(i=1;i<=NF;i++){if($i ~/\<'${tKey}'\>/){print $(i+1);break;}}}'

    return 0
}

function F_setFixLNdVal()
{
    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi
    
    local tLine="$1"
    local tKey="$2"
    local tVal="$3"
    local tEdFile="$4"
    if [ $# -gt 4 ];then
        local proCont="$5"
    fi

    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in function ${thisFName} edit file [${tEdFile}] not exist!\n"
        return 2
    fi

    local tmpStr=$(sed -n "${tLine} {p;q}" ${tEdFile})
    local tOldVal=$(F_prtEchoNdVl "${tKey}" "${tmpStr}")

    if [ "${tOldVal}" == "${tVal}" ];then
        #echo "[${tOldVal}] eq [${tVal}]"
        return 0
    fi

    tmpStr=$(echo "${tmpStr}"|sed -e 's///g' -e 's/^\s\+//g')
    echo -e "line[${LINENO}]:file:[${tEdFile}] \e[1;31m${proCont}\e[0m line:[${tLine}] content:[${tmpStr}] ,modify [\e[1;31m${tKey}\e[0m]'s value [\e[1;31m${tOldVal}\e[0m] to [\e[1;31m${tVal}\e[0m]  "

    #sed -i "${tLine} s/\b${tKey}\b\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g" ${tEdFile}
    sed -i "${tLine}{s/<\s*${tKey}\s*>[^>]*<\s*\/\s*${tKey}\s*>/<${tKey}>${tVal}<\/${tKey}>/}" ${tEdFile} 
    

    return 0
}

function F_setFixLinKeyVal()
{
    local inNum=4
    local thisFName="${FUNCNAME}"
    if [ $# -lt ${inNum} ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: function  ${thisFName} in paramas num less than ${inNum}!\n"
        return 1
    fi
    
    local tLine="$1"
    local tKey="$2"
    local tVal="$3"
    local tEdFile="$4"
    if [ $# -gt 4 ];then
        local proCont="$5"
    fi

    if [ ! -e "${tEdFile}" ];then
        echo -e "\n\tline[${LINENO}]:\e[1;31mERROR\e[0m: in function ${thisFName} edit file [${tEdFile}] not exist!\n"
        return 2
    fi

    local tmpStr=$(sed -n "${tLine} {p;q}" ${tEdFile})
    local tOldVal=$(F_prtfindKeyVal "${tKey}" "${tmpStr}")

    if [ "${tOldVal}" == "${tVal}" ];then
        #echo "[${tOldVal}] eq [${tVal}]"
        return 0
    fi

    tmpStr=$(echo "${tmpStr}"|sed -e 's///g' -e 's/^\s\+//g')
    echo -e "line[${LINENO}]:file:[${tEdFile}] \e[1;31m${proCont}\e[0m line:[${tLine}] content:[${tmpStr}] ,modify [\e[1;31m${tKey}\e[0m]'s value [\e[1;31m${tOldVal}\e[0m] to [\e[1;31m${tVal}\e[0m]  "

    sed -i "${tLine} s/\b${tKey}\b\s*=\s*\"[^\"]*\"/${tKey}=\"${tVal}\"/g" ${tEdFile}
    

    return 0
}



#sed -n '/ectype\s*=\s*"\s*ENCODETYPE_AMT\s*"/p' ${tHaveLN_file1}|sed -n '/hvalue\s*=\s*"\s*90\s*"/p'

#egrep -n '\s*ectype\s*=\s*"\s*ENCODETYPE_AMT\s*"' ${tHaveLN_file1}|egrep 'hvalue\s*=\s*"\s*90\s*'
#egrep -n '\s*ectype\s*=\s*"\s*ENCODETYPE_AMT\s*"' ${tHaveLN_file1}|egrep 'hvalue\s*=\s*"\s*70\s*'


tH_phy_ln=0
tH_add1_ln=0
tH_add2_ln=0
tH_did_ln=0

#根据${tHaveLN_file1}中dataId所在行号取${tHaveLN_file1}中前面相关量:号前面的数字
function F_getPALnByDidLn()
{
    local tHDidln=$1
    local tHPyln=$(echo "${tHDidln} - 3"|bc)
    local tHAdd1ln=$(echo "${tHDidln} - 2"|bc)
    local tHAdd2ln=$(echo "${tHDidln} - 1"|bc)
    tH_phy_ln=$(sed -n "${tHPyln}{p;q}" ${tHaveLN_file1}|awk -F':' '{print $1}')
    tH_add1_ln=$(sed -n "${tHAdd1ln}{p;q}" ${tHaveLN_file1}|awk -F':' '{print $1}')
    tH_add2_ln=$(sed -n "${tHAdd2ln}{p;q}" ${tHaveLN_file1}|awk -F':' '{print $1}')
    tH_did_ln=$(sed -n "${tHDidln}{p;q}" ${tHaveLN_file1}|awk -F':' '{print $1}')
    return 0
}

dcatalog=""
dkind=""
ectype=""
srctype=""
hvalue=""
ivalue=""

#根据${tHaveLN_file1}中dataId所在行号取得did的一些属性值
function F_getDidAttrInHFileByLn()
{
    local tHDidln=$1
    local tmpStr=$(sed -n "${tHDidln}{p;q}" ${tHaveLN_file1}|awk -F':' '{print $2}')
    dcatalog=$(F_prtfindKeyVal "dcatalog" "${tmpStr}")
    dkind=$(F_prtfindKeyVal "dkind" "${tmpStr}")
    ectype=$(F_prtfindKeyVal "ectype" "${tmpStr}")
    srctype=$(F_prtfindKeyVal "srctype" "${tmpStr}")
    hvalue=$(F_prtfindKeyVal "hvalue" "${tmpStr}")
    ivalue=$(F_prtfindKeyVal "ivalue" "${tmpStr}")

    return 0
}


didLnByAttr=0
#根据${tHaveLN_file1}中dataId的属生值取得dataId在${tHaveLN_file1}中的行号
function F_getDidLnByAttrInHF()
{

    local tmpStr=""
    tmpStr=$(egrep -n "\s*ivalue\s*=\s*\"\s*${ivalue}\s*\"" ${tHaveLN_file1}|egrep "\s*dcatalog\s*=\s*\"\s*${dcatalog}\s*\""|egrep "\s*dkind\s*=\s*\"\s*${dkind}\s*\""|egrep "\s*ectype\s*=\s*\"\s*${ectype}\s*\""|egrep "\s*srctype\s*=\s*\"\s*${srctype}\s*\""|egrep "\s*hvalue\s*=\s*\"\s*${hvalue}\s*\"")
    if [ -z "${tmpStr}" ];then
        echo -e "\n\t\e[1;31mERROR,not find in [${tHaveLN_file1}] as following attr\e[0m: dcatalog=${dcatalog},dkind=${dkind},ectype=${ectype},srctype=${srctype},hvalue=${hvalue},ivalue=${ivalue}\n"
        didLnByAttr=0
        return 1
    fi
    didLnByAttr=$(echo "${tmpStr}"|awk -F':' '{print $1}')
    return 0
}

#配置文件中需要参考量的行号
cfgsrc_phy_ln=0
cfgsrc_add1_ln=0
cfgsrc_add2_ln=0
cfgsrc_did_ln=0

#配置文件中需要修改量的行号
cfgdst_phy_ln=0
cfgdst_add1_ln=0
cfgdst_add2_ln=0
cfgdst_did_ln=0

#根据${tHaveLN_file1}中90米的dataId 的行号得到配置文件中对应的 src 行号和 dst行号，然后取值比对进行修改
function F_toModifyByHDLn()
{
    local tHDidln=$1
    local ret=0

    #直接得到需要修改的行号
    F_getPALnByDidLn ${tHDidln}
    cfgdst_phy_ln=${tH_phy_ln}
    cfgdst_add1_ln=${tH_add1_ln}
    cfgdst_add2_ln=${tH_add2_ln}
    cfgdst_did_ln=${tH_did_ln}

    #取得需要修改行号did对应的现有的一些属性值
    F_getDidAttrInHFileByLn ${tHDidln}
    #修改得到的一些属生值变成要查找的源属性值
    hvalue=70
    #根据属性值找到源did在${tHaveLN_file1}中而不是最终配置文件中的行号
    F_getDidLnByAttrInHF
    ret=$?
    #没有找到则直接退出
    [ ${ret} -ne 0 ] && exit 2


    #取得src源在配置文件中行号
    F_getPALnByDidLn ${didLnByAttr}
    cfgsrc_phy_ln=${tH_phy_ln}
    cfgsrc_add1_ln=${tH_add1_ln}
    cfgsrc_add2_ln=${tH_add2_ln}
    cfgsrc_did_ln=${tH_did_ln}

    local tmpStr=""
    local tmpStr1=""

    local src_multFactor=0
    local src_add1=0
    local src_add2=0

    #get src som attr value
    tmpStr=$(sed -n "${cfgsrc_phy_ln} {p;q}" ${tDofileUtf})
    src_multFactor=$(F_prtfindKeyVal "multFactor" "${tmpStr}")
    local tnum=$(sed -n "${cfgsrc_did_ln} {p;q}" ${tDofileUtf}|egrep '\s*dkind\s*=\s*"\s*DATAKIND_SDV\s*"'|wc -l)
    if [ ${tnum} -eq 0 ];then
        src_multFactor=$(echo "${src_multFactor} * 1.12"|bc)
    fi

    tmpStr=$(sed -n "${cfgsrc_add1_ln} {p;q}" ${tDofileUtf})
    src_add1=$(F_prtEchoNdVl "pntAddr" "${tmpStr}")

    tmpStr=$(sed -n "${cfgsrc_add2_ln} {p;q}" ${tDofileUtf})
    src_add2=$(F_prtEchoNdVl "pntAddr" "${tmpStr}")

    local tmpPtCmt="gls 20200517 modify"

    #set dest value 
    F_setFixLinKeyVal "${cfgdst_phy_ln}" "multFactor" "${src_multFactor}" "${tDofileUtf}" "${tmpPtCmt}"
    F_setFixLNdVal "${cfgdst_add1_ln}" "pntAddr" "${src_add1}" "${tDofileUtf}" "${tmpPtCmt}"
    F_setFixLNdVal "${cfgdst_add2_ln}" "pntAddr" "${src_add2}" "${tDofileUtf}" "${tmpPtCmt}"



    return 0
    

}

#针对90米测风塔风速的量进行修改操作
for hl90 in $(egrep -n '\s*ectype\s*=\s*"\s*ENCODETYPE_AMT\s*"' ${tHaveLN_file1}|egrep 'hvalue\s*=\s*"\s*90\s*'|egrep 'dcatalog\s*=\s*"\s*DATACATALOG_WS\s*'|awk -F':' '{print $1}')
do
    #echo "hl90=${hl90}"
    F_toModifyByHDLn ${hl90}
done




exit 0

