# I. 基本系统配置

## 1. 开始使用

### 1.1. 环境的基本配置

#### 1.1.1. 配置日期和时间简介

* chronyd
* ntpd

#### 1.1.2. 配置系统区域介绍

系统范围的区域设置保存在 `/etc/locale.conf `

```sh
# 列出可用的系统区域设置：
~]$ localectl list-locales

# 显示系统区域设置的当前状态：
~]$ localectl status

# 设置或更改默认系统区域设置：
~] localectl set-locale LANG=locale
```

#### 1.1.3. 配置键盘布局简介

```sh
# 列出可用的键映射：
~]$ localectl list-keymaps

# 显示 keymap 设置的当前状态：
~]$ localectl status

# 设置或更改默认系统键映射：
~] localectl set-keymap
```


### 1.2. 配置和检查网络访问

#### 1.2.1. 在安装过程中配置网络访问
#### 1.2.2. 使用 nmcli 在安装过程后管理网络连接

```sh
# 创建新连接：
~] nmcli con add type type of the connection "con-name" connection name ifname ifname interface-name the name of the interface ipv4 address ipv4 address gw4 address gateway address

# 修改现有连接：
~] nmcli con mod "con-name"

# 显示所有连接：
~] nmcli con show

# 显示活跃连接：
~] nmcli con show --active

# 显示特定连接的所有配置设置：
~] nmcli con show "con-name"
```

#### 1.2.3. 使用 nmtui 在安装过程后管理网络连接
#### 1.2.4. 在 Web 控制台中管理网络

### 1.3. 注册系统管理订阅的基础知识

### 1.4. 安装软件

```sh
# 列出所有可用存储库：
~] subscription-manager repos --list

# 列出所有当前启用的软件仓库：
~]$ yum repolist

# 启用或禁用存储库：
~] subscription-manager repos --enable repository
~] subscription-manager repos --disable repository
```


### 1.5. 在引导时启动 systemd 服务

### 1.6. 使用防火墙、SELinux 和 SSH 日志提高系统安全性

### 1.7. 管理用户帐户的基础知识

* 系统账户和普通账户

    对于系统帐户，1000 以下的用户 ID 被保留。

    对于普通帐户，使用从 1000 开始的 ID。但推荐做法是使用从 5000 开始的 ID。

    分配 ID 的指南可以在 /etc/login.defs 文件中找到。

    ```conf
    # Min/max values for automatic uid selection in useradd
    #
    UID_MIN         1000
    UID_MAX         60000
    # System accounts
    SYS_UID_MIN        201
    SYS_UID_MAX        999
    ```

* 将用户添加到组中

    ```sh
    ~] usermod -a -G group_name user_name
    ```

### 1.8. 使用 kdump 机制转储已清除内核

### 1.9. 执行系统救援并使用 ReaR 创建系统备份

> 当软件或硬件故障破坏操作系统时，您需要一种机制来救援系统。保存系统备份也很有用。红帽建议使用 Relax-and-Recover(ReaR)工具来满足这两个需求。

* 使用：

    ```sh
    # 安装
    yum install rear

    # 创建救援系统
    rear mkrescue
    ```

* Rear 包含完全集成的内置或内部备份方法，称为 NETFS。

    要使 ReaR 使用其内部备份方法，请将这些行添加到 `/etc/rear/local.conf` 文件中：

    ```conf
    BACKUP=NETFS
    BACKUP_URL=backup location
    ```

    您还可以将 ReaR 配置为在创建新归档时保留之前的备份归档，方法是在 `/etc/rear/local.conf` 中添加以下行：

    ```conf
    NETFS_KEEP_OLD_BACKUP_COPY=y
    ```

    要让备份递增，意味着每次运行时只备份更改的文件，将这一行添加到 /etc/rear/local.conf 中：

    ```conf
    BACKUP_TYPE=incremental
    ```

    > 有关使用 ReaR NETFS 内部备份方法的详情请参考 第 27.2.1 节 “内置备份方法”。



