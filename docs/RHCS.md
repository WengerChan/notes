# RHCS, Red Hat Cluster Suite

实验目的: 

* `Demo 1` 使用 RedHat Enterprise Linux 7.6 上搭建一套双机双业务互为冗余的 VSFTPD RHCS 集群

    | Guest Name   |  Hostname  | Management IP  | HeartBeat IP  | Storage IP (Optional)  |
    | ------------ | ---------- | :------------: | :-----------: | :--------------------: |
    | rhel76-01    | rhel76-node01 | 192.168.161.12 | 10.168.161.12 | 20.168.161.12        |
    | rhel76-02    | rhel76-node02 | 192.168.161.13 | 10.168.161.13 | 20.168.161.13        |
    | rhel76-qnetd | rhel76-qnetd  |                | 10.168.161.14 |                      |

* `Demo 2` 使用 RedHat Enterprise Linux 6.4 上搭建一套双机双业务互为冗余的 VSFTPD RHCS 集群

    | Guest Name |  Hostname  | Management IP  | HeartBeat IP  | Storage IP (Optional)  |
    | ---------- | ---------- | :------------: | :-----------: | :--------------------: |
    | rhel64-01 | rhel64-node01 | 192.168.161.15 | 10.168.161.15 | 20.168.161.15        |
    | rhel64-02 | rhel64-node02 | 192.168.161.16 | 10.168.161.16 | 20.168.161.16        |

## 环境准备工作

### 准备时间源

使用 `chrony` 或者 `ntp` 搭建时间源, 此处不做赘述

### 准备共享存储 

共享存储种类: 

```text
  生产环境: 一般使用 SAN 存储或者 iSCSI 企业级软件实现共享存储 (如 `OpenFiler`)
  实验环境: 可使用 Linux 系统 Linux-IO Target 实现 iSCSI 共享存储; 或者 KVM/VMware 等虚拟化平台虚拟的共享磁盘
```

* Linux-IO Target

    示例: (以下仅配置一块共享磁盘, 如果需要双机双业务, 是需要两块共享磁盘的)

    * 安装

        ```sh
        yum install targetcli

        systemctl enable --now target
        ```

        ```sh
        ~] targetcli ls 

        o- / .................................................................... [...]
          o- backstores ......................................................... [...]
          | o- block ............................................. [Storage Objects: 0]
          | o- fileio ............................................ [Storage Objects: 0]
          | o- pscsi ............................................. [Storage Objects: 0]
          | o- ramdisk ........................................... [Storage Objects: 0]
          o- iscsi ....................................................... [Targets: 0]
          o- loopback .................................................... [Targets: 0]
        ```


    * 创建 block

        ```sh
        targetcli /backstores/block create disk01 /dev/sdb
        ```

	* 创建 target, 并分配给 Inititor

        ```sh
        targetcli /iscsi create iqn.2019-12.com.test:rhcs
        targetcli /iscsi/iqn.2019-12.com.test:rhcs/tpg1/acls create iqn.2019-12.com.test:rhcs_node01
        targetcli /iscsi/iqn.2019-12.com.test:rhcs/tpg1/acls create iqn.2019-12.com.test:rhcs_node02
        ```

	* 将之前创建的 block 分配给 target

        ```sh
        targetcli /iscsi/iqn.2019-12.com.test:rhcs/tpg1/luns create /backstores/block/disk01
        ```

	* 配置监听: 取消默认的 `0.0.0.0:3260`, 设置为存储网的IP `20.168.161.240:3260`

        ```sh
        targetcli /iscsi/iqn.2019-12.com.test:rhcs/tpg1/portals delete 0.0.0.0 3260

        targetcli /iscsi/iqn.2019-12.com.test:rhcs/tpg1/portals create 20.168.161.240 3260
        ```

    配置完成:

    ```text
    ~] targetcli ls 

    o- / ........................................................................... [...]
      o- backstores ................................................................ [...]
      | o- block .................................................... [Storage Objects: 1]
      | | o- disk01 ............................ [/dev/sdc (10.0GiB) write-thru activated]
      | |   o- alua ..................................................... [ALUA Groups: 1]
      | |     o- default_tg_pt_gp ......................... [ALUA state: Active/optimized]
      | o- fileio ................................................... [Storage Objects: 0]
      | o- pscsi .................................................... [Storage Objects: 0]
      | o- ramdisk .................................................. [Storage Objects: 0]
      o- iscsi .............................................................. [Targets: 1]
      | o- iqn.2019-12.com.test:rhcs ........................................... [TPGs: 1]
      |   o- tpg1 ................................................. [no-gen-acls, no-auth]
      |     o- acls ............................................................ [ACLs: 2]
      |     | o- iqn.2019-12.com.test:rhcs_node01........................ [Mapped LUNs: 1]
      |     | | o- mapped_lun0 .................................. [lun0 block/disk01 (rw)]
      |     | o- iqn.2019-12.com.test:rhcs_node02........................ [Mapped LUNs: 1]
      |     |   o- mapped_lun0 .................................. [lun0 block/disk01 (rw)]
      |     o- luns ............................................................ [LUNs: 1]
      |     | o- lun0 ........................[block/disk01 (/dev/sdb) (default_tg_pt_gp)]
      |     o- portals ...................................................... [Portals: 1]
      |       o- 20.168.161.240:3260 ................................................ [OK]
      o- loopback ........................................................... [Targets: 0]
    ```


    * 防火墙配置

        ```sh
        ~] netstat -an | grep 3260

        tcp        0      0 20.168.161.240:3260       0.0.0.0:*               LISTEN 
        ```

        ```sh
        firewall-cmd --add-service=iscsi-target --permanent
        firewall-cmd --reload
        ```

    * 已知问题: 如果客户端挂载了服务端共享的磁盘, 并对磁盘使用 Lvm 创建相应 PV, VG, LV; 当服务端操作系统重启后, target 可能丢失 block 。

        原因: 服务端的 `lvm2-lvmetad.service` 将客户端的 Lvm 元素据识别并纳管, 导致 target 绑定的磁盘 `/dev/sdb` 无法被识别。

        解决: 修改 `/etc/lvm/lvm.conf` 中 `volume_list = [ "rhel_host0" ]`, 即只将主机上的卷组添加进去, 其他的不添加。修改完毕以后, 关闭 target 服务, 重启 `lvm2-lvmetad.service` (建议重启操作系统)

* KVM 虚拟机使用共享磁盘

    ```sh
    # 创建
    qemu-img create -f raw /path/to/10g-01.raw 10G
    qemu-img create -f raw /path/to/10g-02.raw 10G

    # 为两个节点挂载上共享磁盘
    # 此处两个节点假设为 node01 和 node02
    virsh attach-disk --domain node01 --source /path/to/10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node01 --source /path/to/10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --config
    virsh attach-disk --domain node01 --source /path/to/10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node01 --source /path/to/10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config

    virsh attach-disk --domain node02 --source /path/to/10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node02 --source /path/to/10g-01.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
    virsh attach-disk --domain node02 --source /path/to/10g-02.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node02 --source /path/to/10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
    ```

* VMware 虚拟机使用共享磁盘

    Workstation/vSphere 等可创建使用共享磁盘, 此处不做介绍。

## Demo 1 - RHEL7.6 - 双机双业务互为冗余的 VSFTPD RHCS 集群

### 1.1 配置时间同步

两个节点配置到同一时间源, 使用 `ntpd` 或者 `chronyd` 均可

### 1.2 配置主机解析记录

两个节点都需要配置, 在 `/etc/hosts` 添加以下两行; 注意使用的 IP 是心跳 IP, 如果资源不足也可和管理 IP 共用

```sh
~] vi /etc/hosts

10.168.161.12 rhel76-node01
10.168.161.13 rhel76-node02
```

### 1.3 配置网卡绑定

有网络冗余要求, 可配置 `Team` 或者 `Bonding`, Refer to: *[Bonding](Bonding.md)* or *[Team](Team.md)*

### 1.4 配置共享存储

KVM/VMware 虚拟机使用共享磁盘, 直接在平台操作挂载以后即可, 无需额外操作, 下文介绍 iSCSI Inititor 配置方法

* 1.4.1 安装

    ```sh
    yum install iscsi-initiator-utils
    ```

* 1.4.2 配置

    修改 InititorName, 与 Target 端配置的保持一致:

    ```sh
    # node01
    ~] vi /etc/iscsi/initiatorname.iscsi
    InitiatorName=iqn.2019-12.com.test:rhcs_node01

    # node02
    ~] vi /etc/iscsi/initiatorname.iscsi   
    InitiatorName=iqn.2019-12.com.test:rhcs_node02
    ```

    启动 `iscsi` 和 `iscsid` 服务, 并设置自启:

    ```sh
    systemctl restart iscsi
    systemctl restart iscsid

    systemctl enable iscsi
    systemctl enable iscsid
    ```

* 1.4.3 发现 iSCSI 目标

    ```sh
    ~] iscsiadm --mode discoverydb --type sendtargets --portal 20.192.168.1 --discover

    20.192.168.1:3260,1 iqn.2019-12.com.test:rhcs
    ```

* 1.4.4 登录/连接

    ```sh
    ~] iscsiadm --mode node --targetname iqn.2019-12.com.test:rhcs --portal 20.192.168.1:3260 --login

    Logging in to [iface: default, target: iqn.2019-12.com.test:targer01, portal: 20.20.20.240,3260] (multiple)
    Login to [iface: default, target: iqn.2019-12.com.test:targer01, portal: 20.20.20.240,3260] successful.
    ```

* 1.4.5 登出/断开连接

    先取消所有磁盘占用, 然后执行以下命令: 

    ```sh
    iscsiadm --mode node --targetname iqn.2019-12.com.test:rhcs --portal 20.192.168.1:3260 --logout
    ```


> 以上三步 (挂载, 登录, 登出) 可参考 `iscsiadm` man 文档的 `EXAMPLE` 部分获取帮助


两个节点均发现磁盘, 表明配置正常: 

```sh
~] lsblk

NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sr0          11:0    1 1024M  0 rom  
vda         253:0    0   20G  0 disk 
├─vda1      253:1    0    1G  0 part /boot
├─vda2      253:2    0    2G  0 part [SWAP]
└─vda3      253:3    0   17G  0 part /
vdb         253:16   0   10G  0 disk 
vdc         253:32   0   10G  0 disk 
```

### 1.5 配置文件系统

任一节点执行创建操作:

```sh
pvcreate /dev/vdb
vgcreate rhcs01 /dev/vdb
lvcreate -n data01 -l 100%FREE rhcs01
mkfs.xfs /dev/mapper/rhcs01-data01

pvcreate /dev/vdc
vgcreate rhcs02 /dev/vdc
lvcreate -n data02 -l 100%FREE rhcs02
mkfs.xfs /dev/mapper/rhcs02-data02
```

执行导入导出, 让两个节点都能识别 LVM 信息:

* 当前节点将卷组失活, 然后导出卷组:

    ```sh
    vgchange -an rhcs01 rhcs02
    vgexport rhcs01 rhcs02
    ```

* 另一节点导入, 并激活卷组:

    ```sh
    vgimport rhcs01 rhcs02
    vgchange -ay rhcs01 rhcs02
    ```

    查看

    ```sh
    ~] lvs
      LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      data01 rhcs01 -wi-a----- <10.00g
      data02 rhcs02 -wi-a----- <10.00g
    ```

* 正常识别后, 将所有节点将卷组取消激活

    ```sh
    vgchange -an rhcs01
    vgchange -an rhcs02
    ```


### 1.6 配置 VSFTPD 服务

> 本次实验搭建双机双业务互为冗余的 VSFTPD 集群, 因此两个节点都需要配置 VSFTPD 服务

* 1.6.1 添加用户及挂载点

    ```sh
    mkdir /data01
    mkdir /data02
    yum install -y vsftpd

    useradd ftpuser01
    useradd ftpuser0101
    useradd ftpuser02
    useradd ftpuser0202
    for user in ftpuser01{,01} ftpuser02{,02} ; do echo '111' | passwd --stdin ${user}; done
    ```

* 1.6.2 修改 VSFTPD 配置文件

    两个节点都需要添加这两个配置文件 `/etc/vsftpd/vsftpd_01.conf`, `/etc/vsftpd/vsftpd_02.conf`, 分别配置两个 VSFTPD 实例: 

    ```sh
    ~] vi /etc/vsftpd/vsftpd_01.conf

    anonymous_enable=NO

    local_enable=YES
    local_root=/data01
    chroot_local_user=NO
    chroot_list_enable=YES
    chroot_list_file=/etc/vsftpd/chroot_list01
    allow_writeable_chroot=NO
    guest_enable=NO

    dirmessage_enable=YES
    connect_from_port_20=YES
    listen=YES
    listen_address=192.168.161.14
    listen_ipv6=NO
    pam_service_name=vsftpd
    userlist_enable=YES
    userlist_deny=NO
    userlist_file=/etc/vsftpd/user_list01
    tcp_wrappers=YES

    # 日志配置
    xferlog_enable=YES
    xferlog_std_format=YES
    xferlog_file=/var/log/xferlog01
    dual_log_enable=YES
    vsftpd_log_file=/var/log/vsftpd01.log
    ```

    ```sh
    ~] vi /etc/vsftpd/vsftpd_02.conf

    anonymous_enable=NO

    local_enable=YES
    local_root=/data02
    chroot_local_user=NO
    chroot_list_enable=YES
    chroot_list_file=/etc/vsftpd/chroot_list02
    allow_writeable_chroot=NO
    guest_enable=NO

    dirmessage_enable=YES
    connect_from_port_20=YES
    listen=YES
    listen_address=192.168.161.15
    listen_ipv6=NO
    pam_service_name=vsftpd
    userlist_enable=YES
    userlist_deny=NO
    userlist_file=/etc/vsftpd/user_list02
    tcp_wrappers=YES

    # 日志配置
    xferlog_enable=YES
    xferlog_std_format=YES
    xferlog_file=/var/log/xferlog02
    dual_log_enable=YES
    vsftpd_log_file=/var/log/vsftpd02.log
    ```

    两个节点都需要在 `/etc/vsftpd/` 下添加 `user_list` 和 `chroot_list` 共四个文件, 和主配置文件中相应配置项保持一致:

    ```sh
    ~] vi user_list01
    ——

    ~] vi user_list02
    ftpuser02
    ftpuser0202

    ~] vi chroot_list01
    ftpuser01
    ftpuser0101

    ~] vi chroot_list02
    ftpuser02
    ftpuser0202
    ```

    如果需要 "**禁用主动模式, 启动被动模式**", 并限制端口范围, 可以参考以下配置:

    ```text
    port_enable=NO
    pasv_enable=YES
    pasv_min_port=2226
    pasv_max_port=2229
    ```


* 1.6.3 防火墙配置

    如果启用了防火墙, 则需要添加策略:

    ```sh
    firewall-cmd --add-service=ftp --permanent
    firewall-cmd --reload
    ```

### 1.7 配置集群


