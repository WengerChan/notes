# shell, bash

CentOS7.6 - 4.2.46
Ubuntu20.04 - 5.0.17




## Variables


| 变量名 | 解释 |
| -- | -- |
| `$_` | 上一条命令的最后一个参数 |
| `$BASH` | 当前bash的绝对路径, 类似的 $SHELL |
| `$BASHPID` | 当前bash的PID |
| `$BASH_COMMAND` | 当前或即将执行的命令 |
| `$BASH_EXECUTION_STRING` | 用来存放`bash -c`选项传递过来的命令 |
| `$BASH_SOURCE` | 数组, 记录执行函数的源文件名 |
| `$BASH_FUNCNAME` | 数组, 记录执行函数的函数名 |
| `$BASH_LINENO` | 数组, 记录函数调用的行号 |
| `$LINENO` | 记录当前行号 |
| `$BASH_SUBSHELL` | 子shell编号, 从0开始 |
| `$BASH_VERSINFO` | 数组, bash版本信息 |
| `$BASH_VERSION` | 数组, bash版本信息 |

* 关于 `$BASH_SOURCE`, `$BASH_LINENO`, `$BASH_FUNCNAME`

    * 示例1

        ```sh
        #!/bin/bash                                   # <-  1: 
        a(){                                          # <-  2: 
        echo "a"                                      # <-  3: 
        echo "\$FUNCNAME --> ${FUNCNAME[*]}"          # <-  4: a main
        echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" # <-  5: filename.sh filename.sh
        echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" # <-  6: 21 0
        b                                             # <-  7: 调用 b 函数
        }                                             # <-  8: 
                                                    # <-  9: 
        b(){                                          # <- 10: 
        echo "b"                                      # <- 11: 
        echo "\$FUNCNAME --> ${FUNCNAME[*]}"          # <- 12: b a main
        echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" # <- 13: filename.sh filename.sh filename.sh
        echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" # <- 14: 7 21 0
        }                                             # <- 15: 
                                                    # <- 16: 
        echo "Begin"                                  # <- 17: 
        echo "\$FUNCNAME --> ${FUNCNAME[*]}"          # <- 18: main (bash认为这里是main函数, 此main与自定义的main函数不同)
        echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" # <- 19: filename.sh
        echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" # <- 20: 0 (表示脚本执行开始就调用)
        a                                             # <- 21: 调用 a 函数
        echo "END"                                    # <- 22: 
        echo "\$FUNCNAME --> ${FUNCNAME[*]}"          # <- 23: main
        echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" # <- 24: filename.sh
        echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" # <- 25: 0
        ```

        执行结果:

        ```text
        Begin
        $FUNCNAME --> main
        $BASH_SOURCE[*] --> filename.sh
        $BASH_LINENO[*] --> 0
        a
        $FUNCNAME --> a main
        $BASH_SOURCE[*] --> filename.sh filename.sh
        $BASH_LINENO[*] --> 21 0
        b
        $FUNCNAME --> b a main
        $BASH_SOURCE[*] --> filename.sh filename.sh filename.sh
        $BASH_LINENO[*] --> 7 21 0
        END
        $FUNCNAME --> main
        $BASH_SOURCE[*] --> filename.sh
        $BASH_LINENO[*] --> 0
        ```

    * 示例2: 脚本中有调用其他文件中的函数

        * `a.sh`

            ```sh
            #!/bin/bash                                   #  1: 
            a(){                                          #  2: 
            echo "a"                                      #  3: 
            echo "\$FUNCNAME --> ${FUNCNAME[*]}"          #  4: a main
            echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" #  5: a.sh a.sh
            echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" #  6: 15 0
            source ./b.sh                                 #  7: 
            b                                             #  8: 调用b函数
            }                                             #  9: 
                                                        # 10: 
            echo "Begin"                                  # 11: 
            echo "\$FUNCNAME --> ${FUNCNAME[*]}"          # 12: main
            echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" # 13: a.sh
            echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" # 14: 0
            a                                             # 15: 调用a函数
            echo "END"                                    # 16: 
            echo "\$FUNCNAME --> ${FUNCNAME[*]}"          # 17: 
            echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" # 18: 
            echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" # 19: 
            ```

        * `b.sh`

            ```sh
            #!/bin/bash
            b(){                                          #  1: 
            echo "b"                                      #  2: 
            echo "\$FUNCNAME --> ${FUNCNAME[*]}"          #  3: b a main
            echo "\$BASH_SOURCE[*] --> ${BASH_SOURCE[*]}" #  4: ./b.sh a.sh a.sh
            echo "\$BASH_LINENO[*] --> ${BASH_LINENO[*]}" #  5: 8 15 0  (此处的8为a.sh脚本中的第8行)
            }                                             #  6: 
            ```

        执行结果

        ```text
        Begin
        $FUNCNAME --> main
        $BASH_SOURCE[*] --> a.sh
        $BASH_LINENO[*] --> 0
        a
        $FUNCNAME --> a main
        $BASH_SOURCE[*] --> a.sh a.sh
        $BASH_LINENO[*] --> 15 0
        b
        $FUNCNAME --> b a main
        $BASH_SOURCE[*] --> ./b.sh a.sh a.sh
        $BASH_LINENO[*] --> 8 15 0
        END
        $FUNCNAME --> main
        $BASH_SOURCE[*] --> a.sh
        $BASH_LINENO[*] --> 0
        ```

* 关于 `$BASH_SUBSHELL`

    Incremented by one within each subshell or subshell environment when the shell begins executing in that environment. The initial value is 0. If BASH_SUBSHELL is unset, it loses its special properties, even if it is subsequently reset.

    真正的子 Shell 可以访问其父 Shell 的任何变量, 而通过再执行一次 bash 命令所启动的 Shell 只能访问其父 Shell 传来的环境变量。

    ```sh
    ~] echo $BASH_SUBSHELL

    0

    ~] (echo $BASH_SUBSHELL)

    1

    ~] ( (echo $BASH_SUBSHELL) )
    2
    ```

    ```sh
    ~] unset a; a=1

    ~] (echo "a is $a in the subshell")

    a is 1 in the subshell

    ~] sh -c 'echo "a is $a in the child shell"'

    a is  in the child shell
    ```