### 1.10. 使用日志文件来故障排除问题

* 系统日志消息由两个服务处理：

    * `systemd-journald` 守护进程 - 收集来自内核的消息、启动过程的早期阶段、标准输出以及守护进程在启动和运行过程中的错误，以及 syslog，并将消息转发到 rsyslog 服务以便进一步处理。
    * `rsyslog` 服务 - 按类型和优先级清理 syslog 消息，并将其写入 `/var/log` 目录中的文件，以持久存储日志。

* 系统日志消息根据包含的信息和日志类型保存在 /var/log 目录下的不同子目录中：

    * `/var/log/messages` - 除下面所述之外的所有 syslog 信息
    * `/var/log/secure` - 与安全性和身份验证相关的消息和错误
    * `/var/log/maillog` - 与邮件服务器相关的消息和错误
    * `/var/log/cron` - 与定期执行任务相关的日志文件
    * `/var/log/boot.log` - 与系统启动相关的日志文件

### 1.11. 访问红帽支持

## 2. 系统位置和键盘配置
### 2.1. 设置系统区域

系统范围的区域设置保存在 `/etc/locale.conf` 文件中，该文件在早期引导时由 systemd 守护进程读取。每个服务或用户都会继承 `/etc/locale.conf` 中配置的区域设置，单独程序或个人用户均覆盖它们。

`/etc/locale.conf` 的基本文件格式是一个以换行分隔的变量分配列表

* 可配置的选项

    | 选项          | 描述                                                   |
    | ------------- | :----------------------------------------------------- |
    | `LANG`        | 为系统区域设置提供默认值。                             |
    | `LC_COLLATE`  | 更改比较本地字母中字符串的函数行为。                   |
    | `LC_CTYPE`    | 更改字符处理和分类功能以及多字节字符函数的行为。       |
    | `LC_NUMERIC`  | 描述数字通常的打印方式，详情包括十进制点和十进制逗号。 |
    | `LC_TIME`     | 更改当前时间、24 小时与 12 小时的显示。                |
    | `LC_MESSAGES` | 确定用于写入到标准错误输出的诊断消息的区域设置。       |

```sh
# 显示当前状态
~]$ localectl status
  System Locale: LANG=en_US.UTF-8
      VC Keymap: us
     X11 Layout: n/a

# 列出可用的区域
localectl list-locales

# 设置区域
localectl set-locale LANG=locale
localectl set-locale LANG=en_GB.utf8
```

### 2.2. 更改键盘布局

```sh
# 可用的键映射
localectl list-keymaps

# 设置 Keymap
localectl set-keymap map  # 也会应用于 X11 窗口系统的默认键盘映射
localectl --no-convert set-keymap map # 此时不会应用于 X11

localectl set-x11-keymap map
localectl --no-convert set-x11-keymap map
```

### 2.3. 其它资源

## 3. 配置日期和时间

现代操作系统区分以下两种时钟：

* 实时时钟 (**RTC**)，通常称为**硬件时钟**（通常是系统板上的集成电路），完全独立于操作系统的当前状态并在计算机关机时运行。
* 系统时钟 （也称为**软件时钟**）由内核维护，其**初始值基于实时时钟**。引导系统且系统时钟初始化后，系统时钟就**完全独立于实时时钟**。

系统时间始终保持在统一世界时间 (UTTC)中，并根据需要在应用程序中转换为本地时间。*本地时间是当前时区的实际时间，考虑到夏天节省时间 (DST)*。实时时钟可以使用 UTC 或本地时间。建议 UTC。

Red Hat Enterprise Linux 7 提供了三个命令行工具，可用于配置和显示有关系统日期和时间的信息：

* `timedatectl` 工具，它是 Red Hat Enterprise Linux 7 中的新功能，是 systemd 的一部分。
* 传统的 `date` 命令.
* 用于访问硬件时钟的 `hwclock` 实用程序.


### 3.1. 使用 timedatectl 命令