* 1.7.1 安装集群套件

    ```sh
    yum groupinstall 'High Availability'
    ```

    如果启用了防火墙, 则需要添加策略:

    ```sh
    firewall-cmd --add-service=high-availability --permanent
    firewall-cmd --reload
    ```

* 1.7.2 初始化集群

    * (1) 启动 `pcsd` 服务

        设置开机自启:

        ```sh
        systemctl start pcsd.service
        systemctl enable pcsd.service
        ```

    * (2) 修改 `hacluster` 服务用户密码

        `hacluster` 用户是集群 `pcsd` 进程认证需要使用的用户; 添加节点到集群时, 需要验证此用户的密码

        ```sh
        echo '123qweQ' | passwd hacluster  --stdin
        ```

    * (3) 节点认证

        ```sh
        pcs cluster auth [node] [...] [-u username] [-p password]
        ```

        - 每个节点中 `pcsd` 管理员用户名必须为 `hacluster`  
        - 如果未指定用户名或密码, 系统会在执行该命令时提示您为每个节点指定那些参数  
        - 如果未指定任何节点, 且之前运行过该命令, 则这个命令会在所有所有使用 `pcs cluster setup` 命令指定的节点中认证 pcsd 
        - 授权令牌保存在 `~/.pcs/tokens` 或 `/var/lib/pcsd/tokens`  


        ```sh
        ~] pcs cluster auth rhel76-node01 rhel76-node02

        Username: hacluster
        Password: 
        node01: Authorized
        node02: Authorized
        ```

* 1.7.3 创建集群

    (1) 创建

    ```sh
    pcs cluster setup --name Cluster-VSFTPD rhel76-node01 rhel76-node02
    ```

    创建完以后可查看集群状态, 此时集群未启动

    ```sh
    ~] pcs status
    Error: cluster is not currently running on this node
    ```

    (2) 启动

    ```sh
    pcs cluster start --all
    ```

    上面命令等同于以下两条命令: 

    ```sh
    systemctl start corosync.service
    systemctl start pacemaker.service
    ```

    (3) 设置自启动

    ```sh
    systemctl enable corosync.service pacemaker.service
    ```

* 1.7.4 状态检查

    * (1) 检查 `corosync` 状态

        * `corosync` 通信状态: 

            ```sh
             ~] corosync-cfgtool -s

            Printing ring status.
            Local node ID 2
            RING ID 0
                    id      = 10.168.161.13
                    status  = ring 0 active with no faults
            ```

        * 成员关系与 quorum: 

            ```sh
            ~] corosync-cmapctl  | grep members

            runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
            runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(10.168.161.12) 
            runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
            runtime.totem.pg.mrp.srp.members.1.status (str) = joined
            runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
            runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(10.168.161.13) 
            runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 1
            runtime.totem.pg.mrp.srp.members.2.status (str) = joined

            ~] pcs status corosync

            Membership information
            ----------------------
                Nodeid      Votes Name
                     1          1 rhel76-node01 (local)
                     2          1 rhel76-node02
            ```

    * (2) 检查 `pacemaker` 状态

        ```sh
        ~] ps axf |grep pacemaker

        4810 pts/0    S+     0:00      |   \_ grep --color=auto pacemaker
        4619 ?        Ss     0:00 /usr/sbin/pacemakerd -f
        4620 ?        Ss     0:00  \_ /usr/libexec/pacemaker/cib
        4621 ?        Ss     0:00  \_ /usr/libexec/pacemaker/stonithd
        4622 ?        Ss     0:00  \_ /usr/libexec/pacemaker/lrmd
        4623 ?        Ss     0:00  \_ /usr/libexec/pacemaker/attrd
        4624 ?        Ss     0:00  \_ /usr/libexec/pacemaker/pengine
        4625 ?        Ss     0:00  \_ /usr/libexec/pacemaker/crmd

        ~] pcs status
        ~] pcs cluster cib
        ```

    * (3) 集群基础配置信息检测

        ```sh
        ~] crm_verify -L -V

           error: unpack_resources:	Resource start-up disabled since no STONITH resources have been defined
           error: unpack_resources:	Either configure some or disable STONITH with the stonith-enabled option
           error: unpack_resources:	NOTE: Clusters with shared data need STONITH to ensure data integrity
        Errors found during check: config not valid
        ```

        注: `STONITH/Fencing` 默认开启, 可以先暂时关闭: 

        > By default pacemaker enables STONITH (Shoot The Other Node In The Head ) / Fencing in an order to protect the data. Fencing is mandatory when you use the shared storage to     avoid the data corruptions.)

        ```sh
        ~] pcs property set stonith-enabled=false

        ~] pcs property show stonith-enabled
        Cluster Properties:
         stonith-enabled: false
        ```


### 1.8 配置服务托管

* 1.8.1 准备工作

    查看集群资源代理标准: 

    ```sh
    ~] pcs resource standards
    lsb            # Open cluster Framework
    ocf            # Linux standard base (legacy init scripts)
    service        # Based on Linux "service" command
    systemd        # systemd based service Management
    stonith        # Fencing Resource standard (实际测试没有该项, 不知道是不是VM的原因)
    ```

    查看 `ocf` 资源代理提供程序:

    ```sh
    ~] pcs resource providers
    heartbeat
    openstack
    pacemaker
    ```

    查看 `ocf` 标准, `heartbeat` 提供的内建类型:

    ```sh
    pcs resource agents ocf             # 查看 ocf 提供的所有内建类型

    pcs resource agents ocf:heartbeat   # 查看 ocf 标准 heartbeat 提供的内建类型
    ```

    查看所有资源类型:

    ```sh
    pcs resource list
    ```

    查看具体资源类型的信息:

    ```sh
    pcs resource list IPaddr2
    pcs resource describe IPaddr2
    ```


* 1.8.2 添加 IP

    ```sh
    pcs resource create IP_161.14 ocf:heartbeat:IPaddr2 ip=192.168.161.14 cidr_netmask=24 nic=eth0 op monitor interval=30s

    pcs resource create IP_161.15 ocf:heartbeat:IPaddr2 ip=192.168.161.15 cidr_netmask=24 nic=eth0 op monitor interval=30s
    ```

    关于 `op monitor interval=30s`: 此项配置是修改监控间隔为 `30s`, 覆盖默认的配置; `30s` 间隔并不是每隔 30s 就检测一次, 而是上一次完成检测后 20s 再次进行检测

    `IPaddr2` 默认的 `op`:

    ```text
    Default operations:
      start: interval=0s timeout=20s
      stop: interval=0s timeout=20s
      monitor: interval=10s timeout=20s
    ```

    查看创建后的资源信息:

    ```sh
    ~] pcs resource show IP_161.14

     Resource: IP_161.14 (class=ocf provider=heartbeat type=IPaddr2)
      Attributes: cidr_netmask=24 ip=192.168.161.14 nic=eth0
      Operations: monitor interval=30s (IP_161.14-monitor-interval-30s)
                  start interval=0s timeout=20s (IP_161.14-start-interval-0s)
                  stop interval=0s timeout=20s (IP_161.14-stop-interval-0s)

    ~] pcs resource show IP_161.15

     Resource: IP_161.15 (class=ocf provider=heartbeat type=IPaddr2)
      Attributes: cidr_netmask=24 ip=192.168.161.15 nic=eth0
      Operations: monitor interval=30s (IP_161.15-monitor-interval-30s)
                  start interval=0s timeout=20s (IP_161.15-start-interval-0s)
                  stop interval=0s timeout=20s (IP_161.15-stop-interval-0s)
    ```


* 1.8.3 添加 HA-LVM

    将卷组交由 RHCS 集群管理, 需先解除本地 LVM 对卷组的管理, 然后配置集群资源管理卷组

    * (1) 解除本地 LVM 对卷组的管理

        * 修改配置文件

            ```sh
            ~] vi /etc/lvm/lvm.conf

            locking_type = 1
            use_lvmetad = 0
            volume_list = [ "rhel-root" ]
            ```

            > 注: `volume_list = [ "rhel-root" ]` 标记本地 LVM 管理的卷组, 除集群管理的卷组均需要填写进去; 如果无, 则配置成 "volume_list = [  ]"

        * 关闭服务:

            ```sh
            systemctl stop lvm2-lvmetad.service lvm2-lvmetad.socket
            systemctl disable lvm2-lvmetad.service
            ```

        > 以上两步可以直接执行 `lvmconf --enable-halvm --services --startstopservices`, 然后检查 `/etc/lvm/lvm.conf` 配置, 注意非集群管理的卷组都要包含在 `volume_list = [  ]` 


        * 重建 initramfs

            ```sh
            cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.$(date +'%Y-%m-%d-%H%M%S').bak
            dracut -H -f /boot/initramfs-$(uname -r).img $(uname -r)
            ```

        * 重启操作系统


    * (2) 配置集群资源管理卷组

        ```sh
        pcs resource create VG_rhcs01 ocf:heartbeat:LVM volgrpname=rhcs01 exclusive=yes
        pcs resource create VG_rhcs02 ocf:heartbeat:LVM volgrpname=rhcs02 exclusive=yes
        ```

        > 注: (1) `ocf:heartbeat:LVM` 可简写成 `LVM`; (2) `exclusive=yes` 表示独占激活

        添加完成以后, 两个卷组分别挂载到不同节点: 

        ```sh
        ~] pcs status 

        Cluster name: Cluster-VSFTPD
        Stack: corosync
        Current DC: rhel76-node01 (version 1.1.19-8.el7-c3c624ea3d) - partition with quorum
        Last updated: Tue Mar 15 10:14:45 2022
        Last change: Tue Mar 15 09:59:46 2022 by root via cibadmin on rhel76-node01

        2 nodes configured
        4 resources configured

        Online: [ rhel76-node01 rhel76-node02 ]

        Full list of resources:

         IP_161.14      (ocf::heartbeat:IPaddr2):       Started rhel76-node01
         IP_161.15      (ocf::heartbeat:IPaddr2):       Started rhel76-node02
         VG_rhcs01      (ocf::heartbeat:LVM):   Started rhel76-node01    # <= 节点 1
         VG_rhcs02      (ocf::heartbeat:LVM):   Started rhel76-node02    # <= 节点 2

        Daemon Status:
          corosync: active/enabled
          pacemaker: active/enabled
          pcsd: active/enabled
        ```


        此时, 分别登录两个节点查看 LV 信息, 一个节点只有一个 LV 是 `active` 状态

        ```sh
        rhel76_node01 ] lvs
          LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
          data01 rhcs01 -wi-a----- <10.00g  # <= a: active
          data02 rhcs02 -wi------- <10.00g 

        rhel76_node02 ] lvs
          LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
          data01 rhcs01 -wi------- <10.00g  
          data02 rhcs02 -wi-a----- <10.00g  # <= a: active
        ```

* 1.8.4 添加 FileSystem

    ```sh
    pcs resource create FS_data01 ocf:heartbeat:Filesystem device="/dev/mapper/rhcs01-data01" directory="/data01" fstype="xfs"
    pcs resource create FS_data02 ocf:heartbeat:Filesystem device="/dev/mapper/rhcs02-data02" directory="/data02" fstype="xfs"
    ```

    > 注: (1) `ocf:heartbeat:Filesystem` 可简写成 `Filesystem`

* 1.8.5 添加 VSFTPD 服务

    取消 Systemd 开机自启动:

    ```sh
    systemctl disable vsftpd
    ```

    添加服务托管:

    ```sh
    pcs resource create VSFTPD_01 systemd:vsftpd@vsftpd_01
    pcs resource create VSFTPD_02 systemd:vsftpd@vsftpd_02
    ```


* 1.8.6 创建资源组

    ```sh
    pcs resource group add VSFTPD_GROUP_01 IP_161.14 VG_rhcs01 FS_data01 VSFTPD_01
    pcs resource group add VSFTPD_GROUP_02 IP_161.15 VG_rhcs02 FS_data02 VSFTPD_02
    ```

* 1.8.7 添加约束条件

    查看约束条件可使用以下格式:

    ```text
    pcs constraint ref <resource>                               # 列出指定资源的约束条件
    pcs constraint [order|colocation|location] [show] [--full]  # 列出约束条件
        --full      # If '--full' is specified also list the constraint ids
    ```

    - (1) 添加 `order` 类约束

        语法:

        ```text
        order [action] <resource id> then [action] <resource id> [options]
        ```

        配置:

        1. 确保 IP 和 FS 都正常启动以后, 才启动 VSFTPD
        2. 确保 VG 正常识别后, 才挂载 FS

        ```sh
        pcs constraint order start IP_161.14 then VSFTPD_01
        pcs constraint order start FS_data01 then VSFTPD_01
        pcs constraint order start VG_rhcs01 then FS_data01

        pcs constraint order start IP_161.15 then VSFTPD_02
        pcs constraint order start FS_data02 then VSFTPD_02
        pcs constraint order start VG_rhcs02 then FS_data02
        ```

        查看配置结果:

        ```sh
        ~] pcs constraint order --full

        Ordering Constraints:
          start IP_161.14 then start VSFTPD_01 (kind:Mandatory) (id:order-IP_161.14-VSFTPD_01-mandatory)
          start FS_data01 then start VSFTPD_01 (kind:Mandatory) (id:order-FS_data01-VSFTPD_01-mandatory)
          start VG_rhcs01 then start FS_data01 (kind:Mandatory) (id:order-VG_rhcs01-FS_data01-mandatory)
          start IP_161.15 then start VSFTPD_02 (kind:Mandatory) (id:order-IP_161.15-VSFTPD_02-mandatory)
          start FS_data02 then start VSFTPD_02 (kind:Mandatory) (id:order-FS_data02-VSFTPD_02-mandatory)
          start VG_rhcs02 then start FS_data02 (kind:Mandatory) (id:order-VG_rhcs02-FS_data02-mandatory)
        ```


    - (2) 添加 `colocation` 类约束

        > 注: 如果设置了资源组, `colocation` 类可不用设置, 因为资源组本就是只能启动在一个节点上

        语法:

        ```text
        colocation add [master|slave] <source resource id> with [master|slave] <target resource id> [score] [options] [id=constraint-id]

        # Request <source resource> to run on the same node where pacemaker has determined <target resource> should run.
        ```

        配置:

        ```sh
        pcs constraint colocation add VG_rhcs01 with FS_data01
        pcs constraint colocation add IP_161.14 with VSFTPD_01
        pcs constraint colocation add FS_data01 with VSFTPD_01

        pcs constraint colocation add VG_rhcs02 with FS_data02
        pcs constraint colocation add IP_161.15 with VSFTPD_02
        pcs constraint colocation add FS_data02 with VSFTPD_02
        ```

        查看配置结果:

        ```sh
        ~] pcs constraint colocation
        Colocation Constraints:
          VG_rhcs01 with FS_data01 (score:INFINITY)
          IP_161.14 with VSFTPD_01 (score:INFINITY)
          FS_data01 with VSFTPD_01 (score:INFINITY)
          VG_rhcs02 with FS_data02 (score:INFINITY)
          IP_161.15 with VSFTPD_02 (score:INFINITY)
          FS_data02 with VSFTPD_02 (score:INFINITY)

        ```

    - (3) 添加`location`类约束

        语法: 

        ```text
        # Create a location constraint on a resource to prefer the specified node with score (default score: INFINITY).
        location <resource> prefers <node>[=<score>] [<node>[=<score>]]...

        # Create a location constraint on a resource to avoid the specified node with score (default score: INFINITY).
        location <resource> avoids <node>[=<score>] [<node>[=<score>]]...
        ```

        配置:

        ```sh
        pcs constraint location VSFTPD_GROUP_01 prefers rhel76-node01=200 rhel76-node02=20
        pcs constraint location VSFTPD_GROUP_02 prefers rhel76-node01=20 rhel76-node02=200
        ```

        查看配置结果:

        ```sh
        ~] pcs constraint location show
        Location Constraints:
          Resource: VSFTPD_GROUP_01
            Enabled on: rhel76-node01 (score:200)
            Enabled on: rhel76-node02 (score:20)
          Resource: VSFTPD_GROUP_02
            Enabled on: rhel76-node01 (score:20)
            Enabled on: rhel76-node02 (score:200)
        ```


