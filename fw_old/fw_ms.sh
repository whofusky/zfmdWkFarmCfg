#!/bin/sh
#
#      File: fw_ms.sh
# Create on: 2019-01-08
#    Author: Sunjianjun/QQ37489753/WeChat:fatsunabc/Email:sunsjj@126.com
#  Function: Setup firewall for Meteo Server.
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

# Setup NTP on Meteo Server.
FW_UDP_NTP

# Setup Meto-data download on Meteo Server.
for remoteip in $METEO1_IP $METEO2_IP
do
  FW_TCP_OUT_R $remoteip 20
  FW_TCP_OUT_R $remoteip 21
  FW_TCP_OUT_R $remoteip 1024:65535
done
FW_TCP_IN_P 20
FW_TCP_IN_P 1024:65535

# Setup for REVERSE ISOLATOR on Meteo Server.
FW_NIC_OUT $MS_BID_NIC1
FW_NIC_OUT $MS_BID_NIC2

# Save it.
FW_SAVE

# View it.
FW_VIEW