```sh
# 查看
timedatectl

# 更改当前时间、日期
timedatectl set-time 23:26:00
timedatectl set-time 2021-12-21  # 不指定时间的情况下，时间会设置为 00:00:00

# 默认情况下，系统配置为使用 UTC；要将您的系统配置为在本地时间维护时钟
timedatectl set-local-rtc [y|n|1|0]

# 时区
timedatectl list-timezones
timedatectl set-timezone time_zone

# 启用与远程时间服务器同步
timedatectl set-ntp [yes|no]  # 可启用 chronyd 或 ntpd 服务，具体取决于安装了哪个服务
```

### 3.2. 使用 date 命令

```sh
# 查看
date   # 显示本地时间
date --utc|-u  # utc 时间
date +'format' # 按格式显示时间
    # 常见格式：
    # %H - HH 格式的小时（如 17）
    # %M - MM 格式的分钟（如 30）
    # %S - SS 格式的第二个版本（如 24）
    # %d - DD 格式的月日（如 16）
    # %m - MM 格式的月份（如 09）
    # %Y - YYYY 格式的年份（例如： 2016 年）
    # %Z - 时区缩写（如 CEST）
    # %F - YYYY-MM-DD 格式的完整日期（例如 2016-09-16）。此选项等于 %Y-%m-%d
    # %T - HH:MM:SS 格式的全职（例如 17:30:24）。这个选项等于 %H:%M:%S

# 更改
date --set YYYY-MM-DD # 不指定时间的情况下，时间会设置为 00:00:00
date --set HH:MM:SS  
date --set HH:MM:SS --utc 
```


### 3.3. 使用 hwclock 命令


```sh
# 显示当前日期和时间（本地时间）
~] hwclock
Tue 15 Apr 2017 04:23:46 PM CST   -0.329272 seconds   # CST - 时区缩写

# 设置
hwclock --set --date "dd mmm yyyy HH:MM"
hwclock --set --date "21 Oct 2016 21:17" --utc

# 同步
# 将硬件时钟设置为当前系统时间
hwclock --systohc  # sys -> hw
# 从硬件时钟设置系统时间
hwclock --hctosys  # hw -> sys
```

> `hwclock --systohc --utc` 命令的功能类似于 `timedatectl set-local-rtc false`，`hwclock --systohc --local` 命令是 `timedatectl set-local-rtc true` 的替代选择。

### 3.4. 其它资源

## 4. 管理用户和组

### 4.1. 用户和组介绍

* 保留的用户和组群 ID

    ```sh
    cat /usr/share/doc/setup*/uidgid
    ```

* 设置系统UID和GID范围

    ```sh
    ~] cat /etc/login.defs
    UID_MIN         1000
    UID_MAX        60000
    ...
    GID_MIN         1000
    GID_MAX        60000
    ```

### 4.2. 在图形环境中管理用户

### 4.3. 使用命令行工具

* 用户相关配置文件

    ```sh
    # /etc/passwd
    juan:x:1001:1001::/home/juan:/bin/bash  # x 表示系统正在使用shadow密码

    # /etc/shadow
    juan:!!:14798:0:99999:7:::    # !! 该字段将锁定帐户

    # /etc/group
    juan:x:1001:
    ```

* umask

    下图显示了 umask 0137 如何影响新文件的创建：

    ![](./pictures/RHEL7-系统管理员指南/Users_Groups-Umask_Example.png)


### 4.4. 其它资源

## 5. 访问控制列表

### 5.1. 挂载文件系统

### 5.2. 设置访问权限 ACL

* 访问ACL和默认ACL

    访问 ACL 是特定文件或目录的访问控制列表。
    
    默认 ACL 只能与目录关联；如果目录中的文件没有访问权限 ACL，它将使用目录的默认 ACL 规则。默认 ACL 是可选的。

