# Linux, GNU/Linux

## 单用户模式

### RHEL/Centos 6.x

```
select "kernel…"

s或者single

passwd root

reboot
```
 
### RHEL/Centos 7.x/8.x

使用 `runlevel1.target` 或 `rescue.target` 实现: 

* 在此模式下, 系统会 **挂载所有的本地文件系统**, 但不会开启网络接口。
* 系统仅启动特定的几个服务和修复系统必要的尽可能少的功能
* 常用场景：
    * 修复损坏的文件系统
    * 重置root密码
    * 修复系统上的一个挂载点问题

进入单用户模式的三种方法:

* 方法 1：通过向内核添加 `rd.break` 参数

    * linux16 这一行添加:

        ```sh
        rd.break
        ```

    * `ctrl+x` 引导进入系统, 执行以下命令修改 `/sysroot` 为读写(rw)

        ```sh
        mount -o remount,rw /sysroot/
        ```

    * 切换环境
    
        ```sh
        chroot /sysroot/
        ```

    * 7/8版本系统默认使用 SELinux, 因此创建下面的隐藏文件, 这个文件会在下一次启动时重新标记所有文件
    
        ```sh
        touch /.autorelabel
        reboot
        ```

* 方法 2：通过用 `init=/bin/bash` 或 `init=/bin/sh` 替换内核中的 `rhgb quiet` 语句

    * `init=/bin/bash` 或 `init=/bin/sh` 替换内核中的 `rhgb quiet` 语句

    * 重新挂载 `/`
    
        ```sh
        mount -o remount,rw /
        ```

    * 执行完操作后, 创建标记文件并重启

        ```sh
        touch /.autorelabel
        exec /sbin/init 6
        ```

* 方法 3：通过用 `rw init=/sysroot/bin/sh` 替换内核中的 `ro` 语句

    * `rw init=/sysroot/bin/sh` 替换内核中的 `ro` 单词

    * 切换环境

        ```sh
        chroot /sysroot
        ```

    * 执行完操作后, 创建标记文件并重启

        ```sh
        touch /.autorelabel
        reboot -f
        ```

### SuSE 12

```sh
init=/bin/bash

mount -o remount,rw /

echo 'root:password' | /usr/sbin/chpasswd

mount -o remount,ro /
```

### Ubuntu

高级选项 => recovery模式 => 

修改: 

```sh
ro recovery nomode set ==> rw single init=/bin/bash
```

### Kylin V10

> GRUB密码: root/Kylin123123

```sh
rd.break

mount -o remount,rw /sysroot

chroot /sysroot

...

reboot
```

ARM版本, 如华为泰山:

```sh
init=/bin/bash console=tty1

mount -o remount,rw /sysroot
# mount -o remount,rw /

chroot /sysroot

...

reboot
```



