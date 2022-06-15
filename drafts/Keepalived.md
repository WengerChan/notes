# Keepalived

Keepalived 是 VRRP 协议的软件实现, 原生设计目的是为了高可用 ipvs 服务.  [https://keepalived.org](https://keepalived.org)

* 基于 VRRP 协议完成地址流程
* 为 VIP 所在地址的节点生成 ipvs 规则(在配置文件中预先定义)
* 为 ipvs 集群的各 RS 做健康状态检查
* 基于脚本调用接口完成脚本中定义的功能, 进而影响集群事务, 以此支持 nginx, HAproxy 等服务

## VRRP 术语

* 虚拟路由器: Virtual Router
* 虚拟路由器标识: VRID(0-255), 唯一标识虚拟路由器
* VIP: Virtual IP
* 物理路由器: master 主设备, backup 备用设备, priority 优先级
* IPVS: IP Virtual Server, 高效的 Layer-4 交换机, 提供负载均衡功能

## Keepalived 设计架构

![Keepalived 设计架构](./pictures/Keepalived/software_design.png)

* 用户空间

    * VRRP Stack: VIP 消息通告
    * checkers: 监测 real server
    * system call: 实现 vrrp 协议状态转换是调用脚本的功能
    * smtp: 邮件组件
    * ipvs wrapper: 生成 ipvs 规则
    * netlink reflector: 网络接口
    * watchdog: 监控进程

* 控制组件: 提供 keepalived.conf 解析器, 完成 keepalived 配置
* IO 复用器: 针对网络目的而优化自己的线程抽象
* 内存管理组件: 为某些通用的内存管理功能 (例如分配, 重新分配, 发布等) 提供访问权限