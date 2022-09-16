# Netfilter - iptables

## 相关概念

* 规则链与规则表

    * 规则链


        | Chains      | Notes                                             |
        | ----------- | :------------------------------------------------ |
        | PREROUTING  | 在进行路由判断之前所要进行的规则(DNAT/REDIRECT)   |
        | INPUT       | 处理入站的数据包                                  |
        | OUTPUT      | 处理出站的数据包                                  |
        | FORWARD     | 处理转发的数据包                                  |
        | POSTROUTING | 在进行路由判断之后所要进行的规则(SNAT/MASQUERADE) |

    * 规则表

        | Tables | Notes                              |
        | ------ | :--------------------------------- |
        | raw    | 确定是否对该数据包进行状态跟踪     |
        | mangle | 为数据包设置标记（较少使用）       |
        | nat    | 修改数据包中的源、目标IP地址或端口 |
        | filter | 确定是否放行该数据包（过滤）       |

* 先后顺序

    规则链的先后顺序:

    * 入站顺序: PREROUTING → INPUT
    * 出站顺序: OUTPUT → POSTROUTING
    * 转发顺序: PREROUTING → FORWARD → POSTROUTING    
 
    规则表的先后顺序: raw → mangle → nat → filter




## 语法

```sh
iptables -t 表名 <-A/I/D/R> 规则链名 [规则号] <-i/o 网卡名> -p 协议名 <-s 源IP/源子网> --sport 源端口 <-d 目标IP/目标子网> --dport 目标端口 -j 动作

iptables [-t table] {-A|-C|-D} chain rule-specification
iptables [-t table] -I chain [rulenum] rule-specification
iptables [-t table] -R chain rulenum rule-specification
iptables [-t table] -D chain rulenum
iptables [-t table] -S [chain [rulenum]]
iptables [-t table] {-F|-L|-Z} [chain [rulenum]] [options...]
iptables [-t table] -N chain
iptables [-t table] -X [chain]
iptables [-t table] -P chain target
iptables [-t table] -E old-chain-name new-chain-name
rule-specification = [matches...] [target]
match = -m matchname [per-match-options]
target = -j targetname [per-target-options]
```

## 表

* `-t`, `--table` — 指定 table

    ```text
    filter:
        默认的表 (如果没有指明 -t 选项), 此表包含了内建的链INPUT (对于到达本地套阶层的数据包), FORWARD (对于经过此路由的包), 和 OUTPUT  (本地产生的数据包)
    
    nat:
        当一个创建了新的连接的包被遇到的时候, nat 表将会被查找。nat 表里包含三个内建链 PREROUTING (只要包到达就对其进行改变), OUTPUT (在路由之前改变本地数据包), 和 POSTROUTING (改变将要发出去的数据包).在kernel 3.7. IPv6 NAT已经被支持了。
    
    mangle:
        这张表是专门进行数据包更改的. 直到 kernel 2.4.17 mangle 表包含两条内建链 PREROUTING (在路由之前改变进来的数据包)和 OUTPUT (在路由之前改变本地产生的数据包).自 kernel 2.4.18 起 mangle 也开始支持了其他的三张表 INPUT (对于自己进到盒子里的数据包),  FORWARD (改变将要经过box进行路由的数据包), and POSTROUTING (改变将要出去的数据包).
    
    raw:
        这张表主要是为了配置免连接的追踪很无踪迹目标的结合。他用高优先级来注册网络筛选系统钩子, 北称作before ip_conntrack或者其他ip表.raw表提供以下内建链PREROUTING (对于通过任何其他网络接口到达的数据包) OUTPUT (对于本地进程产生的数据包)
    
    security:
        这张表是用来进行强制访问控制（ Mandatory Access Control (MAC)）的网络规则, 比如被SECMARK禁用和CONNSECMARK的目标.强制访问控制被linux的安全模块继承了, 例如SELinux.安全表被称作后过滤表, 它允许过滤表中任何自由访问控制规则（ Discretionary Access Control ）DAC在MAC规则之前生效. security表提供了以下的内建链INPUT  (对于自动进入盒子的数据包), OUTPUT (在路由之前改变本地生成的数据包),和FORWARD(改变通过盒子进行路由的数据包).
    ```

