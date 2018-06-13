## [原创]step-by-step install nginx反向代理服务器(unbutu 18.04 LTS)

本文原创：

* **中国科学技术大学 张焕杰**
* **厦门大学 郑海山**

修改时间：2018.06.13

## 一、unbutu 18.04 LTS安装

获取安装包 iso，您可以从以下站点获取 `ubuntu-18.04-live-server-amd64.iso`，文件大小大约是806MB。

* [中国科大镜像站](http://mirrors.ustc.edu.cn/ubuntu-releases/18.04/)
* [上海交大镜像站](http://ftp.sjtu.edu.cn/ubuntu-cd/18.04/)
* [163镜像站](http://mirrors.163.com/ubuntu-releases/18.04/)

说明：这里还有个安装程序，更加灵活，熟练人士可以选择 [中国科大镜像站](http://mirrors.ustc.edu.cn/ubuntu-cdimage/releases/18.04/release/)。

使用物理服务器或新建虚拟机，如果使用虚拟机，选择4个虚拟CPU，2G内存，40G硬盘一般就够用，类型可以选Ubuntu Linux(64-bit)。

使用光盘镜像引导，安装即可，一般在10分钟内完成。如果有疑问，可以参考 
[Ubuntu 18.04 Server 版安装过程图文详解](https://blog.csdn.net/zhengchaooo/article/details/80145744)。

安装时，如果设置了网络，安装过程中会连接官方服务器获取最新的软件包，因此请保持网络畅通。

如果安装时没有设置网络，请参见下面的 配置网络部分。

注意：Ubuntu 系统要求必须使用一个普通用户登录，执行需要特权的命令时，使用`sudo ....`来临时切换为root用户进行。如果需要以root身份执行较多的命令，可以使用`sudo su -`切换为root用户（虽然不建议这样做），这样一来就不需要每次输入`sudo`了。

安装完的系统占用磁盘空间为3.5G（可以用`df`查看）。

## 二、配置网络

反向代理服务器需要IPv4/IPv6的连通性，对外需要开放22、80、443端口，如果您有防火墙，请放开这些端口。

使用安装时设置的普通用户登录系统，使用以下命令测试网络是否正常：
```
ip add    #查看网卡设置的ipv4/ipv6地址
ip route  #查看ipv4网关
ip -f inet6 route #查看ipv6网关
ping 202.38.64.1  #检查ipv4连通性
ping6 2001:da8:d800::1 #检查ipv6连通性
```
如果网络存在问题，请按照以下说明修改配置，直到网络正常。

Ubuntu网络配置与之前的变化较大，采用netplan管理，配置文件存放在`/etc/netplan/*.yaml`。

下面是我使用的例子，文件是`/etc/netplan/50-cloud-init.yaml`，内容如下：

请根据自己的网络情况，修改文件，修改后执行`sudo netplan apply`应用即可。

```
udo ufw enable
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw allow proto tcp from 202.38.64.0/24 to any port 22
sudo ufw default deny
etwork:
    version: 2
    ethernets:
        ens160:
            dhcp4: no
            addresses: [222.195.81.200/24,'2001:da8:d800:381::200/64']
            gateway4: 222.195.81.1
            nameservers:
                    addresses: [202.38.64.1,202.38.64.56]

```

检查点：上述ping之类的命令测试网络正常。

# 注意：以下 三--七 部分有快捷脚本可用，请参见 十、快捷脚本 

## 三、设置系统时区

默认安装的系统时区是UTC，以下命令可以修改为北京时间：
```
sudo timedatectl set-timezone Asia/Shanghai
```

## 四、设置防火墙

安全是第一要务，对于nginx服务器，对外需开通80、443端口，对部分地址开通22端口以方便管理。

使用如下命令设置，请根据自己的管理地址段，替换下面的`202.38.64.0/24`
```
sudo ufw enable
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow proto tcp from 202.38.64.0/24 to any port 22
sudo ufw default deny
```
您可以使用命令`sudo ufw status numbered`查看设置的规则，如果设置错误，可以使用`sudo ufw delete [序号]`删除规则。

如果您有强烈的好奇心，可以执行`sudo iptables -L -nv | more`看看系统实际使用的规则。

检查点：命令`sudo ufw status`能看到设置的规则。

## 五、优化conntrack性能

Linux系统防火墙需要使用conntrack模块记录tcp/udp的连接信息，默认的设置(最多6万连接)不太适合反向代理这种服务使用。

5.1 编辑文件`sudo vi /etc/modules`，增加2行：
```
nf_conntrack_ipv4
nf_conntrack_ipv6
```

5.2 编辑文件`sudo vi /etc/modprobe.d/nf_conntrak.conf`，增加1行(按照以下设置，最多40万连接)：
```
options nf_conntrack hashsize=50000
```

5.3 编辑文件`sudo vi /etc/security/limits.conf`，增加4行：
```
*               soft    nofile  655360
*               hard    nofile  655360
root            soft    nofile  655360
root            hard    nofile  655360
```

5.4 编辑文件`sudo /etc/sysctl.d/90-conntrack.conf`，内容为：
```
net.netfilter.nf_conntrack_dccp_timeout_closereq = 60
net.netfilter.nf_conntrack_dccp_timeout_closing = 60
net.netfilter.nf_conntrack_dccp_timeout_open = 200
net.netfilter.nf_conntrack_dccp_timeout_partopen = 60
net.netfilter.nf_conntrack_dccp_timeout_request = 60
net.netfilter.nf_conntrack_dccp_timeout_respond = 60
net.netfilter.nf_conntrack_dccp_timeout_timewait = 60
net.netfilter.nf_conntrack_frag6_timeout = 10
net.netfilter.nf_conntrack_generic_timeout = 60
net.netfilter.nf_conntrack_icmp_timeout = 10
net.netfilter.nf_conntrack_icmpv6_timeout = 10
net.netfilter.nf_conntrack_sctp_timeout_closed = 10
net.netfilter.nf_conntrack_sctp_timeout_cookie_echoed = 3
net.netfilter.nf_conntrack_sctp_timeout_cookie_wait = 3
net.netfilter.nf_conntrack_sctp_timeout_established = 300
net.netfilter.nf_conntrack_sctp_timeout_heartbeat_acked = 300
net.netfilter.nf_conntrack_sctp_timeout_heartbeat_sent = 30
net.netfilter.nf_conntrack_sctp_timeout_shutdown_ack_sent = 3
net.netfilter.nf_conntrack_sctp_timeout_shutdown_recd = 0
net.netfilter.nf_conntrack_sctp_timeout_shutdown_sent = 0
net.netfilter.nf_conntrack_tcp_timeout_close = 10
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 10
net.netfilter.nf_conntrack_tcp_timeout_established = 600
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 60
net.netfilter.nf_conntrack_tcp_timeout_max_retrans = 60
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 30
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 30
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_unacknowledged = 30
net.netfilter.nf_conntrack_udp_timeout = 10
net.netfilter.nf_conntrack_udp_timeout_stream = 30
```

设置完成后，重启系统。

检查点：重启后执行`dmesg | grep conn`会显示最大连接数为40万，`more /proc/sys/net/netfilter/*timeout*`会显示修改后的超时时间。

检查点：执行`ulimit -a`，显示的`open files`是655360

## 六、安装nginx

执行`sudo apt-get install -y nginx`即可。

## 七、修改nginx配置

建议使用git跟踪配置的变化。

7.1 使用如下命令初始化（请修改自己的个人信息）：
```
git config --global user.email "james@ustc.educ.cn"
git config --global user.name "Zhang Huanje"

cd /etc/nginx
git init
git add *
git commit -m init
```

7.2 生成nginx需要的随机数（需要大约几分钟以搜集足够的随机信息）：
```
sudo mkdir /etc/nginx/ssl
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
```

7.3 下载配置文件模板。我们准备了一份模板，稍许修改就可以使用。

```
cd /etc/nginx
sudo mv nginx.conf nginx.system.conf
sudo wget https://raw.githubusercontent.com/bg6cq/nginx-install/master/nginx.conf
```

7.4 修改配置文件`sudo vi nginx.conf`，修改最后面配置，使用自己学校的主机名、日志文件名、IP地址。

7.5 测试配置是否正确，下面是测试正确的显示：
```
sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

7.6 如果测试正确，执行以下命令应用配置：
```
systemctl restart nginx.service
```

## 八、测试

在自己机器上修改hosts文件，如下所示(请用自己的替换)：
```
222.195.81.200 www.ustc.edu.cn
2001:da8:d800:381::200 www.ustc.edu.cn
```
修改后测试是否可以访问，并可以查看nginx服务器上`/var/log/nginx/`下的日志文件，看到有访问记录。

## 九、启用IPv6访问

经过测试访问正常后，可以修改DNS服务器上www.ustc.edu.cn的信息，增加

```
www	IN	AAAA	2001:da8:d800:381::200
````
这样就能观察到IPv6的访问，过一会查看 https://ipv6.ustc.edu.cn 的测试能看到v6 HTTP已经正常。

## 十、快捷脚本

以上 三---七 部分，有快捷脚本可用，只要完成二配置，网络通了的情况，执行以下脚本即可完成大部分配置，只要修改配置文件即可。

注意，执行脚本时，请根据自己的信息替换参数。

```
sudo su -
cd /
wget http://202.38.64.1/install-nginx.sh

bash ./install-nginx.sh yes 202.38.95.0/24 james@ustc.edu.cn "Zhang Huanjie"
```

执行完脚本，重新启动，然后请参考 7.4 修改配置和后续工作

## 十一、后续更精彩

陆续有Let's encrypt 证书申请，https开通。

***
欢迎 [加入我们整理资料](https://github.com/bg6cq/ITTS)
