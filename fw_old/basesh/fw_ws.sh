#!/bin/sh
#
#      File: fw_ws.sh
# Create on: 2019-01-08
#    Author: Sunjianjun/QQ37489753/WeChat:fatsunabc/Email:sunsjj@126.com
#  Function: Setup firewall for Workstation.
#   Version: 1.1
# Revision History:
#   2019-01-23    Add WS_CLIENTS[].
#   2019-01-08    Created by SunJianjun.
#   2019-05-17    Modify by fushikai

if [ $# -ne 0 ];
then
    echo "****************************************************************"
    echo "Usage: $0"
    echo ""
    echo "****************************************************************"
    exit
fi


baseDir=$(dirname $0)
funcFile="${baseDir}/functions"

if [ ! -e ${funcFile} ];then
    echo -e "\n\tError: File [${funcFile}] does not exist!!\n"
    exit 1
fi

. ${funcFile}

echo -e "\n\t\e[1;31mdebugFlag=[${debugFlag}]\e[0m"
echo -e "\t\e[1;31menablePing=[${enablePing}]\e[0m"
echo -e "\t\e[1;31menInterSsh=[${enInterSsh}]\e[0m"
echo -e "\t\e[1;31mbindNICByIP=[${bindNICByIP}]\e[0m"


#--------------------------------------------------------------------------------
# new_fw_onerule_op( outPrtFlag, server_opFlag, op_protocol, NIC_name, local_ip:port, remote_ip:port )
#----------------------------------------------------------------------
# input:
#-------
#   outPrtFlag:        0:OUTPUT,INPUT; 1:OUTPUT; 2:INPUT 
#   server_opFlag      0:client; 1:server; 2:client,server; 3:stat null
#   op_protocol        tcp,upd,all
#   NIC_name           Network card name
#   local_Addr         local_ip:loca_port
#   remote_addr        remote_ip:remote_port
#----------------------------------------------------------------------
# output:
#-------
#   error msg OR null
#----------------------------------------------------------------------
# return:
#-------
#          0:      success
#      other:      error
# 
#--------------------------------------------------------------------------------



# Initiate Server.
FW_INIT

# Open internal ssh port
if [[ ! -z "${enInterSsh}" && ${enInterSsh} -eq 1 ]];then
    for remoteip in $SCADA_IP $PS1_IP $PS2_IP
    do
        new_fw_onerule_op 0 2 "tcp"  "" "$WS_IP" "${remoteip}:22"
        
    done

fi


# Setup FULL TCP/IP function for software 'TimeSync'.
for remoteip in $SCADA_IP $PS1_IP $PS2_IP
do
    new_fw_onerule_op 0 2 "tcp" "" "$WS_IP" "${remoteip}:${TIME_PORT}"
done

# Setup Audit Link on Workstation.
new_fw_onerule_op 0 3 "udp" "" "${WS_IP}:${AUDIT_PORT}" "${AUDIT_IP}"

# Setup Data Center Link on Workstation.
for remoteip in $PS1_IP $PS2_IP
do
    new_fw_onerule_op 0 0 "tcp" "" ${WS_IP} "${remoteip}:${DC_PORT}"
done

# Setup Web link to Predict Server 1/2 on Workstation.
for remoteip in $PS1_IP $PS2_IP
do
    new_fw_onerule_op 0 0 "tcp" "" ${WS_IP} "${remoteip}:${WEB_PORT}"
done

# Setup TCP/IP Clients on Workstation.
WS_CLIENTS=$(convertVLineToSpace "${WS_CLIENTS}") 
for addr in ${WS_CLIENTS}
do
    localaddr=$(echo "${addr}" | cut -d / -f 1)
    remoteaddr=$(echo "${addr}" | cut -d / -f 2)
    new_fw_onerule_op 0 0 "tcp" "" "${localaddr}" "${remoteaddr}"

done

# Save it.
FW_SAVE

# View it.
FW_VIEW

echo -e "\n"
exit 0
