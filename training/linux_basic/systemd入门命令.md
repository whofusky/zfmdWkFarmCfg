systemd 入门命令


# systemd 入门


------

## 目录

+ ------ [1. Systemd工具集](#1)
  - [1.1 systemctl](#1_1)
  - [1.2 systemd-analyze](#1_2)
  - [1.3 hostnamectl](#1_3)
  - [1.4 localectl](#1_4)
  - [1.5 timedatectl](#1_5)
  - [1.6 loginctl](#1_6)

+ ------ [2. Unit](#2)
  - [2.1 Unit的含义](#2_1)
  - [2.2 Unit的状态](#2_2)
  - [2.3 Unit 管理](#2_3)
  - [2.4 依赖关系](#2_4)


+ ------ [3. Unit 的配置文件](#3)
  - [3.1 概述](#3_1)
  - [3.2 配置文件的状态](#3_2)
  - [3.3 配置文件的格式](#3_3)
  - [3.4 配置文件的区块](#3_4)


+ ------ [4. Target](#4)


+ ------ [5. 日志管理](#5)



------

查看是否为systemd

```
ps -p 1
ls -l /sbin/init
```

## 1
## Systemd工具集

Systemd并不是一个命令,而是一组命令,涉及到系统管理的方方面面。

### 1_1
### systemctl

systemctl是 Systemd 的主命令,用于管理系统

这里只列出系统管理命令

```shell
# 重启系统
sudo systemctl reboot

# 关闭系统，切断电源
sudo systemctl poweroff

# CPU停止工作
sudo systemctl halt

# 暂停系统
sudo systemctl suspend

# 让系统进入休眠状态
sudo systemctl hibernate

# 让系统进入交互式休眠状态
sudo systemctl hybrid-sleep

# 启动进入救援状态（单用户状态）
sudo systemctl rescue

```


>[返回目录](#目录)


### 1_2
### systemd-analyze

systemd-analyze 命令用于查看启动耗时

```shell
# 查看启动耗时
systemd-analyze

# 查看每个服务的启动耗时
systemd-analyze blame

# 显示瀑布状的启动过程流
systemd-analyze critical-chain

# 显示指定服务的启动流
systemd-analyze critical-chain atd.service

```

>[返回目录](#目录)


### 1_3
### hostnamectl

hostnamectl命令用于查看 / 设置当前主机的信息,它其实是往 /etc/hostname 文件名写入你设置的名称

```shell
# 显示当前主机的信息
hostnamectl

# 设置主机名
sudo hostnamectl set-hostname Bruce

```

### 1_4
### localectl

命令用于查看 / 设置本地化设置,该命令其实就是往 /etc/locale.conf 文件写参数

```shell
# 查看本地化设置
localectl

# 设置本地化参数。
sudo localectl set-locale LANG=en_US.utf8
sudo localectl set-keymap en_US

# 注意set-locale其实是往/etc/locale.conf文件写参数，如果你一次只设置一个属性，则后面写的会把前面的覆盖掉，所以必须多个属性一起设置才行，一起设置用空格格开就行，如：
sudo localectl set-locale LANG=en_US.utf8 LC_CTYPE=en_US.utf8

```

>[返回目录](#目录)


### 1_5
### timedatectl

timedatectl命令用于查看当前时区设置

```shell
# 查看当前时区设置
timedatectl

# 显示所有可用的时区
timedatectl list-timezones

# 设置当前时区
sudo timedatectl set-timezone Asia/Shanghai
sudo timedatectl set-time YYYY-MM-DD
sudo timedatectl set-time HH:MM:SS

```
timedatectl修改时区,实际上是把 /usr/share/zoneinfo/ 中的某个时区软链到 /etc/localtime 文件

### 1_6
### loginctl

```shell
# 列出当前session
loginctl list-sessions

# 列出当前登录用户
loginctl list-users

# 列出显示指定用户的信息
loginctl show-user ruanyf

```

>[返回目录](#目录)


------

## 2
## Unit

### 2_1
### Unit的含义

Systemd可以管理所有系统资源,不同的资源统称为 Unit( 单元 ) , Unit 一共分成 12 种。

>1. Service unit :系统服务   
>2. Target unit :多个 Unit 构成的一个组  
>3. Device Unit :硬件设备    
>4. Mount Unit :文件系统的挂载点 
>5. Automount Unit:自动挂载点
>6. Path Unit :文件或路径
>7. Scope Unit :不是由 Systemd 启动的外部进程
>8. Slice Unit :进程组
>9. Snapshot Unit : Systemd 快照,可以切回某个快照
>10. Socket Unit :进程间通信的 socket
>11. Swap Unit : swap 文件
>12. Timer Unit :定时器   

```
# 列出正在运行的 Unit
systemctl list-units

# 列出所有Unit，包括没有找到配置文件的或者启动失败的
systemctl list-units --all

# 列出所有没有运行的 Unit
systemctl list-units --all --state=inactive

# 列出所有加载失败的 Unit
systemctl list-units --failed

```

>[返回目录](#目录)


### 2_2
### Unit的状态

```
# 显示系统状态
systemctl status

# 显示单个 Unit 的状态
sysystemctl status bluetooth.service

# 显示远程主机的某个 Unit 的状态
systemctl -H root@rhel7.example.com status nginx.service

# 显示某个Unit是否正在运行
systemctl is-active application.service

# 显示某个Unit是否处于启动失败状态
systemctl is-failed application.service

# 显示某个Unit服务是否建立了启动链接
systemctl is-enabled application.service

```

>[返回目录](#目录)


### 2_3
### Unit 管理

```
# 立即启动一个服务
sudo systemctl start apache.service

# 立即停止一个服务
sudo systemctl stop apache.service

# 重启一个服务
sudo systemctl restart apache.service

# 杀死一个服务的所有子进程
sudo systemctl kill apache.service

# 重新加载一个服务的配置文件
sudo systemctl reload apache.service

# 重载所有修改过的配置文件(这里指位于/usr/lib/systemd/system中的配置文件)
sudo systemctl daemon-reload

# 显示某个 Unit 的所有底层参数
systemctl show nginx.service

# 显示某个 Unit 的指定属性的值
systemctl show -p CPUShares nginx.service

# 设置某个 Unit 的指定属性
sudo systemctl set-property nginx.service CPUShares=500

```


### 2_4
### 依赖关系

```
#列出一个 Unit 的所有依赖
systemctl list-dependencies nginx.service
#有些依赖是 Target 类型,默认不会展开显示。如果要展开
systemctl list-dependencies --all nginx.service
```

>[返回目录](#目录)


------

## 3
## Unit 的配置文件

### 3_1
### 概述

每一个 Unit 都有一个配置文件 ( 一般后缀为 .service ,但也有其它后缀的 ) ,用于告诉 Systemd 怎么启动这个 Unit 。

Systemd 会从以下两个目录中读取配置

```
# 用户手动安装的软件Unit配置文件(当然你往/usr/lib/systemd/system/放也不会有问题)
/etc/systemd/system/
# 通常通过yum/dnf(centos8, yum的升级)/rpm/apt 等系统安装命令安装的软件包的Unit配置文件会放在该目录中
/usr/lib/systemd/system/

```

`systemctl enable xxxx`命令用于在上面两个目录之间,建立符号链接 ( 即软链接 ) 关系,当原配置文件在 /etc/systemd/system/
时,它会向 /usr/lib/systemd/system/ 创建一个符号链接,反之,当原配置文件在 /usr/lib/systemd/system/ 时,它会向 /et
c/systemd/system/ 创建一个符号链接

```
sudo systemctl enable clamd@scan.service
# 等同于
sudo ln -s '/usr/lib/systemd/system/clamd@scan.service' '/etc/systemd/system/multi-user.target.wants/clamd@scan.service'

```

注意:符号链接其实一般不是直接创建在 /etc/systemd/system/ 下,而是创建在它下面的某个目录下,比如常⻅的 multi-user.t
arget.wants 目录,因为 Linux 服务器一般都是运行在多用戶模式下,所以一般设置开机启动,会在该目录下创建 multi-user.targ
et.wants 目录下创建。
如果配置文件里面设置了开机启动, `systemctl enable xxx` 命令相当于激活开机启动。与之对应的, `systemctl disable xxx `命令用于在两个目录之间,撤销符号链接关系,相当于撤销开机启动。

```
sudo systemctl disable clamd@scan.service
```

配置文件的后缀名,就是该 Unit 的种类,比如 sshd.socket 。如果省略, Systemd 默认后缀名为 .service ,所以 sshd 会被理解成
sshd.service 。
注意: /run/systemd/generator.late/ 目录中的 .service 文件是 systemd-sysv-generator 工具处理 SysV init 脚本 ( 即 /etc/
rc.d/init.d/ 中的文件 ) 自动生成的,这样做是为了兼容 SysV init ⻛格 ( 即老式启动方式 ) ,其本质其实还是调用的 SysV init 的启动命
令。
比如典型的,我们可以查看 /run/systemd/generator.late/network.service 这个文件,你会发现它里面启动和停止语句是这样的:
```
ExecStart=/etc/rc.d/init.d/network start
ExecStart=/etc/rc.d/init.d/network stop
```

>[返回目录](#目录)



### 3_2
### 配置文件的状态

```
# 列出所有配置文件
$ systemctl list-unit-files

# 列出指定类型的配置文件
$ systemctl list-unit-files --type=service

```

这个列表显示每个配置文件的状态,一共有四种:
```
enabled :已建立启动链接
disabled :没建立启动链接
static :该配置文件没有 [Install] 部分(无法执行),只能作为其他配置文件的依赖
masked :该配置文件被禁止建立启动链接
```
注意,从配置文件的状态无法看出,该 Unit 是否正在运行。这必须执行前面提到的 systemctl status 命令。
```
systemctl status bluetooth.service
```
一旦修改配置文件,就要让 Systemd 重新加载配置文件,然后重新启动,否则修改不会生效 ( 事实上如果你不重置,它会提示你需要重
置 ) :
```
sudo systemctl daemon-reload
sudo systemctl restart nginx.service
```

>[返回目录](#目录)



### 3_3
### 配置文件的格式

配置文件就是普通的文本文件,可以用文本编辑器打开。
`systemctl cat `命令可以查看配置文件的内容:

```
systemctl cat atd.service

[Unit]
Description=ATD daemon

[Service]
Type=forking
ExecStart=/usr/bin/atd

[Install]
WantedBy=multi-user.target

```

从上面的输出可以看到,配置文件分成几个区块。每个区块的第一行,是用方括号表示的区别名,比如 [Unit] 。注意,配置文件的
区块名和字段名,都是大小写敏感的。
每个区块内部是一些等号连接的键值对 ( 注意:键值对的等号两侧不能有空格 ) 。
```
[Section]
Directive1=value
Directive2=value
```

>[返回目录](#目录)


### 3_4
### 配置文件的区块

+ Description:简短描述
+ Documentation :文档地址
+ Requires :当前 Unit 依赖的其他 Unit ,如果它们没有运行,当前 Unit 会启动失败
+ Wants :与当前 Unit 配合的其他 Unit ,如果它们没有运行,当前 Unit 不会启动失败
+ BindsTo :与 Requires 类似,它指定的 Unit 如果退出,会导致当前 Unit 停止运行
+ Before :如果该字段指定的 Unit 也要启动,那么必须在当前 Unit 之后启动
+ After :如果该字段指定的 Unit 也要启动,那么必须在当前 Unit 之前启动
+ Conflicts :这里指定的 Unit 不能与当前 Unit 同时运行
+ Condition... :当前 Unit 运行必须满足的条件,否则不会运行
+ Assert... :当前 Unit 运行必须满足的条件,否则会报启动失败

`[Install] `通常是配置文件的最后一个区块,用来定义如何启动,以及是否开机启动。它的主要字段如下:

+ WantedBy :它的值是一个或多个 Target ,当前 Unit 激活时( enable )符号链接会放入 /etc/systemd/system 目录下面以
Target 名 + .wants 后缀构成的子目录中
+ RequiredBy :它的值是一个或多个 Target ,当前 Unit 激活时,符号链接会放入 /etc/systemd/system 目录下面以 Target 名 +
.required 后缀构成的子目录中
+ Alias :当前 Unit 可用于启动的别名
+ Also :当前 Unit 激活( enable )时,会被同时激活的其他 Unit

`[Service]`区块用来设置 Service 的配置,只有 Servic 类型的 Unit 才有这个区块。它的主要字段如下。

+ Type :定义启动时的进程行为。它有以下几种值。
	Type=simple :默认值,执行 ExecStart 指定的命令,启动主进程
	Type=forking :以 fork 方式从父进程创建子进程,创建后父进程会立即退出    
	Type=oneshot :一次性进程, Systemd 会等当前服务退出,再继续往下执行    
	Type=dbus :当前服务通过 D-Bus 启动
	Type=notify :当前服务启动完毕,会通知 Systemd ,再继续往下执行    
	Type=idle :若有其他任务执行完毕,当前服务才会运行
+ ExecStart :启动当前服务的命令
+ ExecStartPre :启动当前服务之前执行的命令
+ ExecStartPost :启动当前服务之后执行的命令
+ ExecReload :重启当前服务时执行的命令
+ ExecStop :停止当前服务时执行的命令
+ ExecStopPost :停止当其服务之后执行的命令
+ RestartSec :自动重启当前服务间隔的秒数
+ Restart:定义何种情况 Systemd 会自动重启当前服务,可能的值包括 always (总是重启)、 on-success 、 on-failure 、 on-
abnormal 、 on-abort 、 on-watchdog
+ TimeoutSec :定义 Systemd 停止当前服务之前等待的秒数
+ Environment :指定环境变量


>[返回目录](#目录)


------

## 4
## Target

启动计算机的时候,需要启动大量的 Unit 。如果每一次启动,都要一一写明本次启动需要哪些 Unit ,显然非常不方便。 Systemd 的解
决方案就是 Target 。
简单说, Target 就是一个 Unit 组,包含许多相关的 Unit 。启动某个 Target 的时候, Systemd 就会启动里面所有的 Unit 。从这个意义上
说, Target 这个概念类似于 ” 状态点 ” ,启动某个 Target 就好比启动到某种状态。
传统的 init 启动模式里面,有 RunLevel 的概念,跟 Target 的作用很类似。不同的是, RunLevel 是互斥的,不可能多个 RunLevel 同时启
动,但是多个 Target 可以同时启动。

```
# 查看当前系统的所有 Target
systemctl list-unit-files --type=target

# 查看一个 Target 包含的所有 Unit
systemctl list-dependencies multi-user.target

# 查看启动时的默认 Target
systemctl get-default

# 设置启动时的默认 Target
sudo systemctl set-default multi-user.target

# 切换 Target 时，默认不关闭前一个 Target 启动的进程，
# systemctl isolate 命令改变这种行为，
# 关闭前一个 Target 里面所有不属于后一个 Target 的进程
sudo systemctl isolate multi-user.target

```

与 传统 RunLevel 的对应关系如下

```
Traditional runlevel      New target name     Symbolically linked to...

Runlevel 0           |    runlevel0.target -> poweroff.target
Runlevel 1           |    runlevel1.target -> rescue.target
Runlevel 2           |    runlevel2.target -> multi-user.target
Runlevel 3           |    runlevel3.target -> multi-user.target
Runlevel 4           |    runlevel4.target -> multi-user.target
Runlevel 5           |    runlevel5.target -> graphical.target
Runlevel 6           |    runlevel6.target -> reboot.target


```

它与 init 进程的主要差别如下:

1. 默 认 的 RunLevel ( 在 /etc/inittab 文 件 设 置 ) 现 在 被 默 认 的 Target 取 代 , 位 置
是 /etc/systemd/system/default.target ,通常符号链接到 graphical.target (图形界面)或者 multi-user.target
(多用戶命令行)。

2. 启动脚本的位置,以前是 /etc/init.d/ 目录,符号链接到不同的 RunLevel 目录 (比如 /etc/rc3.d 、 /etc/rc5.d 等),
现在则存放在 /lib/systemd/system 和 /etc/systemd/system 目录。

3. 配置文件的位置,以前 init 进程的配置文件是 /etc/inittab ,各种服务的配置文件存放在 /etc/sysconfig 目录。现在的配置
文件主要存放在 /lib/systemd 目录,在 /etc/systemd 目录里面的修改可以覆盖原始设置。



>[返回目录](#目录)


------

## 5
## 日志管理

systemd统一管理所有 Unit 的启动日志。带来的好处就是,可以只用 journalctl 一个命令,查看所有日志(内核日志和应用日志)。日
志的配置文件是 /etc/systemd/journald.conf 。
journalctl 功能强大,用法非常多:

```
# 查看所有日志（默认情况下 ，只保存本次启动的日志）
sudo journalctl

# 查看内核日志（不显示应用日志）
sudo journalctl -k

# 查看系统本次启动的日志
sudo journalctl -b
sudo journalctl -b -0

# 查看上一次启动的日志（需更改设置）
sudo journalctl -b -1

# 查看指定时间的日志
sudo journalctl --since="2012-10-30 18:17:16"
sudo journalctl --since "20 min ago"
sudo journalctl --since yesterday
sudo journalctl --since "2015-01-10" --until "2015-01-11 03:00"
$ sudo journalctl --since 09:00 --until "1 hour ago"

# 显示尾部的最新10行日志
sudo journalctl -n

# 显示尾部指定行数的日志
sudo journalctl -n 20

# 实时滚动显示最新日志(类似tail -f -n /path/to/error.log)
sudo journalctl -f

# 查看指定服务的日志
sudo journalctl /usr/lib/systemd/systemd

# 查看指定进程的日志
sudo journalctl _PID=1

# 查看某个路径的脚本的日志
sudo journalctl /usr/bin/bash

# 查看指定用户的日志
sudo journalctl _UID=33 --since today

# 查看某个 Unit 的日志
sudo journalctl -u nginx.service
sudo journalctl -u nginx.service --since today

# 实时滚动显示某个 Unit 的最新日志(类似tail -f -n /path/to/error.log)
sudo journalctl -u nginx.service -f

# 合并显示多个 Unit 的日志
journalctl -u nginx.service -u php-fpm.service --since today

# 查看指定优先级（及其以上级别）的日志，共有8级
# 0: emerg
# 1: alert
# 2: crit
# 3: err
# 4: warning
# 5: notice
# 6: info
# 7: debug
sudo journalctl -p err -b

# 日志默认分页输出，--no-pager 改为正常的标准输出
sudo journalctl --no-pager

# 以 JSON 格式（单行）输出
sudo journalctl -b -u nginx.service -o json

# 以 JSON 格式（多行）输出，可读性更好
sudo journalctl -b -u nginx.serviceqq
 -o json-pretty

# 显示日志占据的硬盘空间
sudo journalctl --disk-usage

# 指定日志文件占据的最大空间
sudo journalctl --vacuum-size=1G

# 指定日志文件保存多久
sudo journalctl --vacuum-time=1years

```

>[返回目录](#目录)


------