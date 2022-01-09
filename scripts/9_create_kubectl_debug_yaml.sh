#!/bin/bash
#Auth: Jack
#Date: 2021/8/23
#Version: 1.0
#Description: Deploy kubectl-debug

cat > $DIR/data/yaml/debug-agent.yaml <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: debug-agent
  name: debug-agent
spec:
  selector:
    matchLabels:
      app: debug-agent
  template:
    metadata:
      labels:
        app: debug-agent
    spec:
      hostPID: true
      tolerations:
        - key: node-role.kubernetes.io/master
          effect: NoSchedule
      containers:
        - name: debug-agent
          image: registry.cn-shanghai.aliyuncs.com/jacke/debug-agent:latest
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10027
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          ports:
            - containerPort: 10027
              hostPort: 10027
              name: http
              protocol: TCP
          volumeMounts:
            - name: cgroup
              mountPath: /sys/fs/cgroup
            - name: lxcfs
              mountPath: /var/lib/lxc
              mountPropagation: Bidirectional
            - name: docker
              mountPath: "/var/run/docker.sock"
            - name: runcontainerd
              mountPath: "/run/containerd"
            - name: runrunc
              mountPath: "/run/runc"
            - name: vardata
              mountPath: "/var/data"
      # hostNetwork: true
      volumes:
        - name: cgroup
          hostPath:
            path: /sys/fs/cgroup
        - name: lxcfs
          hostPath:
            path: /var/lib/lxc
            type: DirectoryOrCreate
        - name: docker
          hostPath:
            path: /var/run/docker.sock
        # containerd client will need to access /var/data, /run/containerd and /run/runc
        - name: vardata
          hostPath:
            path: /var/data
        - name: runcontainerd
          hostPath:
            path: /run/containerd
        - name: runrunc
          hostPath:
            path: /run/runc
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 5
    type: RollingUpdate
EOF


cat > $DIR/data/yaml/debug-config <<EOF
agentPort: 10027
agentless: false
agentPodNamespace: default
agentPodNamePrefix: debug-agent-pod
agentImage: registry.cn-shanghai.aliyuncs.com/jacke/debug-agent:latest
debugAgentDaemonset: debug-agent
debugAgentNamespace: default
portForward: false
image: registry.cn-shanghai.aliyuncs.com/jacke/busybox:latest
command:
- '/bin/sh'
- '-l'
registrySecretName: my-debug-secret
registrySecretNamespace: debug
agentCpuRequests: "100m"
agentCpuLimits: "300m"
agentMemoryRequests: "100Mi"
agentMemoryLimits: "200Mi"
forkPodRetainLabels: []
registrySkipTLSVerify: false
verbosity : 0
EOF
