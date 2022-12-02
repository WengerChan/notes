# DNS

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