* 设置ACL

    ```sh
    setfacl -m rules file  # 设置访问ACL
    setfacl -x rules file  # 删除
    setfacl -m d:o:rx /dir # 设置默认ACL
    getfacl <file|/dir> # 查看

    # rules:
    # 设置用户的访问权限 ACL
    u:uid:perms
    # 设置组的访问权限 ACL
    g:gid:perms
    # 设置有效的权利掩码
    m:perms
    # 为 组中不属于 文件的用户设置访问权限 ACL
    o:perms
    ```

### 5.3. 设置默认 ACL

### 5.4. 检索 ACL

### 5.5. 使用 ACL 归档文件系统

### 5.6. 与旧系统的兼容性

### 5.7. ACL 参考

## 6. 获取特权

# II. 订阅和支持

# III. 安装和管理软件

## 9. yum

### 9.1. 检查和更新软件包

* 更新

    ```sh
    yum check-update             # 检查更新
    yum update package_name      # 更新
    yum group update group_name  # 更新软件包组
    yum update                   # 更新所有软件包及其依赖项
    yum update --security        # 更新与安全相关的软件包
    yum update-minimal --security # 更新为包含最新安全更新的版本

    # e.g. 假设:
    # kernel-3.10.0-1 软件包安装在您的系统中；
    # kernel-3.10.0-2 软件包已作为安全更新发布；
    # kernel-3.10.0-3 软件包已作为程序错误修复更新发布。
    # 则:
    # yum update-minimal --security 将软件包更新至 kernel-3.10.0-2
    # yum update --security         将软件包更新为 kernel-3.10.0-3
    ```

* 自动更新软件包

    ```sh
    yum install yum-cron        # 安装 yum-cron

    # 配置文件
    /etc/yum/yum-cron.conf      # 用于日常任务
    /etc/yum/yum-cron-hourly.conf   # 用于每小时任务

    # 启用自动安装更新，编辑配置文件：
    apply_updates = yes         

    # 计划任务
    ~] cat /etc/cron.daily/0yum-daily.cron
    exec /usr/sbin/yum-cron

    ~] /etc/cron.daily/0yum-hourly.cron
    exec /usr/sbin/yum-cron /etc/yum-cron-hourly.conf
    ```

* 使用 ISO 和 Yum 离线升级系统

    ```sh
    # 创建挂载点
    mkdir mount_dir

    # 挂载ISO
    mount -o loop iso_name mount_dir

    # 将media.repo复制到 /etc/yum.repos.d/ 目录
    cp mount_dir/media.repo /etc/yum.repos.d/new.repo

    # 编辑 repo 文件
    ~] vi /etc/yum.repos.d/new.repo
    baseurl=file:///mount_dir

    # 更新
    yum update
    ```

### 9.2. 使用软件包

*  搜索、列出软件包

    ```sh
    yum search package                 # 搜索
    yum list all                       # 列出所有软件包
    yum list glob_expression           # 列出 glob 表达式匹配的已安装和可用软件包
    yum list installed glob_expression # 列出 glob 表达式匹配的已安装软件包
    yum list available glob_expression # 列出 glob 表达式匹配的可用软件包
    yum repolist                       # 列出存储库
    yum repoinfo
    yum repolist -v                    # 列出存储库，显示更多信息
    yum repolist [all|disabled|enabled]
    ```

* 安装、卸载软件包

    ```sh
    yum install package_name1 [package_name2]  # 安装具体的package
    yum install glob_expression                # 使用 glob 表达式安装多个名称相似的软件包
    yum install /usr/sbin/named                # 通过文件名安装（如果仅知道要安装的文件的名称，但不知道其软件包名称）

    yum remove totem  # 卸载可以使用 软件包名称、glob 表达式、文件列表、软件包提供者
    
    yum install-n package_name
    yum install-na name.architecture
    yum install-nevra name-epoch:version-release.architecture
    yum remove-n
    yum remove-na
    yum remove-nevra

    yum localinstall /path/to/package
    ```


### 9.3. 使用软件包组

