#!/bin/bash
#
################################################################################
#
#author : fushikai
#date   : 2021-04-29
#dsc    : 添加iptables出的规则，禁止探针发"Agent is Online"的报文
#
################################################################################

tcmd="iptables"       ; ttable="filter"       ; tchain="OUTPUT"
srcIP="198.122.0.110" ; dstIP="198.122.98.95" ; dstPort="8800"

tHexString="|41 67 65 6e 74 20 69 73 20 4f 6e 6c 69 6e 65|" #Agent is Online
tFrom=52 ; tTo=77 ;

function  F_iptables_status()
{
    local ret=0
    service ${tcmd} status >/dev/null 2>&1
    ret=$?
    return ${ret}
}

function F_save_add()
{
    local ret=0

    [ $# -eq 1 ] && ret="$1"
    [ "${ret}x" = "0x" ] && service ${tcmd} save 

    return 0
}

function F_check()
{
    local ret=0
    F_iptables_status
    ret=$?
    if [ ${ret} -ne 0 ];then
        service ${tcmd} start
        ret=$?
        if [ ${ret} -ne 0 ];then
            echo -e "\n启动防火墙失败，请联系管理员!\n"
            exit 1
        fi
    fi

    return 0
}

function F_insert_noSnd_rule()
{
    local insertLNo; local tmpStr ; local tOpName="-I"

    tmpStr=$(${tcmd} -t ${ttable} -vnL ${tchain} --line-number|sed -n '3{p;q}')
    if [ -z "${tmpStr}" ];then
        tOpName="-A"
    else
        insertLNo=$(${tcmd} -t ${ttable} -vnL ${tchain} --line-number|grep "${srcIP}"|head -1|awk '{print $1}')
        if [ -z "${insertLNo}" ];then
            insertLNo=1
        fi
    fi

    ${tcmd} -t ${ttable} ${tOpName} ${tchain} ${insertLNo} -d ${dstIP}  -s ${srcIP} -p tcp --dport ${dstPort} -m string --hex-string "${tHexString}" --algo bm  --from ${tFrom}  --to ${tTo} -j DROP

    return 0

}

function F_del_old_noSnd()
{
    local delLineNo

    delLineNo=$(${tcmd} -t ${ttable} -nvL ${tchain} --line-number|grep "${srcIP}"|grep -i "string match"|head -1|awk '{print $1}')
    while [ ! -z "${delLineNo}" ]
    do
        ${tcmd} -t ${ttable} -D ${tchain} ${delLineNo}
        delLineNo=$(${tcmd} -t ${ttable} -nvL ${tchain} --line-number|grep "${srcIP}"|grep -i "string match"|head -1|awk '{print $1}')
    done

    return 0
}

function F_show_output_srcRule()
{
    echo -e "\n----${tcmd}:${ttable}:${tchain}:${srcIP}:rules----"
    ${tcmd} -t ${ttable} -nvL ${tchain} --line-number|head -2|tail -1
    ${tcmd} -t ${ttable} -nvL ${tchain} --line-number|grep "${srcIP}"
    return 0
}

main()
{
    local ret=0

    F_check
    F_del_old_noSnd
    F_insert_noSnd_rule
    ret=$?
    F_save_add "${ret}"
    F_show_output_srcRule

    return 0
}

main

exit 0
