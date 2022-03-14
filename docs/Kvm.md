# Kvm

## 虚拟机管理

### 查看/启动/关闭/挂起/保存/删除 虚拟机

* 查看

    ```sh
    virsh list         # 显示正在运行的虚拟机
    virsh list --all   # 显示所有虚拟机
    ```

* 启动

    ```sh
    virsh start VM-NAME                  # 启动
    virsh autostart VM-NAME              # 开机自启
    virsh autostart --disable VM-NAME    # 取消开机自启
    ```

* 关闭

    ```sh
    virsh shutdown VM-NAME     # 正常关机
    virsh destroy VM-NAME      # 强制关机
    ```

* 挂起

    ```sh
    virsh suspend VM-NAME      # 挂起
    virsh resume VM-NAME       # 恢复挂起
    ```

* 保存

    ```sh
    virsh managedsave VM-NAME

    # [--domain] <string>  domain name, id or uuid
    # --bypass-cache   avoid file system cache when saving
    # --running        set domain to be running on next start
    # --paused         set domain to be paused on next start
    # --verbose        display the progress of save

    virsh start VM-NAME
    ```

* 删除

    ```sh
    virsh undefined VM-NAME

    [--managed-save]         # 当虚拟机处于saved状态时，删除时需要指定这个选项
    [--snapshots-metadata]
    [ {--storage volumes | --remove-all-storage [--delete-snapshots]} --wipe-storage]
    ```

### 克隆虚拟机

```sh
virsh shutdown VM-NAME-01                                         # 确保VM-NAME-01为关机状态
virt-clone -o VM-NAME-01 -n VM-NAME-02 -f /data/VM-NAME-02.qcow2  # VM-NAME-01克隆为VM-NAME-02
```

### 配置虚拟机


* 虚拟内存

    ```sh
    virsh setmaxmem VM-NAME 4096M --config   # 最大可分配内存, 重启后生效
    virsh setmem VM-NAME 2048M               # 当前分配内存, 值应该小于最大可分配内存的值
    ```


* 虚拟机时间

    ```sh
    $ virsh domtime rhel79 --pretty    # 显示虚拟机时间, 仅可查看开机状态的主机
    $ virsh domtime --time 1614244228  # 设置时间

    # --now            set to the time of the host running virsh, " acts like if it was an alias for --time $now "
    # --pretty         print domain's time in human readable form
    # --sync           instead of setting given time, synchronize from domain's RTC
    # --time <number>  time to set
    ```

* 网卡

    * 添加网卡

        ```text
        SYNOPSIS
          attach-interface <domain> <type> <source> [--target <string>] [--mac <string>] [--script <string>] [--model <string>] [--inbound <string>] [--outbound <string>] 
            [--persistent] [--config] [--live] [--current] [--print-xml] [--managed]

        OPTIONS
          [--domain] <string>   domain name, id or uuid
          [--type] <string>     network interface type
          [--source] <string>   source of network interface
          --target <string>     target network name
          --mac <string>        MAC address
          --script <string>     script used to bridge network interface
          --model <string>      model type
          --inbound <string>    control domain's incoming traffics
          --outbound <string>   control domain's outgoing traffics
          --persistent          make live change persistent
          --config              affect next boot
          --live                affect running domain
          --current             affect current domain
          --print-xml           print XML document rather than attach the interface
          --managed             libvirt will automatically detach/attach the device from/to host
        ```

        ```sh
        $ virsh attach-interface --domain rhel79 --type bridge --source br0 --model virtio --print-xml

        <interface type='bridge'>
          <source bridge='br0'/>
          <model type='virtio'/>
        </interface>
        ```

    * 删除网卡

        ```text
        SYNOPSIS
          detach-interface <domain> <type> [--mac <string>] [--persistent] [--config] [--live] [--current]

        OPTIONS
          [--domain] <string>  domain name, id or uuid
          [--type] <string>    network interface type
          --mac <string>       MAC address
          --persistent         make live change persistent
          --config             affect next boot
          --live               affect running domain
          --current            affect current domain
        ```

        ```sh
        $ virsh detach-interface rhel79 --type bridge      # 有多网卡时, 需要指定mac来删除网卡
        error: Domain has 2 interfaces. Please specify which one to detach using --mac
        error: Failed to detach interface

        $ virsh detach-interface rhel79 --type bridge --mac 52:54:00:84:14:f2
        Interface detached successfully

        $ virsh domiflist rhel79
        Interface  Type       Source     Model       MAC
        -------------------------------------------------------
        vnet0      bridge     br0        virtio      52:54:00:64:fc:47
        ```

