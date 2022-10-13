# SSH

## 关于 `ssh_config`

### 配置文件优先级及格式

* 配置文件优先级

    * 1.command-line options
    * 2.user's configuration file (`~/.ssh/config`)
    * 3.system-wide configuration file (`/etc/ssh/ssh_config`)

* 配置文件的格式

    * 配置行写法

        ```sh
        config value
        config value1 value2
        ```

        or

        ```sh
        config=value
        config=value1 value2
        ```

    * 空行和以 `#` 开头的行会被忽略

    * 参数值区分大小写, 参数名不区分大小写


### `PATTERNs` 和 `TOKENs`

* `PATTERNs`

    部分配置项中可能会用到 `pattern`, 其规则(写法)如下:

    * 一个模式由零个或多个非空白字符组成; 多个模式组成模式列表

    * 符号的含义:

        |  | 含义 | 实例 |
        | -- | -- |
        | `*` | 匹配任意个任意字符 | `Host *.co.uk` |
        | `?` | 匹配任意一个字符 | `Host 192.168.0.?` |
        | `!` | 否定运算符 | |
        | `,` | 分割模式列表中多个模式 | `from="!*.dialup.example.com,*.example.com"` |


* `TOKENs`

    Arguments to some keywords can make use of tokens, which are expanded at runtime:

    | Arguments | Meanings |
    |  --  | :-- |
    | `%%` | A literal `%`. |
    | `%C` | Shorthand for `%l%h%p%r`. |
    | `%d` | Local user's home directory. |
    | `%h` | The remote hostname. |
    | `%i` | The local user ID. |
    | `%L` | The local hostname. |
    | `%l` | The local hostname, including the domain name. |
    | `%n` | The original remote hostname, as given on the command line. |
    | `%p` | The remote port. |
    | `%r` | The remote username. |
    | `%u` | The local username. |

    * `Match exec`: accepts the tokens `%%`, `%h`, `%L`, `%l`, `%n`, `%p`, `%r`, and `%u`.
    * `CertificateFile`: accepts the tokens `%%`, `%d`, `%h`, `%l`, `%r`, and `%u`.
    * `ControlPath`: accepts the tokens `%%`, `%C`, `%h`, %i, `%L`, `%l`, `%n`, `%p`, `%r`, and` %u`.
    * `HostName`: accepts the tokens `%%` and `%h`.


### `Host`, `Match`

* `Host`, 标识一个组

    ```text
    Host <标识符>
        ...
    ```

    * 标识符, 作为整个组的标识(直到下个`Host`/`Match`出现); 可以理解为名字; 

    * 标识符可以有多个, 用空格隔开;

        ```text
        Host rhel-79 rhel-7
            HostName 192.168.1.201
            User root
            Port 22
        ```

    * 可以结合`PATTERN`的运算符号, 写出多种配置

        示例: *匹配任何 `-79` 结尾主机, 除了 `rhel-79`*

        ```sh
        Host *-79 !rhel-79
            HostName 192.168.1.201
            User root
            Port 22
        ```

* `Match`, 引入匹配块

    > 不常用, 只做介绍

    * 支持的关键字:
        * `all`
        * `criteria`<sup>条件, 准则</sup>类: `canonical`, `exec`, `host`, `originalhost`, `user`, and `localuser`
            * `exec`: 执行命令返回值为 0
            * `user`: 匹配到用户
            * `host`: 匹配到主机

    * 示例:

        示例1: *如果是来自 `qwer` 用户 ssh 连接, 将其由 `192.168.1.202` 代理连接*

        ```sh
        Match User qwer
            ProxyCommand ssh root@192.168.1.202 -W %h:%p
        ```

        ```sh
        ~]$ ssh qwer@192.168.1.201
        Last login: Sat May 29 21:39:51 2021 from 192.168.1.202    # <= 登陆来自192.168.1.202

        qwer ~]$ w
        21:39:51 up  3:53,  1 users,  load average: 0.00, 0.01, 0.05
        USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
        qwer     pts/1    192.168.1.202    21:34    1.00s  0.06s  0.04s w      # <= 登陆来自192.168.1.202
        ```

        示例2: *如果是来自 `qwer` 用户的 ssh 连接, 并且源 IP 是 `192.168.1.*`, 将其由 `192.168.1.202` 代理连接*

        ```sh
        Match User qwer, Exec "echo %h | grep 192.168.1."
            ProxyCommand ssh root@192.168.1.202 -W %h:%p
        ```

