# 深入剖析 Kubernetes


## 1 容器技术

* 容器技术的核心功能，就是通过约束和修改进程的动态表现，从而为其创造出一个“边界”。

* 对于 Docker 等大多数 Linux 容器来说，`Cgroups` 技术是用来制造约束的主要手段，而 `Namespace` 技术则是用来修改进程视图的主要方法。

* `Namespace` 的使用方式也非常有意思：它其实只是 Linux 创建新进程的一个可选参数。

    ```c
    int pid = clone(main_function, stack_size, CLONE_NEWPID | SIGCHLD, NULL); 
    ```

    当指定 `CLONE_NEWPID` 参数时，新创建的这个进程将会“看到”一个全新的进程空间，在这个进程空间里，它的 PID 是 1。之所以说“看到”，是因为这只是一个“障眼法”，在宿主机真实的进程空间里，这个进程的 PID 还是真实的数值，比如 100。

* 除了 PID Namespace，Linux 操作系统还提供了 Mount、UTS、IPC、Network 和 User 这些 Namespace，用来对各种不同的进程上下文进行“障眼法”操作。

* Mount Namespace 只隔离增量，不隔离存量

    Mount Namespace 修改的，是容器进程对文件系统“挂载点”的认知。但是，这也就意味着，只有在“挂载”这个操作发生之后，进程的视图才会被改变。而在此之前，新创建的容器会直接继承宿主机的各个挂载点。

    这就是 Mount Namespace 跟其他 Namespace 的使用略有不同的地方：**它对容器进程视图的改变，一定是伴随着挂载操作（mount）才能生效。**

* rootfs - 载在容器根目录上、用来为容器进程提供隔离后执行环境的文件系统，就是所谓的“容器镜像”

* 隔离不彻底

    * 首先，既然容器只是运行在宿主机上的一种特殊的进程，那么多个容器之间使用的就还是同一个宿主机的操作系统内核。
    * 其次，在 Linux 内核中，有很多资源和对象是不能被 Namespace 化的，最典型的例子就是：时间。

* Linux Cgroups 就是 Linux 内核中用来为进程设置资源限制的一个重要功能。

* Linux Cgroups 的全称是 Linux Control Group。它最主要的作用，就是限制一个进程组能够使用的资源上限，包括 CPU、内存、磁盘、网络带宽等等。此外，Cgroups 还能够对进程进行优先级设置、审计，以及将进程挂起和恢复等操作。

* 在 Linux 中，Cgroups 给用户暴露出来的操作接口是文件系统，即它以文件和目录的方式组织在操作系统的 `/sys/fs/cgroup` 路径下。

* 实例：Cgroup 显示进程 CPU 使用率

    ```sh
    # 1 进入 cgroup 目录
    ~] cd /sys/fs/cgroup/cpu/

    # 2 创建一个 test 目录，此时系统会自动生成一系列控制 cpu 的文件
    # cfs_period 和 cfs_quota 这两个参数需要组合使用：用来限制进程在长度为 cfs_period 的一段时间内，只能被分配到总量为 cfs_quota 的 CPU 时间
    ~] mkdir test
    # 查看 test目录下的 CPU quota 任何限制（即：-1），CPU period 则是默认的 100 ms（100000 us）
    ~] cat cpu.cfs_period_us 
    100000
    ~] cat cpu.cfs_quota_us 
    -1
    ~] top
    %Cpu0  :100.0 us,  0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    %Cpu1  :  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    ...

    # 3 运行以下命令，会将一个 CPU 使用率打满
    ~] while : ; do : ; done &
    [1] 3861

    # 4 将进程号写入 tasks 文件，同时修改 quota 为 20000 (20ms)
    # 表示：100ms 内最多使用CPU 20ms；即显示进程使用 20% CPU
    ~] echo 3861 > tasks 
    ~] echo 20000 > cpu.cfs_quota_us
    ~] top # 按 1 可看到具体每个 CPU 使用率
    %Cpu0  : 20.2 us,  0.3 sy,  0.0 ni, 79.5 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    %Cpu1  :  0.0 us,  0.3 sy,  0.0 ni, 99.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    ...
    ```