* 块设备(磁盘)

    * 创建/扩容磁盘

        ```sh
        qemu-img create -f qcow2 /home/virtimg/rhel6.img 10G # 创建磁盘
        qemu-img resize /home/virtimg/rhel6.img +1G          # 增大磁盘容量
        qemu-img info /home/virtimg/rhel6.img                # 查看磁盘信息
        ```

    * 添加磁盘

        ```text
        SYNOPSIS
          attach-disk <domain> <source> <target> [--targetbus <string>] [--driver <string>] [--subdriver <string>] [--iothread <string>] [--cache <string>] 
            [--io <string>] [--type <string>] [--mode <string>] [--sourcetype <string>] [--serial <string>] [--wwn <string>] [--rawio] [--address <string>] 
            [--multifunction] [--print-xml] [--persistent] [--config] [--live] [--current]
        
        OPTIONS
          [--domain] <string>    domain name, id or uuid
          [--source] <string>    source of disk device     => /data/dev-7-rhel79.qcow2
          [--target] <string>    target of disk device     => vda, sdb等
          --targetbus <string>   target bus of disk device => 典型值为ide,scsi,virtio,xen,usb,sata或sd; 如果省略,则根据设备名称的样式推断总线类型（例如, 'sda'则认为是使用SCSI总线导出的设备） 
          --driver <string>      driver of disk device     => For Xen Hypervior: file,tap,phy; For QEMU emulator:qemu
          --subdriver <string>   subdriver of disk device  => For Xen Hypervior: aio;          For QEMU emulator:raw or qcow2
          --iothread <string>    IOThread to be used by supported device
          --cache <string>       cache mode of disk device            => "default","none","writethrough","writeback","directsync" or "unsafe".
          --io <string>          io policy of disk device             => "threads" and "native"
          --type <string>        target device type                   => 设备类型: disk(default),lun,cdrom,floppy
          --mode <string>        mode of device reading and writing   => readonly/shareable
          --sourcetype <string>  type of source (block|file)
          --serial <string>      serial of disk device                => 设备序列号
          --wwn <string>         wwn of disk device                   => 设备wwn
          --rawio                needs rawio capability
          --address <string>     address of disk device               => address is the address of disk device in the form of pci:domain.bus.slot.function, scsi:controller.bus.unit,
                                                                           ide:controller.bus.unit or ccw:cssid.ssid.devno.
          --multifunction        use multifunction pci under specified address
          --print-xml            print XML document rather than attach the disk
          --persistent           make live change persistent
          --config               affect next boot
          --live                 affect running domain
          --current              affect current domain
        ```
        
        ```sh
        $ virsh attach-disk --domain rhel79 --source /data/tmp.qcow2  --target vdb --targetbus virtio --driver qemu --subdriver qcow2 --print-xml 
        <disk type='file'>
          <driver name='qemu' type='qcow2'/>
          <source file='/data/tmp.qcow2'/>
          <target dev='vdb' bus='virtio'/>
        </disk>
        ```


    * 删除磁盘

        ```text
        SYNOPSIS
            detach-disk <domain> <target> [--persistent] [--config] [--live] [--current] [--print-xml]
        
        OPTIONS
          [--domain] <string>  domain name, id or uuid
          [--target] <string>  target of disk device
          --persistent     make live change persistent
          --config         affect next boot
          --live           affect running domain
          --current        affect current domain
          --print-xml      print XML document rather than detach the disk
        ```
        
        ```sh
        virsh detach-disk --domain rhel79-clone --target vdb --config
        ```

