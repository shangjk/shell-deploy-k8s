#!/usr/bin/bash
#Auth: Jack
#Date: 2021/1/12
#Version: 1.0
#Description: run.sh 

###########add-node-parameter########################################
source scripts/lib
[ "$1" == '--help' ] && help
[ "$1" == '-h' ] && help
if [ "$1" == 'add' ];then
   ./scripts/add_node.sh $1 $2 $3 $4
   [ "$?" != "0" ] && exit 3
   exit 0
elif [ "$1" == 'create' ] && [ "$2" == 'namespace' ] && [ "$3" != "" ] && [ "$4" != "" ] && [ "$5" != "" ];then
   ./scripts/create_namespaces.sh $5 $3 $4
   [ "$?" != "0" ] && exit 4
   exit 0
fi
###########初始化区##################################################
#source scripts/lib
mkdir ./record &> /dev/null
#Determine whether the env.yml file exists
if [ ! -f $(pwd)/env.yml ];then
   echo -e "\033[31m>>[ERROR]: No find env.yml in local dir ! \033[0m"
   exit 1
fi
#####################################################################
#variables
#export ROOT=$(grep '\<ROOT\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')   #环境安装的根目录
#export KUBERNETES_SVC_IP=$(grep '\<KUBERNETES_SVC_IP\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')  
#export SCR=$(grep '\<SCR\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')   #集群service_cluster_ip_range
#export COREDNS=$(grep '\<COREDNS\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')  #集群COREDNS的SVC地址
#export NTPSERVER=$(grep '\<NTPSERVER\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g') #ntp server的地址
#export CALICO_NETWORK_MODE=$(grep '\<CALICO_NETWORK_MODE\>' env.yml | awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')
export ROOT=/opt/k8s    #安装环境的根目录
export DIR=$(pwd)       #脚本执行的当前目录，请确保目录下有env.yml 
export SSH_PORT=22
export KUBERNETES_SVC_IP=192.168.0.1
export SCR=192.168.0.0/16
export COREDNS=192.168.0.2
export CALICO_NETWORK_MODE=BGP
export NTPSERVER=ntp1.aliyun.com
export VIP=$(grep '\<VIP\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')   #集群Master的VIP
export CIDR=$(grep '\<CIDR\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g') #集群pod_ip_range
export MASTER_LIST=($(grep '\<MASTER\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g'))  #集群MASTER的IP列表
export NODE_LIST=($(grep '\<NODES\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g'))  #集群MASTER的IP列表
export ENCRYPTION_SECRET=$(head -c 32 /dev/urandom | base64)
export NAMESPACES=($(grep '\<NAMESPACES\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g'))
export ES_NODES=($(grep '\<ES_NODES\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g'))
export ES_USER=$(grep '\<ES_USER\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')
export ES_PASSWORD=$(grep '\<ES_PASSWORD\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')
export GRAFANA_ADDRESS=$(grep '\<GRAFANA_ADDRESS\>' env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')
#填充ETCD_CLUSTER\ETCD_SERVERS
ETCD_CLUSTER=
ETCD_SERVERS=
if [ "${#MASTER_LIST[*]}" -gt 0 ];then
    for i in ${MASTER_LIST[*]}
    do 
        if [ ! -n "$ETCD_SERVERS" ];then
            ETCD_CLUSTER=$i=https://$i:2380
	    ETCD_SERVERS=https://$i:2379
	else
	    ETCD_CLUSTER=${ETCD_CLUSTER},$i=https://$i:2380
	    ETCD_SERVERS=${ETCD_SERVERS},https://$i:2379
	fi
    done
fi
export ETCD_CLUSTER
export ETCD_SERVERS

if [ "$CALICO_NETWORK_MODE" == "BGP" ];then
   export BGP_IPIP=off
elif [ "$CALICO_NETWORK_MODE" == "IPIP" ];then
   export BGP_IPIP=Always
else 
   red "You need to specify a calico network mode!"
fi

ES_HOSTS=
if [ "${#ES_NODES[*]}" -gt 0 ];then
   for i in ${ES_NODES[*]}
   do
      if [ ! -n "$ES_HOSTS" ];then
         ES_HOSTS=${i}:9200
      else
         ES_HOSTS=${ES_HOSTS},${i}:9200
      fi
   done
fi
export ES_HOSTS
#######Env show######################################################
echo -e "\033[1;32m>>>>>>>>> The installation information is as follows <<<<<<<<<<<<\033[0m" 
cat << EOF
>>>Master hosts    : ${MASTER_LIST[*]}
>>>Node   hosts    : ${NODE_LIST[*]}
>>>Service ip range: $SCR
>>>Pod ip range    : $CIDR
>>>Kubeapi VIP     : $VIP
>>>Calico net mode : $CALICO_NETWORK_MODE
>>>NAMESPACES      : ${NAMESPACES[*]}
>>>ES NODES        : ${ES_NODES[*]}
>>>Target dir      : $ROOT
>>>K8s version     : $($DIR/resources/master-bin/kube-apiserver --version)
EOF
echo -e "\033[1;32m>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\033[0m" 
#####################################################################
#Make final confirmation
read -p "Make final confirmation(y/n): " confirmed
if [ $confirmed != "y" ];then
   exit 1
fi
#######执行区########################################################
#Connectivity check
print_out "Target host connection check"
for i in ${MASTER_LIST[*]} ${NODE_LIST[*]}
do
    timeout 5 ssh -p $SSH_PORT $i "hostname" &> /dev/null && green "$i connected" || red "cannot connect $i by ssh"
done
#####################################################################
#env
if [ ! -f ./record/0_cleanliness_detection.ok ];then
   print_out "Target host Environmental cleanliness detection"
   for i in ${MASTER_LIST[*]} ${NODE_LIST[*]}
   do
     [[ $(timeout 10 ssh -p $SSH_PORT $i "netstat -anlp|grep -E '\<2379\>|\<6443\>|\<10250\>|\<10251\>|\<2380\>|\<10259\>|\<10257\>'|wc -l") -gt 0 ]] && red "Host $i port 2379|6443|10250|10251 is open,not clean"
     green "The nodes is clean and can be installed"
     touch ./record/0_cleanliness_detection.ok
   done
fi
#####################################################################
#Target host initialization
if [ ! -f ./record/0_init_sys.ok ];then
    print_out "Remote host initialization"
    for i in ${MASTER_LIST[*]} ${NODE_LIST[*]}
    do
       timeout 20 ssh -p $SSH_PORT $i "mkdir -p /tmp/linshi" || red "remote host $i mkdir failed!"
       timeout 20 scp -P $SSH_PORT scripts/0_system_init.sh $i:/tmp/linshi/ || red "$i scp system_init.sh script failed !"
       timeout 300 ssh -p $SSH_PORT $i "bash /tmp/linshi/0_system_init.sh $ROOT $NTPSERVER" && green "$i system init done" || red "$i system init failed !"
    done
    touch ./record/0_init_sys.ok
fi
#################################################################
#Target host environment check
if [ ! -f ./record/1_env_check.ok ];then
   print_out "Target host environment check"
   check_system
   touch ./record/1_env_check.ok
fi
##################################################################
#Create TLS certs
if [ ! -f ./record/2_sign_ssl.ok ];then
    print_out "Signed SSL certificate"
    timeout 10 ./scripts/1_create_ssl_certs.sh &>/dev/null && green "TLS certificate created" || red "TLS certificate creation failed!" 
    touch ./record/2_sign_ssl.ok
fi
##################################################################
#Create kubeconfig files
if [ ! -f ./record/3_create_kubeconfig.ok ];then
    print_out "Kubeconfig file preparation"
    timeout 10 ./scripts/2_create_kubeconfig.sh &>/dev/null && green "Kubeconfig created" || red "Kubeconfig creation failed!"
    touch ./record/3_create_kubeconfig.ok
fi
###################################################################
#Create config & service
if [ ! -f ./record/4_conf_service.ok ];then
    print_out "Create config and service"
    if [[ ${MASTER_LIST[0]} != "" ]];then
       for i in ${MASTER_LIST[*]}
       do 
           timeout 5 ./scripts/3_create_service_conf.sh $i master || red "Master $i config creation failed"
       done
       [ $? -eq 0 ]&& green "Master configuration file created successfully" ||red "Master configuration file creation failed"
    fi
    if [[ ${NODE_LIST[0]} != "" ]];then
        for i in ${NODE_LIST[*]}
        do 
             timeout 5 ./scripts/3_create_service_conf.sh $i node || red "Node $i config creation failed"
        done
        [ $? -eq 0 ] && green "Node configuration file created successfully" ||red "Node configuration file creation failed"
    fi
    touch ./record/4_conf_service.ok
fi
####################################################################
#Rsync files to remote hosts
if [ ! -f ./record/5_rsync_files.ok ];then
    print_out "Sync files to remote hosts"
    for i in ${MASTER_LIST[*]}
    do
      print_out_ "$i"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" certs/ $i:$ROOT/certs/ && green "Certs sync done" || red "Certs sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" certs/kubeconfig/kubectl.kubeconfig $i:/root/.kube/config && green "/root/.kube/config sync done" || red "/root/.kube/config sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" --exclude "daemon.json" ./data/master/$i/etc/  $i:$ROOT/etc/ && green "Config file sync done" || red "Config file sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./data/master/$i/etc/daemon.json  $i:/etc/docker/  && green "Docker config sync done" || red "Docker config sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./data/master/$i/service/  $i:/usr/lib/systemd/system/ && green "Service file sync done" || red "Service file sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/docker/ $i:/usr/local/bin/ && green "Docker bin sync done" || red "Docker bin sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/cni  $i:/opt/   && green "CNI bin sync done" || red "CNI bin sync failed!"
      timeout 120 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/master-bin/ $i:/usr/local/bin/ && green "Kube bin sync done" || red "Kube bin sync failed!"
      timeout 20 ssh -p $SSH_PORT $i "sudo chown root. /usr/lib/systemd/system/{docker.service,etcd.service,kube-apiserver.service,kube-controller-manager.service,kube-scheduler.service,kubelet.service,kube-proxy.service} && sudo chmod 644 /usr/lib/systemd/system/{docker.service,etcd.service,kube-apiserver.service,kube-controller-manager.service,kube-scheduler.service,kubelet.service,kube-proxy.service}" && green "service file authority change ok" || red "service file authority change failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo chown root. /usr/local/bin/* && sudo chmod 755 /usr/local/bin/*" && green "Local bin file chmod ok" || red "Local bin file chmod failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo chmod -R 755 $ROOT" && green "$ROOT chmod 755 OK" || red "$ROOT chmod 755 failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo systemctl daemon-reload" && green "Service loaded successfully" || red "Service loaded failed!"
    done

    for i in ${NODE_LIST[*]}
    do
      print_out_ "$i"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" certs/ $i:$ROOT/certs/ && green "Certs sync done" || red "Certs sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" --exclude "daemon.json" ./data/node/$i/etc/ $i:$ROOT/etc/ && green "Config file sync done" || red "Config file sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./data/node/$i/etc/daemon.json $i:/etc/docker/ && green "Docker config sync done" || red "Docker config sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./data/node/$i/service/  $i:/usr/lib/systemd/system/ && green "Service file sync done" || red "Service file sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/docker/ $i:/usr/local/bin/ && green "Docker bin sync done" || red "Docker bin sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/cni  $i:/opt/   && green "CNI bin sync done" || red "CNI bin sync failed!"
      timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" ./resources/node-bin/ $i:/usr/local/bin/ && green "Kube bin sync done" || red "Kube bin sync failed!"
      timeout 20 ssh -p $SSH_PORT $i "sudo chown root. /usr/lib/systemd/system/{docker.service,kubelet.service,kube-proxy.service} && sudo chmod 644 /usr/lib/systemd/system/{docker.service,kubelet.service,kube-proxy.service}" && green "service file authority change ok" || red "service file authority change failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo chown root. /usr/local/bin/* && sudo chmod 755 /usr/local/bin/*" && green "Local bin file chmod ok" || red "Local bin file chmod failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo chmod -R 755 $ROOT" && green "$ROOT chmod 755 OK" || red "$ROOT chmod 755 failed"
      timeout 20 ssh -p $SSH_PORT $i "sudo systemctl daemon-reload" && green "Service loaded successfully" || red "Service loaded failed!"
    done
    touch ./record/5_rsync_files.ok
fi
##########################################################
#Start docker
if [ ! -f ./record/6_start_docker.ok ];then
    print_out "Starting Docker Engine"
    for i in ${MASTER_LIST[*]} ${NODE_LIST[*]}
    do
      if [ $(timeout 30 ssh -p $SSH_PORT $i "[ -S /var/run/docker.sock ] && echo OK || echo NO") == "OK" ];then
         timeout 30 ssh -p $SSH_PORT $i "sudo systemctl restart docker &> /dev/null"
      else
         timeout 30 ssh -p $SSH_PORT $i "sudo systemctl start docker && sudo systemctl enable docker &> /dev/null"
      fi
      [ $(timeout 30 ssh -p $SSH_PORT $i "[ -S /var/run/docker.sock ] && echo OK || echo NO") == "OK" ] && green "$i Docker Started" || red "$i Docker Start Failed!"
    done
    touch ./record/6_start_docker.ok
fi
###########################################################
#同步镜像，只在本地测试使用该步骤
#cd /root/calico_images_3.2.8
#./scp.sh ${MASTER_LIST[*]} ${NODE_LIST[*]}
#cd -
############################################################
#Start etcd
if [ ! -f ./record/7_start_etcd.ok ];then
    print_out "Starting Etcd Cluster"
    for i in ${MASTER_LIST[*]}
    do
      port_check $i 2379 &> /dev/null
      check_status=$?
      if [[ $check_status -eq 1 ]];then
         timeout 30 ssh -p $SSH_PORT $i "sudo systemctl start etcd && sudo systemctl enable etcd &> /dev/null" && green "$i Etcd service started" || red "$i Etcd service start failed" &
      elif [[ $chec_status -eq 2 ]];then
         timeout 30 ssh -p $SSH_PORT $i "sudo systemctl restart etcd &> /dev/null" && green "$i Etcd service started" || red "$i Etcd service start failed" &
      fi
    done
    sleep 6
    print_out "Check etcd cluster"
    for i in ${MASTER_LIST[*]}
    do
      etcd_check $i
    done
    touch ./record/7_start_etcd.ok
fi
#################################################################
#Start kube-apiserver
if [ ! -f ./record/8_start_master.ok ];then
    print_out "Starting Master Component"
    for i in ${MASTER_LIST[*]}
    do
      print_out_ "$i"
      port_check $i 6443 &> /dev/null
      kube_check=$?
      if [[ $kube_check -eq 1 ]];then
        timeout 60 ssh -p $SSH_PORT $i "sudo systemctl start kube-apiserver && sudo systemctl enable kube-apiserver &> /dev/null" && green "Apiserver start done" || red "Apiserver start failed"
        timeout 60 ssh -p $SSH_PORT $i "sudo systemctl start kube-controller-manager && sudo systemctl enable kube-controller-manager &> /dev/null" && green "Controller start done" || red "Controller start failed"
        timeout 60 ssh -p $SSH_PORT $i "sudo systemctl start kube-scheduler && sudo systemctl enable kube-scheduler &> /dev/null" && green "Scheduler start done" || red "Scheduler start failed"
      elif [[ $kube_check -eq 2 ]];then
        timeout 60 ssh -p $SSH_PORT $i "sudo systemctl restart kube-apiserver && sudo systemctl enable kube-apiserver &> /dev/null" && green "Apiserver restart done" || red "Apiserver restart failed"
        timeout 60 ssh -p $SSH_PORT $i "sudo systemctl restart kube-controller-manager && sudo systemctl enable kube-controller-manager &> /dev/null" && green "Controller restart done" || red "Controller restart failed"
        timeout 60 ssh -p $SSH_PORT $i "sudo systemctl restart kube-scheduler && sudo systemctl enable kube-scheduler &> /dev/null" && green "Scheduler restart done" || red "Scheduler restart failed"
      fi 
    done
    sleep 5
    print_out "Master Cpmponent Health Check"
    for i in ${MASTER_LIST[*]}
    do  
      check_kubeapi $i
    done
    touch ./record/8_start_master.ok
fi
##################################################################
#RBAC Clusterrolebinding
mkdir -p $DIR/data/yaml &> /dev/null
if [ ! -f ./record/9_apply_clusterrolebinding.ok ];then
    print_out "Create clusterrolebinding for cluster"
    timeout 10 $DIR/scripts/4_create_rbac_policy.sh && green "RBAC yaml create done" || red "RBAC yaml create failed!"
    timeout 10 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/{tls-instructs-csr.yaml,rbac-clusterrolebinding.yaml} ${MASTER_LIST[0]}:/tmp/linshi/yaml/ && green "Clusterrole yaml sync done" || red "Clusterrole yaml sync failed!"
    ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/tls-instructs-csr.yaml" &> /dev/null && green "Clusterrole certificatesingingrequests:selfnodeserver create successfully" || red "Clusterrole certificatesingingrequests:selfnodeserver create failed!"
    ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/rbac-clusterrolebinding.yaml" &> /dev/null && green "Clusterrolebinding create successfully" || red "Clusterrolebinding create failed!"
    touch ./record/9_apply_clusterrolebinding.ok
fi
###################################################################
#Start kubelet\kube-proxy
if [ ! -f ./record/10_start_node.ok ];then
    print_out "Starting kubelet and kube-proxy component"
    for i in ${MASTER_LIST[*]} ${NODE_LIST[*]}
    do 
      timeout 30 ssh -p $SSH_PORT $i "sudo systemctl start kubelet kube-proxy && sudo systemctl enable kubelet kube-proxy &> /dev/null" && green "$i kubelet and kube-proxy start done"|| red "$i kubelet and kube-proxy start failed"
    done
    touch ./record/10_start_node.ok
    sleep 30
fi
###################################################################
#Label nodes
######在部署第三方组件之前最好检测一下集群状态
if [ ! -f ./record/11_label_node.ok ];then
   #Master node label
   print_out "Label the master and node"
   if [ -n ${MASTER_LIST[0]} ];then
   ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl label nodes ${MASTER_LIST[*]} node-role.kubernetes.io/master= --overwrite &> /dev/null" && green "Master nodes labeled master role successfully" || red "Master nodes labeled master role failed!"
   ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl label nodes ${MASTER_LIST[*]} coredns=true --overwrite &> /dev/null" && green "Master nodes labeled coredns successfully" || red "Master nodes labeled coredns failed!"
   ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl taint nodes ${MASTER_LIST[*]} node-role.kubernetes.io/master=:NoSchedule --overwrite &> /dev/null" && green "Master nodes tainted successfully" || red "Master nodes tainted failed!"
   fi

   #Node nodes label
   if [ "${NODE_LIST[0]}" != "" ];then
   ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl label nodes ${NODE_LIST[*]} node-role.kubernetes.io/node= --overwrite &> /dev/null" && green "Node nodes labeled node role successfully" || red "Node nodes labeled node role failed!"
   #需要给node打什么label,可以在这里添加
   fi
   touch ./record/11_label_node.ok
fi

#rsync images
#for i in ${MASTER_LIST[*]} ${NODE_LIST[*]}
#do
#  rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" /root/images/calico_images $i:/tmp/linshi/
#  ssh_remote $i 'cd /tmp/linshi/calico_images/;for i in $(ls *.tar);do sudo docker load -i $i ;done'
#done

####################################################################
#Deploy calico
if [ ! -f ./record/12_deploy_calico.ok ];then
    print_out "Deploying calico network plugin"
    timeout 10 $DIR/scripts/5_create_calico_yaml.sh && green "Calico yaml create done!" || red "Calico yaml create failed!"
    timeout 20 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/calico.yaml ${MASTER_LIST[0]}:/tmp/linshi/yaml/ && green "Calico yaml rsync done" || red "Calico yaml rsync failed!"
    ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/calico.yaml" &> /dev/null && green "Calico yaml apply succeeded!" || red "Calico yaml apply failed!"
    touch ./record/12_deploy_calico.ok
fi
######################################################################
#Deploy coredns
if [ ! -f ./record/13_deploy_coredns.ok ];then
    print_out "Deploy coredns plugin"
    timeout 10 $DIR/scripts/6_create_coredns_yaml.sh && green "Coredns yaml create done!" || red "Coredns yaml create failed!"
    timeout 20 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/coredns.yaml ${MASTER_LIST[0]}:/tmp/linshi/yaml/ && green "Coredns yaml rsync done!" || red "Coredns yaml rsync failed!"
    ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/coredns.yaml" &> /dev/null && green "Coredns yaml apply succeeded!" || red "Coredns yaml apply failed!"
    touch ./record/13_deploy_coredns.ok
fi
########################################################################
#Deploy ingress
if [ ! -f ./record/14_deploy_ingress.ok ];then
  if [ ${NAMESPACES[0]} != "" ];then
     print_out "Deploy ingress plugin"
     timeout 10 $DIR/scripts/8_create_ingress_yaml.sh ${NAMESPACES[0]} && green "Ingress yaml create done!" || red "Ingress yaml create failed!"
     timeout 20 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/ingress-controller-${NAMESPACES[0]}.yaml ${MASTER_LIST[0]}:/tmp/linshi/yaml/ && green "Ingress yaml rsync done!"|| red "Ingress yaml rsync failed!"
     ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/ingress-controller-${NAMESPACES[0]}.yaml" &> /dev/null && green "Ingress yaml apply succeeded!" || red "Ingress yaml apply failed!"
  else
     print_out "Deploy ingress plugin"
     timeout 10 $DIR/scripts/8_create_ingress_yaml.sh default && green "Ingress yaml create done!" || red "Ingress yaml create failed!"
     timeout 20 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/ingress-controller-default.yaml ${MASTER_LIST[0]}:/tmp/linshi/yaml/ && green "Ingress yaml rsync done!"|| red "Ingress yaml rsync failed!"
     ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/ingress-controller-default.yaml" &> /dev/null && green "Ingress yaml apply succeeded!" || red "Ingress yaml apply failed!"
  fi
  touch ./record/14_deploy_ingress.ok
fi
#########################################################################
#Deploy metrics
if [ ! -f ./record/15_deploy_metrics.ok ];then
    print_out "Deploying metrics server plugin"
    timeout 10 $DIR/scripts/7_create_metrics_yaml.sh && green "Metrics yaml create done!" || red "Metrics yaml create failed!"
    timeout 20 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/metrics-server.yaml ${MASTER_LIST[0]}:/tmp/linshi/yaml/ && green "Metrics yaml rsync done!" ||red "Metrics yaml rsync failed!"
    ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/metrics-server.yaml" &> /dev/null && green "Metrics ymal apply succeeded!" || red "Metrics yaml apply failed!"
    touch ./record/15_deploy_metrics.ok
fi
########################################################################
#Create NS
if [ ${NAMESPACES[0]} != "" ];then
if [ ! -f ./record/16_create_ns.ok ];then
    print_out "Create namespaces on cluster!"
    for i in ${NAMESPACES[*]}
    do
      ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl create ns $i" &> /dev/null && green "NS $i create succeeded!" || red "NS $i create failed!"
    done
    touch ./record/16_create_ns.ok
fi
fi
########################################################################
#create moth
if [ ! -f ./record/17_create_moth.ok ];then
   print_out "Create sa moth for the publishing platform"
   ssh_remote ${MASTER_LIST[0]} 'sudo /usr/local/bin/kubectl create sa moth' &> /dev/null && green 'SA moth create succeeded!' || red 'SA moth create failed!'
   ssh_remote ${MASTER_LIST[0]} 'sudo /usr/local/bin/kubectl create clusterrolebinding moth --clusterrole=cluster-admin --serviceaccount=default:moth' &> /dev/null && green 'clusterrolebinding create succeeded!' || red 'clusterrolebinding create failed!'
   moth_secret=$(ssh_remote ${MASTER_LIST[0]} 'sudo /usr/local/bin/kubectl get secret|grep moth-token|cut -d " " -f1')
   moth_token=$(ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl get secret $moth_secret -o jsonpath={".data.token"} |base64 -d")
   echo -e  "\033[1;32m>>>moth token: $moth_token \033[0m"
   touch ./record/17_create_moth.ok   
fi
#######################################################################
#Deploy ingress log cut
if [ ! -f ./record/18_ingress_log_cut.ok ];then
  if [ ${NAMESPACES[0]} != "" ];then
     print_out "Deploy ingress log cut script"
     timeout 10 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/resources/expand/ingress_log_cut/ ${MASTER_LIST[0]}:$ROOT/script/ && green "Ingress log cut script rsync done!" || red "Ingress log cut script rsync failed!"
     ssh_remote ${MASTER_LIST[0]} "sudo $ROOT/script/set_crontab.sh $ROOT/script/nginx_log_cut.sh ${NAMESPACES[0]}" && green "Ingress log cut crontab set successfully!" || red "Ingress log cut crontab setup failed!"
  else
     print_out "Deploy ingress log cut script"
     timeout 10 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/resources/expand/ingress_log_cut/ ${MASTER_LIST[0]}:$ROOT/script/ && green "Ingress log cut script rsync done!" || red "Ingress log cut script rsync failed!"
     ssh_remote ${MASTER_LIST[0]} "sudo $ROOT/script/set_crontab.sh $ROOT/script/nginx_log_cut.sh default" && green "Ingress log cut crontab set successfully!" || red "Ingress log cut crontab setup failed!"
  fi
   touch ./record/18_ingress_log_cut.ok 
fi
########################################################################
#Deploy kubectl debug tools
if [ ! -f ./record/19_deploy_kubectl_debug.ok ];then
   print_out "Deploy kubectl debug tools"
   timeout 10 $DIR/scripts/9_create_kubectl_debug_yaml.sh && green "kubectl-debug yaml create done!" || red "kubectl-debug yaml create failed!"
   timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/debug-config ${MASTER_LIST[0]}:/root/.kube/debug-config && green "kubectl-debug config file sync done" || red "kubectl-debug config file sync failed"
   timeout 60 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/debug-agent.yaml ${MASTER_LIST[0]}:/tmp/linshi/yaml/debug-agent.yaml && green "Debug-agent yaml sync done" || red "Debug-agent yaml sync failed"
   ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/debug-agent.yaml &> /dev/null" && green "Debug-agent yaml apply successed" || red "Debug-agent yaml apply failed"
   touch ./record/19_deploy_kubectl_debug.ok
fi
########################################################################
#Deploy Prometheus
if [ ! -f ./record/20_deploy_prometheus.ok ];then
   if [ ${NAMESPACES[0]} != "" ];then
     print_out "Deploy prometheus monitor"
     timeout 10 $DIR/scripts/10_create_prometheus_yaml.sh ${NAMESPACES[0]} ${MASTER_LIST[*]} && green "Prometheus yaml create done!" || red "Prometheus yaml create failed!"
     timeout 20 rsync -a -e "ssh -p $SSH_PORT" --rsync-path="sudo rsync" $DIR/data/yaml/prometheus.yaml ${MASTER_LIST[0]}:/tmp/linshi/yaml/ && green "Prometheus yaml rsync done!" || red "Prometheus yaml rsync failed!"
     ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl apply -f /tmp/linshi/yaml/prometheus.yaml" &> /dev/null && green "Prometheus yaml apply done!" || red "Prometheus yaml apply failed!"
     ssh_remote ${MASTER_LIST[0]} "sudo /usr/local/bin/kubectl create secret generic etcd-certs --from-file=$ROOT/certs/ssl/etcd.pem --from-file=$ROOT/certs/ssl/etcd-key.pem --from-file=$ROOT/certs/ssl/ca.pem -n monitoring" &> /dev/null && green "Prometheus-etcd-secret created!" || red "Prometheus-etcd-secret create failed!"
     touch ./record/20_deploy_prometheus.ok
   fi
fi 
########################################################################
#Create grafana dashboard for cluster
if [ ! -f ./record/20_create_grafana_dashboard.ok ];then
   if [ ${NAMESPACES[0]} != "" ];then
     print_out "Create grafana dashboard"
     timeout 10 $DIR/scripts/11_create_grafana_dashboard.sh ${NAMESPACES[0]} && green "Dashboard json file create successed!" || red "Dashboard json file create failed!"
     timeout 10 curl -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer eyJrIjoiQ0c3TmVYNFlyMGc5MVUzNmFFSXhCNVVUdlpmTGNVQlEiLCJuIjoiYWRtaW4iLCJpZCI6MX0=" http://$GRAFANA_ADDRESS:3000/api/datasources -d @$DIR/data/json/grafana-datasource.json &> /dev/null && green "Grafana datasource datasource_${NAMESPACES[0]} create successed!" || red "Grafana datasource datasource_${NAMESPACES[0]} create failed!"
     timeout 10 curl -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer eyJrIjoiQ0c3TmVYNFlyMGc5MVUzNmFFSXhCNVVUdlpmTGNVQlEiLCJuIjoiYWRtaW4iLCJpZCI6MX0=" http://$GRAFANA_ADDRESS:3000/api/dashboards/db -d @$DIR/data/json/grafana-dashboard.json &> /dev/null && green "Grafana dashboard CLUSTER_${NAMESPACES[0]}_DASHBOARD create successed!" || red "Grafana dashboard CLUSTER_${NAMESPACES[0]}_DASHBOARD create failed!"
     touch ./record/20_create_grafana_dashboard.ok
   fi
fi
########################################################################
#Backup certs & config files
if [ ! -f ./record/21_backup_files.ok ];then
if [ ${NAMESPACES[0]} != "" ];then
   print_out "Ready Backup certs and config files"
   mkdir -p $DIR/HISTORY_BACKUP/${NAMESPACES[0]}
   cd $DIR
   tar zcf $DIR/HISTORY_BACKUP/${NAMESPACES[0]}/$(date +%F).tar.gz certs data env.yml &> /dev/null
   [ -f $DIR/HISTORY_BACKUP/${NAMESPACES[0]}/$(date +%F).tar.gz ] && green "BACKUP SUCCESSED!" || red "BACKUP FAILED!"
   cd - &> /dev/null
   touch ./record/21_backup_files.ok
else
   print_out "Ready Backup certs and config files"
   mkdir -p $DIR/HISTORY_BACKUP/${MASTER_LIST[0]}
   back_file=$(date +%Y%m%d-%N)
   cd $DIR
   tar zcf $DIR/HISTORY_BACKUP/${MASTER_LIST[0]}/${back_file}.tar.gz certs data env.yml &> /dev/null
   [ -f $DIR/HISTORY_BACKUP/${MASTER_LIST[0]}/${back_file}.tar.gz ] && green "BACKUP SUCCESSED!" || red "BACKUP FAILED!"
   cd - &> /dev/null
   touch ./record/21_backup_files.ok
fi
   echo -e "\n\033[1;32m>>>[Finish] The cluster will download the image gradually in the future, please give the cluster some time to be ready \033[0m\n"
fi
########################################################################
#clean record dir
#rm -fr record/*
#touch ./record/0_init_sys.ok

########################################################################
#
