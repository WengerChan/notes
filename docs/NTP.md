# NTP

## 配置时区和时间

- 时区

    ```sh
    tzselect
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    timedatectl set-timezone Asia/Shanghai
    ```

- 设置时间

    ```sh
    date -s "2020-04-18 09:09:09"
    timedatectl set-time "2020-04-18 09:09:09"
    ```


## 设置NTP服务器

* 向上游同步时间

    ```sh
    ~] vim /etc/ntp.conf

    server s1a.time.edu.cn prefer
    restrict 192.168.20.0 mask 255.255.255.0 nomodify notrap
    ```

* 本机作为顶层 ntp 服务器

    ```sh
    ~] vim /etc/ntp.conf

    server  127.127.1.0
    fudge 127.127.1.0 stratum 0
    restrict 192.168.55.0 mask 255.255.255.0 nomodify notrap
    ```

    * `fudge <IP> [stratum <INT>]`
        
        设置时间服务器的层级, 需要和 server 一起使用
        
        e.g.: fudge 10.225.5.1 stratum 10
        
        `<INT>` 取值 0-15, 0 表示顶级, 10 通常用于给局域网主机提供时间服务

* `server` 配置行相关参数

    ```sh
    server <IP> [OPTIONs]
    ```

    * `burst`/`iburst`: 当此行 `server` 配置的 NTP 服务器 "可用"/"不可用" 时，向它发送一系列的并发包进行检测

    * `minpoll N`/`maxpoll N`: 指定 NTP 消息的最小和最大轮询间隔

        * `minpoll` 默认值 6 (*2<sup>6</sup>=64s*), 最小可设置为 3(8s)

        * `maxpoll` 默认值 10 (*2<sup>10</sup>=1024s*), 最大可设置为 17(36h)

    * `prefer`: 优先使用此行配置