* 快照

    ```text
    snapshot-create      Create a snapshot from XML  
    snapshot-create-as   Create a snapshot from a set of args  
    snapshot-current     Get or set the current snapshot        <=当前快照
    snapshot-delete      Delete a domain snapshot
    snapshot-dumpxml     Dump XML for a domain snapshot         <=导出快照xml文件
    snapshot-edit        edit XML for a snapshot                <=编辑快照xml文件
    snapshot-info        snapshot information                   <=查看快照信息
    snapshot-list        List snapshots for a domain  
    snapshot-parent      Get the name of the parent of a snapshot  
    snapshot-revert      Revert a domain to a snapshot 
    ``` 

    * 创建快照

        * 1. `snapshot-create-as`: 创建默认快照（一般为一串数字）

        * 2. `snapshot-create`: 创建自定义名称快照

        ```sh
        $ virsh snapshot-create --domain rhel79
        $ virsh snapshot-create-as rhel79 --name rhel79-snapshot-1
        $ virsh snapshot-list rhel79

        Name                 Creation Time             State
        ------------------------------------------------------------
        1614330821           2021-02-26 17:13:41 +0800 shutoff
        rhel79-snapshot-1    2021-02-26 17:14:08 +0800 shutoff
        ```

    * 关于内置快照和外置快照

        * 内置快照: 快照数据和base磁盘数据放在一个qcow2文件中。

        * 外置快照: 快照数据单独的qcow2文件存放。

            ```sh
            # 1. 创建
            virsh snapshot-create-as --domain rhel79 --name fresh --disk-only --diskspec vda,snapshot=external,file=/data/rhel79_1.qcow2 --atomic

            # 2. 合并快照

            ## 2.1 blockcommit将top镜像合并至低层的base镜像     快照路径:初始=>rhel79_1=>rhel79_2=>当前
            virsh blockcommit --domain rhel79 --base /data/rhel79_1.qcow2 --top /data/rhel79_2.qcow2 --wait --verbose

            ## 2.2 blockpull将backing-file向上合并至active     快照路径: 初始=>rhel79_3=>rhel79_4=>当前
            
            # 合并快照3到当前使用的快照4中
            virsh blockpull --domain rhel79 --path /data/rhel79_3.qcow2 --base /data/test4.qcow2 --wait --verbose
            
            # 迁移虚拟机，合并base-image到active,合并需要一段时间
            virsh blockpull --domain rhel79 --path /data/test4.qcow2 --wait --verbose
            ```

    * 恢复快照

        ```sh
        virsh snapshot-revert --domain rhel79 --snapshotname 1614330821
        ```

    * 删除快照

        ```sh
        virsh snapshot-delete rhel79 --snapshotname 1614330821
        ```

### 配置Console


```sh
$ virsh console rhel79

# --force          force console connection (disconnect already connected sessions)
# --safe           only connect if safe console handling is supported
```

默认情况下, 直接执行命令连接到虚拟机时, 会卡住, 需要特殊配置

* RHEL/CentOS 6

    * `/etc/securetty`中添加`ttyS0`

        ```sh
        echo "ttyS0" >> /etc/securetty
        ```

    * `/etc/grub.conf`中添加参数`console=ttyS0`

        ```text
        ...
        title Red Hat Enterprise Linux (2.6.32-358.el6.x86_64)
                root (hd0,0)
                kernel /vmlinuz-2.6.32-358.el6.x86_64 ro ... rhgb quiet console=ttyS0    <== 添加 console=ttyS0
                initrd /initramfs-2.6.32-358.el6.x86_64.img
        ...
        ```

    * `/etc/inittab`中添加`S0:12345:respawn:/sbin/agetty ttyS0 115200`

        ```sh
        echo "S0:12345:respawn:/sbin/agetty ttyS0 115200"  >> /etc/inittab
        ```

* RHEL/CentOS 7

    * 方法一: 执行命令添加参数"`console=ttyS0`"

        ```sh
        grubby --update-kernel=ALL --args="console=ttyS0"
        ```

    * 方法二: 手动编辑 `/etc/default/grub` , 添加参数"`console=ttyS0`", 然后使用 `grub2-mkconfig` 命令使配置生效

        ```x
        # /etc/default/grub
        ...
        GRUB_CMDLINE_LINUX="spectre_v2=retpoline rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet console=ttyS0"  <== 添加 console=ttyS0
        ...
        ```

        ```sh
        grub2-mkconfig -o /boot/grub2/grub.cfg
        ```

    * 方法三: 

        ```sh
        systemctl enable serial-getty@ttyS0.service
        systemctl start serial-getty@ttyS0.service
        ```

* RHEL/CentOS/Rocky 8

    * 方法一: 执行命令添加参数"`console=ttyS0`"

        ```sh
        grubby --update-kernel=ALL --args="console=ttyS0,115200n8"
        ```

    * 方法二: 

        ```sh
        systemctl enable serial-getty@ttyS0.service
        systemctl start serial-getty@ttyS0.service
        ```

