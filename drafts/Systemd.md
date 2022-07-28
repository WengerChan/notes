# Systemd


## systemd-mountd

创建/销毁临时 mount 或 automount 挂载点

* ***systemd-mount*** 用于创建并启动一个临时 `.mount` 或 `.automount` 单元，也就是将 WHAT 文件系统挂载到 WHERE 目录。

* ***systemd-mount*** 在功能上与传统的 ***mount(8)*** 命令很相似， 不同之处在于，***systemd-mount*** 并不立即直接执行挂载操作，而是将挂载操作封装到一个临时的 `.mount` 或 `.automount` 单元中，以接受 systemd 对各种单元的统一管理， 从而可以实现将挂载操作自动按照依赖关系排入任务队列、自动处理依赖关系、挂载前进行文件系统检查、按需自动挂载等好处。

* 如果仅设置了一个参数，那么此参数必须是一个块设备(例如 */dev/sdb1* )、 或者是一个包含文件系统镜像的普通文件(例如 */path/to/disk.img*)。 如果是一个块设备，那么对应的挂载点将根据该设备的文件系统卷标(label)或其他元数据自动生成(例如 */run/media/system/mydata*, */run/media/system/VBOX_HARDDISK*)。 在仅设置了一个参数的情况下，指定的块设备在调用该命令时必须是已经存在的。如果指定的块设备是一个例如U盘之类的移动块设备， 那么将会自动创建一个临时 `.automount` 单元(而不是默认的 `.mount` 单元)， 也就是相当于自动设置了 `--automount=yes` 选项(见后文)。

* 如果同时设置了两个参数， 那么 `WHAT` 参数表示挂载源、`WHERE` 参数表示挂载点。 在同时设置了两个参数的情况下， 如果明确使用了 `--discover` 选项， 那么指定的块设备在调用该命令时必须是已经存在的； 否则，指定的块设备在调用该命令时可以暂时不存在。

* 可以使用 `--list` 命令 列出所有本地已知可挂载的块设备的简明信息。

* `systemd-umount` 用于卸载 mount 或 automount 挂载点，它等价于 `systemd-mount --umount` 命令。


```sh
systemd-mount [OPTIONS...] WHAT [WHERE]
systemd-mount [OPTIONS...] --list
systemd-mount [OPTIONS...] --umount WHAT|WHERE...
```

### Options


