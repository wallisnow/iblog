---
title: 记一次kubelet假死的问题排查
date: 2022-09-28 13:36:05
tags: ["kubernetes", "linux"]
categories: ["kubernetes"]
---

## 发现问题
今天在升级kubernetes集群时，被升级节点突然开始变得异常缓慢，ssh需要很久很久, 但是却可以ping的通. 有问题如下:

- 节点缓慢
- 可以ping ssh很慢
- 健康节点上 kubectl describe node, 可以看到 
```bash
Conditions:
  Type                 Status    LastHeartbeatTime                 LastTransitionTime                Reason              Message
  ----                 ------    -----------------                 ------------------                ------              -------
  NetworkUnavailable   False     Wed, 28 Sep 2022 07:08:34 +0000   Wed, 28 Sep 2022 07:08:34 +0000   CalicoIsUp          Calico is running on this node
  MemoryPressure       Unknown   Wed, 28 Sep 2022 07:46:33 +0000   Wed, 28 Sep 2022 07:47:36 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  DiskPressure         Unknown   Wed, 28 Sep 2022 07:46:33 +0000   Wed, 28 Sep 2022 07:47:36 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  PIDPressure          Unknown   Wed, 28 Sep 2022 07:46:33 +0000   Wed, 28 Sep 2022 07:47:36 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
  Ready                Unknown   Wed, 28 Sep 2022 07:46:33 +0000   Wed, 28 Sep 2022 07:47:36 +0000   NodeStatusUnknown   Kubelet stopped posting node status.
Addresses:
```

## 排查问题

1. ssh 到问题节点, 拿到shell并root

在describe node 时， 看到kubelet有问题， 那么先查看kubelet

* 首先查看kubelet 状态
```bash
journalctl -u kubelet|less

or

root@node-15-cp-gswpw:~> systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/local/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
     Active: active (running) since Wed 2022-09-28 06:39:55 UTC; 1h 14min ago
       Docs: http://kubernetes.io/docs/
   Main PID: 8440 (kubelet)
      Tasks: 27
     CGroup: /system.slice/kubelet.service
             └─8440 /usr/local/bin/kubelet --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf --read-only-port=0 --config=/var/lib/kubelet/config.yaml -->

Sep 28 07:54:18 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:18.267169    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:20 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:20.268365    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:22 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:22.268410    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:24 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:24.266872    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:26 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:26.268006    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:28 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:28.269099    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:30 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:30.266409    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:32 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:32.268111    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:34 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:34.266758    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181c>
Sep 28 07:54:36 node-15-cp-gswpw.novalocal kubelet[8440]: E0928 07:54:36.272904    8440 kubelet_volumes.go:245] "There were many similar errors. Turn up verbosity to see them." err="orphaned pod \"7181
```
看到kubelet 实际是启动的，但是有报错

* 查看api server

```bash
crictl ps -a
```

看到 api server 是退出的状态, 在查看它的日志

```bash
crictl log 87d3992f84f74
```

看到许多的链接异常, 并看到etcd异常, 此时基本断定，etcd通讯异常和我们ssh应该是一个问题，也就是说不是kubernetes 的问题了

2. 排查系统层面的问题

* 查看进程

