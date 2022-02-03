---
title: lsof的权限问题
date: 2022-02-03 10:34:51
tags: ["linux"]
---

## lsof 了解

linux 一切皆文件, lsof -- lists open files, 所以, 这个命令理论上, 你可以看到所有打开的文件, 也就是所有打开的东西, 比如, 文本, 网络链接, 进程, 等

## 常见用法
不是本文讨论重点, 可以自行谷歌
[常见用法](https://www.cnblogs.com/sparkdev/p/10271351.html)

## 实验
一般教程往往给定了root权限, 所以当使用lsof时, 可以看到所有文件信息, 但是生产环境不一定, 这里我们做一个实验, 创建一个普通用户, 对比另一个用户执行lsof

- 创建一个用户

```bash
sudo useradd tester
sudo passwd tester
```

- 模拟一个进程来占用文件

```bash
touch test.txt
tail -f test.txt

#为了方便观察, 先删了这个文件, 注意, 此时tail 还在访问这个文件
rm test.txt
```
<!--more-->
- 然后lsof 查看
```bash
dev@vm:~> sudo lsof -l|grep deleted
... ...
tail      20598                     1001    3r      REG              253,3         0    1663794 /home/dev/test.txt (deleted)
```

- 转换成刚刚创建的用户再次查看
```bash
eccd@worker-pool1-al0h1t9p-efggjjp-ibd-test:~> su - tester
Password: 

tester@vm> lsof -l|grep deleted
#没有同样的输出
```

## 结论
lsof 实际是和权限有关的, 这个其实也是很显而易见的, 往往有时忽略权限问题, 导致结果就是排查问题会忘记权限影响的输出结果