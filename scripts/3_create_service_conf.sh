#!/usr/bin/bash
#Auth: Jack
#Date: 2021/1/12
#Version: 1.0
#Description: create service and conf files

#-------变量区---------
DIR=$DIR/data/$2
#创建节点的配置文件存放目录
mkdir -p $DIR/$1/{etc,service} &> /dev/null || echo -e "\033[31m 配置文件存放目录创建失败! \033[0m"

if [ "$2" == "master" ];then

ETCD_NAME=$1
ETCD_IP=$1
#ETCD_CLUSTER_IP=($(grep MASTER env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g'))
#ETCD_CLUSTER=

#-------ETCD---------
cat <<EOF > $DIR/$1/etc/etcd.yml
name: ${ETCD_NAME}
data-dir: $ROOT/data/etcd
listen-peer-urls: https://${ETCD_IP}:2380
listen-client-urls: https://${ETCD_IP}:2379,http://127.0.0.1:2379

advertise-client-urls: https://${ETCD_IP}:2379
initial-advertise-peer-urls: https://${ETCD_IP}:2380
initial-cluster: ${ETCD_CLUSTER}
initial-cluster-token: k8s-etcd-cluster
initial-cluster-state: new

client-transport-security:
  cert-file: $ROOT/certs/ssl/etcd.pem
  key-file: $ROOT/certs/ssl/etcd-key.pem
  client-cert-auth: true
  trusted-ca-file: $ROOT/certs/ssl/ca.pem
  auto-tls: true

peer-transport-security:
  cert-file: $ROOT/certs/ssl/etcd.pem
  key-file: $ROOT/certs/ssl/etcd-key.pem
  client-cert-auth: true
  trusted-ca-file: $ROOT/certs/ssl/ca.pem
  auto-tls: true

debug: false
logger: zap
log-outputs: [stderr]
EOF

cat <<EOF > $DIR/$1/service/etcd.service
[Unit]
Description=Etcd Server
Documentation=https://github.com/etcd-io/etcd
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
LimitNOFILE=65536
Restart=on-failure
RestartSec=5s
TimeoutStartSec=0
ExecStart=/usr/local/bin/etcd --config-file=$ROOT/etc/etcd.yml

[Install]
WantedBy=multi-user.target
EOF

#-----------kube-apiserver---------
cat <<EOF > $DIR/$1/etc/kube-apiserver.conf
KUBE_APISERVER_OPTS="--logtostderr=false \\
--v=2 \\
--alsologtostderr=false \\
--log-dir=$ROOT/logs/kube-apiserver \\
--apiserver-count=3 \\
--bind-address=0.0.0.0 \\
--secure-port=6443 \\
--advertise-address=$1 \\
--allow-privileged=true \\
--service-cluster-ip-range=$SCR \\
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota,NodeRestriction \\
--authorization-mode=RBAC,Node \\
--enable-swagger-ui=true \\
--enable-bootstrap-token-auth=true \\
--token-auth-file=$ROOT/certs/kubeconfig/token.csv \\
--anonymous-auth=false \\
--encryption-provider-config=$ROOT/etc/encryption-config.yaml \\
--service-node-port-range=3000-65535 \\
--event-ttl=168h \\
--default-not-ready-toleration-seconds=30 \\
--default-unreachable-toleration-seconds=30 \\
--kubelet-https=true \\
--kubelet-client-certificate=$ROOT/certs/ssl/server.pem \\
--kubelet-client-key=$ROOT/certs/ssl/server-key.pem \\
--tls-cert-file=$ROOT/certs/ssl/server.pem  \\
--tls-private-key-file=$ROOT/certs/ssl/server-key.pem \\
--client-ca-file=$ROOT/certs/ssl/ca.pem \\
--etcd-cafile=$ROOT/certs/ssl/ca.pem \\
--etcd-certfile=$ROOT/certs/ssl/server.pem \\
--etcd-keyfile=$ROOT/certs/ssl/server-key.pem \\
--etcd-servers=${ETCD_SERVERS} \\
--requestheader-client-ca-file=$ROOT/certs/ssl/ca.pem \\
--requestheader-extra-headers-prefix=X-Remote-Extra- \\
--requestheader-group-headers=X-Remote-Group \\
--requestheader-username-headers=X-Remote-User \\
--proxy-client-cert-file=$ROOT/certs/ssl/metrics-server.pem \\
--proxy-client-key-file=$ROOT/certs/ssl/metrics-server-key.pem \\
--service-account-key-file=$ROOT/certs/ssl/sa.pub \\
--runtime-config=api/all=true \\
--enable-aggregator-routing=true \\
--profiling=false \\
--audit-log-maxage=30 \\
--audit-log-maxbackup=10 \\
--audit-log-maxsize=100 \\
--audit-log-truncate-enabled=true \\
--audit-policy-file=$ROOT/etc/kubeapi-audit-policy.yaml \\
--audit-log-path=$ROOT/logs/kube-apiserver/k8s-audit.log"
EOF

