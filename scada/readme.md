
** 某些文件说明 **
```
.
├── rinetd.gls.20200903.tar.gz  #2020-09-3 部署scada v10.04.050版本时现场部署到/zfmd/rinetd的端口转发软件包
├── cfg_gls_onsite.cfg          #scada配置配置文件的配置文件 
├── release_log                 #存入发布新scada版本时的日志记录
├── scada_ip_info.txt           #某些ip信息
├── scdCfg.xml                  #scada 新配置文件
└── unitMemInit.xml             #scada旧配置文件
```
**变更说明**

2021-03-02 工程鞠文强    将scada的版本升级到V10.05.040

> 1.主配置文件中的端口号作了修改，因为新版本scada是根据配置文件中实际的端口号进行
> 绑定的
>
> 2.配置文件中的grpAttr=3都修改成了grpAttr=0,因为3时当物理量的值小于0时，程序将
>  值修改成了0（没有理油的乱改）