### 1.9 配置 Fence

* 1.9.1 引言

    上面配置完成以后: `VSFTPD_GROUP_01` 运行在 `rhel76-node01` 上, `VSFTPD_GROUP_02` 运行在 `rhel76-node02` 上; 

    如果 down 掉 `rhel76-node01` 的心跳网卡 eth1, 模拟节点网卡故障: 

    * rhel76-node02 "认为" rhel76-node01 失联 - 开始接管 `VSFTPD_GROUP_01` 服务
    * rhel76-node01 同样 "认为" rhel76-node02 失联 - 开始接管 `VSFTPD_GROUP_02` 服务
    
    上面的情形很容易造成相互抢占资源, 而且不释放已经争抢到的资源; 严重情况下可能会导致数据丢失, 磁盘损坏等.

    为了避免上因此需要给集群各节点配置 Fence 监控节点状态, 如果节点出现故障而未释放资源时, 做出预设的操作来保证集群正常工作; 偶数节点/两节点的集群, 同时搭配仲裁设备来完善.

* 1.9.2 Fence 类型

    1. 如果使用的是 VMware vSphere 虚拟化平台的虚拟机来搭建的 RHCS 集群, 可使用 vCenter/ESXi 的接口来配置 Fence (`fence_vmware_soap`)
    2. 如果使用的是 KVM 类虚拟化平台的虚拟机搭建 RHCS 集群, 可在宿主机配置 `fence_virtd` 来执行节点 Fence (`fence_xvm`)
    3. 物理机搭建 RHCS 时, 可配置通过 带外/管理口/IPMI 来配置 Fence (`fence_ipmilan`).


* 1.9.3 前置配置

    触发 Fence 操作时, 节点主机应该立刻 "断电关机/重启", 即 *powered off immediately*, 而不是执行普通的 "系统关机", 即 *shutdown gracefully*。
    
    为了达到此要求, 需要关闭 主机/操作系统 的 ACPI Soft-Off 功能: 
    
    1. 主机层面, 可以在 BIOS 中关闭
    2. 操作系统层面, 可以通过 禁用对应服务 或者配置内核参数彻底禁用此功能。

    具体操作如下: 

    * RHEL 5,6:

        The preferred method of disabling ACPI Soft-Off is with `chkconfig` management. If the preferred method is not effective for your cluster, you can disable ACPI Soft-Off with the BIOS power management. If neither of those methods is effective for your cluster, you can disable ACPI completely by appending `acpi=off` to the kernel boot command line in the grub.conf file.

        * Disabling ACPI Soft-Off with the BIOS

            BIOS CMOS Setup Utility, `Soft-Off by PWR-BTTN` set to `Instant-Off`

            *[Refer to Redhat Document ->](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/cluster_administration/s1-acpi-ca)*

        * Disabling ACPI Soft-Off with `chkconfig`

            ```sh
            chkconfig --del acpid
            ```

            or

            ```sh
            chkconfig --level 345 acpid off
            ```

            Then `reboot` the node.

        * Disabling ACPI Completely in the `grub.conf` File

            ```sh
            ~] vi /boot/grub/grub.conf
            ...
            title Red Hat Enterprise Linux Server (2.6.32-193.el6.x86_64)
                    root (hd0,0)
                    kernel /vmlinuz-2.6.32-193.el6.x86_64 ... acpi=off   # <= 添加 acpi=off
            ...

            ~] reboot
            ```

    * RHEL 7,8:

        You can disable ACPI Soft-Off with one of the following alternate methods:

        * Disabling ACPI Soft-Off with the BIOS

            BIOS CMOS Setup Utility, `Soft-Off by PWR-BTTN` set to `Instant-Off`

            *[Refer to Redhat Document ->](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/high_availability_add-on_reference/s1-acpi-ca)*

        * Disabling ACPI Soft-Off in the `logind.conf` file

            ```sh
            ~] vi /etc/systemd/logind.conf
            HandlePowerKey=ignore

            ~] systemctl daemon-reload
            ~] systemctl restart systemd-logind.service

        * Disabling ACPI Completely in the `GRUB 2` File

            This method completely disables ACPI; some computers do not boot correctly if ACPI is completely disabled. Use this method *only* if the other methods are not effective for your cluster.

            ```sh
            ~] grubby --args=acpi=off --update-kernel=ALL
            ~] reboot
            ```


* 1.9.4 添加 vCenter 或 Esxi 作为 Fence 设备

    ```text
    # Examples:
        Hostnames: node1, node2.
        VM names: node1-vm, node2-vm.
    ```

    检查连接是否正常:

    ```sh
    ~] fence_vmware_soap -a <vCenter/ESXi IP address> -l <vCenter/ESXi username> -p <vCenter/ESXi password> [--ssl] --ssl-insecure -o status
    Status: ON
    ```

    找到虚拟机信息:   

    ```sh
    ~] fence_vmware_soap -a <vCenter/ESXi IP address> -l <vCenter/ESXi username> -p <vCenter/ESXi password> [--ssl] --ssl-insecure -o list | egrep '(node1-vm|node2-vm)'
    node1-vm,11111111-aaaa-bbbb-cccc-111111111111
    node2-vm,22222222-dddd-eeee-ffff-222222222222
    ```

    添加 Fencing:

    > 参考链接: [https://access.redhat.com/solutions/917813](https://access.redhat.com/solutions/917813)

    ```sh
    # 查看 fence_vmware_soap 的配置参考 
    pcs stonith describe fence_vmware_soap

    # 添加
    pcs stonith create FTP_fence_vmware fence_vmware_soap inet4_only=1 ipport=443 ipaddr="192.168.163.252" login="administrator@vsphere.local" passwd="1qaz@WSX4rfv" ssl_insecure=1 pcmk_host_map="node1:11111111-aaaa-bbbb-cccc-111111111111;node2:22222222-dddd-eeee-ffff-222222222222" pcmk_host_list="node1-vm,node2-vm" pcmk_host_check=static-list
    # pcmk_host_map 也可以写成 "node1:node1-vm;node2:node2-vm"
    ```

* 1.9.5 IPMI 设置 Fence

    ```sh
    # 检查连接状态
    ~] fence_ipmilan -a <IP> -P -l <username> -p <password> –o status
    Status: ON    # ON 表示正常

    # 检查连接状态
    ~] ipmitool -H <IP> -I lanplus -U <username> [-L ADMINISTRATOR] -P <password> chassis power status -vvv

    # 配置
    ~] pcs stonith create <NAME> fence_ipmilan pcmk_host_list='cnsz03016' pcmk_host_check='static-list' ipaddr='10.0.64.115' login='USERID' passwd='PASSW0RD' lanplus=1 power_wait=4 pcmk_reboot_action='reboot' op monitor interval=30s
    ```

    `pcmk_reboot_action` 用于指定 Fence 操作, 默认指令为 `reboot`, 可按需求修改, 如改成 `off` (只关机不开机)


* 1.9.6 KVM 虚拟机配置 Fence

    * KVM 宿主机配置

        It is needed to setup `fence_virtd` on the KVM host so that `fence_xvm` can be configured on the virtual machines. `fence_virtd` is a host daemon designed to route fencing requests for virtual machines

        1. Install:

            ```sh
            yum install fence-virt fence-virtd fence-virtd-libvirt fence-virtd-multicast fence-virtd-serial
            ```

        2. Create and distribute fence key:

            ```sh
            mkdir -p /etc/cluster
            dd if=/dev/urandom of=/etc/cluster/fence_xvm.key bs=4k count=1

            # copy key to all nodes
            scp /etc/cluster/fence_xvm.key nodeX:/etc/cluster/
            ```

        3. Create `/etc/fence_virt.conf` file:

            ```sh
            ~] fence_virtd -c

            ...
            Interface [virbr0]: br-heartb   # <= br-heartb: 心跳网
            ...
            ...
            Replace /etc/fence_virt.conf with the above [y/N]? y    # <= y: 确认修改
            ```

        4. Start the `fence_virtd` service

            ```sh
            # <= 6
            service fence_virtd restart
            chkconfig fence_virtd on

            # >= 7
            systemctl restart fence_virtd
            systemctl enable fence_virtd
            ```

    * 节点配置

        1. Ensure `fence-virt` package is installed on each cluster node

            ```sh
            rpm -qa fence-virt
            ```

        2. Firewall settings

            ```sh
            # <= 6
            iptables -I INPUT -m state --state NEW -p tcp --dport 1229 -j ACCEPT
            service iptables save
            service iptables restart

            # >= 7
            firewall-cmd --permanent --add-port=1229/tcp
            firewall-cmd --reload
            ```

        3. Test fencing: In order that the fencing to be successful, below command should succeed on host as well as cluster nodes. 

            ```sh
            fence_xvm -o list
            fence_xvm -o reboot -H <cluster-node>
            ```

        4. (Optional) Edit `/etc/hosts`: 按需决定是否添加 Fence 使用的网络到虚拟机名称的解析记录(最好使用与心跳IP不同网段)

            > 配置了解析以后, 添加 Fence 设备时, 可以直接使用 IP 配置, 而不用指定主机的 Guest Name (虚拟机名字)

            ```sh
            ~] vi /etc/hosts

            10.168.161.12 rhel76-node01
            10.168.161.13 rhel76-node02
            
            xx.xx.xx.xx rhel76-01
            xx.xx.xx.xx rhel76-02
            ```

    * 为集群节点添加 Fence 代理

        ```sh
        pcs stonith create VSFTPD_xvmfence fence_xvm key_file=/etc/cluster/fence_xvm.key
        pcs stonith create VSFTPD_xvmfence fence_xvm pcmk_host_check=static-list pcmk_host_map="rhel76-node01:rhel76-01;rhel76-node02:rhel76-02" key_file=/etc/cluster/fence_xvm.key
        ```

* 1.9.7 后置操作

    前文中将 `STONITH/Fencing` 暂时关闭了, 配置完成以后需要开启: 

    ```sh
    ~] pcs property set stonith-enabled=true

    ~] pcs property show

    Cluster Properties:
     cluster-infrastructure: corosync
     cluster-name: Cluster-VSFTPD
     dc-version: 1.1.19-8.el7-c3c624ea3d
     have-watchdog: false
     last-lrm-refresh: 1647849911
     stonith-enabled: true   # <= 此处已修改成 true
    ```

* 1.9.7 查看 Fence 配置

    ```
    ~] pcs stonith show --full

    Resource: FTP_fence_vmware (class=stonith type=fence_vmware_soap)
    Attributes: inet4_only=1 ipaddr=192.168.163.252 ipport=443 login=administrator@vsphere.local passwd=1qaz@WSX4rfv pcmk_host_check=static-list pcmk_host_list=node01,node02 pcmk_host_map=node01:422a97b9-5f92-a095-db50-c6a08eccda73;node02:422aa805-fe81-638a-02a5-a1985085f68e ssl_insecure=1
    Operations: monitor interval=60s (FTP_fence_vmware-monitor-interval-60s)
    ```


### 1.10 配置仲裁

RHEL 使用 `votequorum` 服务配合 `fencing` 来避免集群出现 "脑裂" 情况, 以下是关于仲裁的相关介绍: 

* 1.10.1 Quorum - votequorum

    > Refer to: `votequorum(5)`

    * (1) 查看当前集群 `Quorum` 状态

        The following command shows the quorum configuration.

        ```sh
        pcs quorum [config]
        ```

        The following command shows the quorum runtime status.

        ```sh
        pcs quorum status
        ```

        ```sh
        ~] pcs quorum status
        Quorum information
        ------------------
        Date:             Sat Mar 26 23:23:35 2022
        Quorum provider:  corosync_votequorum
        Nodes:            2
        Node ID:          1
        Ring ID:          1/212
        Quorate:          Yes

        Votequorum information
        ----------------------
        Expected votes:   2
        Highest expected: 2
        Total votes:      2
        Quorum:           1  
        Flags:            2Node Quorate WaitForAll 

        Membership information
        ----------------------
            Nodeid      Votes    Qdevice Name
                1          1         NR rhel76-node01 (local)
                2          1         NR rhel76-node02
        ```

    * (2) 修改集群 `Quorum` 选项

        ```sh
        pcs quorum update [auto_tie_breaker=[0|1]] [last_man_standing=[0|1]] [last_man_standing_window=[time-in-ms] [wait_for_all=[0|1]]
        ```

        * `two_node`

            Enables two node cluster operations (default: 0).

            NOTES: enabling `two_node: 1` automatically enables `wait_for_all`. It is still possible to override `wait_for_all` by explicitly setting it to 0.  If more than 2 nodes join the cluster, the `two_node` option is automatically disabled.

        * `wait_for_all`

            Enables Wait For All (WFA) feature (default: 0).

            The general behaviour of `votequorum` is to switch a cluster from *inquorate* to *quorate* as soon as possible. For example, in an 8 node cluster, where every node has 1 vote, `expected_votes` is set to 8 and `quorum` is (50% + 1) 5. As soon as 5 (or more) nodes are visible to each other, the partition of 5 (or more) becomes *quorate* and can start operating. (As soon as 5 nodes become *quorate*, with the other 3 still offline, the remaining 3 nodes will be fenced.)

            When WFA is enabled, the cluster will be quorate for the first time only after all nodes have been  visible  at  least once at the same time.

        * `last_man_standing` / `last_man_standing_window: 10000`

            Enables Last Man Standing (LMS) feature (default:  0). Tunable `last_man_standing_window` (default: 10 seconds expressed in ms).

            Using  for example an 8 node cluster where each node has 1 vote, `expected_votes` is set to 8 and *quorate* to 5. This condition allows a total failure of 3 nodes. If a 4th node fails, the cluster becomes *inquorate* and it will stop providing services.

            Enabling LMS allows the cluster to dynamically recalculate `expected_votes` and `quorum` under specific circumstances. It is essential to **enable WFA** when using LMS in High Availability clusters.

            Using the above 8 node cluster example, with LMS enabled the cluster can retain quorum and continue operating by  losing, in a cascade fashion, up to 6 nodes with only 2 remaining active.

            Example chain of events:

            ```text
               1) cluster is fully operational with 8 nodes.
                  (expected_votes: 8 quorum: 5)

               2) 3 nodes die, cluster is quorate with 5 nodes.

               3) after last_man_standing_window timer expires,
                  expected_votes and quorum are recalculated.
                  (expected_votes: 5 quorum: 3)

               4) at this point, 2 more nodes can die and
                  cluster will still be quorate with 3.

               5) once again, after last_man_standing_window
                  timer expires expected_votes and quorum are
                  recalculated.
                  (expected_votes: 3 quorum: 2)

               6) at this point, 1 more node can die and
                  cluster will still be quorate with 2.

               7) one more last_man_standing_window timer
                  (expected_votes: 2 quorum: 2)
            ```

            NOTES: 

            In order for the cluster to downgrade automatically from 2 nodes to a 1 node cluster, the `auto_tie_breaker` feature must also be enabled (see below).  

            If `auto_tie_breaker` is not enabled, and one more failure occurs, the remaining node will not be quorate. 

            LMS does not work with asymmetric voting schemes, each node must vote 1. 

            LMS is also incompatible with quorum devices, if `last_man_standing` is specified in `corosync.conf` then the quorum device will be disabled.


        * `auto_tie_breaker`

            Enables Auto Tie Breaker (ATB) feature (default: 0).

            The general behaviour of `votequorum` allows a simultaneous node failure up to 50% - 1 node, assuming each node has 1 vote.

            When enabled, the cluster can suffer up to 50% of the nodes failing at the same time, in a deterministic fashion. The cluster partition, or the set of nodes that are still in contact with the `nodeid` configured in `auto_tie_breaker_node` (or `lowest` nodeid if not set), will remain *quorate*. The other nodes will be *inquorate*.

        * `auto_tie_breaker_node: lowest|highest|<list of node IDs>`

            节点间出现隔离时, 如果配置 `lowest`: 默认配置, 使得节点序号小的节点达到 quorate; `highest`: 使得节点序号大的节点达到 quorate;  `<list of node IDs>`: 指定的列表为优先顺序(空格分割; 此处的 `nodeid` 可以通过 `pcs quorum status` 查询)

    * (3) 关闭 quorum

        ```sh
        pcs cluster quorum unblock
        ```

    * (4) 管理 quorum device

        见 `1.10.2` 详解

    Quorum 相关的管理命令汇总: 

    ```sh
    pcs quorum [config]
    pcs quorum status
    pcs quorum device status [--full]
    pcs quorum device add [<generic options>] model <device model> [<model options>]
    pcs quorum device update [<generic options>] [model <model options>]
    pcs quorum device remove
    pcs quorum expectd-vote <vote>
    pcs quorum unblock [--force]
    pcs quorum update [auto_tie_breaker=[0|1]] [last_man_standing=[0|1]] [last_man_standing_window=[<time in ms>]] [wait_for_all=[0|1]]
    ```

* 1.10.2 Quorum Device

    在 RHEL7.4/CentOS7.4 中, Pacemaker 新增了 Quorum Device 的功能, 通过一个新增的服务器作为 Quorum Device, 原有节点通过网络连接到Quorum Device上, 由 Quorum Device 进行仲裁。

    `QDevice` 和 `QNetd` 会参与仲裁决定。在仲裁方 `corosync-qnetd` 的协助下, `corosync-qdevice` 会提供一个可配置的投票数, 以使群集可以承受大于标准仲裁规则所允许的节点故障数量。

    `QNetd` (corosync-qnetd): 一个不属于群集的 systemd 服务, 向 corosync-qdevice 守护程序提供投票的 systemd 守护程序。

    `QDevice` (corosync-qdevice): 每个群集节点上与 Corosync 一起运行的 systemd 服务。这是 corosync-qnetd 的客户端。QDevice 可以与不同的仲裁方配合工作, 但目前仅支持与 QNetd 配合工作。

    原有的节点保持不动, 找一台新的机器搭建 Quorum Device. 注: 一个集群只能连接到一个 Quorum Device, 而一个 Quorum Device 可以被多个集群所使用。所以如果有多个集群环境, 有一个 Quorum Device 的机器就足够为这些集群提供服务了

    > Refer to: `corosync-qdevice(8)` 

    配置 Quorum device 主机: 

    1. 额外找一台主机 (10.168.161.14), 安装 `pcs` 和 `corosync-qnetd`

        ```sh
        yum install pcs corosync-qnetd
        ```

    2. 启动 `pcsd` 服务

        ```sh
        systemctl enable --now pcsd
        ```

    3. 防火墙配置

        ```sh
        # 放行整个 HA 服务
        firewall-cmd --add-service=high-availability

        # 或者直接关闭防火墙
        systemctl disable --now firewalld
        ```

    4. 配置 quorum device

        仲裁设备目前只支持 `net` 类型, 其提供以下两种算法: 

        * `ffsplit`: fifty-fifty split. 为活动节点数最多的分区提供一票。

        * `lms`: last-man-standing. 如果该节点是集群中唯一可以看到 qnetd 服务器(仲裁设备)的节点, 那么它得到一票。

        (1) 添加并启动一个 `net` 格式的仲裁设备, 同时设置开机自启动

        ```sh
        ~] pcs qdevice setup model net --enable --start

        Quorum device 'net' initialized
        quorum device enabled
        Starting quorum device...
        quorum device started
        ```

        (2) 添加完成以后, 检查仲裁设备状态

        ```sh
        ~] pcs qdevice status net --full

        QNetd address:                  *:5403
        TLS:                            Supported (client certificate required)
        Connected clients:              0
        Connected clusters:             0
        Maximum send/receive size:      32768/32768 bytes
        ```

        Quorum Device 节点相关的管理命令汇总: 

        ```sh
        pcs qdevice setup model <device model> [--enable] [--start]
        pcs qdevice status <device model> [--full] [<cluster_name>]
        pcs qdevice [start|stop|enable|disable|kill] <device model>
        pcs qdevice destroy <device model>
        ```

    5. 添加仲裁设备到集群中

        (1) 集群对仲裁设备节点认证

        ```sh
        # 修改 hacluster 用户密码
        rhel76-qnetd ~] echo '123qweQ.' | passwd --stdin hacluster

        # 配置 hosts
        rhel76-qnetd ~] vi /etc/hosts
        ...
        10.168.161.12 rhel76-node01
        10.168.161.13 rhel76-node02
        10.168.161.14 rhel76-qnetd
        ...

        rhel76-node01 ~] vi /etc/hosts
        ...
        10.168.161.12 rhel76-node01
        10.168.161.13 rhel76-node02
        10.168.161.14 rhel76-qnetd
        ...

        rhel76-node02 ~] vi /etc/hosts
        ...
        10.168.161.12 rhel76-node01
        10.168.161.13 rhel76-node02
        10.168.161.14 rhel76-qnetd
        ...

        # 新增认证节点: 任意找一个集群节点, 执行以下命令对 quorum device 节点进行认证
        rhel76-node01 ~] pcs cluster auth rhel76-qnetd
        ```

        (2) 添加仲裁设备

        ```sh
        pcs cluster stop --all
        pcs quorum device add model net host=rhel76-qnetd algorithm=ffsplit
        pcs cluster start --all
        ```

        (3) 查看 quorum 配置状态

        ```sh
        ~] pcs quorum config

        Options:
        Device:
        votes: 1
        Model: net
            algorithm: ffsplit
            host: rhel76-qnetd
        ```

        (4) 查看 quorum 运行状态

        ```sh
        ~] pcs quorum status

        Quorum information
        ------------------
        Date:             Sun Mar 27 16:39:29 2022
        Quorum provider:  corosync_votequorum
        Nodes:            2
        Node ID:          2
        Ring ID:          1/240
        Quorate:          Yes

        Votequorum information
        ----------------------
        Expected votes:   3
        Highest expected: 3
        Total votes:      3
        Quorum:           2  
        Flags:            Quorate Qdevice 

        Membership information
        ----------------------
            Nodeid      Votes    Qdevice Name
                 1          1    A,V,NMW rhel76-node01 (local)
                 2          1    A,V,NMW rhel76-node02
                 0          1            Qdevice
        ```

        NOTES:

        1. `pcs quorum status` 等同于直接执行 `corosync-quorumtool` 命令
        2. `Quorate: Yes` 表示集群仲裁状态正常, 且当前节点正常
        3. Qdevice 状态: 

            | 符号      | 含义 |
            | --------- | --------- |
            | `A`, `NA` | (active) 显示 `QDevice` 与 `Corosync` 之间的连接状态 |
            | `V`, `NV` | (vote) 显示仲裁设备是否已为节点投票; 两节点集群异常情况时, 一个节点为 `V`, 一个 `NV` |
            | `MW`, `NMW` | (master_wins) 显示是否为主体获胜 |
            | `NR` | (not register) 表示节点未在使用仲裁设备 |


        (4) 查看 quorum device 运行状态

        ```sh
        ~] pcs quorum device status 

        Qdevice information
        -------------------
        Model:                  Net
        Node ID:                2
        Configured node list:
            0   Node ID = 1
            1   Node ID = 2
        Membership node list:   1, 2

        Qdevice-net information
        ----------------------
        Cluster name:           Cluster-VSFTPD
        QNetd host:             rhel76-qnetd:5403
        Algorithm:              Fifty-Fifty split
        Tie-breaker:            Node with lowest node ID
        State:                  Connected
        ```

        仲裁设备配置命令汇总: 

        ```sh
        pcs quorum device status [--full]
        pcs quorum device add [<generic options>] model <device model> [<model options>]
        pcs quorum device update [<generic options>] [model <model options>]
        pcs quorum device remove
        pcs quorum device heuristics remove
        ```


## Demo 2 - RHEL6.4 - 双机双业务互为冗余的 VSFTPD RHCS 集群

|  Hostname  | Management IP  | HeartBeat IP  | Storage IP (Optional)  |
| ---------- | :------------: | :-----------: | :--------------------: |
| rhel64-node01 | 192.168.161.16 | 10.168.161.16 | 20.168.161.16       |
| rhel64-node02 | 192.168.161.17 | 10.168.161.17 | 20.168.161.17       |



### 2.1 配置时间同步

两个节点配置到同一时间源, 使用 `ntpd` 同步或者定时执行 `ntpupdate` 均可。

### 2.2 配置主机解析记录

两个节点都需要配置, 在 `/etc/hosts` 添加以下两行; 注意使用的 IP 是心跳 IP, 如果资源不足也可和管理 IP 共用

```sh
~] vi /etc/hosts

