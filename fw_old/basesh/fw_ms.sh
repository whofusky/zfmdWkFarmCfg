#!/bin/sh
#
#      File: fw_ms.sh
# Create on: 2019-01-08
#    Author: Sunjianjun/QQ37489753/WeChat:fatsunabc/Email:sunsjj@126.com
#  Function: Setup firewall for Meteo Server.
#   Version: 1.0
# Revision History:
#   2019-01-08    Created by SunJianjun.
#   2019-05-15    Modify by fushikai

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

# Setup NTP on Meteo Server.
#FW_UDP_NTP ${METE_INTERNET_NIC}
new_fw_onerule_op 0 3 "udp" "" "${METE_LOCAL_INTERNET_IP}" ":123"

# Setup Meto-data download on Meteo Server.
for remoteip in $METEO1_IP $METEO2_IP
do
    new_fw_onerule_op 0 1 "tcp" "" "${METE_LOCAL_INTERNET_IP}" "${remoteip}:20"
    new_fw_onerule_op 0 0 "tcp" "" "${METE_LOCAL_INTERNET_IP}" "${remoteip}:21"
    new_fw_onerule_op 0 0 "tcp" "" "${METE_LOCAL_INTERNET_IP}" "${remoteip}:1024-65535"
done
#FW_TCP_IN_P 20
#FW_TCP_IN_P 1024:65535

# Setup for REVERSE ISOLATOR on Meteo Server.
#FW_NIC_OUT $MS_BID_NIC1
#FW_NIC_OUT $MS_BID_NIC2
new_fw_onerule_op 0 0 "all" "${MS_BID_NIC1}" "" ""
new_fw_onerule_op 0 0 "all" "${MS_BID_NIC2}" "" ""

# Save it.
FW_SAVE

# View it.
FW_VIEW

echo -e "\n"
exit 0