cat <<EOF > $DIR/$1/service/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target
After=etcd.service

[Service]
User=root
EnvironmentFile=$ROOT/etc/kube-apiserver.conf
ExecStart=/usr/local/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure
Type=notify
LimitNOFILE=65536
RestartSec=5s
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

#生成kubeapi-audit-policy.yaml
cat <<EOF > $DIR/$1/etc/kubeapi-audit-policy.yaml 
apiVersion: audit.k8s.io/v1beta1 # This is required.
kind: Policy
omitStages:
  - "RequestReceived"
rules:
  - level: RequestResponse
    resources:
    - group: ""
      resources: ["pods"]
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    namespaces: ["kube-system"]
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.
  - level: Metadata
    omitStages:
      - "RequestReceived"
EOF

#生成encryption-config.yaml
cat << EOF > $DIR/$1/etc/encryption-config.yaml 
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
     - secrets
    providers:
     - aescbc:
         keys:
           - name: key1
             secret: $ENCRYPTION_SECRET
     - identity: {}
EOF

#-----------Kube-controller-manager----------
#--kubeconfig=/etc/kubernetes/conf/kube-controller-manager.kubeconfig
cat <<EOF > $DIR/$1/etc/kube-controller-manager.conf
KUBE_CONTROLLER_MANAGER_OPTS="--allocate-node-cidrs=true \\
--bind-address=0.0.0.0 \\
--master=127.0.0.1:8080 \\
--client-ca-file=$ROOT/certs/ssl/ca.pem \\
--cluster-cidr=$CIDR \\
--cluster-name=kubernetes \\
--cluster-signing-cert-file=$ROOT/certs/ssl/ca.pem \\
--cluster-signing-key-file=$ROOT/certs/ssl/ca-key.pem \\
--controllers=*,bootstrapsigner,tokencleaner \\
--experimental-cluster-signing-duration=87600h \\
--leader-elect=true \\
--horizontal-pod-autoscaler-use-rest-clients=true \\
--horizontal-pod-autoscaler-sync-period=10s \\
--requestheader-client-ca-file=$ROOT/certs/ssl/ca.pem \\
--root-ca-file=$ROOT/certs/ssl/ca.pem \\
--service-cluster-ip-range=$SCR \\
--use-service-account-credentials=true \\
--service-account-private-key-file=$ROOT/certs/ssl/sa.key \\
--feature-gates=RotateKubeletServerCertificate=true \\
--alsologtostderr=false \\
--pod-eviction-timeout=30s \\
--profiling=false \\
--logtostderr=false \\
--log-dir=$ROOT/logs/kube-controller-manager \\
--v=2"
EOF

cat <<EOF >$DIR/$1/service/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service

[Service]
User=root
EnvironmentFile=$ROOT/etc/kube-controller-manager.conf
ExecStart=/usr/local/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF


#--------------kube-scheduler-----------------
cat <<EOF >$DIR/$1/etc/kube-scheduler.conf
KUBE_SCHEDULER_OPTS="--logtostderr=false \\
--v=2 \\
--master=127.0.0.1:8080 \\
--address=127.0.0.1 \\
--alsologtostderr=false \\
--profiling=false \\
--log-dir=$ROOT/logs/kube-scheduler \\
--leader-elect=true"
EOF

cat <<EOF >$DIR/$1/service/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
#After=kube-apiserver.service
#Requires=kube-apiserver.service

[Service]
User=root
EnvironmentFile=$ROOT/etc/kube-scheduler.conf
ExecStart=/usr/local/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

#----------------kubelet--------------
cat <<EOF >$DIR/$1/etc/kubelet.conf
KUBELET_OPTS="--logtostderr=false \\
--v=2 \\
--client-ca-file=$ROOT/certs/ssl/ca.pem \\
--alsologtostderr=false \\
--log-dir=$ROOT/logs/kubelet \\
--hostname-override=$1 \\
--kubeconfig=$ROOT/certs/kubelet/kubelet.kubeconfig \\
--bootstrap-kubeconfig=$ROOT/certs/kubeconfig/kubelet-bootstrap.kubeconfig \\
--config=$ROOT/etc/kubelet-config.yml \\
--cert-dir=$ROOT/certs/kubelet \\
--root-dir=$ROOT/data/kubelet \\
--network-plugin=cni \\
--cni-conf-dir=/etc/cni/net.d \\
--cni-bin-dir=/opt/cni/bin \\
--feature-gates=TTLAfterFinished=true,RotateKubeletServerCertificate=true,RotateKubeletClientCertificate=true \\
--pod-infra-container-image=registry.cn-shanghai.aliyuncs.com/jacke/pause:3.2"
EOF