### 常见参数

| 参数名 |  取值[默认值] | 解释 |
|  ---  | --- | :-- |
| `AddKeysToAgent` | `yes,confirm,ask,[no]` | 添加key到ssh agent |
| `AddressFamily`  | `[any],inet,inet6` | address family |
| `BatchMode`      | `yes,[no]` | yes表示不提示输入密码,而是直接失败,避免批处理卡住 |
| `BindAddress`    | `NULL` | `UsePrivilegedPort=yes`时不生效 |
| `CertificateFile` |  | 证书 |
| `CheckHostIP` | `[yes],no` | 检查目标Host key是否因DNS欺骗(spoof)而改变, 并添加到`~/.ssh/known_hosts` |
| `Cipher` | | Specifies the cipher to use for encrypting the session in protocol version 1. |
| `Ciphers` | | Specifies the ciphers allowed for protocol version 2 in order of preference. |
| `Compression` | `yes,[no]` | Specifies whether to use compression. |
| `CompressionLevel` | `1(fast)~9(slow, best)[6]` | the compression level |
| `ConnectionAttempts` | `<Integer>,[1]` | 每秒尝试连接次数 |
| `ConnectTimeout` | `<TCP-TIMEOUT>` | 连接超时时间, 默认使用TCP超时时间 |
| `EscapeChar` | `~` | 设置ssh的逃逸符号(作用可使用`~?`查看) |
| `ForwardAgent` | `yes,[no]` | 设置连接是否经过"认证代理"(如果存在)转发给远程计算机 |
| `ForwardX11` | `yes,[no]` | 设置X11连接是否被自动重定向到安全的通道和显示集(DISPLAY set) |
| `ForwardX11Timeout` | `[20](min)` | 设置不受信的x11连接的超时时间 |
| `ForwardX11Trusted` | `yes,[no]` | 设置是否将x11连接设置为受信(完全访问权限) |
| `GatewayPorts` | `yes,[no]` | 设置是否允许转发端口 |
| `HostKeyAlgorithms` | | 指定期望目标主机提供的algorithms |
| `HostName` | | 主机名/IP |
| `Include` | | Include the specified configuration file(s) |
| `KexAlgorithms` | | Specifies the available KEX (Key Exchange) algorithms |
| `LocalCommand` | | 设定本地执行的命令, 执行正常才发起连接 |
| `LocalForward` | `[bind_address:]port host:hostport` | 本地转发端口, 需要提供两个参数 |
| `LogLevel` | `[INFO]` | QUIET,FATAL,ERROR,INFO,VERBOSE,DEBUG,DEBUG1,DEBUG2,DEBUG3 |
| `MACs` | | Specifies the MAC algorithms in order of preference. |
| `NumberOfPasswordPrompts` | `3` | 设置允许尝试输入密码的次数 |
| `PasswordAuthentication` | `[yes],no` | 是否使用密码认证 |
| `PermitLocalCommand` | `yes,[no]` | 是否允许`LocalCommand`设置的命令执行 |
| `Port` | `22` | ssh连接端口 |
| `PreferredAuthentications` | | 设置认证顺序 |
| `Protocol` | `[2],1` | 设置protocol:可以单独设置1/2,也可以设置2,1顺序 |
| `ProxyCommand` | | Specifies the command to use to connect to the server |
| `PubkeyAcceptedKeyTypes` | | 设置公钥认证支持的类型(逗号分隔)) |
| `PubkeyAuthentication` | `[yes],no` | 是否使用公钥认证 |
| `RemoteForward` | `[bind_address:]port host:hostport` | 远程转发端口, 需要提供两个参数 |
| `RevokedHostKeys` | | 指定撤销的主机公钥(文件);即该文件中的公钥不能用主机认证 |
| `RequestTTY` | `yes,no,force,auto` | Specifies whether to request a pseudo-tty for the session. |
| `RhostsAuthentication` | `[yes],no` | 设置是否使用基于rhosts的安全验证 |
| `RhostsRSAAuthentication` | `yes,[no]` | 设置是否使用用RSA算法的基于rhosts的安全验证 |
| `RSAAuthentication` | `[yes],no` | 设置是否使用RSA认证(仅Protocol 1) |
| `SendEnv` | | 设置发送的环境变量 |
| `ServerAliveCountMax` | `3` | 设置ssh后台发送server alive messages数量 |
| `ServerAliveInterval` | `0` | 设置ssh后台发送server alive messages间隔, 0表示不发送 |
| `StrictHostKeyChecking` | `yes,no,[ask]` | 优先级低于`CheckHostIP` |
| `TCPKeepAlive` | `[yes],no` | 设置是否发送TCP keepalive messages |
| `UpdateHostKeys` | `yes,[no],ask` | 是否允许更新替换host key |
| `UsePrivilegedPort` | `yes,[no]` | Specifies whether to use a privileged port for outgoing connections.|
| `User` | | 用于登陆的用户 |
| `UserKnownHostsFile` | `~/.ssh/known_hosts{,2}` | 设置known_hosts |
| `VerifyHostKeyDNS` | `yes,[no],ask` | 是否通过DNS确认Host key |
| `XAuthLocation` | `/usr/bin/xauth` | Specifies the full pathname of the `xauth` program |

