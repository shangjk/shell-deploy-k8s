注意事项：
1、env.yml文件为运行配置文件，必须存在
2、run.sh要在env.yml所在目录运行
3、请注意本地用于与远程主机是否可免密ssh
4、部分操作需要root权限，请主机远程用户需要有root权限

HARBOR: harbor地址
SCR:  service clusterIP 网段，默认是192.168.0.0/16
CIDR: pod 网段
VIP: master apiserver的vip，域名形式
MASTER: master 节点ip，空格隔开
NODES: node 节点ip，空格隔开
KUBERNETES_SVC_IP: 集群内部访问的apiserver的IP，通常是service clusterIP网段的首个IP地址，默认是：192.168.0.1
COREDNS: coredns的svc clusterip,通常是service clusterip 网段的第二个IP地址，默认：192.168.0.2
ROOT: 目标安装路径
NTPSERVER: ntpserver的地址
CALICO_NETWORK_NODE: calico网络模式，BGP or IPIP
NAMESPACES: namespace，多个以空格隔开
ES_NODES: elasticsearch节点地址，多个以空格隔开

目标主机目录结构示例如下：
/opt/
└── k8s
    ├── certs
    │   ├── kubeconfig
    │   ├── kubelet
    │   └── ssl
    ├── data
    │   ├── docker
    │   ├── etcd
    │   └── kubelet
    ├── etc
    └── logs
        ├── docker
        ├── etcd
        ├── kube-apiserver
        ├── kube-controller-manager
        ├── kubelet
        ├── kube-proxy
        └── kube-scheduler