cat <<EOF >$DIR/$1/etc/kubelet-config.yml
kind: KubeletConfiguration # 使用对象
apiVersion: kubelet.config.k8s.io/v1beta1 # api版本
address: 0.0.0.0 # 监听地址
port: 10250 # 当前kubelet的端口
readOnlyPort: 0 #10255 kubelet暴露的端口
cgroupDriver: systemd # 驱动，要于docker info显示的驱动一致
clusterDNS:
  - ${COREDNS}
clusterDomain: cluster.local  # 集群域
failSwapOn: false # 关闭swap

# 身份验证
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: $ROOT/certs/ssl/ca.pem

# 授权
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s

# Node 资源保留
evictionHard:
  imagefs.available: 15%
  memory.available: 1G
  nodefs.available: 10%
  nodefs.inodesFree: 5%
evictionPressureTransitionPeriod: 5m0s

# 镜像删除策略
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
imageMinimumGCAge: 2m0s

# 旋转证书
rotateCertificates: true # 旋转kubelet client 证书
featureGates:
  RotateKubeletServerCertificate: true
  RotateKubeletClientCertificate: true

maxOpenFiles: 1000000
maxPods: 150
EOF

cat <<EOF >$DIR/$1/service/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-$ROOT/etc/kubelet.conf
ExecStart=/usr/local/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
KillMode=process
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF


#----------------kube-proxy--------------------
cat <<EOF >$DIR/$1/etc/kube-proxy.conf
KUBE_PROXY_OPTS="--logtostderr=false \\
--v=2 \\
--alsologtostderr=false \\
--log-dir=$ROOT/logs/kube-proxy \\
--config=$ROOT/etc/kube-proxy-config.yml"
EOF

cat <<EOF >$DIR/$1/etc/kube-proxy-config.yml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
address: 0.0.0.0 
metricsBindAddress: 0.0.0.0:10249
clientConnection:
  kubeconfig: $ROOT/certs/kubeconfig/kube-proxy.kubeconfig
hostnameOverride: $1
clusterCIDR: $SCR 
mode: iptables 

# 使用 ipvs 模式
#mode: ipvs # ipvs 模式
#ipvs:
#  scheduler: "rr"
#iptables:
#  masqueradeAll: true
EOF

cat <<EOF >$DIR/$1/service/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=$ROOT/etc/kube-proxy.conf
ExecStart=/usr/local/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

#第二层判断
elif [ "$2" == "node" ];then


#----------------kubelet--------------
cat << EOF >$DIR/$1/etc/kubelet.conf
KUBELET_OPTS="--logtostderr=false \\
--v=2 \\
--client-ca-file=$ROOT/certs/ssl/ca.pem \\
--alsologtostderr=false \\
--log-dir=$ROOT/logs/kubelet \\
--hostname-override=$1 \\
--kubeconfig=$ROOT/certs/kubelet/kubelet.kubeconfig \\
--bootstrap-kubeconfig=$ROOT/certs/kubeconfig/kubelet-bootstrap.kubeconfig \\
--config=$ROOT/etc/kubelet-config.yml \\
--cert-dir=$ROOT/certs/kubelet \\
--root-dir=$ROOT/data/kubelet \\
--network-plugin=cni \\
--cni-conf-dir=/etc/cni/net.d \\
--cni-bin-dir=/opt/cni/bin \\
--feature-gates=TTLAfterFinished=true,RotateKubeletServerCertificate=true,RotateKubeletClientCertificate=true \\
--pod-infra-container-image=registry.cn-shanghai.aliyuncs.com/jacke/pause:3.2"
EOF

cat <<EOF >$DIR/$1/etc/kubelet-config.yml
kind: KubeletConfiguration # 使用对象
apiVersion: kubelet.config.k8s.io/v1beta1 # api版本
address: 0.0.0.0 # 监听地址
port: 10250 # 当前kubelet的端口
readOnlyPort: 0 #10255 kubelet暴露的端口
cgroupDriver: systemd # 驱动，要于docker info显示的驱动一致
clusterDNS:
  - ${COREDNS}
clusterDomain: cluster.local  # 集群域
failSwapOn: false # 关闭swap

# 身份验证
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: $ROOT/certs/ssl/ca.pem

# 授权
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s

# Node 资源保留
evictionHard:
  imagefs.available: 15%
  memory.available: 1G
  nodefs.available: 10%
  nodefs.inodesFree: 5%
evictionPressureTransitionPeriod: 5m0s