* Ubuntu 14.04, 16.04

    * 编辑 `/etc/default/grub` 添加/修改: 

        ```x
        GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200"
        GRUB_TERMINAL=serial
        GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
        ```

    * 编辑 `/etc/init/ttyS0.conf` 添加/修改: 

        ```text
        start on stopped rc RUNLEVEL=[2345] and (
                    not-container or
                    container CONTAINER=lxc or
                    container CONTAINER=lxc-libvirt)
        
        stop on runlevel [!2345]
        
        respawn
        exec /sbin/getty -h -L -w  115200 ttyS0 vt100
        ```

    * 更新grub
      
        ```sh
        update-grub
        ```

* Ubuntu 18.04, 20.04

    * 编辑 `/etc/default/grub` 添加/修改: 

        ```x
        GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200"
        GRUB_TERMINAL="console serial"
        GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
        ```

    * 更新grub
      
        ```sh
        update-grub
        # 或
        grub-mkconfig -o /boot/grub/grub.cfg
    ```


## 虚拟机信息

### 基本信息

```sh
$ virsh dominfo rhel79

Id:             32
Name:           rhel79
UUID:           4ecca1a6-cfe2-4975-9ffe-cb80c2356d55
OS Type:        hvm
State:          running
CPU(s):         1
CPU time:       53.2s
Max memory:     1048576 KiB
Used memory:    1048576 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: none
Security DOI:   0
```

### 详细信息

```sh
$ virsh domstats rhel79-clone rhel79

# --state            report domain state
# --cpu-total        report domain physical cpu usage
# --balloon          report domain balloon statistics
# --vcpu             report domain virtual cpu information
# --interface        report domain network interface information
# --block            report domain block device statistics
# --perf             report domain perf event statistics
# --list-active      list only active domains
# --list-inactive    list only inactive domains
# --list-persistent  list only persistent domains
# --list-transient   list only transient domains
# --list-running     list only running domains
# --list-paused      list only paused domains
# --list-shutoff     list only shutoff domains
# --list-other       list only domains in other states
# --raw              do not pretty-print the fields
# --enforce          enforce requested stats parameters
# --backing          add backing chain information to block stats
# --nowait           report only stats that are accessible instantly
# <domain>           list of domains to get stats for
```

### 虚拟机状态

```sh
$ virsh domstate rhel79-clone --reason 

running (booted)

# --reason         also print reason for the state
```

### 块设备信息

* 块设备基本信息

    ```sh
    $ virsh domblklist rhel79 --details

    Type       Device     Target     Source
    ------------------------------------------------
    file       disk       vda        /data/rhel79.qcow2

    # --inactive       get inactive rather than running configuration
    ```

* 块设备大小信息

    ```sh
    $ virsh domblkinfo rhel79 vda

    Capacity:       10737418240
    Allocation:     1802313728
    Physical:       1802371072

    # --device <string>  block device
    # --human            Human readable output
    # --all              display all block devices info
    ```

* 显示块设备详细信息

    ```sh
    $ virsh domblkstat rhel79   # 仅可查看开机状态的主机

    rd_req 9741
    rd_bytes 154587648
    wr_req 614
    wr_bytes 13020672
    flush_operations 320
    rd_total_times 1419425446
    wr_total_times 321114004
    flush_total_times 290348748

    # --device <string>  block device
    # --human            print a more human readable output
    ```

* 显示块设备中的错误  

    ```sh
    virsh domblkerror VM-NAME   # 仅可查看开机状态的主机
    ```

### 网络相关信息

* 控制接口的状态 (仅开机状态)

    ```sh
    $ virsh domcontrol rhel79

    ok
    ```

* 查看网卡列表

    ```sh
    $ virsh domiflist rhel79

    Interface  Type       Source     Model       MAC
    -------------------------------------------------------
    -          bridge     br0        virtio      52:54:00:f0:a3:23

    # --inactive       get inactive rather than running configuration
    ```

* 网卡状态 (仅开机状态)

    * 连通性

        ```sh
        $ virsh domif-getlink rhel79 vnet1

        vnet1 up
        
        # --config         Get persistent interface state
        ```

    * 流量信息

        ```sh
        $ virsh domifstat rhel79 vnet1
        
        vnet1 rx_bytes 82461
        vnet1 rx_packets 617
        vnet1 rx_errs 0
        vnet1 rx_drop 0
        vnet1 tx_bytes 2428
        vnet1 tx_packets 38
        vnet1 tx_errs 0
        vnet1 tx_drop 0
        ```

    * 网卡IP信息

        ```sh
        $ virsh domifaddr rhel79 

        # --interface <string>  network interface name
        # --full                always display names and MACs of interfaces
        # --source <string>     address source: 'lease', 'agent', or 'arp'
        ```

