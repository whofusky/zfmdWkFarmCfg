#!/bin/sh
#
#      File: fw.sh
# Create on: 2019-01-08
#    Author: Sunjianjun/QQ37489753/WeChat:fatsunabc/Email:sunsjj@126.com
#  Function: Firewall Control.
#   Version: 1.0
# Revision History:
#   2019-01-08    Created by SunJianjun.

. $PWD/functions

function PRINT_HELP()
{
  echo "****************************************************************"
  echo "Usage: $0 start"
  echo "       $0 stop"
  echo "       $0 clear"
  echo "       $0 view"
  echo ""
  echo "****************************************************************"
}

if [ $# -ne 1 ];
then
  PRINT_HELP
  exit
fi

case $1 in
  start)
  FW_START
  ;;
  stop)
  FW_STOP
  ;;
  clear)
  FW_CLEAR
  ;;
  view)
  FW_VIEW
  ;;
  *)
  PRINT_HELP
  ;;
esac
