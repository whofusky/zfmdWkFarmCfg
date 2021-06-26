
# 操作日志备注

## 2021-06-26

scada 配置文件修改：风机通道添加的端口理论功率和可用功率2个量，且这2个量不在入
系统，只是为了转发用（在此修改之前是从数据库里出库用于转发的）

替换步骤如下:

```
1. 用root用户登录scada主机操作
2. 将/zfmd/wpfs20/scada/scdCfg.xml文件备份到/zfmd/wpfs20/backup/scdCfg.xml.20210625
3. /zfmd/wpfs20/backup下新建立目录20210626
4. 将压缩包linyou_scada_cfg_20210626.zip放在 /zfmd/wpfs20/backup/20210626下面，然后解压
5. 将/zfmd/wpfs20/backup/20210626下解压后的scdCfg.xml文件覆盖/zfmd/wpfs20/scada/scdCfg.xm文件
6. 确认以上操作完成后，在桌面右键打开一个终端，执行命令  run_scada  --restart
```

因理论功率从风机系统采集得到，因此需要把预测系统的理论功率软件停掉，步骤是
先关自启动，然后再关系理论功率软件，关闭自启动的步骤如下:

```
zfmd用户登录
在/zfmd/wpfs20/startup目录下右键打开一个终端执行命令: ./stopOrStartOne.sh
然后输入1
然后输入程序名: TheoryPowerCalculate
```

