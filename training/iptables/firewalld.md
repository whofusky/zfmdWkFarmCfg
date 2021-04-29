firewalld


# firewalld


-------------------

## 目录

+ ---------- [1. firewalld在linux中的位置](#1-firewalld在linux中的位置)

+ ---------- [2. firewalld的主要概念](#2-firewalld的主要概念)
  + --------- [2.1 过滤规则集合zone](#2_1-过滤规则集合zone)
  + --------- [2.2 service](#2_2-service)
  + --------- [2.3 过滤规则](#2_3-过滤规则)
  + --------- [2.4 过滤规则优先级](#2_4-过滤规则优先级)
 
+ ---------- [3. firewalld配置文件](#3-firewalld配置文件)
  + --------- [3.1 firewalld配置方式](#3_1-firewalld配置方式)
  + --------- [3.2 配置文件存储位置](#3_2-配置文件存储位置)
  + --------- [3.3 配置文件结构](#3_3-配置文件结构)
  + --------- [3.4 zone文件中配置规则](#3_4-zone文件中配置规则)

+ ---------- [4. firewalld常用命令](#4-firewalld常用命令)
  + --------- [4.1 查看防火墙状态](#4_1-查看防火墙状态)
  + --------- [4.2 开启防火墙并设置开机自启](#4_2-开启防火墙并设置开机自启)
  + --------- [4.3 总的查询命令](#4_3-总的查询命令)
  + --------- [4.4 配置文件加载与保存](#4_4-配置文件加载与保存)
  + --------- [4.5 zone的相关操作](#4_5-zone的相关操作)
  + --------- [4.6 panic模式](#4_6-panic模式)
  + --------- [4.7 配置规则 source](#4_7-firewall-cmd配置规则-source)
  + --------- [4.8 配置规则 interface](#4_8-firewall-cmd配置规则-interface)
  + --------- [4.9 配置规则 interface](#4_9-firewall-cmd配置规则-interface)
  + --------- [4.10 配置规则 port](#4_10-firewall-cmd配置规则-port)
  + --------- [4.11 配置规则 icmp-block](#4_11-firewall-cmd配置规则-icmp-block)
  + --------- [4.12 配置规则 masquerade](#4_12-firewall-cmd配置规则-masquerade)
  + --------- [4.13 配置规则 端口转发](#4_13-firewall-cmd配置规则-端口转发)
  + --------- [4.14 配置规则 rule规则](#4_14-firewall-cmd配置规则-rule规则)
  + --------- [4.15 配置规则 direct](#4_15-firewall-cmd配置规则-direct)


-------------------

## 1 firewalld在linux中的位置

RHEL中有几种防火墙共存,这些软件本身其实并不具备防火墙功能，他们的作用都是在用户空间中管理和维护规则，只不过规则结构和使用方法不一样罢了，真正利用规则进行过滤是由内核的netfilter完成的。

CentOS7默认采用的是firewalld管理netfilter子系统，底层调用的仍然是iptables命令。不同的防火墙软件相互间存在冲突，使用某个时应禁用其他的。



```
│system-config-firewall││firewall-config││firewall-cmd │
└─────────┬────────────┘└──────┬────────┘└──┬──────────┘
   ┌──────▼──────────┐  ┌──────▼────────────▼────┐
   │iptalbes(service)│  │firewall(daemon&servcie)│
   └───┬─────────────┘  └─┬──────────────────────┘
   ┌───▼──────────────────▼┐
   │   iptables(command)   │
   └───────────┬───────────┘
   ┌───────────▼───────┐
   │ kernel(netfilter) │
   └───────────────────┘
```

dynamic firewall daemon。支持ipv4和ipv6。Centos7中默认将防火墙从iptables升级为了firewalld。firewalld相对于iptables主要的优点有：

1.  firewalld可以动态修改单条规则，而不需要像iptables那样，在修改了规则后必须得全部刷新才可以生效；
2.  firewalld在使用上要比iptables人性化很多，即使不明白“五张表五条链”而且对TCP/IP协议也不理解也可以实现大部分功能。


>[返回目录](#目录)


-------------------

## 2 firewalld的主要概念

### 2_1 过滤规则集合zone

+   一个zone就是一套过滤规则，数据包必须要经过某个zone才能入站或出站。不同zone中规则粒度粗细、安全强度都不尽相同。可以把zone看作是一个个出站或入站必须经过的安检门，有的严格、有的宽松、有的检查的细致、有的检查的粗略。

+   每个zone单独对应一个xml配置文件，文件名为<zone名称>.xml。自定义zone只需要添加一个<zone名称>.xml文件，然后在其中添加过滤规则即可。

+   每个zone都有一个默认的处理行为，包括：default(省缺),   ACCEPT,%%REJECT%%,DROP 

+   firewalld提供了9个zone：
    + drop  任何流入的包都被丢弃，不做任何响应。只允许流出的数据包。
  
    + block 任何流入的包都被拒绝，返回icmp-host-prohibited报文(ipv4)或icmp6-adm-prohibited报文(ipv6)。只允许由该系统初始化的网络连接
  
    + public 默认的zone。部分公开，不信任网络中其他计算机，只放行特定服务。 
   
    + external 只允许选中的服务通过，用在路由器等启用伪装的外部网络。认为网路中其他计算器不可信。
   
    + dmz  允许隔离区(dmz)中的电脑有限的被外界网络访问，只允许选中的服务通过。
   
    + work  用在工作网络。你信任网络中的大多数计算机不会影响你的计算机，只允许选中的服务通过。
 
    + home  用在家庭网络。信任网络中的大多数计算机，只允许选中的服务通过。
 
    + internal 用在内部网络。信任网络中的大多数计算机，只允许选中的服务通过。
  
    + trusted  允许所有网络连接，即使没有开放任何服务，那么使用此zone的流量照样通过（一路绿灯）。

zone配置文件示例：public.xml
```
<?xml version="1.0" encoding="utf-8"?>
<zone target="default">
  <short>Public</short>
  <description>For use in public areas...</description>
  <service name="ssh"/>
  <service name="dhcpv6-client"/>
</zone>
```

>[返回目录](#目录)


### 2_2 service

+   一个service中可以配置特定的端口（将端口和service的名字关联）。zone中加入service规则就等效于直接加入了port规则，但是使用service更容易管理和理解。

+   定义service的方式：添加<service名称>.xml文件，在其中加入要关联的端口即可。

### 2_3 过滤规则

+   source 根据数据包源地址过滤，相同的source只能在一个zone中配置。
+   interface 根据接收数据包的网卡过滤
+   service 根据服务名过滤（实际是查找服务关联的端口，根据端口过滤），一个service可以配置到多个zone中。
+   port 根据端口过滤
+   icmp-block icmp报文过滤，可按照icmp类型设置
+   masquerade ip地址伪装，即将接收到的请求的源地址设置为转发请求网卡的地址（路由器的工作原理）。
+   forward-port 端口转发
+   rule 自定义规则，与itables配置接近。rule结合--timeout可以实现一些有用的功能，比如可以写个自动化脚本，发现异常连接时添加一条rule将相应地址drop掉，并使用--timeout设置时间段，过了之后再自动开放。

### 2_4 过滤规则优先级

1.  source               源地址
2.  interface            接收请求的网卡
3.  firewalld.conf中配置的默认zone



>[返回目录](#目录)

-------------------

## 3 firewalld配置文件

### 3_1 firewalld配置方式

+  firewall-config       GUI工具
+  firewall-cmd         命令行工具
+  直接编辑xml文件    编辑后还需要reload才生效


### 3_2 配置文件存储位置

firewalld的配置文件以xml为主（主配置文件firewalld.conf除外），有两个存储位置：

-   /etc/firewalld/ 存放修改过的配置（优先查找，找不到再找默认的配置）

-   /usr/lib/firewalld/ 默认的配置
修改配置的话只需要将/usr/lib/firewalld中的配置文件复制到/etc/firewalld中修改。恢复配置的话直接删除/etc/firewalld中的配置文件即可。


### 3_3 配置文件结构

+   firewalld.conf 主配置文件，键值对格式
    +   DefaultZone 默认使用的zone，默认值为public
	+   MinimalMark 标记的最小值，默认为100
	+   CleanupOnExit 退出firewalld后是否清除防火墙规则，默认为yes
	+   Lockdown 是否其他程序允许通过D-BUS接口操作，使用lockdown-whitelist.xml限制程序，默认为no
	+   IPv6_rpfilter 类似rp_filter，判断接收的包是否是伪造的（通过路由表中的路由条目，查找uRPF），默认为yes     
+   lockdown-whitelist.xml
+   direct.xml direct功能，直接使用防火墙的过滤规则，便于iptables的迁移
+   zones/ zone配置文件
+   services/ service配置文件
+   icmptypes/ icmp类型相关的配置文件


>[返回目录](#目录)


### 3_4 zone文件中配置规则

```
<?xml version="1.0" encoding="utf-8"?>
<zone target="default">   <!--target属性为zone的默认处理行为，可选值：default(省缺),   ACCEPT,   %%REJECT%%,  DROP -->
    <short>Demo</short>
    <description>demo...</description>
    <source address="address[/mask]">
    <interface name="ifcfg-em1"/>     <!--也可在网卡配置文件ifcfg-*中配置，只需要加入 ZONE=public -->  
    <service name="ssh"/>
    <port port="portid[-portid]" protocol="tcp|udp"/>
    <icmp-block name="echo-request"/>   <!--ping报文-->
    <masquerade/>
    <forward-port port="portid[-portid]" protocol="tcp|udp" [to-port="portid[-portid]"] [to-addr="ipv4address"]/>

    <rule [family="ipv4|ipv6"]>
               [ <source address="address[/mask]" [invert="bool"]/> ]
               [ <destination address="address[/mask]" [invert="bool"]/> ]
               [
                 <service name="string"/> |
                 <port port="portid[-portid]" protocol="tcp|udp"/> |
                 <protocol value="protocol"/> |
                 <icmp-block name="icmptype"/> |
                 <masquerade/> |
                 <forward-port port="portid[-portid]" protocol="tcp|udp" [to-port="portid[-portid]"] [to-addr="address"]/>
               ]
               [ <log [prefix="prefixtext"] [level="emerg|alert|crit|err|warn|notice|info|debug"]/> [<limit value="rate/duration"/>] </log> ]
               [ <audit> [<limit value="rate/duration"/>] </audit> ]
               [ <accept/> | <reject [type="rejecttype"]/> | <drop/> ]
     </rule>
</zone>
```

>[返回目录](#目录)

-------------------

## 4 firewalld常用命令

### 4_1 查看防火墙状态

```
systemctl status firewalld
```

### 4_2 开启防火墙并设置开机自启

```
systemctl start firewalld
systemctl enable firewalld
```

>[返回目录](#目录)


### 4_3 总的查询命令

```
firewall-cmd --version
firewall-cmd --help

#查看firewalld服务状态
firewall-cmd --state  

```

>[返回目录](#目录)


### 4_4 配置文件加载与保存

```
#修改配置文件后，动态加载，不会断开连接。
firewall-cmd --reload        

#完全重新加载看，会断开连接。类似重启。
firewall-cmd --complete-reload     

#Make the new settings persistent
firewall-cmd --runtime-to-permanent
```

>[返回目录](#目录)


### 4_5 zone的相关操作

```
#查看已有的zone名
firewall-cmd --get-zones

#设置/查询默认的zone，也可以修改firewalld.conf中的DefaultZone选项。
firewall-cmd --set-default-zone=ZONE 
firewall-cmd --get-default-zone

#zone的默认的行为
firewall-cmd --permanent [--zone=zone] --get-target
firewall-cmd --permanent [--zone=zone] --set-target=target

#查看所有绑定了source, interface和默认的zone，以及各个zone的生效条件。
firewall-cmd --get-active-zones                    
firewall-cmd --zone=xxxx --list-all


//反向查询：  根据source或interface查询对应的zone
firewall-cmd --get-zone-of-interface=interface
firewall-cmd --get-zone-of-source=source[/mask]

```

>[返回目录](#目录)


### 4_6 panic模式
```
#panic模式开启/关闭/查询。panic模式会丢弃所有出入站的数据包，一段时间后所有连接都会超时中断。
firewall-cmd --panic-on/--panic-off/--query-panic  
```

>[返回目录](#目录)


### 4_7 firewall-cmd配置规则 source

>配置source，相同的source只能在一个zone中配置,否则会提示Error ZONE_CONFLICT

```
#显示绑定的source
firewall-cmd [--permanent] [--zone=zone] --list-sources   

#查询是否绑定了source
firewall-cmd [--permanent] [--zone=zone] --query-source=source[/mask]  

#绑定source，如果已有绑定则取消。
firewall-cmd [--permanent] [--zone=zone] --add-source=source[/mask]  

#修改source，如果原来未绑定则添加绑定。
firewall-cmd [--zone=zone] --change-source=source[/mask] 

#删除绑定   
firewall-cmd [--permanent] [--zone=zone] --remove-source=source[/mask]         
```

>[返回目录](#目录)


### 4_8 firewall-cmd配置规则 interface

>interface   如eth0, 也可以在网卡配置文件ifcfg-\*中加入  ZONE=ZONE名

```
firewall-cmd [--permanent] [--zone=zone] --list-interfaces
firewall-cmd [--permanent] [--zone=zone] --add-interface=interface
firewall-cmd [--zone=zone] --change-interface=interface
firewall-cmd [--permanent] [--zone=zone] --query-interface=interface
firewall-cmd [--permanent] [--zone=zone] --remove-interface=interface
```

>[返回目录](#目录)


### 4_9 firewall-cmd配置规则 service

```
firewall-cmd [--permanent] [--zone=zone] --list-services
firewall-cmd [--permanent] [--zone=zone] --add-service=service [--timeout=seconds]   
firewall-cmd [--permanent] [--zone=zone] --remove-service=service
firewall-cmd [--permanent] [--zone=zone] --query-service=service
```

>[返回目录](#目录)


### 4_10 firewall-cmd配置规则 port

```
firewall-cmd [--permanent] [--zone=zone] --list-ports
firewall-cmd [--permanent] [--zone=zone] --add-port=portid[-portid]/protocol [--timeout=seconds]
firewall-cmd [--permanent] [--zone=zone] --remove-port=portid[-portid]/protocol
firewall-cmd [--permanent] [--zone=zone] --query-port=portid[-portid]/protocol
```


开放或限制端口eg:

```
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --reload
firewall-cmd --zone=public --query-port=22/tcp
firewall-cmd --zone=public --list-ports

firewall-cmd --zone=public --remove-port=22/tcp --permanent
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
```

批量开放或限制端口eg:

```
firewall-cmd --zone=public --add-port=100-500/tcp --permanent

firewall-cmd --zone=public --remove-port=100-500/tcp --permanent 

```

>[返回目录](#目录)



### 4_11 firewall-cmd配置规则 icmp-block

>icmp-block, 默认允许所有ICMP通过

```
#查看所有支持的ICMP类型
firewall-cmd --get-icmptypes

firewall-cmd [--permanent] [--zone=zone] --list-icmp-blocks
firewall-cmd [--permanent] [--zone=zone] --add-icmp-block=icmptype [--timeout=seconds]
firewall-cmd [--permanent] [--zone=zone] --remove-icmp-block=icmptype
firewall-cmd [--permanent] [--zone=zone] --query-icmp-block=icmptype
```

eg:

```
firewall-cmd --permanent --zone=public --add-icmp-block=echo-reply
firewall-cmd --permanent --zone=public --add-icmp-block=echo-request
```


>[返回目录](#目录)


### 4_12 firewall-cmd配置规则 masquerade

```
firewall-cmd [--permanent] [--zone=zone] --add-masquerade [--timeout=seconds]
firewall-cmd [--permanent] [--zone=zone] --remove-masquerade
firewall-cmd [--permanent] [--zone=zone] --query-masquerade
```

>[返回目录](#目录)


### 4_13 firewall-cmd配置规则 端口转发

```
firewall-cmd [--permanent] [--zone=zone] --list-forward-ports
firewall-cmd [--permanent] [--zone=zone] --add-forward-port=port=PORT[-PORT]:proto=PROTOCAL[:toport=PORT[-PORT]][:toaddr=ADDRESS[/MASK]][--timeout=SECONDS]
firewall-cmd [--permanent] [--zone=zone] --remove-forward-port=port=PORT[-PORT]:proto=PROTOCAL[:toport=PORT[-PORT]][:toaddr=ADDRESS[/MASK]]
firewall-cmd [--permanent] [--zone=zone] --query-forward-port=port=PORT[-PORT]:proto=PROTOCAL[:toport=PORT[-PORT]][:toaddr=ADDRESS[/MASK]]
```

>[返回目录](#目录)


### 4_14 firewall-cmd配置规则 rule规则

```
#rule规则，  'rule'是将xml配置中的<和/>符号去掉后的字符串，如 'rule family="ipv4" source address="1.2.3.4" drop'
firewall-cmd [--permanent] [--zone=zone] --list-rich-rules
firewall-cmd [--permanent] [--zone=zone] --add-rich-rule='rule' [--timeout=seconds]
firewall-cmd [--permanent] [--zone=zone] --remove-rich-rule='rule'
firewall-cmd [--permanent] [--zone=zone] --query-rich-rule='rule'
```

开放或限制IP eg:

```
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.0.200" port protocol="tcp" port="80" reject"
firewall-cmd --reload
firewall-cmd --zone=public --list-rich-rules

firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="192.168.0.200" port protocol="tcp" port="80" accept"
firewall-cmd --add-rich-rule="rule family="ipv4" source address="192.168.0.233 destination address="192.168.0.147" port port="80" protocol="tcp" accep"
firewall-cmd --add-rich-rule="rule family="ipv4" source address="192.168.0.233 destination address="192.168.0.147" port port="80" protocol="tcp" log prefix="fusktest" level="warning" limit value="2/s" accep"
firewall-cmd --add-rich-rule="rule family="ipv4" source address="192.168.0.233 destination address="192.168.0.147" source-port port="80" protocol="tcp" log prefix="fusktest" level="warning" limit value="2/s" accep"

#注意: source-port 与 port 不能同时设置


#如设置未生效，可尝试直接编辑规则文件，删掉原来的设置规则，重新载入一下防火墙即可
#vi /etc/firewalld/zones/public.xml
```

限制IP地址段eg:

```
firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="10.0.0.0/24" port protocol="tcp" port="80" reject"

firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="10.0.0.0/24" port protocol="tcp" port="80" accept" 

```

>[返回目录](#目录)


### 4_15 firewall-cmd配置规则 direct

>iptables 的直接接口
对于最高级的使用，或对于 iptables 专家，FirewallD 提供了一个直接Direct接口，允许你给它传递原始 iptables命令。 直接接口规则不是持久的，除非使用 --permanent。


The basic structure of a rule is:
```
ipv - "ipv4|ipv6|eb" # If rule is iptables, ip6tables or ebtables based
table -"table" # Location of rule in filter, mangle, nat, etc. table
chain - "chain" # Location of rule in INPUT, OUTPUT, FORWARD, etc. chain
priority - "priority" # Lower priority value rules take precedence over higher priority values
rule
```

要查看添加到 FirewallD 的所有自定义链或规则：

```
firewall-cmd --direct --get-all-chains
firewall-cmd --direct --get-all-rules
```

```
firewall-cmd --direct --add-rule ipv4 filter IN_public_allow \
        0 -m tcp -p tcp --dport 666 -j ACCEPT

firewall-cmd --direct --remove-rule ipv4 filter IN_public_allow \
        0 -m tcp -p tcp --dport 666 -j ACCEPT

firewall-cmd --direct --get-rules ipv4 filter IN_public_allow

```

firewall-cmd --direct eg:

```
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p tcp --dport 80 -s 10.0.0.107 -j LOG --log-prefix "DIRECT HTTP ACCEPT"

firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 1 -p tcp --dport 80 -s 10.0.0.107 -j ACCEPT

firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 2 -p tcp --dport 80 -j LOG --log-prefix "DIRECT HTTP REJECT" 

firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 3 -p tcp --dport 80 -s 0.0.0.0 -j REJECT --reject-with icmp-host-unreachable

firewall-cmd --reload

#firewall-cmd --direct --get-all-rules
ipv4 filter INPUT 0 -p tcp --dport 80 -s 10.0.0.107 -j LOG --log-prefix 'DIRECT HTTP ACCEPT'
ipv4 filter INPUT 1 -p tcp --dport 80 -s 10.0.0.107 -j ACCEPT
ipv4 filter INPUT 2 -p tcp --dport 80 -j LOG --log-prefix 'DIRECT HTTP REJECT'
ipv4 filter INPUT 3 -p tcp --dport 80 -s 0.0.0.0 -j REJECT --reject-with icmp-host-unreachable
```


>[返回目录](#目录)


-------------------
