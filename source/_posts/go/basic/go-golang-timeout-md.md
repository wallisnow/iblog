---
title: go中实现简单异步回调函数
date: 2022-03-06 20:16:13
tags: ["golang", "channel"]
categories: ["golang"]
---

## 回调函数
回调函数是指当程序执行到某种条件时, 执行一些action, 比如, 当程序正确执行完成, 回调某函数, 这里比较绕的地方就是, 此程序是异步执行, 主线程是不关心它是否结束, 所以也就产生了回调的概念

## 使用场景
假设我们有一个程序A正在运行, 同时, 我们希望异步执行B程序, 执行完成后让用户知道, B执行完成, 比如打印什么的, 那么这种情况就是一种异步回调

## 代码
我们模拟一个这样的场景, task线程比如我们就是一个耗时的操作sleep, 那么我们希望B正常执行完成后, 回调函数, 控制台输出成功
<!--more-->
```go
//定义一个channel来记录task的执行结果
var result = make(chan string)

//模拟一个耗时的操作, 操作完成给channel 写入success
func task(){
    time.Sleep(time.Second * 3)
	result <- "success"
}

//启用一个线程(go中叫协程)来执行task
//这里注意 return 是不会被阻塞的
func start() chan string{
	go task()
	return result
}

//定义一个回调函数
func callback() {
    fmt.Println("do something more")
}

func runTask() (interface{}, error){
	//运行task
    start()
	
	//使用select 来定义场景, 假设result有只值则回调callback 方法
	//若执行过久则超时
	select{
	    case:  c := <-result:
			callback()
			return c, nil 
		case:  <- time.After(time.Second * 5):
            return nil, fmt.Errorf("\ntimeout")
    }   
}


func TestTimeout(t *testing.T) {
    r, err := runTask()
    if err != nil {
        fmt.Println(err)
        return
    }
        fmt.Println(r)
    }
```

## 总结
这里利用了channel 和select来实现 timeout的控制, 同时, 也利用此特性来实现回调,这里注意我们可以直接将回调函数放在内部, 例如:
```go
func task(call func()) {
	time.Sleep(time.Second * 3)
	result <- "success"
	call()
}
```
这里只是抛砖引玉, 可以根据需求来调整回调的位置及条件