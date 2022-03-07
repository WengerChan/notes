# LVM #

LVM: Logical Volume Manager, 逻辑卷管理. 

LVM 的工作原理其实很简单, 它就是通过将底层的物理硬盘/分区抽象的封装起来, 然后以逻辑卷的方式呈现给上层应用。

在传统的磁盘管理机制中, 我们的上层应用是直接访问文件系统, 从而对底层的物理硬盘进行读取, 而在 LVM 中, 其通过对底层的硬盘进行封装, 当我们对底层的物理硬盘进行操作时, 其不再是针对于分区进行操作, 而是通过一个叫做 "逻辑卷" 的东西来对其进行底层的磁盘管理操作。<sup>Baidu<sup>

## LVM相关概念 ##

```text
LVM 架构:

    +----------------------------------------------------------------------------------------------------------------------+
    |    +----------------------------------+     +-----------------------------------+     +----------------------------+ |
    |    |        /dev/sda, 100G            |     |         /dev/sdb, 100G            |     |        /dev/sdc, 100G      | |
    |    +----------------------------------+     +-----------------------------------+     +----------------------------+ |
    +...........|....................|....................|....................|...........................|...............+
    |           ↓                    ↓                    ↓                    ↓                           ↓               |
    |     +-----------+        +-----------+        +-----------+        +-----------+                    /                |
    |     |   1 GiB   |        |   99 GiB  |        |   50 GiB  |        |   50 GiB  |                   /                 |
    |     +-----------+        +-----------+        +-----------+        +-----------+                  /                  |
    |     | /dev/sda1 |        | /dev/sda2 |        | /dev/sdb1 |        | /dev/sda2 |                 /                   |
    |     +-----------+        +-----------+        +-----------+        +-----------+                /                    |
    |           |           +........|....................|.........+..........|..........+..........|...................+ |
    |           ↓           |        ↓                    ↓         .          ↓          .          ↓   Physical Volume | |
    |     +-----------+     | +-------------+      +-------------+  .   +-------------+   .   +-------------+            | |
    |     |   /boot   |     | |PV: /dev/sda2|      |PV: /dev/sdb1|  .   |PV: /dev/sdb2|   .   | PV: /dev/sdc|            | |
    |     +-----------+     | +-------------+      +-------------+  .   +-------------+   .   +-------------+            | |
    |                       +........|....................|.........+..........|..........+..........|...................+ |
    |                       |        ↓                    ↓         .          ↓                     ↓   Volume Group    | |
    |                       | +----------------------------------+  .   +-------------------------------------+          | |
    |                       | |       vg_root: 149 GiB           |  .   |           vg_bak: 150 GiB           |          | |
    |                       | +----------------------------------+  .   +-------------------------------------+          | |
    | +.....................+.............|.........................+.......................|............................+ |
    | |  Logical Volume                   ↓                                                 ↓                            | |
    | |  (LV)        +--------------------+-------------------+                   +---------+----------+                 | |
    | |              ↓                    ↓                    ↓                  ↓                    ↓                 | |
    | |     +-----------------+  +----------------+  +-----------------+  +----------------+  +-------------------+      | |
    | |     | lv_root: 40 GiB |  | lv_swap: 8 GiB |  | lv_data: 100 GiB|  | lv_bak: 100 GiB|  | Free Space: 50GiB |      | |
    | |     +-----------------+  +----------------+  +-----------------+  +----------------+  +-------------------+      | |
    | +.........|.....................|...................|......................|.......................................+ |
    |           ↓                     ↓                   ↓                      ↓                                         |
    |         +---+               +------+            +-------+             +---------+                                    |
    |         | / |               | swap |            | /data |             | /backup |                                    |
    |         +---+               +------+            +-------+             +---------+                                    |
    |                                                                                                                      |
    +----------------------------------------------------------------------------------------------------------------------+
```

