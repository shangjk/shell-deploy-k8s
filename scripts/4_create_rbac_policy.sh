#!/usr/bin/bash
#Auth: Jack
#Date: 2021/1/12
#Version: 1.0
#Description: clusterrolebinding

#创建 Node节点 授权用户 kubelet-bootstrap
#kubectl create clusterrolebinding  kubelet-bootstrap --clusterrole=system:node-bootstrapper  --user=kubelet-bootstrap

#创建自动批准相关 CSR 请求的 ClusterRole
cat <<EOF > $DIR/data/yaml/tls-instructs-csr.yaml 
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeserver
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
EOF


#自动批准kubelet-bootstrap用户首次申请证书的csr请求
#kubectl create clusterrolebinding node-client-auto-approve-csr --clusterrole=system:certificates.k8s.io:certificatesigningrequests:nodeclient --user=kubelet-bootstrap

#自动批准 system:nodes 组用户更新 kubelet 自身与 apiserver 通讯证书的 CSR 请求
#kubectl create clusterrolebinding node-client-auto-renew-crt --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeclient --group=system:nodes

#自动批准 system:nodes 组用户更新 kubelet 10250 api 端口证书的 CSR 请求
#kubectl create clusterrolebinding node-server-auto-renew-crt --clusterrole=system:certificates.k8s.io:certificatesigningrequests:selfnodeserver --group=system:nodes

#创建clusterrolebinding yaml
cat << EOF > $DIR/data/yaml/rbac-clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubelet-bootstrap
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node-bootstrapper
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: kubelet-bootstrap
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-client-auto-approve-csr
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: kubelet-bootstrap
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-client-auto-renew-crt
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-server-auto-renew-crt
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeserver
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubelet-api-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kubelet-api-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: kubernetes
EOF



#批准kube-apiserver查询pod日志

#cat << EOF > apiserver-to-kubelet-rbac.yml
#kind: ClusterRoleBinding
#apiVersion: rbac.authorization.k8s.io/v1
#metadata:
#  name: kubelet-api-admin
#subjects:
#- kind: User
#  name: kubernetes
#  apiGroup: rbac.authorization.k8s.io
#roleRef:
#  kind: ClusterRole
#  name: system:kubelet-api-admin
#  apiGroup: rbac.authorization.k8s.io
#EOF

####