EXAMPLE:

```sh
PubkeyAcceptedKeyTypes +ssh-rsa
Host rhel511
    HostName 192.168.1.51
    User root
    Port 22
    KexAlgorithms diffie-hellman-group1-sha1

Host <name>
    HostName 192.168.1.202
    User <user>
    Port <port>
    ProxyCommand ssh <cloud-user>@<cloud-host> -W %h:%p

# <name>: 是一个方便记得本地登录服务器用的名称, 自己决定即可
# <user>: 登录服务器使用的用户名
# <Port>: 映射端口号, 一般22
# <cloud-user>: 登录跳板机使用的用户名
# <cloud-host>: 跳板机的hostname或ip地址
```


## 端口转发

```sh
ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface] [-b bind_address] [-c cipher_spec] [-D [bind_address:]port] [-E log_file] [-e escape_char] [-F configfile]
         [-I pkcs11] [-i identity_file] [-J destination] [-L address] [-l login_name] [-m mac_spec] [-O ctl_cmd] [-o option] [-p port] [-Q query_option] [-R address]
         [-S ctl_path] [-W host:port] [-w local_tun[:remote_tun]] destination [command]
# -f ssh在执行命令前退至后台(后台启用)
# -N 不打开远程shell, 处于等待状态, 用于转发端口（不加-N则直接登录进去）
# -g 允许远端主机连接本地的转发端口 (支持多主机访问本地侦听端口)
# -L 将本地主机的地址和端口接收到的数据通过安全通道转发给远程主机的地址和端口
# -R 将远程主机上的地址和端口接收的数据通过安全通道转发给本地主机的地址和端口
# -D 动态转发
```

### 本地端口转发

接收本地端口(Local Port)数据, 转发到远程端口(Remote Port)

* 格式

    ```sh
    ssh -L [Local IP:]<Local Port>:<Remote IP>:<Remote Port> [User@]<Remote IP>
    ```

* 示例1: `ServerA:8080 =22=> ServerB:127.0.0.1:80`

    * ServerB 只允许本地 127.0.0.1 访问 nginx 的 80 端口
    * ServerA 可以连接 ServerB 的 22 端口
    * 实现: 将 ServerA 的 8080 端口转发到 ServerB 的 127.0.0.1:80 端口, 这样外部可以通过访问 ServerA-IP:8080 访问到 ServerB 的 nginx

        ```text
             +------------------------+------------------------+
             |        Server A        |        Server B        |
             |........................|........................|
        ---> |:8080 <--+              |       +--> 127.0.0.1:80|
             |         |              |       |                |
             |         +--> Port <--> |:22 <--+                |
             +------------------------+------------------------+
        ```

        ```sh
        ServerA> ssh -Nf -L 0.0.0.0:8080:127.0.0.1:80 User@ServerB-IP
        ```

* 示例2: `ServerA:8022 =22=> ServerB:22 =22=> ServerC:22`

    * ServerA 可以访问 ServerB 的 22 端口, 而与 ServerC 网络隔离;
    * ServerB 可以访问 ServerC 的 22 端口;
    * 实现: ServerA ssh 连接本地 8022 端口, 即可完成 ssh 访问到 ServerC 的 22 端口

        ```sh
        ServerA> ssh -Nf -L 127.0.0.1:8022:<ServerC-IP>:22 User@ServerB-IP
        ```


### 远程端口转发

接收远程端口(Remote Port)数据, 转发到服务端口(Server Port)

