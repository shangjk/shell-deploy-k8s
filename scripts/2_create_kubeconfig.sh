#!/usr/bin/bash
# Author: Jack
# Date: 2020/9/6
# Description: Create kubeconfig

# 环境变量
# VIP=$(grep VIP env.yml |awk -F ":" '{print $2}'|sed 's/^[ \t]*//g')
# DIR=$(pwd)

#创建TLS Bootstrapping Token
# 生成token.csv,采用静态token文件的认证方式，该文件安全级别较高，请注意设置文件权限
mkdir -p $DIR/certs/kubeconfig &> /dev/null 
rm -f $DIR/certs/kubeconfig/*
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x|tr -d ' ')
cat > $DIR/certs/kubeconfig/token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
export KUBE_APISERVER="https://$VIP:6443"
cd $DIR/certs/kubeconfig

# 生成kubelet-bootstrap.kubeconfig
kubectl config set-cluster kubernetes \
     --certificate-authority=$DIR/certs/ssl/ca.pem \
     --embed-certs=true \
     --server=${KUBE_APISERVER} \
     --kubeconfig=kubelet-bootstrap.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
     --token=${BOOTSTRAP_TOKEN} \
     --kubeconfig=kubelet-bootstrap.kubeconfig
# 设置上下文参数
kubectl config set-context default \
     --cluster=kubernetes \
     --user=kubelet-bootstrap \
     --kubeconfig=kubelet-bootstrap.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kubelet-bootstrap.kubeconfig
#echo -e "\033[32m kubelet-bootstrap.kubeconfig created! \033[0m"

##### 生成kubectl.kubeconfig 文件 ####
kubectl config set-cluster kubernetes \
     --certificate-authority=$DIR/certs/ssl/ca.pem \
     --embed-certs=true \
     --server=${KUBE_APISERVER} \
     --kubeconfig=kubectl.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials admin \
     --client-certificate=$DIR/certs/ssl/admin.pem \
     --client-key=$DIR/certs/ssl/admin-key.pem \
     --embed-certs=true \
     --kubeconfig=kubectl.kubeconfig
# 设置上下文参数
kubectl config set-context kubernetes \
     --cluster=kubernetes \
     --user=admin \
     --kubeconfig=kubectl.kubeconfig
# 设置默认上下文
kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig
#echo -e "\033[32m kubectl.kubeconfig created! \033[0m"


#### 生成kube-proxy.kubeconfig 文件 ####
kubectl config set-cluster kubernetes \
     --certificate-authority=$DIR/certs/ssl/ca.pem \
     --embed-certs=true \
     --server=${KUBE_APISERVER} \
     --kubeconfig=kube-proxy.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials kube-proxy \
     --client-certificate=$DIR/certs/ssl/kube-proxy.pem \
     --client-key=$DIR/certs/ssl/kube-proxy-key.pem \
     --embed-certs=true \
     --kubeconfig=kube-proxy.kubeconfig
# 设置上下文参数
kubectl config set-context default \
     --cluster=kubernetes \
     --user=kube-proxy \
     --kubeconfig=kube-proxy.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
#echo -e "\033[32m kube-proxy.kubeconfig created! \033[0m"


# #### 生成kube-scheduler.kubeconfig ####
kubectl config set-cluster kubernetes \
     --certificate-authority=$DIR/certs/ssl/ca.pem \
     --embed-certs=true \
     --server=${KUBE_APISERVER} \
     --kubeconfig=kube-scheduler.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials system:kube-scheduler \
     --client-certificate=$DIR/certs/ssl/kube-scheduler.pem \
     --client-key=$DIR/certs/ssl/kube-scheduler-key.pem \
     --embed-certs=true \
     --kubeconfig=kube-scheduler.kubeconfig
# 设置上下文参数
kubectl config set-context default \
     --cluster=kubernetes \
     --user=system:kube-scheduler \
     --kubeconfig=kube-scheduler.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
#echo -e "\033[32m kube-scheduler.kubeconfig created! \033[0m"
#### 生成kube-controller-manager.kubeconfig ####
kubectl config set-cluster kubernetes \
     --certificate-authority=$DIR/certs/ssl/ca.pem \
     --embed-certs=true \
     --server=${KUBE_APISERVER} \
     --kubeconfig=kube-controller-manager.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials system:kube-controller-manager \
     --client-certificate=$DIR/certs/ssl/kube-controller-manager.pem \
     --client-key=$DIR/certs/ssl/kube-controller-manager-key.pem \
     --embed-certs=true \
     --kubeconfig=kube-controller-manager.kubeconfig
 # 设置上下文参数
kubectl config set-context default \
     --cluster=kubernetes \
     --user=system:kube-controller-manager \
     --kubeconfig=kube-controller-manager.kubeconfig
 # 设置默认上下文
kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
# echo -e "\033[32m kube-controller-manager.kubeconfig created! \033[0m"