10.168.161.16 rhel64-node01
10.168.161.17 rhel64-node02
```

### 2.3 配置网卡绑定

> 需要关闭 `NetworkManager`

有网络冗余要求, 可配置 `Team` 或者 `Bonding`, Refer to: *[Bonding](Bonding.md)* or *[Team](Team.md)*

### 2.4 配置共享存储

下文使用 KVM 虚拟机进行实验, 参照 [准备共享存储](#准备共享存储) 为两个节点添加两块共享存储; 如果需要使用 ISCSI 共享存储, 配置方法参见 [1.4 配置共享存储](#14-配置共享存储)


在宿主机执行: 

```sh
# 创建
qemu-img create -f raw /var/lib/libvirt/images/rhel64-rhcs-10g-01.raw 10G
qemu-img create -f raw /var/lib/libvirt/images/rhel64-rhcs-10g-02.raw 10G

# 挂载
virsh attach-disk --domain rhel64-01 --source /var/lib/libvirt/images/rhel64-rhcs-10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
virsh attach-disk --domain rhel64-01 --source /var/lib/libvirt/images/rhel64-rhcs-10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --config
virsh attach-disk --domain rhel64-01 --source /var/lib/libvirt/images/rhel64-rhcs-10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --current
virsh attach-disk --domain rhel64-01 --source /var/lib/libvirt/images/rhel64-rhcs-10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config

virsh attach-disk --domain rhel64-02 --source /var/lib/libvirt/images/rhel64-rhcs-10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
virsh attach-disk --domain rhel64-02 --source /var/lib/libvirt/images/rhel64-rhcs-10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --config
virsh attach-disk --domain rhel64-02 --source /var/lib/libvirt/images/rhel64-rhcs-10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --current
virsh attach-disk --domain rhel64-02 --source /var/lib/libvirt/images/rhel64-rhcs-10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
```

两个节点均发现磁盘, 表明配置正常: 

```sh
~] lsblk

NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sr0                           11:0    1 1024M  0 rom  
vda                          252:0    0   20G  0 disk 
├─vda1                       252:1    0  500M  0 part /boot
└─vda2                       252:2    0 19.5G  0 part 
  ├─vg_rhel64-lv_root (dm-0) 253:0    0 17.6G  0 lvm  /
  └─vg_rhel64-lv_swap (dm-1) 253:1    0    2G  0 lvm  [SWAP]
vdb                          252:16   0   10G  0 disk 
vdc                          252:32   0   10G  0 disk 
```

### 2.5 配置文件系统

任一节点执行创建操作:

```sh
pvcreate /dev/vdb
vgcreate rhcs01 /dev/vdb
lvcreate -n data01 -l 100%FREE rhcs01
mkfs.ext4 /dev/mapper/rhcs01-data01

