#!/usr/bin/bash
#Auth: Jack
#Date: 2021/1/12
#Version: 1.0
#Description: 生成TLS签名证书

#环境变量
MASTER=$(grep MASTER env.yml |awk -F ":" '{print $2}'| sed 's/^[ \t]*//g'|sed 's/[ ]/","/g')
#MASTER=($(grep MASTER env.yml |awk -F ":" '{print $2}'| sed 's/^[ \t]*//g'))
# VIP=$(grep VIP env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')
# KUBERNETES_SVC_IP=$(grep KUBERNETES_SVC_IP env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g') 
# DIR=$(pwd)

#创建一个临时目录生成证书请求文件
mkdir -p $DIR/csr &> /dev/null 

#生成证书请求文件
cat > $DIR/csr/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "876000h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "876000h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

cat > $DIR/csr/ca-csr.json <<EOF
{
    "CN": "kubernetes-ca",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C":  "CN",
        "L":  "Shanghai",
        "ST": "Shanghai",
        "O":  "LU",
        "OU": "System"
      }
    ],
    "CA": {
        "expiry": "876000h",
        "pathlen": 0
    }
}
EOF

#-----------------------

cat > $DIR/csr/server-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "$MASTER",
    "$VIP",
    "$KUBERNETES_SVC_IP",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "Lu",
      "OU": "LuSystem"
    }
  ]
}
EOF

#-----------------------
cat > $DIR/csr/etcd.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "$VIP",
    "$MASTER"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "Lu",
      "OU": "LuSystem"
    }
  ]
}
EOF
#-----------------------

cat > $DIR/csr/kube-controller-manager.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "hosts": [
    "127.0.0.1",
    "$VIP",
    "$MASTER"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "system:kube-controller-manager",
      "OU": "LuSystem"
    }
  ]
}
EOF

#-----------------------

cat > $DIR/csr/kube-scheduler.json <<EOF
{
  "CN": "system:kube-scheduler",
  "hosts": [
    "127.0.0.1",
    "$MASTER"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "system:kube-scheduler",
      "OU": "LuSystem"
    }
  ]
}
EOF

#----------------------
cat > $DIR/csr/calico.json <<EOF
{
  "CN": "calico",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "Lu:masters",
      "OU": "LuSystem"
    }
  ]
}
EOF

#-----------------------
cat > $DIR/csr/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "system:masters",
      "OU": "LuSystem"
    }
  ]
}
EOF

#-----------------------

cat > $DIR/csr/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "Lu:masters",
      "OU": "LuSystem"
    }
  ]
}
EOF

#-----------------------
cat > $DIR/csr/metrics-server-csr.json <<EOF
{
  "CN": "aggregator",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ShangHai",
      "L": "ShangHai",
      "O": "Lu",
      "OU": "LuSystem"
    }
  ]
}
EOF

#生成证书存放目录
mkdir -p $DIR/certs/ssl &> /dev/null
rm -f $DIR/certs/ssl/*
cd $DIR/certs/ssl 
#生成证书请求文件
cfssl gencert -initca $DIR/csr/ca-csr.json | cfssljson -bare ca -
[[ "$?" != "0" ]] && echo -e "\033[1;31m[ERROR] CA cert create failed!\033[0m"
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/server-csr.json | cfssljson -bare server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/admin-csr.json | cfssljson -bare admin
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/kube-proxy-csr.json | cfssljson -bare kube-proxy
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/metrics-server-csr.json | cfssljson -bare metrics-server
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/etcd.json |cfssljson -bare etcd
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/kube-controller-manager.json |cfssljson -bare kube-controller-manager
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/kube-scheduler.json |cfssljson -bare kube-scheduler
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=$DIR/csr/ca-config.json -profile=kubernetes  $DIR/csr/calico.json |cfssljson -bare calico


#生成公私钥对
openssl genrsa -out sa.key 2048 && openssl rsa -in sa.key -pubout -out sa.pub

#清理多余的文件
rm -f  $DIR/certs/ssl/*.csr
rm -fr $DIR/csr


