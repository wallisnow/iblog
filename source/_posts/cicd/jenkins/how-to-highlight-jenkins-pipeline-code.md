---
title: "[jenkins]Intellij jenkins pipeline代码高亮设置"
date: 2021-10-22 10:13:50
tags: ["jenkins", "Intellij"]
categories: ["jenkins"]
toc: true
---

# 问题
在CICD的建设中, jenkins的pipeline代码一般是脚本的形式存在, 作为一个开发人员, 我们往往熟悉了idea给我们提供的代码高亮和验证功能, 那么是否可以实现代码高亮? 答案是可以, 但是并没有我们写传统java, Python等代码时那么完善, 不过总被没有强

# 方法
## 配置pipeline代码让groovy可以识别
在Intellij 的setting中, 找到File types, 然后按下图让Intellij识别你的Jenkinsfile为groovy文件
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634887503/blog/jenkins/jenkins1_lwce9g.png)
<!--more-->
## 配置pipeline的语法声明描述文件
假设你的项目是如下模样,Jenkinsfile在根目录:
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634888025/blog/jenkins/jenkins2_kkhfg6.png)
然后在你的jenkins pipeline 上找到 **IntelliJ IDEA GDSL**, 并复制它
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634888367/blog/jenkins/jenkins3_hceyz4.png)
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634888367/blog/jenkins/jenkins4_hndlrh.png)
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634888367/blog/jenkins/jenkins5_kkb1wk.png)
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634888367/blog/jenkins/jenkins6_huyych.png)
最后在你的项目src中, 也就是源文件中创建一个jenkins.gdsl
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634888367/blog/jenkins/jenkins7_fxidoy.png)
此时就完成了配置

# 效果
再次查看自己的Jenkinsfile 已经有了部分提示
![](https://res.cloudinary.com/djpkulbas/image/upload/v1634888610/blog/jenkins/jenkins8_lmq1rz.png)
正如之前所说, 这个地方还不完善, 网上也有其他的gdsl文件, 大家可以关注 [这个issue](https://gist.github.com/arehmandev/736daba40a3e1ef1fbe939c6674d7da8)



