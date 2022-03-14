# RHCS, Red Hat Cluster Suite

## Demo 1 - RHEL7.6 - 双机双业务互为冗余的 VSFTPD RHCS 集群

|  Hostname  | Management IP  | HeartBeat IP  | Storage IP (Optional)  |
| ---------- | :------------: | :-----------: | :--------------------: |
| node01     | 192.168.161.12 | 10.168.161.12 | 20.168.161.12          |
| node02     | 192.168.161.13 | 10.168.161.13 | 20.168.161.13          |

### 准备工作

> *主要内容: 时间源, 共享存储*

* 时间源

    使用 `chrony` 或者 `ntp` 搭建时间源, 此处不做赘述

* 共享存储 

    最好使用 SAN 存储, 如果没有硬件共享存储, 可使用以下两种方法:
    
    * iSCSI 软件实现企业级共享存储
    * 如果使用 KVM 搭建实验环境, 可使用 raw 创建共享磁盘

* iSCSI 共享存储

    可以采用企业级别的软件实现, 如 `OpenFiler`; 实验环境可使用 Linux 系统的 Linux-IO Target 模拟 iSCSI 共享存储

    示例: (以下仅配置一块共享磁盘, 如果需要双机双业务, 是需要两块共享磁盘的)

    * 安装

        ```sh
        yum install targetcli

        systemctl enable --now target
        ```

    * 配置

        ```sh
        ~] targetcli ls 
        
        o- / ................................................................................. [...]
          o- backstores ...................................................................... [...]
          | o- block .......................................................... [Storage Objects: 0]
          | o- fileio ......................................................... [Storage Objects: 0]
          | o- pscsi .......................................................... [Storage Objects: 0]
          | o- ramdisk ........................................................ [Storage Objects: 0]
          o- iscsi .................................................................... [Targets: 0]
          o- loopback ................................................................. [Targets: 0]
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
        
        o- / ................................................................................. [...]
          o- backstores ...................................................................... [...]
          | o- block .......................................................... [Storage Objects: 1]
          | | o- disk01 .................................. [/dev/sdc (10.0GiB) write-thru activated]
          | |   o- alua ........................................................... [ALUA Groups: 1]
          | |     o- default_tg_pt_gp ............................... [ALUA state: Active/optimized]
          | o- fileio ......................................................... [Storage Objects: 0]
          | o- pscsi .......................................................... [Storage Objects: 0]
          | o- ramdisk ........................................................ [Storage Objects: 0]
          o- iscsi .................................................................... [Targets: 1]
          | o- iqn.2019-12.com.test:rhcs ................................................. [TPGs: 1]
          |   o- tpg1 ....................................................... [no-gen-acls, no-auth]
          |     o- acls .................................................................. [ACLs: 2]
          |     | o- iqn.2019-12.com.test:rhcs_node01 ............................. [Mapped LUNs: 1]
          |     | | o- mapped_lun0 ........................................ [lun0 block/disk01 (rw)]
          |     | o- iqn.2019-12.com.test:rhcs_node02 ............................. [Mapped LUNs: 1]
          |     |   o- mapped_lun0 ........................................ [lun0 block/disk01 (rw)]
          |     o- luns .................................................................. [LUNs: 1]
          |     | o- lun0 ..............................[block/disk01 (/dev/sdb) (default_tg_pt_gp)]
          |     o- portals ............................................................ [Portals: 1]
          |       o- 20.168.161.240:3260 ...................................................... [OK]
          o- loopback ................................................................. [Targets: 0]
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
    virsh attach-disk --domain node01 --source /var/lib/libvirt/images/rhel76-rhcs-10g-01.raw  --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node01 --source /var/lib/libvirt/images/rhel76-rhcs-10g-01.raw  --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --config
    virsh attach-disk --domain node01 --source /var/lib/libvirt/images/rhel76-rhcs-10g-02.raw  --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node01 --source /var/lib/libvirt/images/rhel76-rhcs-10g-02.raw  --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
    
    virsh attach-disk --domain node02 --source /var/lib/libvirt/images/rhel76-rhcs-10g-01.raw  --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node02 --source /var/lib/libvirt/images/rhel76-rhcs-10g-01.raw  --target vdb --targetbus virtio --driver qemu --subdriver raw --shareable --current
    virsh attach-disk --domain node02 --source /var/lib/libvirt/images/rhel76-rhcs-10g-02.raw  --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
    virsh attach-disk --domain node02 --source /var/lib/libvirt/images/rhel76-rhcs-10g-02.raw  --target vdc --targetbus virtio --driver qemu --subdriver raw --shareable --config
    ```


### 节点配置

> *主要内容: 配置时间同步, 添加主机解析记录, 网卡绑定, 挂载共享存储, 创建文件系统, 配置 VSFTPD 服务*

* 配置时间同步

    两个节点配置到同一时间源, 使用 `ntpd` 或者 `chronyd` 均可

* 添加主机解析记录

    两个节点都需要配置, 在 `/etc/hosts` 添加以下两行; 注意使用的 IP 是心跳 IP, 如果资源不足也可和管理 IP 共用

    ```sh
    ~] vi /etc/hosts

    10.168.161.12 node01
    10.168.161.13 node02
    ```

* 网卡绑定

    有网络冗余要求, 可配置 `Team` 或者 `Bonding`, Refer to: *[Bonding](Bonding.md)* or *[Team](Team.md)*