* 关于 `$BASH_VERSINFO`, `$BASH_VERSION`


    ```sh
    $ echo ${BASH_VERSINFO[*]}
    4 3 48 1 release x86_64-suse-linux-gnu

    $ echo $BASH_VERSION
    4.3.48(1)-release
    ```


## 通配符及特殊符号

### 通配符, globbing

适用范围：命令行的普通命令或脚本编程中

* 模糊匹配

    - `*` : 任意个任意字符
    - `?` : 任意单个字符 
    - `[ ]` ：匹配单个指定范围内的字符`[abc]`, `[a-z]`, `[A-Z]`, `[a-zA-Z]`
    - `[^ ]` 或`[!]` : 取不在指定范围内的字符

* 路径匹配

    - `.` : 当前目录
    - `..` : 上级目录
    - `-` : 上一次所在的目录
    - `~` : 用户家目录

* 特殊指代

    - `[:space:]`
    - `[:punct:]`
    - `[:lower:]`
    - `[:upper:]`
    - `[:alpha:]`
    - `[:digit:]`
    - `[:alnum:]`


### 引号相关

- 单引号引用字符串, 所见即所得  
- 双引号引用字符串, 解析变量、命令  
- 反引号引用命令, 等价于`$()`

### 其他字符

- `;` 命令分隔符  
- `#` 
    * 1> root用户提示符  
    * 2> 注释  
- `'$'`  
    * 1> 普通用户提示符  
    * 2> 调用变量使用  
- `|` 管道符
- `\ ` 转义字符
- `{ }` 
    * 1> 展开, 用于生成序列  
    * 2> 引用变量 `${PATH}`
- `&&`, `||` 逻辑判断


## 参数扩展

### 基本参数扩展

`${parameter}`

### 间接参数扩展

`${!parameter}`, 其中引用的参数并不是 `parameter`, 而是 `parameter` 的实际值

示例:

```sh
shell> parameter="var"
shell> var="helloworld"
shell> echo ${!parameter}
helloworld
```

```sh
${parameter:-word}
              Use Default Values.  If parameter is unset or null, the expansion of word is substituted.  Otherwise, the value of parameter is substituted.
${parameter:=word}
              Assign Default Values.  If parameter is unset or null, the expansion of word is assigned to parameter.  The value of parameter is then substituted.  Positional parameters  and  special parameters may not be assigned to in this way.
${parameter:?word}
              Display  Error  if  Null  or  Unset.  If parameter is null or unset, the expansion of word (or a message to that effect if word is not present) is written to the standard error and the shell, if it is not interactive, exits.  Otherwise, the value of parameter is substituted.
${parameter:+word}
              Use Alternate Value.  If parameter is null or unset, nothing is substituted, otherwise the expansion of word is substituted.
```

### 参数大小写修改

| 写法  | 作用 | 作用范围 |
| --   | -- | :-- |
| `${A^}`   | `小写 -> 大写`  | 第一个小写字母 |
| `${A^^}`  | `小写 -> 大写`  | 所有小写字母 |
| `${A,}`   | `大写 -> 小写`  | 第一个大写字母 |
| `${A,,}`  | `大写 -> 小写`  | 所有大写字母 |
| `${A~}`   | `大小写互换` | 第一个字母 |
| `${A~~}`  | `大小写互换` | 全部字母 |

所有的大小写修改操作，均可以使用 pattern 来对指定的字符进行大小写转换：

```sh
~] string=aaabbbccc
~] echo ${string^^a}
AAAbbbccc
~] echo ${string^^[bc]}
aaaBBBCCC
```

### 空参数处理

- `${A:-B}`, `${A-B}`
- `${A:+B}`, `${A+B}`
- `${A:=B}`, `${A=B}`
- `${A:?}`, `${A?}`


| 参数扩展 | unset A | A='' | A="Value" |
| ---------- | ------ | ------ | ------ |
| `${A:+B}`  | `''`   | `''`   | `${B}` |
| `${A+B}`   | `''`   | `${B}` | `${B}` |
| `${A:-B}`  | `${B}` | `${B}` | `${A}` |
| `${A-B}`   | `${B}` | `''`   | `${A}` |
| `${A:=B}`  | `${B}` | `${B}` | `${A}` |
| `${A=B}`   | `${B}` | `''`   | `${A}` |
| `${A:?}`   | Error  | Error  | `${A}` |
| `${A?}`    | Error  |  `''`  | `${A}` |

注: `${A:=B}` 和 `${A=B}` 使用 `${B}` 值时, 实际是执行了 `A=${B}`, 即将 B 的值赋给 A


* 示例: `${parameter:-word}` 和 `${parameter-word}`

    ```sh
    # 1. 定义两个变量para01,para02, para03不定义
    shell> para01=""
    shell> para02="something"
    shell> set | grep para
    para01=
    para02=something

    # 2. para01定义为空, 此时${para01:-otherthing}输出otherthing, para01的值未被修改
    shell> echo ${para01:-otherthing}
    otherthing
    shell> echo ${para01}
                # <= 为空

    # 3. para02定义为something, 此时${para02:-otherthing}输出something, para02的值未被修改
    shell> echo ${para02:-otherthing}
    something
    shell> echo ${para02}
    something

    # 3. para03未定义, 此时${para03:-otherthing}输出otherthing, para03的值未被修改, 同时也没有变量para03
    shell> echo ${para03:-otherthing}
    otherthing
    shell> echo ${para03}
                # <= 为空
    shell> set | grep para
    para01=
    para02=something
    ```

    观察 `${parameter-word}`, `para01` 和 `para02` 都没有输出otherthing, 说明使用的是本身的值

    ```sh
    shell> set | grep para
    para01=
    para02=something
    shell> echo ${para01-otherthing}

    shell> echo ${para01}

    shell> echo ${para02-otherthing}
    something
    shell> echo ${para02}
    something
    shell> echo ${para03-otherthing}
    otherthing
    shell> echo ${para03}

    shell> set | grep para
    para01=
    para02=something
    ```

    总结-1: 

    - 当 **变量未定义** 或者 **变量定义为空** 时, `${parameter:-word}` 会临时使用 `word` 作为变量解析结果 
    - 当 **变量定义不为空** 时, `${parameter:-word}` 会取 `parameter` 的值作为解析结果
    - `${parameter-word}`只会检查**变量是否定义**, 无论定义为何值: **变量已定义**=> `${parameter-word}`取 `parameter` 的值作为变量解析结果; 相反, 取 `word` .
    - 两种写法均不会对 `parameter` 做任何操作


