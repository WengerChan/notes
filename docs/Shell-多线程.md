# Shell - 多线程

需求: 处理10000个类似工作, 如何用shell实现?

## 方法一: for循环完成

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

## 方法二: `&` + `wait` 实现"多线程"

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


## 方法三: `xargs -P`

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

## 方法四: GNU `parallel`

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


## 方法五: FIFO+fd实现"多线程"

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