* 格式

    ```sh
    ssh -L [Remote IP:]<Remote Port>:<Server IP>:<Server Port> [User@]<Remote IP>
    ```

* 示例1: `ServerA <=22,6666= ServerB =7777=> ServerC`

    * ServerB 可以访问 ServerA 的 22 和 6666 端口;
    * ServerB 可以访问 ServerC 的 7777 端口;
    * ServerA 与 ServerC 网络隔离
    * 实现: ServerA 的 6666 端口与 ServerC 的 7777 端口通信

        ```sh
        ServerB> ssh -Nf -R <ServerC-IP>:7777:<ServerA-IP>:6666 <ServerC-IP>

        # 1. ServerC可以查询到7777端口监听, 用nc查看7777端口输出
        nc -v 127.0.0.1 7777

        # 2. ServerA手动配置监听6666端口
        nc -l 6666

        # 3. ServerA与ServerC互发信息能够相互接收
        ServerC> nc -v 127.0.0.1 7777
        Ncat: Version 7.50 ( https://nmap.org/ncat )
        Ncat: Connected to 127.0.0.1:7777.
        hello
        this is ServerA

        ServerA> nc -l 6666
        hello
        this is ServerA
        ```


### 动态端口转发

对于 "本地端口转发" 和 "远程端口转发", 都存在两个一一对应的端口, 分别位于SSH的客户端和服务端, "动态端口转发" 则只是绑定了一个本地端口, 而 `<Server IP>:<Server Port>` 则是不固定的。

`<Server IP>:<Server Port>` 是由发起的请求决定的, 比如, 请求地址为 `192.168.1.100:3000`, 则通过SSH转发的请求地址也是`192.168.1.100:3000`。

* 格式

    ```sh
    ssh -D [Local IP:]<Local port> [User@]<Remote IP>
    ```

    通过动态端口转发, 可以将在本地主机ServerA发起的请求, 转发到远程主机ServerB, 而由ServerB去真正地发起请求。

* 示例

    实现通过本地主机 ServerA 2000端口代理访问远程主机 ServerB 的动态端口

    ```sh
    ServerA> ssh -D localhost:2000 root@<ServerB-IP>
    ```

    在本地发起的请求, 需要由 Socket 代理(Socket Proxy)转发到SSH绑定的2000端口。以Firefox浏览器为例, 配置Socket代理需要找到 `首选项 > 高级 > 网络 > 连接 -> 设置`



## 关于 `internal-sftp`

internal-sftp 可以实现对用户 SFTP 连接的灵活限制


* 限制用户通过 SFTP 连接到指定目录, 并且无法 SSH 连接至服务器

    完成改功能需要两步配置: 

    * *Step 1*: 修改 `/etc/ssh/sshd_config`

        ```sh
        ~] vi /etc/ssh/sshd_config

        #Subsystem      sftp   /usr/libexec/openssh/sftp-server  <===注释这一行
	
        Subsystem	sftp	internal-sftp
        Match User sftpuser01
        		ChrootDirectory /data03
        		ForceCommand internal-sftp
        		X11Forwarding no
        		AllowTcpForwarding no
        ```

        - `Match`: 匹配块, 只有匹配的用户才受后续配置影响; `Match GroupA,GroupB` 匹配用户组, `Match user userA,userB` 匹配用户

        - `ChrootDirectory`: 设置 Chroot 目录, 即用户的 "根目录"; 可用 `%h` 代表用户家目录, `%u` 代表用户名

        - `ForceCommand internal-sftp`: 强制执行命令 `internal-sftp`, 并忽略任何 `~/.ssh/rc` 文件配置; 可以为 `internal-sftp` 命令指定参数, 如 `-u`, `-m`等

        - `AllowTcpForwarding`: 是否允许 TCP 转发, 默认值为 "yes"

        - `X11Forwarding no`: 是否允许进行 X11 转发, 默认值是 "no"


    * *Step 2*: 配置目录的权限

        ```sh
        ~] ll /data03 -d
        
        drwxr-x---    10 root root    118784  12月 31 17:17 /data03
        ```

        目录权限设置上要遵循2点：

        - `ChrootDirectory` 设置的 *根目录及其所有的上级目录* 权限, 属主和属组必须是 root (经测试, 配置属主为 `root` 即可)

        - `ChrootDirectory` 设置的 *根目录及其所有的上级目录* 权限, 只有属主能拥有写权限, 权限最大设置只能是 `755`。


    * Match

        The arguments to Match are one or more criteria-pattern pairs or the single token All which matches all criteria.  The available criteria are User, Group, Host, LocalAddress, LocalPort, and Address.  The match patterns may consist of single entries or comma-separated lists and may use the wildcard and negation operators described in the PATTERNS section of ssh_config(5).

        Available keywords are: 
        `AcceptEnv`, `AllowAgentForwarding`, `AllowGroups`, `AllowStreamLocalForwarding`, `AllowTcpForwarding`, `AllowUsers`, `AuthenticationMethods`, `AuthorizedKeysCommand`, `AuthorizedKeysCommandUser`, `AuthorizedKeysFile`, `AuthorizedPrincipalsCommand`, `AuthorizedPrincipalsCommandUser`, `AuthorizedPrincipalsFile`, `Banner`, `ChrootDirectory`, `ClientAliveCountMax`, `ClientAliveInterval`, `DenyGroups`, `DenyUsers`, `ForceCommand`, `GatewayPorts`, `GSSAPIAuthentication`, `HostbasedAcceptedKeyTypes`, `HostbasedAuthentication`, `HostbasedUsesNameFromPacketOnly`, `IPQoS`, `KbdInteractiveAuthentication`, `KerberosAuthentication`, `KerberosUseKuserok`, `MaxAuthTries`, `MaxSessions`, `PasswordAuthentication`, `PermitEmptyPasswords`, `PermitOpen`, `PermitRootLogin`, `PermitTTY`, `PermitTunnel`, `PermitUserRC`, `PubkeyAcceptedKeyTypes`, `PubkeyAuthentication`, `RekeyLimit`, `RevokedKeys`, `StreamLocalBindMask`, `StreamLocalBindUnlink`, `TrustedUserCAKeys`, `X11DisplayOffset`, `X11MaxDisplays`, `X11Forwarding` and `X11UseLocalHost`.