* `${parameter:+word}` 和 `${parameter+word}`

    ```sh
    shell> set | grep para
    para01=
    para02=something

    # 1. ${parameter:+word} 相关验证结果
    shell> echo ${para01:+otherthing}
                # <= 为空
    shell> echo ${para01}
                # <= 为空
    shell> echo ${para02:+otherthing}
    otherthing
    shell> echo ${para02}
    something
    shell> echo ${para03:+otherthing}
                # <= 为空
    shell> echo ${para03}
                # <= 为空
    shell> set | grep para
    para01=
    para02=something

    # 2. ${parameter+word} 相关验证结果
    shell> echo ${para01+otherthing}
    otherthing
    shell> echo ${para01}
                # <= 为空
    shell> echo ${para02+otherthing}
    otherthing
    shell> echo ${para02}
    something
    shell> echo ${para03+otherthing}
                # <= 为空
    shell> echo ${para03}
                # <= 为空
    shell> set | grep para
    para01=
    para02=something
    ```

    总结-2: 

    - 当 **变量未定义** 或者 **变量定义为空** 时, `${parameter:+word}` 会使用 `parameter` 的值作为变量解析结果 
    - 当 **变量定义不为空** 时, `${parameter:+word}` 会临时使用 `word` 作为解析结果
    - `${parameter+word}`只会检查**变量是否定义**, 无论定义为何值: **变量已定义** => `${parameter+word}`取 `word` 作为变量解析结果; 相反, 取 `parameter` 的值.
    - 两种写法均不会对 `parameter` 做任何操作

* `${parameter:=word}` 和 `${parameter=word}`

    ```sh
    shell> set | grep para
    para01=
    para02=something

    # 1. ${parameter:=word} 相关验证结果
    shell> echo ${para01:=otherthing}
    otherthing
    shell> echo ${para01}
    otherthing
    shell> echo ${para02:=otherthing}
    something
    shell> echo ${para02}
    something
    shell> echo ${para03:=otherthing}
    otherthing
    shell> echo ${para03}
    otherthing
    shell> set | grep para
    para01=otherthing
    para02=something
    para03=otherthing

    # 2. ${parameter=word} 相关验证结果
    shell> set | grep para
    para01=
    para02=something
    shell> echo ${para01=otherthing}
                # <= 为空
    shell> echo ${para01}
                # <= 为空
    shell> echo ${para02=otherthing}
    something
    shell> echo ${para02}
    something
    shell> echo ${para03=otherthing}
    otherthing
    shell> echo ${para03}
    otherthing
    shell> set | grep para
    para01=
    para02=something
    para03=otherthing
    ```

    总结-3: 

    - 当 **变量未定义** 或者 **变量定义为空** 时, `${parameter:=word}` 会使用 `word` 作为变量解析结果,
    - 当 **变量定义不为空** 时, `${parameter:=word}` 会使用 `parameter` 的值作为解析结果
    - `${parameter=word}`只会检查**变量是否定义**, 无论定义为何值: **变量已定义**=> `${parameter=word}`取 `parameter` 作为变量解析结果; 相反, 取 `word` 的值.
    - 以上两种写法, 只要取了 `word` 的值, 那么 `parameter` 值会被同步的修改为 `word`; `parameter` 未定义时, 会将其定义.

* `${parameter:?word}` 和 `${parameter?word}`

    ```sh
    shell> set | grep para
    para01=
    para02=something
    shell> echo ${para01:?otherthing}
    -bash: para01: otherthing
    shell> echo ${para02:?otherthing}
    something
    shell> echo ${para03:?otherthing}
    -bash: para03: otherthing
    shell> echo ${para01?otherthing}
            # <= 为空
    shell> echo ${para02?otherthing}
    something
    shell> echo ${para03?otherthing}
    -bash: para03: otherthing
    shell> set | grep para
    para01=
    para02=something
    ```

    总结-4: 

    - 当 **变量未定义** 或者 **变量定义为空** 时, `${parameter:?word}` 会抛出异常 `-bash: parameter: word`,
    - 当 **变量定义不为空** 时, `${parameter:?word}` 会使用 `parameter` 的值作为解析结果
    - `${parameter?word}`只会检查**变量是否定义**, 无论定义为何值: **变量已定义**=> `${parameter=word}`取 `parameter` 作为变量解析结果; 相反, 取 `word` 的值.
    - 两种写法均不会对 `parameter` 做任何操作

### 变量切片

```sh
${parameter:start}
${parameter:start:length}
# start: 起始点
# length: 字符长度/结束点位置
```

* 起始位置为 `0`，最后一个字符为 `-1`

    ```sh
            0  1  2  3  4  5  6  7  8  9
    No →:   0  1  2  3  4  5  6  7  8  9
    No ←: -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
    ```

* 不指定 `length` 时，表示截取到字符串结尾；当 `length>0` 时，表示 "字符长度"；当 `length<0` 时，表示 "结束点位置"，此时 `length` 指定位置的值不会被截取

    ```sh
    ~] string=0123456789

    # 省略 length
    ~] echo ${string: 1}
    123456789
    ~] echo ${string: -5}
    56789

    # length>0
    ~] echo ${string: 1: 2}
    12
    ~] echo ${string: -4: 2}
    67

    # length<0, 此时 -1 对应的字符 9 未被截取
    ~] echo ${string: 1: -1}
    12345678
    ~] echo ${string: -4: -1}
    678
    ```

* 当 `start` 为负数时，主要要和 : 保留一个空格，否则会被解释器错误解释

    ```sh
    ~] echo ${string: -6: 2}
    45

    ~] echo ${string:-6: 2}
    0123456789
    ```

* 如果 `start` 为 `@`（作为参数），此时起始值为 1，且 `length` 不能为负数

    ```sh
            0  1  2  3  4  5  6  7  8  9
    No →:   1  2  3  4  5  6  7  8  9  10
    No ←: -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
    ```

    ```sh
    ~] set -- 0 1 2 3 4 5 6 7 8 9
    
    ~] echo ${@:0}
    -bash 0 1 2 3 4 5 6 7 8 9
    ~] echo ${@:1}
    0 1 2 3 4 5 6 7 8 9
    ~] echo ${@:7}
    6 7 8 9
    ~] echo ${@: -3: 2}
    7 8
    ~] echo ${@: -3: -1}
    -bash:  -1: substring expression < 0
    ```

