#! /bin/bash
# 
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#        NAME: zsjj_security_baseline.sh
#     VERSION: v1.0
#        DATE: 2021-03-16
# DESCRIPTION: 基线配置，适用于RHEL6/7
# (注：本脚本参照《招商基金-Linux系统安全基线配置项v1.3.xlsx》编写)
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

VERSION=`cat /etc/redhat-release|grep -aPo '(?<=release\s)\d'`

# 3. UID为0的非root账号数量，默认为0
uid_0_user="$(awk -F: '($3 == 0) { print $1 }' /etc/passwd | grep -v root)"
if [ -z "${uid_0_users}" ]; then
    echo "Not Found Uid=0 User"
else 
    for user in `echo ${uid_0_users}`
    do 
        echo "Deleting User ${user}"
        userdel ${user}
    done
fi


# 5. 查看所有用户和组信息，删除无关用户和组信息

for user in "lp" "adm" "bin" "shutdown" "games" "gopher" "ftp" "news" "uucp" "operator"
do
    userdel ${user} 2>/dev/null
done
for group in "lp" "adm" "bin" "shutdown" "games" "news" "uucp"
do
    groupdel ${group} 2>/dev/null
done

# 6. 空口令账号
no_passwd_user="$(awk -F: '( $2 == "" ) { print $1 }' /etc/shadow)"
echo "no_passwd_user=${no_passwd_user}"

# 7. 口令锁定策略
# 错误输入次数 5次
# 锁定时间  180秒
grep -q '^auth\s*required\s*pam_tally2.so' /etc/pam.d/system-auth-ac &&\
sed -i 's@\(^auth\s*required\s*pam_tally2.so\).*@\1 deny=5 onerr=fail unlock_time=180 even_deny_root root_unlock_time=10@g' /etc/pam.d/system-auth-ac || \
sed -i '/auth\s*required\s*pam_env.so/a auth        required      pam_cracklib.so deny=5 onerr=fail unlock_time=180 even_deny_root root_unlock_time=10' /etc/pam.d/system-auth-ac

# 8. 口令生存期    
# PASS_MAX_DAYS（口令生存周期最大值）90
# PASS_MIN_DAYS（口令生存周期最小值）0
# PASS_MIN_LEN（口令最小长度）12
# PASS_WARN_AGE（口令过期提前告警时间）7
sed -i 's@\(^PASS_MAX_DAYS\).*@\1\t90@g' /etc/login.defs
sed -i 's@\(^PASS_MIN_DAYS\).*@\1\t0@g'  /etc/login.defs 
sed -i 's@\(^PASS_MIN_LEN\).*@\1\t12@g'  /etc/login.defs
sed -i 's@\(^PASS_WARN_AGE\).*@\1\t7@g'  /etc/login.defs

# 9. 口令复杂度策略    
# 口令长度 大于等于 12
# 口令中包含的数字个数 大于等于 1
# 口令中包含的小写字母个数 大于等于 1
# 口令中包含的大写字母个数 大于等于 1
# 口令中包含的特殊字符个数 大于等于 1

case ${VERSION} in
    7)
    grep -q "^password\s*requisite.*pam_pwquality.so" /etc/pam.d/system-auth-ac \
        && sed -i 's@\(^password\s*requisite.*pam_pwquality.so\).*@\1 try_first_pass retry=3 dcredit=-1 lcredit=-1 ucredit=-1 ocredit=-1 minlen=12@g' /etc/pam.d/system-auth-ac \
        || sed -i '/password\s*requisite/i password    requisite     pam_pwquality.so try_first_pass retry=3 dcredit=-1 lcredit=-1 ucredit=-1 ocredit=-1 minlen=12' /etc/pam.d/system-auth-ac
    ;;
    6)
    grep -q "^password\s*requisite.*pam_cracklib.so" /etc/pam.d/system-auth-ac \
        && sed -i 's@\(^password\s*requisite.*pam_cracklib.so\).*@\1 try_first_pass retry=3 dcredit=-1 lcredit=-1 ucredit=-1 ocredit=-1 minlen=12@g' /etc/pam.d/system-auth-ac \
        || sed -i '/password\s*requisite/i password    requisite     pam_cracklib.so try_first_pass retry=3 dcredit=-1 lcredit=-1 ucredit=-1 ocredit=-1 minlen=12' /etc/pam.d/system-auth-ac
    ;;
