#!/usr/bin/bash
#Auth: Jack
#Date: 2021/2/12
#Version: 1.0
#Description: add node to cluster

if [ "$1" != "add" ];then
   echo -e "\033[1;31m>>>\$1 is not \"add\""
   help_addnode
elif [ ! -n "$2" ] || [ ! -d "HISTORY_BACKUP/$2" ];then
   echo -e "\033[1;31m>>>\$2 is null or HISTORY_BACKUP/$2 dir no exsit! \033[0m"
   help_addnode
elif [ ! -n "$3" ] || [ ! -f "HISTORY_BACKUP/$2/${3}.tar.gz" ];then
   echo -e "\033[1;31m>>>\$3 is null or HISTORY_BACKUP/\$2/\$3 file is not exsit! \033[0m"
   help_addnode
elif [ ! -n "$4" ];then
   echo -e "\033[1;31m>>>\$4 is null \033[0m"
   help_addnode
fi

#Generate node data file
export ROOT=/opt/k8s    #安装环境的根目录
export DIR=$(pwd)       #脚本执行的当前目录，请确保目录下有env.yml 
export SSH_PORT=22
export KUBERNETES_SVC_IP=192.168.0.1
export SCR=192.168.0.0/16
export COREDNS=192.168.0.2
export NTPSERVER=ntp1.aliyun.com
export VIP=$(grep '\<VIP\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')   #集群Master的VIP
export CIDR=$(grep '\<CIDR\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g') #集群pod_ip_range
export MASTER_LIST=($(grep '\<MASTER\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g'))  #集群MASTER的IP列表
export NODE_LIST=($(echo "$4" |sed 's/,/ /g'))  #集群NODE的IP列表
export NAMESPACES=($(grep '\<NAMESPACES\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g'))

#mkdir record dir
mkdir -p ./record/ &> /dev/null

#Connectivity check
print_out "Target host connection check"
for i in ${MASTER_LIST[0]} ${NODE_LIST[*]}
do
    timeout 5 ssh -p $SSH_PORT $i "hostname" &> /dev/null && green "$i connected" || red "cannot connect $i by ssh"
done

#env
if [ ! -f ./record/0_addnode_cleanliness_detection.ok ];then
   print_out "Target host Environmental cleanliness detection"
   for i in ${NODE_LIST[*]}
   do
     [[ $(timeout 10 ssh -p $SSH_PORT $i "netstat -anlp|grep -E '\<2379\>|\<6443\>|\<10250\>|\<10251\>|\<2380\>|\<10259\>|\<10257\>'|wc -l") -gt 0 ]] && red "Host $i port 2379|6443|10250|10251 is open,not clean"
     green "The nodes is clean and can be installed"
     touch ./record/0_addnode_cleanliness_detection.ok
   done
fi

#Target host initialization
if [ ! -f ./record/0_addnode_init_sys.ok ];then
    print_out "Remote host initialization"
    for i in ${NODE_LIST[*]}
    do
       timeout 20 ssh -p $SSH_PORT $i "mkdir -p /tmp/linshi" || red "remote host $i mkdir failed!"
       timeout 20 scp -P $SSH_PORT scripts/0_system_init.sh $i:/tmp/linshi/ || red "$i scp system_init.sh script failed !"
       timeout 300 ssh -p $SSH_PORT $i "bash /tmp/linshi/0_system_init.sh $ROOT $NTPSERVER" && green "$i system init done" || red "$i system init failed !"
    done
    touch ./record/0_addnode_init_sys.ok
fi

#Restore data directory
if [ ! -f ./record/0_addnode_gunzip_data.ok ];then
   timeout 60 tar xf $DIR/HISTORY_BACKUP/$2/${3}.tar.gz -C $DIR/
   touch ./record/0_addnode_gunzip_data.ok
fi

#Target host environment check
if [ ! -f ./record/1_addnode_env_check.ok ];then
   print_out "Target host environment check"
   check_system
   touch ./record/1_addnode_env_check.ok
fi

#Create config & service
if [ ! -f ./record/2_addnode_conf_service.ok ];then
    print_out "Create config and service"
    if [[ ${NODE_LIST[0]} != "" ]];then
        for i in ${NODE_LIST[*]}
        do
             timeout 5 ./scripts/3_create_service_conf.sh $i node || red "Node $i config creation failed"
        done
        [ $? -eq 0 ] && green "Node configuration file created successfully" ||red "Node configuration file creation failed"
    fi
    touch ./record/2_addnode_conf_service.ok
fi