* 如果 `start` 为下标是 `@` 或者 `*` 的数组，此时表达式含义为 `array[start]` 后的 `length` 个值，`length` 不能为负数

    ```sh
    ~] array=(0 1 2 3 4 5 6 7 8 9)

    ~] echo ${array[*]}
    0 1 2 3 4 5 6 7 8 9
    ~] echo ${array[*]:7}
    7 8 9
    ~] echo ${array[*]:7:2}
    7 8
    ~] echo ${array[*]:7: -2}
    -bash:  -2: substring expression < 0
    ```


### 参数查找

```sh
${!prefix*}
${!prefix@}

"${!prefix*}"
"${!prefix@}"
```

shell 将其展为所有以 `prefix` 开头为的变量名：

* 当被双引号包裹时 `@` 会扩展成独立的几个变量名，而 `*` 则会扩展成变量组合而成的字符串
* 当没有被双引号包裹时 `@`，`*` 都会扩展成独立的几个变量

示例：

```sh
~] var1=111
~] var2=222

# 没有双引号包裹
~] for v in ${!var@}; do echo $v; done;
var1
var2
~] for v in ${!var@}; do echo ${!v}; done;
111
222

~] for v in ${!var*}; do echo ${!v}; done;
111
222
~] for v in ${!var*}; do echo $v; done;
var1
var2

# 有双引号包裹
~] for v in "${!var@}"; do echo $v; done;
var1
var2
~] for v in "${!var@}"; do echo ${!v}; done;
111
222

~] for v in "${!var*}"; do echo $v; done;
var1 var2
~] for v in "${!var*}"; do echo ${!v}; done;  # 此时展开成一个变量 "var1 var2"
-bash: var1 var2: invalid variable name
```


### 删除、替换

* 删除

    ```sh
    ${param#str}   # param 从头开始匹配 str 并删除（尽可能少的匹配）
    ${param##str}  # param 从头开始匹配 str 并删除（尽可能多的匹配）
    
    ${param%str}   # param 从尾开始匹配 str 并删除（尽可能少的匹配）
    ${param%%str}  # param 从尾开始匹配 str 并删除（尽可能多的匹配）
    ```

    通配字符：

    * `*`: 任意个任意字符
    * `?`: 任意一个任意字符
    * `[]`: `[ab]` 表示匹配 a 或者 b，`[^ab]` 表示除 a、b 以外的其他字符

* 替换

    ```sh
    ${parame/pattern/str}  # 将从左到右、第一个出现的 pattern 替换成 str
    ```

    pattern 可以以以下特殊字符开头，表达不同需求：

    * `/`: 不仅仅替换第一个 pattern，而是替换所有
    * `#`: 必须是开头
    * `%`: 必须是结尾




~]

```sh
```
```sh
```

## 脚本参数接收

* Demo 1:

    ```sh
    #! /bin/bash

    while getopts "t:a:u:h" opt
    do
    case "$opt" in
        t ) TOKEN="$OPTARG" ;;
        a ) ACCOUNT_TYPE="$OPTARG" ;;
        u ) ACCOUNT_NAME="$OPTARG" ;;
        h ) help ;;
        ? ) help ;;
    esac
    done
    ```

* Demo 2:

    ```sh
    #! /bin/bash

    usage() {

    cat <<EOF

    rh_iso_extract.sh [ options ]

    Valid options are:
        -h | --help    This help
        -a | --arch    The architecture to work with [ default i386 ]
        -d | --dest-dir    The destination dir prefix    [ default /var/ftp ]
        -i | --iso-dir    The source iso dir prefix     [ default /var/ftp ]
        -r | --release  The release name              [ default beta/null ]

    If you cannot loop mount a file on an NFS filesystem,
    e.g. 2.2.x kernel based systems, you should copy your
    iso images to a local directory and override the iso-dir
    and dest-dir defaults.

    e.g.
    # mkdir -p /mnt/scratch/ftp/pub/redhat/linux/RELEASE/en/iso/i386/

    # cp /var/ftp/pub/redhat/linux/RELEASE/en/iso/i386/*.iso \\
                /mnt/scratch/ftp/pub/redhat/linux/RELEASE/en/iso/i386/

    # rh_iso_extract.sh -i /mnt/scratch/ftp/pub -d /var/ftp/pub

    EOF
    exit 1
    }

    TEMP=`getopt -o ha:d:i:r: --long help,arch:,dest-dir:,iso-dir:,release: -n 'rh_iso_extract.sh' -- "$@"`

    eval set -- "$TEMP"

    while true ; do
        case "$1" in 
            -h|--help) usage ;;
            -a|--arch)
                ARCH=$2
                shift 2
                ;;
            -d|--dest-dir) 
                DESTPREFIX=$2
                shift 2
                ;;
            -i|--iso-dir) 
                ISOPREFIX=$2
                shift 2
                ;;
            -r|--release) 
                RELEASE=$2
                shift 2
                ;;
            --) shift ; break;;
            *) echo "Internal error!" ; exit 1;;
        esac
    done
    ```


## 随机睡眠


```sh
function random_sleep() {
    low=10
    up=30
    max=$(($up-$low+1))
    num=$(($RANDOM+1000000000))
    sleep_time=$(($num%$max+$low))
    echo "sleep_time=$sleep_time"
    sleep $sleep_time
}
```

* `$RANDOM` 取值范围`0-32767`

* 如果要取 0-9 的值, 可以用 `$(($RANDOM*10/32767))`

* 如果要取 10-100 的值, 可以用 `$(($RANDOM*100/32767))`


## 临时文件处理规范

### 创建临时文件

```sh
~] mktemp
/tmp/tmp.1IekR8km9h

~] mktemp /tmp/XXXX    # 每位 X 都会被替换成随机字符
/tmp/VP7z

```

### 创建临时目录

* 推荐做法1：用 `mktemp` 创建只有脚本作者能访问的临时目录

    ```sh
    function func()
    {
        : ${TMPDIR:=/tmp}
        local temp_dir=""
        local save_mask=$(umask)
        umask 077
        temp_dir=$(mktemp -d "${TMPDIR}/XXXXXXXXXXXXXXXXXX")   # 每位 X 都会被替换成随机字符
        if [ $? -ne 0 ]
        then
            # 出错处理
            umask "${save_mask}"
            return 1
        fi
        umask "${save_mask}"

        # 业务逻辑
    }
    ```

