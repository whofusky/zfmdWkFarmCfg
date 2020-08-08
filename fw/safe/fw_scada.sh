#!/bin/sh

#
#      File: fw_scada.sh
# Create on: 2019-01-08
#    Author: Sunjianjun/QQ37489753/WeChat:fatsunabc/Email:sunsjj@126.com
#  Function: Setup firewall for SCADA Server.
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
for remoteip in $PS1_IP $PS2_IP $WS_IP
do
  FW_TCP_EACHOTHER $SCADA_IP $remoteip $TIME_PORT_FIRST:$TIME_PORT_LAST
done

# Setup Audit Link on SCADA Server.
FW_UDP_OUT $SCADA_IP $AUDIT_IP
FW_TCP_OUT $SCADA_IP $AUDIT_IP $AUDIT_PORT1
FW_TCP_OUT $SCADA_IP $AUDIT_IP $AUDIT_PORT2

# Setup Data Center Link on SCADA Server.
for remoteip in $PS1_IP $PS2_IP
do
  FW_TCP_OUT $SCADA_IP $remoteip $DC_PORT
done

# Setup TCP/IP Servers on SCADA Server.
for addr in ${SCADA_SERVERS[@]}
do
  localaddr=`echo $addr | cut -d / -f 1`
  localip=`echo $localaddr | cut -d : -f 1`
  localport=`echo $localaddr | cut -d : -f 2`
  remoteaddr=`echo $addr | cut -d / -f 2`
  remoteip=`echo $remoteaddr | cut -d : -f 1`
  FW_TCP_IN $localip $localport $remoteip
done

# Setup TCP/IP Clients on SCADA Server.
for addr in ${SCADA_CLIENTS[@]}
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