top 后， 看到 kswapd0 占用高cpu, 简单说， 就是系统现在没内存了， 要异步回收资源, 看到这里就已经有点问题的苗头了.
而且 load average 值过高(实际要观察其1-15分钟的变化)， 现在很多进程需要处理.
<!--more-->
```bash
top

top - 08:20:09 up  1:43,  1 user,  load average: 176.16, 177.88, 186.03
Tasks: 373 total,  53 running, 316 sleeping,   0 stopped,   4 zombie
%Cpu(s):  0.2 us, 99.8 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.1 si,  0.0 st
MiB Mem : 3921.832 total,   86.609 free, 3869.438 used,  210.109 buff/cache
MiB Swap:    0.000 total,    0.000 free,    0.000 used.   52.395 avail Mem 

   PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND                                                                                                                                  
   108 root      20   0       0      0      0 R 69.09 0.000  38:38.54 kswapd0                                                                                                                                  
  8690 root      15  -5 1801280 828812      0 S 35.76 20.64  28:20.95 kube-apiserver                                                                                                                           
  5561 root      20   0  819188  19556      0 S 22.12 0.487  11:00.48 kube-controller                                                                                                                          
116886 292100    20   0 4240176 280800      0 S 17.27 6.992   3:00.43 java                                                                                                                                     
  5579 root      20   0  752904  26280      0 R 16.97 0.654   9:51.93 kube-scheduler                                                                                                                           
116503 211908    20   0 4232144 280032      0 S 16.06 6.973   3:04.31 java                                                                                                                                     
  7799 root      15  -5  9.892g 128688      0 R 15.45 3.204  13:20.12 etcd                                                                                                                                     
100063 root      20   0  751580  20368      0 R 14.85 0.507   3:54.08 coredns                                                                                                                                  
115499 root      20   0 1454732  88380    440 S 14.24 2.201   2:50.97 vmagent                                                                                                                                  
 69120 root      20   0 2042904  21748      0 S 9.697 0.542  13:06.08 calico-node                                                                                                                              
 69121 root      20   0 1894928  15780      0 S 9.394 0.393   3:28.76 calico-node                                                                                                                              
102022 root      20   0 1798948 227396      0 S 9.091 5.662   2:53.44 vmstorage                                                                                                                                
 35393 root      20   0  728996  20380      0 R 8.485 0.507   4:40.08 registry                                                                                                                                 
101284 288256    20   0 1260044  12480      0 R 8.182 0.311   1:54.41 controller                                                                                                                               
  8440 root      20   0 2817068  98476      0 S 7.879 2.452  10:45.11 kubelet                                                                                                                                  
119482 root      20   0   12292   1108    900 R 7.576 0.028   0:00.49 sh                                                                                                                                       
117868 root      20   0  118232   7604   6472 R 7.273 0.189   1:08.98 systemd-journal                                                                                                                          
 69118 root      20   0 1452024  12740      0 R 6.667 0.317   1:33.67 calico-node                                                                                                                              
 26767 root      20   0  965176 294476  30348 R 6.364 7.333   5:27.58 falco                                                                                                                                    
113762 root      20   0 1164648  13464      0 S 6.364 0.335   1:29.39 vmselect                                                                                                                                 
115675 128052    20   0 1334232  10372      0 R 6.364 0.258   1:36.60 app                                                                                                                                      
 10800 root      20   0  712264   8672      0 S 6.061 0.216   1:02.54 xx-local-execu                                                                                                                          
114380 root      20   0 1231764  67000      0 S 5.758 1.668   1:19.32 vminsert                                                                                                                                 
119450 root      20   0  724712    528      0 R 5.455 0.013   0:01.48 crictl                                                                                                                                   
119456 root      20   0   45896   2956   1892 R 5.455 0.074   0:00.77 top
```

* 查看内核日志

为了确定这一点， 来查看内核日志.

需要注意的是， 内核日志有可能刷新太快， 你grep 时不一定有输出， 要持续观察
```bash
-bash-4.4# grep -i "Out Of Memory" /var/log/messages
2022-09-28T08:24:19.537448+00:00 node-15-cp-gswpw kernel: [ 6472.442368] Out of memory: Killed process 101788 (python3) total-vm:487148kB, anon-rss:54264kB, file-rss:0kB, shmem-rss:0kB
2022-09-28T08:27:28.284397+00:00 node-15-cp-gswpw kernel: [ 6661.390988] Out of memory: Killed process 113716 (python3) total-vm:297436kB, anon-rss:49260kB, file-rss:0kB, shmem-rss:0kB
```

看到上面的信息， 我们也就看到了问题, 就是 OOM

* 查看僵尸进程

hmmm... 这么多 (Z)Zombie 状态的进程，很多都是和网络有关,这就是什么所有链接的怪怪的

```bash
-bash-4.4# ps aux|grep Z
USER        PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root     101788  0.2  0.0      0     0 ?        Zs   07:50   0:06 [python3] <defunct>
root     113716  0.2  0.0      0     0 ?        Zs   07:55   0:05 [python3] <defunct>
root     115424  0.2  0.0      0     0 ?        Zsl  07:55   0:05 [python3] <defunct>
128052   117448  0.0  0.0      0     0 ?        Z    07:55   0:00 [curl] <defunct>
root     118982  0.0  0.0      0     0 ?        Z    08:17   0:00 [ip6tables] <defunct>
root     118994  0.0  0.0      0     0 ?        Z    08:17   0:00 [iptables] <defunct>
128052   119206  0.4  0.0      0     0 ?        Z    08:18   0:03 [curl] <defunct>
root     119324  1.7  0.0      0     0 ?        Zs   08:18   0:12 [calico-node] <defunct>
root     119460  0.2  0.0      0     0 ?        Z    08:19   0:01 [iptables] <defunct>
root     119736 16.4  0.0  10248  1512 pts/1    S+   08:30   0:00 grep Z
```

* 查看当前系统的内存

只有3个G， free 是0. (注意free 是0 不能断定系统没内存了, 详情 ref： https://www.linuxatemyram.com/)

```bash
-bash-4.4# free -g
              total        used        free      shared  buff/cache   available
Mem:              3           3           0           0           0           0
Swap:             0           0           0
```

* 多一嘴

OOM Killer 会在系统内存相当吃紧时被调用， 此时， 很多进程就会被杀死， 那么整个系统就并不可靠了， 因为你不知道谁被杀了

## 解决问题

加内存， 或者将一些应用的内存调小