* 推荐做法2：如果不支持命令 `mktemp` , 则用 `mkdir` 搭配 `${RANDOM}` 和 `$$` 创建只有脚本作者能访问的临时目录

    ```sh
    function func()
    {
        local temp_dir="/tmp/tmp_${RANDOM}_$$"
        mkdir -m 700 "${temp_dir}"
        if [ $? -ne 0 ]
        then
            #出错处理"
            return 1
        fi

        #业务逻辑
    }
    ```

### 删除临时目录

* 推荐做法：使用 `mktemp` 创建只有脚本作者能访问的临时目录, 并用 `trap` 命令在脚本退出时删除整个临时目录

    ```sh
    #!/bin/bash
    
    : ${TMPDIR:=/tmp}
    trap '[ -n "${temp_dir}" ] && rm -rf "${temp_dir}"' EXIT
    
    save_mask=$(umask)
    umask 077
    temp_dir=$(mktemp -d "${TMPDIR}/XXXXXXXXXXXXXXXXXX") 
    if [ $? -ne 0 ]
    then
        #出错处理
        umask "${save_mask}"
        exit 1
    fi    
    umask "${save_mask}"

    #业务逻辑
    ```

### 关于 `trap`

* 命令格式

    1. 当脚本收到 `signal-list` 清单内列出的信号时, `trap` 命令执行 `commands` 操作

        ```sh
        trap "commands" signal-list
        ```

    2. 将 `commands` 指定为 `-`, 表示接受信号的默认操作

        ```sh
        trap - signal-list
        ```

    3. 将 `commands` 指定为 `""`, 表示允许忽视此信号

        ```sh
        trap "" signal-list
        trap " " signal-list  # 类似于不执行
        trap ":" signal-list  # 类似于不执行
        ```

* 扩展 1: 操作系统信号

    如常见的 `Ctrl+C` 组合键会产生 `SIGINT` 信号, `Ctrl+Z` 会产生 `SIGTSTP` 信号。

    |名称|默认动作|说明|
    | -- | -- | -- |
    |`SIGHUP`|终止进程|终端线路挂断|
    |`SIGINT`|终止进程|中断进程|
    |`SIGQUIT`|建立CORE文件|终止进程, 并且生成core文件|
    |`SIGILL`|建立CORE文件|非法指令|
    |`SIGTRAP`|建立CORE文件|跟踪自陷|
    |`SIGBUS`|建立CORE文件|总线错误|
    |`SIGSEGV`|建立CORE文件|段非法错误|
    |`SIGFPE`|建立CORE文件|浮点异常|
    |`SIGIOT`|建立CORE文件|执行I/O自陷|
    |`SIGKILL`|终止进程|杀死进程|
    |`SIGPIPE`|终止进程|向一个没有读进程的管道写数据|
    |`SIGALARM`|终止进程|计时器到时|
    |`SIGTERM`|终止进程|软件终止信号|
    |`SIGSTOP`|停止进程|非终端来的停止信号|
    |`SIGTSTP`|停止进程|终端来的停止信号|
    |`SIGCONT`|忽略信号|继续执行一个停止的进程|
    |`SIGURG`|忽略信号|I/O紧急信号|
    |`SIGIO`|忽略信号|描述符上可以进行I/O|
    |`SIGCHLD`|忽略信号|当子进程停止或退出时通知父进程|
    |`SIGTTOU`|停止进程|后台进程写终端|
    |`SIGTTIN`|停止进程|后台进程读终端|
    |`SIGXGPU`|终止进程|CPU时限超时|
    |`SIGXFSZ`|终止进程|文件长度过长|
    |`SIGWINCH`|忽略信号|窗口大小发生变化|
    |`SIGPROF`|终止进程|统计分布图用计时器到时|
    |`SIGUSR1`|终止进程|用户定义信号1|
    |`SIGUSR2`|终止进程|用户定义信号2|
    |`SIGVTALRM`|终止进程|虚拟计时器到时|

    也可以用数字指定信号, 对应关系:

    | Signal Number | Signal Name |
    |       --      |    --       |
    | 0             | EXIT        |
    | 1             | SIGHUP      |
    | 2             | SIGINT      |
    | 3             | SIGQUIT     |
    | 6             | SIGABRT     |
    | 9             | SIGKILL     |
    | 14            | SIGALRM     |
    | 15            | SIGTERM     |


* 扩展 2: `kill` 命令支持的信号

    ```sh
    ~] trap -l  # == kill -l
     1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL       5) SIGTRAP
     6) SIGABRT      7) SIGBUS       8) SIGFPE       9) SIGKILL     10) SIGUSR1
    11) SIGSEGV     12) SIGUSR2     13) SIGPIPE     14) SIGALRM     15) SIGTERM
    16) SIGSTKFLT   17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
    21) SIGTTIN     22) SIGTTOU     23) SIGURG      24) SIGXCPU     25) SIGXFSZ
    26) SIGVTALRM   27) SIGPROF     28) SIGWINCH    29) SIGIO       30) SIGPWR
    31) SIGSYS      34) SIGRTMIN    35) SIGRTMIN+1  36) SIGRTMIN+2  37) SIGRTMIN+3
    38) SIGRTMIN+4  39) SIGRTMIN+5  40) SIGRTMIN+6  41) SIGRTMIN+7  42) SIGRTMIN+8
    43) SIGRTMIN+9  44) SIGRTMIN+10 45) SIGRTMIN+11 46) SIGRTMIN+12 47) SIGRTMIN+13
    48) SIGRTMIN+14 49) SIGRTMIN+15 50) SIGRTMAX-14 51) SIGRTMAX-13 52) SIGRTMAX-12
    53) SIGRTMAX-11 54) SIGRTMAX-10 55) SIGRTMAX-9  56) SIGRTMAX-8  57) SIGRTMAX-7
    58) SIGRTMAX-6  59) SIGRTMAX-5  60) SIGRTMAX-4  61) SIGRTMAX-3  62) SIGRTMAX-2
    63) SIGRTMAX-1  64) SIGRTMAX
    ```

