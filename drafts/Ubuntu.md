# Ubuntu

## 安装

虚拟机化环境, 安装后需删除部分不需要的软件:

```sh
apt purge cloud-init
apt purge cloud-guest-utils
apt purge open-vm-tools open-vm-tools-dev
```

## 软件/补丁源

* 本地 ISO 源

    * 清空或者注释 `/etc/apt/sources.list` 内容

    * 挂载 ISO 至 /media/cdrom

        ```sh
        mount /dev/cdrom /media/cdrom
        ```

    * 添加本地目录到软件源

        ```sh
        sudo apt-cdrom -m -d=/media/cdrom add
        apt-get update
        ```

        `apt-cdrom` 命令会在 `/etc/apt/sources.list` 中添加以下行:

        ```text
        deb cdrom:[Ubuntu-Server 16.04.7 LTS _Xenial Xerus_ - Release amd64 (20200810)]/ xenial main restricted
        ```

* 远程软件源

    > 可以在软件/补丁源服务器上, 通过挂载 ISO 或者向 Ubuntu 官方/国内在线源服务器同步等方式搭建

    主要看 `ubuntu/dist` 目录下拥有哪些目录, 就可以配置哪些目录.

    方法一: 使用命令添加

    ```sh
    # ISO
    apt-add-repository "http://192.168.161.1:8800/ubuntu16.04.7 main restricted"
    ```

    方法二: 编辑配置文件

    ```sh
    ~] vi /etc/apt/sources.list

    deb http://192.168.161.1:8800/ubuntu16.04.7 xenial main restricted
    ```

* 软件源目录结构

    ```text
    /
    dists/    包含各个发行版
        bionic/            
            main/          自由软件、可以被自由发布的软件和被Ubuntu团队完全支持的软件
            multiverse/    包含非自由软件, 需尊重版权, 自行负责
            restricted/    没有自由软件版权, 但依然被Ubuntu团队支持的软件
            universe/      包含大多数开源软件建立在公共源上(由main中软件编写, 但是没有升级/维护保障)
        bionic-security/    仅修复漏洞, 并且尽可能少的改变软件包的行为
        bionic-backports/   security 策略加上新版本的软件（包括候选版本的）
        bionic-updates/     修复严重但不影响系统安全运行的漏洞
        bionic-proposed/    update 类的测试部分, 仅建议提供测试和反馈的人进行安装
    indices/      维护人员文件和重载文件
    pool/         实际存储软件包的位置, dists/中文件会指向此处
        main/        
        multiverse/  
        restricted/  
        universe/    
    project/      大部分为开发人员的资源 (包括 gpg, gpg.sig, release 等文件)
    ```


## Server and Desktop Differences (20.04 LTS)

The *Ubuntu Server Edition* and the *Ubuntu Desktop Edition* use the same apt repositories, making it just as easy to install a *server* application on the Desktop Edition as on the Server Edition.

One major difference is that the graphical environment used for the Desktop Edition is not installed for the Server. This includes the graphics server itself, the graphical utilities and applications, and the various user-supporting services needed by desktop users.


## Package Management

### apt

```text
Most used commands:
  list         - list packages based on package names
  search       - search in package descriptions
  show         - show package details
  install      - install packages
  reinstall    - reinstall packages
  remove       - remove packages
  autoremove   - Remove automatically all unused packages
  update       - update list of available packages
  upgrade      - upgrade the system by installing/upgrading packages
  full-upgrade - upgrade the system by removing/installing/upgrading packages
  edit-sources - edit the source information file
  satisfy      - satisfy dependency strings
  purge        - ="remove --purge", 删除软件的同时删除配置文件
```

### apt-cache

apt-cache 主要用于搜索软件

```sh
apt-cache search neofetch
apt-cache show nofetch
```

### dpkg

```text
Usage: dpkg [<option> ...] <command>

Commands:
  -i|--install       <.deb file name>... | -R|--recursive <directory>...
  -r|--remove        <package>... | -a|--pending
  -P|--purge         <package>... | -a|--pending
  -s|--status [<package>...]       Display package status details.
  -p|--print-avail [<package>...]  Display available version details.
  -L|--listfiles <package>...      List files 'owned' by package(s).
  -l|--list [<pattern>...]         List packages concisely.
  -S|--search <pattern>...         Find package(s) owning file(s).

Options:
  --admindir=<directory>     Use <directory> instead of /var/lib/dpkg.
  --root=<directory>         Install on a different root directory.
  --instdir=<directory>      Change installation dir without changing admin dir.
  --path-exclude=<pattern>   Do not install paths which match a shell pattern.
  --path-include=<pattern>   Re-include a pattern after a previous exclusion.
  -O|--selected-only         Skip packages not selected for install/upgrade.
  -E|--skip-same-version     Skip packages whose same version is installed.
  -G|--refuse-downgrade      Skip packages with earlier version than installed.
  -B|--auto-deconfigure      Install even if it would break some other package.
  --[no-]triggers            Skip or force consequential trigger processing.
  --verify-format=<format>   Verify output format (supported: 'rpm').
  --no-debsig                Do not try to verify package signatures.
  --no-act|--dry-run|--simulate
                             Just say what we would do - don't do it.
  --force-...                Override problems (see --force-help).
  --no-force-...|--refuse-...
                             Stop when problems encountered.
  --abort-after <n>          Abort after encountering <n> errors.

Comparison operators for --compare-versions are:
  lt le eq ne ge gt       (treat empty version as earlier than any version);
  lt-nl le-nl ge-nl gt-nl (treat empty version as later than any version);
  < << <= = >= >> >       (only for compatibility with control file syntax).

Use 'apt' or 'aptitude' for user-friendly package management.
```