* 相关名词解释

    * PV (Physical Volume): 物理卷
        
        物理卷在LVM管理中处于最底层, 它可以是实际物理硬盘上的分区, 也可以是整个物理硬盘。

        常用命令: `pvcreate`, `pvs`, `pvdisplay`, `pvremove`, `pvmove`, `pvscan`

    * VG (Volume Group): 卷组

        卷组建立在物理卷之上, 一个卷组中至少要包括一个物理卷, 在卷组建立之后可动态添加物理卷到卷组中。一个逻辑卷管理系统工程中可以只有一个卷组, 也可以拥有多个卷组。

        常用命令: `vgcreate`, `vgs`, `vgdisplay`, `vgremove`, `vgchange`, `vgreduce`, `vgextend`, `vgscan`, `vgrename`, `vgexport`, `vgimport`

    * LV (Logical Volume): 逻辑卷

        逻辑卷由卷组分配, 卷组中的未分配空间可以用于建立新的逻辑卷, 逻辑卷建立后可以动态地扩展和缩小空间。

        常用命令: `lvcreate`, `lvs`, `lvdisplay`, `lvremove`, `lvextend`, `lvresize`, `lvscan`, `lvrename`

    * PE (Physical Extent)

        每一个物理卷被划分为称为 PE (Physical Extents)的基本单元, 具有唯一编号的PE是可以被LVM寻址的最小单元。PE 的大小是可配置的, 默认为 4MB。
        
        > 注: PV 加入 VG 后, 才会划分 PE (后面实操中会提及)

    * LE(Logical Extent)

        逻辑卷也被划分为被称为 LE (Logical Extents) 的可被寻址的基本单位。在同一个卷组中, LE 的大小和 PE 是相同的, 并且一一对应。

* 命令速查

    | 命令 | 释义 |
    | -- | -- |
    | `lvchange` | Change the attributes of logical volume(s) |
    | `lvconvert` | Change logical volume layout |
    | `lvcreate` | Create a logical volume |
    | `lvdisplay` | Display information about a logical volume |
    | `lvextend` | Add space to a logical volume |
    | `lvmchange` | With the device mapper, this is obsolete and does nothing. |
    | `lvmconfig` | Display and manipulate configuration information |
    | `lvmdiskscan` | List devices that may be used as physical volumes |
    | `lvmsadc` | Collect activity data |
    | `lvmsar` | Create activity report |
    | `lvreduce` | Reduce the size of a logical volume |
    | `lvremove` | Remove logical volume(s) from the system |
    | `lvrename` | Rename a logical volume |
    | `lvresize` | Resize a logical volume |
    | `lvs` | Display information about logical volumes |
    | `lvscan` | List all logical volumes in all volume groups |
    | `pvchange` | Change attributes of physical volume(s) |
    | `pvresize` | Resize physical volume(s) |
    | `pvck` | Check the consistency of physical volume(s) |
    | `pvcreate` | Initialize physical volume(s) for use by LVM |
    | `pvdata` | Display the on-disk metadata for physical volume(s) |
    | `pvdisplay` | Display various attributes of physical volume(s) |
    | `pvmove` | Move extents from one physical volume to another |
    | `lvpoll` | Continue already initiated poll operation on a logical volume |
    | `pvremove` | Remove LVM label(s) from physical volume(s) |
    | `pvs` | Display information about physical volumes |
    | `pvscan` | List all physical volumes |
    | `segtypes` | List available segment types |
    | `systemid` | Display the system ID, if any, currently set on this host |
    | `tags` | List tags defined on this host |
    | `vgcfgbackup` | Backup volume group configuration(s) |
    | `vgcfgrestore` | Restore volume group configuration |
    | `vgchange` | Change volume group attributes |
    | `vgck` | Check the consistency of volume group(s) |
    | `vgconvert` | Change volume group metadata format |
    | `vgcreate` | Create a volume group |
    | `vgdisplay` | Display volume group information |
    | `vgexport` | Unregister volume group(s) from the system |
    | `vgextend` | Add physical volumes to a volume group |
    | `vgimport` | Register exported volume group with system |
    | `vgimportclone` | Import a VG from cloned PVs |
    | `vgmerge` | Merge volume groups |
    | `vgmknodes` | Create the special files for volume group devices in /dev |
    | `vgreduce` | Remove physical volume(s) from a volume group |
    | `vgremove` | Remove volume group(s) |
    | `vgrename` | Rename a volume group |
    | `vgs` | Display information about volume groups |
    | `vgscan` | Search for all volume groups |
    | `vgsplit` | Move physical volumes into a new or existing volume group |

## 实操一: LVM全新创建 ##

* 安装LVM软件包

    ```sh
    yum install lvm2
    ```