# 镜像删除策略
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
imageMinimumGCAge: 2m0s

# 旋转证书
rotateCertificates: true # 旋转kubelet client 证书
featureGates:
  RotateKubeletServerCertificate: true
  RotateKubeletClientCertificate: true

maxOpenFiles: 1000000
maxPods: 150
EOF

cat <<EOF >$DIR/$1/service/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=$ROOT/etc/kubelet.conf
ExecStart=/usr/local/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
KillMode=process
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF


#----------------kube-proxy--------------------
cat <<EOF >$DIR/$1/etc/kube-proxy.conf
KUBE_PROXY_OPTS="--logtostderr=false \\
--v=2 \\
--alsologtostderr=false \\
--log-dir=$ROOT/logs/kube-proxy \\
--config=$ROOT/etc/kube-proxy-config.yml"
EOF

cat <<EOF >$DIR/$1/etc/kube-proxy-config.yml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
address: 0.0.0.0 # 监听地址
metricsBindAddress: 0.0.0.0:10249 # 监控指标地址,监控获取相关信息 就从这里获取
clientConnection:
  kubeconfig: $ROOT/certs/kubeconfig/kube-proxy.kubeconfig # 读取配置文件
hostnameOverride: $1 # 注册到k8s的节点名称唯一
clusterCIDR: $SCR # service IP范围
mode: iptables # 使用iptables模式

# 使用 ipvs 模式
#mode: ipvs # ipvs 模式
#ipvs:
#  scheduler: "rr"
#iptables:
#  masqueradeAll: true
EOF

cat <<EOF >$DIR/$1/service/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=$ROOT/etc/kube-proxy.conf
ExecStart=/usr/local/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

fi 

#---------公共配置------------
cat << EOF > $DIR/$1/service/calico-node.service
[Unit]
Description=calico-node
After=docker.service
Requires=docker.service

[Service]
User=root
EnvironmentFile=-/etc/calico/calico.env
ExecStartPre=-/usr/local/bin/docker rm -f calico-node
ExecStart=/usr/local/bin/docker run --net=host --privileged \\
    --name=calico-node \\
    -e NODENAME=$1  \\
    -e IP=$1 \\
    -e IP6= \\
    -e AS= \\
    -e NO_DEFAULT_POOLS= \\
    -e CALICO_STARTUP_LOGLEVEL=info \\
    -e CALICO_IPV4POOL_CIDR=$CIDR \\
    -e CALICO_IPV4POOL_IPIP=off \\
    -e CALICO_LIBNETWORK_ENABLED=true \\
    -e CALICO_NETWORKING_BACKEND=bird \\
    -e FELIX_DEFAULTENDPOINTTOHOSTACTION=ACCEPT \\
    -e FELIX_IPV6SUPPORT=false \\
    -e FELIX_LOGSEVERITYSCREEN=info \\
    -e FELIX_HEALTHENABLED=true \\
    -e CLUSTER_TYPE=k8s,bgp \\
    -e DATASTORE_TYPE=etcdv3 \\
    -e ETCD_ENDPOINTS=${ETCD_SERVERS} \\
    -e ETCD_CA_CERT_FILE=/opt/k8s/certs/ssl/ca.pem \\
    -e ETCD_CERT_FILE=/opt/k8s/certs/ssl/calico.pem \\
    -e ETCD_KEY_FILE=/opt/k8s/certs/ssl/calico-key.pem \\
    -e KUBECONFIG=/opt/k8s/certs/kubeconfig/kubectl.kubeconfig \\
    -v /var/log/calico:/var/log/calico \\
    -v /run/docker/plugins:/run/docker/plugins \\
    -v /lib/modules:/lib/modules \\
    -v /var/run/calico:/var/run/calico \\
    -v /opt/k8s/certs/ssl:/opt/k8s/certs/ssl \\
    calico/node:v3.17.2
ExecStop=/usr/local/bin/docker stop calico-node
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > $DIR/$1/etc/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "storage-driver": "overlay2",
  "storage-opts": [
     "overlay2.override_kernel_check=true"
  ]
}
EOF

cat <<EOF > $DIR/$1/service/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=-/etc/sysconfig/docker
Environment=PATH=/usr/libexec/docker:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
ExecStart=/usr/local/bin/dockerd  \\
         --selinux-enabled=false \\
         --log-opt max-size=1g \\
         --log-opt max-file=5 \\
         --log-level info \\
         --data-root $ROOT/data/docker \\
         \$OPTIONS \\
         \$INSECURE_REGISTRY
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
StartLimitBurst=3
StartLimitInterval=10s
LimitNOFILE=65535
LimitNPROC=65535
LimitCORE=65535
#TasksMax=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

