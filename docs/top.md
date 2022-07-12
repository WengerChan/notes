# top

## 1. 表头信息详解

```text
## 系统整体情况概览
top - 12:05:07 up  1:16,  2 users,  load average: 1.77, 1.38, 1.24
      | 时间 | 运行时间 |当前登录用户|平均负载: 1分钟/5分钟/15分钟均值|
                                    即任务队列的平均长度
```

```text
## 进程状态
Tasks: 215 total,   1 running, 213 sleeping,   1 stopped,   0 zombie
      | 总任务  |      运行中 |     休眠状态 |   停止状态 |   僵尸进程 |
```

```text
## CPU
%Cpu(s):  7.4 us,  5.2 sy,  0.0 ni, 87.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
       | 用户空间|内核空间| 优先级调|   空闲 |  等待I/O |  硬中断 | 软中断 | steal |
                          整耗时(用户空间)                               虚拟机调度/申请等花费

           a    b     c    d
%Cpu(s):  75.0/25.0  100[ ...
     a) is the combined us and ni percentage; 
     b) is the sy percentage; 
     c) is the total; 
     d) is one of two visual graphs of those representations.
```

```text
## 内存, SWAP信息
KiB Mem : 32780168 total, 25278248 free,  2334020 used,  5167900 buff/cache
单位   |  总容量         |         空闲 |       已使用 |               缓存 |

KiB Swap:  4063228 total,  4063228 free,        0 used. 25974516 avail Mem
单位   |  总容量         |         空闲 |       已使用 |

           a    b          c
GiB Mem : 18.7/15.738   [ ...
GiB Swap:  0.0/7.999    [ ...
     a) is the percentage used; 
     b) is the total available; 
     c) is one of two visual graphs of those representations.

```


## 2. 进程状态

```text
## 进程状态
    PID USER        PR        NI     VIRT     RES      SHR S          %CPU     %MEM         TIME+ COMMAND                                                                                                
   4708 qemu        20         0  4424784  342904    21752 S           5.9      1.0     286:49.77 qemu-kvm
      3 root         0       -20        0       0        0 I           0.0      0.0       0:00.00 rcu_gp  
PID |进程用户|动态优先级|静态优先级|虚拟内存|物理内存|共享内存|进程状态|CPU占用| 内存占用| 占用CPU总时间|进程命令描述
              Priority      nice      KB      KB      KB  R=运行               %RES
                                                          S=睡眠
                                                          T=跟踪/停止
                                                          D=不可中断的睡眠状态 
                                                          Z=僵尸进程
```

全部列（字段）：

```text
Fields Management for window 1:Def, whose current sort field is %CPU
   Navigate with Up/Dn, Right selects for move then <Enter> or Left commits,
   'd' or <Space> toggles display, 's' sets sort.  Use 'q' or <Esc> to end!
* PID     = Process Id             DATA    = Data+Stack (KiB)    
* USER    = Effective User Name    nMaj    = Major Page Faults   
* PR      = Priority               nMin    = Minor Page Faults   
* NI      = Nice Value             nDRT    = Dirty Pages Count   
* VIRT    = Virtual Image (KiB)    WCHAN   = Sleeping in Function
* RES     = Resident Size (KiB)    Flags   = Task Flags <sched.h>
* SHR     = Shared Memory (KiB)    CGROUPS = Control Groups      
* S       = Process Status         SUPGIDS = Supp Groups IDs     
* %CPU    = CPU Usage              SUPGRPS = Supp Groups Names   
* %MEM    = Memory Usage (RES)     TGID    = Thread Group Id     
* TIME+   = CPU Time, hundredths   OOMa    = OOMEM Adjustment    
* COMMAND = Command Name/Line      OOMs    = OOMEM Score current 
  PPID    = Parent Process pid     ENVIRON = Environment vars    
  UID     = Effective User Id      vMj     = Major Faults delta  
  RUID    = Real User Id           vMn     = Minor Faults delta  
  RUSER   = Real User Name         USED    = Res+Swap Size (KiB) 
  SUID    = Saved User Id          nsIPC   = IPC namespace Inode 
  SUSER   = Saved User Name        nsMNT   = MNT namespace Inode 
  GID     = Group Id               nsNET   = NET namespace Inode 
  GROUP   = Group Name             nsPID   = PID namespace Inode 
  PGRP    = Process Group Id       nsUSER  = USER namespace Inode
  TTY     = Controlling Tty        nsUTS   = UTS namespace Inode 
  TPGID   = Tty Process Grp Id     LXC     = LXC container name  
  SID     = Session Id             RSan    = RES Anonymous (KiB) 
  nTH     = Number of Threads      RSfd    = RES File-based (KiB)
  P       = Last Used Cpu (SMP)    RSlk    = RES Locked (KiB)    
  TIME    = CPU Time               RSsh    = RES Shared (KiB)    
  SWAP    = Swapped Size (KiB)     CGNAME  = Control Group name  
  CODE    = Code Size (KiB)        NU      = Last Used NUMA node 
```

