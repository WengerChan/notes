# quota - 配额管理

quota 可以实现对用户的磁盘空间使用量的配额：

* 仅能针对整个文件系统（需要在文件系统挂载时指定参数）
* 只对普通用户有效
* 支持 ext 和 xfs 文件系统
* 配额可针对 user 或者 group
* 配额可限制 inode 或者 block
* 需要内核支持：

    ```sh
    ~] grep -i quota /boot/config-3.10.0-1160.66.1.el7.x86_64
    ...
    CONFIG_XFS_QUOTA=y
    CONFIG_QUOTA=y
    ...
    ```

## 方式一 - 通用配置方法

> 使用于 `ext4`、`xfs`

工具/命令：

| 工具/命令    | 用途                            | 参数                                                                                                             |
| ------------ | ------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `quotacheck` | 主要用来扫描支持quota的文件系统 | `-a` 检查所有已挂载的文件系统<br>`-u` 只检查用户的配额<br>`-g` 只检查用户组的配额<br>`-v` 打印过程               |
| `quotaon`    | 开启文件系统quota               |                                                                                                                  |
| `quotaoff`   | 关闭文件系统quota               |                                                                                                                  |
| `repquota`   | 打印输出quota分区的使用情况     | `-a` 输出所有分区<br>`-u` 输出用户(默认)<br>`-g` 输出用户组<br>`-s` 可读性输出<br>`-v` 显示更多详情              |
| `quota`      | 查询当前用户的quota信息         | `-u` 指定查询用户<br>`-g` 指定查询用户组<br>`-v` 显示更多详情<br>`-s` 可读性输出                                 |
| `edquota`    | 编辑quota配置                   | `-u` 指定编辑的用户<br>`-g` 指定编辑的用户组<br>`-p` 指定要复制权限的用户/用户组<br>`-t` 编辑宽限时间            |
| `setquota`   | 非交互式配置quota               | **e.g.**: `setquota -u zhangsan 200 400   0  0 /dev/sda3`<br>`/data` 配额：`zhangsan` 软限制 200KB，硬限制 400KB |

> `quotacheck` 主要检查 `noquota`, `usrquota`, `grpquota` 挂载参数


* 挂载: 按需求添加 `usrquota`, `grpquota` 挂载参数

    ```sh
    mount -t ext4 -o usrquota,grpquota /dev/vdb1 /dir_01
    mount -t xfs -o usrquota,grpquota /dev/vdc1 /dir_02
    ```

* 扫描 quota 磁盘

    ```sh
    setenforce 0
    quotacheck -augv  # 提示 "Skipping /dev/vdc1 [/dir_02]", 但实际 quotaon 可对xfs文件系统使用
    ```

* 配置配额

    ```sh
    # 对用户
    ~] edquota -u user_01

    Disk quotas for user user_01 (uid 1001):
      Filesystem                   blocks       soft       hard     inodes     soft     hard
      /dev/vdb1                         0      10240      10240          0        0       10
      /dev/vdc1                         0      20480      20480          0        0       20

    # 对用户组
    ~] edquota -u group_01

    Disk quotas for user group_01 (gid 1002):
      Filesystem                   blocks       soft       hard     inodes     soft     hard
      /dev/vdb1                         0      10240      10240          0        0       10
      /dev/vdc1                         0      20480      20480          0        0       20
    
    # 或直接使用 setquota 配置
    setquota -u user_01 0 10240 0 10 /dev/vdb1
    setquota -g group_01 0 20480 0 20 /dev/vdb1
    ```

    * Filesystem - 配额针对的文件系统
    * blocks - 已使用的配额容量, 单位 KB
        * soft - 软限制 (警告值): 当使用量超过软限制，则会发出警告；如果使用量持续超过软限制，宽限时间(默认7天)过后，则会禁止使用磁盘
        * hard - 硬限制 (最大值)：使用量超过硬限制，禁止使用磁盘
    * inodes - 已使用的inodes
        * soft - 同blocks
        * hard - 同blocks

* 使配额生效/失效

    ```sh
    quotaon -augv
    quotaoff -augv
    ```

* 查看配额使用情况

    ```sh
    # 从用户、用户组角度查看
    quota -uvs user_01
    quota -gvs group_01

    # 从文件系统角度查看
    repquota -auvgs  #
    ```

* 被配额限制的提示信息

    ```info
    touch: cannot touch 'test': Disk quota exceeded

    vdb1: write failed, user block limit reached.
    -bash: echo: write error: Disk quota exceeded
    ```

