#!/bin/sh

#
#      File: fw_ps1.sh
# Create on: 2019-01-08
#    Author: Sunjianjun/QQ37489753/WeChat:fatsunabc/Email:sunsjj@126.com
#  Function: Setup firewall for Predict Server 1.
#   Version: 1.0
# Revision History:
#   2019-01-08    Created by SunJianjun.

if [ $# -ne 0 ];
then
  echo "****************************************************************"
  echo "Usage: $0"
  echo ""
  echo "****************************************************************"
  exit
fi

. $PWD/functions

# Initiate Server.
FW_INIT

# Setup FULL TCP/IP function for software 'TimeSync'.
for remoteip in $SCADA_IP $PS2_IP $WS_IP
do
  FW_TCP_EACHOTHER $PS1_IP $remoteip $TIME_PORT_FIRST:$TIME_PORT_LAST
done

# Setup Audit Link on Predict Server 1.
FW_UDP_OUT $PS1_IP $AUDIT_IP
FW_TCP_OUT $PS1_IP $AUDIT_IP $AUDIT_PORT1
FW_TCP_OUT $PS1_IP $AUDIT_IP $AUDIT_PORT2

# Setup for REVERSE ISOLATOR on Predict Server 1.
FW_NIC_IN $PS1_BID_NIC

# Setup Web on Predict Server 1.
FW_TCP_IN $PS1_IP $WEB_PORT $WS_IP

# Setup Data Center Link on Predict Server 1.
for remoteip in $SCADA_IP $PS2_IP $WS_IP
do
  FW_TCP_IN $PS1_IP $DC_PORT $remoteip
done
FW_TCP_OUT $PS1_IP $PS2_IP $DC_PORT

# Setup TCP/IP Servers on Predict Server 1.
for addr in ${PS1_SERVERS[@]}
do
  localaddr=`echo $addr | cut -d / -f 1`
  localip=`echo $localaddr | cut -d : -f 1`
  localport=`echo $localaddr | cut -d : -f 2`
  remoteaddr=`echo $addr | cut -d / -f 2`
  remoteip=`echo $remoteaddr | cut -d : -f 1`
  FW_TCP_IN $localip $localport $remoteip
done

# Setup TCP/IP Clients on Predict Server 1.
for addr in ${PS1_CLIENTS[@]}
do
  localaddr=`echo $addr | cut -d / -f 1`
  localip=`echo $localaddr | cut -d : -f 1`
  remoteaddr=`echo $addr | cut -d / -f 2`
  remoteip=`echo $remoteaddr | cut -d : -f 1`
  remoteport=`echo $remoteaddr | cut -d : -f 2`
  FW_TCP_OUT $localip $remoteip $remoteport
done

# Save it.
FW_SAVE

# View it.
FW_VIEW