## 选项参数

### 执行操作的命令

以下选项指明了将要被执行的操作. 以下选项只能单独在命令行中被指明使用, 除非其他被指出的情况。

```text
   -A, --append chain rule-specification
          在选定的链后添加一个或者多个规则
 
   -C, --check chain rule-specification
          检测一条规则是否匹配此链中指定的规则, 或者说检测匹配规则是否存在C
 
   -D, --delete chain rule-specification
   -D, --delete chain rulenum
          删除一个或者多个从链中指定的规则, 可以使用规则号码或者匹配的规则信息
 
   -E, --rename-chain old-chain new-chain
          用给定的链名称重命名一条旧的链
 
   -F, --flush [chain]
          刷新选中的链或者所有的链（如果未指定具体的链）。此操作等于删除了所有的规则
 
   -I, --insert chain [rulenum] rule-specification
          向选定的链中以给定序号向对应位置插入一条或者多条规则。
 
   -L, --list [chain]
         列出链中的所有规则, 如果没有指定链, 则所有的链中的规则都将被显示
           用法：iptables -t nat -n -L
           用法：iptables -L -v
 
   -N, --new-chain chain
          用给定的名称创建一条用户自定的链
 
   -P, --policy chain target
          对于给定的目标设置链的策略, 如将INPUT链设置为DROP: iptables -P INPUT DROP
 
   -R, --replace chain rulenum rule-specification
          替换选定链中的一条规则
 
   -S, --list-rules [chain]
          显示所与选中链中的规则, 如果未选中具体的链, 则所有链的规则将以 iptables-save 形式打印出来
 
   -X, --delete-chain [chain]
          删除用户自定的链. 要删除的链必须不存在其他参考.
 
   -Z, --zero [chain [rulenum]]
          将所有链中的数据包归零,或者清零给定的链, 或者指定链中的具体规则
 
   -h     帮助.  给出(当前最简)语法描述.
```

### 参数陈列

以下参数明组成了一条规则的设置(例如添加、删除、插入、替换、附加等命令).

```text
   -4, --ipv4
          此选项对iptables和iptables-restore无效.
 
   -6, --ipv6
          如果一条规则使用了-6参数插入iptables-restore此操作将会被默默忽略, 其他的用法会报错
 
   [!] -p, --protocol protocol
          检测规则或者数据包的传输协议.
          The specified protocol can be one of tcp, udp, udplite, icmp, icmpv6,esp, ah, sctp, mh or the special
          keyword "all", or it can be a numeric value, representing one of these protocols or a different one.  
          A protocol name from /etc/protocols is also allowed

   [!] -s, --source address[/mask][,...]
          指明源, 地址可以是网路名称,主机名,网络地址 (with /mask), 或者普通ip
 
   [!] -d, --destination address[/mask][,...]
          指明目的
 
   -m, --match match
          指明一条匹配的规则进行使用
 
   -j, --jump target
          指明规则的目标（下一跳）: ACCEPT, DROP or RETURN; DNAT, LOG, MARK...
          Refer to iptables-extensions(8)
 
   -g, --goto chain
          指明进程应该在用户指定的链中继续执行
 
   [!] -i, --in-interface name
          数据包要通过或者接收的接口名称(只有进入INPUT, FORWARD 和 PREROUTING
          链的数据包需要指明)
 
   [!] -o, --out-interface name
          指明数据包将要被送往的接口名称
 
   -c, --set-counters packets bytes
          此参数可以使管理员初始化数据包和字节计数(在 INSERT,  APPEND,  REPLACE 操作中).

   [!] --source-port,--sport port[:port]

   [!] --destination-port,--dport port[:port]
```

### 附加参数