### 内存信息 (仅开机状态)

```sh
$ virsh dommemstat rhel79

actual 1048576
swap_in 0
swap_out 0
major_fault 186
minor_fault 158840
unused 879464
available 1014784
last_update 1614304438
rss 594740

# --period <number>  period in seconds to set collection
# --config           affect next boot
# --live             affect running domain
# --current          affect current domain
# 对于带有memory balloon的QEMU/KVM，将可选的--period设置为大于0的值（以秒为单位），将使balloon dirver程序返回其他统计信息，这些统计信息将由后续的dommemstat命令显示。 
# 将--period设置为0将停止气球状驱动程序收集，但不会清除气球状驱动程序中的统计信息。 需要至少QEMU/KVM 1.5在主机上运行。
# --live，-config和--current标志仅在使用--period选项设置气球驱动程序的收集时间时有效。 
#     如果指定了--live，则仅影响正在运行的来宾收集周期。 
#     如果指定了--config，将影响持久客户机的下一次引导。 
#     如果指定了--current，则影响当前的来宾状态。
# --current不能和--live和--config一起给出。如果未指定标志，则行为将根据来宾状态而有所不同。 

# swap_in           - The amount of data read from swap space (in KiB)
# swap_out          - The amount of memory written out to swap space (in KiB)
# major_fault       - The number of page faults where disk IO was required
# minor_fault       - The number of other page faults
# unused            - The amount of memory left unused by the system (in KiB)
# available         - The amount of usable memory as seen by the domain (in KiB)
# actual            - Current balloon value (in KiB)
# rss               - Resident Set Size of the running domain's process (in KiB)
# usable            - The amount of memory which can be reclaimed by balloon without causing host swapping (in KiB)
# last-update       - Timestamp of the last update of statistics (in seconds)
# disk_caches       - The amount of memory that can be reclaimed without additional I/O, typically disk caches (in KiB)
```

## 虚拟机创建

### 图形化方式创建: `virt-manager`

### `virt-install`

