---
title: "[博客搭建 0] - 新建并挂载自己的博客到github page"
date: 2021-07-09
draft: false
categories: ["blog"]
tags: ["hugo","blog", "tutorial"]
author: "Jiang WU"
comments: true
contentCopyright: '<a rel="license noopener" href="https://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License" target="_blank">Creative Commons Attribution-ShareAlike License</a>'

---

# 0. 搭建个人博客原料
*github pages*

这里, 由于我们的个人博客是运行中github上, 使用过得是github提供的免费的github pages, 所以github是必要的

*Hugo*

Hugo是一个免费的go语言博客框架, 会帮助我们生成静态的html及相关脚本, 类似Hexo, 本教程使用的是Hugo框架

<!--more-->
# 1. 安装HUGO

- Windows

打开Powershell, 右键管理员权限, 使用choco安装
```
$ choco install hugo -confirm
```

- Linux

打开Terminal, 使用snap安装
```
$ sudo snap install hugo
```

> 更多安装方式, 请参考官方文档: https://gohugo.io/getting-started/installing/

# 2. 创建一个hugo github page

## 2.1 创建git page 的 repository

Repository 就是一个普通的git 项目, git page 是通过解析项目来加载我们的静态网页文件, 小白的话, 就不必关心它是什么了

- 登录 https://github.com/, 点击 "Sign Up", 根据提示完成github的注册
- 登录自己的github
- 创建一个repository, 注意这里需要填写和你用户名一致的repo名, 再跟上.github.io 
  ![alt text](https://res.cloudinary.com/djpkulbas/image/upload/v1625820727/blog/git_hub_create_a_new_blog_repo_smvmx3.png "Title")
- 选择public, 然后点击create repository
- 接下来你会看到一个Git操作指引, 这里先不要管, 我们先做后续的步骤
  ![alt text](https://res.cloudinary.com/djpkulbas/image/upload/v1625820982/blog/git_hub_create_a_new_blog_repo_command_jmcf3p.png "Title") 

## 2.2 安装git
由于生成的git操作指引是需要安装git的, 那么我们需要先安装它, 安装信息: https://git-scm.com/downloads

## 2.3 创建一个本地hugo 网页库

例如, 我在 ~/tmp/blog 下创建, 那么执行 hugo new site .

```
test@1vvp2:~/tmp/blog$ hugo new site .
Congratulations! Your new Hugo site is created in /home/tmp/tmp/blog.

Just a few more steps and you're ready to go:

1. Download a theme into the same-named folder.
   Choose a theme from https://themes.gohugo.io/ or
   create your own with the "hugo new theme <THEMENAME>" command.
2. Perhaps you want to add some content. You can add single files
   with "hugo new <SECTIONNAME>/<FILENAME>.<FORMAT>".
3. Start the built-in live server via "hugo server".

Visit https://gohugo.io/ for quickstart guide and full documentation.
```

此时如果你查看当前的文件夹, 会发现hugo 已经创建了所有需要的文件

```
test@1vvp2:~/tmp/blog$ ls
archetypes  config.toml  content  data  layouts  static  themes
```

测试一下网页, 会提示本地网站运行在 http://localhost:1313/
```
test@1vvp2:~/tmp/blog$ hugo server
```
浏览器输入 http://localhost:1313/ 发现是空白页, 但是没有报错, 证明hugo运行正常, 空白的原因是我们没有加载主题

## 2.3 使用Hugo主题

登录 https://themes.gohugo.io/tags/blog/ 选择一款自己喜欢的主题, 一般主题分Blog 和 个人主页, 如果是想突出个人, 就选择 个人主页, 如果是记录性质的, 选择 Blog
这里以cactus 为例

```
tmp@e1vvp2:~/tmp/blog$ cd ~/tmp/blog

//克隆主题到本地的/theme
tmp@e1vvp2:~/tmp/blog$ git clone https://github.com/monkeyWzr/hugo-theme-cactus.git themes/cactus
... ...
tmp@e1vvp2:~/tmp/blog/themes$ cd cactus/
tmp@e1vvp2:~/tmp/blog/themes/cactus$ ls
assets  exampleSite  images  layouts  LICENSE  README.md  static  theme.toml

//将模版网页应用于本地
tmp@e1vvp2:~/tmp/blog/themes/cactus$ cp exampleSite/* ../../
```

此时, 再次运行 
```
hugo server
```

登录 http://localhost:1313/, 你会发现现在的页面已经变了
![alt text](https://res.cloudinary.com/djpkulbas/image/upload/v1625822540/blog/hugo_theme_exp_Cactus_taqz59.png "Title")

## 2.4 创建新的页面

在hugo 的本地网页代码库中, content文件夹下创建文件夹 posts, 然后创建一个 test.md 的markdown文件输入如下内容
```
---
title: "你好"
tags: ["hello"]
categories: ["hello"]
---

你好
```
![alt text](https://res.cloudinary.com/djpkulbas/image/upload/v1625822988/blog/hugo_theme_exp_Cactus_test_page_md_dqdwhe.png "Title")
此时再次查看 http://localhost:1313/, 你会发现你的页面已经出现了
![alt text](https://res.cloudinary.com/djpkulbas/image/upload/v1625822988/blog/hugo_theme_exp_Cactus_test_page_output_ueajhs.png "Title")

> 通过 Ctrl+c 来停止正在运行的网页

## 2.5 将自己的页面和github page 连起来
这时我们再回头看看刚才github为我们创造的操作指南, 那么我们现在需要将本地的网页放在github上跑起来

- 1. 生成静态页面 *hugo -D*
```
test@1vvp2:~/tmp/blog$ hugo -D
Start building sites … 
hugo v0.85.0+extended linux/amd64 BuildDate=2021-07-05T14:34:48Z
WARNING: calling IsSet with unsupported type "ptr" (*hugolib.SiteInfo) will always return false.

                   | EN  
-------------------+-----
  Pages            | 13  
  Paginator pages  |  0  
  Non-page files   |  0  
  Static files     | 59  
  Processed images |  0  
  Aliases          |  3  
  Sitemaps         |  1  
  Cleaned          |  0  

Total in 56 ms

//此时会生成一个静态网页文件夹public
test@1vvp2:~/tmp/blog$ ls
archetypes  config.toml  content  data  deploy.sh  layouts  netlify.toml  public  resources  static  themes

```

- 2. 推送自己的网页到远端
```
// 进入public 文件夹, 执行初始化 git
tmp@e1vvp2:~/tmp/blog/public$ git init
Initialized empty Git repository in /home/tmp/tmp/blog/public/.git/

// 给定远端的博客地址
tmp@e1vvp2:~/tmp/blog/public$ git remote add origin git@github.com:JohnAndEthan/JohnAndEthan.github.io.git

// 添加本地页面代码, 并提交
tmp@e1vvp2:~/tmp/blog/public$ git add .
tmp@e1vvp2:~/tmp/blog/public$ git commit -m "我的博客"
[master (root-commit) 054cd26] 我的博客
 78 files changed, 11636 insertions(+)
 
// 提交到远端库
tmp@e1vvp2:~/tmp/blog/public$ git branch -M main
tmp@e1vvp2:~/tmp/blog/public$ git push -u origin main
Counting objects: 110, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (100/100), done.
Writing objects: 100% (110/110), 3.11 MiB | 1.53 MiB/s, done.
Total 110 (delta 23), reused 0 (delta 0)
remote: Resolving deltas: 100% (23/23), done.
To github.com:JohnAndEthan/JohnAndEthan.github.io.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

## 2.6 修改 baseURL
记得在 config.toml 中修改自己的baseURL 指向你的github page地址, 不然有可能页面不能加载主题
```
baseURL = "https://johnandethan.github.io/"
```

# 3. 测试
此时输入刚才我们 创建的repo地址, https://johnandethan.github.io/ 就可以看到我们的网页了

# 4. 遇到问题怎么办
- 如果是失误操作, 直接删掉你本地的文件夹, 和github 的repository 重来就行了
- 如果是其他问题, 一般多数是由于主题的使用, 建议仔细阅读主题的相关文档