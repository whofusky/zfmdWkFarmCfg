
# ntp 校时


ntp 校时采用的协议是 udp,所用端口为 123

配置文件:

```
/etc/ntp.conf
/etc/sysconfig/ntpd
```

## 0.添加ntp服务器ip

在打开的配置文件(/etc/ntp.conf)把带server行中无用的服务器配置注释掉（在行首加#号）
然后添加想添加的服务器，格式如下:

```
server 202.112.10.36 
server cn.pool.ntp.org
```

在打开的配置文件(/etc/sysconfig/ntpd)添加如下配置

```
SYNC_HWCLOCK=yes # 将他改成 yes 这样 BIOS 的时间也会跟着改变的！
```

# 1.启动ntpd服务

先使用ntpdate手动同步下时间，免得本机与外部时间服务器时间差距太大，让ntpd不能正常同步。在终端下输入如下命令

```
#下面的ntp服务器需要根据实际情况变动
ntpdate -u cn.pool.ntp.org
```

同步系统时间到硬件时间

```
hwclock --systohc
```

服务启动ntpd服务,不同版本的系统命令不一样，常用的如下:

```
service ntpd start
#或
systemctl start ntpd.service
```

查看ntpd服务启动的状态:

```
servcie ntpd status
#或
systemctl status ntpd.service
```

## 2.查看ntp校时状态

一般需要5-10分钟左右的时候才能与外部时间服务器开始同步时间。可以通过命令查询NTPD服务情况:

```
ss -aunp|column -t|grep ntpd
```

ntpq -p 查看网络中的NTP服务器，同时显示客户端和每个服务器的关系

```
ntpq -p
```

ntpstat 命令查看时间同步状态，这个一般需要5-10分钟后才能成功连接和同步

```
ntpstat
```


## 3.设置ntpd 开机自启动

不同版本的系统命令不一样，常用的如下:

```
chkconfig ntpd on
#或
systemctl enable  ntpd.service
```