* 选择物理磁盘, 创建PV

    ```sh
    ~] lsblk /dev/vdb

    NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    vdb                 253:16   0    1G  0 disk 
    └─vdb1              253:17   0 1022M  0 part 
    ```

    此处创建分区, 而不是直接将整块磁盘作为PV; 一般建议生产环境的虚拟机使用此方式, 物理机直接使用整盘.


    ```sh
    # 格式: pvcreate < Disk_Name | Partition_Name>

    ~] pvcreate /dev/vdb1

    WARNING: xfs signature detected on /dev/vdb1 at offset 0. Wipe it? [y/n]: y
    Wiping xfs signature on /dev/vdb1.
    Physical volume "/dev/vdb1" successfully created.
    ```

    `pvs` 和 `pvdisplay` 同样都是查看pv信息, 但是 `pvdisplay` 显示的详细信息, 而 `pvs` 显示比较简略; `vgs` 和 `vgdisplay` , `lvs` 和 `pvdisplay` 亦是如此.

    ```sh
    ~] pvs

    PV         VG Fmt  Attr PSize    PFree   
    /dev/vdb1     lvm2 ---  1022.00m 1022.00m

    ~] pvdisplay 

    "/dev/vdb1" is a new physical volume of "1022.00 MiB"
    --- NEW Physical volume ---
    PV Name               /dev/vdb1
    VG Name               
    PV Size               1022.00 MiB
    Allocatable           NO
    PE Size               0    # <= PV此时并未被划分为PE
    Total PE              0    # <= PV此时并未被划分为PE
    Free PE               0    # <= PV此时并未被划分为PE
    Allocated PE          0    # <= PV此时并未被划分为PE
    PV UUID               3Ylg8w-2ej1-18Jg-iKg1-zaet-JXu4-jIIbdr  # <= 唯一UUID
    ```

    从上面输出可以看出, 此时 `PE Size`, `Total PE`, `Free PE`, `Allocated PE` 均为 0, 说明 PV 此时并未被划分为PE

* 创建 VG

    ```sh
    # 格式: vgcreate VG_Name PV_Name1, PV_name2, ...
    ~] vgcreate vg_test /dev/vdb1

    Volume group "vg_test" successfully created

    ~] vgdisplay

    --- Volume group ---
    VG Name               vg_test
    System ID             
    Format                lvm2
    Metadata Areas        1
    Metadata Sequence No  1
    VG Access             read/write
    VG Status             resizable
    MAX LV                0
    Cur LV                0
    Open LV               0
    Max PV                0
    Cur PV                1
    Act PV                1
    VG Size               1020.00 MiB    # <= VG大小
    PE Size               4.00 MiB       # <= PE大小
    Total PE              255            # <= PE总个数
    Alloc PE / Size       0 / 0   
    Free  PE / Size       255 / 1020.00 MiB
    VG UUID               lJMVMU-2GEG-ygtS-6Z6d-cDQt-0rfa-lTEsS1  # <= 唯一UUID
    ```

    VG 创建成功后, LVM 对 PV 进行 PE 划分, 此步骤结束后可查看到 PE 相关信息; "`PV Size`" 的值也由 "`1022.00 MiB`" 变成 "`1022.00 MiB / not usable 2.00 MiB`"

    ```sh
    ~] pvdisplay 

    --- Physical volume ---
    PV Name               /dev/vdb1
    VG Name               vg_test
    PV Size               1022.00 MiB / not usable 2.00 MiB
    Allocatable           yes 
    PE Size               4.00 MiB
    Total PE              255
    Free PE               255
    Allocated PE          0
    PV UUID               3Ylg8w-2ej1-18Jg-iKg1-zaet-JXu4-jIIbdr
    ```


* 创建 LV


    ```sh
    # 格式: lvcreate -n LV_Name < -L Size | -l N%FREE > VG_Name

    ~] lvcreate -n lv_test -L 64MB vg_test

    Logical volume "lv_test" created.

    ~] lvdisplay

    --- Logical volume ---
    LV Path                /dev/vg_test/lv_test
    LV Name                lv_test
    VG Name                vg_test
    LV UUID                39dHQN-0ECl-mrie-I2sX-1e73-Mswf-NVySIP
    LV Write Access        read/write
    LV Creation host, time centos76, 2022-03-07 11:01:23 +0800
    LV Status              available
    # open                 0
    LV Size                64.00 MiB
    Current LE             16
    Segments               1
    Allocation             inherit
    Read ahead sectors     auto
    - currently set to     8192
    Block device           252:0
    ```


* 格式化文件系统, 配置挂载

    ```sh
    ~] l3sblk /dev/vdb

    NAME                MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    vdb                 253:16   0    1G  0 disk 
    └─vdb1              253:17   0 1022M  0 part 
    └─vg_test-lv_test 252:0    0   64M  0 lvm  


    ~] mkfs.xfs /dev/mapper/vg_test-lv_test
    ~] mount /dev/mapper/vg_test-lv_test /mount_point
    ```