esac

# 10. 口令历史记录
# 保留10次历史密码
touch /etc/security/opasswd
chown root:root /etc/security/opasswd
chmod 600 /etc/security/opasswd

grep '^password\s*sufficient.*pam_unix.so' /etc/pam.d/system-auth-ac | grep -q 'remember' \
    && sed -i 's@\(^password\s*sufficient.*pam_unix.so.*remember\).*$@\1=10@' /etc/pam.d/system-auth-ac \
    || sed -i 's@\(^password\s*sufficient.*pam_unix.so.*\)$@\1 remember=10@' /etc/pam.d/system-auth-ac


# 11. 使用PAM认证模块禁止wheel组之外的用户su为root
# 禁止wheel组之外的用户su为root
grep -qE '^auth\s*required.*pam_wheel.so.*(use_uid|group=wheel)' /etc/pam.d/su \
    || sed -i '/pam_rootok.so/a auth            required        pam_wheel.so use_uid' /etc/pam.d/su

# 12. 使用SSH V2协议进行远程
grep -q "^Protocol" /etc/ssh/sshd_config \
  && sed -i 's@\(^Protocol\).*@\1 2@g' /etc/ssh/sshd_config \
  || sed -i '$a \Protocol 2' /etc/ssh/sshd_config

# 13. 用户IP地址限制
# 限制只有5网段可以ssh到服务器，如果特殊需求评审后处理

grep -q '^sshd:192.168.5.0/24' /etc/hosts.allow \
    || sed -i '$a \sshd:192.168.5.0/24' /etc/hosts.allow

grep -q '^sshd:ALL' /etc/hosts.deny \
    || sed -i '$a \sshd:ALL' /etc/hosts.deny

# 14. 重要信息资源设置敏感标识	
#     1. 将/etc/issue文件改为（删除默认信息）
#     =======================================
#     cmfchina
#     =======================================
#     2. 将/etc/issue.net文件改为（删除默认信息）
#     =======================================
#     cmfchina
#     =======================================
#     3. 将/etc/motd文件改为（删除默认信息）
#     =======================================
#     cmfchina
#     =======================================

cat << EOF > /etc/issue
=======================================
cmfchina
=======================================
EOF

cat << EOF > /etc/issue.net
=======================================
cmfchina
=======================================
EOF

cat << EOF > /etc/motd
=======================================
cmfchina
=======================================
EOF

# 16. 配置NTP
# 内网NTP：
# 172.18.3.105
# 172.18.3.106
# 172.18.3.107
# 外网NTP：
# 192.168.6.136
# 192.168.6.169 
# 192.168.6.171

case ${VERSION} in
    6)
    sed -i 's/^server.*/#&/g' /etc/ntp.conf
    cat << EOF >> /etc/ntp.conf
server 172.18.3.105
server 172.18.3.106
server 172.18.3.107
EOF
    ;;
    7)
    sed -i 's/^server.*/#&/g' /etc/chrony.conf
    cat << EOF >> /etc/chrony.conf
server 172.18.3.105 iburst
server 172.18.3.106 iburst
server 172.18.3.107 iburst
EOF
    ;;

esac


# 18. 文件与目录缺省权限控制
# /etc/profile文件末尾存在umask 022，则合规，否则为不合规
grep -q "^umask" /etc/profile \
    && sed -i 's/^umask\s*[0-9]*/umask 027/' /etc/profile \
    || sed -i '$a \umask 027' /etc/profile

# 19. 账号文件权限设置
chmod 644 /etc/passwd
chmod 600 /etc/shadow
chmod 644 /etc/group

# 23. 打开syncookie缓解syn flood攻击
# net.ipv4.tcp_syncookies = 1
grep -q '^net.ipv4.tcp_syncookies' /etc/sysctl.conf \
    && sed -i 's/\(^net.ipv4.tcp_syncookies\).*/\1 = 1/' /etc/sysctl.conf \
    || sed -i '$a \net.ipv4.tcp_syncookies = 1' /etc/sysctl.conf