* 其他信息

    ext4 文件系统的quota配额信息保存在 `aquota.group`, `aquota.user` 文件中，这两个文件存在该磁盘的根目录级别下（如上例 `/dir_01/aquota.group`, `/dir_01/aquota.user`）


## 方式二 - XFS文件系统

* 对 xfs 文件系统使用quota，可通过`xfs_quota`命令配置。
* xfs文件系统除了支持user、group配置配额，还可以以project形式配置配额
* There is no need for quota files in the root of the XFS filesystem. - 即不需要 `aquota.group`, `aquota.user` 文件

### 相关命令、参数介绍

> * Refer to: [RedHat KB](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/storage_administration_guide/xfsquota)
> * Refer to: [man 8 xfs_quota](https://linux.die.net/man/8/xfs_quota)

* `xfs_quota` 参数：

    ```sh
    xfs_quota [ -x ] [ -p prog ] [ -c cmd ] ... [ -d project ] ... [ path ... ]
    xfs_quota -V
    ```

    | 参数   | 说明                                              |
    | ------ | ------------------------------------------------- |
    | `-x`   | 启用专业模式，可使用管理命令                      |
    | `-p`   |                                                   |
    | `-c`   | 后面接命令，可多个`-c`同时使用                    |
    | `-d`   | 后面接project名字或者数字标识，可多个`-d`同时使用 |
    | `path` | 挂载点路径                                        |

* USER COMMANDs

    | 命令                                                         | 用途                              | 参数解释                                                                                                                                  |
    | ------------------------------------------------------------ | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
    | `print`                                                      | 列出所有路径，包括device和project |
    | `df`                                                         | =`free`                           |
    | `quota [-g\|-p\|-u] [-bir] [-hnNv] [-f file] [ID\|name]` ... | 显示配额信息                      | `-u`,`-g`,`-p` 指定用户/用户组/项目<br>`-b`,`-i`,`-r` 显示block/inode/实时数据??<br>`-h` 输出可读性<br>`-N` 不显示表头<br>`-f` 输出到文件 |
    | `free [-bir] [-hN] [-f file]`                                | 显示文件系统使用信息              |
    | `help [command]`                                             |                                   |                                                                                                                                           |
    | `quit`,`q`                                                   |                                   |                                                                                                                                           |

* ADMINISTATOR COMMANDs

    | 命令                                                                                       | 用途                                                                                | 备注                                                |
    | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- | --------------------------------------------------- |
    | `path [N]`                                                                                 | 列出所有路径                                                                        |                                                     |
    | `report [-gpu] [-bir] [-ahntlLNU] [-f file]`                                               | 查询文件系统配额信息                                                                |                                                     |
    | `state [-f file] [-av] [-f file]`                                                          | 查询所有配额信息                                                                    |                                                     |
    | `limit [-g\|-p\|-u] bsoft=N\|bhard=N\|isoft=N\|ihard=N\|rtbsoft=N\|rtbhard=N -d\|id\|name` | 配置配额                                                                            | N可以加单位                                         |
    | `timer [-g\|-p\|-u] [-bir] value`                                                          | 配置宽限时间                                                                        |                                                     |
    | `warn [-g\|-p\|-u] [-bir] value -d\|id\|name`                                              | 配置quota警告                                                                       | 如发送警告的次数                                    |
    | `enable [-gpu] [-v]`                                                                       | 启用配额                                                                            |                                                     |
    | `diable [-gpu] [-v]`                                                                       | 暂停配额                                                                            |                                                     |
    | `off [-gpu] [-v]`                                                                          | 关闭配额                                                                            |                                                     |
    | `remove [-gpu] [-v]`                                                                       | 移除所有配额                                                                        | 要在off的状态                                       |
    | `dump [-g\|-p\|-u] [-f file]`                                                              | 导出配额信息数据                                                                    |                                                     |
    | `restore [-g\|-p\|-u] [-f file]`                                                           | 从配额信息数据中恢复                                                                |                                                     |
    | `quot [-g\|-p\|-u] [-bir] [-acnv] [-f file]`                                               | 统计文件系统信息                                                                    |                                                     |
    | `project [-cCs [-d depth] [-p path] id\|name]`                                             | `-s` setup<br>`-C` clear<br>`-c` check<br>`-d` recursion level<br>`-p` 指定proj文件 | recursion level:<br>-1 infinite;0=top;1=first level |

    * `-d` - defaults

* 文件：`projects`, `projid`

    * `/etc/projects` - provides a mapping between numeric project identifiers and directories(the roots of quota tree).

        ```conf
        # comments
        10:/export/cage
        42:/var/log
        ```

    * `/etc/projid` - provides a mapping between numeric project identifiers and human readable names(similar to that username with uid).

        ```conf
        # comments
        cage:10
        logfiles:42
        ```

    * 启用 `prjquota`

        > 注：`prjquota`不能与 `grpquota` 同时配置

        ```sh
        mount -o prjquota /dev/vdc1 /dir_02
        ```


### 配额配置

* 挂载

    ```sh
    # Accounting=ON, Enforcement=ON
    mount -o usrquota,grpquota,prjquota /dev/vdc1 /dir_02
    mount -o uquota,gquota,pquota /dev/vdc1 /dir_02   # uquota=quota=usrquota
    
    # Accounting=ON, Enforcement=OFF
    mount -o uqnoenforce,gqnoenforce,pqnoenforce /dev/vdc1 /dir_02
    ```

* 查看配额功能是否启用

    ```sh
    xfs_quota -x -c "state"
    xfs_quota -x -c "state -u"  # 只查看 user
    xfs_quota -x -c "state -g"  # 只查看 group
    xfs_quota -x -c "state -p"  # 只查看 project


    # 输出
    User quota state on /dir_02 (/dev/vdc1)
      Accounting: ON
      Enforcement: ON
      Inode: #67 (1 blocks, 1 extents)
    Group quota state on /dir_02 (/dev/vdc1)
      Accounting: ON
      Enforcement: ON
      Inode: #68 (1 blocks, 1 extents)
    Project quota state on /dir_02 (/dev/vdc1)
      Accounting: ON
      Enforcement: ON
      Inode: #68 (1 blocks, 1 extents)
    Blocks grace time: [7 days]
    Inodes grace time: [7 days]
    Realtime Blocks grace time: [7 days]
    ```

* 配置配额

    * 查看当前配额配置情况：

        ```sh
        xfs_quota -x -c "report" /dir_02
        xfs_quota -x -c "report -ugp -b" /dir_02  # 同上

        xfs_quota -x -c "report -ugp -b" /dir_02  # 只查看block配额, -b 可省略
        xfs_quota -x -c "report -ugp -i" /dir_02  # 只查看inode配额

        xfs_quota -x -c "report -u" /dir_02       # 只查看user配额
        xfs_quota -x -c "report -g" /dir_02       # 只查看group配额
        xfs_quota -x -c "report -p" /dir_02       # 只查看project配额
        
        # -h 可读友好性
        ```

    * 通过user,group配置配额：

        ```sh
        # 1. 配置配额
        # block
        xfs_quota -x -c "limit -u bsoft=10M bhard=20M user_01" /dir_02
        xfs_quota -x -c "limit -g bsoft=10M bhard=20M group_01" /dir_02

        # inode
        xfs_quota -x -c "limit -u isoft=100 ihard=200 user_01" /dir_02
        xfs_quota -x -c "limit -g isoft=100 ihard=200 group_01" /dir_02


        # 2. 取消配置
        # 值设置为 0 即取消配额
        xfs_quota -x -c "limit -u bsoft=0 bhard=0 user_01" /dir_02
        ```

    * 通过project配置配额：

        * 编辑文件，创建project对应关系
        
            ```sh
            ~] vi /etc/projects
            10:/dir_02           # ID:目录

            ~] vi /etc/projid
            project_user_02:10   # 项目名:ID
            ```
        
        * 初始化project

            ```sh
            ~] xfs_quota -x -c 'project -s 10'

            Setting up project 10 (path /dir_02)...
            Processed 1 (/etc/projects and cmdline) paths for project 10 with recursion depth infinite (-1).
            Setting up project 10 (path /dir_02)...
            Processed 1 (/etc/projects and cmdline) paths for project 10 with recursion depth infinite (-1).
            Setting up project 10 (path /dir_02)...
            Processed 1 (/etc/projects and cmdline) paths for project 10 with recursion depth infinite (-1).
            
            ~] xfs_quota -x -c 'project -c 10'   # -c Check
            ```

            也可以不通过文件定义，直接在通过 `-p` 指定路径：

            ```sh
            xfs_quota -x -c 'project -s -p /dir_02 12'
            ```

            如何取消project：

            ```sh
            xfs_quota -x -c 'project -C 10'   # -C Clear
            ```

        * 配置配额

            ```sh
            xfs_quota -x -c 'limit -p bsoft=20M bhard=40M 10' /dir_02

            # 如何取消配置：设置为0即取消配额
            xfs_quota -x -c 'limit -p bsoft=0 bhard=0 10' /dir_02
            ```

