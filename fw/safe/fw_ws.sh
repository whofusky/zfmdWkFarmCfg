#!/bin/sh
#
#      File: fw_ws.sh
# Create on: 2019-01-08
#    Author: Sunjianjun/QQ37489753/WeChat:fatsunabc/Email:sunsjj@126.com
#  Function: Setup firewall for Workstation.
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
for remoteip in $SCADA_IP $PS1_IP $PS2_IP
do
  FW_TCP_EACHOTHER $WS_IP $remoteip $TIME_PORT_FIRST:$TIME_PORT_LAST
done

# Setup Audit Link on Workstation.
FW_UDP_OUT $WS_IP $AUDIT_IP
FW_TCP_OUT $WS_IP $AUDIT_IP $AUDIT_PORT1
FW_TCP_OUT $WS_IP $AUDIT_IP $AUDIT_PORT2

# Setup Data Center Link on Workstation.
for remoteip in $PS1_IP $PS2_IP
do
  FW_TCP_OUT $WS_IP $remoteip $DC_PORT
done

# Setup Web link to Predict Server 1/2 on Workstation.
for remoteip in $PS1_IP $PS2_IP
do
FW_TCP_OUT $WS_IP $remoteip $WEB_PORT
done

# Save it.
FW_SAVE

# View it.
FW_VIEW