# 24. TMOUT
grep -q "^TMOUT" /etc/profile \
    && sed -i 's/^TMOUT=[0-9]*/TMOUT=1800/' /etc/profile \
    || sed -i '$a \TMOUT=1800' /etc/profile
grep -q '^export.*TMOUT' /etc/profile \
    && sed -i 's/^export.*TMOUT.*/export TMOUT/' /etc/profile \
    || sed -i '$a \export TMOUT' /etc/profile

# 26. 禁止组合键关机
case ${VERSION} in
    6)
    sed -i 's@^exec.*/sbin/shutdown.*@#&@' /etc/init/control-alt-delete.conf
    ;;
    7)
    rm -f /usr/lib/systemd/system/ctrl-alt-del.target
    ;;
esac

# 27. DNS
# 检查是否设置首先通过DNS解析IP地址，然后通过hosts文件解析。
# 检查设置检测是否 /etc/hosts 文件中的主机是否拥有多个IP地址(比如有多个以太口网卡)。
# 检查是否设置说明要注意对本机未经许可的IP欺骗。
# 外网DNS：192.168.6.68/30
# 内网DNS：172.18.3.49/50

sed -i -e '/^order/d' -e '/^multi/d' -e '/^nospoof/d' /etc/host.conf
cat << EOF >> /etc/host.conf
order hosts,bind
multi on
nospoof on
EOF

sed -i '/^nameserver/d' /etc/resolv.conf
cat << EOF >> /etc/resolv.conf
nameserver 172.18.3.49
EOF

# 28. 禁用selinux
setenforce 0
sed -i 's@\(^SELINUX=\).*@\1disabled@g' /etc/selinux/config

# 29. history命令格式配置
sed -i 's@\(^HISTSIZE\).*@\1=200@g' /etc/profile
sed -i -e '/^export.*HISTTIMEFORMAT/d' -e '/^HISTTIMEFORMAT/d' /etc/profile
echo 'export HISTTIMEFORMAT="`whoami` [%Y-%m-%d %H:%M:%S] "' >> /etc/profile

# 35. yum
wget -P /etc/yum.repos.d http://mirrors.cmfchina.com/rhel/rhel-yum-repos/rhel74.repo
wget -P /etc/yum.repos.d http://mirrors.cmfchina.com/rhel/rhel-yum-repos/rhel7-updates.repo
wget -P /etc/yum.repos.d http://mirrors.cmfchina.com/rhel/rhel-yum-repos/epel.repo 

# 36. 资源限制
# 修改/etc/security/limits.conf文件
# 修改/etc/sysctl.conf文件
# 修改/etc/security/limits.conf文件，在最后增加
# *                hard    core           40
# *                hard    rss            10000
# *                hard    nproc          65535
# *                hard    nofile         65535

sed -i -r -e '/^\*.*hard.*(core|rss|nproc|nofile).*/d' /etc/security/limits.conf

cat << EOF >> /etc/security/limits.conf
*                hard    core           40
*                hard    rss            10000
*                hard    nproc          65535
*                hard    nofile         65535
EOF

#vm.max_map_count = 262144
grep -q '^vm.max_map_count' /etc/sysctl.conf \
    && sed -i 's/\(^vm.max_map_count\).*/\1 = 262144/' /etc/sysctl.conf \
    || sed -i '$a \vm.max_map_count = 262144' /etc/sysctl.conf

# 37. audit

sed -i '/-a always,exit.*/d' /etc/audit/audit.rules
cat << EOF >> /etc/audit/audit.rules
-a always,exit -S execve
EOF

if [ ${VERSION} -ge 7 ]; then
    sed -i '/-a always,exit.*/d' /etc/audit/rules.d/audit.rules
    cat << EOF >> /etc/audit/rules.d/audit.rules
-a always,exit -S execve
EOF
fi
service auditd restart &> /dev/null
source /etc/proifle &> /dev/nul
