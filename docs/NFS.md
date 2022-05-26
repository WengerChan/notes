# NFS - Network File System

> NFS Server 相关文档

## 安装

> 服务端和客户端都需要安装

```sh
yum install nfs-utils rpcbind    # 安装nfs-utils时会依赖安装rpcbind
```

## 配置

### 配置文件

NFS配置文件主要为 `/etc/exports`, 每行一条记录, 代表一个对外共享的目录, 其配置格式:

```sh
[共享目录] [第一台主机(权限)] [主机可用"主机名", "通配符"表示]
```

关于 `(权限)` 相关理解:

|权限|解释|
| --------- | ------- |
|`rw`, `ro` | 指定客户端对共享目录的权限: 可读或读写(最终能不能"读写", 需要检查文件权限及身份) |
|`sync`, `async` | `sync`代表数据会同步写入到内存与硬盘中, `async`则代表数据会暂存于内存当中, 而非直接写入硬盘 |
|`root_squash`, `no_root_squash` | 客户端使用NFS文件系统的账号为root时, 系统该如何判断这个账号的身份？<br>默认的情况下, 客户端root的身份会由`root_squash`的设置`nfsnobody`, 如此对服务器系统会较有保障。<br>如果想开放客户端使用root身份来操作服务器的文件系统, 设置`no_root_squash` |
|`all_squash` | 不论NFS的用户为何, 他的身份都会被压缩成为匿名用户, 通常也就是nobody(nfsnobody) |
|`anonuid`, `anongid` | 对匿名用户设置uid和gid(必须是`/etc/passwd`存在的uid和gid) |
|`hide`, `no_hide` | `hide`: NFS共享目录下的子目录不可见<br>`no_hide` : 可见 |
|`secure`, `insecure` | `secure`: 限制客户端只能从小于1024的tcp/ip端口连接nfs服务器（默认设置）<br>`insecure` : 允许 |
|`subtree`, `no_subtree` | `subtree`: 若输出目录是一个子目录, 则nfs服务器将检查其父目录的权限(默认设置)；<br>`no_subtree`: 即使输出目录是一个子目录, nfs服务器也不检查其父目录的权限, 这样可以提高效率； |

### Samples

- Export the entire filesystem to machines master and trusty.  In addition to write access, all uid squashing is turned off for host trusty.

    ```sh
    /           master(rw) trusty(rw,no_root_squash)`
    ```

- Examples for wildcard hostnames and netgroups (This is the entry `@trusted').

    ```sh
    /projects   proj*.local.domain(rw)`
    ```

    ```sh
    /usr        *.local.domain(ro) @trusted(rw)
    ```

- Set uid and gid for all anonymous users

    `all_squash`: Map all uids and gids to the anonymous user.

    ```sh
    /home/joe   pc001(rw,all_squash,anonuid=150,anongid=100)
    ```

- Exports the public FTP directory to every host in the world, executing all requests under the nobody account. 

    The `insecure` option in this entry also allows clients with NFS implementations that don't use a reserved port for NFS.    

    ```sh
    /pub        *(ro,insecure,all_squash)
    ```

- Exports a directory read-write to the machine 'server' as well as the '@trusted' netgroup, and read-only to netgroup '@external'

    All three mounts with the 'sync' option enabled.   

    ```sh
    /srv/www    -sync,rw server @trusted @external(ro)
    ```

- Exports a directory to both an IPv6 and an IPv4 subnet.   

    ```sh
    /foo        2001:db8:9:e54::/64(rw) 192.0.2.0/24(rw)
    ```

- Demonstrate a character class wildcard match.  

    ```sh
    /build      buildhost[0-9].local.domain(rw)
    ```

- Exports a directory to static ip (192.168.163.241)  

    ```sh
    /           192.168.163.241(rw)
    ```


## 启动服务

* 为 `rpcbind` 和 `nfs-server` 服务设置开机自启: 

    ```sh	
    systemctl enable rpcbind
    systemctl enable nfs-server
    ```

* 启动服务:

    ```sh
    systemctl start rpcbind
    systemctl start nfs-server
    ```


## 客户端配置

* 安装服务包 

    ```sh
    yum install rpcbind nfs-utils 
    ```

* 服务设置

    ```sh
    systemctl enable rpcbind
    systemctl start rpcbind
    ```

* 获取服务器共享出来的目录

    ```sh
    showmount -e ServerHost
    ```

* 挂载

    * 手动挂载

        ```sh
        mount -t nfs 192.168.161.12:/home/example /mount_point
        # -o 指定选项

        sudo mount -t nfs -o vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport file-system-id.region.nas.aliyuncs.com:/ /mnt

        sudo mount -t nfs -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport file-system-id.region.nas.aliyuncs.com:/ /mnt
        ```

        | 参数 | 说明 |
        | vers | 文件系统版本，如 nfs v3、nfs v4 |
        | _netdev | 防止客户端在网络就绪之前开始挂载文件系统 |
        | noresvport | 网络重连时使用新的TCP端口，保障在网络发生故障恢复的时候不会中断连接 |


    * fstab

        ```sh
        192.168.161.12:/home/example  /mount_point  nfs  vers=3,_netdev,noresvport  0 0
        192.168.161.12:/home/example  /mount_point  nfs  defaults,_netdev,noresvport  0 0
        ```


## 关于 `showmount -e` 漏洞

`showmount -e` 通过 `mountd` 守护进程去显示信息, 因此可以限制 `mountd` 的访问达到限制

```sh
~] vi /etc/hosts.deny
mountd:all

~] vi /etc/hosts.allow
mountd:192.168.55.20
```

```sh
~] rpcinfo -p 192.168.1.71
   program vers proto   port  service
    100000    4   tcp    111  portmapper
    100000    3   tcp    111  portmapper
    100000    2   tcp    111  portmapper
    100000    4   udp    111  portmapper
    100000    3   udp    111  portmapper
    100000    2   udp    111  portmapper
    100024    1   udp  53579  status
    100024    1   tcp  40254  status
    100005    1   udp  20048  mountd
    100005    1   tcp  20048  mountd
    100005    2   udp  20048  mountd
    100005    2   tcp  20048  mountd
    100005    3   udp  20048  mountd
    100005    3   tcp  20048  mountd
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100227    3   tcp   2049  nfs_acl
    100003    3   udp   2049  nfs
    100003    4   udp   2049  nfs
    100227    3   udp   2049  nfs_acl
    100021    1   udp  48485  nlockmgr
    100021    3   udp  48485  nlockmgr
    100021    4   udp  48485  nlockmgr
    100021    1   tcp  45860  nlockmgr
    100021    3   tcp  45860  nlockmgr
    100021    4   tcp  45860  nlockmgr
```