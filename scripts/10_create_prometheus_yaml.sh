#!/bin/bash
#Auth: Jack
#Date: 2021/3/21
#Version: 1.0
#Description: create prometheus yaml


NAMESPACES=$1
MASTER1=$2
MASTER2=$3
MASTER3=$4

cat > $DIR/data/yaml/prometheus.yaml <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: EnsureExists
data:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    route:
      group_by: ['severity','name','namespace']
      group_wait: 20s
      group_interval: 5m
      repeat_interval: 4h
      receiver: alarm
    receivers:
    - name: 'alarm'
      webhook_configs:
      - send_resolved: true
        url: http://alarmtransfer.devops.lufax.tool/k8s-alarm
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$1
    kubernetes.io/ingress.class: ${NAMESPACES}
  name: alertmanager-ingress
  namespace: monitoring
spec:
  rules:
  - host: cops-${NAMESPACES}.dev.lufax.com
    http:
      paths:
      - backend:
          serviceName: alertmanager
          servicePort: 9093
        path: /alertmanager/(.*)
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: alertmanager
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: alertmanager
  namespace: monitoring
  labels:
    k8s-app: alertmanager
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    version: v0.21.0
spec:
  podManagementPolicy: OrderedReady
  replicas: 2
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: alertmanager
      version: v0.21.0
  serviceName: alertmanager
  template:
    metadata:
      labels:
        k8s-app: alertmanager
        version: v0.21.0
    spec:
      priorityClassName: system-cluster-critical
      containers:
        - name: alertmanager
          image: "registry.cn-shanghai.aliyuncs.com/jacke/alertmanager:v0.21.0"
          imagePullPolicy: "IfNotPresent"
          args:
            - --config.file=/etc/config/alertmanager.yaml
            - --cluster.listen-address=[\$(POD_IP)]:6783
            - --data.retention=120h
            - --web.listen-address=:9093
            - --storage.path=/data
            - --cluster.peer=alertmanager-0.alertmanager.monitoring.svc:6783
            - --cluster.peer=alertmanager-1.alertmanager.monitoring.svc:6783
          env:
          - name: POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP 
          ports:
            - containerPort: 9093
              name: web
              protocol: TCP 
            - containerPort: 6783
              name: mesh 
              protocol: TCP 
          readinessProbe:
            httpGet:
              path: /api/v1/status
              port: 9093
              scheme: HTTP 
            failureThreshold: 5
            successThreshold: 1
            periodSeconds: 5
            initialDelaySeconds: 20
            timeoutSeconds: 20
          livenessProbe:
            httpGet:
              path: /api/v1/status
              port: 9093
              scheme: HTTP 
            failureThreshold: 5
            successThreshold: 1
            periodSeconds: 5
            initialDelaySeconds: 20
            timeoutSeconds: 20
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
            - name: storage-volume
              mountPath: "/data"
              subPath: ""
          resources:
            limits:
              cpu: 200m
              memory: 200Mi
            requests:
              cpu: 100m
              memory: 100Mi
        - name: prometheus-alertmanager-configmap-reload
          image: "registry.cn-shanghai.aliyuncs.com/jacke/configmap-reload:v0.5.0"
          imagePullPolicy: "IfNotPresent"
          args:
            - --volume-dir=/etc/config
            - --webhook-url=http://localhost:9093/-/reload
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
              readOnly: true
          resources:
            limits:
              cpu: 20m
              memory: 20Mi
            requests:
              cpu: 20m
              memory: 20Mi
      dnsPolicy: ClusterFirst
      nodeSelector:
        beta.kubernetes.io/os: linux
      restartPolicy: Always
      schedulerName: default-scheduler
      serviceAccount: alertmanager
      serviceAccountName: alertmanager
      volumes:
        - name: config-volume
          configMap:
            name: alertmanager-config
        - name: storage-volume
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "Alertmanager"
spec:
  ports:
    - name: web
      port: 9093
      protocol: TCP
      targetPort: 9093
    - name: mesh 
      port: 6783
      protocol: TCP
      targetPort: 6783
  selector:
    k8s-app: alertmanager
  type: "ClusterIP"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-state-metrics
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-state-metrics
subjects:
- kind: ServiceAccount
  name: kube-state-metrics
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kube-state-metrics
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups: [""]
  resources:
  - configmaps
  - secrets
  - nodes
  - pods
  - services
  - resourcequotas
  - replicationcontrollers
  - limitranges
  - persistentvolumeclaims
  - persistentvolumes
  - namespaces
  - endpoints
  verbs: ["list", "watch"]
