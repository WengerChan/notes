# Linux, GNU/Linux

## 自定义编译 RH 内核

> [https://www.cnblogs.com/luohaixian/p/9313863.html](https://www.cnblogs.com/luohaixian/p/9313863.html)

### 1 准备工作

* 创建编译用户

    ```sh
    useradd rpmbuilder
    ```

* 构建编译所需环境

    * 安装依赖包

        ```sh
        yum install rpm-build redhat-rpm-config asciidoc hmaccalc perl-ExtUtils-Embed pesign xmlto
        yum install audit-libs-devel binutils-devel elfutils-devel elfutils-libelf-devel java-devel
        yum install ncurses-devel newt-devel numactl-devel pciutils-devel python-devel zlib-devel
        yum install make gcc bc openssl-devel 
        yum groupinstall "Development Tools"
        ```

    * rpm编译目录创建

        ```sh
        su - rpmbuilder
        mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
        # echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros    # 默认情况下 _topdir 就是 $HOME/rpmbuild
        ```
 
### 2 获取源码

有两种办法获取源码:

* 使用"红帽系"发行版操作系统提供的 `SRPM`, 即 SRC RPM

* 下载 kernel 源码

以下介绍 SRPM 重新编译方法:

### 3 通过 SRPM 编译

* 获取 `.src.rpm` 内核源码包

    ```sh
    ~]$ uname -r 
    3.10.0-957.el7.x86_64

    ~]$ ls -l kernel-3.10.0-957.el7.src.rpm 
    -rw-------. 1 rpmbuilder rpmbuilder 101032927 Feb 26 15:44 kernel-3.10.0-957.el7.src.rpm
    ```

* 安装 `.src.rpm` 内核源码包

    ```sh
    ~]$ rpm -i kernel-3.10.0-957.el7.src.rpm 2>/dev/null
    ```

* 检查 `BuildRequire` 有没有少安装

    ```sh
    ]$ grep BuildRequire ~/rpmbuild/SPEC/kernel.spec

    BuildRequires: module-init-tools, patch >= 2.5.4, bash >= 2.03, sh-utils, tar
    BuildRequires: xz, findutils, gzip, m4, perl, make >= 3.78, diffutils, gawk
    BuildRequires: gcc >= 4.8.5-29, binutils >= 2.25, redhat-rpm-config >= 9.1.0-55
    BuildRequires: hostname, net-tools, bc
    BuildRequires: xmlto, asciidoc
    BuildRequires: openssl
    BuildRequires: hmaccalc
    BuildRequires: python-devel, newt-devel, perl(ExtUtils::Embed)  # perl-ExtUtils-Embed
    BuildRequires: pesign >= 0.109-4
    BuildRequires: elfutils-libelf-devel
    BuildRequires: sparse >= 0.4.1
    BuildRequires: elfutils-devel zlib-devel binutils-devel bison
    BuildRequires: audit-libs-devel
    BuildRequires: java-devel
    BuildRequires: numactl-devel
    BuildRequires: pciutils-devel gettext ncurses-devel
    BuildRequires: python-docutils
    BuildRequires: zlib-devel binutils-devel
    BuildRequires: rpm-build >= 4.9.0-1, elfutils >= 0.153-1
    BuildRequires: bison flex
    BuildRequires: glibc-static

    root ~] yum install module-init-tools patch bash sh-utils tar xz findutils gzip m4 perl make diffutils gawk gcc binutils redhat-rpm-config hostname net-tools bc xmlto asciidoc openssl hmaccalc python-devel newt-devel perl pesign elfutils-libelf-devel sparse elfutils-devel zlib-devel binutils-devel bison audit-libs-devel java-devel numactl-devel pciutils-devel gettext ncurses-devel python-docutils zlib-devel binutils-devel rpm-build elfutils bison flex glibc-static
    ```


* 解压并释放源码包

    ```sh
    ]$ cd ~/rpmbuild/SPECS
    ]$ rpmbuild -bp --target=$(uname -m) kernel.spec
    ```

* 修改配置文件

    ```sh
    # 1. 切换至相应目录, 准备修改".config"
    cd ~/rpmbuild/BUILD/kernel-3.10.0-957.el7/linux-3.10.0-957.el7.x86_64/

    # 2. 自定义编译模块
    make menuconfig

    # 3. .config 文件改名, 拷贝到编译配置文件目录
    cp .config ~/rpmbuild/SOURCES/kernel-3.10.0-`uname -m`.config

    ```

* 编译

    ```sh
    cd ~/rpmbuild/SPECS
    rpmbuild -bb --target=`uname -m` kernel.spec --without debug --without debuginfo
    ```


    如果出现以下报错, 则需要修改 ```~/rpmbuild/SOURCES/kernel-3.10.0-`uname -m`.config```, 首行修改为 `# x86_64`

    ```text
    ...
    + rm -f .newoptions
    + make ARCH= oldnoconfig
    Makefile:530: arch//Makefile: No such file or directory
    make: *** No rule to make target 'arch//Makefile'.  Stop.
    error: Bad exit status from /var/tmp/rpm-tmp.AEKmiI (%prep)


    RPM build errors:
        Bad exit status from /var/tmp/rpm-tmp.AEKmiI (%prep)
        ...
    ```


## 报错处理

### `[FAILED] Failed to mount /. - See 'systemctl status -.mount' for details`

确保 `/etc/mtab` 是软链接，是否指向 `/proc/self/mounts`


### `[FAILED] Failed to listen on RPCbind Server Acitvation Socket`

已知 Bug, 可升级到 `rpcbind-0.2.0-49.el7.x86_64.rpm`

或者: 

```text
[Unit]
Description=RPCbind Server Activation Socket

[Socket]
ListenStream=/var/run/rpcbind.sock

# RPC netconfig can't handle ipv6/ipv4 dual sockets
# Workaround for RHBZ 1531486
#BindIPv6Only=ipv6-only       # <= 注释
#ListenStream=0.0.0.0:111     # <= 注释
#ListenDatagram=0.0.0.0:111   # <= 注释
#ListenStream=[::]:111        # <= 注释
#ListenDatagram=[::]:111      # <= 注释

[Install]
WantedBy=sockets.target
```


### `dracut-initqueue timeout: dracut-initqueue timeout`

```text
...
dracut-initqueue timeout: dracut-initqueue timeout
...
/dev/rootvg/lvswap1 does not exist
/dev/rootvg/lvswap2 does not exist
/dev/rootvg/lvswap3 does not exist
/dev/rootvg/lvswap4 does not exist

dracut>
```

原因: `/dev/rootvg/lvswap1` 被人为删除

1. 手动挂载`/`、`/boot`、`/boot/efi` (如果有efi，可以结合 `blkid` 和 `/etc/fstab` 判断)
2. 修改 `/<MOUNT_POINT>/etc/fstab`, 注释掉swap相关的配置行
3. 修改 `/<MOUNT_POINT>/boot/efi/EFI/redhat/grub.cfg`, 将`linux16`(efi为`linuxefi`)行中的 `rd.lvm.lv=rootvg/swap` 字样的都注释(先备份后再修改)
4. `reboot`


### `ffi.h No such file or directory`

```sh
yum install libffi libffi-devel  # centos
apt install libffi libffi-dev    # ubuntu
```


### LVM reports `Cannot use device with duplicates.`

Refer to: [https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/duplicate_pv_multipath](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/duplicate_pv_multipath)

* When attempting to extend a VG, the below error is produced: 

    ```sh
    ~] vgextend example_vg /dev/mapper/mpatha
    
    Error vgextend : Cannot use device /dev/mapper/mpatha with duplicates.
    WARNING: Not using lvmetad because duplicate PVs were found.
    WARNING: Use multipath or vgimportclone to resolve duplicate PVs?
    WARNING: After duplicates are resolved, run "pvscan --cache" to enable lvmetad.
    WARNING: PV xxxxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx on /dev/sdx was already found on /dev/sdy.
    WARNING: PV xxxxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx on /dev/sdy was already found on /dev/sdz.
    WARNING: PV xxxxxx-xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx on /dev/sdz was already found on /dev/mapper/mpatha.
    <...>
    Cannot use device /dev/mapper/mpatha with duplicates.
    ```

* or when attempting to create a new volume group, getting error: `Cannot use device /dev/mapper/mpatha with duplicates.`

* 解决

    LVM 会尝试扫描列出所有设备有 lvm 标记的磁盘, 当配置了多路径设备时会出现以上报错, 可修改 `/etc/lvm.conf` 的 filter 进行过滤:

    ```text
    # This configuration option has an automatic default value.
    # filter = [ "a|.*/|" ]
    filter = [ "a|^/dev/sda5$|", "a|/dev/emcpower.*|", "r|.*|" ]
    global_filter = [ "a|^/dev/sda5$|, "a|/dev/emcpower.*|", "r|.*|" ]
    ```

    修改完毕后, 重建 initramfs:

    ```sh
    cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.$(date +%m-%d-%H%M%S).bak
    dracut -f -v
    pvscan --cache
    ```

* 附 `lvm.conf` filter 配置示例

    > * `a` - accept
    > * `r` - reject

    ```conf
    # Accept every block device (default value):
    filter = [ "a|.*/|" ]

    # Reject the cdrom drive:
    filter = [ "r|/dev/cdrom|" ]

    # Work with just loopback devices, e.g. for testing:
    filter = [ "a|loop|", "r|.*|" ]

    # Accept all loop devices and ide drives except hdc:
    filter = [ "a|loop|", "r|/dev/hdc|", "a|/dev/ide|", "r|.*|" ]

    # Use anchors to be very specific:
    filter = [ "a|^/dev/hda8$|", "r|.*/|" ]

    # Use global_filter to hide devices from these LVM system components.
    # The syntax is the same as devices/filter. Devices rejected by
    # global_filter are not opened by LVM.
    # This configuration option has an automatic default value.
    global_filter = [ "a|.*/|" ]
    ```

    This filter accepts the second partition on the first hard drive ( `/dev/sda` and any `device-mapper-multipath devices`, while rejecting everything else.)
    
    ```conf
    filter = [ "a|/dev/sda2$|", "a|/dev/mapper/mpath.*|", "r|.*|" ]
    ```
    
    This filter accepts all HP SmartArray controllers and any EMC PowerPath devices.
    
    ```conf
    filter = [ "a|/dev/cciss/.*|", "a|/dev/emcpower.*|", "r|.*|" ]
    ```
    
    This filter accepts any partitions on the first IDE drive and any multipath devices.
    
    ```conf
    filter = [ "a|/dev/hda.*|", "a|/dev/mapper/mpath.*|", "r|.*|" ]
    ```

    -> 2022-11-25 EMC存储:

    ```conf
    filter = [ "a|/dev/sda3$|", "a|/dev/sda4$|", "a|/dev/cciss/.*|", "a|/dev/mapper/mpath.*|","a|/dev/emcpower.*|","r|.*|" ]
    ```


### NetworkManager

部分情况下进行运行级别切换, 对配置了 team 的网络会有影响

* team

    | 运行级别切换 | 切换前               | 切换后                   |
    | ------------ | -------------------- | :----------------------- |
    | 3 -> 5       | NM=Running, Disabled | team0 网卡丢失, NM->Dead |
    | 3 -> 5       | NM=Dead, Disabled    | team0 网卡丢失, NM->Dead |
    | 3 -> 5       | NM=Running, Enabled  | 正常, NM=Running         |
    | 3 -> 5       | NM=Dead, Enabled     | 正常, NM=Running         |
    | 5 -> 3       | NM=Running, Disabled | team0 网卡丢失, NM->Dead |
    | 5 -> 3       | NM=Dead, Disabled    | team0 网卡丢失, NM->Dead |
    | 5 -> 3       | NM=Running, Enabled  | 正常, NM=Running         |
    | 5 -> 3       | NM=Dead, Enabled     | 正常, NM=Running         |

* bond

    | 运行级别切换 | 切换前              | 切换后 |
    | ------------ | ------------------- | :----- |
    | 3 -> 5       | NM=Dead,Disabled    | 正常   |
    | 3 -> 5       | NM=Running,Disabled | 正常   |

* 无 bond / team

    单网卡/双网卡均无影响


### `pam_sss(sshd:account): Request to sssd failed. Connection refused`

[Reference Link](https://support.oracle.com/knowledge/Oracle%20Linux%20and%20Virtualization/2309075_1.html)

Local users cannot login to the server.  The /var/log/secure log shows entries similar to:

```text
Sep 18 10:44:39 hostname sshd[XXXXXX]: Connection from XX.XX.XX.XX port XXXXX
Sep 18 10:44:40 hostname sshd[XXXXXX]: pam_sss(sshd:account): Request to sssd failed. Connection refused >>>
Sep 18 10:44:40 hostname sshd[XXXXXX]: Failed password for username from XX.XX.XX.XX port XXXXX ssh2
Sep 18 10:44:40 hostname sshd[XXXXXX]: fatal: Access denied for user <User_name> by PAM account configuration
```

The PAM (Pluggable Authentication Module) subsystem module `pam_sss.so` is blocking the local user authentication.

PAM is not allowing user access to non-LAPD users when the sssd(8) service is not running.

Solution: 

* Validate the availability of the LDAP server and then run the below command to restart the sssd(8) service.

* 如果升级了内核, 同步升级 sssd 至最新版本


### `Timed out waiting for device dev-disk-by\x2duuid-XXXXXXX.device`

`/etc/fstab` 中使用的是`UUID`指定挂载设备, 而此时 UUID 发生了改变, 修改成新的 UUID 即可


### `Timed out waiting for device dev-mapper-rhel\x2dlvTSMARC.device`

```text
...
Job device dev-mapper-rhel\x2dlvTSMARC.device/start timed out
systemd[1]: Timed out waiting for device dev-mapper-rhel\x2dlvTSMARC.device
Dependence failed for /TSMARC.
Denpedence failed for Local File Systems.
Job...
```

检查 `/etc/fstab` 和 `lsblk`, `lvs` 输出的区别, `/etc/fstab` 是否存在配置错误的行 ?


### `dracut-initqueue[xxx]: Warning: dracut-initqueue timeout`

```text
...
[  192.205351] dracut-initqueue[259]: Warning: dracut-initqueue timeout

        Starting Dracut Emergency Shell...
Warning: /dev/centos/root does not exist
Warning: /dev/centos/swap does not exist
Warning: /dev/mapper/centos-root does not exist

Generating "/run/initramfs/rdsosreport.txt"

Entering emergency mode. Exit the shell to continue.
Type "journalctl" to view system logs.
You might want to save "/run/initramfs/rdsosreport.txt" to a USB stick or /boot
after mounting them and attach it to a bug report.

dracut:/#
```

开机内核选择界面, 选择带 `rescue` 的内核 `CentOS Linux (0-rescue-...) 7 (Core)` 启动, 启动后使用 root 登录, 执行 `dracut -f`, 重启


### `jexec servicesStarting certmonger`

CentOS 6.6 开机卡在 `jexec servicesStarting certmonger`，修改运行级别：

```sh
~] vi /etc/inittab
id:3:initdefault:    # 修改为 3
```


### `Failed to set locale, defaulting to C.UTF-8`

CentOS/RHEL 8 中, 执行 `dnf repolist` 或者其他 `dnf`/`yum` 命令时，出现以下报错：

```sh
~] dnf repolist
Failed to set locale, defaulting to C.UTF-8            <=报错
Updating Subscription Management repositories.
Unable to read consumer identity

This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.
```

这是系统缺少语言包，导致设置的 `/etc/locale.conf` 中的设置 ( 如 `LANG=en_US.UTF-8` ) 无法被 `dnf`/`yum` 读取

* 查看目前系统已安装的语言包

    ```sh
    locale -a
    ```

* 安装语言包

    ```sh
    # 中文
    yum install glibc-langpack-zh

    # 英文
    dnf install glibc-langpack-en
    # 或
    dnf install langpacks-en glibc-all-langpacks
    ```


### `swapon: /xxx/swapfile: swapon failed: Cannot allocate memory`

- Increase `vm.min_free_kbytes` value, for example to a higher value than a single allocation request. 
- Change `vm.zone_reclaim_mode` to 1 if it's set to zero, so the system can reclaim back memory from cached memory.  


### `PAM uable to dlopen(/usr/lib/security/pam_limits.so): /usr/lib/security/pam_limits.so: cannot open share object file: No such file or directory

```sh
mkdir -p /lib/security/
cp /lib64/security/pam_limits.so /lib/security/
```