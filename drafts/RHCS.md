# RHCS, Red Hat Cluster Suite

实验目的: 

* `Demo 1` 使用 RedHat Enterprise Linux 7.6 上搭建一套双机双业务互为冗余的 VSFTPD RHCS 集群
* `Demo 2` 使用 RedHat Enterprise Linux 6.4 上搭建一套双机双业务互为冗余的 VSFTPD RHCS 集群

## 环境准备工作

### 准备时间源

    使用 `chrony` 或者 `ntp` 搭建时间源, 此处不做赘述

### 准备共享存储 

共享存储种类: 

* 生产环境: SAN 存储或者 iSCSI 企业级软件实现共享存储 (如 `OpenFiler`)
* 实验环境: Linux 系统 Linux-IO Target 实现 iSCSI 共享存储; 或者 KVM/VMware 等虚拟化平台虚拟的共享磁盘


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

    ```sh
    ~] targetcli ls 

    o- / .............................................................................. [...]
      o- backstores ................................................................... [...]
      | o- block ....................................................... [Storage Objects: 1]
      | | o- disk01 ............................... [/dev/sdc (10.0GiB) write-thru activated]
      | |   o- alua ........................................................ [ALUA Groups: 1]
      | |     o- default_tg_pt_gp ............................ [ALUA state: Active/optimized]
      | o- fileio ...................................................... [Storage Objects: 0]
      | o- pscsi ....................................................... [Storage Objects: 0]
      | o- ramdisk ..................................................... [Storage Objects: 0]
      o- iscsi ................................................................. [Targets: 1]
      | o- iqn.2019-12.com.test:rhcs .............................................. [TPGs: 1]
      |   o- tpg1 .................................................... [no-gen-acls, no-auth]
      |     o- acls ............................................................... [ACLs: 2]
      |     | o- iqn.2019-12.com.test:rhcs_node01........................... [Mapped LUNs: 1]
      |     | | o- mapped_lun0 ..................................... [lun0 block/disk01 (rw)]
      |     | o- iqn.2019-12.com.test:rhcs_node02........................... [Mapped LUNs: 1]
      |     |   o- mapped_lun0 ..................................... [lun0 block/disk01 (rw)]
      |     o- luns ............................................................... [LUNs: 1]
      |     | o- lun0 ...........................[block/disk01 (/dev/sdb) (default_tg_pt_gp)]
      |     o- portals ......................................................... [Portals: 1]
      |       o- 20.168.161.240:3260 ................................................... [OK]
      o- loopback .............................................................. [Targets: 0]
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

        原因：服务端的 `lvm2-lvmetad.service` 将客户端的 Lvm 元素据识别并纳管, 导致 target 绑定的磁盘 `/dev/sdb` 无法被识别。

        解决：修改 `/etc/lvm/lvm.conf` 中 `volume_list = [ "rhel_host0" ]`, 即只将主机上的卷组添加进去, 其他的不添加。修改完毕以后, 关闭 target 服务, 重启 `lvm2-lvmetad.service` (建议重启操作系统)

* KVM 虚拟机使用共享磁盘

    ```sh
    # 创建
    qemu-img create -f raw /var/lib/libvirt/images/rhel76-rhcs-10g-01.raw 10G
    qemu-img create -f raw /var/lib/libvirt/images/rhel76-rhcs-10g-02.raw 10G

    # 挂载
    cd /var/lib/libvirt/images
    virsh attach-disk --domain node01 --source rhel76-rhcs-10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node01 --source rhel76-rhcs-10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --config
    virsh attach-disk --domain node01 --source rhel76-rhcs-10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node01 --source rhel76-rhcs-10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config

    virsh attach-disk --domain node02 --source rhel76-rhcs-10g-01.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node02 --source rhel76-rhcs-10g-01.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
    virsh attach-disk --domain node02 --source rhel76-rhcs-10g-02.raw --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node02 --source rhel76-rhcs-10g-02.raw --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
    ```

* VMware 虚拟机使用共享磁盘

    Workstation/vSphere 等可创建使用共享磁盘

## Demo 1: RHCS via RHEL 6.7


|  Hostname  | Management IP  | HeartBeat IP  | Storage IP (Optional)  |
| ---------- | :------------: | :-----------: | :--------------------: |
| node01     | 192.168.161.12 | 10.168.161.12 | 20.168.161.12          |
| node02     | 192.168.161.13 | 10.168.161.13 | 20.168.161.13          |

> *主要内容: 配置时间同步, 添加主机解析记录, 网卡绑定, 挂载共享存储, 创建文件系统, 配置 VSFTPD 服务*


### 配置时间同步

两个节点配置到同一时间源, 使用 `ntpd` 或者 `chronyd` 均可

### 配置主机解析记录

两个节点都需要配置, 在 `/etc/hosts` 添加以下两行; 注意使用的 IP 是心跳 IP, 如果资源不足也可和管理 IP 共用

```sh
~] vi /etc/hosts