```text
--no-block
    不同步等待临时挂载点单元完成启动操作。如果未使用此选项，那么 systemd-mount 将会在临时挂载点单元完成启动操作之后才返回。使用此选
    项之后， systemd-mount 将会立即返回，并以异步方式检查临时挂载点单元是否完成了启动操作。

--no-pager
    不将程序的输出内容管道(pipe)给分页程序。

--no-ask-password
    在执行特权操作时不向用户索要密码。

--quiet, -q
    安静模式，也就是不显示额外的信息。

--discover
    强制探测挂载源，也就是探测挂载源的文件系统卷标(label)及其他元数据，以帮助更有效的创建临时挂载点单元。 例如，将文件系统卷标以及设
    备型号组合在一起，作为临时挂载点单元的描述字符串。 又如，如果检测到的块设备是U盘之类的可移动块设备，那么将会创建临时 automount 
    单元(而不是常规的 mount 单元)， 并且会自动为下文的 --timeout-idle-sec= 选项设置一个较小的值，以确保及时卸载可移动文件系统，从
    而有效保证移动存储设备上的文件系统一致性。 如果仅设置了一个参数，那么此选项将被默认开启。

--type=, -t
    指定要挂载的文件系统类型(例如 "vfat", "ext4", …)。 如果省略(或设为 "auto")则表示自动检测。

--options=, -o
    设置明确的挂载选项。

--owner=USER
    将挂载的文件系统拥有者指定为 USER 用户。 也就是使用 uid= 与 gid= 挂载选项。 只有某些特定的文件系统支持此选项。

--fsck=
    控制是否在挂载之前先对文件系统进行一次检查，接受一个布尔值，默认值为 yes 。 对于 automount 单元(参见下文的 --automount= 选项)来
    说， 因为仅在首次访问块设备时才进行文件系统检查，所以可能会轻微的降低首次访问时的响应速度。

--description=
    为临时 mount 或 automount 单元设置一个描述性的字符串。参见 systemd.unit(5) 的 Description= 选项。

--property=, -p
    为临时 mount 单元设置一个属性。此选项接受的值的格式与 systemctl(1) 的 set-property 命令相同。

--automount=
    控制是否创建一个临时 automount 挂载点。接受一个布尔值。 设为 yes 表示创建一个临时 automount 挂载点，也就是仅在首次实际访问该挂载
    点时才真正挂载实际的文件系统。 设为 no 表示创建一个临时 mount 挂载点，也就是立即真正挂载实际的文件系统。 自动挂载点的好处是按需自
    动挂载，并且可以使用下文的 --timeout-idle-sec= 选项设置一个空闲时间以实现自动卸载，也就是，如果自动挂载点空闲(无访问)超过了指定的
    时长，那么它将被自动卸载。

    如果明确或者隐含(仅设置了一个参数)的设置了 --discover 选项， 并且检测到的块设备是U盘之类的可移动块设备， 那么此选项的默认值
    是 yes (以减少意外拔出可移动块设备可能造成的文件系统不一致)， 否则默认值是 no 。

-A
    等价于 --automount=yes

--timeout-idle-sec=
    设置 automount 单元的空闲超时时长。 也就是，如果自动挂载点(automount)空闲(无访问)超过了指定的时长，那么它将被自动卸载。
    systemd.time(7) 手册详细的描述了时长的表示语法。 此选项对仅创建了临时 mount 单元的挂载点 没有意义。

    注意，如果明确或者隐含(仅设置了一个参数)的设置了 --discover 选项， 并且检测到的块设备是U盘之类的可移动块设备，那么此选项的默认
    值是"1s"(一秒)， 否则，默认值是 "infinity"(永不超时)。

--automount-property=
    与 --property= 选项类似，不过仅作用于临时 automount 单元。

--bind-device=
    控制是否将 automount 单元与对应的块设备存在期绑定，此选项接受一个布尔值，且仅对 automount 挂载点有效。 设为 yes 表示：当对应的
    块设备消失时，automount 挂载点将会被自动删除。设为 no 表示：即使对应的块设备消失，automount 挂载点也依然被保留， 同时对该
     automount 挂载点的访问将会被一直阻塞到重新插上对应的块设备。 此选项对非设备类文件系统(例如网络文件系统或虚拟内核文件系统)的挂
     载无效。

    注意，如果明确或者隐含(仅设置了一个参数)的设置了 --discover 选项， 并且检测到的块设备是U盘之类的可移动块设备，那么此选项的默认值
    是 yes ， 否则，默认值是 no 。

--list
    命令列出所有 本地已知可挂载的块设备的简明信息 (包括例如文件系统卷标之类的元数据)。

-u, --umount
    停止 挂载点(WHERE)或块设备(WHAT)对应的 mount 与 automount 单元。 使用此选项等价于直接使用 systemd-umount 命令，并且可以一次接
    受多个参数， 这些参数可以是挂载点、块设备、/etc/fstab 风格的设备节点、 包含文件系统的 loop 文件，例如 
    systemd-mount --umount /path/to/umount /dev/sda1 UUID=xxxxxx-xxxx LABEL=xxxxx /path/to/disk.img 。 注意，如果使用了 -H 或
     -M 选项， 那么挂载点必须只能用绝对路径表示。

-G, --collect
    完成后卸载临时单元(即使它失败了)。如果不使用此选项， 所有挂载成功和失败的 mount 单元都将保留在内存中，直到用户使用 
    systemctl reset-failed 或等效命令显式重置失败状态。 另一方面，成功停止的单元将被立即卸载。使用该选项之后，单元的"垃圾回收"将更加
    激进， 无论单元是否成功停止，都会被卸载。此选项是 --property=CollectMode=inactive-or-failed 的快捷方式，详见 CollectMode= 选
    项(参见 systemd.unit(5) 手册)。

--user
    与当前调用用户的用户服务管理器(systemd 用户实例)通信， 而不是默认的系统服务管理器(systemd 系统实例)。

--system
    与系统服务管理器(systemd 系统实例)通信， 这是默认值。

-H, --host=
    操作指定的远程主机。可以仅指定一个主机名(hostname)， 也可以使用 "username@hostname" 格式。 hostname 后面还可以加上 SSH监听端口(
    以冒号":"分隔)与容器名(以正斜线"/"分隔)，也就是形如 "hostname:port/container" 的格式， 以表示直接连接到指定主机的指定容器内。 操
    作将通过SSH协议进行，以确保安全。 可以通过 machinectl -H HOST 命令列出远程主机上的所有容器名称。IPv6地址必须放在方括号([])内。

-M, --machine=
    在本地容器内执行操作。 必须明确指定容器的名称。

-h, --help
    显示简短的帮助信息并退出。

--version
    显示简短的版本信息并退出。
```

### Examples

```sh
systemd-mount /dev/cdrom                       # 挂载，不指定挂载点
systemd-mount /dev/cdrom /mnt                  # 普通模式挂载 -> 直接挂载
systemd-mount --discover /dev/cdrom /mnt       # 挂载
systemd-mount --automount=yes /dev/cdrom /mnt  # 自动挂载
systemd-mount --automount=yes --timeout-idle-sec=5s /dev/cdrom /mnt  # 配置空闲超时时间，超时后自动卸载

systemd-mount --umount /mnt                    # 卸载
systemd-mount --umount /dev/cdrom              # 卸载
systemd-umount /mnt                            # 卸载
```

执行完成以后，会自动生成对应的systemd服务，可用 `systemctl status|start|stop` 管理：

```sh
~] systemctl status mnt.mount 
● mnt.mount - /mnt
   Loaded: loaded (/run/systemd/transient/mnt.mount; transient)
Transient: yes
   Active: active (mounted) since Fri 2021-11-26 13:40:50 CST; 2h 52min ago
    Where: /mnt
     What: /dev/sr0
    Tasks: 0 (limit: 49468)
   Memory: 24.0K
   CGroup: /system.slice/mnt.mount

Nov 26 13:40:50 centos-test-app1 systemd[1]: Mounting /mnt...
Nov 26 13:40:50 centos-test-app1 mount[1851]: mount: /mnt: WARNING: device write-protected, mounted read-only.
Nov 26 13:40:50 centos-test-app1 systemd[1]: Mounted /mnt.

~] systemctl status mnt.automount 
● mnt.automount
   Loaded: loaded (/run/systemd/transient/mnt.automount; transient)
Transient: yes
   Active: active (running) since Fri 2021-11-26 13:40:06 CST; 2h 55min ago
    Where: /mnt

Nov 26 13:40:06 centos-test-app1 systemd[1]: Set up automount mnt.automount.
Nov 26 13:40:50 centos-test-app1 systemd[1]: mnt.automount: Got automount request for /mnt, triggered by 1848 (ls)
```