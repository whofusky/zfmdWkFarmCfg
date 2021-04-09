浅析 Linux 初始化

# 浅析 Linux 初始化

----------

## 目录

+ -------[1. 第一部分 – Sysvinit](#1)
  + [1.1 什么是 Init 系统](#1_1)
  + [1.2 优缺点](#1_2)
  + [1.3 Sysvinit 的管理和控制功能](#1_3)

+ -------[2. 第二部分 – UpStart](#2)
  + [2.1 Upstart 简介](#2_1)
    + [2.1.1 概念和术语之Job](#2_1_1)
    + [2.1.2 概念和术语之Event](#2_1_2)
  + [2.2 配置文件](#2_2)
  + [2.3 Upstart 开发需求](#2_3)
  + [2.4 及运行级别](#2_4)
  + [2.5 需要了解的 Upstart 命令](#2_5)
  
+ -------[3. 第三部分 – Systemd](#3)
  + [3.1 Systemd的简介和特点](#3_1) 
  + [3.2 Systemd 的基本概念](#3_2) 
    + [3.2.1 单元的概念](#3_2_1)
    + [3.2.2 依赖关系](#3_2_2)
    + [3.2.3 Systemd 事务](#3_2_3)
    + [3.2.4 Target 和运行级别](#3_2_4)
    + [3.2.5 Systemd 的并发启动原理](#3_2_5)
  + [3.3 Systemd 的使用](#3_3) 
    + [3.3.1 系统软件开发人员](#3_3_1)
    + [3.3.2 系统管理员](#3_3_2)


----------

## 1
## 第一部分 – Sysvinit

### 1_1
### 什么是 Init 系统

操作系统的启动首先从 BIOS 开始,接下来进入 boot loader ,由 bootloader 载入内核,进行内核初始化。内核初始化的最后一步
就是启动 pid 为 1 的 init 进程。这个进程是系统的第一个进程,它负责产生其他所有用戶进程。

init 以守护进程方式存在,是所有其他进程的祖先。 init 进程非常独特,能够完成其他进程无法完成的任务。

Init 系统能够定义、管理和控制 init 进程的行为。它负责组织和运行许多独立的或相关的始化工作 ( 因此被称为 init 系统 ) ,从而让计算机
系统进入某种用戶预订的运行模式。

Sysvinit就是 systemV ⻛格的 init 系统,顾名思义,它源于 SystemV 系列 UNIX 。它提供了比 BSD ⻛格 init 系统更高的灵活性。是已经⻛行
了几十年的 UNIXinit 系统,一直被各类 Linux 发行版所采用。

**运行级别**

用术语 runlevel 来定义 “ 预订的运行模式 ” 。 Sysvinit 检查 /etc/inittab 文件中是否含有 initdefault 项。这告诉 init 系统是
否有一个默认运行模式。如果没有默认的运行模式,那么用戶将进入系统控制台,手动决定进入何种运行模式。

>[返回目录](#目录)

### 1_2
### 优缺点

**------优点------**

的优点是概念简单。 Service 开发人员只需要编写启动和停止脚本,概念非常清楚;将 service 添加 / 删除到某个 runlevel 时,只
需要执行一些创建 / 删除软连接文件的基本操作;这些都不需要学习额外的知识或特殊的定义语法 (UpStart 和 Systemd 都需要用戶学习
新的定义系统初始化行为的语言 ) 。
其次, sysvinit 的另一个重要优点是确定的执行顺序:脚本严格按照启动数字的大小顺序执行,一个执行完毕再执行下一个,这非常
有益于错误排查。 UpStart 和 systemd 支持并发启动,导致没有人可以确定地了解具体的启动顺序,排错不易。

**------缺点------**

它主要依赖于 Shell 脚本,这就决定了它的最大弱点:启动太慢。在很少重新启动的 Server 上,这个缺点并不重要。而当 Linux 被应用到移动终端设备的时候,启动慢就成了一个大问题。此外动态设备加载等 Linux 新特性也暴露出 sysvinit 设计的一些问题。

为了更快地启动,人们开始改进 sysvinit ,先后出现了 upstart 和 systemd 这两个主要的新一代 init 系统。 Upstart 已经开发了 8 年多,在不少系统中已经替换 sysvinit 。 Systemd 出现较晚,但发展更快,大有取代 upstart 的趋势。


>[返回目录](#目录)

### 1_3
### Sysvinit 的管理和控制功能


此外,在系统启动之后,管理员还需要对已经启动的进程进行管理和控制。原始的 sysvinit 软件包包含了一系列的控制启动,运行和关闭所有其他程序的工具。

|命令|解释|
|----|---|
|halt| :停止系统。|
|init |:这个就是 sysvinit 本身的 init 进程实体,以 pid 1 身份运行,是所有用戶进程的父进程,最主要的作用是在启动过程中使用 /etc/inittab 文件创建进程。|
|killall5 |:就是 SystemV 的 killall 命令。向除自己的会话 (session) 进程之外的其它进程发出信号,所以不能杀死当前使用的 shell 。|
|last |:回溯 /var/log/wtmp 文件 ( 或者 -f 选项指定的文件 ) ,显示自从这个文件建立以来,所有用戶的登录情况。|
|lastb |:作用和 last 差不多,默认情况下使用 /var/log/btmp 文件,显示所有失败登录企图。|
|mesg| :控制其它用戶对用戶终端的访问。|
|pidof| :找出程序的进程识别号 (pid) ,输出到标准输出设备。|
|poweroff |:等于 shutdown -h –p ,或者 telinit 0 。关闭系统并切断电源。|
|reboot |:等于 shutdown –r 或者 telinit 6 。重启系统。|
|runlevel |:读取系统的登录记录文件 ( 一般是 /var/run/utmp) 把以前和当前的系统运行级输出到标准输出设备。|
|shutdown| :以一种安全的方式终止系统,所有正在登录的用戶都会收到系统将要终止通知,并且不准新的登录。|
|sulogin |:当系统进入单用戶模式时,被 init 调用。当接收到启动加载程序传递的 -b 选项时, init 也会调用 sulogin 。|
|telinit |:实际是 init 的一个连接,用来向 init 传送单字符参数和信号。|
|utmpdump |:以一种用戶友好的格式向标准输出设备显示 /var/run/utmp 文件的内容。|
|wall |:向所有有信息权限的登录用戶发送消息。|

不同的 Linux 发行版在这些 sysvinit 的基本工具基础上又开发了一些辅助工具用来简化 init 系统的管理工作。比如 RedHat 的 RHEL 在
sysvinit 的基础上开发了 initscripts 软件包,包含了大量的启动脚本 ( 如 rc.sysinit) ,还提供了 `service , chkconfig` 等命令行工具,甚至一套图形化界面来管理 init 系统。其他的 Linux 发行版也有各自的 initscript 或其他名字的 init 软件包来简化 sysvinit 的管理。


>[返回目录](#目录)

----------

## 2
## 第二部分 – UpStart

### 2_1
### Upstart 简介

#### 2_1_1
#### 概念和术语之Job

Upstart的基本概念和设计清晰明确。 UpStart 主要的概念是 job 和 event 。 Job 就是一个工作单元,用来完成一件工作,比如启动一个后
台服务,或者运行一个配置命令。每个 Job 都等待一个或多个事件,一旦事件发生, upstart 就触发该 job 完成相应的工作。

Job就是一个工作的单元,一个任务或者一个服务。可以理解为 sysvinit 中的一个服务脚本。有三种类型的工作:
>1. task job ;
>2. service job ;
>3. abstract job ;

Job 的可能状态
|状态名|含义|
|-----|----|
|Waiting|初始状态|
|Starting|Job 即将开始|
|pre-start|执行 pre-start 段,即任务开始前应该完成的工作|
|Spawned|准备执行 script 或者 exec 段|
|post-start|执行 post-start 动作|
|Running|interim state set after post-start section processed denoting job is running (But it may have no associated PID!)|
|pre-stop|执行 pre-stop 段|
|Stopping|interim state set after pre-stop section processed|
|Killed|任务即将被停止|
|post-stop|执行 post-stop 段|

 其中有四个状态会引起 init 进程发送相应的事件,表明该工作的相应变化:
>+ Starting
>+ Started
>+ Stopping
>+ Stopped

而其它的状态变化不会发出事件。


>[返回目录](#目录)

#### 2_1_2
#### 概念和术语之Event

顾名思义, Event 就是一个事件。事件在 upstart 中以通知消息的形式具体存在。一旦某个事件发生了, Upstart 就向整个系统发送一个消息。没有任何手段阻止事件消息被 upstart 的其它部分知晓,也就是说,事件一旦发生,整个 upstart 系统中所有工作和其它的事件都会得到通知。

Event 可以分为三类 : `signal 、 methods 或者 hooks` 。

>1. Signals : Signal 事件是非阻塞的,异步的。发送一个信号之后控制权立即返回。
>
>2. Methods : Methods 事件是阻塞的,同步的。
>
>3. Hooks : Hooks 事件是阻塞的,同步的。它介于 Signals 和 Methods 之间,调用发出 Hooks 事件的进程必须等待事件完成才可以得到控
制权,但不检查事件是否成功。

### 2_2
### 配置文件 

任何一个工作都是由一个工作配置文件 (Job Configuration File) 定义的。这个文件是一个文本文件,包含一个或者多个小节 (stanza) 。
每个小节是一个完整的定义模块,定义了工作的一个方面,比如 author 小节定义了工作的作者。`工作配置文件存放在 /etc/init 下面,是以 .conf 作为文件后缀的文件`。


>[返回目录](#目录)

### 2_3
### Upstart 开发需求

当 Linux 内核进入 2.6 时代时,内核功能有了很多新的更新。新特性使得 Linux 不仅是一款优秀的服务器操作系统,也可以被用于桌面系
统,甚至嵌入式设备。桌面系统或便携式设备的一个特点是经常重启,而且要频繁地使用硬件热插拔技术。

在 2.6 内核支持下,一旦新外设连接到系统,内核便可以自动实时地发现它们,并初始化这些设备,进而使用它们。这为便携式设备用戶提供了很大的灵活性。

UpStart解决了之前提到的 sysvinit 的缺点。采用事件驱动模型, UpStart 可以

>1. 更快地启动系统
>2. 当新硬件被发现时动态启动服务
>3. 硬件被拔除时动态停止服务
>4. 这些特点使得 UpStart 可以很好地应用在桌面或者便携式系统中,处理这些系统中的动态硬件插拔特性

>[返回目录](#目录)

### 2_4
### 及运行级别


Upstart 系统中的运行级别
Upstart 的运作完全是基于工作和事件的。工作的状态变化和运行会引起事件,进而触发其它工作和事件。
而传统的 Linux 系统初始化是基于运行级别的,即 SysVInit 。因为历史的原因, Linux 上的多数软件还是采用传统的 SysVInit 脚本启动方
式,并没有为 UpStart 开发新的启动脚本,因此即便在 Debian 和 Ubuntu 系统上,还是必须模拟老的 SysVInit 的运行级别模式,以便和
多数现有软件兼容。

虽然 Upstart 本身并没有运行级别的概念,但完全可以用 UpStart 的工作模拟出来。让我们完整地考察一下 UpStart 机制下的系统启动过
程。

```
1. 系统上电后运行 GRUB 载入内核。
2. 内核执行硬件初始化和内核自身初始化。在内核初始化的最后,内核将启动 pid 为 1 的 init 进程,即UpStart 进程。
3. Upstart 进程在执行了一些自身的初始化工作后,立即发出 ”startup” 事件。
4. 所有依赖于 ”startup” 事件的工作被触发
5. 任务 rc-sysinit 会被触发
6. 任务 rc-sysinit 调用 telinit 。 Telinit 任务会发出 runlevel 事件,触发执行 /etc/init/rc.conf 。
7. rc.conf 执行 /etc/rc$.d/ 目录下的所有脚本,和 SysVInit 非常类似
```

在 Upstart 系统中,需要修改 /etc/init/rc-sysinti.conf 中的 DEFAULT_RUNLEVEL 这个参数,以便修改默认启动运行级别。这一点和
sysvinit 的习惯有所不同。

>[返回目录](#目录)

### 2_5
### 需要了解的 Upstart 命令

作为系统管理员,一个重要的职责就是管理系统服务。比如系统服务的监控,启动,停止和配置。 UpStart 提供了一系列的命令来完
成这些工作。其中的核心是 initctl ,这是一个带子命令⻛格的命令行工具

service 命令和 initctl 命令对照表
|Service命令 |UpStart initctl命令|
|-----------|-------------------|
|service start| initctl start|
|service stop |initctl stop|
|service restart| initctl restart|
|service reload |initctl reload|

一些命令是为了兼容其它系统 ( 主要是 sysvinit) ,比如显示 runlevel 用 /sbin/runlevel 命令



>[返回目录](#目录)

----------

## 3
## 第三部分 – Systemd

### 3_1
### Systemd的简介和特点

是 Linux 系统中最新的初始化系统 (init) ,它主要的设计目标是克服 sysvinit 固有的缺点,提高系统的启动速度。 systemd 和ubuntu 的 upstart 是竞争对手,预计会取代 UpStar。

Systemd 的很多概念来源于苹果 MacOS 操作系统上的 launchd ,不过 launchd 专用于苹果系统,因此⻓期未能获得应有的广泛关注。
Systemd 借鉴了很多 launchd 的思想,它的重要特性如下:

1.  同 SysVinit 和 LSB initscripts 兼容
2.  更快的启动速度    
  提供了比 UpStart 更激进的并行启动能力,采用了 socket/D-Bus activation 等技术启动服务。一个显而易⻅的结果就是:更快
的启动速度

3.  Systemd 提供按需启动能力   
	Systemd 可以提供按需启动的能力,只有在某个服务被真正请求的时候才启动它。当该服务结束, systemd 可以关闭它,等待下次需
要时再次启动它。

4.  采用 Linux 的 Cgroup 特性跟踪和管理进程的生命周期    
	CGroup 已经出现了很久,它主要用来实现系统资源配额管理。 CGroup 提供了类似文件系统的接口,使用方便。当进程创建子进程
时,子进程会继承父进程的 CGroup 。因此无论服务如何启动新的子进程,所有的这些相关进程都会属于同一个 CGroup , systemd 只
需要简单地遍历指定的 CGroup 即可正确地找到所有的相关进程,将它们一一停止即可。

5.  启动挂载点和自动挂载的管理    
	Systemd 内建了自动挂载服务,无需另外安装 autofs 服务,可以直接使用 systemd 提供的自动挂载管理能力来实现 autofs 的功能。

6.  实现事务性依赖关系管理    
	systemd 维护一个 ” 事务一致性 ” 的概念,保证所有相关的服务都可以正常启动而不会出现互相依赖,以至于死锁的情况。

7.  能够对系统进行快照和恢复    
	Systemd支持按需启动,因此系统的运行状态是动态变化的,人们无法准确地知道系统当前运行了哪些服务。 Systemd 快照提供了一
种将当前系统运行状态保存并恢复的能力。

8.  日志服务    
	Systemd自带日志服务 journald ,该日志服务的设计初衷是克服现有的 syslog 服务的缺点。

>[返回目录](#目录)

### 3_2
### Systemd 的基本概念

#### 3_2_1
#### 单元的概念

系统初始化需要做的事情非常多。需要启动后台服务,比如启动 sshd 服务;需要做配置工作,比如挂载文件系统。这个过程中的每一
步都被 systemd 抽象为一个配置单元,即 unit 。可以认为一个服务是一个配置单元;一个挂载点是一个配置单元;一个交换分区的配
置是一个配置单元;等等。

Systemd 将配置单元归纳为以下一些不同的类型(配置单元类型可能在不久的将来继续增加)

|类型|含义|
|---|---|
|service |:代表一个后台服务进程,比如 mysqld 。这是最常用的一类|
|socket |:此类配置单元封装系统和互联网中的一个套接字。|
|device |:此类配置单元封装一个存在于 Linux 设备树中的设备。|
|mount |:此类配置单元封装文件系统结构层次中的一个挂载点。|
|automount |:此类配置单元封装系统结构层次中的一个自挂载点。|
|target |:此类配置单元为其他配置单元进行逻辑分组。|
|timer|:定时器配置单元用来定时触发用戶定义的操作,这类配置单元取代了 atd 、 crond 等传统的定时服务。|
|snapshot| :与 target 配置单元相似,快照是一组配置单元。它保存了系统当前的运行状态。|

每个配置单元都有一个对应的配置文件,系统管理员的任务就是编写和维护这些不同的配置文件,比如一个 MySQL 服务对应一个
mysql.service 文件。这种配置文件的语法非常简单,用戶不需要再编写和维护复杂的系统 5 脚本了。


>[返回目录](#目录)


#### 3_2_2
#### 依赖关系

虽然 systemd 将大量的启动工作解除了依赖,使得它们可以并发启动。但还是存在有些任务,它们之间存在天生的依赖,不能用 “ 套接
字激活 ”(socket activation) 、 D-Bus activation 和 autofs 三大方法来解除依赖(三大方法详情⻅后续描述)。

为了解决这类依赖问题, systemd 的配置单元之间可以彼此定义依赖
关系。Systemd 用配置单元定义文件中的关键字来描述配置单元之间的依赖关系。比如: unit A 依赖 unit B ,可以在 unit B 的定义中用 ”require A” 来表示。这样 systemd 就会保证先启动 A 再启动 B 。


>[返回目录](#目录)


#### 3_2_3
#### Systemd 事务
Systemd能保证事务完整性。 Systemd 的事务概念和数据库中的有所不同,主要是为了保证多个依赖的配置单元之间没有环形引用。

存在循环依赖,那么 systemd 将无法启动任意一个服务。此时 systemd 将会尝试解决这个问题,因为配置单元之间的依赖关系有两种: required 是强依赖; want 则是弱依赖, systemd 将去掉 wants 关键字指定的依赖看看是否能打破循环。如果无法修复, systemd 会报错。

Systemd 能够自动检测和修复这类配置错误,极大地减轻了管理员的排错负担。

>[返回目录](#目录)

#### 3_2_4
#### Target 和运行级别

Systemd用目标 (target) 替代了运行级别的概念,提供了更大的灵活性,如您可以继承一个已有的目标,并添加其它服务,来创建自己的目标。下表列举了 systemd 下的目标和常⻅ runlevel 的对应关系:

|Sysvinit运行级别|Systemd目标|备注|
|-----|-----|---|
|0 |runlevel0.target, poweroff.target | 关闭系统。|
|1, s, single |runlevel1.target, rescue.target |单用戶模式。 |
| 2, 4| runlevel2.target, runlevel4.target, multi-user.target|用戶定义 / 域特定运行级别。默认等同于 3 。 |
|3 |runlevel3.target, multi-user.target |多用戶,非图形化。用戶可以通过多个控制台或网络登录。 |
|5 |runlevel5.target, graphical.target |多用戶,图形化。通常为所有运行级别 3 的服务外加图形化登录。 |
|6 |runlevel6.target, reboot.target | 重启|
|emergency | emergency.target| 紧急 Shell|

>[返回目录](#目录)

#### 3_2_5
#### Systemd 的并发启动原理

Systemd 的开发人员仔细研究了服务之间相互依赖的本质问题,发现所谓依赖可以分为三个具体的类型,而每一个类型实际上都可以
通过相应的技术解除依赖关系。

1.  并发启动原理之一:解决 socket 依赖    
	绝大多数的服务依赖是套接字依赖。Systemd 认为,只要我们预先把 S1 建立好,那么其他所有的服务就可以同时启动而无需等待服务 A
来创建 S1 了。如果服务 A 尚未启动,那么其他进程向 S1 发送的服务请求实际上会被 Linux 操作系统缓存,其他进程会在这个请求的地
方等待。一旦服务 A 启动就绪,就可以立即处理缓存的请求,一切都开始正常运行。

2.  并发启动原理之二:解决 D-Bus 依赖     
    D-Bus 是 desktop-bus 的简称,是一个低延迟、低开销、高可用性的进程间通信机制。它越来越多地用于应用程序之间通信,也用于应
用程序和操作系统内核之间的通信。D-Bus 支持所谓 ”bus activation” 功能。如果服务 A 需要使用服务 B 的 D-Bus 服务,而服务 B 并没有运行,则 D-Bus 可以在服务 A 请求服务B 的 D-Bus 时自动启动服务 B 。而服务 A 发出的请求会被 D-Bus 缓存,服务 A 会等待服务 B 启动就绪。利用这个特性,依赖 D-Bus 的服务
就可以实现并行启动。

3.  并发启动原理之三:解决文件系统依赖    
    Systemd 参考了 autofs 的设计思路,使得依赖文件系统的服务和文件系统本身初始化两者可以并发工作。 autofs 可以监测到某个文件
系统挂载点真正被访问到的时候才触发挂载操作,这是通过内核automounter 模块的支持而实现的。比如一个 open() 系统调用作用在 ”/misc/cd/file1′′ 的时候, /misc/cd 尚未执行挂载操作,此时 open() 调用被挂起等待, Linux 内核通知 autofs , autofs 执行挂载。这时候,控制权返回给 open() 系统调用,并正常打开文件。当然对于 / 根目录的依赖实际上一定还是要串行执行,因为 systemd 自己也存放在 / 之下,必须等待系统根目录挂载检查好。


>[返回目录](#目录)


### 3_3
### Systemd 的使用

下面针对技术人员的不同⻆色来简单地介绍一下 systemd 的使用。

#### 3_3_1
#### 系统软件开发人员
开发人员需要了解 systemd 的更多细节。比如您打算开发一个新的系统服务,就必须了解如何让这个服务能够被 systemd 管理。这需要您注意以下这些要点:

```
1. 后台服务进程代码不需要执行两次派生来实现后台精灵进程,只需要实现服务本身的主循环即可。
2. 不要调用 setsid() ,交给 systemd 处理
3. 不再需要维护 pid 文件。
4. Systemd 提供了日志功能,服务进程只需要输出到 stderr 即可,无需使用 syslog 。
5. 处理信号 SIGTERM ,这个信号的唯一正确作用就是停止当前服务,不要做其他的事情。
6. SIGHUP 信号的作用是重启服务。
7. 需要套接字的服务,不要自己创建套接字,让 systemd 传入套接字。
8. 使用 sd_notify() 函数通知 systemd 服务自己的状态改变。一般地,当服务初始化结束,进入服务就绪状态时,可以调用它。
```

Unit 文件的编写

对于开发者来说,工作量最大的部分应该是编写配置单元文件,定义所需要的单元。

以SSH 服务的配置单元文件文件为例：
```
#cat /etc/system/system/sshd.service
[Unit]
Description=OpenSSH server daemon
[Service]
EnvironmentFile=/etc/sysconfig/sshd
ExecStartPre=/usr/sbin/sshd-keygen
ExecStart=/usrsbin/sshd –D $OPTIONS
ExecReload=/bin/kill –HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s
[Install]
WantedBy=multi-user.target

分为三个小节。
第一个是 [Unit] 部分,这里仅仅有一个描述信息。

第二部分是 Service 定义,其中, ExecStartPre 定义启动服务之
前应该运行的命令; ExecStart 定义启动服务的具体命令行语法。

第三部分是 [Install] , WangtedBy 表明这个服务是在多用戶模式下所
需要的。
```

>[返回目录](#目录)


#### 3_3_2
#### 系统管理员
Systemd的主要命令行工具是 systemctl 。

多数管理员应该都已经非常熟悉系统服务和 init 系统的管理,比如 service 、 chkconfig 以及telinit 命令的使用。 Systemd 也完成同样的管理任务,只是命令工具 systemctl 的语法有所不同而已,因此用表格来对比 systemctl 和传统的系统管理命令会非常清晰。

|Sysvinit命令|Systemd命令| 备注 |
|--------|:------|---------|
|service foo start |systemctl start foo.service |用来启动一个服务 ( 并不会重启现有的 )|
| service foo stop|systemctl stop foo.service | 用来停止一个服务 ( 并不会重启现有的 ) 。|
|service foo restart | systemctl restart foo.service| 用来停止并启动一个服务。|
|service foo reload | systemctl reload foo.service|当支持时,重新装载配置文件而不中断等待操作。 |
|service foo condrestart |systemctl condrestart foo.service | 如果服务正在运行那么重启它。|
|service foo status |systemctl status foo.service |汇报服务是否正在运行。 |
|ls /etc/rc.d/init.d/ | systemctl list-unit-files --type=service|用来列出可以启动或停止的服务列表。 |
|chkconfig foo on |systemctl enable foo.service |在下次启动时或满足其他触发条件时设置服务为启用 |
|chkconfig foo off |systemctl disable foo.service |在下次启动时或满足其他触发条件时设置服务为禁用 |
|chkconfig foo |systemctl is-enabled foo.service | 用来检查一个服务在当前环境下被配置为启用还是禁用。|
|chkconfig --list |systemctl list-unit-files --type=service |输出在各个运行级别下服务的启用和禁用情况 |
|chkconfig foo --list |ls /etc/systemd/system/\*.wants/foo.service | 用来列出该服务在哪些运行级别下启用和禁用。|
|chkconfig foo --add |systemctl daemon-reload |当您创建新服务文件或者变更设置时使用。 |
|telinit 3 |systemctl isolate multi-user.target (OR systemctl isolate runlevel3.target OR telinit 3) | 改变至多用戶运行级别。|


systemd 电源管理命令

|命令|操作|
|--|--|
|systemctl reboot |重启机器 |
|systemctl poweroff | 关机|
|systemctl suspend | 待机|
|systemctl hibernate |休眠 |
|systemctl hybrid-sleep |混合休眠模式(同时休眠到硬盘并待机)|

关机不是每个登录用戶在任何情况下都可以执行的,一般只有管理员才可以关机。正常情况下系统不应该允许 SSH 远程登录的用戶执行关机命令。否则其他用戶正在工作,一个用戶把系统关了就不好了。为了解决这个问题,传统的 Linux 系统使用 ConsoleKit 跟踪用戶登录情况,并决定是否赋予其关机的权限。

现在 ConsoleKit 已经被 systemd 的 logind 所替代。

**logind** 不是 pid-1 的 init 进程。它的作用和 UpStart 的 sessioninit 类似,但功能要丰富很多,它能够管理几乎所有用戶会话 (session) 相关的事情。 logind 不仅是 ConsoleKit 的替代,它可以
```
1. 维护,跟踪会话和用戶登录情况。
2. Logind 也负责统计用戶会话是否⻓时间没有操作,可以执行休眠 / 关机等相应操作。
3. 为用戶会话的所有进程创建 CGroup 。
4. 负责电源管理的组合键处理,比如用戶按下电源键,将系统切换至睡眠状态。
5. 多席位 (multi-seat) 管理。如今的电脑,即便一台笔记本电脑,也完全可以提供多人同时使用的计算能力。
```

以上描述的这些管理功能仅仅是 systemd 的部分功能,除此之外, systemd 还负责系统其他的管理配置,比如配置网络, Locale 管
理,管理系统内核模块加载等。



>[返回目录](#目录)

----------
