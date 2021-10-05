---
title: "[Vagrant] 入门"
date: 2021-07-14T12:56:11+03:00
draft: false
layout: default
tags: ["vagrant", "tutorial"]
categories: ["vagrant"]
author: "Jiang WU"
comments: true
---
# 1.什么是vagrant
具体定义大家可以参见官方网站: https://www.vagrantup.com/.

那么大白话vagrant 到底是干嘛的, 它和docker有点像, 甚至部分操作用过docker 的人都会觉得似曾相识, 我们知道, docker 是来管理container的, 而vagrant是来管理虚拟机的, 比如你有个tomcat, 这个tomcat可以运行在docker容器上, 我们通过docker来管理这个容器, 而这个docker容器可以运行在VM上, 而vagrant可以是用来管理这个VM的, 当然, 这个只是一个宽泛的解释, 具体还是需要深入理解其本质.

# 2.如何工作
vagrant 通过不同的provider 来对虚拟机软件的API进行调用, 例如 virtualbox, 那么vagrant 通过virtualbox provider 来操作VM. 也就省去了我们手动创建的麻烦
![how_does_vagrant_works](https://res.cloudinary.com/djpkulbas/image/upload/v1626286970/vagrant/how_does_vagrant_works_ltsbdm.png)
<!--more-->
# 3. 安装

> 更多方式: https://www.vagrantup.com/downloads

- Linux/Ubuntu
```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vagrant
```
- Windows
这里注意，如果你使用virtualbox或者vmware,　并且运行你普通使用创建vm没问题，那么你只需要根据上面的链接安装vagrant, 如果你不要
  因为vagrant需要hyper-v, 所以你要打开自己的windows hyper-v, [传送门](https://docs.microsoft.com/en-us/locale/?target=https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v) 然后根据上面的下载地址，下载安装
  
- MacOS
```
brew tap hashicorp/tap
brew install vagrant
```

验证是否已经安装
```
$ vagrant --version
Vagrant 2.2.17
```

# 4. 下载基础镜像
这里我们以virtualbox 为例, 创建一个centos 7 的基础镜像，　那么我们需要现在vagrant上面下载: https://app.vagrantup.com/centos/boxes/7
![image](https://res.cloudinary.com/djpkulbas/image/upload/v1626285565/vagrant/download_base_image_sc6e8a.png)
   
点击这个镜像，可以看到我们的安装方式有vagrant file 和 new.　我们使用文件的方式, 本地新建一个文件夹用于vagrant, 然后创建这样一个文件，并执行安装.

```
//创建Vagrantfile
test@agv1vvp2:~/vagrant$ cat>Vagrantfile 
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
end
//安装
test@1vvp2:~/vagrant$ vagrant up --provider=virtualbox --color
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'centos/7' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'centos/7'
    default: URL: https://vagrantcloud.com/centos/7
==> default: Adding box 'centos/7' (v2004.01) for provider: virtualbox
    default: Downloading: https://vagrantcloud.com/centos/boxes/7/versions/2004.01/providers/virtualbox.box
Download redirected to host: cloud.centos.org
    default: Calculating and comparing box checksum...
==> default: Successfully added box 'centos/7' (v2004.01) for 'virtualbox'!
... ...

//查看Vagrant 是否在运行
test@agv1vvp2:~/vagrant$ vagrant status
Current machine states:

default                   running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`.
```

* 如果下载速度过慢，可以采用科学上网，或者添加新的镜像源, 源自己找就可以了，网上一堆:
```
$ vagrant box add centos7 <image link>
```

# 5. ssh到虚拟机
- 最快的方式
```
test@agv1vvp2:~/vagrant$ vagrant ssh
Last login: Wed Jul 14 13:02:41 2021 from 10.0.2.2
```

- 传统ssh 的方式

有时我们需要传统的方式来ssh，那么我们需要先查看ssh 配置
```
test@agv1vvp2:~/vagrant$ vagrant ssh-config
Host default
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/test/vagrant/.vagrant/machines/default/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```
然后ssh
```
ssh vagrant@127.0.0.1 -p 2222 -o LogLevel=FATAL -o Compression=yes -o DSAAuthentication=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/test/vagrant/.vagrant/machines/default/virtualbox/private_key
```
或者用配置文件的方式
```
test@agv1vvp2:~/vagrant$ vagrant ssh-config > vagrant-ssh
test@agv1vvp2:~/vagrant$ ssh -F vagrant-ssh default
Last login: Wed Jul 14 13:01:37 2021 from 10.0.2.2
```

# 6. 配置自己的虚拟机
实际上, 这个Vagrantfile 就是一个Ruby 脚本, 它本身会调用Vagrant的API, 首先观察这个文件
```
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
end
```
可以看到, config.vm.box 这一行代码, 显而易见,这里就是指定了我们镜像的类型, 那么假设我们需要搭建多个节点, 我们同样可以扩展这个文件
```
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  
  //配置第一台vm, hostname为 server1
  config.vm.define "node1" do |server1|
    server1.vm.hostname = "server1"
  end
  
  //配置第一台vm, hostname为 server2
  config.vm.define "node2" do |server2|
    server2.vm.hostname = "server2"
  end
  
  //配置第一台vm, hostname为 server3
  config.vm.define "node3" do |server3|
    server3.vm.hostname = "server3"
  end

end
```
重新创建
```
test@agv1vvp2:~/vagrant$ vagrant up
Bringing machine 'node1' up with 'virtualbox' provider...
Bringing machine 'node2' up with 'virtualbox' provider...
Bringing machine 'node3' up with 'virtualbox' provider...
... ...

//查看其中一台vm
test@agv1vvp2:~/vagrant$ vagrant ssh node1
[vagrant@server1 ~]$ exit
```
此时, 如果你打开你的virtualbox, 可以看到自己创建的三个文件

> 如果需要更多配置, 可以参考官方文档: https://www.vagrantup.com/docs/vagrantfile

# 7. 常用的命令

- 开机
```
vagrant up
```

- 关机
```
vagrant halt
```

- 关机并删除
```
vagrant destroy
```

- ssh连接到虚拟机
```
vagrant ssh <host_name>
```

- 重新加载Vagrantfile
```
vagrant reload
```


