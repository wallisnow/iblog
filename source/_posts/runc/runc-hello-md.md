---
title: runc 入门使用
date: 2022-05-09 16:15:42
tags: ["runc"]
categories: ["runc"]
---

## runc的个人理解
结合日常应用, 我个人的理解就是一个运行于docker和操作系统之间的中间件, 也就是说docker 通过调用runc, 达到对容器的操作, 也就是说docker的所有操作也可以通过直接操作runc完成:
docker ----> runc -----> os

## 测试环境

假设此时, 我们有一个容器
```bash
#解包一个本地容器内容
mkdir rootfs
sudo docker export $(sudo docker create busybox:1.34.1)|tar -C ./rootfs -xvf -
```
然后生成runc配置
```bash
runc spec 
```
<!--more-->
此时会生成一个config.json, 如下
```json
{
	"ociVersion": "1.0.2-dev",
	"process": {
		"terminal": true,
		"user": {
			"uid": 0,
			"gid": 0
		},
		"args": [
			"sh"
		],
		"env": [
			"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
			"TERM=xterm"
		],
		"cwd": "/",
		"capabilities": {
			"bounding": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"effective": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"inheritable": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"permitted": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			],
			"ambient": [
				"CAP_AUDIT_WRITE",
				"CAP_KILL",
				"CAP_NET_BIND_SERVICE"
			]
		},
		"rlimits": [
			{
				"type": "RLIMIT_NOFILE",
				"hard": 1024,
				"soft": 1024
			}
		],
		"noNewPrivileges": true
	},
	"root": {
		"path": "rootfs",
		"readonly": true
	},
	"hostname": "runc",
	"mounts": [
		{
			"destination": "/proc",
			"type": "proc",
			"source": "proc"
		},
		{
			"destination": "/dev",
			"type": "tmpfs",
			"source": "tmpfs",
			"options": [
				"nosuid",
				"strictatime",
				"mode=755",
				"size=65536k"
			]
		},
		{
			"destination": "/dev/pts",
			"type": "devpts",
			"source": "devpts",
			"options": [
				"nosuid",
				"noexec",
				"newinstance",
				"ptmxmode=0666",
				"mode=0620",
				"gid=5"
			]
		},
		{
			"destination": "/dev/shm",
			"type": "tmpfs",
			"source": "shm",
			"options": [
				"nosuid",
				"noexec",
				"nodev",
				"mode=1777",
				"size=65536k"
			]
		},
		{
			"destination": "/dev/mqueue",
			"type": "mqueue",
			"source": "mqueue",
			"options": [
				"nosuid",
				"noexec",
				"nodev"
			]
		},
		{
			"destination": "/sys",
			"type": "sysfs",
			"source": "sysfs",
			"options": [
				"nosuid",
				"noexec",
				"nodev",
				"ro"
			]
		},
		{
			"destination": "/sys/fs/cgroup",
			"type": "cgroup",
			"source": "cgroup",
			"options": [
				"nosuid",
				"noexec",
				"nodev",
				"relatime",
				"ro"
			]
		}
	],
	"linux": {
		"resources": {
			"devices": [
				{
					"allow": false,
					"access": "rwm"
				}
			]
		},
		"namespaces": [
			{
				"type": "pid"
			},
			{
				"type": "network"
			},
			{
				"type": "ipc"
			},
			{
				"type": "uts"
			},
			{
				"type": "mount"
			}
		],
		"maskedPaths": [
			"/proc/acpi",
			"/proc/asound",
			"/proc/kcore",
			"/proc/keys",
			"/proc/latency_stats",
			"/proc/timer_list",
			"/proc/timer_stats",
			"/proc/sched_debug",
			"/sys/firmware",
			"/proc/scsi"
		],
		"readonlyPaths": [
			"/proc/bus",
			"/proc/fs",
			"/proc/irq",
			"/proc/sys",
			"/proc/sysrq-trigger"
		]
	}
}
```
启动容器并进入容器
```bash
~/busybox> sudo runc run test
/ # 
/ # 
/ # ls
bin   dev   etc   home  proc  root  sys   tmp   usr   var
/ # env
SHLVL=1
HOME=/root
TERM=xterm
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PWD=/
/ # 
```
这里面的env显示, 实际我们可以通过confg.json中的env来进行更改, 比如我们加一个ABC=EFG, 那么生成的新的容器就会读取此环境变量


再切换终端, 看看运行时容器
```bash
~> sudo runc list
ID          PID         STATUS      BUNDLE               CREATED                        OWNER
test        35850       running     /home/bx/busybox   2022-05-09T13:36:30.6041705Z   root
```

## 配置文件的使用
runc 在生成这个配置文件config.json后, 便会以这个文件为基准来创建容器, 这里也有很多常见的docker配置, 比如, env, mount等, 这里以mount为例, 我们在上面的配置中添加一个挂载点
```json
{
  "mounts": [
            ...
                {
                        "destination": "/app",
                        "type": "bind",
                        "source": "/home/test/runc/app",
                        "options": [
                                "rbind","rw"
                        ]
                },
            ...
  ]
}
```
再次启动容器
```bash
~> sudo runc run mytest
~> sudo runc list
ID          PID         STATUS      BUNDLE                   CREATED                          OWNER
mytest      107520      running     /home/test/runc/alpine   2022-05-09T18:46:37.156872532Z   root
```
进入容器查看挂载的文件
```bash
~> sudo runc exec -t mytest sh
/ # ls
app    bin    dev    etc    home   lib    media  mnt    opt    proc   root   run    sbin   srv    sys    tmp    usr    var
/ # cd app/
/app # ls
test.sh
/app # 
```
这个挂载点就对应了我们本地挂载的文件夹, 里面有个我们创建的test.sh
```bash
~/runc/app> ls
test.sh
~runc/app> pwd
/home/test/runc/app
```

## 删除容器

- 关闭容器进程
```bash
runc kill <pid>
```

- 删除容器
```bash
runc delete <pid>
```