pvcreate /dev/vdc
vgcreate rhcs02 /dev/vdc
lvcreate -n data02 -l 100%FREE rhcs02
mkfs.ext4 /dev/mapper/rhcs02-data02
```

执行导入导出, 让两个节点都能识别 LVM 信息:

* 当前节点将卷组失活, 然后导出卷组:

    ```sh
    vgchange -an rhcs01 rhcs02
    vgexport rhcs01 rhcs02
    ```

* 另一节点导入, 并激活卷组:

    ```sh
    vgimport rhcs01 rhcs02
    vgchange -ay rhcs01 rhcs02
    ```

    查看

    ```sh
    ~] lvs
      LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      data01 rhcs01 -wi-a----- <10.00g
      data02 rhcs02 -wi-a----- <10.00g
    ```

* 正常识别后, 将所有节点将卷组取消激活

    ```sh
    vgchange -an rhcs01
    vgchange -an rhcs02
    ```

### 2.6 配置 VSFTPD 服务

参照 [1.6 配置 VSFTPD 服务](#16-配置-vsftpd-服务); 如果需要 "防火墙配置" 时, 则需要保证 iptables 中包含以下规则: 

```sh
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp --dport 21 -j ACCEPT
-A OUTPUT -p tcp --sport 20 -j ACCEPT
```


### 2.7 配置集群


* 2.7.1 安装集群套件

    ```sh
    yum groupinstall 'High Availability'
    yum install -y luci             # 若要使用 luci/conga 用户界面, 需要安装此包(按需安装, 不要求每个节点都安装)
    yum install -y lvm2-cluster     # 若使用 clvm, 则需要安装此包(每个节点都需要)
    ```

    如果启用了防火墙, 则需要添加规则。配置防火墙有两种方法: 

    * 第一种取巧的配置, 集群节点之间全部端口都放开, 不做任何限制

        ```sh
        #  rhel64-node01 上配置信任 rhel64-node02 (要用心跳 IP)
        -A INPUT -s 10.168.161.16 -j ACCEPT
        -A OUTPUT -s 10.168.161.17 -j ACCEPT

        #  rhel64-node02 上配置信任 rhel64-node01  (要用心跳 IP)
        -A INPUT -s 10.168.161.17 -j ACCEPT
        -A OUTPUT -s 10.168.161.16 -j ACCEPT
        ```

    * 第二种配置具体端口

        |端口|协议|组件|
        |--|--|--|
        |`5404`,`5405`| UDP | corosync/cman(集群管理器) |
        |`21064`| TCP |	dlm |
        |`16851`| TCP |	modclusterd |
        |`11111`| TCP |	ricci(为 luci 提供接口) |
        |`8084`<sup id="a1">[1](#f1)</sup>| TCP | luci (conga用户界面)|

        按照上表列出的端口, 则节点在 node01 上可以配置 node02 的访问策略 (node02 上配置类似): 

        ```sh
        -A INPUT -m state --state NEW -p udp -s <node02> -d <node01> -m multiport --dports 5404,5405 -j ACCEPT
        -A INPUT -m addrtype --dst-type MULTICAST -m state --state NEW -p udp -m multiport -s <node02> --dports 5404,5405 -j ACCEPT
        -A INPUT -m state --state NEW -p tcp -s <node02> -d <node01> -m multiport --dports 11111,21064,16851 -j ACCEPT
        -A INPUT -m state --state NEW -p tcp -s <IP_of_Luci_CLient> -d <IP_of_Luci_Listen> --dport 8084 -j ACCEPT
        -A INPUT -p igmp -j ACCEPT  # For igmp (Internet Group Management Protocol)
        ```

        上面的规则摘自红帽官方文档, 可以适当的简略一下: 

        ```sh
        -A INPUT -p udp -s <node02> -m multiport --dports 5404,5405 -j ACCEPT
        -A INPUT -p tcp -s <node02> -m multiport --dports 11111,21064,16851 -j ACCEPT
        -A INPUT -p igmp -j ACCEPT       # For igmp (Internet Group Management Protocol)

        -A INPUT -p tcp --dport 8084 -j ACCEPT  # 如果有安装 luci
        ```

        --- 

        <b id="f1"><font size=1>1 luci 配置文件 "/etc/sysconfig/luci" 中的 "port = 8084" 可以修改端口 </font></b> [↺](#a11)


* 2.7.2 初始化集群

   * (1) 启动 `ricci` 服务

        设置开机自启:

        ```sh
        chkconfig ricci on
        service ricci start
        ```

    * (2) 修改 `ricci` 服务用户密码

        `ricci` 用户是集群认证需要使用的用户; 添加节点到集群时, 需要验证此用户的密码

        ```sh
        echo '123qweQ' | passwd ricci --stdin
        ```

    * (3) 节点认证

        与 RHCS 7 不同, 在后续创建集群、添加节点、同步配置文件等操作时才会需要输入密码做节点认证。

* 2.7.3 创建集群

    ```sh
    Cluster Operations:
          --createcluster <cluster>
                            Create a new cluster.conf (removing old one if it exists)
          --getversion      Get the current cluster.conf version
          --setversion <n>  Set the cluster.conf version
          --incversion      Increment the cluster.conf version by 1
          --startall        Start *AND* enable cluster services on reboot for all nodes
          --stopall         Stop *AND* disable cluster services on reboot for all nodes
          --start           Start *AND* enable cluster services on reboot for host specified with -h
          --stop            Stop *AND* disable cluster services on reboot for host specified with -h
    Node Operations:
          --lsnodes         List all nodes in the cluster
          --addnode <node>  Add node <node> to the cluster
          --rmnode <node>
                            Remove a node from the cluster
          --nodeid <nodeid> Specify nodeid when adding a node
          --votes <votes>   Specify number of votes when adding a node
          --addalt <node name> <alt name> [alt options]
                            Add an altname to a node for RRP
          --rmalt <node name>
                            Remove an altname from a node for RRP
    ```

    (1) 创建

    在其中一个节点上执行命令创建集群: 

    ```sh
    # css -h <host> --createcluster <cluster_name>
    css -h rhel64-node01 --createcluster Cluster-VSFTPD  # <= 输入 rhel64-node01 上 ricci 用户密码
    ```

    上面的操作实际上是在 rhel64-node01 节点上新建一个配置文件 `/etc/cluster/cluster.conf`

    ```sh
    ~] cat /etc/cluster/cluster.conf
    ~] ccs -f /etc/cluster/cluster.conf --getconf   # 查看指定配置文件
    ~] ccs -h rhel64-node01 --getconf               # 查看指定节点的配置文件

    <?xml version="1.0"?>
    <cluster config_version="1" name="Cluster-VSFTPD">  
      <fence_daemon/>   
      <clusternodes/>  
      <cman/>  
      <fencedevices/>  
      <rm>    
        <failoverdomains/>    
        <resources/>    
      </rm>  
    </cluster>
    ```

    (2) 添加节点

    ```sh
    # ccs -h <host> --addnode <host> [--nodeid <node_id>] [--votes <votes>]
    # "--addnode": 添加节点, 一次只能添加一个节点; 如果要删除节点, 使用 "--rmnode"
    # "--nodeid": 指定节点的 id
    # "--votes": 指定节点的投票权

    ccs -h rhel64-node01 --addnode rhel64-node01
    ccs -h rhel64-node01 --addnode rhel64-node02
    ```

    ```sh
    ~] ccs -h localhost --lsnodes

    rhel64-node01: nodeid=1
    rhel64-node02: nodeid=2

    ~] ccs -h rhel64-node01 --getconf

    <cluster config_version="3" name="Cluster-VSFTPD">  
      <fence_daemon/>  
      <clusternodes>    
        <clusternode name="rhel64-node01" nodeid="1"/>    # < 新增的行
        <clusternode name="rhel64-node02" nodeid="2"/>    # < 新增的行
      </clusternodes>  
      <cman/>  
      <fencedevices/>  
      <rm>    
        <failoverdomains/>    
        <resources/>    
      </rm>  
    </cluster>
    ```

    > NOTES: 查看 `/etc/cluster/cluster.conf` 文件可以发现: 多了两行 `clusternode` 配置, 而且 `config_version` 由 `1` 变成 `3`。这是因为任何一个节点对集群配置文件进行修改, 这个值都会自增 1, 后续集群间配置文件同步时, 也是由 `config_version` 的值决定谁是 "最新" 的。


### 2.8 配置资源

```text
Service Operations:
      --lsserviceopts [service type]
                        List available services.  If a service type is
                        specified, then list options for the specified
                        service type
      --lsservices      List currently configured services and resources in
                        the cluster
      --addresource <resource type> [resource options] ...
                        Add global cluster resources to the cluster
                        Resource types and variables can be found in the
                        online documentation under 'HA Resource Parameters'
      --rmresource <resource type> [resource options]
                        Remove specified resource with resource options
      --addservice <servicename> [service options] ...
                        Add service to cluster
      --rmservice <servicename>
                        Removes a service and all of its subservices
      --addvm <virtual machine name> [vm options] ...
                        Add a virtual machine to the cluster
      --rmvm <virtual machine name>
                        Removes named virtual machine from the cluster
      --addsubservice <servicename> <subservice> [service options] ...
                        Add individual subservices, if adding child services,
                        use ':' to separate parent and child subservices
                        and brackets to identify subservices of the same type

                        Subservice types and variables can be found in the
                        online documentation in 'HA Resource Parameters'

                        To add a nfsclient subservice as a child of the 2nd
                        nfsclient subservice in the 'service_a' service use
                        the following example: --addsubservice service_a \
                                               nfsclient[1]:nfsclient \
                                               ref=/test
      --rmsubservice <servicename> <subservice>
                        Removes a specific subservice specified by the
                        subservice, using ':' to separate elements and
                        brackets to identify between subservices of the
                        same type.
                        To remove the 1st nfsclient child subservice
                        of the 2nd nfsclient subservice in the 'service_a'
                        service, use the following example:
                                            --rmsubservice service_a \
                                            nfsclient[1]:nfsclient