* `trap` 示例

    * 示例 1: 捕获 `Ctrl-C`

        ```sh
        #!/bin/bash
        trap "echo 'Sorry! I have trapped Ctrl-C'" SIGINT

        echo This is a test script

        count=1
        while [ $count -le 10 ]
        do
        echo "Loop $count"
        sleep 1
        count=$[ $count + 1 ]
        done

        echo The end.
        ```

        运行结果：

        ```text
        This is a test script
        Loop 1
        Loop 2
        ^CSorry! I have trapped Ctrl-C
        Loop 3
        Loop 4
        ^CSorry! I have trapped Ctrl-C
        Loop 5
        Loop 6
        Loop 7
        Loop 8
        ^CSorry! I have trapped Ctrl-C
        Loop 9
        Loop 10
        The end.
        ```

    * 示例 2: 捕获脚本退出信号

        ```sh
        #!/bin/bash
        trap "echo Goodbye." EXIT

        echo This is a test script

        count=1
        while [ $count -le 10 ]
        do
        echo "Loop $count"
        sleep 1
        count=$[ $count + 1 ]
        done

        echo The end.
        ```

        运行结果：

        ```text
        This is a test script
        Loop 1
        Loop 2
        Loop 3
        Loop 4
        Loop 5
        Loop 6
        Loop 7
        Loop 8
        Loop 9
        Loop 10
        The end.
        Goodbye.
        ```

    * 示例 3: 脚本中途修改 `trap` 设置

        ```sh
        #!/bin/bash
        trap "echo 'Sorry! I have trapped Ctrl-C'" SIGINT

        count=1
        while [ $count -le 5 ]
        do
        echo "Loop $count"
        sleep 1
        count=$[ $count + 1 ]
        done


        trap "echo 'Sorry! The trap has been modified.'" SIGINT

        count=1
        while [ $count -le 5 ]
        do
        echo "Loop $count"
        sleep 1
        count=$[ $count + 1 ]
        done

        echo The end.
        ```

        运行结果：

        ```text
        Loop 1
        Loop 2
        Loop 3
        ^CSorry! I have trapped Ctrl-C
        Loop 4
        Loop 5
        Loop 1
        Loop 2
        Loop 3
        ^CSorry! The trap has been modified.
        Loop 4
        Loop 5
        The end.
        ```

* 小东西

    ```sh
    $ stty -a  # 显示触发某些信号的键位
    speed 38400 baud; rows 61; columns 236; line = 0;
    intr = ^C; quit = ^\; erase = ^?; kill = ^U; eof = ^D; eol = <undef>; eol2 = <undef>; swtch = <undef>; start = ^Q; stop = ^S; susp = ^Z; rprnt = ^R; werase = ^W; lnext = ^V; discard = ^O; min = 1; time = 0;
    -parenb -parodd -cmspar cs8 -hupcl -cstopb cread -clocal -crtscts
    -ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr icrnl ixon -ixoff -iuclc -ixany -imaxbel -iutf8
    opost -olcuc -ocrnl onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0
    isig icanon iexten echo echoe echok -echonl -noflsh -xcase -tostop -echoprt echoctl echoke -flusho -extproc
    ```


## 按行读取

### 从文件中按行读取

以常见的 csv 文件为例:

```sh
#! /bin/bash 

file_T="test.csv"   # 给定csv文件名
# test.csv内容示例：
# os_type,os_version,rpm_name,rpm_version
# redhat,6,openssh,5.3p1-124.el6_10.x86_64
# redhat,7,openssh,7.4p1-21.el7.x86_64

num=0
IFS=,     # 修改默认分隔符 <= 注：Internal Field Seprator, 内部域分隔符

# 按行读取文件, 并将四个值分别赋值给四个变量
while read -r os_type_T os_version_T rpm_name_T rpm_version_T
    do
        let num+=1
        echo "======${num}======"
        echo "os_type_T=${os_type_T}"
        echo "os_version_T=${os_version_T}"
        echo "rpm_name_T=${rpm_name_T}"
        echo "rpm_version_T=${rpm_version_T}"
    done < ${file_T}
```

### 从 `<<EOF` 输入的文本中按行读取

```sh
#! /bin/bash

num=0
IFS=,     # 修改默认分隔符 <= 注：Internal Field Seprator, 内部域分隔符

# 按行读取输入, 并将四个值分别赋值给四个变量
while read -r os_type_T os_version_T rpm_name_T rpm_version_T
    do
        let num+=1
        echo "======${num}======"
        echo "os_type_T=${os_type_T}"
        echo "os_version_T=${os_version_T}"
        echo "rpm_name_T=${rpm_name_T}"
        echo "rpm_version_T=${rpm_version_T}"
    done << EOF
redhat,6,openssh,5.3p1-124.el6_10.x86_64
redhat,7,openssh,7.4p1-21.el7.x86_64
EOF
```

### 从命令输出结果中按行读取

```sh
#! /bin/bash

num=0
IFS=,     # 修改默认分隔符 <= 注：Internal Field Seprator, 内部域分隔符

# 按行读取输入, 并将四个值分别赋值给四个变量
while read -r os_type_T os_version_T rpm_name_T rpm_version_T
    do
        let num+=1
        echo "======${num}======"
        echo "os_type_T=${os_type_T}"
        echo "os_version_T=${os_version_T}"
        echo "rpm_name_T=${rpm_name_T}"
        echo "rpm_version_T=${rpm_version_T}"
    done <<< "$(echo -e 'redhat,6,openssh,5.3p1-124.el6_10.x86_64\nredhat,7,openssh,7.4p1-21.el7.x86_64')"
# 此处的""必须加, 因为设置了"IFS=,", 如果不加的话, shell将","作为分隔符而隐藏。参考：
# shell> IFS=,
# shell> var='a,b,c'
# shell> echo $var
# a b c
# shell> echo "$var"

# 也可以用下面这种写法完成
while read -r os_type_T os_version_T rpm_name_T rpm_version_T
    do
        let num+=1
        echo "======${num}======"
        echo "os_type_T=${os_type_T}"
        echo "os_version_T=${os_version_T}"
        echo "rpm_name_T=${rpm_name_T}"
        echo "rpm_version_T=${rpm_version_T}"
    done < <(echo -e 'redhat,6,openssh,5.3p1-124.el6_10.x86_64\nredhat,7,openssh,7.4p1-21.el7.x86_64')
```

## 注释

* 单行注释: `#`

