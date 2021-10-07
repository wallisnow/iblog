---
title: "[博客搭建 1] - 在goDaddy购买域名并绑定博客"
date: 2021-07-05T18:08:23+03:00
categories: ["blog"]
tags: ["hugo","blog","tutorial"]
comments: true
toc: true
---
# 0. 域名(Domain name)是什么
[维基百科][domain-name]中定义: 网域名称（英语：Domain Name，简称：Domain），简称域名、网域，是由一串用点分隔的字符组成的互联网上某一台计算机或计算机组的名称，用于在数据传输时标识计算机的电子方位。域名可以说是一个IP地址的代称，目的是为了便于记忆后者。
大白话就是说, 用一个好记的名字来代表ip地址. 类似别人问你在哪, 你会说"我在北京路", 而不会说我在北纬41°24'12.2 ... 

# 1. 为什么博客要Domain name
高端,大气,上档次

# 2. 在哪儿买Domain name
这里就放两个常用的:
* 国内: https://wanwang.aliyun.com/domain/
* 国外: https://www.godaddy.com/

<!--more-->
# 3. 实例 (goDaddy)
由于我是用goDaddy, 我这里就直接用它来讲解

## 3.1 搜索并购买域名
登录 https://hk.godaddy.com/ 实例并搜索你要的域名
![alt text](/gallery/buy_domain_godaddy.png "Title")
根据自己的需要选定服务, 例如这里的全方位保护项, 戴保护肯定安全, 不戴后果自负, 反正我不爱戴
![alt text](/gallery/order_domain_godaddy.png "Title")
付账, 邮箱确认, 完毕

# 3.2 绑定自己的git page
## 3.2.1 配置 A 记录
先说概念, A(Address)记录: 顾名思义就是地址, 也就是说, 假设你访问 google.com, 那么请求发出去后, 实际是访问google.com 的IP地址, 就是这个地址, 当然真正的访问过程要复杂得多, 这里简单理解即可, 配置位置
![alt text](/gallery/config_a_recard_0.png "Title")
点击自己的域名, 既可以开始配置, 此时有可能要求你邮箱确认, 你确认一下
![alt text](/gallery/config_a_recard_1.png "Title")
拖到最下面, 进入配置页面
![alt text](/gallery/config_a_recard_2.png "Title")
点击编辑按钮, 编辑A记录, 此时配置地址 *185.199.108.153*, 这个地址就是 [git page](https://docs.github.com/cn/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site) 的 IP 
![alt text](/gallery/config_a_recard_3.png "Title")
当前的ip地址包含:

|GIT PAGE IPS|
|-----------------|
| 185.199.108.153 |
| 185.199.109.153 |
| 185.199.110.153 |
| 185.199.111.153 |

如果你觉得填一个不保险, 点击 "加入" 按钮, 填写方法和图里面的一样添加 *185.199.109.153* ...

## 3.2.2 将git page 和 domain name 连起来

登录自己的github page工程, 添加一个名为CNAME的文件
![alt text](/gallery/config_a_recard_4.png "Title")
CNAME文件内容就是你自己的域名
![alt text](/gallery/config_a_recard_5.png "Title")

## 3.3 测试
![alt text](/gallery/blog_home_page.png "Title")

## 3.4 http 添加 ssl 证书
也就是 http -> https, 这一步需要在你自己的git page 工程下, 勾选 "Enforce HTTPS", 这里需要一定的时间, 因为github 需要生成ssl证书给你
![alt text](/gallery/add_ssl_to_http.png "Title")
过一段时间后, 你便可以看到自己的博客协议已经是https, 不过, 这里有个证书信任问题, 我们可以后面在处理

# 4. 结论
没结论

[domain-name]: https://zh.wikipedia.org/wiki/%E5%9F%9F%E5%90%8D  "wiki: domain name"