## 3. 快捷键

* 显示相关

    ```text
    space  立即刷新
    d,s  设置更新间隔(s)

    0  值为0的不显示
    1  显示CPU各个核心的信息
    2  显示NUMA各个节点信息
    3  显示指定NUMA信息

    l  切换表头 负载信息 显示模式(开/关)
    t  切换表头 CPU 显示模式
    m  切换表头 内存/SWAP 显示模式

    E  切换表头 内存/SWAP 显示单位
    e  切换 VIRT, RES, SHR 显示单位

    H  显示线程信息而不是进程信息

    c  显示 命令名称/完整命令(COMMAND)
    i  显示/不显示 任何闲置或者僵死(idle)的进程

    B  开启/关闭高亮
    x,y  高亮：x=排序列，y=当前运行的进程
    b  切换选中模式（默认为加粗显示，可切换为高亮整行/列）
       搭配使用：xb, yb

    V  树形显示
    v  在 V 激活时，折叠/展开子进程

    z,Z  z: 切换彩色显示; Z: 彩色显示高级设置

    I  开启/关闭 Irix mode(默认开启)
        Irix mode: 计算占总CPU的百分比, 可能会超过100%, 但不会超过 核数*100%
        Solaris mode: 计算分摊到所有CPU的平均百分比, 总的CPU百分比/核数
    
    C  显示滚动坐标："y = 1/124 (tasks), x = 1/12 (fields)"

    j  切换左对齐/右对齐（针对数值型字段）数值型字段默认右对齐
    J  切换左对齐/右对齐（针对字符型字段）字符型字段默认左对齐

    S  显示累计CPU使用时间（会包含该进程已经死掉的子进程的时间）
    ```

* 排序相关

    ```text
    R  切换排序规则(从大到小, 从小到大)
    P  按 CPU 使用率从大到小排序
    M  按 内存 使用率从大到小排序
    N  按 PID 号从大到小排序
    T  按 TIME+ 从大到小排序
    f,F 添加/删除显示的列; 设置排序的列
        按 f 进入字段选择界面
        按 ↑, ↓ 选择字段
            按 s 选择排序的列
            按 → 选中字段, 然后按 ↑, ↓ 来移动字段显示
            按 d 或者 space 来取消/显示字段
        按 q 回到主界面查看排序
    ```