* 多行注释

    1. 使用多个 `#`

    2. 采用 `HERE DOCUMENT` 特性

        ```sh
        << COMMENT
        ...
        COMMENT
        ```
    
    3. 采用 `:` 命令的特殊作用

        > 这种做法有很多局限性, 而且会影响性能

        ```sh
        : '
        COMMENT1
        COMMENT2
        '
        ```

        关于 "`:`"

        ```sh
        ~] help :

        :: :
            Null command.
            
            No effect; the command does nothing.
            
            Exit Status:
            Always succeeds.
        ```
    
        `:` 也是一个命令, 因此可以给它传参数; 但因它会过滤掉这些参数, 而单引号括起来的是普通的代码部分表示字符串, 所以我们刚好可将来用来代表注释, 表示在 `:` 后的单引号括起来的部分在程序执行的时候忽略

        这个用法潜藏的问题: 

        * 它不会注释 shell 脚本中本身带有单引号的语句部分, 除非你将程序中的单引号全部换成双引号, 这样不爽。
        * 此外, 虽然 `:` 会忽视后面的参数, 但其实参数部分还是可能会被执行些操作, 比如 **替换操作**, **文件截取操作**等, 所以这样会影响到代码的执行效率。例如：
            * `: > file` 会截取 `file`
            * `: $(dangerous command)` 这个替换操作照样会执行



    4. 采用 `: + << 'COMMENT'` 组合的方式

        ```sh
        : << COMMENT
        ...
        COMMENT
        ```


## 变量自增

```sh
i=`expr $i + 1`

let i+=1

((i++))

i=$[$i+1]        # 此时 $i 也可以直接写成 i

i=$(( $i + 1 ))  # 此时 $i 也可以直接写成 i
```


## 多线程


例如要完成以下需求: 处理10000个类似工作, 如何用shell实现?

### 方法一: for循环完成

```sh
#! /bin/bash

start=$(date +'%s')

for i in $(seq 1 10000); do
    sleep 1   # 此处用 sleep 1 替换实际执行任务的操作
    echo -e "${i}\tSuccess"
done

stop=$(date +'%s')
echo "Start: ${start}"
echo " Stop: ${stop}"
```

### 方法二: `&` + `wait` 实现"多线程"

* `&`: 后台执行

* `wait`: 等待所有子后台进程结束

```sh
#! /bin/bash

start=$(date +'%s')

for i in $(seq 1 10000); do
    {
        sleep 1   # 此处用 sleep 1 替换实际执行任务的操作
        echo -e "${i}\tSuccess"
    } &
done

wait

stop=$(date +'%s')
echo "Start: ${start}"
echo " Stop: ${stop}"
```

此方法速度极快, 在高性能服务器上能够显著提升效率, 但是 `&` 后台运行的线程数不可控, 在普通配置的服务器上, 随着高并发压力, 处理速度反而会慢下来


### 方法三: `xargs -P`

| 参数 | 含义 |
| -- | -- |
| `-I R` | = `-i R` |
| `-i [R]` | Replace R in initial arguments with names read from standard input. If R is unspecified, assume `{}` |
| `-P N` | Run up to *N* processes at a time |
| `-n N` | Use at most *N* arguments per command line |


```sh
#! /bin/bash

start=$(date +'%s')

seq 1 10000 | xargs -I {} -P 1000 sh -c 'sleep 1; echo -e "{}\tSuccess"'

stop=$(date +'%s')
echo "Start: ${start}"
echo " Stop: ${stop}"
```

### 方法四: GNU `parallel`

需要从epel库中安装parallel

```text
parallel [options] [command [arguments]] < list_of_arguments

parallel [options] [command [arguments]] ( ::: arguments | :::: argfile(s) | -a argfile1 -a argfile2 ...) ...

-0, --null
--bg:        Run command in background thus GNU parallel will not wait for completion of the command before exiting. This is the default if --semaphore is set.
--fg:        Run command in foreground thus GNU parallel will wait for completion of the command before exiting.
--dry-run:   Print the job to run on stdout (standard output), but do not run the job.
-j, --jobs
    "N":  Number of jobslots on each machine
    "+N": Add N to the number of CPU cores
    "-N": Subtract N from the number of CPU cores)
    "N%": Multiply N% with the number of CPU cores.
-N max-args: Use at most max-args arguments per command line.
```

```sh
#! /bin/bash

start=$(date +'%s')

parallel -j 1000 "sleep 1; echo -e '{}\tSuccess'" ::: $(seq 1 10000)

stop=$(date +'%s')
echo "Start: ${start}"
echo " Stop: ${stop}"
```


### 方法五: FIFO+fd实现"多线程"

* 有名管道FIFO

    管道文件有两种, 一个是有名管道FIFO, 一个是匿名管道PIPE。

    FIFO特性: 

    * 如果管道内容为空, 则阻塞;

    * 如果没有读管道的操作, 则阻塞.

    管道具有存一个读一个读完一个就少一个, 没有则阻塞, 放回的可以重复取, 这正是队列特性; 但是问题是当往管道文件里面放入一段内容, 没人取则会阻塞, 这样你永远也没办法往管道里面同时放入多段内容

    10000 个人去网吧上网, 网吧只有 100 台电脑; 每个人开卡才能上网, 上完网下机后下一个人才能继续在这台电脑上上机; 这样就可以实现10000个人100台电脑上网, 最大上机数只能是100

    创建FIFO:

    ```sh
    mkfifo file_name
    ```

