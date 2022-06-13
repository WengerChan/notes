# Python

## 使用解释器

启动: 终端中输入 python 来启动, 进入交互式命令行界面

退出: `quit()`

一次性的调用 python 解释器: `python -c command [arg] ...`

修改默认编码: 在第一行中定义

```py
# -*- coding: utf8 -*-
```

当在 Unix 类系统中使用时, 如果第一行要定义 Shebang, 那么编码可在第二行定义

```py
#!/usr/bin/env python3
# -*- coding: utf_8 -*-
```

Python 和 C 一样，任何非零整数都为真；零为假。这个条件也可以是字符串或是列表的值，事实上任何序列都可以；长度非零就为真，空序列就为假

标准的比较操作符的写法和 C 语言里是一样： < （小于）、 > （大于）、 == （等于）、 <= （小于或等于)、 >= （大于或等于）以及 != （不等于）


## 流程控制工具

* while

* if

* for

* range() 函数

    ```py
    range(Begin,End,step)
    ```

* break, continue, pass

* 函数

    ```py
    def fib(n):
        """Print a Fibonacci series up to n."""
        a, b = 0, 1
        while a < n:
            print(a, end=' ')
            a, b = b, a+b
        print()
    ```

    第一个语句可以（可选的）是字符串文字, 这个字符串文字是函数的文档字符串或称为 docstring


* return


PEP8 代码规范


## 快捷键

| 类型 | 快捷键 | 
| -- | -- |
| 移动当前行 | `⇧ ⌘ ↑` / `⇧ ⌘ ↓` |
| 复制当前选中/当前行 | `⌘ D` |
| 查看定义 | `⌥ Space` |
| 删除整行 | `⌘ X` |
| 删除到行首 | `⌘ 删除键` |