## 实操二: LVM在线扩容 ##

* 选择物理磁盘, 创建 PV

    * 情景一: 检查 VG 是否有空余空间, 如果有, 可使用空余空间扩容, 无需扩展 VG
    
        ```sh
        vgs
        ```
    
    * 情景二: VG 无空余空间; 检查是否有未使用的物理磁盘或者未分配完的空间, 如果有, 将使用这部分空间创建新的 PV

        ```sh
        lsblk
        pvcreate /dev/vdb2
        ```

* 扩展 VG (将 PV 添加至 VG )

    ```sh
    # 格式: vgextend VG_Name PV_Name

    vgextend vg_test /dev/vdb2
    ```

* 扩展 LV

    ```sh
    # 格式1: 使用lv所在vg的全部空间
    lvextend -l +100%FREE /dev/mapper/vg_test-lv_test
    
    # 格式2: 指定具体大小, 如扩5G
    lvextend -L +5G /dev/mapper/vg_test-lv_test
    ```


* 扩展文件系统

    * Ext: ext3, ext4, ...
    
    ```sh
    resize2fs /dev/mapper/vg_test-lv_test
    ```

    * XFS

    ```sh
    xfs_growfs /dev/mapper/vg_test-lv_test
    ```


## 实操三: RHCS 卷组信息同步 ##

搭建 RHCS 群集时, 如果未使用集群文件系统, 而使用的是本地文件系统, 在进行完 LVM 在线扩容, 建议对卷组执行一般导入导出, 同步 VG 信息

以两节点 RHCS 群集为例, 操作如下:

* Step 1: 停止群集服务(在此不做介绍)

* Step 2: 在主节点正常进行 LVM 分区扩容操作

* Step 3: 在主节点和备节点上将卷组 "失活" (两边都执行)

    ```sh
    vgchange -an vg_test
    ```

* Step 4: 主节点 "导出" 卷组

    ```sh
    vgexport vg_test
    ```

* Step 5: 备节点 "导入" 卷组

    ```sh
    vgimport vg_test
    ```

* Step 6: 备节点 "激活" 卷组

    ```sh
    vgchange -ay vg_test
    ```

* Step 7: 备节点手动挂载分区验证磁盘容量, 读写等

    ```sh
    mount /dev/vg_data/lv_data /mnt
    df -hT
    vgdisplay
    ...
    
    umount /mnt
    ```

* Step 8: 重复Step 3-7, 由备节点导出, 主节点导入

* Step 9: 主节点验证完毕后主备节点均 "激活" 卷组

    ```sh
    vgchange -ay vg_test
    ```

* 恢复群集服务

注: 执行以上命令时, 部分会由部分对卷组状态的提示, 忽略这部分提示

## 实操四: LVM 数据迁移 ##


* 情景一: 更新替换

    对LVM使用的底层物理磁盘更新替换: 如底层SAN存储到期更换或其他原因更新(e.g.: EMC -> Huawei); 典型的, 当前 LVM 使用的 LUN 识别为 `/dev/sdb`, 要更换相同大小或更大的LUN `/dev/sdc`

* 情景二: "磁盘整合"

    前期对 LVM 进行过多次扩容, 为了方便管理, 需要将多块磁盘整个成一块或者几块大的磁盘; 典型的, 当前 LVM 使用的共有三块磁盘 `/dev/sdb`, `/dev/sdc`, `/dev/sdd`各100G, 使用一块 500G 的磁盘来整合

* 基本思路

    * 将新磁盘添加到 VG ;
    * 将旧磁盘数据迁移到新加磁盘
    * 将旧磁盘从 VG 移除
    * 将旧磁盘创建的PV移除

    ```text
    +---------------------------------------------------------------------------------------+
    |   +...........................................+                                       |
    |   | vg_test                                   |                                       |
    |   |  +----------------+   +----------------+  |            +----------------------+   |
    |   |  |     100 GiB    |   |     100 GiB    |  |    Step 1  |       >=200 GiB      |   |
    |   |  +----------------+   +----------------+  | <--------+ +----------------------+   |
    |   |  |    /dev/sdb    |   |    /dev/sdc    |  |  vgextend  |       /dev/sdd       |   |
    |   |  +-------+--------+   +-------+--------+  |            +----------+-----------+   |
    |   +.+........|....................|...........+                       ↑               |
    |     | pvmove ↓             pvmove ↓                                   |               |
    |     |        +---->---->---->---->+---->---->---->---->---->---->---->+               | 
    |     |                                   Step 2                                        |
    |     ↓                                                                                 |
    | Step 3,4: Remove PVs(/dev/sdc, /dev/sdd)                                              |
    |                                                                                       |
    +---------------------------------------------------------------------------------------+
    ```

