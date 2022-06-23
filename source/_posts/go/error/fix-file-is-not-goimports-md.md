---
title: Golang 解决错误 File is not goimports -ed (goimports)
date: 2022-05-06 15:14:48
tags: ["golang", "error"]
categories: ["golang"]
---

## 问题

当我们引入```golangci-lint```, 然后检查代码格式, 检查时会产生如下问题
```go
File is not `goimports`-ed (goimports)
```
这个是因为我们的代码中部分 import 格式并不符合linting 的规范
<!--more-->
## 解决方法
1. 手动解决:
```go
//安装goimports
go get golang.org/x/tools/cmd/goimports
//更新报错的文件
goimports -w -local mit.com/adm <path-to-file>
```

2. 使用golang插件
```go
//安装goimports
go get golang.org/x/tools/cmd/goimports
```
接下来在报错的go文件窗口, 进入菜单 Tools | Go Tools 点击 Goimports file