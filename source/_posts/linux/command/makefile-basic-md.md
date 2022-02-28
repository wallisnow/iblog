---
title: Makefile入门
date: 2022-02-03 10:34:51
tags: ["linux", "makefile"]
categories: ["linux"]
---

## Makefile 是什么

不写具体定义, 个人理解就是一个通用的将代码组织起来的工具, 在java中我们常用maven或者gradle, 他们可以帮助我们编译java, 打包, 配置等等. 而makefile则是将这个过程交给开发人员本身, 用目标文件和它是怎么来的定义make的过程, 比如, 我们有一个, 可执行文件a, 这个a引用了b, 那么我们定义这个a的依赖过程, 就可以写在make中

## 举个栗子
<!--more-->
### 入门例子1 - hello 
此时,创建一个Makefile文件(建议习惯性使用Makefile作为文件名, 避免不同系统直接拷贝后不可用的问题), 写入下面内容(注意, 第二行开头是tab键不是空格), 执行 make hello
```bash
hello:
	@echo "hello world"
```
会输出 "hello world", 这里的@符号是为了除去输出echo 语句

### 例子2 - 依赖传递

下面这个例子中, 我们定义一个main函数, 这个函数引用, add.c 和 dev.c. 然后在main函数中调用add和dev中的方法. 这里我们就需要用到 编译后的add和dev文件 add.o及dev.o给main.c: 


首先定义两个函数(以下代码放到同一个文件夹下), add 和 dev,这里重点关注make, 两个函数只是随意定义的即可

- add

头文件 add.h
```bash
#ifndef UNTITLED1_ADD_H
#define UNTITLED1_ADD_H
int add(int x, int y);
#endif //UNTITLED1_ADD_H
```

add.c
```bash
int add(int x, int y) {
    return x + y;
}
```

- dev

头文件 dev.h
```bash
#ifndef UNTITLED1_DEV_H
#define UNTITLED1_DEV_H
int dev(int i, int j);
#endif //UNTITLED1_DEV_H
```
dev.c
```bash
int dev(int x, int y) {
    return x / y;
}
```

- main.c

这里main引用了add 和 dev
```bash
#include <stdio.h>
#include "add.h"
#include "dev.h"

int main() {
    printf("Hello, World!\n");
    printf("add %i!\n", add(1,2));
    printf("dev %i!\n", dev(2,1));
    return 0;
}
```

- Makefile

这里注意
1. $^ 表示所有依赖, $@ 表示所有输出, 比如第一行的$^表示add.c, 也可以写成 gcc -c add.c
2. 比如第一个目标文件,是add.o
3. 第三个目标是main文件, 它的依赖则是 main.c, add.o, dev.o
```bash
add.o:add.c
	gcc -c $^

dev.o:dev.c
	gcc -c $^

main:main.c add.o dev.o
	gcc $^ -o $@
```
运行 make man, 可以即得到我们预期的main 的二进制文件, 使用./main执行即可. 如果此时你查看当前目录, 也可以看到add.o, dev.o 文件, 因为这些是中间目标文件.

### 删除目标文件

执行完或者执行前, 我们希望删除之前生成的文件
```bash
#定义一个变量来写clean 
C_CLEAN=clean

# 定义clean 目标
$(C_CLEAN):
	rm *.o main

# 定义一个all 来每次执行"main" 前都先删除之前的目标文件 	
all: $(C_CLEAN) main

# 定义伪目标
.PHONY: $(C_CLEAN)
```
那么, 此时, 我们只需要执行make all 即可. 这里定义了一个伪目标, 避免当存在文件名为clean文件时, 因为**makefile是以文件为默认目标, 且先尝试找文件**, 编译失败, 具体大家可以搜搜.PHONY的详细用法

#### 所有代码

目录
```bash
.
├── add.c
├── add.h
├── cmake-build-debug
├── CMakeLists.txt
├── dev.c
├── dev.h
├── main.c
└── Makefile

1 directory, 7 files
```

Makefile
```bash
A=hello
B=world
C=big $(B)

C_SOURCE=main.c dev.c add.c
C_CLEAN=clean

#目标文件一定要存在, 依赖文件可以不需要
#echo "hello world"
#hello world

#添加@后, 不会打印
#hello world
hello:
	@echo "hello world"

add.o:add.c
	gcc -c $^

dev.o:dev.c
	gcc -c $^

main:main.c add.o dev.o
	gcc $^ -o $@

all: $(C_CLEAN) main

#使用变量
vars:
	@echo $A
	@echo $B
	@echo $C

$(C_CLEAN):
	rm *.o main

.PHONY: $(C_CLEAN)
```

## 总结

单纯Makefile是非常强大的, 因为它把项目的编译主动权交给了开发人员, 那么个人理解, 如果是一些Iaas和Paas层的开发较常见使用, 比如涉及容器, kubernetes, vm等. 而软件层面往往使用现有的封装好的框架工具比如gradle此类即可. 