* 操作步骤

    ```bash
    # Step 1
    pvcreate /dev/sdd;
    vgextend vg_data /dev/sdd

    # Step 2
    pvmove -v /dev/sdd

    # Step 3
    vgreduce vg_data /dev/sdb
    vgreduce vg_data /dev/sdc

    # Step 4
    pvremove /dev/sdb
    pvremove /dev/sdc
    ```

* `pvmove(8)`: Examples

    ```sh
    # Move all physical extents that are used by simple LVs on the specified PV to free physical extents elsewhere in the VG.
    pvmove /dev/sdb1

    # Use a specific destination PV when moving physical extents.
    pvmove /dev/sdb1 /dev/sdc1

    # Move extents belonging to a single LV.
    pvmove -n lvol1 /dev/sdb1 /dev/sdc1

    # Rather  than  moving  the  contents  of an entire device, it is possible to move a range of physical extents, for example numbers 1000 to 1999 inclusive on the specified PV.
    pvmove /dev/sdb1:1000-1999

    # A range of physical extents to move can be specified as start+length. For example, starting from PE 1000. (Counting starts from 0, so this refers to the 1001st to the 2000th PE inclusive.)
    pvmove /dev/sdb1:1000+1000

    # Move a range of physical extents to a specific PV (which must have sufficient free extents).
    pvmove /dev/sdb1:1000-1999 /dev/sdc1

    # Move a range of physical extents to specific new extents on a new PV.
    pvmove /dev/sdb1:1000-1999 /dev/sdc1:0-999

    # If the source and destination are on the same disk, the anywhere allocation policy is needed.
    pvmove --alloc anywhere /dev/sdb1:1000-1999 /dev/sdb1:0-999

    # The part of a specific LV present within in a range of physical extents can also be picked out and moved.
    pvmove -n lvol1 /dev/sdb1:1000-1999 /dev/sdc1
    ```


## 关于PE大小 ##

当使用 `vgcreate` 创建 VG 时, 如果未指定 PE 大小, 那么 PE 默认大小 4MB.

* 创建 VG 时指定PE大小

    要指定 PE 大小, 使用类似以下命令创建 VG:

    ```sh
    vgcreate -s 8MB vg_test /dev/vdb1 # 8, 8M, 8Mb, 8MB, 8MiB 都是正确的格式
    ```

* 创建 VG 后修改 PE 大小

    `vgchange` man 文档关于 `-s` 的解释: 

    ```text
    -s|--physicalextentsize Size[m|UNIT]

        The value must be either a power of 2 of at least 1 sector (where the sector size is the largest sector size of the PVs currently used in the VG), or at least 128KiB.
        Once this value has been set, it is difficult to change without recreating the VG, unless no extents need moving.
        Before increasing the physical extent size, you might need to use `lvresize`, `pvresize` and/or `pvmove` so that everything fits. For example, every contiguous range of extents used in a LV must start and end on an extent boundary.
    ```

    经过实验, 总结来说:

    * 当修改 PE 大小时, 新设定的 PE 大小必须能够被当前VG空间大小 `PE Size * Total PE` 整除;
    * 修改 PE 后需要分别对 PV 和 LV 执行 `pvresize` 和 `lvresize` 操作, 同时还需要执行 `pvmove` 保证数据可用;
    * PE 也可以为 5MB, 10MB 等, 并非一定要 2 的幂数值;
    * 调小 PE 时, 一般 `PE Size / 2` 可用;
    * 生产环境下, 不建议直接修改 PE 大小, 最佳实践是**新建一个VG指定特定大小的PE, 对数据进行迁移**.


## 关于扫盘 ##

* 手动

    ```bash
    # 单个host扫描
    echo "- - -" > /sys/class/scsi_host/host0/scan

    # 全部host扫描一遍
    for h in $(ls /sys/class/scsi_host);do echo "- - -" > /sys/class/scsi_host/$h/scan; done
    ```

* 用过脚本

    当安装了 `sg3_utils` 包时, 可使用软件包含的扫描 SCSI 设备的脚本

    ```bash
    /usr/bin/rescan-scsi-bus.sh

    ~] rpm -qf /usr/bin/rescan-scsi-bus.sh
    sg3_utils-1.37-17.el7.x86_64
    ```