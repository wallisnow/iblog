---
title: "[centos8] 使用DNF安装git"
date: 2021-08-02T11:11:47+03:00
tags: ["centos8", "git"]
categories: ["git"]
comments: true
---

# 前言
这里使用dnf, dnf是下一代的包管理工具

# 安装git
安装dnf
```
$ sudo dnf update -y
```
安装git
```
$ sudo dnf install git -y
```
验证
```
$ git --version
git version 2.27.0
```

# 简单配置git

```
$ vim ~/.gitconfig
```

配置用户信息
```
[user]
  name = developer
  email = developer@domain.com
```

验证
```
$ git config --list

user.name=developer
user.email=developer@domain.com
```