#!/bin/bash

ROOT=$1
NTPSERVER=$2
if [ ! -n "$ROOT" ];then
   exit 40
fi

#system check
function check_linux_system(){
    linux_version=$(cat /etc/redhat-release)
    if [[ ${linux_version} =~ "CentOS" ]];then
       echo OK > /dev/null
    else
       echo -e "\033[32;32m system is not Centos, this script only run on centos\033[0m"
       exit 1
    fi
}


function epel(){
    yum install epel-release -y >/dev/null 2>&1
    sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel.repo
    sed -i 's/#baseurl/baseurl/g' /etc/yum.repos.d/epel.repo
    sed -i '6s/enabled=0/enabled=1/g' /etc/yum.repos.d/epel.repo
    sed -i '7s/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/epel.repo
    yum clean all >/dev/null 2>&1
}


function ulimits(){
cat > /etc/security/limits.conf << ENDOF
* soft noproc 65536
* hard noproc 65536
* soft nofile 65536
* hard nofile 65536
* soft memlock  unlimited
* hard memlock  unlimited
ENDOF
echo > /etc/security/limits.d/20-nproc.conf
ulimit -n 65536
ulimit -u 65536
}



function ssh(){
   [ -f /etc/ssh/sshd_config ]  && sed -ir '13 iUseDNS no\nGSSAPIAuthentication no' /etc/ssh/sshd_config && systemctl restart  sshd >/dev/null 2>&1
}


function add_lsmod(){
cat > /etc/modules-load.d/k8s.conf << ENDOF
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack_ipv4
ip_conntrack
br_netfilter
ip_set
ip_tables
ip6_tables
ipt_REJECT
ipt_rpfilter
ipt_set
nf_conntrack_netlink
sctp
xt_addrtype
xt_comment
xt_conntrack
xt_ipvs
xt_mark
xt_multiport
xt_sctp
xt_set
xt_u32
ipip
ENDOF
for i in $(cat /etc/modules-load.d/k8s.conf)
do
   /usr/sbin/modprobe $i || (echo "modprobe $i failed!";exit 43)
done
}


function kernel_add(){
cat > /etc/sysctl.conf <<ENDOF
fs.file-max = 655350
fs.nr_open = 655350
fs.inotify.max_user_watches = 655350
net.core.netdev_max_backlog = 65535
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.somaxconn = 65535
net.core.wmem_default = 8388608
net.core.wmem_max = 16777216
net.ipv4.conf.all.arp_ignore = 0
net.ipv4.conf.lo.arp_announce = 0
net.ipv4.conf.lo.arp_ignore = 0
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_forward = 1
net.netfilter.nf_conntrack_max = 65535
net.nf_conntrack_max = 65535
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
vm.overcommit_memory = 1
vm.panic_on_oom = 0
ENDOF
sysctl -p >/dev/null || (echo "Kernel optimization failed!";exit 34)
}



function security(){
    setenforce 0 &> /dev/null
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
    systemctl stop firewalld.service
    systemctl disable firewalld.service &> /dev/null
}


function swap_off(){
    /usr/sbin/swapoff -a || (echo "swapoff failed!";exit 4)
}


function yum_install(){
    yum install -y conntrack-tools conntrack sysstat ipset ipvsadm tar rsync ntpdate net-tools lvm2 nfs-utils curl yum-utils device-mapper-persistent-data &> /dev/null
    yum install -y vim wget lrzsz telnet traceroute iotop tree >/dev/null 2>&1
    yum install -y ncftp axel git zlib-devel openssl-devel unzip xz libxslt-devel libxml2-devel libcurl-devel libseccomp libtool-ltdl >/dev/null 2>&1
}



function timezone(){
  /usr/bin/timedatectl set-timezone Asia/Shanghai
  /usr/bin/timedatectl set-local-rtc 0
}

function del_search(){
  sed -i '/^search/d' /etc/resolv.conf
}


function mkdir_dir(){
   mkdir -p $ROOT/{certs/{kubeconfig,ssl,kubelet},script,logs/{docker,kubelet,kube-proxy,kube-apiserver,kube-controller-manager,kube-scheduler,etcd},data/{docker,kubelet,etcd},etc}
   mkdir -p ~/.kube
   mkdir -p /etc/docker
   mkdir -p /etc/systemd/system/docker.service.d
}


export -f check_linux_system
export -f epel
export -f ulimits
export -f ssh
export -f kernel_add
export -f security
export -f yum_install
export -f add_lsmod
export -f swap_off
export -f mkdir_dir
#export -f ntp_sync
export -f del_search



check_linux_system
yum_install || (echo -e "yum install failed!";exit 34)
add_lsmod || (echo -e "lsmod add failed!";exit 35)
swap_off
#epel
ulimits
#ssh
kernel_add  || (echo -e "kernel apply failed!";exit 36)
security
mkdir_dir
del_search
ntpdate $2 &> /dev/null