- apiGroups: ["extensions","apps"]
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs: ["list", "watch"]
- apiGroups: ["apps"]
  resources:
  - statefulsets
  verbs: ["list", "watch"]
- apiGroups: ["batch"]
  resources:
  - cronjobs
  - jobs
  verbs: ["list", "watch"]
- apiGroups: ["autoscaling"]
  resources:
  - horizontalpodautoscalers
  verbs: ["list", "watch"]
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-state-metrics-config
  namespace: monitoring
  labels:
    k8s-app: kube-state-metrics
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
data:
  NannyConfiguration: |-
    apiVersion: nannyconfig/v1alpha1
    kind: NannyConfiguration
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    k8s-app: kube-state-metrics
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  selector:
    matchLabels:
      k8s-app: kube-state-metrics
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kube-state-metrics
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        k8s-app: kube-state-metrics
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: kube-state-metrics
      containers:
      - name: kube-state-metrics
        image: registry.cn-shanghai.aliyuncs.com/jacke/kube-state-metrics:v2.1.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: http-metrics
          containerPort: 8080
        - name: telemetry
          containerPort: 8081
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          failureThreshold: 3
          successThreshold: 1
          initialDelaySeconds: 10
          timeoutSeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          failureThreshold: 3
          successThreshold: 1
          initialDelaySeconds: 10
          timeoutSeconds: 5
          periodSeconds: 5
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
          requests:
            cpu: 100m 
            memory: 100Mi
      - name: addon-resizer
        image: registry.cn-shanghai.aliyuncs.com/jacke/addon-resizer:1.8.7
        resources:
          limits:
            cpu: 150m
            memory: 60Mi
          requests:
            cpu: 100m
            memory: 30Mi
        env:
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
        volumeMounts:
          - name: config-volume
            mountPath: /etc/config
        command:
          - /pod_nanny
          - --config-dir=/etc/config
          - --container=kube-state-metrics
          - --cpu=100m
          - --extra-cpu=2m
          - --memory=100Mi
          - --extra-memory=20Mi
          - --threshold=5
          - --deployment=kube-state-metrics
      volumes:
        - name: config-volume
          configMap:
            name: kube-state-metrics-config
      dnsPolicy: ClusterFirst
      nodeSelector:
        beta.kubernetes.io/os: linux
      restartPolicy: Always
      schedulerName: default-scheduler
      serviceAccount: kube-state-metrics
      serviceAccountName: kube-state-metrics
      terminationGracePeriodSeconds: 30
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: kube-state-metrics-resizer
subjects:
- kind: ServiceAccount
  name: kube-state-metrics
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: kube-state-metrics-resizer
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
rules:
- apiGroups: [""]
  resources:
  - pods
  verbs: ["get"]
