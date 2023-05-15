# IP, ip

## ipaddr

```sh
# 添加
ip addr add 192.168.161.11/24 dev ens33
# 删除
ip addr del 192.168.161.11/24 dev ens33
```

## netns, veth

```sh
# 查看网络命名空间
ip netns ls 
# 添加
ip netns add qwer
# 删除
ip netns del qwer
# 在指定命名空间中执行命令
ip netns exec qwer ip link
ip netns exec qwer bash

# 添加一对veth
ip link add veth0 type veth peer veth1
# 将veth1迁移到指定网络命名空间
ip link set veth1 netns qwer
# 将veth1从指定网络命名空间删除
ip netns exec qwer ip link delete veth1

# 为指定网络命名空间中的veth设置IP，并启动
ip netns exec qwer ip addr add 192.168.50.2/24 dev veth1
ip netns exec qwer ip link set veth1 up 
ip netns exec qwer ip link set lo up 

# 为主机上的veth设置IP
ip addr add 192.168.50.3/24 dev veth0
ip link set veth0 up

# ping测试
ping -c 4 192.168.50.2

# 添加路由，使得网络命名空间中的veth1能访问其他网络（通过veth0）
ip netns exec qwer ip route add default via 192.168.50.3
```