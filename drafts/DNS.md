# DNS

## DNS简介

* DNS

    DNS (Domain Name System)是一种分布式数据库系统，用于将主机名与对应的 IP 地址关联。对于用户，其优势在于他们可以通过名称来指代网络上的计算机，这些名称通常比数字网络地址更容易记忆。对于系统管理员而言，使用 DNS 服务器（也称为名称服务器）可以更改主机的 IP 地址，而不会影响基于名称的查询。DNS 数据库的使用不仅仅是用于将 IP 地址解析为域名，随着 DNSSEC 部署，它们的使用越来越广泛。


    通常使用对特定域具有权威的一个或多个集中式服务器来实施 DNS。当客户端主机请求名称服务器的信息时，它通常连接到端口 53。然后，名称服务器尝试解析请求的名称。如果名称服务器已配置为递归名称服务器并且没有权威答案，或者尚未从之前的查询中缓存答案，它将查询其他名称服务器（称为 root 名称服务器），以确定哪些名称服务器对于该名称具有权威，然后查询它们以获取请求的名称。配置为完全权威的名称服务器（禁用递归）不会代表客户端进行查找。

* 名称服务器区域

    在 DNS 服务器中，所有信息都存储在称为**资源记录** (`RR`) 的基本数据元素中。资源记录在 [RFC 1034](http://www.rfc-editor.org/rfc/rfc1034.txt) 中定义。域名组织为**树结构**。层次结构的每个级别都以句点(`.`)分隔。例如：由 `.` 表示的根域是 DNS 树的**根域**，其级别为**零**。**顶级域**(`TLD`) 如 `com` 是根域(`.`)的**子级**，它是层次结构的第一层。域名 `example.com` 处于层次结构的第二个级别。

    * 示例：`RR` 与 `RRSet`：

        ```sh
        example.com.      86400    IN         A           192.0.2.1
        ```

        其中:

        * `example.com` 该记录的“所有者”
        * `86400` 该记录生存时间（TTL）
        * `IN` 该记录的类：**Internet 系统**
        * `A` 该记录的类别：**主机地址**
        * `192.0.2.1` 该记录指向的主机地址

        具有相同类型、所有者和类的资源记录(`RR`)称为资源记录集(`RRSet`)
    
    * 区域

        `区域` 通过权威名称服务器上的区域文件定义，该文件包含区域内所有RR。

        区域文件存储在主名称服务器上，当发生文件修改，从名称服务器要从主名称服务器上同步。

        主名称服务器和从名称服务器对该区域具有权威，并且对客户端而言看起来相同。根据配置，任何名称服务器可以同时充当多个区域的主或次要服务器。


* 名称服务器配置类型

    * 权威（authoritative）：权威名称服务器应答仅属于其区域一部分的资源记录。此类别包括主要（主）和次要（从属）名称服务器。
    * 递归（recursive）：递归名称服务器提供解析服务，但它们对任何区域都不是权威的。所有解析的应答会在一段固定时间内（TTL）缓存在内存中，TTL由检索的资源记录指定。

    > 虽然名称服务器可以同时具有权威和递归性，但建议不要组合配置类型

* BIND - Berkeley Internet Name Domain

    BIND consists of a set of DNS-related programs. It contains a name server called `named`, an administration utility called `rndc`, and a debugging tool called `dig`.


## BIND

* 空区域

    BIND 配置了许多“空区域”，以防止递归服务器向无法处理它们的 Internet 服务器发送不必要的查询(从而为查询它们的客户端创建延迟和 `SERVFAIL` 响应)。这些空区域确保返回即时和权威的 `NXDOMAIN` 响应。配置选项 `empty-zones-enable` 控制是否创建空区域，而 `disable-empty-zone` 可禁用将使用的默认前缀列表中的单个或多个空区域


* 配置服务

    * named 服务的配置文件

        | Path              | Description              |
        | ----------------- | ------------------------ |
        | `/etc/named.conf` | 主配置文件               |
        | `/etc/named/`     | 主配置文件包含的辅助目录 |

        配置文件有一组 `{}`扩起，典型的如下：

        ```conf
        statement-1 ["statement-1-name"] [statement-1-class] {
          option-1;
          option-2;
          ...
        };
        statement-2 ["statement-2-name"] [statement-2-class] {
          option-1;
          option-2;
          ...
        };
        ...
        ```


> [https://access.redhat.com/solutions/40683#simple_dns](https://access.redhat.com/solutions/40683#simple_dns)
 
* Install the DNS server packages

    ```bash
    # On Red Hat Enterprise Linux 5
    yum install bind bind-chroot caching-nameserver

    # On Red Hat Enterprise Linux 6/7/8
    yum install bind bind-chroot
    ```

* Edit the configure file

    Navigate to the configure directory:

    ```bash
    # For RHEL 5, the configuration files have been placed there.
    ~] cd /var/named/chroot/etc/
    ~] ls
    localtime  named.caching-nameserver.conf  named.rfc1912.zones  rndc.key
    
    # For RHEL 6, copy the sample files to the specific directory.
    ~] cd /var/named/chroot/etc/
    ~] cp /usr/share/doc/bind-{version}/sample/etc/* .

    # For RHEL 7/8, If you want to use sample files, you can copy the sample files to /etc directory.
    # Don't need to copy the sample files to /var/named/chroot/etc/. when using chroot version because it is mounted automatically(mount --bind) with /etc/
    ~] cd /etc/   
    ~] cp /usr/share/doc/bind-{version}/sample/etc/* .  # <-----RHEL7
    ~] cp /usr/share/doc/bind/sample/etc/* .            # <-----RHEL8
    ```