#Rsync files to remote hosts
if [ ! -f ./record/3_addnode_rsync_files.ok ];then
    print_out "Sync files to remote hosts"
    for i in ${NODE_LIST[*]}
    do
      print_out_ "$i"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" certs/ $i:$ROOT/certs/ && green "Certs sync done" || red "Certs sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" --exclude "daemon.json" ./data/node/$i/etc/ $i:$ROOT/etc/ && green "Config file sync done" || red "config file sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./data/node/$i/etc/daemon.json $i:/etc/docker/ && green "Docker config sync done" || red "Docker config sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./data/node/$i/service/  $i:/usr/lib/systemd/system/ && green "Service file sync done" || red "Service file sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/docker/ $i:/usr/local/bin/ && green "Docker bin sync done" || red "Docker bin sync faile
d!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/cni  $i:/opt/   && green "CNI bin sync done" || red "CNI bin sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/node-bin/ $i:/usr/local/bin/ && green "Kube bin sync done" || red "Kube bin sync failed!
"
      timeout 20 ssh -p $SSH_PORT $i "sudo chown root. /usr/lib/systemd/system/{docker.service,kubelet.service,kube-proxy.service} && sudo chmod 644 /usr/lib/systemd/system/{docker.service,kubelet.service,kube-proxy.service}" && green "service file authority change ok" || red "service file authority change failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo chown root. /usr/local/bin/* && sudo chmod 755 /usr/local/bin/*" && green "Local bin file chmod ok" || red "Local bin file chmod failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo chmod -R 755 $ROOT" && green "$ROOT chmod 755 OK" || red "$ROOT chmod 755 failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo systemctl daemon-reload" && green "Service loaded successfully" || red "Service loaded failed!"
    done
    touch ./record/3_addnode_rsync_files.ok
fi

#Start docker
if [ ! -f ./record/4_addnode_start_docker.ok ];then
    print_out "Starting Docker Engine"
    for i in ${NODE_LIST[*]}
    do
      if [ $(timeout 30 ssh -p $SSH_PORT $i "[ -S /var/run/docker.sock ] && echo OK || echo NO") == "OK" ];then
         timeout 30 ssh -p $SSH_PORT $i "sudo systemctl restart docker &> /dev/null"
      else
         timeout 30 ssh -p $SSH_PORT $i "sudo systemctl start docker && sudo systemctl enable docker &> /dev/null"
      fi
      [ $(timeout 30 ssh -p $SSH_PORT $i "[ -S /var/run/docker.sock ] && echo OK || echo NO") == "OK" ] && green "$i Docker Started" || red "$i Docker Start Failed!"
    done
    touch ./record/4_addnode_start_docker.ok
fi

#Start kubelet\kube-proxy
if [ ! -f ./record/5_addnode_start_node.ok ];then
    print_out "Starting kubelet and kube-proxy component"
    for i in ${NODE_LIST[*]}
    do
      timeout 30 ssh -p $SSH_PORT $i "sudo systemctl start kubelet kube-proxy && sudo systemctl enable kubelet kube-proxy &> /dev/null" && green "$i kubelet and kube-proxy start done"|| red "$i kubelet and kube-proxy start failed"
    done
    touch ./record/5_addnode_start_node.ok
    sleep 30
fi

#Label nodes
######在部署第三方组件之前最好检测一下集群状态
if [ ! -f ./record/6_addnode_label_node.ok ];then
   #Node nodes label
   if [ "${NODE_LIST[0]}" != "" ];then
   ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl label nodes ${NODE_LIST[*]} node-role.kubernetes.io/node= --overwrite &> /dev/null" && green "Node nodes labeled node role successfully" || red "Node nodes labeled node role failed!"
   fi
   touch ./record/6_addnode_label_node.ok
fi

#Backup certs & config files
if [ ! -f ./record/7_addnode_backup_files.ok ];then
if [ ${NAMESPACES[0]} != "" ];then
   print_out "Ready Backup certs and config files"
   mkdir -p $DIR/HISTORY_BACKUP/${NAMESPACES[0]}
   cd $DIR
   tar zcf $DIR/HISTORY_BACKUP/${NAMESPACES[0]}/$(date +%F).tar.gz certs data env.yml &> /dev/null
   [ -f $DIR/HISTORY_BACKUP/${NAMESPACES[0]}/$(date +%F).tar.gz ] && green "BACKUP SUCCESSED!" || red "BACKUP FAILED!"
   cd - &> /dev/null
   touch ./record/7_addnode_backup_files.ok
else
   print_out "Ready Backup certs and config files"
   mkdir -p $DIR/HISTORY_BACKUP/${MASTER_LIST[0]}
   back_file=$(date +%Y%m%d-%N)
   cd $DIR
   tar zcf $DIR/HISTORY_BACKUP/${MASTER_LIST[0]}/${back_file}.tar.gz certs data env.yml &> /dev/null
   [ -f $DIR/HISTORY_BACKUP/${MASTER_LIST[0]}/${back_file}.tar.gz ] && green "BACKUP SUCCESSED!" || red "BACKUP FAILED!"
   cd - &> /dev/null
   touch ./record/7_addnode_backup_files.ok
fi
fi