```

* 2.8.1 准备工作

    > 关于 `resource` 和 `service`: 可以将多个 `resource` 绑定在一起, 创建成一个 `service`, 类似于 RHCS 7 中的 "资源组"。

    ```sh
    ccs -h <host> --lsresourceopt       # 列出所有支持的 resource
    ccs -h <host> --lsresourceopt ip    # 列出指定 resource 的配置选项

    ccs -h <host> --lsservices          # 列出所有已经配置的 resource 和 service
    ccs -h <host> --addresource resourcetype [resource options]   # 添加
    ccs -h <host> --rmresource resourcetype [resource options]    # 删除
    ```

    ```sh
    ~] ccs -h rhel64-node01 --lsresourceopt

    service - Defines a service (resource group).
    ASEHAagent - Sybase ASE Failover Instance
    SAPDatabase - Manages any SAP database (based on Oracle, MaxDB, or DB2)
    SAPInstance - SAP instance resource agent
    apache - Defines an Apache web server
    clusterfs - Defines a cluster file system mount.
    fs - Defines a file system mount.
    ip - This is an IP address.
    lvm - LVM Failover script
    mysql - Defines a MySQL database server
    named - Defines an instance of named server
    netfs - Defines an NFS/CIFS file system mount.
    nfsclient - Defines an NFS client.
    nfsexport - This defines an NFS export.
    nfsserver - This defines an NFS server resource.
    openldap - Defines an Open LDAP server
    oracledb - Oracle 10g Failover Instance
    orainstance - Oracle 10g Failover Instance
    oralistener - Oracle 10g Listener Instance
    postgres-8 - Defines a PostgreSQL server
    samba - Dynamic smbd/nmbd resource agent
    script - LSB-compliant init script as a clustered resource.
    tomcat-6 - Defines a Tomcat server
    vm - Defines a Virtual Machine
    ```

* 2.8.2 添加 IP

    ```sh
    ~] ccs -h rhel64-node01 --lsserviceopt ip

    ip - This is an IP address.
      Required Options:
        address: IP Address
      Optional Options:
        family: Family
        monitor_link: Monitor NIC Link
        nfslock: Enable NFS lock workarounds
        sleeptime: Amount of time (seconds) to sleep.
        disable_rdisc: Disable updating of routing using RDISC protocol
        prefer_interface: Network interface
        __independent_subtree: Treat this and all children as an independent subtree.
        __enforce_timeouts: Consider a timeout for operations as fatal.
        __max_failures: Maximum number of failures before returning a failure to a status check.
        __failure_expire_time: Amount of time before a failure is forgotten.
        __max_restarts: Maximum number restarts for an independent subtree before giving up.
        __restart_expire_time: Amount of time before a failure is forgotten for an independent subtree.
    ```

    使用以下命令 添加/删除 IP 资源: 

    ```sh
    # 添加
    ccs -h rhel64-node01 --addresource ip address="192.168.161.18/24" family=ipv4 monitor_link=1 sleeptime=10 prefer_interface=eth0
    ccs -h rhel64-node01 --addresource ip address="192.168.161.19/24" family=ipv4 monitor_link=1 sleeptime=10 prefer_interface=eth0

    # 删除
    # ccs -h <host> --rmresource <resourcetype> [resource options]
    ccs -h rhel64-node01 --rmresource ip address="192.168.161.18/24"
    ccs -h rhel64-node01 --rmresource ip address="192.168.161.19/24"
    ```

* 2.8.3 添加 HA-LVM
 
    将卷组交由 RHCS 集群管理, 需先解除本地 LVM 对卷组的管理, 然后配置集群资源管理卷组。RHCS 6 中有两种方法配置 HA-LVM: 

    * (Perferred) 使用 CLVM 在节点上管理 LVM (此时节点会独占 LVM 上所有的逻辑卷)

        1. 安装软件包
            
            ```sh
            yum groupinstall "Resilient Storage"
            # or
            yum install lvm2-cluster
            ```
        2. 修改 lvm 配置

            ```sh
            ~] vi /etc/lvm/lvm.conf
            
            # locking_type = 1
            locking_type = 3
            ```

        3. 需要启动 clvmd

            ```sh
            service clvmd start
            chkconfig clvmd on
            ```

        4. 创建卷组时的注意点

            示例: 

            ```sh
            pvcreate /dev/vdb1
            vgcreate -cy shared_vg /dev/vdb1    # 此时要为卷组指定 -c, --clustered {y|n}
            lvcreate -L 10G -n ha_lv shared_vg
            mkfs.ext4 /dev/shared_vg/ha_lv
            lvchange -an shared_vg/ha_lv
            ```


    * 使用 LVM 本地 tag 管理

        1. 修改 lvm 配置

            ```sh
            ~] vi /etc/lvm/lvm.conf

            locking_type = 1
            use_lvmetad = 0
            volume_list = [ "VolGroup00", "@rhel64-node01" ] # 填写本机使用的卷组, 集群管理的卷组不能写进去
                                                             # 同时填写主机名, 要与集群配置的节点名称一致

            # 另一个节点使用:  volume_list = [ "VolGroup00", "@rhel64-node02" ] 
            ```
            
            > 使用 `lvmconf --enable-halvm` 命令可以直接将 `locking_type` 和 `use_lvmetad` 配置好
        
        2. 重建 initramfs

            ```sh
            cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.$(date +%m-%d-%H%M%S).bak
            dracut -H -f /boot/initramfs-$(uname -r).img $(uname -r)
            ```

        3. `reboot`

    配置完以后, 添加 HA-LVM 到集群: 

    ```sh
    ~] ccs -h rhel64-node01 --lsserviceopt lvm
    vm - LVM Failover script
     Required Options:
       name: Name
       vg_name: Volume group name
     Optional Options:
       lv_name: Logical Volume name (optional).
       self_fence: Fence the node if it is not able to clean up LVM tags
       nfslock: Enable NFS lock workarounds
       __independent_subtree: Treat this and all children as an independent subtree.
       __enforce_timeouts: Consider a timeout for operations as fatal.
       __max_failures: Maximum number of failures before returning a failure to a status check.
       __failure_expire_time: Amount of time before a failure is forgotten.
       __max_restarts: Maximum number restarts for an independent subtree before giving up.
       __restart_expire_time: Amount of time before a failure is forgotten for an independent subtree.


    ~] ccs -h rhel64-node01 --addresource lvm name="LVM_RHCS01" vg_name="rhcs01" lv_name="data01" self_fence=1
    ~] ccs -h rhel64-node01 --addresource lvm name="LVM_RHCS02" vg_name="rhcs02" lv_name="data02" self_fence=1
    ```

* 2.8.4 添加 FileSystem

    ```sh
    ~] ccs -h rhel64-node01 --lsserviceopt fs

    fs - Defines a file system mount.
      Required Options:
        name: File System Name
        mountpoint: Mount Point
        device: Device or Label
      Optional Options:
        fstype: File system type
        force_unmount: Force Unmount
        quick_status: Quick/brief status checks.
        self_fence: Seppuku Unmount
        nfslock: Enable NFS lock workarounds
        nfsrestart: Enable NFS daemon and lockd workaround
        fsid: NFS File system ID
        force_fsck: Force fsck support
        options: Mount Options
        __independent_subtree: Treat this and all children as an independent subtree.
        __enforce_timeouts: Consider a timeout for operations as fatal.
        __max_failures: Maximum number of failures before returning a failure to a status check.
        __failure_expire_time: Amount of time before a failure is forgotten.
        __max_restarts: Maximum number restarts for an independent subtree before giving up.
        __restart_expire_time: Amount of time before a failure is forgotten for an independent subtree.


    ~] ccs -h rhel64-node01 --addresource fs name="FS_data01" mountpoint="/data01" device="/dev/mapper/rhcs01-data01" fstype="ext4" self_fence=1 force_fsck=1
    ~] ccs -h rhel64-node01 --addresource fs name="FS_data02" mountpoint="/data02" device="/dev/mapper/rhcs02-data02" fstype="ext4" self_fence=1 force_fsck=1
    ```

* 2.8.5 添加 VSFTPD

    RHCS 6 中没有办法将一个系统服务添加到集群, 需要使用 script 来替代。

    1. 从 /etc/init.d/vsftpd 复制两份出来, 分别作为两个节点 VSFTPD 服务的服务文件(启动脚本)

        ```sh
        cp -a /etc/init.d/vsftpd /etc/init.d/vsftpd_01
        cp -a /etc/init.d/vsftpd /etc/init.d/vsftpd_02
        ```

    2. 修改服务文件, 保证只按指定的配置文件启动 VSFTPD

        将原有的 `CONFS` 行注释, 新增一行 `CONFS`: 

        ```sh
        ~] vi /etc/init.d/vsftpd_01
        ...
        # CONFS=`ls /etc/vsftpd/*.conf 2>/dev/null`
        CONFS=`ls /etc/vsftpd/vsftpd_01.conf 2>/dev/null`
        ...

        ~] vi /etc/init.d/vsftpd_02
        ...
        # CONFS=`ls /etc/vsftpd/*.conf 2>/dev/null`
        CONFS=`ls /etc/vsftpd/vsftpd_02.conf 2>/dev/null`
        ...
        ```

    3. 添加 script 到集群

        ```sh
        ~] ccs -h rhel64-node01 --lsserviceopt script
        script - LSB-compliant init script as a clustered resource.
          Required Options:
            name: Name
            file: Path to script
          Optional Options:
            service_name: Inherit the service name.
            __independent_subtree: Treat this and all children as an independent subtree.
            __enforce_timeouts: Consider a timeout for operations as fatal.
            __max_failures: Maximum number of failures before returning a failure to a status check.
            __failure_expire_time: Amount of time before a failure is forgotten.
            __max_restarts: Maximum number restarts for an independent subtree before giving up.
            __restart_expire_time: Amount of time before a failure is forgotten for an independent subtree.


        ~] ccs -h rhel64-node01 --addresource script name="VSFTPD_01" file="/etc/init.d/vsftpd_01"
        ~] ccs -h rhel64-node01 --addresource script name="VSFTPD_02" file="/etc/init.d/vsftpd_02"
        ```

    添加完 IP, LVM, FS 和 SCRIPT 后, 配置文件内容如下: 

    ```html
    ~] ccs -h rhel64-node01 --getconf

    <cluster config_version="15" name="Cluster-VSFTPD">  
      <fence_daemon/>  
      <clusternodes>    
        <clusternode name="rhel64-node01" nodeid="1"/>    
        <clusternode name="rhel64-node02" nodeid="2"/>    
      </clusternodes>  
      <cman/>  
      <fencedevices/>  
      <rm>    
        <failoverdomains/>    
        <resources>      
          <ip address="192.168.161.18/24" family="ipv4" monitor_link="1" prefer_interface="eth0" sleeptime="10"/>      <!-- IP -->
          <ip address="192.168.161.19/24" family="ipv4" monitor_link="1" prefer_interface="eth0" sleeptime="10"/>      <!-- IP -->
          <lvm lv_name="data01" name="LVM_RHCS01" self_fence="1" vg_name="rhcs01"/>      <!-- LVM -->
          <lvm lv_name="data02" name="LVM_RHCS02" self_fence="1" vg_name="rhcs02"/>      <!-- LVM -->
          <fs device="/dev/mapper/rhcs01-data01" fstype="ext4" mountpoint="/data01" name="FS_data01" self_fence="1"/>      <!-- FS -->
          <fs device="/dev/mapper/rhcs02-data02" fstype="ext4" mountpoint="/data02" name="FS_data02" self_fence="1"/>      <!-- FS -->
          <script file="/etc/init.d/vsftpd_01" name="VSFTPD_01"/>      <!-- SCRIPT -->
          <script file="/etc/init.d/vsftpd_02" name="VSFTPD_02"/>      <!-- SCRIPT -->
        </resources>    
      </rm>  
    </cluster>
    ```

    ```sh
    ~] ccs -h rhel64-node01 --lsservices

    resources: 
      ip: monitor_link=1, sleeptime=10, prefer_interface=eth0, family=ipv4, address=192.168.161.18/24
      ip: monitor_link=1, sleeptime=10, prefer_interface=eth0, family=ipv4, address=192.168.161.19/24
      lvm: name=LVM_RHCS01, self_fence=1, vg_name=rhcs01, lv_name=data01
      lvm: name=LVM_RHCS02, self_fence=1, vg_name=rhcs02, lv_name=data02
      fs: name=FS_data01, device=/dev/mapper/rhcs01-data01, mountpoint=/data01, self_fence=1, fstype=ext4
      fs: name=FS_data02, device=/dev/mapper/rhcs02-data02, mountpoint=/data02, self_fence=1, fstype=ext4
      script: name=VSFTPD_01, file=/etc/init.d/vsftpd_01
      script: name=VSFTPD_02, file=/etc/init.d/vsftpd_02
    ```

### 2.9 配置 Fence


* 前言

    RHCS 6 配置 Fence 时, 有两种配置方式。以双节点为例: 

    * 方式一: 配置一个 Fence 设备, 两个节点作为两个实例添加到该 Fence 设备。适用于选择 vCenter/ESXi/KVM 等虚拟化平台或者集中式电源管理作为 Fence 设备的情况。配置示例: 

        ```html
            <clusternode name="rhel64-node01" nodeid="1">      
                <fence>        
                    <method name="xvm_method">          
                        <device name="XVM_FENCE" port="rhel64-01"/>          
                    </method>        
                </fence>      
            </clusternode>    
            <clusternode name="rhel64-node02" nodeid="2">      
                <fence>        
                    <method name="xvm_method">          
                        <device name="XVM_FENCE" port="rhel64-02"/>          
                    </method>        
                </fence>      
            </clusternode> 
        ...
        <fencedevices>    
                <fencedevice agent="fence_xvm" name="XVM_FENCE"/>    
        </fencedevices> 
        ```

    * 方式二: 配置两个 Fence 设备, 两个节点分别使用不同的 Fence 设备。适用于使用物理机 IPMI/带外/管理 接口作为 Fence 设备的情况。vCenter/ESXi/KVM 同样适用。配置示例: 

        ```html
            <clusternode name="rhel64-node01" nodeid="1" votes="1">
                <fence>
                    <method name="xvm_method">
                        <device delay="5" name="fencedev1"/>
                    </method>
                </fence>
                </clusternode>
            <clusternode name="rhel64-node02" nodeid="2" votes="1">
                <fence>
                    <method name="xvm_method">
                        <device name="fencedev2"/>
                    </method>
                </fence>
            </clusternode>
        ...
        <fencedevices>
            <fencedevice agent="fence_xvm" name="XVM_FENCE_1" port="rhel64-01"/>
            <fencedevice agent="fence_xvm" name="XVM_FENCE_2" port="rhel64-02"/>
        </fencedevices>
        ```
        .,bvcx


    配置语法: 

    ```text
    Fencing Operations:
          --lsfenceopts [fence type]
                            List available fence devices.  If a fence type is
                            specified, then list options for the specified
                            fence type
          --lsfencedev      List all of the fence devices configured
          --lsfenceinst [<node>]
                            List all of the fence methods and instances on the
                            specified node or all nodes if no node is specified
          --addmethod <method> <node>
                            Add a fence method to a specific node
          --rmmethod <method> <node>
                            Remove a fence method from a specific node
          --addfencedev <device name> [fence device options]
                            Add fence device. Fence devices and parameters can be
                            found in online documentation in 'Fence Device
                            Parameters'
          --rmfencedev <fence device name>
                            Remove fence device
          --addfenceinst <fence device name> <node> <method> [options]
                            Add fence instance. Fence instance parameters can be
                            found in online documentation in 'Fence Device
                            Parameters'
          --rmfenceinst <fence device name> <node> <method>
                            Remove all instances of the fence device listed from
                            the given method and node
          --addunfenceinst <fence device name> <node> [options]
                            Add an unfence instance
          --rmunfenceinst <fence device name> <node>
                            Remove all instances of the fence device listed from
                            the unfence section of the node
    ```


    常用的 Fence 设备: 

    ```sh
    ~] ccs -h rhel64-node01 --lsfenceopt

    ...
    fence_ipmilan - Fence agent for IPMI over LAN
    fence_vmware_soap - Fence agent for VMWare over SOAP API
    fence_xvm - Fence agent for virtual machines
    ```

* 前置操作

    参考 [1.9 配置 Fence](#19-配置-fence) `1.9.3 前置配置` 中的前置操作

    > When using SELinux with the High Availability Add-On in a VM environment, you should ensure that the SELinux boolean `fenced_can_network_connect` is persistently set to on. This allows the `fence_xvm` fencing agent to work properly, enabling the system to fence virtual machines.

    关于`post_fail_delay`,`post_join_delay`两个参数

    - `post_fail_delay`: the number of seconds the fence daemon ( `fenced` ) waits before fencing a node (a member of the fence domain) after the node has failed (default 0) .
    - `post_join_delay`: the number of seconds the fence daemon ( `fenced` ) waits before fencing a node after the node joins the fence domain. The `post_join_delay` default value is 6. A typical setting for `post_join_delay` is between 20 and 30 seconds, but can vary according to cluster and network performance.

    这两个参数需要同时设置, 如果只单独设置一个, 另一个会重置为默认值  

    ```sh
    ccs -h rhel64-node01 --setfencedaemon post_fail_delay=0 post_join_delay=25
    ```


* 使用 vCenter 作为 Fence 设备

    ```sh
    ] ccs -h rhel64-node01 --lsfenceopt fence_vmware_soap

    fence_vmware_soap - Fence agent for VMWare over SOAP API
      Required Options:
      Optional Options:
        option: No description available
        action: Fencing Action
        ipaddr: IP Address or Hostname
        login: Login Name
        passwd: Login password or passphrase
        passwd_script: Script to retrieve password
        ssl: SSL connection
        port: Physical plug number or name of virtual machine
        uuid: The UUID of the virtual machine to fence.
        ipport: TCP port to use for connection with device
        verbose: Verbose mode
        debug: Write debug information to given file
        version: Display version information and exit
        help: Display help and exit
        separator: Separator for CSV created by operation list
        power_timeout: Test X seconds for status change after ON/OFF
        shell_timeout: Wait X seconds for cmd prompt after issuing command
        login_timeout: Wait X seconds for cmd prompt after login
        power_wait: Wait X seconds after issuing ON/OFF
        delay: Wait X seconds before fencing is started
        retry_on: Count of attempts to retry power on
    ```

    ```sh
    # Example
    # Hostname: node01,node02; 
    # VM name: vm-node01,vm-node02

    # 找到虚拟机
    ~] fence_vmware_soap -a 192.168.163.252 -z -l administrator@vsphere.local -p 1qaz@WSX4rfv -o list
    ...
    vm-node01,422ad512-3ce5-c046-0046-9516094be718
    vm-node02,422ac3f0-e2f9-31a7-1816-7980e4757b80
    ...

    # 创建 fence 设备
    ~] ccs -h node01 --addfencedev VC_Fence agent=fence_vmware_soap ipaddr="192.168.163.252" login="administrator@vsphere.local" passwd="1qaz@WSX4rfv" action="reboot"

    # 为节点添加一个 method
    ~] ccs -h node01 --addmethod method_name node01
    ~] ccs -h node01 --addmethod method_name node02

    # 添加实例
    ~] ccs -h node01 --addfenceinst VC_Fence node01 method_name port=vm-node01 ssl=on uuid=422ad512-3ce5-c046-0046-9516094be718
    ~] ccs -h node01 --addfenceinst VC_Fence node02 method_name port=vm-node02 ssl=on uuid=422ac3f0-e2f9-31a7-1816-7980e4757b80
    
    # 删除
    ccs -h <host> --rmmethod <method> <node>
    ccs -h <host> --rmfenceinst --rmfenceinst <fence device name> <node> <method>
    ```

* ipmi: fence_ipmilan

    ```sh
    ~] ccs -h rhel64-node01 --lsfenceopt fence_ipmilan

    fence_ipmilan - Fence agent for IPMI over LAN
      Required Options:
      Optional Options:
        option: No description available
        auth: IPMI Lan Auth type (md5, password, or none)
        ipaddr: IPMI Lan IP to talk to
        passwd: Password (if required) to control power on IPMI device
        passwd_script: Script to retrieve password (if required)
        lanplus: Use Lanplus
        login: Username/Login (if required) to control power on IPMI device
        action: Operation to perform. Valid operations: on, off, reboot, status, list, diag, monitor or metadata
        timeout: Timeout (sec) for IPMI operation
        cipher: Ciphersuite to use (same as ipmitool -C parameter)
        method: Method to fence (onoff or cycle)
        power_wait: Wait X seconds after on/off operation
        delay: Wait X seconds before fencing is started
        privlvl: Privilege level on IPMI device
        verbose: Verbose mode
    ```

    ```sh
    # 验证
    ~] ipmitool -I lanplus -H x.x.x.x -U root -P 'Yth@2019' -v chassis power status

    # 创建 Fence 设备
    ccs -h node01 --addfencedev IPMI_Fence_01 agent=fence_ipmilan ipaddr="192.168.1.10" auth="password" login="admin" passwd="passw0rd" lanplus=1 power_wait=4
    ccs -h node01 --addfencedev IPMI_Fence_02 agent=fence_ipmilan ipaddr="192.168.1.11" auth="password" login="admin" passwd="passw0rd" lanplus=1 power_wait=4

    # 添加 method 和 instances
    ccs -h node01 --addmethod ipmi_method node01
    ccs -h node01 --addmethod ipmi_method node02

    ccs -h node01 --addfenceinst IPMI_Fence_01 node01 ipmi_method
    ccs -h node01 --addfenceinst IPMI_Fence_02 node02 ipmi_method
    ```

* KVM 虚拟机:  fence_xvm

    1. 从 KVM 宿主机(配置了 `fence_virtd` )中过去 Key 文件

        ```sh
        rhel64-node01 ~] scp {kvm_host}:/etc/cluster/fence_xvm.key /etc/cluster/
        rhel64-node02 ~] scp {kvm_host}:/etc/cluster/fence_xvm.key /etc/cluster/
        ```

    2. 验证本地能通过以下命令获取到各个节点信息, 并且状态 on

        ```sh
        ~] fence_xvm -o list
        rhel64-01            1cdcf5d4-d6f6-4251-9864-ec4b516fd344 on
        rhel64-02            999303cd-a80e-4a44-af38-b15fe7302f86 on
        ```

    3. 添加 Fence device, method, instance

        ```sh
        ccs -h rhel64-node01 --addfencedev XVM_FENCE_01 agent="fence_xvm" key_file="/etc/cluster/fence_xvm.key" port="rhel64-01"
        ccs -h rhel64-node01 --addfencedev XVM_FENCE_02 agent="fence_xvm" key_file="/etc/cluster/fence_xvm.key" port="rhel64-02"

        ccs -h rhel64-node01 --addmethod xvm_method rhel64-node01
        ccs -h rhel64-node01 --addmethod xvm_method rhel64-node02

        ccs -h rhel64-node01 --addfenceinst XVM_FENCE_01 rhel64-node01 xvm_method
        ccs -h rhel64-node01 --addfenceinst XVM_FENCE_02 rhel64-node02 xvm_method
        ```


* 后置操作

    检查/测试 fence 状态: 

    ```sh
    ~] fence_check     # 需要启动集群才能验证

    fence_check run at Wed Oct 14 14:49:47 CST 2020 pid: 19117
    Testing node03 method 1: success
    Testing node04 method 1: success
    ```

    测试 Fence 某个节点: 

    ```sh
    ~] fence_node node01
    ~] fence_node -vv node01
    ```

### 2.10 配置故障切换域

```text
Failover Domain Operations:
      --lsfailoverdomain
                        Lists all of the failover domains and failover domain
                        nodes configured in the cluster
      --addfailoverdomain <name> [restricted] [ordered] [nofailback]
                        Add failover domain
      --rmfailoverdomain <name>
                        Remove failover domain
      --addfailoverdomainnode <failover domain> <node> [priority]
                        Add node to given failover domain
      --rmfailoverdomainnode <failover domain> <node>
                        Remove node from failover domain
