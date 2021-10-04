---
title: 链接pod时 出现Error from server error dialing backend remote error - tls - internal error
date: 2021-10-04 16:32:15
tags: ["kubernetes"]
categories: ["kubernetes"]
---

# 问题出现
发现这个问题是因为我需要查看部分CrashLoopBackOff 的pod日志, 当执行 

```
$ kubectl -n kube-system exec -it openstack-cloud-controller-manager-vrdld -- /bin/bash
```

时报错, 错误如下:
```
Error from server: error dialing backend: remote error: tls: internal error
```
<!--more-->
# 问题分析
看到tls, 很明显就是来自证书问题, 猜测是证书制作有问题, 那么kubernetes中的证书是由kubernetes的CA签发, 这时可以通过curl 来猜测一下:
```
$ curl -v https://[fd00:1111:94:1111::12]:10250/containerLogs/kube-system/openstack-cloud-controller-manager-xqqm5/openstack-cloud-controller-manager
*   Trying fd00:1111:94:1111::12:10250...
* TCP_NODELAY set
* Connected to fd00:eccd:94:1111::12 (fd00:1111:94:1111::12) port 10250 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS alert, internal error (592):
* error:14094438:SSL routines:ssl3_read_bytes:tlsv1 alert internal error
* Closing connection 0
curl: (35) error:14094438:SSL routines:ssl3_read_bytes:tlsv1 alert internal error
```
可以看到这里错误
> error:14094438:SSL routines:ssl3_read_bytes:tlsv1 alert internal error

此时查询所有证书
```
$ kubectl get csr
NAME        AGE     SIGNERNAME                      REQUESTOR                                CONDITION
csr-27xqp   55m     kubernetes.io/kubelet-serving   system:node:master-2-efggjjp-ansibd-01   Pending
csr-28w9n   19h     kubernetes.io/kubelet-serving   system:node:master-2-efggjjp-ansibd-01   Pending
csr-2gdwc   20h     kubernetes.io/kubelet-serving   system:node:master-2-efggjjp-ansibd-01   Pending
csr-2hq2x   6h5m    kubernetes.io/kubelet-serving   system:node:master-0-efggjjp-ansibd-01   Pending
... ...
```
发现所有证书都在pending, 此时我们需要批准证书

# 解决问题

kubernetes 提供给管理员直接approve 的api: 
```bash
$ kubectl certificate approve <certificat name>
```
写个脚本批准所有
```bash
#!/bin/bash

for i in $(kubectl get csr |grep Pending| awk '{print $1}'); do
    kubectl certificate approve $i
done
```

再次通过 kubectl logs 或者 kubectl exec 尝试接入pod
```bash
$ kubectl -n kube-system logs openstack-cloud-controller-manager-xqqm5
I1004 10:27:34.324881       1 flags.go:59] FLAG: --add-dir-header="false"
I1004 10:27:34.324929       1 flags.go:59] FLAG: --add_dir_header="false"
... ...
```