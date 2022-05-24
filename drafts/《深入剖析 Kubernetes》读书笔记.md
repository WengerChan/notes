# 深入剖析 Kubernetes


## 1 容器技术

* 容器技术的核心功能，就是通过约束和修改进程的动态表现，从而为其创造出一个“边界”。

* 对于 Docker 等大多数 Linux 容器来说，`Cgroups` 技术是用来制造约束的主要手段，而 `Namespace` 技术则是用来修改进程视图的主要方法。

* `Namespace` 的使用方式也非常有意思：它其实只是 Linux 创建新进程的一个可选参数。

    ```c
    int pid = clone(main_function, stack_size, CLONE_NEWPID | SIGCHLD, NULL); 
    ```

    当指定 CLONE_NEWPID 参数时，新创建的这个进程将会“看到”一个全新的进程空间，在这个进程空间里，它的 PID 是 1。之所以说“看到”，是因为这只是一个“障眼法”，在宿主机真实的进程空间里，这个进程的 PID 还是真实的数值，比如 100。

* 除了 PID Namespace，Linux 操作系统还提供了 Mount、UTS、IPC、Network 和 User 这些 Namespace，用来对各种不同的进程上下文进行“障眼法”操作。

* 隔离不彻底

    * 首先，既然容器只是运行在宿主机上的一种特殊的进程，那么多个容器之间使用的就还是同一个宿主机的操作系统内核。
    * 其次，在 Linux 内核中，有很多资源和对象是不能被 Namespace 化的，最典型的例子就是：时间。

* Linux Cgroups 就是 Linux 内核中用来为进程设置资源限制的一个重要功能。

* Linux Cgroups 的全称是 Linux Control Group。它最主要的作用，就是限制一个进程组能够使用的资源上限，包括 CPU、内存、磁盘、网络带宽等等。此外，Cgroups 还能够对进程进行优先级设置、审计，以及将进程挂起和恢复等操作。

* 在 Linux 中，Cgroups 给用户暴露出来的操作接口是文件系统，即它以文件和目录的方式组织在操作系统的 `/sys/fs/cgroup` 路径下。