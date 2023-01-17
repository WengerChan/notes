# rsync

## 实战1：Windows Server搭建服务端

### 配置参考

1. 下载安装包 `cwRsyncServer`
   
   从官网[https://www.itefix.net/cwrsync](https://www.itefix.net/cwrsync)下载服务端 `cwRsyncServer_x.x.x_Installe.zip` 

2. 创建用户

    为 cwrsync server 创建一个安装和运行的专用账户(虽然默认会创建 `SvcCWRSYNC` 用户，建议自行创建)：

    * 打开 `lusrmgr.msc`, 创建用户 `cwrsync` 并设置密码
    * 添加到 `administrators` 组

3. 安装

    * 解压 `.zip`, 双击 `.exe` 文件安装（默认会安装到 `C:\Program Files(x86)\ICW` 目录下）
    * 安装完成后，设置服务开机自启动： 打开 `services.msc`, 找到 `RsyncServer`, 设置为开机自启动

4. 创建密码文件

    进入 cwrsync server 安装目录，新建用户密码文件 `rsyncd_user.db`, 文件内容为 `用户名:用户密码`，如：

    ```conf
    user1:user1_password
    ```

5. 修改配置文件

    默认配置文件如下：

    ```conf
    use chroot = false
    strict modes = false
    hosts allow = *
    log file = rsyncd.log
    # Module definitions
    # Remember cygwin naming conventions : c:\work becomes /cygwin/c/work
    #
    [test]    
    path = /cygdrive/d/work
    read only = false
    transfer logging = yes
    ```

    典型配置：

    ```conf
    use chroot = false
    strict modes = false
    hosts allow = *
    log file = rsyncd.log
    # Module definitions
    # Remember cygwin naming conventions : c:\work becomes /cygwin/c/work
    #
    [test]    
    path = /cygdrive/d/work
    read only = false
    transfer logging = yes
    ```

### 附: `rsyncd.conf` 参数

* 全局参数

    * The first parameters in the file (before a [module] header) are the global parameters.
    * You may also include any module parameters in the global part of the config file in which case the supplied value will override the default for that parameter.

    | PARAMETERS     | 说明                    |
    | -------------- | :---------------------- |
    | port           | 设置监听端口（默认873） |
    | address        | 设置监听地址            |
    | motd file      |                         |
    | pid file       |                         |
    | socket options |                         |

* 模块参数

    * Define a number of modules, each module exports a directory tree as a symbolic name.
    * Modules are exported by specifying a module name in square brackets `[module]` followed by the parameters for that module. 

    > 模块名称不能包含斜杠或闭合方括号；如果名称包含空格，则每个内部空格序列将被更改为一个空格，而前导或后面的空格将被丢弃。

    | PARAMETERS      | 说明                                                          |
    | --------------- | :------------------------------------------------------------ |
    | comment         | 设置模块说明                                                  |
    | path            | 设置模块导出的目录                                            |
    | user chroot     | 设置传输文件是否先chroot到path（默认true）                    |
    | numeric ids     | 设置是否将UID/GID与用户名/组名对应<sup id="a1">[1](#f1)</sup> |
    | munge symlinks  | 拷贝链接文件                                                  |
    | charset         | 设置字符集                                                    |
    | max connections | 设置最大连接数（默认0不限制）                                 |
    | log file        | 设置日志文件名                                                |
    | syslog facility | 设置syslog日志设备                                            |
    | max verbosity   | 设置日志详细程度（默认1）                                     |
    | lock file       | 设置锁文件（用于支持 max connections）                        |
    | read only       | 设置只读，客户端不能上传（默认true）                          |
    | write only      | 设置只写，客户端不能下载（默认false）                         |
    | list            | 设置该module是否可被list（默认true）                          |
    | uid             | 默认-2                                                        |
    | gid             | 默认-2                                                        |
    | fake super      |                                                               |
    | filter          |                                                               |
    | exclude         | 跳过                                                          |
    | include         | 传输                                                          |
    | exclude from    |                                                               |
    | include from    |                                                               |
    | incoming chmod  | 设置接收到的文件的权限                                        |
    | outcoming chmod | 设置发出去的文件的权限                                        |
    | auth users      |                                                               |
    | secrets file    |                                                               |
    | strict modes    |                                                               |
    | hosts allow     |                                                               |
    hosts deny
    ignore errors
    ignore nonreadable
    transfer logging
    log format
    timeout
    refuse options
    dont compress
    pre-xfer exec, post-xfer exec

<b id="f1"><font size=1>1 By default, this parameter is enabled for chroot modules and disabled for non-chroot modules.</font></b> [↺](#a1)  
<b id="f2"><font size=2>2 Daemon端过滤链由filter, include from, include, exclude from, exclude参数组成，并以此为先后（生效）顺序</font></b> [↺](#a2)  




## 实战2：Linux搭建服务端



### 附: 筛选规则

> [https://www.cnblogs.com/f-ck-need-u/p/7221713.html](https://www.cnblogs.com/f-ck-need-u/p/7221713.html)

Daemon端过滤链由filter, include from, include, exclude from, exclude参数组成，并以此为先后（生效）顺序。

Daemon端和客户端发送的筛选规则的交集为实际传输的文件。

rsync会按照筛选规则建立一个有序的规则列表，筛选规则语法如下：

```conf
RULE [PATTERN_OR_FILENAME]             # PATTERN或FILENAME必须跟在单个空格或下划线后
RULE,MODIFIERS [PATTERN_OR_FILENAME]   # 使用短格式的RULE时','可省
```

规则前缀：

| RULE             | 说明                                                                                                       |
| ---------------- | ---------------------------------------------------------------------------------------------------------- |
| `exclude`, `-`   | 指定排除规则。                                                                                             |
| `include`, `+`   | 指定包含规则。                                                                                             |
| `merge`, `.`     | 指定一个可读取更多规则的merge-file。                                                                       |
| `dir-merge`, `:` | 指定一个每目录的merge-file。                                                                               |
| `hide`, `H`      | 指定传输过程中需要隐藏的文件 (exclude的本质是hide, 作用于sender端)                                         |
| `show`, `S`      | 指定不被隐藏的文件 (include的本质是show, 作用于sender端)                                                   |
| `protect`, `P`   | 指定保护文件不被删除的规则 (--delete和--exclude同时使用时, 会对被排除的文件加上保护规则; 作用于receiver端) |
| `risk`, `R`      | 指定不被保护的(即能被删除)文件。(--delete-excluded是将被保护的文件强制取消保护; 作用于receiver端)          |
| `clear`, `!`     | 清空当前include/exclude列表。(不带任何参数)                                                                |


* include/exclude匹配模式

    * 如果匹配模式以斜线(/)开头，它表示锚定层次结构中某个特定位置的文件，否则将表示匹配路径名的结尾。
    * 若匹配模式以斜线(/)结尾，将只匹配目录，而不匹配普通文件、字符链接以及设备文件。
        * `/foo` 匹配传输根目录下的 `foo` 文件或目录
        * `foo` 匹配任意位置下的 `foo` 文件或目录
        * `sub/foo` 非锚定，匹配层次结构中位于sub目录下的 `foo` 文件
        * `foo/` 匹配层次结构中的 `foo` 目录
    * rsync 会检查 `*`, `?` 以及 `[` 符号:
        * 单个 `*` 匹配任意路径元素，遇到斜线时终止匹配
        * `**` 匹配任意路径元素，能匹配斜线
        * `?` 匹配任意非斜线的单个字符
        * `[` 表示字符类匹配，例如 `[a-z]`, `[[:alpha:]]`
        * `\` 可以对通配符号进行转义
    * 如果匹配模式中包含了一个 `/` (不包括以斜线结尾的情况)或 `**`，则表示对包括前导目录的全路径进行匹配。
    * 如果匹配模式中不包括 `/` 或 `**` ，则表示只对全路径尾部的路径元素进行匹配。(注意：使用了递归功能时，`全路径` 可能是从最顶端开始向下递归的某中间 段路径)。

    示例：

    ```text
    "- *.o"         将排除所有文件名能匹配 "*.o" 的文件。
    "- /foo"        将排除传输根目录下名为 "foo" 的文件或目录。
    "- foo/"        将排除所有名为 "foo" 的目录。 
    "- /foo/*/bar"  将排除传输根目录下 "foo" 目录再向下两层的 "bar" 文件。
    "- /foo/**/bar" 将排除传输根目录下 "foo" 目录再向下递归任意层次后名为 "bar" 的文件
    
    "+  */", "+ *.c", "- *"         将只包含所有目录和C源码文件，除此之外的所有文件和目录都被排除。(参见选项"--prune-empty-dirs")
    "+ foo/", "+ foo/bar.c", "- *"  将只包含 "foo" 目录和 "foo/bar.c" 。("foo" 目录必须显式包含，否则将被排除规则 "- *" 排除掉)
    ```

    以下是 "`+`" 或 "`-`" 后可接的修饰符:

    * "`/`": 指定include/exclude规则需要与当前条目的绝对路径进行匹配。例如:
        * "`-/ /etc/passwd"` 将在任意传输 /etc 目录中文件时刻都排除 passwd 文件
        * "`-/ subdir/foo`" 当传输 "subdir`" 目录中文件时，将总是排除 "foo" 文件，即使"foo"文件可能是在传输根目录中的。

    * "`!`": 指定如果模式匹配失败，则include/exclude规则生效（类似于"取反"）。例如: "`-! */`" 将排除所有非目录文件

    * "`C`": 表示将所有的全局CVS排除规则插入到普通排除规则中，而不再使用 "-C" 选项来插入。其后不能再接其他参数。

    * "`s`": 表示规则只应用于 sender 端。当某规则作用于sender端时，它可以防止文件被传输。
        * 默认情况下，所有规则都会作用于两端，除非使用了 "`--delete-exclude`" 选项，这样规则将只作用于sender端。
        * "`hide`"(H) 和 "`show`"(S) 规则，这是指定 sender 端include/exclude规则的另一种方式。

    * "`r`": 表示规则只应用于 receiver 端。当规则作用于receiver端，它可以防止文件被删除。
        更多信息见 "`s`" 修饰符。另请参见"`P`"和"`R`"规则，它们是指定receiver端include/exclude规则的另一种方式。

    * "`p`": 表示此规则是易过期的，这意味着将忽略正在被删除的目录。例如，"`-C`"选项的默认规则是以CVS风格进行排除，且"*.o"文件会被标记为易过期，这将不会阻止在源端移除的目录在目标端上被删除。(译者注：也就是说在源端删除的目录在目标端上也会被删除。)