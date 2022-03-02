---
title: go struct的指针
date: 2022-03-02 13:54:42
tags: ["golang", "pointer"]
categories: ["golang"]
---

## 指针概述
最早接触指针是大学学C的时候, 印象最深刻的就是说指针即地址, 随着工作经验的增加, 知道了,程序初始化对象时, (通常)会在内存中开辟空间来存放这个对象, 那在计算机处理这个对象时,必然需要知道这个对象所在的位置, 那么这个位置就是指针, 也就是你买了个房子, 住了进去, 那么为了让别人知道你家在哪, 那得有个地址.

## 再次理解
假设我们有一个对象 User1, 在内存中有一片自己的值空间:
```
||||| User1 |||||
| id   1        |
| name  LaoWang |
|||||||||||||||||
-----------------
|  0xc00000e038 |
```
<!--more-->
那么它本身必然是有一个地址, 上面这个图就是表达了这个意思, 0xc00000e038 就是它的地址

## 代编程语言中理解指针
Java中我们一般不需要理解指针, 因为java已经将其弱化, 或者可以理解为你在new的时候, 拿到的对象实际已经包含指针, 比如 User u = new User(), 此时u(对象的引用)中已经含有指针. 而golang, 我个人理解, 算是C, C++等语言的一种变体, 即保留了C/C++的一些特性又结合了面向对象语言中的一些特性, 而指针正是保留C/C++的一部分.

## go语言中的指针

### Hello world
下面的代码初始化了一个变量a, 然后用变量p, 获得了其指针并保存
```go
a:=10
var p *int
p=&a
fmt.Printf("%p\n", p)
```

### 结构体的指针
工作中, 我们最常见的就是结构体, 类似java中的各种对象, 当写java代码时, 我们不需要指针, 但是当我们读go代码时, 往往我们看到, 对结构体操作时, 通常是其指针的操作.

接下来, 我们假设一种常见的情况, 我们有一个User对象, 然后我们想通过ChangeId方法来修改它的值, 那么分使用指针和不使用指针的情况:

- 先定义结构体和构造方法

```go
//先定义一个结构体
type User struct {
	Id   int
	Sex  int
	Name string
}

//定义一个"构造器"
//这个构造器返回一个没有非指针的"对象"
func NewUser() User {
    return User{}
}

//定义一个"构造器"
//这个构造器返回"对象"的指针
func NewUserPtr() *User {
    return new(User)
}

//编写一个ChangeId方法, 方法参数为User类型
func ChangeId(u User) {
    u.Id = 10
}

//编写一个ChangeIdByPtr方法, 方法参数为User类型的指针
func ChangeIdByPtr(u *User) {
   //fmt.Printf("parameter user address %p %p %T %v\n", &u, u, u, *u)
    u.Id = 30
}
```

- 不使用指针的情况

```go
//那么我们来使用它
user := NewUser()
//打印结果可以得到{0 0 }
fmt.Println(user)
//调用ChangeId方法
ChangeId(user)
//{Id:0 Sex:0 Name:}
fmt.Printf("%+v\n", user)
```
可以看出, 此时 Id 并没有变成10, 依旧是0

- 使用指针的情况

```go
//那么我们来使用它
user := NewUserPtr()
//打印结果可以得到&{0 0 }
fmt.Println(user)
//调用ChangeIdByPtr方法
ChangeIdByPtr(user)
//{Id:10 Sex:0 Name:}
fmt.Printf("%+v\n", user)
```
修改成功

### 为什么指针可以?

一句话解释就是, go是在传参时, 传入的是值拷贝. 也就是说我们传入对象user1时, 不论是ChangeId(user User)还是ChangeIdByPtr(user * User), 传入的user是**值相同的不同对象**, 具体说, 假设内存中user 对象是:
```
||||| user1 |||||
| id   1        |
| name  LaoWang |
|||||||||||||||||
-----------------
|  0xc00000e038 |
```
那么此时ChangeId(user)中的user,由于go是值拷贝传递,则这个方法参数的user是
```
||||| user  |||||
| id   1        |
| name  LaoWang |
|||||||||||||||||
-----------------
|  0xc00000e099 |
```
所以你改的id实际改的是地址为 0xc00000e099 这里的id, 所以0xc00000e038的对象, 依然是1.

那么为什么ChangeIdByPtr(user * User) 可以修改成功呢? 因为此时传入的user指针是这个样子
```
||||| user  |||||
|  0xc00000e038 |
|||||||||||||||||
-----------------
|  0xc00000e119 |
```
那么此时, 方法体内, user.id=10, 就表示0xc00000e119指向的0xc00000e038指向的id更换为10, 而0xc00000e038指向的就是我们想改的对象, 所以他是成功的

以上的问题, 你可以打印在执行方法前后的对象的值, 指针, 类型, 来查看其变化过程, 例如:
```go
fmt.Printf("parameter user address %p %p %T %v\n", &u, u, u, *u)
```

### 总结
对于刚刚从面向对象转入go开发时, 建议直接全部使用指针, 然后慢慢根据开发经验的积累来改变自己对指针的使用