* 文件描述符: FD(File Descriptor)

    File descriptor是一个抽象的指示符, 用一个整数表示(非负整数)。它指向了由系统内核维护的一个file table中的某个条目(entry)。为了了解FD, 先了解一下以下内容:

    * User space & Kernel space

        现代操作系统会把内存划分为2个区域, 分别为 `Use space`(用户空间) 和 `Kernel space`(内核空间)。用户的程序在 `User space` 执行, 系统内核在 `Kernel space` 中执行。

    * System Call

        用户的程序没有权限直接访问硬件资源, 但系统内核可以。比如: 读写本地文件需要访问磁盘, 创建socket需要网卡等。因此用户程序想要读写文件, 必须要向内核发起读写请求, 这个过程即 `system call`。

        内核收到用户程序 `system call` 时, 负责访问硬件, 并把结果返回给程序

        例如, 完成以下代码: 

        ```c
        FileInputStream fis = new FileInputStream("/tmp/test.txt");
        byte[] buf = new byte[256];
        fis.read(buf);
        ```

        会经过的流程:

        ```text
        +---------------------------------------------------------------------------------------------------------------+
        |                                                                                                               |
        |      +-----------------------+           +-----------------------+           +-----------------------+        |
        |      |       User Space      |           |     Kernel Space      |           |       Hardware        |        |
        |      +-----------------------+           +-----------------------+           +-----------------------+        |
        |                  |                                   |                                   |                    |
        |                  |           read() syscall          |                                   |                    |
        |                  | +-------------------------------> |                                   |                    |
        |                  |                                   |           ask for data            |                    |
        |                  |                                   | +-------------------------------> |                    |
        |                  |                                   |                                   |                    |
        |                  |                                   | data to kernel buffer through DMA |                    |
        |                  |                                   | <- - - - - - - - - - - - - - - -+ |                    |
        |                  |     copy data to user buffer      |                                   |                    |
        |                  | <- - - - - - - - - - - - - - - -+ |                                   |                    |
        |                  |                                   |                                   |                    |
        |                  | +---------+                       |                                   |                    |
        |                  |           | code logic continues  |                                   |                    |
        |                  | <---------+                       |                                   |                    |
        |                  |                                   |                                   |                    |
        |                  |                                   |                                   |                    |
        +---------------------------------------------------------------------------------------------------------------+
        ```

    * File Descriptor

        和fd相关的一共有3张表, 分别是 `file descriptor`、`file table`、`inode table`, 如下图所示。


        ```text
        +-------------------------------------------------------------------------------------------------------------+
        |                                                                                                             |
        |      +----------------------+           +-----------------------+           +----------------------+        |
        |      |    File Descriptor   |           |   Global File Table   |           |      Inode Table     |        |
        |      +----------------------+           +-----------------------+           +----------------------+        |
        |      |          0           | +-------> | read-only, offset: 0  | +---+     | /dev/pts21           |        |    
        |      |----------------------|           |-----------------------|      \    |----------------------|        |    
        |      |          1           | +-----+-> | write-only, offset: 0 | +-----+-> | /dev/pts22           |        |    
        |      |----------------------|      /    |-----------------------|           |----------------------|        |    
        |      |          2           | +---+     |                       |       +-> | /path/to/myfile1.txt |        |    
        |      |----------------------|           |-----------------------|      /    |----------------------|        |    
        |      |          3           | +-------> | read-write, offset:12 | +---+     | /path/to/myfile2.txt |        |    
        |      |----------------------|           |-----------------------|           |----------------------|        |    
        |      |          4           | +-------> | read-write, offset: 0 | +-------> | /path/to/myfile3.txt |        |    
        |      |----------------------|           |-----------------------|           |----------------------|        |    
        |      |         ...          |           |                       |           |         ...          |        |    
        |      +----------------------+           +-----------------------+           +----------------------+        |      
        |                                                                                                             |
        +-------------------------------------------------------------------------------------------------------------+
        ```

        * File Descriptor table

            File descriptors table由用户进程所有, 每个进程都有一个这样的表, 这里记录了进程打开的文件所代表的fd, fd的值映射到File table中的条目(entry)。

            每个进程都会预留3个默认的fd: stdin, stdout, stderr; 它们的值分别是0, 1, 2。

            | Integer Value | Name | Symbolic Constant | File Stream |
            | -- | -- | -- | -- |
            | 0 | Standard input | STDIN_FILENO | stdin |
            | 1 | Standard output | STDOUT_FILENO | stdout |
            | 2 | Standard error | STDERR_FILENO | stderr |
        
        * File table

            File table是全局唯一的表, 由系统内核维护。这个表记录了所有进程打开的文件的状态(是否可读、可写等状态), 同时它也映射到 Inode table中的entry。

        * Inode table

            Inode table同样是全局唯一的, 它指向了真正的文件地址(磁盘中的位置), 每个entry全局唯一。


    当程序向内核发起system call `open()`时:
    
    ```text
        内核允许程序请求 => 创建一个 entry 插入到 File table, 并返回 file descriptor => 程序收到fd, 建fd插入fds中
    ```
    
    当程序再次发起system call `read()`时: 
    
    ```text
        程序把相关的fd传给内核 => 内核定位到具体的文件(fd –> file table –> inode table), 向磁盘发起读取请求, 读取到的数据 => 返回给程序处理
    
    # system call: read()
    ssize_t read(int fd, void *buf, size_t count);

    # system call: write()
     ssize_t write(int fd, const void *buf, size_t nbytes);
    ```


    * 查看fd

        ```sh
        # ls -l /proc/PID/fd

        ~] ls -l /proc/self/fd/

        lrwx------. 1 root root 64 Mar  3 20:19 0 -> /dev/pts/1
        lrwx------. 1 root root 64 Mar  3 20:19 1 -> /dev/pts/1
        lrwx------. 1 root root 64 Mar  3 20:19 2 -> /dev/pts/1
        lr-x------. 1 root root 64 Mar  3 20:19 3 -> /var/lib/sss/mc/passwd
        lrwx------. 1 root root 64 Mar  3 20:19 4 -> 'socket:[19415980]'
        lr-x------. 1 root root 64 Mar  3 20:19 5 -> /var/lib/sss/mc/group
        lr-x------. 1 root root 64 Mar  3 20:19 6 -> /proc/1235249/fd
        ```

    * 操作fd

        利用重定向为一个fd赋值:

        ```sh
        6>&1  # fd-6指向fd-1, 即stdout
        6>$-  # fd-6指向空值 = 关闭fd-6
        6<fifo_file
        ```

        当前shell中长期生效: 

        ```sh
        exec 6>&1  # 打开fd-6
        exec 6>&-  # 关闭fd-6
        ```

* FIFO+fd实现"多线程"

    ```sh
    #! /bin/bash

    start=$(date +'%s')

    fifo_file="/tmp/$$.fifo"  # 新建一个fifo, 同时将fd-6输入输出都定义为这个fifo
    mkfifo ${fifo_file}
    exec 6<>${fifo_file}

    for i in {1..1000}; do    # 写入空行作为读取的值, 需要开几个线程就写入几个空行
        echo
    done >&6

    for i in $(seq 1 10000); do
        read -u 6             # 从fd-6中取值, 如果取到, 执行接下来的操作, "&"表示放后台执行
        { 
            sleep 1
            echo -e "$i\tSuccess"
            echo >&6          # 执行完操作后, 将read取走的值重新放回fd-6
        } &
    done

    wait

    stop=$(date +'%s')

    echo "Start: ${start}"
    echo " Stop: ${stop}"

    exec 6>&-                # 关闭fd-6
    ```