* 查找/过滤

    ```text
    =   取消过滤条件
    ctrl+o 查看当前的过滤条件
    
    L   查找
    &   查找下一个
    u,U 只显示指定用户的进程, 如 "root" 只显示root用户进程, "!root" 显示非root用户进程
        u: effective, U: real, effective, saved...
    o,O 过滤, o 忽略大小写; O 大小写敏感
        +------------------------------------------------+
        |   #1           #2  #3              ( required )|
        |   Field-Name   ?   include-if-value            |
        |!  Field-Name   ?   exclude-if-value            |
        |#4                                  ( optional )|
        +------------------------------------------------+
        #2: 运算符号, 只能是 +, >, <
            =: 部分匹配即可
            >, <: 使用字符串比较, 即使是数字字段(实测:纯数字字段课使用算术比较)
        例:
            查找命令中含 systemd 的进程: COMMAND=systemd
            查找 CPU 占用超过 1% 的进程: %CPU>1.0
    ```

* 其他

    ```text
    h  帮助
    q  退出

    W  保存当前配置到文件中, 下次启动 top 时会使用此配置

    k  kill 终止进程
    r  renice 修改进程 nice 值
    ```



## 4. 参数

```sh
top -hv|-bcEHiOSs1 -d secs -n max -u|U user -p pid -o fld -w [cols]
```

```text
-h | -v  帮助信息
-b  批处理模式, 结果输出到stdout
    -n 指定执行的次数
-c  显示完整命令
-d  设置刷新间隔（单位：secs.tenths）
-E  设置表头显示内存的单位，可设置为 k|m|g|t|p|e
-H  设置表头显示线程而不是进程信息
-i  不显示闲置/僵死的进程
-o  指定排序的字段，如 "-o +%MEM"，字段前的"+"表示从大到小排序，"-"从小到大排序
-O  打印所有可用字段
-p  只显示指定进程号的进程信息，"-pPID1 -pPID2..."
-s  安全模式运行，无法执行一些有潜在风险的交互命令，如 "k", "r" 等
-S  显示每个进程累计占用CPU时间模式，每个进程的CPU时间会包含该进程和该进程已经死掉的子进程的时间
-u,-U 只显示指定用户的进程，可用"!"表示排除， 如 -u '!root' 表示显示所有非root用户的进程
-1  显示各个CPU的信息
```

---

## 附录 A：top 命令各字段含义

```text
%CPU  --  CPU Usage
%MEM  --  Memory Usage (RES)
CGNAME  --  Control Group Name
CGROUPS  --  Control Groups
CODE  --  Code Size (KiB)
          可执行代码占用的物理内存量，也称文本驻留集大小（TRS）
COMMAND  --  Command Name or Command Line
DATA  --  Data + Stack Size (KiB) 
          进程保留的私有内存量，也称数据驻留集（DRS），此类内存可能尚未映射到物理内存 (RES)，但将始终包含在虚拟内存 (VIRT) 
ENVIRON  --  Environment variables
Flags  --  Task Flags
GID  --  The effective group ID.
GROUP  --  The effective group name.
LXC  --  Lxc Container Name
         进程在 Lxc 容器中的名字，如果没有在容器运行，显示为"-"
NI  --  Nice Value
NU  --  Last known NUMA node (-1 表示numa不可用)
OOMa  --  Out of Memory Adjustment Factor [-1000, 1000]
OOMs  --  Out of Memory Score [0, 1000]
          Zero translates to 'never kill' whereas 1000 means `always kill'.
P  --  Last used CPU (SMP)
PGRP  --  Process Group Id
PID  --  Process Id
PPID  --  Parent Process Id
PR  --  Priority
RES  --  Resident Memory Size (KiB)
         (VIRT subset) 总驻留内存大小：进程使当前使用的、non-swapped的物理内存大小
         RES = RSan + RSfd + RSsh
RSan  --  Resident Anonymous Memory Size (KiB)
          (RES subset) 驻留匿名内存大小：未映射到文件的私有页面的常驻内存
RSfd  --  Resident File-Backed Memory Size (KiB)
          (RES subset) 驻留文件支持内存大小：支持程序映像和共享库的隐式共享页面
RSlk  --  Resident Locked Memory Size (KiB)
          (RES subset) 驻留锁定内存大小：无法 swapped out
RSsh  --  Resident Shared Memory Size (KiB) 
          (RES subset) 驻留共享内存大小