* `restrict` 控制权限

    ```sh
    restrict [-6] <IP> mask <MASK> [OPTIONs]
    ```

    * `-6`: 使用 IPv6

    * `IP`: 填写 IP 地址; 如果要指定 "所有IP", 使用 `default`

    * `MASK`: 掩码

    * `OPTIONs`

        常见参数如下:

        | 参数 | 含义 |
        | -- | -- |
        | `nomodify` | 拒绝 `ntpq` 和 `ntpdc` 修改服务端状态的数据包 |
        | `noquery` | 拒绝 `ntpq` 和 `ntpdc` 查询的数据包 |
        | `ignore` | 拒绝所有 NTP 数据包 |
        | `nopeer` | 阻止主机尝试与服务器对等, 并允许欺诈性服务器控制时钟 |
        | `notrust` | 拒绝未经加密验证的数据包 |
        | `notrap` | 拒绝提供trap远端登陆<sup id="a1">[1](#f1) |
        | `limited` | 丢弃超过 `discard` 设置速率的请求包; `ntpq` 和 `ntpdc` 查询不受影响 |
        | `kod` |  被 `limited` 拒绝时发送 KoD 包 |
        | `lowpriotrap` | 设置低优先级陷阱声明 |
        |  |  |
        | `flake` | 设置 0.1 的概率丢弃 NTP 数据包; 用于测试和娱乐 |
        | `mssntp` | 开启微软AD服务 MS-SNTP |
        | `version` | 拒绝和当前 NTP 版本不匹配的客户端的数据包 |

        ---

        <b id="f1"><font size=1>1 拒绝为匹配的主机提供 模式6 控制消息陷阱服务( trap service ); 陷阱服务是 ntpdq 控制消息协议的子系统, 用于远程事件日志记录程序</font> [?](#a1)

## 查询同步结果

* `ntpq -p`

    > *Refer to: [https://support.ntp.org/bin/view/Support/TroubleshootingNTP](https://support.ntp.org/bin/view/Support/TroubleshootingNTP)*

    ```sh
    ~] ntpq -p

        remote           refid      st t when poll reach   delay   offset  jitter
    ==============================================================================
    10.112.202.in-a .GPS.            1 u   22   64    3   98.888  -21.391  17.237
    ntp1.ams1.nl.le .STEP.          16 u    -   64    0    0.000    0.000   0.000
    124-108-20-1.st .STEP.          16 u    -   64    0    0.000    0.000   0.000
    *electabuzz.feli 185.255.55.20    3 u   49   64    1  295.219  -15.540  20.121

    ~] date
    Mon Apr 22 15:19:40 CST 2019
    ```

    表头含义: 

    |  Variable  | Description                                                                                |
    | ---------- | ------------------------------------------------------------------------------------------ |
    | `[tally]`  | single-character code indicating current value of the select field of the peer status word |
    | `remote`   | host name (or IP number) of peer                                                           |
    | `refid`    | association ID or kiss code                                                                |
    | `st`       | stratum                                                                                    |
    | `t`        | `u`: unicast, `b`: broadcast, `l`: local(such as a GPS, WWVB)                              |
    | `when`     | `sec/min/hr` since last received packet                                                    |
    | `poll`     | poll interval (log2 s)                                                                     |
    | `reach`    | reach shift register (octal), 每成功连接一次, 值就会增加                                     |
    | `delay`    | roundtrip delay, 传输延迟                                                                   |
    | `offset`   | offset                                                                                     |
    | `jitter`   | jitter<sup>振动</sup>, 描述 offset 分布情况                                                 |


    * 关于 `[tally]`

    ```text
    " "    : 无状态，表示: 没有远程通信的主机 
    "LOCAL": 即本机 （未被使用的）高层级服务器 远程主机使用的这台机器作为同步服务器 
    "x"    : 已不再使用 
    "-"    : 已不再使用 
    "#"    : 良好的远程节点或服务器但是未被使用 （不在按同步距离排序的前六个节点中，作为备用节点使用） 
    "+"    : 良好的且优先使用的远程节点或服务器（包含在组合算法中） 
    "*"    : 当前作为优先主同步对象的远程节点或服务器 
    "o"    : PPS 节点 (当优先节点是有效时)。实际的系统同步是源于秒脉冲信号（pulse-per-second，PPS），可能通过PPS 时钟驱动或者通过内核接口。
    ```

    * 关于 `refid`

        The identification of the time source to which the remote machines is synced.

        可以理解为 NTP 服务器使用的上一级 NTP 服务器标识

        ```text
        IP-addr – 远程节点或服务器的 IP 地址
        .LOCL.  – 本机 (当没有远程节点或服务器可用时）
        .PPS.   – 时间标准中的“Pulse Per Second”（秒脉冲）
        .IRIG.  – Inter-Range Instrumentation Group 时间码
        .ACTS.  – 美国 NIST 标准时间 电话调制器
        .NIST.  – 美国 NIST 标准时间电话调制器
        .PTB.   – 德国 PTB 时间标准电话调制器
        .USNO.  – 美国 USNO 标准时间 电话调制器
        .CHU.   – CHU (HF, Ottawa, ON, Canada) 标准时间无线电接收器
        .DCFa.  – DCF77 (LF, Mainflingen, Germany) 标准时间无线电接收器
        .HBG.   – HBG (LF Prangins, Switzerland) 标准时间无线电接收器
        .JJY.   – JJY (LF Fukushima, Japan) 标准时间无线电接收器
        .LORC.  – LORAN-C station (MF) 标准时间无线电接收器，注： 不再可用 (被 eLORAN 废弃)
        .MSF.   – MSF (LF, Anthorn, Great Britain) 标准时间无线电接收器
        .TDF.   – TDF (MF, Allouis, France)标准时间无线电接收器
        .WWV.   – WWV (HF, Ft. Collins, CO, America) 标准时间无线电接收器
        .WWVB.  – WWVB (LF, Ft. Collins, CO, America) 标准时间无线电接收器
        .WWVH.  – WWVH (HF, Kauai, HI, America) 标准时间无线电接收器
        .GOES.  – 美国静止环境观测卫星;
        .GPS.   – 美国 GPS;
        .GAL.   – 伽利略定位系统欧洲 GNSS;
        .ACST.  – 选播服务器
        .AUTH.  – 认证错误
        .AUTO.  – Autokey （NTP 的一种认证机制）顺序错误
        .BCST.  – 广播服务器
        .CRYPT. – Autokey 协议错误
        .DENY.  – 服务器拒绝访问;
        .INIT.  – 关联初始化
        .MCST.  – 多播服务器
        .RATE.  – (轮询) 速率超出限定
        .TIME.  – 关联超时
        .STEP.  – 间隔时长改变，偏移量比危险阈值小(1000ms) 比间隔时间 (125ms)大
        ```

* `ntpq -c associations`

    ```sh
    ~] ntpq -c asso

    ind assid status  conf reach auth condition  last_event cnt
    ===========================================================
    1 55829  963a   yes   yes  none  sys.peer    sys_peer  3
    ```

    |  Variable    | Description                                                     |
    | ------------ | --------------------------------------------------------------- |
    | `ind`        | index on this list                                              |
    | `assid`      | association ID                                                  |
    | `status`     | peer status word                                                |
    | `conf`       | `yes`: persistent, `no`: ephemeral<sup>短暂的</sup>             |
    | `reach`      | `yes`: reachable, `no`: unreachable                             |
    | `auth`       | `ok`, `yes`, `bad` and `none`                                   |
    | `condition`  | selection status (see the select field of the peer status word) |
    | `last_event` | event report (see the event field of the peer status word)      |
    | `cnt`        | event count (see the count field of the peer status word)       |

## 其他配置

* 将同步好的系统时间写入到硬件(BIOS)时间里

    ```sh
    $ vim /etc/sysconfig/ntpd

    # Drop root to id 'ntp:ntp' by default.
    OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid -g"
    SYNC_HWCLOCK=yes    #添加一行SYNC_HWCLOCK=yes
    ```

    ```sh
    hwclock -w
    ```

* 修改ntp提供服务的ip地址

    ```sh
    interface listen IPv4|IPv6|all 
    interface ignore IPv4|IPv6|all 
    interface drop IPv4|IPv6|all 
    ```

    示例:

    ```sh
    interface ignore wildcard       #忽略所有端口之上的监听
    interface listen 172.16.3.1
    interface listen 10.105.28.1
    ```

    > 6 版本自带的ntp配置不生效, 提示 `configure: keyword "interface" unknown, line ignored`

