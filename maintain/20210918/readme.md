
# 香山4修改scada配置说明

修改内容为:

```
 1.将scada配置文件中原来的“可用功率”改为“理论功率”
 2.将scada配置文件中原来的“可用功率*0.956”改为“可用功率”

```

预计在 2021-09-19 号对现场进行修改

## 修改操作执行操作过程

> 修改操作请用 root 用户登录 scada服务器进行操作

1. 将修改脚本的压缩包`xs4md210918.zip`导入scada服务器的/zfmd/wpfs20/backup目录下;
2. 将压缩包`xs4md210918.zip`在服务上解压；
3. 在解压后的目录下打开终端执行如下命令:

```
#给操作脚本赋权
chmod  u+x   xs4md210918.sh

#执行脚本对scada配置文件进行修改
./xs4md210918.sh   /zfmd/wpfs20/scada/scdCfg.xml
```

在执行脚本时观察执行的结果，如果有如下字样则表示执行成功:(提示执行结果中backup字样后的文件是备份修改之前的配置文件)

```
backup file:/zfmd/wpfs20/scada/scdCfg.xml --> file:/zfmd/wpfs20/scada/scdCfg.xml.back.20210918_3322236

Edit the /zfmd/wpfs20/scada/scdCfg.xml file successfully 
```

4. 如果脚本执行成功则重启scada程序,重启时可以用如下命令（提示如果没有如下命令可以手动结果scada进程进行重启)

```
#重启scada程序的命令
run_scada   --restart
```
 