```sh
yum groups summary              # 查看已安装组、可用组、可用环境组的数量
yum group list                  # 列出软件包组
yum group list hidden
yum group list --hidden         # 列出软件包组，更细粒度
yum group list ids
yum group list --ids            # 列出软件包组与软件包组id
yum group list glob_expression  # 列出指定的软件包组

yum group info glob_expression  # 显示软件包组信息
# 显示的软件包前符号含义：
#   - : 未安装包，不会将其作为包组的一部分安装
#   + : 包未安装，但将在下一次 yum 升级或 yum 组升级时安装
#   = : 包已安装并且作为包组的一部分安装
#   无符号 : 软件包已安装，但安装在软件包组之外; 这意味着 yum group remove 不会删除这些软件包
yum group mark install xxx
yum group mark remove xxx

yum group install "group name"
yum group install group_id
yum install @"group name"  # @ 可以标记软件包组; @^ 可以标记环境包组
yum install @group_id

yum group remove "group name"
yum group remove group_id
yum remove @"group name"
yum remove @group_id
```

### 9.4. 使用事务历史记录

* 查看

    ```sh
    yum history list
    yum history list all   # 列出所有
    yum history list 1..5  # 列出 1-5
    
    # ID: 标识特定事务的整数值
    # Login user: 用于启动事务的登录会话的用户名称。此信息通常显示为 Full Name <username> 。对于不是由用户发布的事务（如自动系统更新），则显示 System <unset>
    # Date and time: 事务执行的日期和时间
    # Action(s): 事务执行的操作列表
    # Altered: 受事务影响的软件包数量
    
    yum history summary   # 事务的摘要
    yum history summary start_id..end_id
    
    yum history package-list glob_expression  # 跟踪软件包历史记录
    yum history package-info glob_expression
    
    yum history info start_id..end_id  # 详细地显示特定的事务，id 参数是可选的，当省略它时，yum 会自动使用最后一个事务
    
    yum history addon-info id
    yum history addon-info last  # 还可以查看其他信息，如事务时使用的配置选项，或者从哪个存储库以及安装某些软件包的原因
    # config-main: 事务期间使用的全局 yum 选项
    # config-repos: 单个 yum 软件仓库的选项
    # saved_tx: the data that can be used by the "yum load-transaction" command in order to repeat the transaction on another machine
    yum history addon-info id config-main
    ```

    | Action     | Abbreviation | Description                                                   |
    | ---------- | ------------ | ------------------------------------------------------------- |
    | Downgrade  | D            | At least one package has been downgraded to an older version. |
    | Erase      | E            | At least one package has been removed.                        |
    | Install    | I            | At least one new package has been installed.                  |
    | Obsoleting | O            | At least one package has been marked as obsolete.             |
    | Reinstall  | R            | At least one package has been reinstalled.                    |
    | Update     | U            | At least one package has been updated to a newer version.     |
    
    | Altered Symbol | Description                                                                                                                  |
    | -------------- | ---------------------------------------------------------------------------------------------------------------------------- |
    | `<`            | Before the transaction finished, the rpmdb database was changed outside yum.                                                 |
    | `>`            | After the transaction finished, the rpmdb database was changed outside yum.                                                  |
    | `*`            | The transaction failed to finish.                                                                                            |
    | `#`            | The transaction finished successfully, but yum returned a non-zero exit code.                                                |
    | `E`            | The transaction finished successfully, but an error or a warning was displayed.                                              |
    | `P`            | The transaction finished successfully, but problems already existed in the rpmdb database.                                   |
    | `s`            | The transaction finished successfully, but the --skip-broken command-line option was used and certain packages were skipped. |

