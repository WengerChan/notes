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

### 4.2. 在图形环境中管理用户

### 4.3. 使用命令行工具

### 4.4. 其它资源

## 5. 访问控制列表

### 5.1. 挂载文件系统

### 5.2. 设置访问权限 ACL

```sh
setfacl -m rules files  # 设置
setfacl -x rules files  # 删除
setfacl -m d:o:rx /share # 设置默认ACL
getfacl files # 查看

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

6.1. 使用 su 实用程序配置管理访问权限
6.2. 使用 sudo 实用程序配置管理访问权限
6.3. 其它资源
II. 订阅和支持

```sh
```
```sh
```
```sh
```
# II. 订阅和支持



# III. 安装和管理软件

# IV. 基础架构服务

# V. 服务器

# VI. 监控和自动化

# VII. 使用 Bootloader 自定义内核

# VIII. 系统备份和恢复
