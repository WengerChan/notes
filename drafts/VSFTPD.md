# VSFTPD, Very Security FTP Daemon

vsftp 提供3种远程的登录方式：

* 匿名登录方式: 不需要用户名和密码

* 本地用户登录方式: 需要用户名和密码, 并且用户应该存在 Linux 系统里面

* 虚拟用户登录方式: 需要用户名和密码, 用户不在你 Linux 系统



## 安装与配置

* 安装

    ```sh
    yum install vsftpd   # vsftpd-3.0.2-25.el7.x86_64
    ```

* 启动服务

    ```sh
    iptables -I INPUT -p tcp -m multiport --dports 20,21 -j ACCEPT
    service iptables save
    service iptables restart 

    firewall-cmd --zone=public --add-service=ftp --permanent
    #firewall-cmd --zone=public --add-port=20-21/tcp --permanent
    firewall-cmd --reload
    ```

* 配置 VSFTPD

    VSFTPD 配置文件主要存放在 /etc/vsftpd/ 目录下: 

    |  文件名                                  | 作用                                                          |
    | ---------------------------------------- | ------------------------------------------------------------ |
    | `ftpusers`<sup id="aa1">[1](#ff1)</sup>    | 用户列表, 记录的用户不允许访问 FTP 服务器                       |
    | `user_list`<sup id="aa2">[2](#ff2)</sup>   | 用户列表, 作用取决于 `userlist_enbale`, `userlist_deny` 的配置 |
    | `vsftpd.conf`<sup id="aa3">[3](#ff3)</sup> | 默认主配置文件.                                               |
    | `vsftpd_conf_migrate.sh`                 | 脚本文件, 此文件可以忽略.                                      |

    * 文件默认配置: 

        * <b id="ff1">"/etc/vsftpd/ftpusers"</b> [↺](#aa1)

            ```text
            # Users that are not allowed to login via ftp
            root
            bin
            daemon
            adm
            lp
            sync
            shutdown
            halt
            mail
            news
            uucp
            operator
            games
            nobody
            ```

        * <b id="ff2">"/etc/vsftpd/user_list"</b> [↺](#aa2)

            ```text
            # vsftpd userlist
            # If userlist_deny=NO, only allow users in this file
            # If userlist_deny=YES (default), never allow users in this file, and
            # do not even prompt for a password.
            # Note that the default vsftpd pam config also checks /etc/vsftpd/ftpusers
            # for users that are denied.
            root
            bin
            daemon
            adm
            lp
            sync
            shutdown
            halt
            mail
            news
            uucp
            operator
            games
            nobody
            ```

        * <b id="ff3">"/etc/vsftpd/vsftpd.conf"</b> [↺](#aa3)

            ```sh
            anonymous_enable=YES
            local_enable=YES
            write_enable=YES
            local_umask=022
            dirmessage_enable=YES
            xferlog_enable=YES
            connect_from_port_20=YES
            xferlog_std_format=YES
            listen=NO
            listen_ipv6=YES
            pam_service_name=vsftpd
            userlist_enable=YES
            tcp_wrappers=YES
            ```


    * FTP 用户目录设置

        默认情况下, 本地用户登录以后进入用户家目录, 匿名用户登录以后进入 `/var/ftp`

        `local_root` 设置以后, 本地用户登录将统一进入设置的目录

    * FTP 访问控制

        * 用户限制: 通过 `ftpusers` 和 `user_list` 文件控制, 下文详解

        * IP 限制: 可通过 `TCP Wrappers` 控制, 不过需要 VSFTPD 配置 `tcp_wrappers=YES`

            ```sh
            # 设置该 IP 地址不可以访问 FTP 服务
            echo 'vsftpd:192.168.5.128:DENY' >> /etc/hosts.allow
            ```
        
        * 访问时间限制：要控制访问时间, 需要将 VSFTPD 托管给 `inetd`/`xinetd`

            ```sh
            ~] cp /usr/share/doc/vsftpd-1.1.3/vsftpd.xinetd /etc/xinetd.d/vsftpd
            
            ~] vi /etc/vsftpd/vsftpd.conf

            ...
            listen=NO
            ...

            ~] vi /etc/xinetd.d/vsftpd
            
            service ftp
            {
                    ...
                    disable                 = no
                    # access_time = hour:min-hour:min
                    access_time = 8:30-11:30 17:30-21:30
                    ...
            }
            ```

## 关于 VSFTPD 运行模式


* `stand-alone`

    表示配置 VSFTPD 守护进程, 持久的驻留在内存中, 由自身控制访问及资源

    开启此模式: 
    
    1. 删除 Xinetd 配置
    2. 主配置文件 `/etc/vsftpd/vsftpd.conf` 中设置 `listen=YES` 或者 `listen_ipv6=YES`


* `super-daemon`

    将 VSFTPD 托管给 Xinetd, 由 Xinetd 控制服务按需启动, 只在外部连接发送请求时才调用 VSFTPD 进程

    开启此模式: 
    
    1. 安装 Xinetd
    2. 将主配置文件 `/etc/vsftpd/vsftpd.conf` 中设置 `listen` 和  `listen_ipv6` 行删除或者修改为 "NO"
    3. 配置托管文件 `/etc/xinetd.d/vsftpd` 中 `disable = no`


## 关于 VSFTPD 服务模式



被动模式, PASV Style, passive mode

* 主动模式

    主动模式, PORT Style, active mode

    * 端口
    
        认证/命令/控制连接: 21

        数据传输: 20

    * 工作过程

        ```text
        1. 客户端以随机非特权端口 N, 就是大于 1024 的端口, 对服务端 21 端口发起连接;
        2. 客户端开始监听 N+1 端口;
        3. 服务端会主动以 20 端口连接到客户端的 N+1 端口 <= connect_timeout
        ```

    * 优/缺点

        优点: 服务端配置简单, 利于服务器安全管理, 服务器只需要开放 21 端口

        缺点: 如果客户端开启了防火墙, 或客户端处于内网 (NAT 网关之后), 那么服务器对客户端端口发起的连接可能会失败


* 被动模式

    * 端口
    
        认证/命令/控制连接: 21

        数据传输: 大于 1024 的随机端口

    * 工作过程

        ```text
        1. 客户端以随机非特权端口 N 对服务端 21 端口发起连接;
        2. 服务端开启一个非特权端口 M 为被动端口, 并返回给客户端;
        3. 客户端以 N+1 端口主动连接服务端的 M 端口
        ```

    * 优/缺点

        缺点：服务器配置管理稍显复杂, 不利于安全, 服务器需要开放随机高位端口以便客户端可以连接, 因此大多数 FTP 服务软件都可以手动配置被动端口的范围

        优点：对客户端网络环境没有要求


## 详解 `vsftpd.conf`

### Daemon Options



* `listen=NO`

* `listen_ipv6=NO`<sup id="a1">[1](#f1)</sup>

* `session_support=NO` — VSFTPD 尝试通过 PAM 为每个登录的用户 (开启 `pam_session`) 维护 login session (如更新 `utmp`, `wtmp`)

`listen` 或者 `listen_ipv6` 默认选项为 NO, 如果设置为 YES 表示开启 "stand-alone"; 此外, 如果需要同时监听 IPv4 和 IPv6 地址, `listen` 和 `listen_ipv6` 选项都需要指定

---

<b id="f1"><font size=1>1 虽然默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a1)


### Log In Options and Access Controls

* `anonymous_enable=YES` — 控制是否允许匿名登录; 如果启用, 用户名 `ftp` 和 `anonymous` 都会被识别成匿名登录
* `deny_email_enable=NO` — 控制是否启用匿名登录邮件地址(密码)过滤<sup id="a2">[2](#f2)</sup>
* `banned_email_file=/etc/vsftpd.banned_emails` — 邮件列表, 记录拒绝访问的邮件地址; 仅当 `deny_email_enable=YES` 时才生效

* `ftpd_banner=[String]` — 字符串, 设置 FTP 登录欢迎语
* `banner_file=/path/to/file` — 文件名, 设置 FTP 登录欢迎语; 该指令会覆盖 `ftpd_banner` 的配置

* `userlist_enable=NO`<sup id="a3">[3](#f3)</sup> — 控制是否通过用户列表控制用户登录 (注: 主配置文件初始配置为 "YES")
* `userlist_deny=YES` — 控制用户列表对用户的控制动作是: "YES" => Deny, "NO" => Allow
* `userlist_file=/etc/vsftpd/user_list` — 用户列表, 列表中的用户允许<sup>`userlist_deny=NO`</sup>/禁止<sup>`userlist_deny=YES`</sup>访问 FTP 

* `cmds_allowed=cmd1, cmd2, ...` 逗号分隔的列表, 设置允许执行的 FTP 命令, 未设置的命令都会被拒绝执行
* `pam_service_name=ftp`<sup id="a4">[4](#f4)</sup> — 设置 VSFTPD 的 PAM 服务名
* `tcp_wrappers=NO`<sup id="a5">[5](#f5)</sup> — 控制是否通过 TCP Wrappers 进行访问控制
* `local_enable=YES` — 控制是否允许本地用户方式登录, 注意 SELinux 权限

---

<b id="f2"><font size=1>2 虽然默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a2)  
<b id="f3"><font size=1>3 如果使用匿名登录, 会要求输入 Email Address</font></b> [↺](#a3)  
<b id="f4"><font size=1>4 RHEL 6 中, 默认值为 "vsftpd"; RHEL 7 中主配置文件初始配置为 "vsftpd"</font></b> [↺](#a4)  
<b id="f5"><font size=1>5 虽然默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a5)  


### Anonymous User Options

* `anon_mkdir_write_enable=NO` — 控制是否允许匿名登录用户拥有创建目录权限; 该指令需要配置 `write_enable=YES`
* `anon_upload_enable=NO` — 控制是否允许匿名登录用户拥有上传文件权限; 该指令需要配置 `write_enable=YES`
* `anon_root=/path/to/root` — 设置匿名用户登录后目录
* `anon_world_readable_only=YES` — 控制匿名用户只能下载设置了 "全局可读" 权限的文件
* `ftp_username=ftp` — 设置匿名用户对应的本地 FTP 用户
* `no_anon_password=NO` — 控制是否允许免密匿名登陆: "NO" => 不允许, "YES" => 允许
* `secure_email_list_enable=NO` — 控制是否启用匿名登录邮件地址(密码)过滤, "YES" => 只允许以 `/etc/vsftpd/email_passwords` 中的密码登录


### Local-User Options


* `chmod_enable=YES` — 控制是否允许本地用户通过 `SITE CHMOD` 命令修改文件权限 (仅对本地用户登录方式生效)



* `chroot_local_user=NO` — 控制是否将本地用户限制在某一目录<sup id="a6">[6](#f6)</sup>活动 ( 强制 `chroot` )

* `chroot_list_enable=NO` — 控制是否启用 chroot 用户列表

* `chroot_list_file=/etc/vsftpd/chroot_list` — chroot 用户列表

    * `chroot_list_enable=NO`:  则 `chroot_local_user`: `YES` => 所有本地用户限制在家目录活动; `NO` => 所有用户都不限制

    * `chroot_list_enable=YES`: 则 `chroot_local_user`: `YES` => 列表中用户不限制, 其他用户限制; `NO` => 列表中用户限制, 其他用户不限制

* `allow_wirteable_chroot=NO` — 控制是否允许用户 chroot 进入具有 `write` 权限的目录 <sup>[Probelm](###500-oops-vsftpd-refusing-to-run-with-writable-root-inside-chroot)</sup>



* `guest_enable=NO` — 控制是否将非匿名登录用户设置为 guest 身份用户<sup>由 `guest_username` 设置用户</sup>

* `guest_username=ftp` — 设置 guest 身份用户

* `local_root=/path/to/dir` — 设置本地用户登录 FTP 后进入的目录, 此指标会覆盖用户家目录

* `local_umask=077`<sup id="a7">[7](#f7)</sup> — 设置用户的 umask 值

* `passwd_chroot_enable=NO`:

* `user_config_dir=/path/to/dir` — 设置一个目录路径, 该目录下存放指定用户的专属配置 (该配置会覆盖 `/etc/vsftpd/vsftpd.conf` 全局配置)
    
    > 示例: 设置 `user_config_dir=/etc/vsftpd/user_conf`, 当 tom 用户登录时, 会尝试加载 `/etc/vsftpd/user_conf/tom` 配置

---

<b id="f6"><font size=1>6 "目录": 默认情况下, 本地用户登录后会切换到"家目录"; 当 "local_root" 指令时, 用户会切换到 "local_root" 设定的目录中 </font></b> [↺](#a6)  
<b id="f7"><font size=1>7 RHEL 6 中, 默认值为 "022"; 虽然 RHEL 7 中默认值为 "077", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a7)  


### Directory Options


* `dirlist_enable=YES` — 控制是否允许用户查看用户列表

* `dirmessage_enable=NO`<sup id="a8">[8](#f8)</sup> — 控制是否限制目录下消息文件: 进入目录时显示当前目录的消息文件, 默认为 `.message`, 可通过 `message_file` 指定

* `force_dot_files=NO` — 控制是否显示 `.` 开头的文件和目录, 除了 `.` 和 `..`

* `hide_ids=NO` — If enabled, all user and group information in directory listings will be displayed as "ftp".

* `message_file=.message` — 设置消息文件名

* `text_userdb_names=NO` — 控制是否将 UID 和 GID 显示成 User 和 Group 名

* `use_localtime=NO` — 控制是否使用本地系统时间, 而不是 GMT 时间

---

<b id="f8"><font size=1>8 RHEL 6 中, 默认值为 "YES"; 虽然 RHEL 7 中默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a8)  


### File Transfer Options


* `download_enable=YES` — 控制是否允许文件下载

* `chown_uploads=NO` — 控制是否修改匿名登录用户上传的文件所有权 (由 `chown_username` 指定用户)

* `chown_username=root` — 所有权用户

* `write_enable=NO`<sup id="a9">[9](#f9)</sup> — 控制是否允许执行修改 FS 的 FTP 命令, 如 `STOR`, `DELE`, `RNFR`, `RNTO`, `MKD`, `RMD`, `APPE`, `SITE`

---

<b id="f9"><font size=1>9 虽然默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a9)  


### Logging Options



* `xferlog_enable=NO`<sup id="a10">[10](#f10)</sup> — 控制是否记录 FTP 上传和下载详细信息到日志文件; 

* `xferlog_std_format=NO`<sup id="a11">[11](#f11)</sup> — 控制是否以 xferlog 格式<sup>wu-ftpd style</sup>记录日志到 `vsftpd_log_file`

* `xferlog_file=/var/log/xferlog` — 设置上传和下载日志文件名

* `dual_log_enable=NO` — 控制是否同时记录两份日志: 由 `xferlog_file`<sup>wu-ftpd style</sup> 和 `vsftpd_log_file`<sup>vsftpd style</sup> 指定的文件

* `syslog_enable=NO` — 控制是否将原先写入 `vsftpd_log_file` 的日志转至 syslog (facility: `FTPD`)

* `vsftpd_log_file=/var/log/vsftpd.log` — 设置 VSFTPD 标准日志文件名



* `log_ftp_protocol=NO` — 控制是否记录所有 FTP 请求和响应 (需要 `xferlog_std_format=NO`)

VSFTPD 日志的参考配置:

```text
xferlog_enable=YES
xferlog_std_format=YES
xferlog_file=/var/log/xferlog
dual_log_enable=YES
vsftpd_log_file=/var/log/vsftpd.log
```

---

<b id="f10"><font size=1>10 虽然默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a10)
<b id="f11"><font size=1>11 虽然默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a11) 



### Network Options


* `listen_port=21` — 设置 网络连接 的监听端口

* `listen_address=[IPv4]` — 默认为 `none`, 表示监听本机所有 IPv4 地址

* `listen_address6=[IPv6]` — 默认为 `none`, 表示监听本机所有 IPv6 地址



* `max_clients=0` — 设置 "stand-alone" 模式下允许的最大连接数

* `max_per_ip=2000` — 设置 "stand-alone" 模式下每个源 IP 允许的最大连接数

* `max_login_fails=3`



* `idle_session_timeout=20` — 设置最长空闲时间, 超时后连接中断 (单位 s)

* `data_connection_timeout=300` — 设置允许数据传输停止的最长时间, 超时后连接会中断 (单位 s)



* `anon_max_rate=0` — 设置匿名登录用户传输速率, 单位 bytes/s; "0" 表示不限制

* `local_max_rate=` — 设置本地登录用户传输速率, 单位 bytes/s; "0" 表示不限制



以下参数与 "主动模式" 和 "被动模式" 相关:



* `port_enable=YES` — 控制是否启用 主动模式

* `connect_from_port_20=NO`<sup id="a12">[12](#f12)</sup> — 控制主动模式数据传输使用 20 端口, 此时 VSFTPD 有较大权限

* `ftp_data_port=20` — 设置主动模式下数据连接的端口



* `pasv_enable=YES` — 控制是否启用 被动模式

* `pasv_address=[IP|Hostname]` — 设置被动模式下响应 FTP 操作命令的 IP 地址 (默认值为空, 表示从传入的套接字中取地址)

* `pasv_max_port=0` — 设置被动模式下随机端口最大值 (`<=65535`)

* `pasv_min_port=0` — 设置被动模式下随机端口最小值 (`>=1024`)

* `pasv_promiscuous=NO`<sup>混杂</sup> — 控制在被动模式是否关闭对数据连接的安全检查<sup id="a13">[13](#f13)</sup>

* `pasv_addr_resolve=NO` — 控制是否开启 "pasv_address" 主机名解析



* `connect_timeout=60` — 设置主动模式下客户端响应 数据连接 的时间量 (超时时间, 单位 s)

* `accept_timeout=60` — 设置被动模式下客户端建立 数据连接 的时间量 (超时时间, 单位 s)


---

<b id="f12"><font size=1>12 RHEL 6 中, 默认值为 "YES"; 虽然 RHEL 7 中默认值为 "NO", 但是主配置文件初始配置为 "YES"</font></b> [↺](#a12) 
<b id="f13"><font size=1>13 "检查": 数据连接的 IP 和网络连接 IP 是否相同</font></b> [↺](#a13)  


### Security Options


* `isolate_network=YES` — If enabled, `vsftpd` uses the `CLONE_NEWNET` container flag to isolate the unprivileged protocol handler processes, so that they cannot arbitrarily call `connect()` and instead have to ask the privileged process for sockets (the `port_promiscuous` option must be disabled).

* `isolate=YES` — If enabled, `vsftpd` uses the `CLONE_NEWPID` and `CLONE_NEWIPC` container flags to isolate processes to their IPC and PID namespaces to prevent them from interacting with each other.

* `ssl_enable=NO` — 控制是否开启 SSL, TLS

* `ssl_sslv2=NO` — SSL V2

* `ssl_sslv3=NO` — SSL V3

* `ssl_tlsv1=NO` —  TLS v1

* `ssl_tlsv1_1=NO` — TLS v1.1

* `ssl_tlsv1_2=YES` — TLS v1.2

* `ssl_request_cert=YES` — 控制是否向发起 SSL 连接的客户端索取证书<sup id="a14">[14](#f14)</sup>

* `require_cert=NO` — 控制是否所有的 SSL 连接都需要提供证书

* `validate_cert=NO` — 控制所有的客户端 SSL 连接提供的证书必须 "validate OK", ( Self-signed certs do not constitute OK validation. )

* `allow_anon_ssl=NO` — 控制是否允许匿名用户使用 SSL 连接


---

<b id="f14"><font size=1>14 "索取": 只发送 `request`, 并不是 `require`</font></b> [↺](#a14)  




## VSFTPD 问题处理

### 关于设置防火墙的问题


* 主动模式下, 客户端连接 TCP/21, 服务端通过 TCP/20 连接客户端的随机端口

    ```text
    -A INPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp --dport 21 -j ACCEPT
    -A OUTPUT -p tcp --sport 20 -j ACCEPT
    ```

* 被动模式下, 客户端连接 TCP/21, 客户端再通过其他端口连接服务端的随机端口

    > 常见现象: 客户端能够登录到, 但是 LIST 列出目录失败(超时)。

    被动模式下服务端没有打开临时端口让 client 连过来

    设置被动模式的端口范围, 例如 2000-3000 :

    ```text
    pasv_max_port=2000
    pasv_min_port=3000
    ```

    配置 iptables:

    ```text
    -A INPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
    -A INPUT -p tcp --dport 21 -j ACCEPT
    -A INPUT -p tcp --dport 2000:3000 -j ACCEPT
    ```


    如果不配置端口范围, 有一种 "临时打洞" 的方法 (来自网上, 未验证):

    ```sh
    ~] vi /etc/modprobe.d/vsftpd.conf

    alias ip_conntrack ip_conntract_ftp ip_nat_ftp

    ~] vi /etc/rc.local

    /sbin/modprobe ip_conntract
    /sbin/modprobe ip_conntrack_ftp
    /sbin/modprobe ip_nat_ftp
    ```

### 500 OOPS: vsftpd: refusing to run with writable root inside chroot

VSFTPD 从 2.3.5 之后增强了安全检查: 如果用户被限定在了其主目录下, 则该用户的主目录不能再具有写权限了! 如果检查发现还有写权限, 就会报该错误。

```
- Add stronger checks for the configuration error of running with a writeable root directory inside a chroot(). This may bite people who carelessly turned on chroot_local_user but such is life.
```

解决办法有以下三种:

* 关闭 VSFTPD 用户的 chroot
* 取消 VSFTPD 用户 chroot 的目录的 "写" 权限
* 添加一行配置: `allow_writeable_chroot=YES`


### SELinux 

For example, in order to be able to share files anonymously, the `public_content_t` label must be assigned to the files and directories to be shared. You can do this using the chcon command as `root`:

```sh
chcon -R -t public_content_t /path/to/directory
```

Similarly, if you want to set up a directory for uploading files, you need to assign that particular directory the `public_content_rw_t` label. 

```sh
chcon -R -t public_content_rw_t /path/to/directory
```

In addition to that, the `allow_ftpd_anon_write` SELinux Boolean option must be set to `1`. Use the setsebool command as `root` to do that:


```sh
setsebool -P allow_ftpd_anon_write=1
```

If you want local users to be able to access their home directories through FTP, which is the default setting on Red Hat Enterprise Linux 6, the `ftp_home_dir` or `tftp_home_dir` Boolean option needs to be set to `1`. If vsftpd is to be allowed to run in standalone mode, which is also enabled by default on Red Hat Enterprise Linux 6, the `ftpd_is_daemon` option needs to be set to 1 as well.<sup>检查未发现此 Boolean</sup>

```sh
setsebool -P tftp_home_dir 1
```

查看:

```sh
getsebool -a | grep ftp
```


* SELinux 排错

```sh
audit2why < /var/log/audit/audit.log     # 日志文件名

audit2allow -a /var/log/audit/audit.log  # -a: 指定日志文件名
audit2allow < /var/log/audit/audit.log 

# ============= ftpd_t ==============
#!!!! This avc is allowed in the current policy
allow ftpd_t default_t:dir { read write };

# 解释: 只需定义一个规则, 允许 ftpd_t 类型对 default_t 类型的目录拥有 read 和 write 权限, 即可解决这个问题
```



<sup id="a15">[15](#f15)</sup>
<sup id="a16">[16](#f16)</sup>
<sup id="a17">[17](#f17)</sup>
<sup id="a18">[18](#f18)</sup>
<sup id="a19">[19](#f19)</sup>
 
  
 
 
<b id="f15"><font size=1>15 </font></b> [↺](#a15)  
<b id="f16"><font size=1>16 </font></b> [↺](#a16)  
<b id="f17"><font size=1>17 </font></b> [↺](#a17)  
<b id="f18"><font size=1>18 </font></b> [↺](#a18)  
<b id="f19"><font size=1>19 </font></b> [↺](#a19) 