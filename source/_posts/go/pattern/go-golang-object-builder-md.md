---
title: go中实现简单的Object builder.md 
date: 2022-03-03 11:12:22 
tags: ["golang", "builder"]
categories: ["golang"]
---

## 建造者模式

在Java 中我们常用建造者模式来构建对象, 相较于传统构造器, 它更加灵活, 但是需要前期编码更多, 那么我们是否可以也在go中实现呢?

## Java中的对象builder
<!--more-->
下面的例子展示了Java 中是如何实现一个User对象的Builder, 可以看出创建User对象只需要根据需要以.的形式来添加属性值即可

```java
public class User {
    private final String phone;
    private final String address;

    public static class UserBuilder {
        private String phone;
        private String address;

        public UserBuilder phone(String phone) {
            this.phone = phone;
            return this;
        }

        public UserBuilder address(String address) {
            this.address = address;
            return this;
        }

        public User build() {
            User user = new User(this);
            validateUserObject(user);
            return user;
        }
    }

    public static void main(String[] args) {
        User user1 = new User.UserBuilder()
                .phone("1234567")
                .address("Fake address 1234")
                .build();
    }
}
```

## Go中的对象builder

```go
type Product struct {
	Id   int    
	Name string 
}

//Product构造函数
func NewProduct() *Product {
    return new(Product)
}

//定义Builder包含相同的属性
type ProductBuilder struct {
    id   int
    name string
}

//定义Builder对象
func NewProductBuilder() *ProductBuilder {
    return &ProductBuilder{}
}

//定义设置id属性方法
//这里返回builder, 以便以"." 的方式继续调用
func (builder *ProductBuilder) Id(id int) *ProductBuilder {
    builder.id = id
    return builder
}

//定义设置name属性方法
func (builder *ProductBuilder) Name(name string) *ProductBuilder {
    builder.name = name
    return builder
}

//build方法返回Product对象
func (builder *ProductBuilder) build() *Product {
    prod := NewProduct()
    prod.Id = builder.id
    prod.Name = builder.name
    return prod
}
```

测试
```go
productBuilder := NewProductBuilder()
build := productBuilder.Id(123).Name("Milk").build()
//&{123 Milk}
fmt.Println(build)
```

## 小结
这里是一个简单的建造者, 其实我们也可以考虑将这里的设置属性通用化, 类似with(fileName, value), 这样会更加灵活, 这里和标准的建造者模式还是不一样的,因为建造者模式实际是以接口的形式, 泛化创建者, 比如上面的Product, 可以是ChineseProduct, JapaneseProduct, 然后定义Builder接口, 两种product 各有各的builder, 最后按需通过director 来调用.