```text
   -v, --verbose
          显示操作的详细输出信息  
 
   -w, --wait [秒]
          等待xtables锁，阻止一个程序的多实例同时运行，并且一段时间试图去获得执行锁。默认的，如果不能获取执行锁，程序将会退出。此参数将会使进程等待，一直到获得执行锁
 
   -n, --numeric
          数字化输出，ip地址和端口号将会以数字格式显示出来。默认的，此程序会尝试列出主机名称或者网络名称或者服务名称
 
   -x, --exact
          数字详述.显示具体的数据包值以及字节数,而不是大约的K's(multiples of 1000) M's (multiples of 1000K)G's (multiples of 1000M)，此参数只与-L参数相关
 
   --line-numbers
          在列出规则时为每一行的开头天加一个行号,并且对应着规则在链中的位置
 
   --modprobe=command

```

### module, match

* limit

    对 IPTABLES 策略的速率进行控制, 超过限制的将交由后续策略处理, 后续的规则不符合, 则按照默认策略处理

    ```text
       limit
           This module matches at a limited rate using a token bucket filter. 
           A rule using this extension will match until this limit is reached. 
           It can be used in combination with the LOG target to give limited logging, for example.
    
           --limit rate[/second|/minute|/hour|/day]
                  Maximum average matching rate: specified as a number, with an optional 
                  '/second', '/minute', '/hour', or '/day' suffix; the default is 3/hour.
    
           --limit-burst number
                  Maximum initial number of packets to match: this number gets recharged by one 
                  every time the limit specified above is not reached, up to this number; the
                  default is 5.
    ```

    * 理解 limit 的工作方式: 

        > [http://blog.sina.com.cn/s/blog_53d7350f0100od58.html](http://blog.sina.com.cn/s/blog_53d7350f0100od58.html) 这篇博客通过一个日常的例子, 让 Limit 工作方式很容易理解. 

        limit 的工作方式就像一个单位大门口的保安: 当有人要从大门进入时, 需要找保安办理通行证。
        
        每天早上上班时, 保安手里有一定数量的通行证, 来一个人, 就签发一个, 当通行证用完后, 再来人就进不去了, 但他们不会等, 而是到别的地方去 (在 iptables 里, 这相当于一个包不符合某条规则, 就会由后面的规则来处理, 如果都不符合, 就由缺省的策略处理)。
        
        此外还有个规定, 每隔一段时间保安就要签发一个新的通行证。这样, 后面来的人如果恰巧赶上, 也就能进去了。如果没有人来, 那通行证就保留下来, 以备来的人用。如果一直没人来, 可用的通行证的数量就增加了, 但不是无限增大的, 最多也就是刚开始时保安手里有的那个数量。
        
        也就是说, 刚开始时, 通行证的数量是有限的, 但每隔一段时间就有新的通行证可用。limit 两个参数就对应这种情况, `--limit-burst` 指定刚开始时有多少通行证可用, `--limit` 指定要隔多长时间才能签发一个新的通行证。要注意的是, 这里强调的是 "签发一个新的通行证", 这是以 iptables 的角度考虑的。在写规则时, 就要从这个角度考虑。比如, 你指定了 `--limit 3/minute --limit-burst 5` , 意思是开始时有 5 个通行证, 用完之后每 20 秒增加一个 (以用户的角度看, 则是 "每 1 分钟增加 3 个" 或 "每分钟只能过 3 个")。

    * Examples: 限制 ping 响应

        ```text
        iptables -A INPUT -p icmp -m limit --limit 6/m --limit-burst 5 -j ACCEPT
        iptables -P INPUT DROP
        ```

        测试:

        ```sh
        ~] ping 192.168.161.13

        PING 192.168.161.13 (192.168.161.13) 56(84) bytes of data.
        64 bytes from 192.168.161.13: icmp_seq=1 ttl=64 time=0.439 ms
        64 bytes from 192.168.161.13: icmp_seq=2 ttl=64 time=0.364 ms
        64 bytes from 192.168.161.13: icmp_seq=3 ttl=64 time=0.351 ms
        64 bytes from 192.168.161.13: icmp_seq=4 ttl=64 time=0.333 ms
        64 bytes from 192.168.161.13: icmp_seq=5 ttl=64 time=0.360 ms
        64 bytes from 192.168.161.13: icmp_seq=11 ttl=64 time=0.342 ms
        64 bytes from 192.168.161.13: icmp_seq=21 ttl=64 time=0.302 ms
        64 bytes from 192.168.161.13: icmp_seq=31 ttl=64 time=0.341 ms
        ^B^C
        --- 192.168.161.13 ping statistics ---
        33 packets transmitted, 8 received, 75% packet loss, time 32000ms
        rtt min/avg/max/mdev = 0.302/0.354/0.439/0.036 ms
        ```

        初始 "许可" 有 5 个, 因此前 5 个包正常; 使用完初始许可以后, iptables 每 10 s 新签发一个 "许可", 所以第 6-10, 12-20, 22-30 个包被 DROP

* mac

    ```text
       mac
           [!] --mac-source address
                  Match source MAC address. It must be of the form XX:XX:XX:XX:XX:XX. 
                  Note that this only makes sense for packets coming from an Ethernet device and
                  entering the PREROUTING, FORWARD or INPUT chains.
    ```

* state

    ```text
       state
           The "state" extension is a subset of the "conntrack" module.  
           "state" allows access to the connection tracking state for this packet.
    
           [!] --state state
                  Where state is a comma separated list of the connection states to match. 
                  Only a subset of the states unterstood by "conntrack" are recognized: INVALID,
                  ESTABLISHED, NEW, RELATED or UNTRACKED. 
                  For their description, see the "conntrack" heading in this manpage.

       INVALID
              The packet is associated with no known connection.

       NEW    The packet has started a new connection or otherwise associated with 
              a connection which has not seen packets in both directions.

       ESTABLISHED
              The packet is associated with a connection which has seen packets in both directions.

       RELATED
              The packet is starting a new connection, but is associated with an existing connection, such as an FTP data transfer or an ICMP error.

       UNTRACKED
              The packet is not tracked at all, which happens if you explicitly untrack it by using -j CT --notrack in the raw table.

       SNAT   A virtual state, matching if the original source address differs from the reply destination.

       DNAT   A virtual state, matching if the original destination differs from the reply source.
    ```



## 启动/停止/从配置文件恢复

* CentOS 6: `service`

* CentOS 7: `systemctl` (安装了`iptables-services`)

* 不通过守护进程管理, 可直接使用命令操作 iptables 规则:

    ```sh
    iptables-save > /etc/sysconfig/iptables  # 保存当前配置到文件
    iptables-restore /etc/sysconfig/iptables # 从文件恢复iptables规则
    ```

## 典型配置参考

* (1) 设定预设规则

    ```bash
    # 请求接入包 :丢失
    iptables -P INPUT DROP

    # 响应数据包: 接受
    iptables -P OUTPUT ACCEPT

    # 转发数据包: 丢失
    iptables -P FORWARD DROP
    ```

* (2) 开启SSH端口: 22

    ```bash
    # 允许所有IP进行SSH连接
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # 允许特定IP进行SSH连接
    iptables -A INPUT -s 192.168.0.3 -p tcp --dport 22 -j ACCEPT

    # 允许特定网段进行SSH连接
    iptables -A INPUT -s 192.168.0.0/24 -p tcp --dport 22 -j ACCEPT

    # 允许特定段IP进行SSH连接
    iptables -A INPUT -m iprange --src-range 192.168.55.1-192.168.55.10 -p tcp --dport 22 -j ACCEPT

    # 允许除某主机/网段以外的进行SSH连接
    iptables -A INPUT -s ! 192.168.0.3 -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -s ! 192.168.0.0/24 -p tcp --dport 22 -j ACCEPT

    # OUTPUT设置为DROP时, 需要添加以下对应项
    iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT 
    iptables -A OUTPUT -d 192.168.0.3 -p tcp --sport 22 -j ACCEPT
    iptables -A OUTPUT -d 192.168.0.0/24 -p tcp --sport 22 -j ACCEPT
    ```

* (3) 允许ICMP流量进入(允许主机被Ping通)

    - iptables

        ```bash
        iptables -I INPUT -p icmp -j ACCEPT
        ```

    - 内核

        ```bash
        echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_all
        net.ipv4.icmp_echo_ignore_all=1

        # 0:允许, 1:禁止
        # 设置icmp_echo_ignore_all后, 主机也无法ping通其他主机
        ```

* (4) 允许所有已经建立的和相关的连接

    ```bash
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    ```

* (5) DORP非法连接

    ```bash
    iptables -A INPUT   -m state --state INVALID -j DROP
    iptables -A OUTPUT  -m state --state INVALID -j DROP
    iptables -A FORWARD -m state --state INVALID -j DROP
    ```

* (6) 允许loopback回环通信

    ```bash
    iptables -A INPUT -s 127.0.0.1/32 -j ACCEPT
    ```

    或

    ```bash
    iptables -A INPUT -i lo -p all -j ACCEPT
    ```

## 其他服务配置参考

* (1) DNS: 53/UDP

    ```bash
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    ```


* (2) NTP: 123/UCP 

    ```bash
    iptables -A INPUT -m state --state NEW -m udp -p udp --dport 123 -j ACCEPT
    ```

* (3) 邮件服务

    | 协议   | 端口 | 加密端口 |
    | ------ | ---- | -------- |
    | `http` | 80   | 443      |
    | `smtp` | 25   | 465      |
    | `pop3` | 110  | 995      |
    | `imap` | 143  | 993      |


    ```bash
    iptables -A INPUT -p tcp -m multiport --dports 25,80,110,143,443,465,993,995 -j ACCEPT
    iptables -A INPUT -p udp -m multiport --dports 25,80,110,143,443,465,993,995 -j ACCEPT
    ```

* (4) vsftpd

    ```bash
    iptables -I INPUT -p tcp --dport 20:21 -j ACCEPT 
    iptables -I INPUT -p tcp --dport 50000:60000 -j ACCEPT
    ```

* (5) iscsi

    ```bash
    iptables -I INPUT -s 10.10.10.2/24 -p tcp --dport 3260 -j ACCEPT
    ```

* (6) it监控

    ```bash
    iptables -A INPUT -s 10.150.36.71,10.150.36.72,10.150.36.120,10.150.36.122,10.150.36.1 -t tcp -m multiport --dport 1918,63358 -j ACCEPT
    ```

* (7) 蓝鲸

    ```
    -A INPUT -m iprange --src-range 10.150.45.209-10.150.45.222 -j ACCEPT
    -A INPUT -s 127.0.0.1/32 -j ACCEP
    -A INPUT -s 10.150.45.134 -j ACCEP
    -A INPUT -s 10.150.32.243 -p tcp --dport 22 -j ACCEP
    -A INPUT -p tcp --dport 2181 -j ACCEP
    -A INPUT -p tcp --dport 48668 -j ACCEP
    -A INPUT -p tcp --dport 58935 -j ACCEP
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEP
    -A INPUT -s 10.150.36.71,10.150.36.72,10.150.36.120,10.150.36.122,10.150.36.1 -t tcp -m multiport --dports 1918,63358 -j ACCEPT

    -A INPUT -p tcp -m multiport --dports 48668,58625,58725,58925,58930,10020,60020:60030 -j ACCEPT
    -A INPUT -p udp -m multiport --dports 10020,10030,60020:60030 -j ACCEPT
    ```

    ```
    /etc/hosts.allow

        sshd:10.150.45.222:allow
        sshd:10.150.45.134:allow
        sshd:10.150.45.214:allow
        sshd:10.150.45.219:allow
        sshd:10.150.45.220:allow
        sshd:all:deny
    ```

* (8) nfs

    ```bash
    firewall-cmd --add-service=nfs --permanent
    firewall-cmd --add-service=mountd --permanent 
    firewall-cmd --add-service=rpc-bind --permanent
    firewall-cmd --reload


    -A INPUT -p tcp -m multiport --dports 111,2049,20048 -j ACCEPT
    -A INPUT -p udp -m multiport --dports 111,2049,20048 -j ACCEPT
    ```



## 其他参考

### 注1：CentOS初始参考配置

```sh
~] cat /etc/sysconfig/iptables

# Generated by iptables-save v1.4.7 on Tue Dec 17 21:35:04 2019
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -p icmp -j ACCEPT
-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -m state --state INVALID -j DROP
-A INPUT -s 127.0.0.1/32 -j ACCEPT
-A FORWARD -m state --state INVALID -j DROP
-A OUTPUT -m state --state INVALID -j DROP
COMMIT
# Completed on Tue Dec 17 21:35:04 2019
```

### 注2：`-m state --state`

- `NEW`  状态的数据包说明这个数据包是收到的第一个数据包。比如收到一个SYN数据包, 它是连接的第一个数据包, 就会匹配`NEW`状态。第一个包也可能不是SYN包, 但它仍会被认为是`NEW`状态。

- `ESTABLISHED`  只要发送并接到应答, 一个数据连接就从`NEW`变为`ESTABLISHED`,而且该状态会继续匹配这个连接后继数据包。

- `RELATED`  当一个连接和某个已处于`ESTABLISHED`状态的连接有关系时, 就被认为是`RELATED`, 也就是说, 一个连接想要是`RELATED`的, 首先要有个`ESTABLISHED`的连接, 这个`ESTABLISHED`连接再产生一个主连接之外的连接, 这个新的连接就是`RELATED`。

- `INVALID`  状态说明数据包不能被识别属于哪个连接或没有任何状态。


### 注3：`iptables`/`netfilter`的关系

`iptables`其实不是真正的防火墙, 我们可以把它理解成一个客户端代理, 用户通过`iptables`这个代理, 将用户的安全设定执行到对应的"安全框架"中, 这个"安全框架 防火墙, 这个框架的名字叫`netfilter`。

`netfilter`才是防火墙真正的安全框架（framework）, `netfilter`位于内核空间。

`iptables`其实是一个命令行工具, 位于用户空间, 我们用这个工具操作真正的框架。


### 注4：规则和工作原理

- 规则: 其实就是网络管理员预定义的条件, 规则一般的定义为"如果数据包头符合这样的条件, 就这样处理这个数据包"

- 规则存储在内核空间的信息包过滤表中, 这些规则分别指定了**源地址**、**目的地址**、**传输协议(如TCP、UDP、ICMP)** 和 **服务类型(如HTTP、FTP和SMTP)** 等

- 当数据包与规则匹配时, iptables就根据规则所定义的方法来处理这些数据包, 如 **放行(accept)**、**拒绝(reject)** 和 **丢弃(drop)** 等。配置防火墙的主要工作就是 **添加、修改和删除** 这些规则。


<!-- ![Linux-iptables](./pictures/Netfilter-iptables/Netfilter-iptables.png) -->

```text
        +--------------------------------------------------------------------------------------------------------+
        |   User Space                                                                                           |
        |       +---------------------------------------------------------------------------------------+        |
        |       |                                  Web服务  终点/原点                                    |        |
        |       +-------------------------↑-------------------------------------------------↓-----------+        |
        |---------------------------------|-------------------------------------------------|--------------------|
        |   Kernel Space                  |                                                 |                    |
        |                                 ↑                                                 ↓                    |
        |                           +----------+                                      +----------+               |
        |                           |   input  |                                      |  output  |               |
        |                           +----------+                                      +----------+               |
        |                                 ↑                                                 |                    |
        |                                YES                                                ↓                    |
        |  +--------------+       +------ ↑ ------+          +-----------+          +-------------+              |
        |  |  prerouting  | +---> | To localhost? | -> NO -> |  forward  | +------> | postrouting | +-->--+      |
        |  +--------------+       +---------------+          +-----------+          +-------------+       |      |
        |         ↑                                                                                       |      |
        |         |                                                                                       ↓      |
        +---------|---------------------------------------------------------------------------------------|------+
                  ↑                                                                                       ↓
        +---------|---------------------------------------------------------------------------------------|------+
        |         ↑                                  Ethernet                                             ↓      |
        +---------|---------------------------------------------------------------------------------------|------+
 ?? ==>----->-----+                                                                                       +=====> Other Host
```

某些场景中的报文流向: 
- 1>到本机某进程的报文：PREROUTING --> INPUT
- 2>由本机转发的报文：PREROUTING --> FORWARD --> POSTROUTING
- 3>由本机的某进程发出的报文：OUTPUT --> POSTROUTING
