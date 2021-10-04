---
title: "[kubernetes]如何查看node的kubelet配置"
date: 2021-07-26T11:06:28+03:00
draft: false
tags: ["kubernetes"]
categories: ["kubernetes"]
author: "Jiang WU"
comments: true
---

# 0. 前言
有时因为一些原因, 我们需要修改kubelet 的配置, 新版本的kubernetes就是修改 config.yml, 那么这里有一个问题, 你怎么知道你的kubelet 已经生效了?

# 1. 先说结论
查询方法为先开启kube proxy然后使用 kubernetes 提供的查询接口
```
api/vi/nodes/<node_name>/proxy/cofigz
```
<!--more-->
# 2. 举个栗子

例如我们有这样一个集群:
```
test@node-01:~> kubectl get nodes -o wide
NAME                                   STATUS   ROLES                  AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                              KERNEL-VERSION         CONTAINER-RUNTIME
master-0-01             Ready    control-plane,master   16h   v1.21.1   10.0.10.9     <none>        SUSE Linux Enterprise Server 15 SP2   5.3.18-24.67-default   containerd://1.4.4
master-1-01             Ready    control-plane,master   16h   v1.21.1   10.0.10.10    <none>        SUSE Linux Enterprise Server 15 SP2   5.3.18-24.67-default   containerd://1.4.4
master-2-01             Ready    control-plane,master   16h   v1.21.1   10.0.10.24    <none>        SUSE Linux Enterprise Server 15 SP2   5.3.18-24.67-default   containerd://1.4.4
poolalpha-worker-0-01   Ready    worker                 15h   v1.21.1   10.0.10.4     <none>        SUSE Linux Enterprise Server 15 SP2   5.3.18-24.67-default   containerd://1.4.4
poolalpha-worker-1-01   Ready    worker                 15h   v1.21.1   10.0.10.13    <none>        SUSE Linux Enterprise Server 15 SP2   5.3.18-24.67-default   containerd://1.4.4
```

# 2.1 修改kubelet配置
接下来, 我们希望修改poolalpha-worker-0-01 的kubelet某个参数, 那么我们先登录这个节点, 然后查看当前节点使用的config.yml
```
test@poolalpha-worker-0-01:~> systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/usr/local/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-07-26 15:44:19 UTC; 15h ago
     Docs: http://kubernetes.io/docs/
  Process: 8868 ExecStopPost=/bin/umount --verbose /opt/cni (code=exited, status=0/SUCCESS)
  Process: 8874 ExecStartPre=/bin/mount --verbose --bind /usr/local/lib/cni /opt/cni (code=exited, status=0/SUCCESS)
  Process: 8869 ExecStartPre=/bin/mkdir --verbose --parents /opt/cni (code=exited, status=0/SUCCESS)
 Main PID: 8878 (kubelet)
    Tasks: 16
   CGroup: /system.slice/kubelet.service
           └─8878 /usr/local/bin/kubelet 
           ##### 这里可以看到kubelet使用的参数文件
           --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --config=/var/lib/kubelet/config.yaml --network-plugin=cn>
```

我们观察到, 此时这个节点使用的配置文件为 **--config=/var/lib/kubelet/config.yaml**, 打开看一下
```
test@poolalpha-worker-0-01:~> cat /var/lib/kubelet/config.yaml 
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 169.254.20.10
clusterDomain: cluster.local
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
featureGates:
  AllAlpha: false
  BoundServiceAccountTokenVolume: false
  EphemeralContainers: true
  RemoveSelfLink: false
  RotateKubeletServerCertificate: true
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
kubeletCgroups: /system.slice/kubelet.service
logging: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
rotateCertificates: true
runtimeRequestTimeout: 0s

shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s

staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
```
此时, 我们修改优雅关机的相关参数,比如:
```
shutdownGracePeriod: 30s 
shutdownGracePeriodCriticalPods: 10s 
```
在此节点上重启kubelet
```
sudo systemctl daemon-reload 
sudo systemctl stop kubelet
sudo systemctl start kubelet
```
此时我们修改就完成了

