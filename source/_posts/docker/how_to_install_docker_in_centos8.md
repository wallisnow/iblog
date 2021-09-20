---
title: "[docker] centos8 安装docker"
date: 2021-07-19T11:16:26+03:00
draft: false
tags: ["docker", "centos8"]
categories: ["docker"]
comments: true
---

# 1. 前置条件
准备一台centos 8 的机器, 我这里用的是vagrant安装的centos8镜像

# 2. 安装过程

# 2.1 测试是否链接外网
```
$ ping google.com
PING google.com (216.58.211.14) 56(84) bytes of data.
64 bytes from muc03s13-in-f14.1e100.net (216.58.211.14): icmp_seq=1 ttl=63 time=11.5 ms
64 bytes from muc03s13-in-f14.1e100.net (216.58.211.14): icmp_seq=2 ttl=63 time=12.1 ms
^C
--- google.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 11.476/11.781/12.086/0.305 ms

```

# 2.2 删除旧的docker
```
$ sudo yum remove docker \
                   docker-client \
                   docker-client-latest \
                   docker-common \
                   docker-latest \
                   docker-latest-logrotate \
                   docker-logrotate \
                   docker-engine
```

# 2.3 安装需要的依赖包
```
$ sudo yum install -y yum-utils
```
```
//OUTPUT
CentOS Linux 8 - AppStream                                                                                                                               7.4 MB/s | 8.1 MB     00:01    
CentOS Linux 8 - BaseOS                                                                                                                                  4.7 MB/s | 3.6 MB     00:00    
CentOS Linux 8 - Extras                                                                                                                                   38 kB/s | 9.8 kB     00:00    
Package yum-utils-4.0.17-5.el8.noarch is already installed.
Dependencies resolved.
=========================================================================================================================================================================================
 Package                                                 Architecture                          Version                                       Repository                             Size
=========================================================================================================================================================================================
Upgrading:
 dnf-plugins-core                                        noarch                                4.0.18-4.el8                                  baseos                                 69 k
 python3-dnf-plugins-core                                noarch                                4.0.18-4.el8                                  baseos                                234 k
 yum-utils                                               noarch                                4.0.18-4.el8                                  baseos                                 71 k

Transaction Summary
=========================================================================================================================================================================================
Upgrade  3 Packages

Total download size: 375 k
Downloading Packages:
(1/3): yum-utils-4.0.18-4.el8.noarch.rpm                                                                                                                 1.3 MB/s |  71 kB     00:00    
(2/3): dnf-plugins-core-4.0.18-4.el8.noarch.rpm                                                                                                          1.2 MB/s |  69 kB     00:00    
(3/3): python3-dnf-plugins-core-4.0.18-4.el8.noarch.rpm                                                                                                  3.5 MB/s | 234 kB     00:00    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                    858 kB/s | 375 kB     00:00     
warning: /var/cache/dnf/baseos-31c79d9833c65cf7/packages/dnf-plugins-core-4.0.18-4.el8.noarch.rpm: Header V3 RSA/SHA256 Signature, key ID 8483c65d: NOKEY
CentOS Linux 8 - BaseOS                                                                                                                                  1.6 MB/s | 1.6 kB     00:00    
Importing GPG key 0x8483C65D:
 Userid     : "CentOS (CentOS Official Signing Key) <security@centos.org>"
 Fingerprint: 99DB 70FA E1D7 CE22 7FB6 4882 05B5 55B3 8483 C65D
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
Key imported successfully
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                 1/1 
  Upgrading        : python3-dnf-plugins-core-4.0.18-4.el8.noarch                                                                                                                    1/6 
  Upgrading        : dnf-plugins-core-4.0.18-4.el8.noarch                                                                                                                            2/6 
  Upgrading        : yum-utils-4.0.18-4.el8.noarch                                                                                                                                   3/6 
  Cleanup          : yum-utils-4.0.17-5.el8.noarch                                                                                                                                   4/6 
  Cleanup          : dnf-plugins-core-4.0.17-5.el8.noarch                                                                                                                            5/6 
  Cleanup          : python3-dnf-plugins-core-4.0.17-5.el8.noarch                                                                                                                    6/6 
  Running scriptlet: python3-dnf-plugins-core-4.0.17-5.el8.noarch                                                                                                                    6/6 
  Verifying        : dnf-plugins-core-4.0.18-4.el8.noarch                                                                                                                            1/6 
  Verifying        : dnf-plugins-core-4.0.17-5.el8.noarch                                                                                                                            2/6 
  Verifying        : python3-dnf-plugins-core-4.0.18-4.el8.noarch                                                                                                                    3/6 
  Verifying        : python3-dnf-plugins-core-4.0.17-5.el8.noarch                                                                                                                    4/6 
  Verifying        : yum-utils-4.0.18-4.el8.noarch                                                                                                                                   5/6 
  Verifying        : yum-utils-4.0.17-5.el8.noarch                                                                                                                                   6/6 

Upgraded:
  dnf-plugins-core-4.0.18-4.el8.noarch                         python3-dnf-plugins-core-4.0.18-4.el8.noarch                         yum-utils-4.0.18-4.el8.noarch                        

Complete!
```
# 2.4 添加docker repo
```
$ sudo yum-config-manager \
     --add-repo \
     https://download.docker.com/linux/centos/docker-ce.repo
```
# 2.5 安装docker
```
$ sudo yum install docker-ce docker-ce-cli containerd.io
```

# 3. 验证

重启docker
```
$ sudo systemctl start docker
```

验证
```
[vagrant@localhost ~]$ sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
b8dfde127a29: Pull complete 
Digest: sha256:df5f5184104426b65967e016ff2ac0bfcd44ad7899ca3bbcf8e44e4461491a9e
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

# 4. Ref:
https://docs.docker.com/engine/install/centos/