* 挂载共享存储

    > 介绍 iSCSI Inititor 配置方法

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

        ```
        $ iscsiadm --mode discoverydb --type sendtargets --portal 20.192.168.1 --discover

        20.192.168.1:3260,1 iqn.2019-12.com.test:rhcs
        ```

    * 登录

        ```sh
        $ iscsiadm --mode node --targetname iqn.2019-12.com.test:rhcs --portal 20.192.168.1:3260 --login

        Logging in to [iface: default, target: iqn.2019-12.com.test:targer01, portal: 20.20.20.240,3260] (multiple)
        Login to [iface: default, target: iqn.2019-12.com.test:targer01, portal: 20.20.20.240,3260] successful.
        ```

    * 登出

        先取消所有磁盘占用, 然后执行以下命令：

        ```sh
        iscsiadm --mode node --targetname iqn.2019-12.com.test:rhcs --portal 20.192.168.1:3260 --logout
        ```


    > 以上三步可参考 `iscsiadm` man文档的 `EXAMPLE` 部分获取帮助


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

* 创建文件系统

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

    当前节点导出, 让另一个节点导入, 这样两个节点都能识别到 LVM 信息:

    ```sh
    vgchange -an rhcs01 rhcs02
    vgexport rhcs01 rhcs02

    vgimport rhcs01 rhcs02
    vgchange -ay rhcs01 rhcs02
    ```

    查看:

    ```sh
    ~] lvs
      LV     VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
      data01 rhcs01 -wi-a----- <10.00g
      data02 rhcs02 -wi-a----- <10.00g
    ```


* 配置 VSFTPD 服务

    > 本次实验搭建双机双业务互为冗余的 VSFTPD 集群, 因此两个节点都需要配置 VSFTPD 服务

    * 添加用户及挂载点

        ```sh
        mkdir /data01
        mkdir /data02
        yum install -y vsftpd
        useradd vsftpd
        ```

    * 配置 VSFTPD

        两个节点都需要添加这两个配置文件 `/etc/vsftpd/vsftpd_ftp01.conf`, `/etc/vsftpd/vsftpd_ftp02.conf`, 分别配置两个 VSFTPD 实例: 

        ```sh
        ~] vi /etc/vsftpd/vsftpd_ftp01.conf

        anonymous_enable=NO
        guest_enable=NO
        local_enable=YES
        write_enable=YES
        local_umask=022
        port_enable=YES
        pasv_enable=NO
        dirmessage_enable=YES
        ftpd_banner=Welcome to blah FTP service
        xferlog_enable=YES
        xferlog_std_format=YES
        xferlog_file=/var/log/ftp01_xferlog
        dual_log_enable=YES
        vsftpd_log_file=/var/log/ftp01_vsftpd.log
        nopriv_user=vsftpd
        connect_from_port_20=YES
        chroot_local_user=NO
        chroot_list_enable=YES
        chroot_list_file=/etc/vsftpd/chroot_list01
        listen=YES
        listen_ipv6=NO
        listen_address=192.168.161.12
        pam_service_name=vsftpd
        userlist_enable=YES
        userlist_deny=NO
        tcp_wrappers=YES
        local_root=/data01
        use_localtime=YES
        allow_writeable_chroot=YES
        ```

        ```sh
        ~] vi /etc/vsftpd/vsftpd_ftp02.conf

        anonymous_enable=NO
        guest_enable=NO
        local_enable=YES
        write_enable=YES
        local_umask=022
        port_enable=YES
        pasv_enable=NO
        dirmessage_enable=YES
        ftpd_banner=Welcome to blah FTP service
        xferlog_enable=YES
        xferlog_std_format=YES
        xferlog_file=/var/log/ftp02_xferlog
        dual_log_enable=YES
        vsftpd_log_file=/var/log/ftp02_vsftpd.log
        nopriv_user=vsftpd
        connect_from_port_20=YES
        chroot_local_user=NO
        chroot_list_enable=YES
        chroot_list_file=/etc/vsftpd/chroot_list02
        listen=YES
        listen_ipv6=NO
        listen_address=192.168.161.13
        pam_service_name=vsftpd
        userlist_enable=YES
        userlist_deny=NO
        tcp_wrappers=YES
        local_root=/data02
        use_localtime=YES
        allow_writeable_chroot=YES
        ```


        如果需要 "**禁用主动模式, 启动被动模式**", 并限制端口范围, 可以参考以下配置:

        ```text
        port_enable=NO
        pasv_enable=YES
        pasv_min_port=2226
        pasv_max_port=2229
        ```


    * 防火墙
    
        如果启用了防火墙, 则需要添加策略:
        
        ```sh
        firewall-cmd --add-service=ftp --permanent
        firewall-cmd --reload
        ```

### 集群配置

> *主要内容: 安装及配置集群套件, 托管服务, 配置 Fence*


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

* 托管服务


* 配置 Fence

## Demo 2 - RHEL6.4 - 双机双业务互为冗余的 VSFTPD RHCS 集群

|  Hostname  | Management IP  | HeartBeat IP  | Storage IP (Optional)  |
| ---------- | :------------: | :-----------: | :--------------------: |
| node01     | 192.168.161.14 | 10.168.161.14 | 20.168.161.14          |
| node02     | 192.168.161.15 | 10.168.161.15 | 20.168.161.15          |