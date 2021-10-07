---
title: "[Spring][Webflux]如何找出webflux中的阻塞方法"
date: 2021-07-02T11:55:41+03:00
tags: ["java", "spring", "webflux"]
categories: ["java", "spring", "webflux"]
comments: true

thumbnailImage: /img/spring.png

contentCopyright: '<a rel="license noopener" href="https://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License" target="_blank">Creative Commons Attribution-ShareAlike License</a>'

---

<!--more-->
# 0. 为什么需要找到Blocking call
我们使用reactor编程时，其目的就是希望我们的程序符合异步非阻塞的模型，为了达到这个目的，我们希望我们程序中所有的方法都是非阻塞的方法(理想状态)，比如我们在处理JDBC链接时，会考虑使用Schedulers来包裹或是使用R2DBC，那么在响应式编程中，我们会遇到形形色色的阻塞方法，此时，我们就需要用合理的方式处理它们了.
<!--more-->
# 1. 解决方案
BlockHound

# 2. Git 地址
https://github.com/reactor/BlockHound

# 3. 大致原理
类似于Java代理，再入口函数调用前被JVM加载，一旦BlockHound启动，其将标记阻塞方法(例如: sleep()) .并改变其behaviour而抛出一个Error

# 4. 引入BlockHound
在自己的工程中引入BlockHound

## 4.1. maven
```xml
<dependency>
  <groupId>io.projectreactor.tools</groupId>
  <artifactId>blockhound-junit-platform</artifactId>
  <version>1.0.0.RC1</version>
  <scope>test</scope>
</dependency>

```

## 4.2. Gradle
```groovy
repositories {
mavenCentral()
// maven { url 'https://repo.spring.io/milestone' }
// maven { url 'https://repo.spring.io/snapshot' }
}

dependencies {
testCompile 'io.projectreactor.tools:blockhound:$LATEST_RELEASE'
// testCompile 'io.projectreactor.tools:blockhound:$LATEST_MILESTONE'
// testCompile 'io.projectreactor.tools:blockhound:$LATEST_SNAPSHOT'
}

```

# 5. 使用示例
```java
public class DetectBlockingCall {

    @BeforeEach
    void setUp() {
        // 1. 初始化BlockHound
        BlockHound.install();
    }

    // 2. 定义一个阻塞方法
    void blockingCall() {
        Mono.delay(Duration.ofSeconds(1))
                .doOnNext(it -> {
                    try {
                        Thread.sleep(10);
                    } catch (InterruptedException e) {
                        throw new RuntimeException(e);
                    }
                })
                .block();
    }

    @Test
    void blockHoundSimpleTest() {
        //3. 调用阻塞方法
        Throwable throwable = Assertions.assertThrows(Throwable.class, this::blockingCall);
        //4. 验证阻塞方法是否抛出异常
        Assertions.assertTrue(throwable.getMessage().contains("Blocking call!"));
    }
}
```

在这个示例中，第一步加载BlockHound实际是可以省略的，因为我们引入BlockHound到junit 实际是已经被预加载, 大家可以去除这一步再次执行测试代码尝试

# 6. 构建项目时自动执行BlockHound

往往我们希望我们自身的项目可以自动执行BlockHound，从而每次运行测试代码便可以知道我们的代码问题在哪里，那么这里提供一种思路，即使用项目构建工具来执行BlockHound, 以Gradle为例.

## 6.1. 编写定制化BlockHound模块 (当然你可以不定制化)

在开发中，往往我们不可避免的使用部分部分阻塞方法，那么此时我们需要测试时排除这些方法. 此时我们可以定义一些定制化类，例如:

新建一个工程com.test.support， 新建一个模块叫做blockhound-integration, 然后新建一个Log的忽略类

```java
public class LogBlockHoundIntegration implements BlockHoundIntegration {
// 使用系统变量来达到开关的目的
    private static final boolean ENABLED = Boolean.parseBoolean(System.getProperty("LogBlockHoundIntegration.enabled", Boolean.FALSE.toString()));
    @Override
    public void applyTo(BlockHound.Builder builder) {
        if (!ENABLED) {
            return;
        }
        // 加入要忽略的阻塞方法
builder.allowBlockingCallsInside(
                "ch.qos.logback.classic.Logger",
                "buildLoggingEventAndAppend");
    }
}

```

## 6.2. 定义测试监听类

实现TestExecutionListener, 静态加载BlockHound，使得所有测试方法都需要加载BlockHound

```java
public class BlockHoundTestExecutionListener implements TestExecutionListener {
    static {
        BlockHound.install(builder -> {
            builder.blockingMethodCallback(method -> {
                Error error = new BlockingOperationError(method);
                error.printStackTrace(System.err);
                throw error;
            });
        });
    }
}

```

## 6.3. 在自己模块的gradle文件中定义方法，引入我们的定义及默认的junit平台

```groovy
ext {
    // add helper to activate Reactor BlockHound, https://github.com/reactor/BlockHound
    useReactorBlockHound = { ->
        project.dependencies {
            testRuntimeOnly 'com.test.support:blockhound-integration', 'org.junit.platform:junit-platform-launcher'
        }
    }
}
```

# 6.4. 定义执行操作入口

build.gradle 中插入

```groovy
subprojects { subproject ->
  subproject.useReactorBlockHound()
}

// 打开我们自己定义的生效类

tasks.withType(Test) {
        // ignore the blocking nature of Log
        systemProperty 'LogBlockHoundIntegration.enabled', 'true'
    }

```

至此，我们基本可以满足gradle项目开发中所需要的自动化测试了。如果你在使用maven，可以构建自己的maven插件，来实现自动化流程，具体逻辑与gradle是类似的

# 6. 结论
响应式编程是基于我们想充分利用异步非阻塞而产生的一种设计，但如今我理解技术正处于一个转型期，往往我们会遇到阻塞+非阻塞的囧境，为了解决这个问题，今天引入BlockHound工具来探测我们程序中潜在的阻塞API，使我们更快的发现问题并做出调整.

# 7. ref
[https://medium.com/@domenicosibilio/blockhound-detect-blocking-calls-in-reactive-code-before-its-too-late-6472f8ad50c1](https://medium.com/@domenicosibilio/blockhound-detect-blocking-calls-in-reactive-code-before-its-too-late-6472f8ad50c1)