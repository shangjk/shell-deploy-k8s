#!/usr/bin/bash
#Auth: Jack
#Date: 2021/3/7
#Version: 1.0
#Description: create ingress yaml

NS=$1
cat > $DIR/data/yaml/ingress-controller-${NS}.yaml <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: nginx-ingress-role
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - pods
      - secrets
      - namespaces
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-$NS"
      - "nginx-configuration"
      - "tcp-services"
      - "udp-services"
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: nginx-ingress-role-nisa-binding
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-ingress-role
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-nisa-binding
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-ingress-controller-$NS
  namespace: ingress-nginx
  labels:
    app: nginx-ingress-controller-$NS
spec:
  #replicas: 1
  selector:
    matchLabels:
      app: nginx-ingress-controller-$NS
  template:
    metadata:
      labels:
        app: nginx-ingress-controller-$NS
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      # wait up to five minutes for the drain of connections
      terminationGracePeriodSeconds: 300
      serviceAccountName: nginx-ingress-serviceaccount
      nodeSelector:
        kubernetes.io/os: linux
      #hostNetwork: true
      initContainers:
        - name: setsysctl
          image: registry.cn-shanghai.aliyuncs.com/jacke/busybox:latest
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - sh
            - -c
            - |
              sysctl -w net.core.somaxconn=65535
              sysctl -w net.ipv4.ip_local_port_range="1024 65535"
              sysctl -w fs.file-max=1048576
        - name: chown-logdir
          image: registry.cn-shanghai.aliyuncs.com/jacke/busybox:latest
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
          command:
            - sh
            - -c 
            - chown -R 101:101 /var/log/nginx
          volumeMounts:
          - mountPath: /var/log/nginx
            name: log
      containers:
        - name: nginx-ingress-controller
          image: registry.cn-shanghai.aliyuncs.com/jacke/nginx-ingress-controller:0.28.0
          imagePullPolicy: IfNotPresent
          args:
            - /nginx-ingress-controller
            - --configmap=\$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=\$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=\$(POD_NAMESPACE)/udp-services
            - --publish-service=\$(POD_NAMESPACE)/nginx-ingress-controller-$NS
            - --annotations-prefix=nginx.ingress.kubernetes.io
            - --ingress-class=$NS
          securityContext:
            allowPrivilegeEscalation: true
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 101
            runAsUser: 101
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
            - name: https
              containerPort: 443
              protocol: TCP
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          lifecycle:
            preStop:
              exec:
                command:
                  - /wait-shutdown
          volumeMounts:
          - mountPath: /etc/localtime
            name: timezone
            readOnly: true
          - mountPath: /var/log/nginx
            name: log
      volumes:
      - hostPath:
          path: /etc/localtime
          type: ""
        name: timezone
      - hostPath:
          path: /var/log/nginx
          type: ""
        name: log
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-controller-$NS
  namespace: ingress-nginx
  labels:
    app: nginx-ingress-controller-$NS
spec:
  selector:
    app: nginx-ingress-controller-$NS
  ports:
  - protocol: TCP
    name: http
    port: 80 
    targetPort: 80
    nodePort: 20080
  - protocol: TCP
    name: https
    port: 443
    targetPort: 443
    nodePort: 20443
  type: NodePort

---

apiVersion: v1
kind: LimitRange
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  limits:
  - min:
      memory: 150Mi
      cpu: 200m
    type: Container

EOF