```sh
~] virt-install --help

usage: virt-install --name NAME --memory MB STORAGE INSTALL [options]

Create a new virtual machine from specified install media.

optional arguments:
  -h, --help            show this help message and exit
  --version             show program''s version number and exit 
  --connect URI         Connect to hypervisor with libvirt URI

General Options:
  -n NAME, --name NAME  Name of the guest instance
  --memory MEMORY       Configure guest memory allocation. Ex:
                        --memory 1024 (in MiB)
                        --memory memory=1024,currentMemory=512
  --vcpus VCPUS         Number of vcpus to configure for your guest. Ex:
                        --vcpus 5
                        --vcpus 5,maxvcpus=10,cpuset=1-4,6,8
                        --vcpus sockets=2,cores=4,threads=2
  --cpu CPU             CPU model and features. Ex:
                        --cpu coreduo,+x2apic
                        --cpu host-passthrough
                        --cpu host
  --metadata METADATA   Configure guest metadata. Ex:
                        --metadata name=foo,title="My pretty title",uuid=...
                        --metadata description="My nice long description"

Installation Method Options:
  --cdrom CDROM         CD-ROM installation media
  -l LOCATION, --location LOCATION
                        Distro install URL, eg. https://host/path. See man
                        page for specific distro examples.
  --pxe                 Boot from the network using the PXE protocol
  --import              Build guest around an existing disk image 在已有的磁盘镜像中构建客户机
  -x EXTRA_ARGS, --extra-args EXTRA_ARGS
                        Additional arguments to pass to the install kernel
                        booted from --location
  --initrd-inject INITRD_INJECT
                        Add given file to root of initrd from --location
  --unattended [UNATTENDED]
                        Perform an unattended installation
  --install INSTALL     Specify fine grained install options
  --boot BOOT           Configure guest boot settings. Ex:
                        --boot hd,cdrom,menu=on
                        --boot init=/sbin/init (for containers)
  --idmap IDMAP         Enable user namespace for LXC container. Ex:
                        --idmap uid.start=0,uid.target=1000,uid.count=10

OS options:
  --os-variant OS_VARIANT
                        The OS being installed in the guest.
                        This is used for deciding optimal defaults like virtio.
                        Example values: fedora29, rhel7.0, win10, ...
                        See 'osinfo-query os' for a full list.

Device Options:
  --disk DISK           Specify storage with various options. Ex.
                        --disk size=10 (new 10GiB image in default location)
                        --disk /my/existing/disk,cache=none
                        --disk device=cdrom,bus=scsi
                        --disk=?
  -w NETWORK, --network NETWORK
                        Configure a guest network interface. Ex:
                        --network bridge=mybr0
                        --network network=my_libvirt_virtual_net
                        --network network=mynet,model=virtio,mac=00:11...
                        --network none
                        --network help
  --graphics GRAPHICS   Configure guest display settings. Ex:
                        --graphics spice
                        --graphics vnc,port=5901,listen=0.0.0.0
                        --graphics none
  --controller CONTROLLER
                        Configure a guest controller device. Ex:
                        --controller type=usb,model=qemu-xhci
                        --controller virtio-scsi
  --input INPUT         Configure a guest input device. Ex:
                        --input tablet
                        --input keyboard,bus=usb
  --serial SERIAL       Configure a guest serial device
  --parallel PARALLEL   Configure a guest parallel device
  --channel CHANNEL     Configure a guest communication channel
  --console CONSOLE     Configure a text console connection between the guest
                        and host
  --hostdev HOSTDEV     Configure physical USB/PCI/etc host devices to be
                        shared with the guest
  --filesystem FILESYSTEM
                        Pass host directory to the guest. Ex: 
                        --filesystem /my/source/dir,/dir/in/guest
                        --filesystem template_name,/,type=template
  --sound [SOUND]       Configure guest sound device emulation
  --watchdog WATCHDOG   Configure a guest watchdog device
  --video VIDEO         Configure guest video hardware.
  --smartcard SMARTCARD
                        Configure a guest smartcard device. Ex:
                        --smartcard mode=passthrough
  --redirdev REDIRDEV   Configure a guest redirection device. Ex:
                        --redirdev usb,type=tcp,server=192.168.1.1:4000
  --memballoon MEMBALLOON
                        Configure a guest memballoon device. Ex:
                        --memballoon model=virtio
  --tpm TPM             Configure a guest TPM device. Ex:
                        --tpm /dev/tpm
  --rng RNG             Configure a guest RNG device. Ex:
                        --rng /dev/urandom
  --panic PANIC         Configure a guest panic device. Ex:
                        --panic default
  --memdev MEMDEV       Configure a guest memory device. Ex:
                        --memdev dimm,target.size=1024
  --vsock VSOCK         Configure guest vsock sockets. Ex:
                        --vsock cid.auto=yes
                        --vsock cid.address=7

Guest Configuration Options:
  --iothreads IOTHREADS
                        Set domain <iothreads> and <iothreadids>
                        configuration.
  --seclabel SECLABEL, --security SECLABEL
                        Set domain seclabel configuration.
  --cputune CPUTUNE     Tune CPU parameters for the domain process.
  --numatune NUMATUNE   Tune NUMA policy for the domain process.
  --memtune MEMTUNE     Tune memory policy for the domain process.
  --blkiotune BLKIOTUNE
                        Tune blkio policy for the domain process.
  --memorybacking MEMORYBACKING
                        Set memory backing policy for the domain process. Ex:
                        --memorybacking hugepages=on
  --features FEATURES   Set domain <features> XML. Ex:
                        --features acpi=off
                        --features apic=on,apic.eoi=on
  --clock CLOCK         Set domain <clock> XML. Ex:
                        --clock offset=localtime,rtc_tickpolicy=catchup
  --pm PM               Configure VM power management features
  --events EVENTS       Configure VM lifecycle management policy
  --resource RESOURCE   Configure VM resource partitioning (cgroups)
  --sysinfo SYSINFO     Configure SMBIOS System Information. Ex:
                        --sysinfo host
                        --sysinfo bios.vendor=MyVendor,bios.version=1.2.3,...
  --qemu-commandline QEMU_COMMANDLINE
                        Pass arguments directly to the qemu emulator. Ex:
                        --qemu-commandline='-display gtk,gl=on'
                        --qemu-commandline env=DISPLAY=:0.1
  --launchSecurity LAUNCHSECURITY, --launchsecurity LAUNCHSECURITY
                        Configure VM launch security (e.g. SEV memory encryption). Ex:
                        --launchSecurity type=sev,cbitpos=47,reducedPhysBits=1,policy=0x0001,dhCert=BASE64CERT
                        --launchSecurity sev

Virtualization Platform Options:
  -v, --hvm             This guest should be a fully virtualized guest
  -p, --paravirt        This guest should be a paravirtualized guest
  --container           This guest should be a container guest
  --virt-type VIRT_TYPE
                        Hypervisor name to use (kvm, qemu, xen, ...)
  --arch ARCH           The CPU architecture to simulate
  --machine MACHINE     The machine type to emulate

Miscellaneous Options:
  --autostart           Have domain autostart on host boot up.
  --transient           Create a transient domain.
  --destroy-on-exit     Force power off the domain when the console viewer is
                        closed.
  --wait [WAIT]         Minutes to wait for install to complete.
  --noautoconsole       Don't automatically try to connect to the guest
                        console
  --noreboot            Don't boot guest after completing install.
  --print-xml [XMLONLY]
                        Print the generated domain XML rather than create the
                        guest.
  --dry-run             Run through install process, but do not create devices
                        or define the guest.
  --check CHECK         Enable or disable validation checks. Example:
                        --check path_in_use=off
                        --check all=off
  -q, --quiet           Suppress non-error output
  -d, --debug           Print debugging information

Use '--option=?' or '--option help' to see available suboptions
See man page for examples and full option syntax.
```