* 恢复和重复事务

    ```sh
    yum history undo id
    yum history redo id
    # undo和redo只会恢复或重复事务期间执行的步骤：
    #   如果安装了新软件包，则undo则会卸载；
    #   如果卸载了软件包，undo命令将再次安装它；
    #   如果是升级/降级，且旧/新软件包可用，则会将所有更新的软件包降级/升级到之前的版本。

    # 管理多个相同的系统时，yum 还允许您对其中一个系统执行事务，将事务详细信息存储在文件中，并在经过一段时间测试后，在剩余系统上重复同样的事务
    # 将事务详情保存到文件：
    yum -q history addon-info id saved_tx > file_name
    # 将此文件复制到目标系统后，重复事务：
    yum load-transaction file_name

    yum histroy rollback id # 将事务回滚
    # 假如有三个事务：安装A、安装B、安装C；则redo 1会重装A，undo 1会卸载A，rollback 1则会卸载B和C。

    yum history new  # 启用新的事务历史记录（/var/lib/yum/histroy 中会新生成文件）
    ```

### 9.5. 配置 Yum 和 Yum 存储库

* /etc/yum.conf

    `[main]`: 允许您设置具有全局效果的 yum 选项

    `[repository]`: 允许出现一个或多个，设置特定于存储库的选项；该部分定义的值会覆盖 `[main]` 部分中设置的值。

    示例:

    ```conf
    [main]
    cachedir=/var/cache/yum/$basearch/$releasever
    keepcache=0
    debuglevel=2
    logfile=/var/log/yum.log
    exactarch=1
    obsoletes=1
    gpgcheck=1
    plugins=1
    installonly_limit=5
    bugtracker_url=http://bugs.centos.org/set_project.php?project_id=23&ref=http://bugs.centos.org/bug_report_page.php?category=yum
    distoroverpkg=centos-release
    ```

    | 参数                                   | 含义                                       | 取值                                                                                                                                                                                                         |
    | -------------------------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
    | `assumeyes=value`                      | yum 是否提示确认操作                       | 0 - 提示确认（默认）<br>1 - 不提示确认                                                                                                                                                                       |
    | `cachedir=directory`                   | 设置 yum 存储其缓存和数据库文件的目录      | 默认为 `/var/cache/yum/$basearch/$releasever/`                                                                                                                                                               |
    | `debuglevel=value`                     | 指定 yum 生成的输出调试详情级别            | 范围0~10，其中0表示禁用，10最详细，默认值为2                                                                                                                                                                 |
    | `exactarch=value`                      | 安装时确定架构                             | 0 - 关闭<br> 1 - 开启（默认）                                                                                                                                                                                |
    | `exclude=package_name ...`             | 允许在安装或系统更新期间按关键字排除软件包 | 多个软件包以空格分割的，支持glob通配符                                                                                                                                                                       |
    | `gpgcheck=value`                       | 是否应对包执行 GPG 签名检查                | 0 - 禁止<br>1 - 启用（默认）<br>此处设置启用，依然可在`.repo`中针对软件库单独设置是否启用GPG检查                                                                                                             |
    | `group_command=value`                  | 设置安装软件包组时的行为                   | simple - 安装软件包组的所有成员<br>compat - 类似于simple，但yum upgrade也会安装自上一次upgrade以来添加到组中的软件包<br>objects - 跟踪之前安装的组，并区分作为组一部分安装的软件包和单独安装的软件包（默认） |
    | `group_package_types=package_type ...` | 设置安装软件包组时如何选择软件包           | 安装标记为optional、default、mandatory的软件包<br>默认选择default、mandatory                                                                                                                                 |
    | `history_record=value`                 | 设置是否记录事务历史记录                   | 0 - 不记录<br>1 - 记录（默认）                                                                                                                                                                               |
    | `installonlypkgs=package_list`         | 设置yum仅安装但不会更新的软件包列表        | 确保默认安装的软件包(参阅`man yum.conf`)在列表中，确保`installonly_limit`大于2                                                                                                                               |
    | `installonly_limit=value`              | 设置yum可同时安装的软件包数量              | 默认值5                                                                                                                                                                                                      |
    | `keepcache=value`                      | 安装成功后是否保留标头和软件包的缓存       | 0 - 不保留（默认）<br>1 - 保留                                                                                                                                                                               |
    | `logfile=file_name`                    | 指定日志输出的位置                         | 默认值`/var/log/yum.log`                                                                                                                                                                                     |
    | `max_connenctions=number`              | 并发连接的最大数量                         | 默认值5                                                                                                                                                                                                      |
    | `multilib_policy=value`                | 设置多个架构的软件包可用时的安装行为       | best - 安装最佳选择架构<br>all - 安装所有可能的架构<br>如AMD64中设置best，则会安装64-bit，设置all，则会安装i686和64-bit                                                                                      |
    | `obsoletes=value`                      | 是否启用 obsoletes 选项                    | 0 - 禁用<br>1 - 启用（默认）<br>如果启用，则软件包的spec文件中声明了obseletes另一个软件包，则安装该软件包时会替换另一个软件包                                                                                |
    | `plugins=value`                        | 启用或禁用 yum 插件                        | 0 - 全局禁用<br>1 - 全局启用（默认）<br>特定插件的配置文件中`enabled=0`字段可以设置是否启用该插件                                                                                                            |
    | `reposdir=directory`                   | 设置 `.repo` 文件存放目录                  | 如果没有设置，则使用 `/etc/yum.repos.d/`                                                                                                                                                                     |
    | `retries=value`                        | 返回错误之前应尝试检索文件的次数           | 默认值10，0表示一直重试                                                                                                                                                                                      |