```

关于参数解释: 

1. `restricted`: 配置此参数, 集群服务限制在该故障切换域内运行; 如果域中无可用成员, 则服务启动失败。
2. `ordered`: 配置此参数, 故障切换域成员按列表顺序排优先级, 列表顶端的成员是首选成员, 接下来是列表中的第二个成员, 依此类推。
3. `nofailback`: 配置此参数, 故障节点恢复后, 服务不切回到原来节点上运行


创建故障切换域: 

```sh
ccs -h rhel64-node01 --addfailoverdomain VSFTPD_Domain_01 restricted ordered

ccs -h rhel64-node01 --addfailoverdomain VSFTPD_Domain_02 restricted ordered
```

添加域成员, 并指定顺序: 

```sh
ccs -h rhel64-node01 --addfailoverdomainnode VSFTPD_Domain_01 rhel64-node01 1 
ccs -h rhel64-node01 --addfailoverdomainnode VSFTPD_Domain_01 rhel64-node02 2 

ccs -h rhel64-node01 --addfailoverdomainnode VSFTPD_Domain_02 rhel64-node02 1 
ccs -h rhel64-node01 --addfailoverdomainnode VSFTPD_Domain_02 rhel64-node01 2 
```

添加完以后, 查看配置情况: 

```html
~] ccs -h rhel64-node01 --lsfailoverdomain

VSFTPD_Domain_01: restricted=1, ordered=1, nofailback=0
  rhel64-node01: priority=1
  rhel64-node02: priority=2
VSFTPD_Domain_02: restricted=1, ordered=1, nofailback=0
  rhel64-node02: priority=1
  rhel64-node01: priority=2

~] ccs -h rhel64-node01 --getconf

<cluster config_version="21" name="Cluster-VSFTPD">  
  <fence_daemon/>  
  <clusternodes>    
    <clusternode name="rhel64-node01" nodeid="1"/>    
    <clusternode name="rhel64-node02" nodeid="2"/>    
  </clusternodes>  
  <cman/>  
  <fencedevices/>  
  <rm>    
    <failoverdomains>      
      <failoverdomain name="VSFTPD_Domain_01" nofailback="0" ordered="1" restricted="1">        <!-- Failback Domain -->
        <failoverdomainnode name="rhel64-node01" priority="1"/>        
        <failoverdomainnode name="rhel64-node02" priority="2"/>        
      </failoverdomain>      
      <failoverdomain name="VSFTPD_Domain_02" nofailback="0" ordered="1" restricted="1">        <!-- Failback Domain -->
        <failoverdomainnode name="rhel64-node02" priority="1"/>        
        <failoverdomainnode name="rhel64-node01" priority="2"/>        
      </failoverdomain>      
    </failoverdomains>    
    <resources>      
      <ip address="192.168.161.18/24" family="ipv4" monitor_link="1" prefer_interface="eth0" sleeptime="10"/>      
      <ip address="192.168.161.19/24" family="ipv4" monitor_link="1" prefer_interface="eth0" sleeptime="10"/>      
      <lvm lv_name="data01" name="LVM_RHCS01" self_fence="1" vg_name="rhcs01"/>      
      <lvm lv_name="data02" name="LVM_RHCS02" self_fence="1" vg_name="rhcs02"/>      
      <fs device="/dev/mapper/rhcs01-data01" fstype="ext4" mountpoint="/data01" name="FS_data01" self_fence="1"/>      
      <fs device="/dev/mapper/rhcs02-data02" fstype="ext4" mountpoint="/data02" name="FS_data02" self_fence="1"/>      
      <script file="/etc/init.d/vsftpd_01" name="VSFTPD_01"/>      
      <script file="/etc/init.d/vsftpd_02" name="VSFTPD_02"/>      
    </resources>    
  </rm>  
</cluster>
```


### 2.11 配置仲裁

> Quorum Disk is a disk-based quorum daemon, `qdiskd`, that provides supplemental heuristics to determine node fitness. With heuristics you can determine factors that are important to the operation of the node in the event of a network partition. For example, in a four-node cluster with a 3:1 split, ordinarily, the three nodes automatically "win" because of the three-to-one majority. Under those circumstances, the one node is fenced. With `qdiskd` however, you can set up heuristics that allow the one node to win based on access to a critical resource (for example, a critical network path). If your cluster requires additional methods of determining node health, then you should configure qdiskd to meet those needs.<sup>仲裁磁盘是使用磁盘的仲裁守护进程 qdiskd, 它可提供补充的试探法（heuristics）以确定节点是否正常运作。使用这些试探法, 您可以确定在网络分区事件中对节点操作十分重要的因素。例如: 在一个按 3:1 分割的有四个节点的集群中, 最初三个节点自动“获胜”, 因为三对一的占优。在那些情况下, 只有一个节点被 fence。但使用 qdiskd, 您可以设定试探法以便允许一个节点因访问重要资源获胜（例如: 关键网络路径）。如果您的集群需要额外的方法确定节点工作正常, 那么您应该将 qdiskd 配置为满足那些要求。</sup>

配置仲裁的一些要求:

1. 每个集群节点投票权 (vote) 相同, 且都为 1;
2. 仲裁设备成员超时值是根据 CMAN 成员超时值 ( 即 CMAN 认为节点已死, 并不再是成员前该节点不响应的时间 ) 自动配置的; 如果要修改这个值, 应当保证 CMAN 超时值至少是 仲裁设备的 2 倍;
3. Fence 可用;
4. 最多支持 16 节点;
5. 最小 10Mb 的共享磁盘作为仲裁盘。

```sh
Quorum Operations:
      --lsquorum        List quorum options and heuristics
      --setquorumd [quorumd options] ...
                        Add quorumd options
      --addheuristic [heuristic options] ...
                        Add heuristics to quorumd
      --rmheuristic [heuristic options] ...
                        Remove heuristic specified by heurstic options