10.168.161.12 node01
10.168.161.13 node02
```

### 配置网卡绑定

有网络冗余要求, 可配置 `Team` 或者 `Bonding`, Refer to: *[Bonding](Bonding.md)* or *[Team](Team.md)*

### 配置共享存储

KVM/VMware 虚拟机使用共享磁盘, 直接在平台操作挂载以后即可, 无需额外操作, 下文介绍 iSCSI Inititor 配置方法

* 安装

    ```sh
    yum install iscsi-initiator-utils
    ```

* 配置

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

* 发现 iSCSI 目标

    ```sh
    ~] iscsiadm --mode discoverydb --type sendtargets --portal 20.192.168.1 --discover

    20.192.168.1:3260,1 iqn.2019-12.com.test:rhcs
    ```

* 登录/连接

    ```sh
    ~] iscsiadm --mode node --targetname iqn.2019-12.com.test:rhcs --portal 20.192.168.1:3260 --login

    Logging in to [iface: default, target: iqn.2019-12.com.test:targer01, portal: 20.20.20.240,3260] (multiple)
    Login to [iface: default, target: iqn.2019-12.com.test:targer01, portal: 20.20.20.240,3260] successful.
    ```

* 登出/断开连接

    先取消所有磁盘占用, 然后执行以下命令：

    ```sh
    iscsiadm --mode node --targetname iqn.2019-12.com.test:rhcs --portal 20.192.168.1:3260 --logout
    ```


> 以上三步 (挂载, 登录, 登出) 可参考 `iscsiadm` man 文档的 `EXAMPLE` 部分获取帮助


两个节点均发现磁盘, 表明配置正常：

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

### 配置文件系统

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

* 正常识别后, 将所有节点将卷组激活


### 配置 VSFTPD 服务

> 本次实验搭建双机双业务互为冗余的 VSFTPD 集群, 因此两个节点都需要配置 VSFTPD 服务

* 添加用户及挂载点

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

* 修改 VSFTPD 配置文件

    两个节点都需要添加这两个配置文件 `/etc/vsftpd/vsftpd_ftp01.conf`, `/etc/vsftpd/vsftpd_ftp02.conf`, 分别配置两个 VSFTPD 实例: 

    ```sh
    ~] vi /etc/vsftpd/vsftpd_ftp01.conf

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
    listen_ipv6=NO
    pam_service_name=vsftpd_01
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
    ~] vi /etc/vsftpd/vsftpd_ftp02.conf

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
    listen_ipv6=NO
    pam_service_name=vsftpd_02
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

    两个节点添加 `user_list` 和 `chroot_list` 共四个文件, 和主配置文件中相应配置项保持一致:

    ```sh
    ~] vi user_list01
    ftpuser01
    ftpuser0101

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


* 防火墙配置

    如果启用了防火墙, 则需要添加策略:

    ```sh
    firewall-cmd --add-service=ftp --permanent
    firewall-cmd --reload
    ```

### 配置集群


* 安装集群套件

    ```sh
    yum groupinstall 'High Availability'
    ```

    如果启用了防火墙, 则需要添加策略:

    ```sh
    firewall-cmd --add-service=high-availability --permanent
    firewall-cmd --reload
    ```

* 初始化集群

    * 启动 `pcsd` 服务

        设置开机自启:

        ```sh
        systemctl start pcsd.service
        systemctl enable pcsd.service
        ```

    * 修改 `hacluster` 服务用户密码

        `hacluster` 用户是集群 `pcsd` 进程认证需要使用的用户; 添加节点到集群时, 需要验证此用户的密码

        ```sh
        echo '123qweQ' | passwd hacluster  --stdin
        ```

    * 节点认证

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

* 创建集群

    ```sh
    ~] pcs cluster setup --name Cluster-VSFTPD rhel76-node01 rhel76-node02

    Destroying cluster on nodes: rhel76-node01, rhel76-node02...
    rhel76-node01: Stopping Cluster (pacemaker)...
    rhel76-node02: Stopping Cluster (pacemaker)...
    rhel76-node02: Successfully destroyed cluster
    rhel76-node01: Successfully destroyed cluster

    Sending 'pacemaker_remote authkey' to 'rhel76-node01', 'rhel76-node02'
    rhel76-node01: successful distribution of the file 'pacemaker_remote authkey'
    rhel76-node02: successful distribution of the file 'pacemaker_remote authkey'
    Sending cluster config files to the nodes...
    rhel76-node01: Succeeded
    rhel76-node02: Succeeded

    Synchronizing pcsd certificates on nodes rhel76-node01, rhel76-node02...
    rhel76-node02: Success
    rhel76-node01: Success
    Restarting pcsd on the nodes in order to reload the certificates...
    rhel76-node02: Success
    rhel76-node01: Success
    ```


    * 启动集群服务

        ```sh
        ~] pcs status
        Error: cluster is not currently running on this node
        ```

        ```sh
        ~] pcs cluster start --all

        rhel76-node01: Starting Cluster (corosync)...
        rhel76-node02: Starting Cluster (corosync)...
        rhel76-node02: Starting Cluster (pacemaker)...
        rhel76-node01: Starting Cluster (pacemaker)...

        #上面的命令会触发:
        # systemctl start corosync.service
        # systemctl start pacemaker.service

        ~] systemctl enable corosync.service pacemaker.service
        ```

* 状态检查

    * 检查 `corosync` 状态

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

    * 检查 `pacemaker` 状态

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

    * 集群基础配置信息检测

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


### 配置服务托管

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


* 添加 IP

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


* 添加 HA-LVM

    将卷组交由 RHCS 集群管理, 需先解除本地 LVM 对卷组的管理, 然后配置集群资源管理卷组

    * 解除本地 LVM 对卷组的管理

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


    * 配置集群资源管理卷组

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

* 添加 FileSystem

    ```sh
    pcs resource create FS_data01 ocf:heartbeat:Filesystem device="/dev/mapper/rhcs01-data01" directory="/data01" fstype="xfs"
    pcs resource create FS_data02 ocf:heartbeat:Filesystem device="/dev/mapper/rhcs02-data02" directory="/data02" fstype="xfs"
    ```

    > 注: (1) `ocf:heartbeat:Filesystem` 可简写成 `Filesystem`

* 添加 VSFTPD 服务

    取消 Systemd 开机自启动:

    ```sh
    systemctl disable vsftpd
    ```

    添加服务托管:

    ```sh
    pcs resource create VSFTPD_01 systemd:vsftpd@vsftpd_01
    pcs resource create VSFTPD_02 systemd:vsftpd@vsftpd_02
    ```


* 创建资源组

    ```sh
    pcs resource group add VSFTPD_GROUP_01 IP_161.14 VG_rhcs01 FS_data01 VSFTPD_01
    pcs resource group add VSFTPD_GROUP_02 IP_161.15 VG_rhcs02 FS_data02 VSFTPD_02
    ```

* 添加约束条件

    查看约束条件可使用以下格式:

    ```text
    pcs constraint ref <resource>                               # 列出指定资源的约束条件
    pcs constraint [order|colocation|location] [show] [--full]  # 列出约束条件
        --full      # If '--full' is specified also list the constraint ids
    ```

    - 添加 `order` 类约束

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


    - 添加 `colocation` 类约束

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

    - 添加`location`类约束

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


### 配置 Fence

## Demo 2 - RHEL6.4 - 双机双业务互为冗余的 VSFTPD RHCS 集群

|  Hostname  | Management IP  | HeartBeat IP  | Storage IP (Optional)  |
| ---------- | :------------: | :-----------: | :--------------------: |
| node01     | 192.168.161.14 | 10.168.161.14 | 20.168.161.14          |
| node02     | 192.168.161.15 | 10.168.161.15 | 20.168.161.15          |