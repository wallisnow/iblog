---
title: "[kubernetes] kustomize 入门例子"
date: 2021-07-12
draft: false
tags: ["kubernetes", "kubernetes工具"]
categories: ["kubernetes"]
author: "Jiang WU"
comments: true
contentCopyright: '<a rel="license noopener" href="https://creativecommons.org/licenses/by-nc-sa/4.0/" target="_blank">Creative Commons Attribution-ShareAlike License</a>'
---

# 0. 简介

kustomize 形如customize, 也就是k8s+customize, 它是kube资源描述文件的一种抽象工具.

> 官方地址: https://kustomize.io/
<!--more-->
# 1. 为什么会用 kustomize

kustomize它作用类似Helm, 它的实现方式和helm不同, helm是基于模版, 而kustomize是基于overlay 引擎. 通俗讲就是说, 你写一个普通的k8s资源描述yaml文件, 那么所有东西都是写死的, 此时如果你有helm, 你可以把部分值写成变量模版, 达到灵活的目的. 而kustomize更像是代码式的声明将,基代码和定制化代码重叠, 达到灵活的目的, 有时我们的配置比较简单且固定, 此时, 我们更希望一种快捷易于操作的方式, 那么此时就可以考虑kustomize, 当然这不代表kustomize只能写简单的东西.

我们来看一下需求是怎么来的:

假设我们有一个pod.yaml:
```
# pod.yaml contents
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: web
    image: web:v.1.0
```
一切看起来都很好, 突然有一天, 老板说, 我们客户给了一个新环境, 我们得再部署一套应用到名叫XINHUANJING的新环境, 此时你可能会说, 好办, 看我粘贴复制大法, 只需改点点配置.
```
# pod.yaml contents
apiVersion: v1
kind: Pod
metadata:
  name: XINHUANJING-myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: web
    image: web:v.1.0
```
过了两天经理又来找你说, 我们的产品升级, 原来的k8s资源库也要更新, 把web app升级到2.0, 那么你可以继续粘贴复制, so easy!
```
# pod.yaml contents
apiVersion: v1
kind: Pod
metadata:
  name: XINHUANJING-myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: web
    image: web:v.2.0
```
等等, 我还需要更新客户环境的描述文件夹, 粘贴复制 ... 

接下来的日子, 你发现随着业务量的增加, 客户的跟进, 乱七八糟deployment, statfulset ... 越来越多, 客户要的也不止改个名字那么简单, 此时粘贴复制好像就没那么好用了. 此时, 你便需要一个可以一通百通的方式来管理你的配置, 那么kustomize 和helm 就可以帮忙了.

# 2. 入门案例

我们有两套环境, 我们需要分别在不同的开发环境(dev, prod)中, 配置不同的应用名

# 2.1 基代码

```
//创建一个 基代码文件夹
test@master-0-test01:~> mkdir base

//创建基代码
test@master-0-test01:~> cd base/
test@master-0-test01:~/base> ls
kustomization.yaml  pod.yaml

//声明资源文件
test@master-0-test01:~/base> cat kustomization.yaml 
# kustomization.yaml contents
resources:
- pod.yaml

//资源pod文件, 可以是各种k8s复杂的资源, deployment, resfulset, cm ...
test@master-0-test01:~/base> cat pod.yaml 
# pod.yaml contents
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp
spec:
  containers:
  - name: nginx
    image: nginx:latest
```
此时, 你可以看出, 这个时候, 如果你直接kubectl apply 那么它会直接创建一个pod. 接下来我们来根据不同的环境改变这个pod

# 2.2 写各个环境的特殊配置

假设我们有两个环境, 一个是开发环境 dev, 一个是 prod 环境, 我们希望 dev 环境的 pod 会标识出来 dev, 我们希望 prod 环境的 pod 会标识出来 prod

```
test@master-0-test01:~> mkdir overlays
test@master-0-test01:~> cd overlays/
test@master-0-test01:~/overlays> ls
dev  prod

test@master-0-test01:~/overlays> ls dev/
kustomization.yaml
test@master-0-test01:~/overlays> ls prod/
kustomization.yaml

//dev 环境的描述文件, 此时使用了kustomize的 namePrefix 标签
test@master-0-test01:~/overlays> cat dev/kustomization.yaml 
resources:
- ../../base
namePrefix: dev-

//prod 环境的描述文件
test@master-0-test01:~/overlays> cat prod/kustomization.yaml 
resources:
- ../../base
namePrefix: prod-
```

可以看出, 描述文件使用了资源 ../../base, 这里类似我们写代码的import, 而且是个静态的import

# 2.2 写一个总的入口文件

这时我们想看看生成的每个环境的描述文件是否正确, 此时我们需要在工作目录的*根目录*下创建一个总括的 kustomization.yaml 

```
test@master-0-test01:~> cat kustomization.yaml 
resources:
- ./overlays/dev
- ./overlays/prod
namePrefix: my-name-
```
可以看到, 我们的resources引入了 刚才我们创建的两个环境. 再看看此时的目录结构(我没装tree)

```
test@master-0-test01:~> pwd
/home/test
test@master-0-test01:~> ls
base  kustomization.yaml  overlays
test@master-0-test01:~> ls base
kustomization.yaml  pod.yaml
test@master-0-test01:~> ls overlays/
dev  prod
```

# 2.3 测试
执行 kustomize build <path-to-root-kustomization.yaml> 会生成预览文件(和helm 很类似), 可以看出我们的pod名当前前缀都已经变化
```
// 如果你的集群没有kustomize, 可以下载: 
// curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

test@master-0-test01:~> kustomize build
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: myapp
  name: my-name-dev-myapp-pod
spec:
  containers:
  - image: nginx:latest
    name: nginx
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: myapp
  name: my-name-prod-myapp-pod
spec:
  containers:
  - image: nginx:latest
    name: nginx
```

# 2.4 创建pod

```
test@master-0-test01:~> kubectl apply -k .
pod/my-name-dev-myapp-pod created
pod/my-name-prod-myapp-pod created
```

# 3. 总结
本例抛砖引玉, 实际生成也不可能只是个pod, 那么kustomize也提供了各种相关标签供大家使用: https://kubernetes.io/zh/docs/tasks/manage-kubernetes-objects/kustomization/