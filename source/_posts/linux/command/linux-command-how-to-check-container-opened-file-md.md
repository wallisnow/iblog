---
title: 如何查看容器对应的宿主上打开的文件
date: 2022-02-03 10:15:30
tags: ["linux", "docker"]
categories: ["linux"]
---

## 查看容器对应的pid

### 查看容器id
```bash
$ docker ps 

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES 
b71e02952ed1        postgres:13         "docker-entrypoint.s…"   2 weeks ago         Up 2 weeks          0.0.0.0:5432->5432/tcp   docker_db_1 
```

### 查看容器对应的宿主pid

- 通过 docker container top
```bash
$ docker container top b71e02952ed1 

UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD 
999                 20969               20950               0                   tammi19             ?                   00:00:28            postgres 
999                 21228               20969               0                   tammi19             ?                   00:00:00            postgres: checkpointer 
999                 21229               20969               0                   tammi19             ?                   00:00:16            postgres: background writer 
999                 21230               20969               0                   tammi19             ?                   00:00:16            postgres: walwriter 
999                 21231               20969               0                   tammi19             ?                   00:00:23            postgres: autovacuum launcher 
999                 21233               20969               0                   tammi19             ?                   00:00:47            postgres: stats collector 
999                 21234               20969               0                   tammi19             ?                   00:00:00            postgres: logical replication launcher 
```
<!--more-->
- 使用直接访问容器对应的cgroup 文件夹 /sys/fs/cgroup/memory/docker/ 的方式查看

```bash
#看到b71e02952ed1 这个容器文件夹
$ls /sys/fs/cgroup/memory/docker/ 
b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623  memory.kmem.limit_in_bytes          memory.kmem.usage_in_bytes  

#同样可以看到其对应的pid
$cat /sys/fs/cgroup/memory/docker/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/cgroup.procs  
20969 
21228 
21229 
21230 
21231 
21233 
21234 
```

### 查看pid 对应的打开文件

- 使用 lsof -p <pid>

```bash
$ sudo lsof -p 20950 
... ...
COMMAND     PID USER   FD      TYPE             DEVICE SIZE/OFF       NODE NAME 
container 20950 root  cwd       DIR               0,25      120       1356 /run/containerd/io.containerd.runtime.v1.linux/moby/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623 
container 20950 root  rtd       DIR              253,1     4096          2 / 
container 20950 root  txt       REG              253,1  6117096   27010813 /usr/bin/containerd-shim 
container 20950 root    0r      CHR                1,3      0t0          6 /dev/null 
container 20950 root    1w      CHR                1,3      0t0          6 /dev/null 
container 20950 root    2w      CHR                1,3      0t0          6 /dev/null 
... ...
```

- 通过查看程文件夹 /proc/<pid>/fd

```bash
$sudo ls -l /proc/20950/fd 
total 0 
lr-x------ 1 root root 64 Feb  3 09:47 0 -> /dev/null 
l-wx------ 1 root root 64 Feb  3 09:47 1 -> /dev/null 
lrwx------ 1 root root 64 Feb  3 09:47 10 -> 'socket:[4029583985]' 
lr-x------ 1 root root 64 Feb  3 09:47 11 -> 'pipe:[4029582852]' 
l-wx------ 1 root root 64 Feb  3 09:47 12 -> /run/docker/containerd/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/init-stdout 
lr-x------ 1 root root 64 Feb  3 09:47 13 -> 'pipe:[4029582853]' 
l--------- 1 root root 64 Feb  3 09:47 14 -> /run/docker/containerd/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/init-stdout 
l--------- 1 root root 64 Feb  3 09:47 15 -> /run/docker/containerd/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/init-stdout 
lr-x------ 1 root root 64 Feb  3 09:47 16 -> /run/docker/containerd/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/init-stdout 
l--------- 1 root root 64 Feb  3 09:47 17 -> /run/docker/containerd/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/init-stderr 
l-wx------ 1 root root 64 Feb  3 09:47 18 -> /run/docker/containerd/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/init-stderr 
l--------- 1 root root 64 Feb  3 09:47 19 -> /run/docker/containerd/b71e02952ed16769ffdfbf67dfbec8ed622bdc934524a6547f4197b9657ca623/init-stderr 
l-wx------ 1 root root 64 Feb  3 09:47 2 -> /dev/null 
```