* The simplest invocation to interactively install a Fedora 29 KVM VM with recommended defaults. virt-viewer(1) will be launched to graphically interact with the VM install:

    > Note: 启动virt-viewer图形窗口安装; 此操作需要安装virt-viewer; 

    ```sh
    sudo virt-install --install fedora29

    # 'fedora29' 为操作系统类型, 可通过 'osinfo-query os' 查询支持的选项
    ```

* Similar, but use libosinfo's unattended install support, which will perform the fedora29 install automatically without user intervention:

    > Note: 使用 libosinfo 无人值守安装

    ```sh
    sudo virt-install --install fedora29 --unattended
    ```

* Install a Windows 10 VM, using 40GiB storage in the default location and 4096MiB of ram, and ensure we are connecting to the system libvirtd instance:

    ```sh
    virt-install \
        --connect qemu:///system \
        --name my-win10-vm \
        --memory 4096 \
        --disk size=40 \
        --os-variant win10 \
        --cdrom /path/to/my/win10.iso
    ```

* Install a CentOS 7 KVM from a URL, with recommended device defaults and default required storage, but specifically request VNC graphics instead of the default SPICE, and request 8 virtual CPUs and 8192 MiB of memory:

    ```sh
    virt-install \
              --connect qemu:///system \
              --memory 8192 \
              --vcpus 8 \
              --graphics vnc \
              --os-variant centos7.0 \
              --location http://mirror.centos.org/centos-7/7/os/x86_64/
    ```

* Create a VM around an existing debian9 disk image:

    ```sh
    virt-install \
              --import \
              --memory 512 \
              --disk /home/user/VMs/my-debian9.img \
              --os-variant debian9
    ```

## kvm-qemu 配置

### bridge

