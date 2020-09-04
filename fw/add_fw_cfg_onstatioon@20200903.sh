#!/bin/bash
#2020-09-03 晚给网安地址在工作站添加防火墙通过规则

echo "iptables -A OUTPUT -d 100.110.120.100 -s 100.110.120.40  -p tcp  --dport 8800   -j ACCEPT"
iptables -A OUTPUT -d 100.110.120.100 -s 100.110.120.40  -p tcp  --dport 8800   -j ACCEPT
echo "iptables -A INPUT -s 100.110.120.100 -d 100.110.120.40  -p tcp  --sport 8800   -j ACCEPT"
iptables -A INPUT -s 100.110.120.100 -d 100.110.120.40  -p tcp  --sport 8800   -j ACCEPT



