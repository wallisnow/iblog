---
title: jenkins pipeline加载groovy脚本
date: 2022-03-08 21:05:37
tags: ["jenkins","pipeline"]
categories: ["jenkins"]
toc: true
---

## 需求
有时我们希望将jenkins pipeline的代码模块化, 那么这时, 我们可以使用[Jenkins Shared Libraries](http://unprobug.com/2021/11/10/cicd/jenkins/jenkins-sharedlib-tuto/), 但有时我们的代码量不大时, 可以考虑直接加载脚本

## 插件 Pipeline: Groovy
首先安装Pipeline: Groovy插件, 详见[Pipeline: Groovy](https://plugins.jenkins.io/workflow-cps/)

## 如何使用

假设此时你有一个工程是这样:
```bash
project-with-tests$ tree -L 1
.
├── Jenkinsfile
├── logs.groovy
├── pom.xml
├── src
└── target
```
<!--more-->
而你自己定义了一个logs.groovy 来配置一些日志相关的操作, 例如
```groovy
//logs.groovy
void echoTest() {
    echo "test"
}

return this
```
注意, 这里最后有一个 `return this` 这是非常重要的, 那么如何使用呢, 我们往下看
```groovy
//Jenkinsfile
import hudson.model.*

def log

pipeline {
    agent { label "master" }
    stages {
        stage('build') {
            steps {
                script {
                    log = load "${WORKSPACE}/logs.groovy"
                    log.echoTest()
                }
            }
        }
        stage('Result') {
            steps {
                script {
                    FAILED_STAGE = env.STAGE_NAME
                }
                junit '**/target/surefire-reports/TEST-*.xml'
                archiveArtifacts 'target/*.jar'
            }
        }
    }
    post {
        always {
            script {
                echo "Failed stage name: ${FAILED_STAGE}"
            }
        }
    }
}
```
注意这里的 `log = load "${WORKSPACE}/logs.groovy"` 这里根据需要调整脚本位置即可

## 总结
这里注意两点

1. 注意被调用的groovy脚本, 最后需要返回(`retrun this`)
2. 注意 load 脚本时, 根据脚本路径调整其位置
3. 这种方法适合小型项目,不适合大型项目, 因为依旧会随着代码库的增大, 不易读的代码增多, 大型项目应使用 [Jenkins Shared Libraries](http://unprobug.com/2021/11/10/cicd/jenkins/jenkins-sharedlib-tuto/)