* 实际案例

    实现：

    > 1. 指定专用目录作为sftp目录, 读写只在该目录中完成；
    > 2. 用户权限分离, 对于允许的用户：部分用户可读写, 部分用户只读；对于不允许的用户, 不允许读写；
    > 3. 针对后续新增的文件和文件夹, 满足条件1


    * 创建案例中使用用户组

        ```sh
        groupadd -g 1000 sftp_group_rw    # sftp用户组, 该组用户拥有读写权限
        groupadd -g 2000 sftp_group_read  # sftp用户组, 该组用户拥有只读权限
        ```

    * 创建目录

        例如使用如下目录结构时:

        ```text
        /data/
        ├── dir01/
        │   ├── file01
        │   ├── file02
        │   ├── sub_dir/
        │   │   ├── file03
        │   │   └── file04
        │   └── test_dir/
        ├── dir02/
        │   ├── file05
        │   └── file06
        ├── file07
        └── file08
        ```


        ```sh
        mkdir -p /data

        mkdir -p /data/dir01/sub_dir
        touch /data/dir01/file{01,02}
        touch /data/dir01/sub_dir/file{03,04}

        mkdir -p /data/dir02
        touch /data/dir02/file{05,06}

        touch /data/file{07,08}
        ```

    * 修改目录权限:
      
        * /data 目录: 属主: `root`, 属组: `sftp_group_rw`, 权限: `750`
        * /data 下
            * 目录: 属主: `<USERNAME>`, 属组: `sftp_group_rw`, 权限: `775`
            * 文件: 属主: `<USERNAME>`, 属组: `sftp_group_rw`, 权限: `664`

        ```sh
        chown root:sftp_group_rw /data
        chmod 750 /data

        chown -R <USERNAME>:sftp_group_rw /data/*
        find /data/* -type 'd' | xargs chmod 775 
        find /data/* -type 'f' | xargs chmod 664 
        ```

    * 修改 sshd_config

        ```sh
        ~] vim /etc/ssh/sshd_config
        # Subsystem     sftp    /usr/libexec/openssh/sftp-server
        Subsystem       sftp    internal-sftp
        Match Group sftp_group_rw
                ChrootDirectory /data
                ForceCommand internal-sftp -u 0002 -m 664
                X11Forwarding no                         
                AllowTcpForwarding no
        Match Group sftp_group_read
                ChrootDirectory /data
                ForceCommand internal-sftp -R
                X11Forwarding no
                AllowTcpForwarding no
        ```

        注:

        * `-u 0002 -m 664`: 指定用户的umask和新创建文件的权限, 可以保证新创建目录权限775, 新创建文件权限664
        * `-R`: 开启只读模式
        * 经测试, 通过put -r递归上传的目录, 权限与源目录一致, 不受 "`-u`" 配置影响; 文件却会受 "`-m`" 影响

    * 修改目录 acl 及 SGID

        ```sh
        ~] setfacl -m g:sftp_group_read:r-x /data
        ~] chmod g+s /data

        ~] ls -ld /data
        drwxr-x---+ 4 root sftp_group_rw 60 Feb 22 21:54 /data

        ~] getfacl /data
        getfacl: Removing leading '/' from absolute path names
        # file: data
        # owner: root
        # group: sftp_group_rw
        # flags: -s-
        user::rwx
        group::r-x
        group:sftp_group_read:r-x
        mask::r-x
        other::---
        ```