RUID  --  Real User Id
RUSER  --  Real User Name
S  --  Process Status
           D = uninterruptible sleep
           I = idle
           R = running
           S = sleeping
           T = stopped by job control signal
           t = stopped by debugger during trace
           Z = zombie

SHR  --  Shared Memory Size (KiB)
         (RES subset)其他进程可使用的共享内存
SID  --  Session Id
         会话ID（会话是进程组的集合，通常由Login-shell建立，新进程会从此回话fork产生）
SUID  --  Saved User Id
SUPGIDS  --  Supplementary Group IDs
SUPGRPS  --  Supplementary Group Names
SUSER  --  Saved User Name
SWAP  --  Swapped Size (KiB)
TGID  --  Thread Group Id
TIME  --  CPU Time  "00:00:13" 表示 13s
TIME+  --  CPU Time, hundredth  "00:13.16" 表示 13.16s
TPGID  --  Tty Process Group Id
TTY  --  Controlling Tty
UID  --  Effective User Id
USED  --  Memory in Use (KiB)
          USED = RES + SWAP
USER  --  User Name
VIRT  --  Virtual Memory Size (KiB)
WCHAN  --  Sleeping in Function
           显示睡眠状态进程的当前函数名，正在运行的进程显示为 '-'
nDRT  --  Dirty Pages Count
          脏页数：自上次写入辅助存储器以来已修改的页数。脏页必须先写入辅助存储，然后相应的物理内存位置才能用于其他一些虚拟页。
nMaj  --  Major Page Fault Count
nMin  --  Minor Page Fault count
          Page fault: 当进程试图读取或写入当前不在其地址空间中的虚拟页面时，就会发生页面错误
          Major Page Fault: 主要页面错误，涉及辅助存储访问的页面错误
          Minor Page Fault: 次要页面错误，不涉及辅助存储访问的页面错误
nTH -- Number of Threads
       与进程关联的线程数
nsIPC  --  IPC namespace
           (A Inode) 隔离进程间通信 (IPC)的命名空间
nsMNT  --  MNT namespace
           (A Inode) 隔离文件系统挂载点的命名空间
nsNET  --  NET namespace
           (A Inode) 隔离网络设备、IP地址、IP路由、端口号的命名空间
nsPID  --  PID namespace
           (A Inode) 隔离进程 ID 号的命名空间
nsUSER  --  USER namespace
            (A Inode) 隔离用户和组 ID 号的命名空间
nsUTS  --  UTS namespace
           (A Inode) 隔离主机名和 NIS 域名的命名空间
vMj  --  Major Page Fault Count Delta
         自上次更新以来发生的主要页面错误数
vMn  --  Minor Page Fault Count Delta
         自上次更新以来发生的次要页面错误数
```

---

## 附录 B：关于 real, effective, saved 三种 uid 的区别

`top` 命令中有三种 UID，分别是：

```text
UID  --  Effective User Id, EUID
RUID  --  Real User Id
SUID  --  Saved [Set-]User Id
```

其中：

* `real uid` - 启动进程的用户id，表示这个进程是哪个用户调用的，或者是哪个父进程发起的；通常 ruid 是不更改的，也不需要更改。

* `effective uid` - 判定进程对于某个文件的访问权限的时候，需要验证 `euid`

* `saved user id` - 仅在 `euid` 发生改变时保存

说明：

* 只有超级用户进程才能改变 `real user ID`。一般情况下 `real user ID` 在用户登录的时候由 `login` 程序设置，随后将不再改变;

* 当且仅当程序文件设置了 `set-user-ID` 位时，`effective user ID` 会被函数 `exec` 设置程序文件的属主用户 ID;

* `saved set-user ID` 通过 `exec` 函数复制 `effective user ID`;

* 可以调用 `setuid` 函数在任何时候将 `effective user ID` 设置为 `real user ID` 或者 `saved set-user ID`。

