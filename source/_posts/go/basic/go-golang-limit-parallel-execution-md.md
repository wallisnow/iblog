---
title: go 限制并行线程数
date: 2022-03-05 14:57:47
tags: ["golang", "thread"]
categories: ["golang"]
---

## go中的多线程

go 中启动线程很方便, 只需要在函数前 写go 关键字即可
```go
go func(i int) {
    log.Println(i)
    <-ch
}(100)
```
那么这里就有了问题, 如何限定多少个线程同时执行(或者说同批次)? 在生产环境, 为了避免并发数量过高, 引发:
> panic: too many concurrent operations on a single file or socket

那么我们需要解决这一问题

## 问题一, 如何保证所有线程都能结束
<!--more-->
java中我们常使用 *CountDownLatch*, go中也有类似的工具 *sync.WaitGroup*, 它主要包含以下三个方法

```go
// 添加屏障, delat 表示添加屏障的个数
wg.Add(delat int)
// 表示屏障-1
wg.Done()
// 表示阻塞等待, 等待屏障为0
wg.Wait()
```

通俗的讲, 有点类似短跑比赛, 裁判就是这个WaitGroup, 假设10个选手参加比赛, 那么裁判就在自己的比赛板上写10个人的名字,wg.Add(10). 然后开始比赛, 每当一个选手通过终点, 那么裁判就按一下秒表wg.Done(), 也就是比赛的人数-1. 期间裁判会一直等待wg.Wait(), 直到10个人都跑完. 

将上面的例子写成代码(这个代码不能保证线程同时开始, 不过这里不关心)
```go
func TestWaitGroup(t *testing.T) {
	var wgp sync.WaitGroup
	for i := 0; i < 10; i++ {
		wgp.Add(1)
		//模拟跑步
		go func(i int) {
			defer wgp.Done()
			fmt.Println("Runner No.", strconv.Itoa(i), " finished")
			Sleep(Second)
		}(i)
	}
	wgp.Wait()
}
```

## 问题二, 如何保证同批次

假设100个人比赛, 为了保证跑步每组10个, 我们应该是在跑步前, 让10个人都不要动(准确说是永远最多10人在跑道上起跑), 那么如何保证.
```go
func TestWaitGroup(t *testing.T) {
	var wgp sync.WaitGroup
	for i := 0; i < 10; i++ {
		wgp.Add(1)
		// -------------> 这里我们需要每十个一批阻塞
		//模拟跑步
		go func(i int) {
			defer wgp.Done()
			fmt.Println("Runner No.", strconv.Itoa(i), " finished")
			Sleep(Second)
		}(i)
	}
	wgp.Wait()
}
```
这里, 我们可以使用chan
```go
package test

import (
	"fmt"
	"golang.org/x/sys/unix"
	"strconv"
	"sync"
	"testing"
	. "time"
)

var wg sync.WaitGroup
//一个size为10 的channel
var batchCh = make(chan struct{}, 10)

func run(str string) {
	defer wg.Done()
	//每当跑步时, 给channel写入一个数据, 这里struct{}{}是什么, 我们是不不关心的
	//当channel元素到 10 个, 这里开始阻塞
	batchCh <- struct{}{}
	fmt.Printf("%v %s \n", unix.Gettid(), str)
	Sleep(Second)
	//每跑完一个, channel 减一个元素 
	<-batchCh
}

func TestParallel(t *testing.T) {
	for i := 0; i < 10000; i++ {
		//t.Skip("Skipping testing")
		wg.Add(1)
		go run("Runner No." + strconv.Itoa(i) + " finished")
	}
	wg.Wait()
}
```
运行后, 我们可以看出, 此时, 每10个线程一批开始执行

## 总结
我们这里实际还是利用了channel阻塞这一特性, 当然这里并不局限这一种方法