# 2.1 查看新配置是否生效
登录到一个有kubenetes 集群访问权限的节点, 比如一个master节点, 然后开启kube proxy
```
test@master-0-01:~> kubectl proxy --api-prefix=/ &
[1] 6171
```
使用查询接口来查看
```
test@director-0-01:~> curl http://127.0.0.1:8001/api/v1/nodes/poolalpha-worker-0-01/proxy/configz|jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2520    0  2520    0     0   7522      0 --:--:-- --:--:-- --:--:--  7522
{
  "kubeletconfig": {
    "enableServer": true,
    "staticPodPath": "/etc/kubernetes/manifests",
    "syncFrequency": "1m0s",
    "fileCheckFrequency": "20s",
    "httpCheckFrequency": "20s",
    "address": "0.0.0.0",
    "port": 10250,
    "tlsCertFile": "/var/lib/kubelet/pki/kubelet.crt",
    "tlsPrivateKeyFile": "/var/lib/kubelet/pki/kubelet.key",
    "rotateCertificates": true,
    "authentication": {
      "x509": {
        "clientCAFile": "/etc/kubernetes/pki/ca.crt"
      },
      "webhook": {
        "enabled": true,
        "cacheTTL": "2m0s"
      },
      "anonymous": {
        "enabled": false
      }
    },
    "authorization": {
      "mode": "Webhook",
      "webhook": {
        "cacheAuthorizedTTL": "5m0s",
        "cacheUnauthorizedTTL": "30s"
      }
    },
    "registryPullQPS": 5,
    "registryBurst": 10,
    "eventRecordQPS": 5,
    "eventBurst": 10,
    "enableDebuggingHandlers": true,
    "healthzPort": 10248,
    "healthzBindAddress": "127.0.0.1",
    "oomScoreAdj": -999,
    "clusterDomain": "cluster.local",
    "clusterDNS": [
      "169.254.20.10"
    ],
    "streamingConnectionIdleTimeout": "4h0m0s",
    "nodeStatusUpdateFrequency": "10s",
    "nodeStatusReportFrequency": "5m0s",
    "nodeLeaseDurationSeconds": 40,
    "imageMinimumGCAge": "2m0s",
    "imageGCHighThresholdPercent": 85,
    "imageGCLowThresholdPercent": 80,
    "volumeStatsAggPeriod": "1m0s",
    "kubeletCgroups": "/system.slice/kubelet.service",
    "cgroupsPerQOS": true,
    "cgroupDriver": "systemd",
    "cpuManagerPolicy": "none",
    "cpuManagerReconcilePeriod": "10s",
    "memoryManagerPolicy": "None",
    "topologyManagerPolicy": "none",
    "topologyManagerScope": "container",
    "runtimeRequestTimeout": "15m0s",
    "hairpinMode": "promiscuous-bridge",
    "maxPods": 110,
    "podPidsLimit": -1,
    "resolvConf": "/etc/resolv.conf",
    "cpuCFSQuota": true,
    "cpuCFSQuotaPeriod": "100ms",
    "nodeStatusMaxImages": 50,
    "maxOpenFiles": 1000000,
    "contentType": "application/vnd.kubernetes.protobuf",
    "kubeAPIQPS": 5,
    "kubeAPIBurst": 10,
    "serializeImagePulls": true,
    "evictionHard": {
      "imagefs.available": "15%",
      "memory.available": "100Mi",
      "nodefs.available": "10%",
      "nodefs.inodesFree": "5%"
    },
    "evictionPressureTransitionPeriod": "5m0s",
    "enableControllerAttachDetach": true,
    "makeIPTablesUtilChains": true,
    "iptablesMasqueradeBit": 14,
    "iptablesDropBit": 15,
    "featureGates": {
      "AllAlpha": false,
      "BoundServiceAccountTokenVolume": false,
      "EphemeralContainers": true,
      "RemoveSelfLink": false,
      "RotateKubeletServerCertificate": true
    },
    "failSwapOn": true,
    "containerLogMaxSize": "10Mi",
    "containerLogMaxFiles": 5,
    "configMapAndSecretChangeDetectionStrategy": "Watch",
    "enforceNodeAllocatable": [
      "pods"
    ],
    "volumePluginDir": "/usr/libexec/kubernetes/kubelet-plugins/volume/exec/",
    "logging": {
      "format": "text"
    },
    "enableSystemLogHandler": true,
    ################看这里####################
    "shutdownGracePeriod": "30s",
    "shutdownGracePeriodCriticalPods": "10s",
    ########################################
    "enableProfilingHandler": true,
    "enableDebugFlagsHandler": true
  }
}
```

这里使用jq 使得生成的json更加可读

# 3. 结语
上面修改kubelet参数只是一个例子, 修改的方法很多, 但查看其实际配置建议还是采用此接口