## Network

```sh
ip addr add 10.102.66.200/24 dev eth0 # 设置临时 IP

ip link set dev eth0 up 
ip link set dev eth0 down

~] /etc/resolv.conf    # 设置临时 DNS
nameserver 8.8.8.8

ip route add default via 10.102.66.1  # 设置临时默认路由
ip addr flush eth0                    # 清空网卡的临时配置
```

永久配置:

* 14.04/16.04

    ```sh
    ~] vi /etc/network/interfaces
    
    # This file describes the network interfaces available on your system
    # and how to activate them. For more information, see interfaces(5).
    
    source /etc/network/interfaces.d/*
    
    # The loopback network interface
    auto lo
    iface lo inet loopback
    
    # The primary network interface
    auto ens3
    iface ens3 inet static
            address 192.168.161.20
            netmask 255.255.255.0
            network 192.168.161.0
            broadcast 192.168.161.255
            gateway 192.168.161.1
            # dns-nameservers 114.114.114.114 # DNS
    ```

    除了使用 `dns-nameservers` 关键字配置 DNS, 还可以编辑 `/etc/resolvconf/resolv.conf.d/base` 配置:
    
    ```sh
    ~] vi /etc/resolvconf/resolv.conf.d/base 
    nameserver 114.114.114.114

    ~] resolvconf -u
    ```

    重启网络生效：

    ```sh
    /etc/init.d/networking restart
    ```

* 18.04/20.04

    > 网络命令 `netplan` 由 `netplan.io` 这个包提供，不要安装成 `netplan` 这个包。

    ```sh
    ~] cat /etc/netplan/00-installer-config.yaml

    # This is the network config written by 'subiquity'
    network:
      ethernets:
        enp1s0:
          addresses:
          - 192.168.161.21/24
          gateway4: 192.168.161.1
          nameservers:
            addresses: []
            search: []
      version: 2
    
    ~] netplan apply
    ```

    查看 DNS 情况:

    ```sh
    ~] systemd-resolve --status
    ```

## Network - bond

> 参考：[https://netplan.io/examples](https://netplan.io/examples)

* 18.04

    ```sh
    ~] vi /etc/netplan/01-xxxxx.yaml
    network:
      bonds:
        bond1:
          addresses:
          - 10.139.130.4/24
          gateway4: 10.139.130.1
          interfaces:
          - eno1
          - eno2
          nameservers:
            addresses:
            - 114.114.114.114
            - 223.6.6.6
          parameters:
            mode: active-backup
            mii-monitor-interval: 100
      ethernets:
        eno1: {}
        eno2: {}
      version: 2
    ```
  
## Network - team

18.04 - Install `NetworkManager, teamd`, then use `nmcli` to configurate 'team0'

```sh
# 1. install
$ sudo apt install network-manager
$ sudo apt install teamd

# 2. Edit
$ vim /etc/NetworkManager/NetworkManager.conf
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=false   # false -> true

[device]
wifi.scan-rand-mac-address=no

# 3. start
$ systemctl start network-manager
$ systemctl enable network-manager

# 4. 
$ vim /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  renderer: NetworkManager    # -> add: 'renderer: NetworkManager'
                              # -> or change 'renderer: networkd' -> 'renderer: NetworkManager'
  ethernets:
    enp1s0:
      addresses:
      - 192.168.161.21/24
      gateway4: 192.168.161.1
      nameservers:
        addresses: []
        search: []
  version: 2

# 5. Remove all of other network config
$ mv /etc/netplan/xxx.yaml /tmp/   # backup
$ netplan apply

# 6. use 'nmcli'
# delete old
$ nmcli con del bond0
$ nmcli con del bond0-ens192
$ nmcli con del bond0-ens224

# create new
$ nmcli con add type team ifname team0 con-name team0 config '{"runner":{"name":"activebackup"}}'
$ nmcli con add type team-slave ifname eth0 con-name team0-eth0 master team0
$ nmcli con add type team-slave ifname eth1 con-name team0-eth1 master team0
$ nmcli con mod team0 ipv4.addresses 192.168.161.40/24 ipv4.gateway 192.168.161.1 ipv4.method manual autoconnect yes
```