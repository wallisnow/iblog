---
title: "[Jenkins Job DSL]jenkins pipeline 编写共享库"
date: 2021-11-10 09:47:09
tags: ["jenkins", "Intellij"]
categories: ["jenkins"]
toc: true
---

## Jenkins Shared Libraries
使用Jenkins pipeline时, 我们有时不希望代码过于混乱, 代码过于重复,比如一个公用方法, 公用类我们希望它是编写一次, 然后被共享, 但是在Job DSL Plugin 1.60, 以前, 我们可以通过注入共享的groovy文件来达到目的, 但是新版本由于安全问题 [Script-Security](https://github.com/jenkinsci/job-dsl-plugin/wiki/Script-Security), 这种注入的方法被关闭, 如若没有管理员权限开放, 这种方法是不可以使用了:

_To avoid loading arbitrary code from the workspace without approval, the script directory is not added to the classpath and additional classpath entries are not supported when security is enabled. Thus importing classes from the workspace is not possible and the “Additional Classpath” option is not available._

## 如何使用和扩展 Shared Libraries
官网介绍的比较清楚: [传送门](https://www.jenkins.io/zh/doc/book/pipeline/shared-libraries/)

接着上面官网的例子, 实际应用中需要注意的几个点:
<!--more-->
### 目录结构

这个结构中src 可以理解为java中的src, vars可以理解为你要写的pipeline step调用方法, 比如我们可以将一些公用的类, 方法放在src, 比如下图中Bar.groovy, 然后, 你计划写一个 sayHi() 的step中的方法, 那么可以在这里写一个sayHi.groovy, 这个sayHi.groovy 可以调用Bar.groovy这个类.
```bash
(root)
+- src                     # Groovy source files
|   +- org
|       +- foo
|           +- Bar.groovy  # for org.foo.Bar class
+- vars
|   +- foo.groovy          # for global 'foo' variable
|   +- foo.txt             # help for 'foo' variable
|   +- sayHi.groovy 
+- resources               # resource files (external libraries only)
|   +- org
|       +- foo
|           +- bar.json   # static helper data for org.foo.Bar
```

### step 方法的写法

紧接着上面的例子, 那么Bar.groovy和sayHi.groovy分别怎么写
```groovy
//Bar.groovy
package org.foo

class Bar {
    String name
}
```

```groovy
//sayHi.groovy
import org.foo.Student

def call(String name = "foo") {
    def bar = new Bar('name': name)
    echo "Hello, ${bar.name}."
}
```
这个地方最重要是注意, 包, 也就是"package" 和 "import", 生产中, 有时会因为包产生类似 _cannot resolve symbol_ 或者找不到包这些问题, 这也是你debug时候可能遇到的问题. 另外一个, 这个地方必须实现call()方法, 也就是脚本的入口

### 使用自己的公共文件

我这里没有说 "使用自己的共享库", 而是 "自己的公共文件", 原因是, 你不用共享库同样可以达到共享的效果, 请往下看

#### classpath 的配置

- Job DSL 1.60 插件版本前

这个版本前可以参考 https://github.com/sheehan/job-dsl-gradle-example, 这个例子包含是一个以gradle为管理工具的工程, 不是重点, 重点是需要和上面说的目录结构一致即可. 1.6 版本前, 我们可以使用Additional classpath, 比如, 这个工程中, 目录结构是:
```bash
.
├── src
│   ├── jobs                # DSL script files
│   ├── main
│   │   ├── groovy          # support classes
│   │   └── resources
│   │       └── idea.gdsl   # IDE support for IDEA
│   ├── scripts             # scripts to use with "readFileFromWorkspace"
│   └── test
│       └── groovy          # specs
└── build.gradle            # build file
```
然后在自己jenkins UI Job界面上, BUILD下process Job DSLs 项中配置Additional classpath: **src/main/groovy**. 也就是让你的pipeline 脚本能找到这个.class文件. 这个地方个人理解, 因为jenkins pipeline类加载的方式和java, groovy 不太一样, 它有自己的顺序, 所以也就有了之前包的问题的存在. 即便如此, 你还是需要注意包的问题, 也就是 "import" 和 "package". 假设你的additional path配置不好, 很有可能碰到一些问题. 之前就因为同时配置时错误, 导致src是一个普通存在的包, 所以, 绕道(因为没权限)测试发现我们需要"package src", 引入时就是"import src.Myclass". 总之,这里也就是我之前提到的不用共享库同样可以达到共享的效果.

- Job DSL 1.60 插件版本后

前面也说了, 1.6后, 你可以手动在全局配置 Configure Global Security, 中不勾选Enable script security for Job DSL scripts, 这样你就可以继续使用Additional classpath, 而不用上面的共享库. 但是不建议这么做, 显然如果有人恶意利用漏洞(CVE-2018-1000861), 那么老板和小姨子只能跑路了.

安全期间,还是在jenkins中配置自己的库, 具体参考官方文档, 一般快速配置就是在全局配置中配置 Global Pipeline Libraries, 配置自己的代码库即可![](https://www.jenkins.io/zh/doc/book/resources/pipeline/configure-global-pipeline-library.png), 同时也可以根据需要, 使用灵活的配置方法.

#### 调用
你可以在你的dsl job 中build Triggers 下 Pipeline选项卡中, 选择Pipeline script选项卡下测试
```groovy
//调用共享库
@Library('pipeline-library-demo')_
// 你也可以直接引用共享库中的类
// import com.wj.GlobalVars

stage('Demo') {
    echo 'Hello world'
    //调用 sayHi.groovy, sayHi中定义了call方法.
    sayHi 'test test test'
}
```

## 开发框架
这里有一个比较好的gradle管理, jenkins dsl 共享库插件, 但是年久失修, 不过能凑合用: [插件](https://github.com/mkobit/jenkins-pipeline-shared-libraries-gradle-plugin#5-minute-onboarding), [例子](https://github.com/mkobit/jenkins-pipeline-shared-library-example)

## 参考

- https://emilwypych.com/2018/04/15/jenkins-unable-resolve-class-utilities-myutilities/
- https://github.com/jenkinsci/job-dsl-plugin/wiki/Script-Security
- [Jenkins + Groovy脚本 = 高效✔✔ （纯干货）](https://blog.csdn.net/DynastyRumble/article/details/119208326#t9)
- intellij
