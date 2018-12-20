#!/bin/bash

if [ ! $# -eq 1 ]; then
    echo bash ./install-nginx.sh x.x.x.x/24
    echo x.x.x.x is your ssh client network
    echo such as 202.38.64.0/24
    exit
fi

if [ -f /etc/nginx/nginx.conf ]; then
	echo "/etc/nginx/nginx.conf exist, exit";
	exit
fi

id | grep root 
retcode=$?
if [ $retcode -eq 1 ]; then
	echo you are not using root
	exit
fi

echo install nginx
echo ssh client is $1

echo ============= step 3
timedatectl set-timezone Asia/Shanghai

echo ============= step 4
ufw enable
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow proto tcp from $1 to any port 22
ufw default deny

echo ============= step 5.1
echo nf_conntrack_ipv4 >> /etc/modules
echo nf_conntrack_ipv6 >> /etc/modules

echo ============= step 5.2
echo "options nf_conntrack hashsize=50000" > /etc/modprobe.d/nf_conntrack.conf

echo ============= step 5.3
mkdir /etc/systemd/system/nginx.service.d/
echo "[Service]" > /etc/systemd/system/nginx.service.d/limit.conf
echo "LimitNOFILE=655360" >> /etc/systemd/system/nginx.service.d/limit.conf

echo ============= step 5.4
echo "fs.file-max = 655360" >> /etc/sysctl.conf

echo ============= step 5.5
cat << EOF > /etc/sysctl.d/90-conntrack.conf
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
EOF

echo ============= step 6
apt install -y nginx git

echo ============= step 7.2
sudo mkdir /etc/nginx/ssl
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

echo ============= step 7.3
cd /etc/nginx
mv nginx.conf nginx.system.conf
wget https://raw.githubusercontent.com/bg6cq/nginx-install/master/nginx.conf


echo end of script
echo now please do a reboot!!!
echo 
echo after boot up, please do the following
echo vi /etc/nginx/nginx.conf
echo nginx -t
echo 
