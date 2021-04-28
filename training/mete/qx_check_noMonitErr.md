
# 2.0气象下载器未配置monitErr.sh的问题

## 背景

monitErr.sh此脚本一般位于/zfmd/wpfs20/mete/bin/目录下，作用为：监视气象下载器是
否异常，如果异常，则重启气象下载器程序，使之恢复正常。

## 查检是否缺少配置的方法

在zfmd下打开终端执行:`crontab  -l` 如出现如下结果则正常

```
#以下内容在1行上而非2行
* * * * * /zfmd/wpfs20/startup/proRunChk.sh >>/zfmd/wpfs20/startup/log/cron_proRunChk.log 2>&1
#以下内容在1行上而非2行
* * * * * sleep 34 && /zfmd/wpfs20/mete/bin/monitErr.sh >>/zfmd/wpfs20/mete/log/monitErr_sh.log 2>&1
```

**如果没有monitErr.sh这一行的配置则说明未配置monitErr.sh**
    
## 出现未配置monitErr.sh的原因

在部署现场的时候，如果先配置气象，后配置自启动脚本，自启动脚本部署过程中会自动
把monitErr.sh的crontab也配置好。

如果未按顺序部署就会出现monitErr.sh未配置的现象.

避免方法:
>已经更新气象下载器的部署文档，特别说明了需要检查monitErr.sh配置这一项，如再有新
风场部署可避免此问题的出现。


## 少配置可能会引发的问题

如果风场部署时没有配置monitErr.sh的crontab配置，则有可能出现如下问题

>业务清单已经正常下载，但未触发到反隔目录,导致II区场内入库收不到业务清单
>> 这种情况业务清单文件一般处于以下3个目录中的一个，但未被取走
>> 1. /zfmd/wpfs20/mete/filedo/down/ser1
>> 2. /zfmd/wpfs20/mete/filedo/down/ser2
>> 3. /zfmd/wpfs20/mete/filedo/down/yes
>>> 提示: 如果需要把未正常入库的业务清单数据入库，只需要把上面的业务清单，手动移动气象服务器的
反隔目录


## 手动添加monitErr.sh配置的方法

>说明：以下操作中1-4步在气象服务器上用root操作；第5步用zfmd用户操作

    1. 查看/zfmd/wpfs20/mete/bin/目录下是否有monitErr.sh这个文件在在

    2. 如果有monitErr.sh文件则在桌面上打开终端执行:
       gedit  /var/spool/cron/zfmd

    3. 执行第2条命令会打开一个文件，在打开的文件末尾添加一行如下内容：(以下内容在1行上而非2行)
    * * * * * sleep 34 && /zfmd/wpfs20/mete/bin/monitErr.sh >>/zfmd/wpfs20/mete/log/monitErr_sh.log 2>&1


    4. 在确认添加的内容准备无误后，保存并关闭文件。

    5. 过2分钟后按如下步骤验证一下:
      (1) crontab  -l  命令看是否有刚才添加的内容
      (2) pidof  ThrMeteM
      (3) ps   hHp  xxxxx |  wc  -l 看返回的数是否大于等于12（命令中的xxxxx是第2条命令查询返回的数字代替） 