```


* 2.11.1 为节点添加一块共享磁盘, 映射为 "vdd"

    ```sh
    kvm-host ~] qemu-img create -f raw rhel64-rhcs-100m.raw 100M

    kvm-host ~] virsh attach-disk --domain rhel64-01 --source /var/lib/libvirt/images/rhel64-rhcs-100m.raw --target vdd --targetbus virtio --driver qemu --subdriver raw --shareable --current
    kvm-host ~] virsh attach-disk --domain rhel64-01 --source /var/lib/libvirt/images/rhel64-rhcs-100m.raw --target vdd --targetbus virtio --driver qemu --subdriver raw --shareable --config

    kvm-host ~] virsh attach-disk --domain rhel64-02 --source /var/lib/libvirt/images/rhel64-rhcs-100m.raw --target vdd --targetbus virtio --driver qemu --subdriver raw --shareable --current
    kvm-host ~] virsh attach-disk --domain rhel64-02 --source /var/lib/libvirt/images/rhel64-rhcs-100m.raw --target vdd --targetbus virtio --driver qemu --subdriver raw --shareable --config
    ```

* 2.11.2 格式化磁盘为仲裁盘

    ```sh
    usage: mkqdisk -L | -f <label> | -c <device> -l <label> [-d]

    ~] mkqdisk -c /dev/vdd -l rhel64-rhcs-qdisk

    ~] mkqdisk -L       # 检查创建结果, 两个节点都检查一下
    mkqdisk v3.0.12.1
    
    /dev/block/252:48:
    /dev/disk/by-path/pci-0000:00:0c.0-virtio-pci-virtio7:
    /dev/vdd:
            Magic:                eb7a62c2
            Label:                rhel64-rhcs-qdisk
            Created:              Fri Apr  1 15:21:06 2022
            Host:                 rhel64-node01
            Kernel Sector Size:   512
            Recorded Sector Size: 512
    ```

* 2.11.3 添加仲裁盘到集群, 并配置启发式 (`heuristic`, 即检测脚本, 频率等)

    ```sh
    # ccs -h host --setquorumd [quorumd options]
    
    ccs -h rhel64-node01 --setquorumd label=rhel64-rhcs-qdisk device=/dev/vdd
    ```

    quorum disk options: 

    Parameter | Description 
    -- | --
    `interval` | The frequency of read/write cycles, in seconds. 
    `votes` | The number of votes the quorum daemon advertises to cman when it has a high enough score. 
    `tko` | The number of cycles a node must miss to be declared dead. 
    `min_score` | The minimum score for a node to be considered "alive". <br>If omitted or set to 0, the default function, ***floor((n+1)/2)***, is used, where *n* is the sum of the heuristics scores. <br>The **Minimum Score** value must never exceed the sum of the heuristic scores; otherwise, the quorum disk cannot be available. 
    `device` | The storage device the quorum daemon uses. The device must be the same on all nodes. 
    `label` | Specifies the quorum disk label created by the mkqdisk utility. <br>If this field contains an entry, the label overrides the Device field. <br>If this field is used, the quorum daemon reads `/proc/partitions` and checks for qdisk signatures on every block device found, comparing the label against the specified label. <br>This is useful in configurations where the quorum device name differs among nodes.


    ```sh
    # ccs -h host --addheuristic [heuristic options]

    ccs -h rhel64-node01 --addheuristic program="/bin/ping -c1 -t2 10.168.161.14" interval=1 score=1 tko=5
    ```

    > 注: 实验测试过程中, 使用 KVM 宿主机的 bridge 网卡 IP (10.168.161.1) 作为 ping 检测的目标 IP, 会让 quorum 产生错误的判断: 当在节点 1 上执行 `ifdown eth1` 以后, 两个节点的日志文件中都出现了 fence 对方节点的日志, 但是实际上节点 2 会被先 fence; 节点 2 正常启动以后, 节点 1 重启。可能和 KVM/qemu 的网络有关系, 为了避免出错, 建议使用另一台虚拟机上的 IP 作为检查。


    quorum disk heuristic: 

    Parameter | Description 
    --|--
    `program` | The path to the program used to determine if this heuristic is available. <br>This can be anything that can be executed by /bin/sh -c. A return value of 0 indicates success; anything else indicates failure. <br>This parameter is required to use a quorum disk.   
    `interval` | The frequency (in seconds) at which the heuristic is polled. The default interval for every heuristic is 2 seconds.   
    `score` | The weight of this heuristic. Be careful when determining scores for heuristics. The default score for each heuristic is 1.   
    `tko` | The number of consecutive failures required before this heuristic is declared unavailable.  

* 2.11.4 添加后检查

    ```sh
    ~] ccs -h rhel64-node01 --lsquorum

    Quorumd: device=/dev/vdd, label=rhel64-rhcs-qdisk
      heuristic: program=/bin/ping -c1 -t2 10.168.161.1, interval=2, score=1, tko=2


    ~] ccs -h rhel64-node01 --getconf

      <quorumd device="/dev/vdd" label="rhel64-rhcs-qdisk">    
        <heuristic interval="2" program="/bin/ping -c1 -t2 10.168.161.14" score="1" tko="2"/>    
      </quorumd> 
    ```


### 2.12 配置服务

* 创建服务

    ```text
    ~] ccs -h host --addservice <servicename> [service options]
    ```

    Service Options:

    * `autostart` — Specifies whether to autostart the service when the cluster starts. Use "1" to enable and "0" to disable; the default is enabled.
    * `domain` — Specifies a failover domain (if required).
    * `exclusive` — Specifies a policy wherein the service only runs on nodes that have no other services running on them.
    * `recovery` — Specifies a recovery policy for the service. The options are to relocate, restart, disable, or restart-disable the service. 
        * The "`restart`" recovery policy indicates that the system should attempt to restart the failed service before trying to relocate the service to another node. 
        * The "`relocate`" policy indicates that the system should try to restart the service in a different node. 
        * The "`disable`" policy indicates that the system should disable the resource group if any component fails. 
        * The "`restart-disable`" policy indicates that the system should attempt to restart the service in place if it fails, but if restarting the service fails the service will be disabled instead of being moved to another host in the cluster.
            
        If you select `restart` or `restart-disable` as the recovery policy for the service, you can specify *the maximum number of restart failures* before relocating or disabling the service, and you can specify *the length of time in seconds after which to forget a restart*.
    
    * `__independent_subtree` - Treat this and all children as an independent subtree.
    * `__enforce_timeouts` - Consider a timeout for operations as fatal.
    * `__max_failures` - Maximum number of failures before returning a failure to a status check.
    * `__failure_expire_time` - Amount of time before a failure is forgotten.
    * `__max_restarts` - Maximum number restarts for an independent subtree before giving up.
    * `__restart_expire_time` - Amount of time before a failure is forgotten for an independent subtree.

    ```sh
    ccs -h rhel64-node01 --addservice VSFTPD_SERVICE_01 autostart=1 domain=VSFTPD_Domain_01 exclusive=0 recovery=restart __max_failures=3 __restart_expire_time=300
    ccs -h rhel64-node01 --addservice VSFTPD_SERVICE_02 autostart=1 domain=VSFTPD_Domain_02 exclusive=0 recovery=restart __max_failures=3 __restart_expire_time=300
    ```

* 添加全局资源到服务

    ```text
    service: name=VSFTPD_SERVICE_01, exclusive=0, domain=VSFTPD_Domain_01, __max_failures=3, autostart=1, __restart_expire_time=300, recovery=restart
    service: name=VSFTPD_SERVICE_02, exclusive=0, domain=VSFTPD_Domain_02, __max_failures=3, autostart=1, __restart_expire_time=300, recovery=restart
    resources: 
      ip: monitor_link=1, sleeptime=10, prefer_interface=eth0, family=ipv4, address=192.168.161.18/24
      ip: monitor_link=1, sleeptime=10, prefer_interface=eth0, family=ipv4, address=192.168.161.19/24
      lvm: name=LVM_RHCS01, self_fence=1, vg_name=rhcs01, lv_name=data01
      lvm: name=LVM_RHCS02, self_fence=1, vg_name=rhcs02, lv_name=data02
      fs: name=FS_data01, device=/dev/mapper/rhcs01-data01, mountpoint=/data01, self_fence=1, fstype=ext4
      fs: name=FS_data02, device=/dev/mapper/rhcs02-data02, mountpoint=/data02, self_fence=1, fstype=ext4
      script: name=VSFTPD_01, file=/etc/init.d/vsftpd_01
      script: name=VSFTPD_02, file=/etc/init.d/vsftpd_02
    ```

    将 ip, lvm, fs, script 都添加到服务中: 

    ```sh
    # ccs -h host --addsubservice servicename subservice [service options]

    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 ip ref="192.168.161.18/24"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 lvm ref="LVM_RHCS01"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 fs ref="FS_data01"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 script ref="VSFTPD_01"

    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 ip ref="192.168.161.19/24"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 lvm ref="LVM_RHCS02"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 fs ref="FS_data02"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 script ref="VSFTPD_02"
    ```

    添加完以后配置文件如下: 

    ```html
    ~] ccs -h rhel64-node01 --getconf

    ...
    <service __max_failures="3" __restart_expire_time="300" autostart="1" domain="VSFTPD_Domain_01" exclusive="0" name="VSFTPD_SERVICE_01" recovery="restart">      
      <ip ref="192.168.161.18/24"/>      
      <lvm ref="LVM_RHCS01"/>      
      <fs ref="FS_data01"/>      
      <script ref="VSFTPD_01"/>      
    </service>    
    <service __max_failures="3" __restart_expire_time="300" autostart="1" domain="VSFTPD_Domain_02" exclusive="0" name="VSFTPD_SERVICE_02" recovery="restart">      
      <ip ref="192.168.161.19/24"/>      
      <lvm ref="LVM_RHCS02"/>      
      <fs ref="FS_data02"/>      
      <script ref="VSFTPD_02"/>      
    </service> 
    ... 
    ```

    由于我们添加的资源有 “先后” 关系, 如 IP 启动后才能正常启动 VSFTPD,  LVM 启动后 FS 才能正常挂载。
    
    因此服务添加应该按照以下方法为: 

    ```sh
    # 移除资源
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_01 ip
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_01 lvm 
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_01 fs
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_01 script
    
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_02 ip
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_02 lvm 
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_02 fs
    ccs -h rhel64-node01 --rmsubservice VSFTPD_SERVICE_02 script

    # 重新添加资源, 按 "父-子" 顺序
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 ip ref="192.168.161.18/24"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 ip:lvm ref="LVM_RHCS01"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 ip:lvm:fs ref="FS_data01"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_01 ip:lvm:fs:script ref="VSFTPD_01"

    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 ip ref="192.168.161.19/24"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 ip:lvm ref="LVM_RHCS02"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 ip:lvm:fs ref="FS_data02"
    ccs -h rhel64-node01 --addsubservice VSFTPD_SERVICE_02 ip:lvm:fs:script ref="VSFTPD_02"
    ```

    此时, 配置文件内容如下（注意与第一次添加时对比的差异）: 

    ```html
    ~] ccs -h rhel64-node01 --getconf

    ...
    <service __max_failures="3" __restart_expire_time="300" autostart="1" domain="VSFTPD_Domain_01" exclusive="0" name="VSFTPD_SERVICE_01" recovery="restart">      
      <ip ref="192.168.161.18/24">        
        <lvm ref="LVM_RHCS01">          
          <fs ref="FS_data01">            
            <script ref="VSFTPD_01"/>            
          </fs>          
        </lvm>        
      </ip>      
    </service>    
    <service __max_failures="3" __restart_expire_time="300" autostart="1" domain="VSFTPD_Domain_02" exclusive="0" name="VSFTPD_SERVICE_02" recovery="restart">      
      <ip ref="192.168.161.19/24">        
        <lvm ref="LVM_RHCS02">          
          <fs ref="FS_data02">            
            <script ref="VSFTPD_02"/>            
          </fs>          
        </lvm>        
      </ip>      
    </service> 
    ...
    ```

### 2.13 配置其他集群属性


* 2.13.1 查看集群其他属性配置情况

    ```sh
    ccs -h host --lsmisc
    ```

* 2.13.2 集群配置文件版本

    ```sh
    ccs -h host --getversion     # 查看版本
    ccs -h host --setversion n   # 设置
    ccs -h host --incversion     # 版本值 +1
    ```

* 2.13.3 多播地址

    ```sh
    ccs -h <host> --setmulticast <multicastaddress>  # 设置
    ccs -h host --setmulticast                       # 移除（不添加参数）
    ```

    如果未指定多播地址, cman 会基于集群 ID 自动生成: 239.192.x.x (IPv4) / FF15:: (IPv6)

* 2.13.4 两节点集群的配置

    ```sh
    ccs -h <host> --setcman two_node=1 expected_votes=1

    # ccs -h rhel64-node01 --setcman two_node=1 expected_votes=1
    ```

* 2.13.5 日志配置

    ```html
    ~] man cluster.conf

    Logging
        Cluster daemons use a common logging section to configure their 
        loggging behavior.

            <cluster name="alpha" config_version="1">
                    <logging/>
            </cluster>

        Global settings apply to all:

            <logging debug="on"/>

        Per-daemon logging_daemon subsections override the global settings. 
        Daemon names that can be configured include: corosync, qdiskd, groupd, 
        fenced, dlm_controld, gfs_controld, rgmanager.

            <logging>
                    <logging_daemon name="qdiskd" debug="on"/>
                    <logging_daemon name="fenced" debug="on"/>
            </logging>

        Corosync daemon settings apply to all corosync subsystems by default, 
        but subsystems can also be configured individually. These include CLM, 
        CPG, MAIN, SERV, CMAN, TOTEM, QUORUM, CONFDB, CKPT, EVT.

            <logging>
                    <logging_daemon name="corosync" subsys="QUORUM" debug="on"/>
                    <logging_daemon name="corosync" subsys="CONFDB" debug="on"/>
            </logging>

        The attributes available at global, daemon and subsystem levels are:

        to_syslog
                enable/disable messages to syslog (yes/no), default "yes"

        to_logfile
                enable/disable messages to log file (yes/no), default "yes"

        syslog_facility
                facility used for syslog messages, default "daemon"

        syslog_priority
                messages at this level and up will be sent to syslog, default "info"

        logfile_priority
                messages at this level and up will be written to log file, default "info"

        logfile
                the log file name, default /var/log/cluster/<daemon>.log

        debug="on"

    EXAMPLE
        An explicit configuration for the default settings would be:

            <logging to_syslog="yes" to_logfile="yes" syslog_facility="daemon"
                    syslog_priority="info" logfile_priority="info">
                <logging_daemon name="qdiskd"
                        logfile="/var/log/cluster/qdiskd.log"/>
                <logging_daemon name="fenced"
                        logfile="/var/log/cluster/fenced.log"/>
                <logging_daemon name="dlm_controld"
                        logfile="/var/log/cluster/dlm_controld.log"/>
                <logging_daemon name="gfs_controld"
                        logfile="/var/log/cluster/gfs_controld.log"/>
                <logging_daemon name="rgmanager"
                        logfile="/var/log/cluster/rgmanager.log"/>
                <logging_daemon name="corosync"
                        logfile="/var/log/cluster/corosync.log"/>
            </logging>

        To include debug messages (and above) from all daemons in their default log files, 
        either of the following which are equivalent:

            <logging debug="on"/>
            <logging logfile_priority="debug"/>

        To exclude all log messages from syslog:

            <logging to_syslog="no"/>

        To disable logging to all log files:

            <logging to_file="no"/>

        To include debug messages (and above) from all daemons in syslog:

            <logging syslog_priority="debug"/>

        To limit syslog messages to error (and above), keeping info (and above) in log files 
        (this logfile_priority setting is the default so could be omitted):

            <logging syslog_priority="error" logfile_priority="info"/>
    ```

    典型配置: 

    ```sh
    ccs -h rhel64-node01 --setlogging to_syslog=yes syslog_facility=daemon syslog_priority=info to_logfile=yes logfile_priority=info
    ccs -h rhel64-node01 --addlogging name=qdiskd logfile="/var/log/cluster/qdiskd.log"
    ccs -h rhel64-node01 --addlogging name=fenced logfile="/var/log/cluster/fenced.log"
    ccs -h rhel64-node01 --addlogging name=dlm_controld logfile="/var/log/cluster/dlm_controld.log"
    ccs -h rhel64-node01 --addlogging name=gfs_controld logfile="/var/log/cluster/gfs_controld.log"
    ccs -h rhel64-node01 --addlogging name=rgmanager logfile="/var/log/cluster/rgmanager.log"
    ccs -h rhel64-node01 --addlogging name=corosync logfile="/var/log/cluster/corosync.log"
    ```

* 2.13.6 同步配置文件到其他节点

    ```sh
    ccs -h <host> --sync --activate
    ccs -h <host> --checkconf
    ccs -f <file> -h <host> --setconf
    ccs -f file --checkconf
    ```

### 2.14 管理集群

* 集群管理

    ```sh
    ccs -h <host> --start  # Start *AND* enable cluster services on reboot for host specified with "-h"
    ccs -h <host> --stop   # Stop *AND* disable cluster services on reboot for host specified with "-h"
    ccs -h <host> --startall [--noenable]  # Start *AND* enable cluster services on reboot for all nodes
    ccs -h <host> --stopall [--noenable]   #Stop *AND* disable cluster services on reboot for all nodes
    ```

* 节点管理

    ```sh
    ccs -h <host> --lsnode
    ccs -h <host> --addnode <node> [--nodeid <nodeid>] [--vote <nodeid>]
    ccs -h <host> --rmnode <node>
    ```

* 集群服务管理: `clusvcadm`

    ```text
    Resource Group Control Commands:
      -v                     Display version and exit
      -d <group>             Disable <group>.  This stops a group
                             until an administrator enables it again,
                             the cluster loses and regains quorum, or
                             an administrator-defined event script
                             explicitly enables it again.
      -e <group>             Enable <group>
      -e <group> -F          Enable <group> according to failover
                             domain rules (deprecated; always the
                             case when using central processing)
      -e <group> -m <member> Enable <group> on <member>
      -r <group> -m <member> Relocate <group> [to <member>]
                             Stops a group and starts it on another
                             cluster member.
      -M <group> -m <member> Migrate <group> to <member>
                             (e.g. for live migration of VMs)
      -q                     Quiet operation
      -R <group>             Restart a group in place.
      -s <group>             Stop <group>.  This temporarily stops
                             a group.  After the next group or
                             or cluster member transition, the group
                             will be restarted (if possible).
      -Z <group>             Freeze resource group.  This prevents
                             transitions and status checks, and is 
                             useful if an administrator needs to 
                             administer part of a service without 
                             stopping the whole service.
      -U <group>             Unfreeze (thaw) resource group.  Restores
                             a group to normal operation.
      -c <group>             Convalesce (repair, fix) resource group.
                             Attempts to start failed, non-critical 
                             resources within a resource group.
    Resource Group Locking (for cluster Shutdown / Debugging):
      -l                     Lock local resource group managers.
                             This prevents resource groups from
                             starting.
      -S                     Show lock state
      -u                     Unlock resource group managers.
                             This allows resource groups to start.
    ```


## 对比 RHCS 6 和 RHCS 7

* Cluster configuration file locations

    Redhat Cluster Releases	|Configuration files | Description
    --|--|--
    Prior to Redhat Cluster 7 | /etc/cluster/cluster.conf | Stores all the configuration of cluster
    Redhat Cluster 7 (RHEL 7) | /etc/corosync/corosync.conf | Membership and Quorum configuration
    Redhat Cluster 7 (RHEL 7) | /var/lib/heartbeat/crm/cib.xml | Cluster node and Resource configuration.

* Commands

    Configuration Method | Prior to Redhat Cluster 7 | Redhat Cluster 7 (RHEL 7)
    --|--|--
    Command Line utiltiy | ccs | pcs
    GUI tool | luci | PCSD – Pacemaker Web GUI Utility

* Services

    Redhat Cluster Releases | Services | Description
    --|--|--
    Prior to Redhat Cluster 7 | rgmanager	 | Cluster Resource Manager.
    Prior to Redhat Cluster 7 | cman	     | Manages cluster quorum and cluster membership.
    Prior to Redhat Cluster 7 | ricci	     | Cluster management and configuration daemon.
    Redhat Cluster 7 (RHEL 7) | pcsd.service | Cluster  Resource Manager.
    Redhat Cluster 7 (RHEL 7) | corosync.service | Manages cluster quorum and cluster membership.

    NOTES: 上表中的 `cman` 服务, 实际上也是由 `corosync` 提供: 
    
    ```sh
    ~] service cman status
    corosync is stopped
    ```

* Cluster user

    User Access	| Prior to Redhat Cluster 7 | Redhat Cluster 7 (RHEL 7)
    --|--|--
    Cluster user name | ricci | hacluster

* How simple to create a cluster on RHEL 7 ?

    Redhat Cluster Releases | Cluster Creation | Description
    --|--|--
    Prior to Redhat Cluster 7 | `ccs -h node1.ua.com –createcluster uacluster` | Create cluster on first node using ccs
    Prior to Redhat Cluster 7 | `ccs -h node1.ua.com –addnode node2.ua.com` | Add the second node  to the existing cluster
    Redhat Cluster 7 (RHEL 7) | `pcs cluster setup uacluster node1 node2` | Create a cluster on both the nodes using pcs

* Is there any pain to remove a cluster in RHEL 7 ?  No. It’s very simple.

    Redhat Cluster Releases | Remove Cluster | Description
    --|--|--
    Prior to Redhat Cluster 7 | `rm /etc/cluster/cluster.conf` | Remove the cluster.conf file on each cluster nodes
    Prior to Redhat Cluster 7 | `service rgmanager stop`<br>`service cman stop`<br> `service ricci stop` | Stop the cluster services on each cluster nodes
    Prior to Redhat Cluster 7 | `chkconfig rgmanager off`<br> `chkconfig cman off`<br>`chkconfig ricci off`| Disable the cluster services from startup
    Redhat Cluster 7 (RHEL 7) | `pcs cluster destroy` | Destroy the cluster in one-shot using pacemaker


## Others

* [RHCS-Conga界面搭建HA.pdf](./RHCS-HA_with_Conga.pdf)
* [RHCS-Pacemaker_Overview.pdf](./RHCS-Pacemaker_Overview.pdf)