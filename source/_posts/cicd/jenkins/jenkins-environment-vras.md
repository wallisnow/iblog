---
title: Jenkins pipeline 中的环境变量
date: 2021-10-22 11:06:31
tags: ["jenkins"]
categories: ["jenkins"]
toc: true
---
这里Jenkins pipeline中的环境变量就是操作系统的环境变量, 和你在linux 中执行export一个变量是一样的, 其类型为String，不同的是，这个变量是位于这个pipeline生命周期内,也就是说pipeline结束,这个env就没有了

# 如何查看Jenkins 的环境变量
## 直接通过访问master节点的env-vars.html 
直接通过访问master节点的env-vars.html, 例如 ```http://<HOST>/env-vars.html/```, 你可以看到所有当前的环境变量, 但是这些环境变量只是jenkins此时预制的环境变量
<!--more-->
## 通过 printenv 查看
编辑Jenkinsfile脚本, 使用printenv.
例子:
```groovy
pipeline {
    agent { label "master" }

    stages {
        stage("Env Variables") {
            steps {
                sh "printenv"
            }
        }
    }
}
```

## 定义一个环境变量
编辑Jenkinsfile脚本, 例如定义一个 MY_ENV:
```groovy
pipeline {
    agent { label "master" }
    
    environment{
        MY_ENV="TEST ENV"
    }
    //这里打印刚才定义的变量及 打印所有变量
    stages {
        stage("Env Variables") {
            steps {
                sh "my test env: ${MY_ENV}"
                sh "printenv"
            }
        }
    }
}
```
运行结果:
```html
[Pipeline] sh
+ echo TEST ENV
my test env: TEST ENV
[Pipeline] sh
+ printenv
JENKINS_HOME=/var/jenkins_home
GIT_PREVIOUS_SUCCESSFUL_COMMIT=08d9a22a56672004193417d7e1c0ee0299c5b3a1
JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
CI=true
RUN_CHANGES_DISPLAY_URL=http://192.168.60.11:8080/job/test_my_pipeline/22/display/redirect?page=changes
HOSTNAME=f350d2b99e0a
NODE_LABELS=master
HUDSON_URL=http://192.168.60.11:8080/
GIT_COMMIT=df2e37a99a4f7a96793614d0c17f2912b4967ca1
SHLVL=0
... ...
```

## 重写环境变量的值

此时两种情况:
- 使用 _environment{}_ 定义的环境变量 
- 非 *environment{}* 环境变量

看下面的例子:
```groovy
pipeline {
    agent { label "master" }
    
    //使用environment{}定义MY_ENV
    environment{
        MY_ENV="TEST ENV"
    }
    
    stages {
        stage("Env Variables") {
            steps {
                sh "my test env: ${MY_ENV}"
                sh "printenv"
            }
        }
        stage('Set new env') {
            steps{
                script {
                    //不使用environment{}定义
                    env.MY_NEW_ENV = "foo"
                    //尝试修改MY_ENV
                    env.MY_ENV = "bar"
                    sh "echo MY_NEW_ENV: ${MY_NEW_ENV}, MY_ENV: ${MY_ENV}"
                    env.MY_NEW_ENV = "foofoofoo"
                    sh "echo MY_NEW_ENV: ${MY_NEW_ENV}, MY_ENV: ${MY_ENV}"
                }
                //使用withEnv 来修改MY_ENV
                withEnv(["MY_ENV=bar"]) { 
                    echo "MY_ENV = ${env.MY_ENV}" 
                }

            }
        }
    }
}
```
运行:
```html
... ...
[Pipeline] sh
+ echo MY_NEW_ENV: foo, MY_ENV: TEST ENV
MY_NEW_ENV: foo, MY_ENV: TEST ENV
[Pipeline] sh
+ echo MY_NEW_ENV: foofoofoo, MY_ENV: TEST ENV
MY_NEW_ENV: foofoofoo, MY_ENV: TEST ENV
[Pipeline] }
[Pipeline] // script
[Pipeline] withEnv
[Pipeline] {
[Pipeline] echo
MY_ENV = bar
[Pipeline] }
... ...
```
可以看出,普通直接定义的环境变量只需要 **env.** 赋值的形式即可,如果是使用 _environment{}_ 定义的环境变量, 是需要 withEnv([])方法的, 不然是不能修改成功的.
