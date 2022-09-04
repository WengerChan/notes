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

* 位置形参和关键字参数

    ```py
    # / 之前的参数只允许使用位置形参形式传参
    # * 之后的参数只允许使用关键字参数形式传参
    def f(pos1, pos2, /, pos_or_kwd, *, kwd1, kwd2):
        pass
    ```

* 任意的形参列表

    * `*args` 元组
    * `**args`  字典

* 解包参数列表

* Lambda 表达式

    ```py
    lambda a, b: a+b
    ```

* 文档字符串

    第一行应该是对象目的的简要概述。为简洁起见，它不应显式声明对象的名称或类型，因为这些可通过其他方式获得（除非名称恰好是描述函数操作的动词）。这一行应以大写字母开头，以句点结尾。

    如果文档字符串中有更多行，则第二行应为空白，从而在视觉上将摘要与其余描述分开。后面几行应该是一个或多个段落，描述对象的调用约定，它的副作用等。

    ```py
    >>> def my_function():
    ...     """Do nothing, but document it.
    ...
    ...     No, really, it doesn't do anything.
    ...     """
    ...     pass
    ...
    >>> print(my_function.__doc__)
    Do nothing, but document it.

        No, really, it doesn't do anything.
    ```

* 函数标注

    函数标注是关于用户自定义函数中使用的类型的完全可选元数据信息, 以字典的形式存放在函数的 `__annotations__` 属性中，并且不会影响函数的任何其他部分

* PEP8 代码规范

* 循环技巧

    ```py
    # 使用字典 items, keys, values
    knights = {'gallahad': 'the pure', 'robin': 'the brave'}
    for k, v in knights.items():
        print(k, v)

    # 使用 enumerate
    for i, v in enumerate(['tic', 'tac', 'toe']):
        print(i, v)
    
    # 使用 zip()
    questions = ['name', 'quest', 'favorite color']
    answers = ['lancelot', 'the holy grail', 'blue']
    for q, a in zip(questions, answers):
        print('What is your {0}?  It is {1}.'.format(q, a))
    
    # 逆向序列
    for i in reversed(range(1, 10, 2)):
        print(i)

    # 排序
    basket = ['apple', 'orange', 'apple', 'pear', 'orange', 'banana']
    for f in sorted(set(basket)):
        print(f)
    ```

## 数据结构


* `list.append(x)`
    在列表的末尾添加一个元素。相当于 `a[len(a):] = [x]` 。

* `list.extend(iterable)`
    使用可迭代对象中的所有元素来扩展列表。相当于 `a[len(a):] = iterable` 。

* `list.insert(i, x)`
    在给定的位置插入一个元素。第一个参数是要插入的元素的索引，所以 `a.insert(0, x)` 插入列表头部， `a.insert(len(a), x)` 等同于 `a.append(x)` 。

* `list.remove(x)`
    移除列表中第一个值为 x 的元素。如果没有这样的元素，则抛出 ValueError 异常。

* `list.pop([i])`
    删除列表中给定位置的元素并返回它。如果没有给定位置，`a.pop()` 将会删除并返回列表中的最后一个元素。（ 方法签名中 i 两边的方括号表示这个参数是可选的，而不是要你输入方括号。你会在 Python 参考库中经常看到这种表示方法)。

* `list.clear()`
    移除列表中的所有元素。等价于`del a[:]`

* `list.index(x[, start[, end]])`
    返回列表中第一个值为 x 的元素的从零开始的索引。如果没有这样的元素将会抛出 ValueError 异常。

    可选参数 start 和 end 是切片符号，用于将搜索限制为列表的特定子序列。返回的索引是相对于整个序列的开始计算的，而不是 start 参数。

* `list.count(x)`
返回元素 x 在列表中出现的次数。

* `list.sort(*, key=None, reverse=False)`
    对列表中的元素进行排序（参数可用于自定义排序，解释请参见 `sorted()`）。

* `list.reverse()`
    翻转列表中的元素。

* `list.copy()`
    返回列表的一个浅拷贝，等价于 `a[:]`。

* del

    ```py
    a = [1, 2]
    del a(1)
    del a
    del a[:]
    ```

* 列表堆栈

    `list.append()`, `list.pop()`

* 列表队列

    `collections.deque`, `deque.append()`, `deque.popleft()`,

* 列表推导式

    ```py
    square1 = []
    for x in range(10):
        square1.append(x**2)

    square2 = list(map(lambda x: x**2, range(10)))

    square3 = [x**2 for x in range(10)]

    [(x, y) for x in [1,2,3] for y in [3,1,4] if x != y]

    # 列表推导式交换矩阵的行和列（转置）
    matrix = [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
    ]
    
    [[row[i] for row in matrix] for i in range(4)]
    
    list(zip(*matrix))
    ```

* 元组打包

    ```py
    x = 'a', 'b', 'c'
    ```

* 序列解包

    ```py
    a = [1, 2]
    x, y = a
    ```

* 集合推导式

    ```py
    {x for x in 'abracadabra' if x not in 'abc'}
    ```

* 字典

    ```py
    tel = {'jack': 4098, 'sape': 4139}

    dict([('sape', 4139), ('guido', 4127), ('jack', 4098)])

    dict(sape=4139, guido=4127, jack=4098)

    # 字典推导式
    {x: x**2 for x in (2, 4, 6)}

    dict.keys()
    dict.values()
    dict.items()
    ```

* 比较序列

    这种比较使用 字典式 顺序：
    * 首先比较开头的两个对应元素，如果两者不相等则比较结果就由此确定；如果两者相等则比较之后的两个元素，以此类推，直到有一个序列被耗尽。 
    * 如果要比较的两个元素本身又是相同类型的序列，则会递归地执行字典式顺序比较。 
    * 如果两个序列中所有的对应元素都相等，则两个序列也将被视为相等。 
    * 如果一个序列是另一个的初始子序列，则较短的序列就被视为较小（较少）。 
    * 对于字符串来说，字典式顺序是使用 Unicode 码位序号对单个字符排序。 

## 快捷键

| 类型 | 快捷键 | 
| -- | -- |
| 移动当前行 | `⇧ ⌘ ↑` / `⇧ ⌘ ↓` |
| 复制当前选中/当前行 | `⌘ D` |
| 查看定义 | `⌥ Space` |
| 删除整行 | `⌘ X` |
| 删除到行首 | `⌘ 删除键` |
