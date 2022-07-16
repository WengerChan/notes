# Markdown

## 1. 标题

```md
# 111
## 222
...
###### 666666
```

## 2. 斜体

```md
*xieti*
```

## 3. 粗体

```md
**cuti**
```

### 粗斜体

```markdown
***cuxieti***
```

## 4. 插入链接

```md
[哔哩哔哩](http://www.bilibili.com "title") title可以省略
```

```md
<http://www.bilibili.com>
```

扩展用法：

```md
[哔哩哔哩][wangzhi1]
[wangzhi1]:http://www.bilibili.com "title")
```


## 5. 插入图片

```md
![名称](链接 "title")	网页图片
```

```md
![名称][tupian1]	
[tupian1]:链接 "title"
```

```md
![](./tupian1)	本地图片-当前目录
![](tupian1)
![](zimulu/tupian2)	本地图片-子目录
```


## 6. 脚注

```md
待解释文本[^er]

[^er]:jieshi
```

github中脚注：

```md
Bla bla <sup id="a1">[1](#f1)

<b id="f1">1 Footnote content here.</b> [?](#a1)
```

## 7. 引用

```md
> 123
>> 1234
>>> 12345
```

## 8. 代码块

```md
`daimakuai`

```daimakuai```

```

#### 代码区块

```md
    daima   //4个空格或一个tab
```

## 9. 分割线

```md
*-_ 
***
---
___
```

## 10. 上下标

```md
H<sub>2</sub>O
CO<sub>2</sub>
爆米<sup>TM</sup>
```

H<sub>2</sub>O

CO<sub>2</sub>

爆米<sup>TM</sup>


## 11. 插入空格、Tab

```md
&nbsp;
&ensp;
&emsp;
```

## 12. 删除线

```md
~~ABCDEFG~~
```

~~ABCDEFG~~

## 13. 下划线

```md
<u>下划线</u>
```

<u>下划线</u>

## 14. 合并单元格

```html
<table>
    <tr>
        <th>班级</th><th>课程</th><th>平均分</th>
    </tr>
    <tr>
        <td rowspan="3">1班</td><td>语文</td><td>100</td>
    </tr>
    <tr>
        <td>数学</td><td>100</td>
    </tr>
    <tr>
        <td>英语</td><td>100</td>
    </tr>
</table>
```

## 14. 自定义锚点

* 1、建立一个跳转的连接

```md
[说明文字](#jump)
```

* 2、标记要跳转到什么位置

**注意id要与之前（#）中的内容相同**

```html
<span id = "jump">跳转位置</span>
```

应用: 文章中的任意跳转

* 文章头部:


    ```html
    <span id = "Jump1" ></span>

    <!-- <sup><p align="right">[`END↓`](#Jump2)</p></sup> -->
    <sup>[`END↓`](#Jump2)</sup>
    ```

    <span id = "Jump1" ></span>

    <sup>[`END↓`](#Jump2)</sup>

* 文章任意处:

    ```html
    <sup>[`TOP↑`](#Jump1)</sup>

    <sup><p align="right">[`END↓`](#Jump2)</p></sup>
    ```

    <sup>[`TOP↑`](#Jump1)</sup> <sup>[`END↓`](#Jump2)</sup>

* 文章末尾:

    ```html
    <span id = "Jump2" ></span>

    <sup>[`TOP↑`](#Jump1)</sup>
    ```


    <span id = "Jump2" ></span>

    <sup>[`TOP↑`](#Jump1)</sup>



## 15. 标题/目录

### 1、利用标题实现页内跳转

```
* [标题](#标题)
```

### 2、HTML实现页内跳转

```html
<a href="#id">NAME</a>
```

其中的"NAME"可以随便填写, "id"需要填写跳转到的标题的内容

### 3 Github目录

Github md不支持 `[TOC]`, 不过其二级标题可这样写:

```md
## H2-1 ##
## H2-2 ##
```

然后在页面顶部按照 "标题" 写法, 写了1~2条以后, `ctrl+s`保存, 此时会自动生成所有标题组成的目录.


## 16. 颜色与字体

*  设置居中及右对齐

    对于标准的markdown文本, 是不支持居中对齐的。还好markdown支持html语言, 所以我们采用html语法格式即可。（有些markdown编辑器不支持）

    ```markdown
    <center>这一行需要居中</center>
    <div align = center>这一行需要居中</div>
    <div align = left>这一行需要靠左</div>
    <div align = right>这一行需要靠右</div>
    ```

    ```markdown
    <p align="right">右对齐</p>
    <p align="left">左对齐</p>
    ```

    <p align="right">右对齐</p>

    <p align="left">左对齐</p>


* 更换字体

    ```markdown
    <font face="黑体">我是黑体字</font>
    ```

    测试: 

    <font face="黑体">我是黑体字</font>

* 调整字体大小

    ```markdown
    <font face="黑体" size=10>我是黑体字</font>
    ```

    测试: 

    <font face="黑体" size=10>我是黑体字</font>

* 调整字体颜色

    ```markdown
    <font color=red size=2>注意！！！</font>
    <font color=orange size=4>注意！！！</font>
    <font color=#0000FF size=6>注意！！！</font>
    <font color=#FF00FF size=8>注意！！！</font>
    ```

    测试: 

    <font color=red size=2>注意！！！</font>

    <font color=orange size=4>注意！！！</font>

    <font color=#0000FF size=6>注意！！！</font>

    <font color=#FF00FF size=8>注意！！！</font>

## 17. 脚注

```md
<sup id="a1">[1](#f1)

<b id="f1">1 脚注内容 [?](#a1)
```

测试:

脚注1<sup id="a1">[1](#f1)</sup>, 脚注2<sup id="a2">[2](#f2)</sup>

---

<b id="f1">1 脚注内容 [?](#a1)

<b id="f2">2 脚注内容 [?](#a2)

<-!>

## 其他

* 注释

    ```markdown
    <!--注释-->
    ```

* 插入带空格路径

    ```markdown
    [aaa](<path to markdown file.md>)
    ```