* `[repository]`

    每个 `[repository]` 部分必须包含以下指令：

    * `[repository]`: 唯一存储库 ID
    * `name=repository_name`: 描述存储库的可读字符串。
    * `baseurl=repository_url`: 使用存储库数据目录所在目录。可设置 `ftp://`, `http://`, `file:///path`

    其他指令：

    * `enabled=value`: 是否启用。0 - 禁用，1 - 启用
    * `async=value`: 是否并行下载。auto - 如果可能则将使用并行下载（默认），on - 启用，off - 禁用

* 使用 Yum 变量

    * `$releasever` - 发行版本。从 `/etc/yum.conf` 配置文件中的 `distroverpkg=value` 行获取，如果没有此行，则从 `redhat-release` 中获得版本号来推断正确的值。
    * `$arch` - 系统的 CPU 架构。有效值包括：i586、i686 和 x86_64。
    * `$basearch` - 系统基本架构。例如，i386, x86_64。
    * `$YUM0-9` - 可用的变量

    自定义变量：如要设置变量 `var1=100`，那么需要在 `/etc/yum/vars/` 中新建名为 var1 的文件，然后文件内容为100。

    ```sh
    echo 100 > /etc/yum/vars/var1
    ```



```sh
```

```sh
```

### 9.6. yum 插件

### 9.7. 使用 Yum-cron 自动刷新软件包数据库和下载更新


### 9.8. 其它资源


# IV. 基础架构服务

## 10. 使用 systemd 管理服务

### 10.1. systemd 简介


### 10.2. 管理系统服务


### 10.3. 使用 systemd 目标

### 10.4. 关闭、托管和占用系统


### 10.5. 控制远程机器上的 systemd
### 10.6. 创建和修改 systemd 单元文件

### 10.7. 管理服务时的其他注意事项
### 10.8. 其它资源
## 11. 配置系统可访问性

### 11.1. 配置 brltty 服务
### 11.2. switch On Always Show Universal Access Menu
### 11.3. 启用 Festival Speech Synthesis 系统
## 12. OpenSSH

### 12.1. SSH 协议


### 12.2. 配置 OpenSSH


### 12.3. OpenSSH 客户端

### 12.4. 更多安全 Shell

### 12.5. 其它资源
## 13. tigervnc

### 13.1. VNC 服务器


### 13.2. 共享现有桌面
### 13.3. VNC Viewer


### 13.4. 其它资源


# V. 服务器

# VI. 监控和自动化

# VII. 使用 Bootloader 自定义内核

# VIII. 系统备份和恢复
