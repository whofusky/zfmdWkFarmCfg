#!/bin/sh
echo "#复位"
iptables -F
iptables -X
iptables -L -n
/etc/rc.d/init.d/iptables save
service iptables restart
echo "#全开"
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
echo "#复位"
iptables -L -n
/etc/rc.d/init.d/iptables save
service iptables restart