* bridge 常用场景

    * 虚拟机

        > eth0 可以不连接 br0, 看实际需求

        ```text
        +-----------------------------------------------+-----------------------------------+-----------------------------------+
        |                      Host                     |           VirtualMachine1         |           VirtualMachine2         |
        |                                               |                                   |                                   |
        |    +-------------------------------------+    |    +-------------------------+    |    +-------------------------+    |
        |    |        Newwork Protocol Stack       |    |    |  Newwork Protocol Stack |    |    |  Newwork Protocol Stack |    |
        |    +-------------------------------------+    |    +-------------------------+    |    +-------------------------+    |
        |                      ↑                        |                ↑                  |                 ↑                 |
        |......................|........................|................|..................|.................|.................|
        |                      ↓                        |                ↓                  |                 ↓                 |
        |                  +--------+                   |            +-------+              |             +-------+             |
        |                  | .3.101 |                   |            | .3.102|              |             | .3.103|             |
        |     +------+     +--------+     +-------+     |            +-------+              |             +-------+             |
        |     | eth0 |<--->|   br0  |<--->|tun/tap|     |            | eth0  |              |             | eth0  |             |
        |     +------+     +--------+     +-------+     |            +-------+              |             +-------+             |
        |         ↑             ↑             ↑         |                ↑                  |                 ↑                 |
        |         |             |             +--------------------------+                  |                 |                 |
        |         |             ↓                       |                                   |                 |                 |
        |         |         +-------+                   |                                   |                 |                 |
        |         |         |tun/tap|                   |                                   |                 |                 |
        |         |         +-------+                   |                                   |                 |                 |
        |         |             ↑                       |                                   |                 |                 |
        |         |             +-----------------------------------------------------------|-----------------+                 |
        |         |                                     |                                   |                                   |
        +---------|-------------------------------------+-----------------------------------+-----------------------------------+
                  ↓
            Physical Network  (192.168.3.0/24)
        ```

    * docker

        由于容器运行在自己单独的network namespace里面(需要使用 veth对)，所以都有自己单独的协议栈，情况和上面的虚拟机差不多，但它采用了另一种方式来和外界通信: 

        ```text
        +------------------------------------------------+-----------------------------------+-----------------------------------+
        |                       Host                     |           Container 1             |           Container 2             |
        |                                                |                                   |                                   |
        |    +--------------------------------------+    |    +-------------------------+    |    +-------------------------+    |
        |    |        Newwork Protocol Stack        |    |    |  Newwork Protocol Stack |    |    |  Newwork Protocol Stack |    |
        |    +--------------------------------------+    |    +-------------------------+    |    +-------------------------+    |
        |         ↑             ↑                        |                ↑                  |                 ↑                 |
        |.........|.............|........................|................|..................|.................|.................|
        |         ↓             ↓                        |                ↓                  |                 ↓                 |
        |     +------+     +--------+                    |            +-------+              |             +-------+             |
        |     |.3.101|     |  .9.1  |                    |            |  .9.2 |              |             |  .9.3 |             |
        |     +------+     +--------+     +-------+      |            +-------+              |             +-------+             |
        |     | eth0 |     |   br0  |<--->|  veth |      |            | eth0  |              |             | eth0  |             |
        |     +------+     +--------+     +-------+      |            +-------+              |             +-------+             |
        |         ↑             ↑             ↑          |                ↑                  |                 ↑                 |
        |         |             |             +---------------------------+                  |                 |                 |
        |         |             ↓                        |                                   |                 |                 |
        |         |         +-------+                    |                                   |                 |                 |
        |         |         |  veth |                    |                                   |                 |                 |
        |         |         +-------+                    |                                   |                 |                 |
        |         |             ↑                        |                                   |                 |                 |
        |         |             +------------------------------------------------------------|-----------------+                 |
        |         |                                      |                                   |                                   |
        +---------|--------------------------------------+-----------------------------------+-----------------------------------+
                  ↓
            Physical Network  (192.168.3.0/24)
        ```

* 新建 bridge

    ```text
                                --vnet0  ==> kvm-host0
    宿主机 ==> br0 ==> ens33 ==>  
                                --vnet1  ==> kvm-host1
    ```

    * 方法1. 编辑文件配置

        ```sh
        # 修改ifcfg-ens33, 注释掉IP信息, 添加 BRIDGE=br0
        TYPE=Ethernet
        BOOTPROTO=none
        DEFROUTE=yes
        IPV4_FAILURE_FATAL=no
        NAME=ens33
        DEVICE=ens33
        ONBOOT=yes
        #IPADDR=192.168.1.100   <=
        #PREFIX=24              <=
        BRIDGE=br0              <=
        ```

        ```sh
        # 添加ifcfg-br0
        DEVICE=br0
        ONBOOT=yes
        TYPE=Bridge
        BOOTPROTO=none
        IPADDR=192.168.1.100   <=
        NETMASK=255.255.255.0  <=
        DELAY=0
        ```

        重启网络即可

        ```sh
        brctl show 

        bridge name     bridge id               STP enabled     interfaces
        br0             8000.000c297b41d3       no              ens33        <=
        virbr0          8000.525400e4a58b       yes             virbr0-nic
        ```

    * 方法2. `brctl`命令配置

        ```sh
        brctl addr br0
        brctl addif br0 eth0
        brctl stp br0 on
        brctl delif br0 eth0
        ```

    * 方法3. `nmcli`命令配置

        ```sh
        nmcli connection add type bridge ifname br0 con-name br0
        nmcli connection modify br0 ipv4.addresses 192.168.163.1/24 ipv4.method manual autoconnect yes
        ```

    * 方法4. `ip`命令配置

        ```sh
        ip link add name br0 type bridge
        ip link set br0 up
        ip link set dev eth0 master br0
        ip addr add 192.168.3.101/24 dev br0
        ```
