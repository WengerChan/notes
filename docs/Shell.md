# shell, bash

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

    真正的子 Shell 可以访问其父 Shell 的任何变量，而通过再执行一次 bash 命令所启动的 Shell 只能访问其父 Shell 传来的环境变量。

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