## 关于 sftp 日志

### 使用 sftp-server

* 不指定日志文件，记录到 `/var/log/messages`

    编辑 `/etc/ssh/sshd_config`:

    ```text
    Subsystem   sftp    /usr/libexec/openssh/sftp-server -l VERBOSE
    ```

    重启sshd服务，查看 `/var/log/messages`:

    ```log
    Mar  9 09:39:07 localhost sftp-server[1829]: received client version 3
    Mar  9 09:39:07 localhost sftp-server[1829]: realpath "."
    Mar  9 09:39:09 localhost sftp-server[1829]: lstat name "/root"
    ```

* 自定义日志文件

    编辑 `/etc/ssh/sshd_config`:

    ```text
    Subsystem   sftp    /usr/libexec/openssh/sftp-server -l VERBOSE -f LOCAL3
    ```

    编辑 `/etc/rsyslog.conf`:

    ```text
    local3.*                                                /var/log/sftp.log
    ```

    重启sshd、rsyslog服务，查看 `/var/log/sftp`:

    ```log
    Mar  9 09:49:02 localhost sftp-server[1947]: received client version 3
    Mar  9 09:49:02 localhost sftp-server[1947]: realpath "."
    Mar  9 09:49:04 localhost sftp-server[1947]: lstat name "/root"
    ```

    * 如果要使日志只记录在指定的 `/var/log/sftp.log` 文件中, 按以下配置：

        ```text
        ...
        local3.*                        /var/log/sftp.log
        &~
        *.info;mail.none;authpriv.none;cron.none                /var/log/messages
        ```

        由于 `&~` 的存在，后续的日志不会重复。

### 使用 internal-server

* 不指定日志文件，记录到 `/var/log/secure` 或 `/var/log/messages`

    编辑 `/etc/ssh/sshd_config`:

    ```text
    #Subsystem   sftp    /usr/libexec/openssh/sftp-server
    Subsystem   sftp    internal-sftp -l VERBOSE
    Match User user_01
        ChrootDirectorty /data/user_01
    ```

    如果用户被 `Match` 匹配并 `Chroot`，则日志记录到 `/var/log/secure`，如使用 user_01 时:

    ```log
    Mar  9 09:50:02 localhost sshd[2366]: pam_unix(sshd:session): session opened for user user_01 by (uid=0)
    Mar  9 09:50:02 localhost sshd[2366]: session opened for local user user_01 from [192.168.161.1] [postauth]
    Mar  9 09:50:02 localhost sshd[2366]: received client version 3
    Mar  9 09:50:02 localhost sshd[2366]: opendir "/" [postauth]
    Mar  9 09:50:04 localhost sshd[2366]: close "/" [postauth]
    ```

    其余用户日志记录到 `/var/log/messages`，如使用 user_02 时:

    ```log
    Mar  9 09:51:02 localhost systemd-logind: New session 46 of user user_02.
    Mar  9 09:51:02 localhost internal-sftp[2381]: session opened for local user user_02 from [192.168.161.1]
    Mar  9 09:51:02 localhost internal-sftp[2381]: received client version 3
    Mar  9 09:51:02 localhost internal-sftp[2381]: realpath "."
    Mar  9 09:51:04 localhost internal-sftp[2381]: opendir "/home/user_02"
    Mar  9 09:51:04 localhost internal-sftp[2381]: close "/home/user_02"
    ```

* 指定日志文件

    `/etc/ssh/sshd_config` 配置不变，编辑 `/etc/rsyslog.conf`:

    ```
    ```