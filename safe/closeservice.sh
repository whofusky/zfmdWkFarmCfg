#!/bin/sh


echo "关闭服务：文件系统自动加载和卸载，自动挂载文件系统或外设(如USB、光驱等)"
chkconfig autofs off

#echo "邮件服务器相关"
#chkconfig dovecot off

echo "关闭服务：安装和卸载NFS、SAMBA和NCP网络文件系统，系统启动时自动挂载网络文件系统"
chkconfig netfs off

echo "关闭服务：NFS Network File System"
chkconfig nfs off
chkconfig nfs-rdma off
chkconfig nfslock off

#echo "自动对时工具，网络对时服务"
#chkconfig ntpdate off

echo "关闭服务：替代sendmail的邮件服务器"
chkconfig postfix off

echo "关闭服务：拨号网络"
chkconfig pppoe-server off

echo "关闭服务：Redhat注册更新服务"
chkconfig rhnsd off

echo "关闭服务：Redhat升级服务"
chkconfig rhsmcertd off

echo "关闭服务：VNC服务"
chkconfig vncserver off

#echo "FTP服务器程序"
#chkconfig vsftpd off

echo "关闭服务：x web邮件系统World2.1的一部分,用来提供HTTP接口Client"
chkconfig wdaemon off

#echo "一种安装在邮件伺服主机上的邮件过滤器"
#chkconfig spamassassin off