- apiGroups: ["extensions","apps"]
  resources:
  - deployments
  resourceNames: ["kube-state-metrics"]
  verbs: ["get", "update"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-state-metrics
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "kube-state-metrics"
    k8s-app: kube-state-metrics
  annotations:
    prometheus.io/scrape: 'true'
spec:
  ports:
  - name: http-metrics
    port: 8080
    targetPort: http-metrics
    protocol: TCP
  - name: telemetry
    port: 8081
    targetPort: telemetry
    protocol: TCP
  selector:
    k8s-app: kube-state-metrics
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    k8s-app: node-exporter
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    version: v1.1.2
spec:
  selector:
    matchLabels:
      k8s-app: node-exporter
      version: v1.1.2
  updateStrategy:
    type: OnDelete
  template:
    metadata:
      labels:
        k8s-app: node-exporter
        version: v1.1.2
    spec:
      priorityClassName: system-node-critical
      containers:
        - name: prometheus-node-exporter
          image: "registry.cn-shanghai.aliyuncs.com/jacke/node-exporter:v1.1.2"
          imagePullPolicy: "IfNotPresent"
          args:
            - --path.procfs=/host/proc
            - --path.sysfs=/host/sys
          ports:
            - name: metrics
              containerPort: 9100
              hostPort: 9100
          volumeMounts:
            - name: proc
              mountPath: /host/proc
              readOnly:  true
            - name: sys
              mountPath: /host/sys
              readOnly: true
          resources:
            limits:
              cpu: 250m
              memory: 250Mi
            requests:
              cpu: 100m
              memory: 100Mi
      hostNetwork: true
      hostPID: true
      dnsPolicy: ClusterFirst
      nodeSelector:
        beta.kubernetes.io/os: linux
      restartPolicy: Always
      schedulerName: default-scheduler
      serviceAccount: node-exporter
      serviceAccountName: node-exporter
      terminationGracePeriodSeconds: 30
      tolerations:
      - effect: NoExecute
        operator: Exists 
      - effect: NoSchedule
        operator: Exists
      volumes:
        - name: proc
          hostPath:
            path: /proc
        - name: sys
          hostPath:
            path: /sys
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: node-exporter
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: v1
kind: Service
metadata:
  name: node-exporter
  namespace: monitoring
  annotations:
    prometheus.io/scrape: "true"
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "NodeExporter"
    k8s-app: node-exporter
spec:
  clusterIP: None
  ports:
    - name: metrics
      port: 9100
      protocol: TCP
      targetPort: 9100
  selector:
    k8s-app: node-exporter
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
rules:
  - apiGroups:
      - ""
    resources:
      - nodes
      - nodes/metrics
      - services
      - endpoints
      - pods
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - get
  - nonResourceURLs:
      - "/metrics"
    verbs:
      - get
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: EnsureExists
data:
  prometheus.yml: |
    global:
      evaluation_interval: 30s
      scrape_interval: 30s
      scrape_timeout: 10s
      external_labels:
        prometheus: monitoring/k8s 
        prometheus_replica: prometheus-k8s-0
    rule_files:
    - /etc/config/rules/*.yaml
    scrape_configs:
    - job_name: prometheus
      static_configs:
      - targets:
        - localhost:9090

    - job_name: kubernetes-controller-manager
      honor_labels: true
      scheme: http
      tls_config:
        insecure_skip_verify: true
      static_configs:
      - targets:
        - '${MASTER1}:10252'
        - '${MASTER2}:10252'
        - '${MASTER3}:10252'
      relabel_configs:
      - target_label: job
        replacement: kube-controller-manager

    - job_name: kubernetes-scheduler
      honor_labels: true
      scheme: http
      tls_config:
        insecure_skip_verify: true
      static_configs:
      - targets:
        - '${MASTER1}:10251'
        - '${MASTER2}:10251'
        - '${MASTER3}:10251'
      relabel_configs:
      - target_label: job
        replacement: kube-scheduler

    - job_name: kubernetes-etcd
      honor_labels: true
      scrape_interval: 30s
      scheme: https
      tls_config:
        ca_file: /etc/config/etcd-certs/ca.pem
        cert_file: /etc/config/etcd-certs/etcd.pem
        key_file: /etc/config/etcd-certs/etcd-key.pem
      static_configs:
      - targets:
        - '${MASTER1}:2379'
        - '${MASTER2}:2379'
        - '${MASTER3}:2379'
      relabel_configs:
      - target_label: endpoint
        replacement: etcd
      - target_label: job
        replacement: etcd

    - job_name: kubernetes-apiservers
      honor_labels: true
      kubernetes_sd_configs:
      - role: endpoints
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: keep
        regex: default;kubernetes;https
        source_labels:
        - __meta_kubernetes_namespace
        - __meta_kubernetes_service_name
        - __meta_kubernetes_endpoint_port_name
      - target_label: job
        replacement: kube-apiserver

    - job_name: kubernetes-coredns
      honor_labels: true
      kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
          - kube-system
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      scheme: http
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      relabel_configs:
      - action: keep
        source_labels:
        - __meta_kubernetes_service_label_k8s_app
        regex: kube-dns
      - action: keep
        source_labels:
        - __meta_kubernetes_endpoint_port_name
        regex: metrics
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Node;(.*)
        replacement: \${1}
        target_label: node
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Pod;(.*)
        replacement: \${1}
        target_label: pod
      - source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - source_labels:
        - __meta_kubernetes_service_name
        target_label: service
      - source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - source_labels:
        - __meta_kubernetes_service_label_k8s_app
        target_label: job
        regex: (.+)
        replacement: \${1}
      - target_label: endpoint
        replacement: metrics

    - job_name: kubernetes-fluentd-es-cntr
      honor_labels: true
      kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
          - kube-system
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      scheme: http
      relabel_configs:
      - action: keep
        source_labels:
        - __meta_kubernetes_service_label_k8s_app
        regex: fluentd-es
      - action: keep
        source_labels:
        - __meta_kubernetes_endpoint_port_name
        regex: healthz
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Node;(.*)
        replacement: \${1}
        target_label: node
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Pod;(.*)
        replacement: \${1}
        target_label: pod
      - source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - source_labels:
        - __meta_kubernetes_service_name
        target_label: service
      - source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - source_labels:
        - __meta_kubernetes_service_label_k8s_app
        target_label: job
        regex: (.+)
        replacement: \${1}
      - target_label: endpoint
        replacement: fluentd-es

    - job_name: kube-ingress-nginx-${NAMESPACES}
      honor_labels: true
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
          - ingress-nginx 
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      scheme: http
      relabel_configs:
      - action: keep
        source_labels:
        - __meta_kubernetes_pod_label_app
        regex: nginx-ingress-controller-${NAMESPACES}
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: \$1:\$2
      - source_labels:
        - __meta_kubernetes_pod_name
        regex: (.*)
        target_label: pod
      - source_labels:
        - __meta_kubernetes_namespace
        regex: ingress-nginx
        target_label: namespace
        action: keep
      - source_labels:
        - __meta_kubernetes_pod_node_name
        regex: (.*)
        target_label: node
      - target_label: endpoint
        replacement: kube-ingress-nginx


    - job_name: kube-jmx-${NAMESPACES}
      honor_labels: true
      kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
          - ${NAMESPACES}
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      scheme: http
      relabel_configs:
      - action: keep
        source_labels:
        - __meta_kubernetes_service_label_app
        regex: (.*)
      - action: keep
        source_labels:
        - __meta_kubernetes_endpoint_port_name
        regex: jmx
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Node;(.*)
        replacement: \${1}
        target_label: node
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Pod;(.*)
        replacement: \${1}
        target_label: pod
      - source_labels:
        - __meta_kubernetes_namespace
        target_label: namespace
      - source_labels:
        - __meta_kubernetes_service_name
        target_label: service
      - source_labels:
        - __meta_kubernetes_pod_name
        target_label: pod
      - source_labels:
        - __meta_kubernetes_service_label_jmx_${NAMESPACES}
        target_label: job
        regex: (.+)
        replacement: \${1}
      - target_label: endpoint
        replacement: jmx

    - job_name: kubernetes-nodes-kubelet
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

    - job_name: kubernetes-nodes-cadvisor
      honor_labels: true
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - target_label: __metrics_path__
        replacement: /metrics/cadvisor
      scheme: https
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

    - job_name: kubernetes-kube-proxy
      honor_labels: true
      kubernetes_sd_configs:
      - role: node
      scheme: http
      tls_config:
        ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        insecure_skip_verify: true
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - source_labels: 
        - __address__
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?
        replacement: \$1:10249
      - target_label: job
        replacement: kube-proxy

    - job_name: kubernetes-pods
      honor_labels: true
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_scrape
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_pod_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: \$1:\$2
        source_labels:
        - __address__
        - __meta_kubernetes_pod_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: kubernetes_namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_pod_name
        target_label: kubernetes_pod_name

    - job_name: kubernetes-node-exporter
      honor_labels: true
      metrics_path: /metrics
      kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
          - monitoring
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      tls_config:
        insecure_skip_verify: true
      scheme: http
      relabel_configs:
      - action: keep
        source_labels:
        - __meta_kubernetes_service_label_k8s_app
        regex: node-exporter
        replacement: \$1
      - action: keep
        source_labels:
        - __meta_kubernetes_endpoint_port_name
        regex: metrics
        replacement: \$1
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Node;(.*)
        replacement: \${1}
        target_label: node
      - source_labels:
        - __meta_kubernetes_endpoint_address_target_kind
        - __meta_kubernetes_endpoint_address_target_name
        separator: ;
        regex: Pod;(.*)
        replacement: \${1}
        target_label: pod
      - source_labels:
        - __meta_kubernetes_namespace
        separator: ;
        regex: monitoring
        replacement: \$1
        target_label: namespace
      - source_labels:
        - __meta_kubernetes_service_name
        separator: ;
        regex: node-exporter
        replacement: \$1
        target_label: service
      - source_labels:
        - __meta_kubernetes_pod_name
        separator: ;
        regex: (.*)
        replacement: \$1
        target_label: pod
      - source_labels:
        - __meta_kubernetes_pod_node_name
        separator: ;
        regex: (.*)
        replacement: \$1
        target_label: node
      - source_labels:
        - __meta_kubernetes_service_name
        target_label: job
        regex: (.+)
        replacement: \${1}
      - target_label: endpoint
        replacement: node-exporter

    - job_name: kube-state-metrics-main
      honor_labels: true
      metrics_path: /metrics
      scheme: http
      kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
          - monitoring
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      tls_config:
        insecure_skip_verify: true
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_label_k8s_app]
        separator: ;
        regex: kube-state-metrics
        replacement: \$1
        action: keep
      - source_labels: [__meta_kubernetes_endpoint_port_name]
        separator: ;
        regex: http-metrics
        replacement: \$1
        action: keep
      - source_labels: [__meta_kubernetes_endpoint_address_target_kind, __meta_kubernetes_endpoint_address_target_name]
        separator: ;
        regex: Node,(.*)
        target_label: node
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_endpoint_address_target_kind, __meta_kubernetes_endpoint_address_target_name]
        separator: ;
        regex: Pod,(.*)
        target_label: pod
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_namespace]
        separator: ;
        regex: (.*)
        target_label: namespace
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_service_name]
        separator: ;
        regex: (.*)
        target_label: service
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_pod_name]
        separator: ;
        regex: (.*)
        target_label: pod
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_service_label_k8s_app]
        separator: ;
        regex: (.*)
        target_label: job
        replacement: \$1
        action: replace
      - separator: ;
        regex: (.*)
        target_label: endpoint
        replacement: http-metrics
        action: replace
        
    - job_name: kube-state-metrics-telemetry
      honor_labels: true
      metrics_path: /metrics
      scheme: http
      kubernetes_sd_configs:
      - role: endpoints
        namespaces:
          names:
          - monitoring
      bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
      tls_config:
        insecure_skip_verify: true
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_label_k8s_app]
        separator: ;
        regex: kube-state-metrics
        replacement: \$1
        action: keep
      - source_labels: [__meta_kubernetes_endpoint_port_name]
        separator: ;
        regex: telemetry
        replacement: \$1
        action: keep
      - source_labels: [__meta_kubernetes_endpoint_address_target_kind, __meta_kubernetes_endpoint_address_target_name]
        separator: ;
        regex: Node,(.*)
        target_label: node
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_endpoint_address_target_kind, __meta_kubernetes_endpoint_address_target_name]
        separator: ;
        regex: Pod,(.*)
        target_label: pod
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_namespace]
        separator: ;
        regex: (.*)
        target_label: namespace
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_service_name]
        separator: ;
        regex: (.*)
        target_label: service
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_pod_name]
        separator: ;
        regex: (.*)
        target_label: pod
        replacement: \$1
        action: replace
      - source_labels: [__meta_kubernetes_service_label_k8s_app]
        separator: ;
        regex: (.*)
        target_label: job
        replacement: \$1
        action: replace
      - separator: ;
        regex: (.*)
        target_label: endpoint
        replacement: telemetry
        action: replace

    alerting:
      alert_relabel_configs:
      - action: labeldrop
        regex: prometheus_replica
      alertmanagers:
      - path_prefix: /alertrmanager
        scheme: http
      - kubernetes_sd_configs:
          - role: endpoints
            namespaces:
              names:
              - monitoring
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace]
          regex: monitoring
          action: keep
        - source_labels: [__meta_kubernetes_service_name]
          regex: alertmanager
          action: keep
        - source_labels: [__meta_kubernetes_endpoint_port_name]
          regex: web
          action: keep
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: EnsureExists
data:
  monitoring-prometheus-api-rules.yaml: |
    groups:
    - interval: 30s
      name: apiserver-rules
      rules:
      - alert: A1-sys-ApiServerNotReady
        annotations:
          appname: k8s-master
          description: Apiserver {{ \$labels.instance }} not Ready
          summary: Apiserver {{ \$labels.instance }} not Ready
        expr: up{job='kube-apiserver'} != 1
        for: 1m
        labels:
          severity: A1

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /\$1
    kubernetes.io/ingress.class: ${NAMESPACES}
  name: prometheus-ingress
  namespace: monitoring
spec:
  rules:
  - host: prometheus-${NAMESPACES}.jiake.shang
    http:
      paths:
      - backend:
          serviceName: prometheus
          servicePort: 9090
        path: /prometheus/(.*)
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    kubernetes.io/name: "Prometheus"
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
spec:
  ports:
  - name: http
    port: 9090
    protocol: TCP
    targetPort: 9090
  type: ClusterIP
  selector:
    k8s-app: prometheus
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus
  namespace: monitoring
  labels:
    k8s-app: prometheus
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    version: v2.26.0
spec:
  serviceName: "prometheus"
  replicas: 1
  podManagementPolicy: "Parallel"
  updateStrategy:
   type: "RollingUpdate"
  selector:
    matchLabels:
      k8s-app: prometheus
  template:
    metadata:
      labels:
        k8s-app: prometheus
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: prometheus
      initContainers:
      - name: "init-chown-data"
        image: "registry.cn-shanghai.aliyuncs.com/jacke/busybox:latest"
        imagePullPolicy: "IfNotPresent"
        command: ["chown", "-R", "65534:65534", "/data"]
        volumeMounts:
        - name: prometheus-data
          mountPath: /data
          subPath: ""
      containers:
        - name: prometheus-server-configmap-reload
          image: "registry.cn-shanghai.aliyuncs.com/jacke/configmap-reload:v0.5.0"
          imagePullPolicy: "IfNotPresent"
          args:
            - --volume-dir=/etc/config
            - --webhook-url=http://localhost:9090/-/reload
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
              readOnly: true
            - name: config-rules
              mountPath: /etc/config/rules
              readOnly: true
          resources:
            limits:
              cpu: 10m
              memory: 10Mi
            requests:
              cpu: 10m
              memory: 10Mi
        - name: prometheus
          image: "registry.cn-shanghai.aliyuncs.com/jacke/prometheus:v2.26.0"
          imagePullPolicy: "IfNotPresent"
          args:
            - --config.file=/etc/config/prometheus.yml
            - --storage.tsdb.path=/data
            - --storage.tsdb.retention=7d
            - --storage.tsdb.no-lockfile
            - --web.console.libraries=/etc/prometheus/console_libraries
            - --web.console.templates=/etc/prometheus/consoles
            - --web.enable-lifecycle
            - --log.level=info 
            - --log.format=logfmt
          ports:
            - containerPort: 9090
              name: web
              protocol: TCP
          readinessProbe:
            httpGet:
              path: /-/ready
              port: 9090
              scheme: HTTP
            failureThreshold: 3
            successThreshold: 1
            initialDelaySeconds: 30
            timeoutSeconds: 10
            periodSeconds: 5
          livenessProbe:
            httpGet:
              path: /-/healthy
              port: 9090
              scheme: HTTP
            failureThreshold: 3
            successThreshold: 1
            initialDelaySeconds: 30
            timeoutSeconds: 10
            periodSeconds: 5
          resources:
            limits:
              cpu: 500m
              memory: 4096Mi
            requests:
              cpu: 200m
              memory: 1000Mi
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
            - name: prometheus-data
              mountPath: /data
              subPath: ""
            - name: etcd-certs
              mountPath: /etc/config/etcd-certs
            - name: config-rules
              mountPath: /etc/config/rules
      nodeSelector:
        prometheus: "true"
      restartPolicy: Always
      schedulerName: default-scheduler
      serviceAccount: prometheus
      serviceAccountName: prometheus
      terminationGracePeriodSeconds: 300
      volumes:
        - name: config-volume
          configMap:
            name: prometheus-config
        - name: config-rules
          configMap:
            name: prometheus-rules
        - name: prometheus-data
          hostPath:
            path: /opt/k8s/data/prometheus-pv
        - name: etcd-certs
          secret:
            defaultMode: 444
            secretName: etcd-certs
---
EOF
