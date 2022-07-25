#!/bin/bash

LANG=C

echo_ok() {
    COL_SIZE=60
    STRING="$1"
    echo -e "${STRING} \\033[${COL_SIZE}G [\\033[1;32m ok \\033[0;39m]"
}


echo_failure() {
    COL_SIZE=60
    STRING="$1"
    echo -e "${STRING} \\033[${COL_SIZE}G [\\033[1;31mFAILED\\033[0;39m]"
}


run_func() {
    [ $# -ne 2 ] && exit 

    $1 && echo_ok "$2" || echo_failure "$2"
}


get_os() {
    if [ ! -f '/etc/kylin-release' ]; then
        echo "It is not Kylin os, exiting..."
        exit
    else
        get_os_info
        if [ "${version}" != 'V10' ] || \
            [ "${release}" != 'SP1' -a "${release}" != 'SP2' ] || \
            [ "${os_arch}" != 'x86_64' -a "${os_arch}" != 'aarch64' ];
        then 
            echo "'Kylin ${version} ${release} ${os_arch}' is not a support version."
            exit
        fi
    fi
}


get_os_info() {
    version=''       # V10
    release=''       # SP1, SP2
    os_arch=''       # x86_64, aarch64
    release_date=''  # 20200711,20210524

    # e.g. /etc/.productinfo 
    # Kylin Linux Advanced Server
    # release V10 (SP2) /(Sword)-x86_64-Build09/20210524

    if [ -f '/etc/.productinfo' ]; then
        version=$(grep -aPo '(?<=release\s)V[0-9]*' /etc/.productinfo)
        release=$(grep -aPo "(?<=${version}\s\()SP[0-9]*" /etc/.productinfo)
        os_arch=$(grep -E -o 'x86_64|aarch64' /etc/.productinfo)
        release_date=$(grep -aPo '[0-9]*(?=$)' /etc/.productinfo)
    fi
}


# 1      概述
# 2      系统安装配置
# 2.2    时区
set_timezone() {
    timedatectl set-timezone Asia/Shanghai
}

# 2.5    配置补丁更新服务
# set_yum() {
#     :
# }

# 3      日志
# 3.2    日志配置规范
#        （1）每个 log 文件超过 20M 时进行轮换，保持最后 10 个 log
set_log_rotate() {
    # /etc/logrotate.conf
    sed -i 's/^weekly/# &\nsize 20M/g' /etc/logrotate.conf
    sed -i 's/^rotate.*/# &\nrotate 10/g' /etc/logrotate.conf

    # /etc/logrotate.d/rsyslog
    sed -ri '/^\s*(rotate|size)/d' /etc/logrotate.d/rsyslog
}
#        （2）rsyslog 记录的日志类型和级别
# set_log() {
#     :
# }

# 3.3    Linux系统安全审计日志需要发送到日志大数据系统进行集中监控和管理：
# 配置audit
set_auditd() {
    \cp /etc/audit/auditd.conf{,.$(date +'%Y%m%d')}
    sed -i 's/^\(max_log_file =\).*/\1 50/g' /etc/audit/auditd.conf
    sed -i 's/^\(num_logs =\).*/\1 4/g' /etc/audit/auditd.conf
    sed -i 's/^\(flush =\).*/\1 NONE/g' /etc/audit/auditd.conf

    ## audit审计日志不写入/var/log/messages
    echo 'if ($programname == "audit") or ($programname == "auditd") then stop' > /etc/rsyslog.d/ignore-systemd-session-slice.conf
    systemctl restart rsyslog

    \cp /etc/audit/rules.d/audit.rules{,.$(date +'%Y%m%d')}
    cat << EOF > /etc/audit/rules.d/audit.rules
-D
-b 8196
-f 1
-c
-w /etc/login.defs -p wa -k login
-w /etc/securetty -p wa -k login
-w /var/log/faillog -p wa -k login
-w /var/log/lastlog -p wa -k login
-w /var/log/tallylog -p wa -k login
-w /etc/group -p wa -k etcgroup
-w /etc/passwd -p wa -k etcpasswd
-w /etc/gshadow -k etcgroup
-w /etc/shadow -k etcpasswd
-w /etc/security/opasswd -k opasswd
-w /usr/bin/passwd -p x -k passwd_modification
-w /usr/sbin/groupadd -p x -k group_modification
-w /usr/sbin/groupmod -p x -k group_modification
-w /usr/sbin/addgroup -p x -k group_modification
-w /usr/sbin/useradd -p x -k user_modification
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/adduser -p x -k user_modification
-w /etc/issue -p wa -k etcissue 
-w /etc/issue.net -p wa -k etcissue
-w /usr/bin/whoami -p x -k recon
-w /etc/issue -p r -k recon
-w /etc/hostname -p r -k recon
-w /usr/bin/wget -p x -k susp_activity
-w /usr/bin/curl -p x -k susp_activity
-w /bin/netcat -p x -k susp_activity
-w /usr/bin/ssh -p x -k susp_activity
-w /usr/bin/nmap -p x -k susp_activity
-a always,exit -F arch=b64 -S mount -S umount2 -F auid!=-1 -k mount
-a always,exit -F arch=b32 -S mount -S umount -S umount2 -F auid!=-1 -k mount
-a exit,always -F arch=b64 -S open -F dir=/usr/bin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/usr/sbin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/tmp -F success=0 -k unauthedfileaccess
-w /etc/pam.d/ -p wa -k pam
-w /etc/security/namespace.conf -p wa -k pam
-w /etc/ssh/sshd_config -k sshd
-w /tmp -p aw -k tmp
-w /root/.bash_history  -p a -k history
-w /etc/crontab -p wa -k cron
EOF

    systemctl stop auditd.service
    systemctl start auditd.service
}

# 3.4    History 配置
# 见 4.6

# 3.5    日志文件滚动配置
# 见 3.2

# 4      系统安全设置
# 4.1    物理安全设置
#        1、禁止使用 usb 存储设备
disable_usb() {
    echo "install usb-storage /bin/true" > /etc/modprobe.d/usb-storage.conf
}
#        2、禁止 Control+Alt+Delete 直接重启服务器
disable_ctrl_alt_del() {
    [ -f "/etc/systemd/system/ctrl-alt-del.target" ] && \rm /etc/systemd/system/ctrl-alt-del.target
    [ -f "/usr/lib/systemd/system/ctrl-alt-del.target" ] && \rm /usr/lib/systemd/system/ctrl-alt-del.target
    return 0
}

# 4.2    口令策略设置
#        1、口令复杂度规定
set_pwd_strategy() {
    \cp /etc/security/pwquality.conf{,.$(date +'%Y%m%d')}
    cat << EOF > /etc/security/pwquality.conf
minlen = 12
dcredit = 1
ucredit = 1
lcredit = 1
ocredit = 1
EOF
    # 实测：不加 enforce_for_root，root 用户也受影响
    grep -q '^password\s*requisite.*pam_pwquality.so.*' /etc/pam.d/system-auth || \
      sed -i '/^password/i \password    requisite     pam_pwquality.so try_first_pass local_users_only' /etc/pam.d/password-auth
    grep -q '^password\s*requisite.*pam_pwquality.so.*' /etc/pam.d/password-auth || \
      sed -i '/^password/i \password    requisite     pam_pwquality.so try_first_pass local_users_only' /etc/pam.d/password-auth
}
#        2、口令有效期规定
set_pwd_lifetime() {
    \cp /etc/login.defs{,.$(date +'%Y%m%d')}
    sed -i 's/\(^PASS_MAX_DAYS\s*\)[0-9]*/\190/g' /etc/login.defs
    sed -i 's/\(^PASS_MIN_DAYS\s*\)[0-9]*/\11/g' /etc/login.defs
    sed -i 's/\(^PASS_MIN_LEN\s*\)[0-9]*/\112/g' /etc/login.defs
    sed -i 's/\(^PASS_WARN_AGE\s*\)[0-9]*/\17/g' /etc/login.defs

    chage -d 0 -m 1 -M 90 -W 7 root
}

# 4.3    禁用不必要的系统账户
disable_users() {
    for user in adm lp sync shutdown halt news uucp operator gopher; do
        id $user >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            chsh -s /sbin/nologin $user >/dev/null 2>&1
        fi
    done
    return 0
}

# 4.4    UID 0用户设置
check_uid0_user() {
    flag=0
    for user in $(awk -F: '($3 == 0) { print $1 }' /etc/passwd); do
        [ "$user" != "root" ] && flag=1
    done
    [ "${flag}" -eq 1 ] && return 1 || return 0
}

# 4.5    系统登录安全设置
#        1、避免记录不存在用户的登录信息，避免用户误输入导致密码泄露
#        2、记录用户上次登录时间，用户登录时给予提示
set_login_defs() {
    sed -ri '/^LOG_UNKFAIL_ENAB|^LASTLOG_ENAB/d' /etc/login.defs
    sed -i '$a \LOG_UNKFAIL_ENAB        no' /etc/login.defs
    sed -i '$a \LASTLOG_ENAB           yes' /etc/login.defs
}
#        3、用户初次登录需要修改密码

# 4.6    系统全局PROFILE安全设置
#        1、为安全审计需要，在记录用户系统操作命令的同时记录命令的时间戳
#        2、配置命令历史记录条数为 5000
set_history() {
    touch /var/log/cmd_audit.log
    chmod 622 /var/log/cmd_audit.log
    chattr +a /var/log/cmd_audit.log
    echo "export HISTORY_FILE=/var/log/cmd_audit.log" >> /etc/profile
    echo -E """export PROMPT_COMMAND='{ \
        thisHistID=\`history 1 | awk \"{print \\\\\$1}\"\`; \
        lastcommand=\`history 1 | awk \"{\\\\\$1=\\\"\\\" ;print}\"\`; \
        user=\`id -un\`; \
        pwd=\`pwd\`; \
        who_info=(\`who -u am i\`); \
        login_date=\${who_info[3]}; \
        login_time=\${who_info[4]}; \
        login_pid=\${who_info[5]}; \
        login_ip=\${who_info[6]}; \
        if [ \${thisHistID}x != \${lastHistID}x ]; then\
         echo -E [\$(date \"+%Y/%m/%d %H:%M:%S\")] \${login_ip} [sshpid:\${login_pid}] [\${user}@\${pwd}]   \$lastcommand;\
         lastHistID=\$thisHistID; \
        fi; } >> /var/log/cmd_audit.log'""" | \
        sed -r '/^export PROMPT_COMMAND/s/[[:space:]]{8}//g' >> /etc/profile

    sed -i '$a \export HISTSIZE=5000' /etc/profile
    sed -i '$a \export HISTFILESIZE=5000' /etc/profile
    # source /etc/profile
}

#        3、连续 6 次输错密码禁用 300 秒
set_password_lock() {
    sed -ri 's/^(auth.*pam_faillock.so (preauth|authfail|authsucc)).*/\1 audit deny=6 even_deny_root unlock_time=300 root_unlock_time=300/' /etc/pam.d/system-auth
    sed -ri 's/^(auth.*pam_faillock.so (preauth|authfail|authsucc)).*/\1 audit deny=6 even_deny_root unlock_time=300 root_unlock_time=300/' /etc/pam.d/password-auth
}
#        4、用户默认的 umask 值为 022，不应修改
# set_umask() {
#     :
# }

# 4.7    服务的配置
disable_services() {
    for service in cups postfix pcscd smartd alsasound iscsitarget smb acpid telnet
    do
        systemctl --now disable ${service} &>/dev/null
    done
    return 0
}

# 4.8    网络客户端IP建议
# ip_limit() {
#     :
# }

# 4.9    CRON授权规定
set_cron() {
    if [ -s /etc/at.deny ] ; then
        \cp /etc/at.deny{,.$(date +'%Y%m%d')}
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ >> /etc/at.deny
    else
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ > /etc/at.deny
    fi

    if [ -s /etc/cron.deny ] ; then
        \cp /etc/cron.deny{,.$(date +'%Y%m%d')}
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ >> /etc/cron.deny
    else    
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ > /etc/cron.deny
    fi
    
    return 0
}

# 4.10    删除rhost相关高风险文件，系统默认没有这些文件，暂无需运行
delete_high_risk_files() {
    files=("/root/.rhosts" "/root/.shosts" "/etc/hosts.equiv" "/etc/shosts.equiv")
    for i in ${files[*]}; do
        if [ -f ${i} ];then
            rm -f ${i}
        fi
    done
    return 0
}

# 4.11    SELinux设置
set_selinux() {
    setenforce 0 &>/dev/null
    sed -i 's/^SELINUX=.\+/SELINUX=disabled/g' /etc/selinux/config
}

# 4.12    防火墙的配置
set_firewall() {
    systemctl --quiet --now disable firewalld.service
}

# 额外配置
# Performance mode
set_performance() {
    # :
    systemctl --quiet --now enable tuned.service && 
    return 0 || return 1
}

# sshd_config: 注释掉不支持的配置项, 消除日志中的报错提示
set_sshd() {
    sed -i 's/^SyslogFacility.*/SyslogFacility AUTHPRIV/g' /etc/ssh/sshd_config
    sed -i 's/^RSAAuthentication.*/# &/g' /etc/ssh/sshd_config
    sed -i 's/^RhostsRSAAuthentication.*/# &/g' /etc/ssh/sshd_config
    systemctl restart sshd
}


main() {
    if [ $(id -u) -ne 0 ]; then
        echo_failure "run it with root only"
        exit 1
    fi

    get_os
    run_func set_timezone 'Task: Set timezone'
    run_func set_log_rotate 'Task: Set log rotate'
    run_func set_auditd 'Task: Set auditd'
    run_func disable_usb 'Task: Disable USB storage'
    run_func disable_ctrl_alt_del 'Task: Disable "Ctrl-Alt-Del" reboot server'
    run_func set_pwd_strategy 'Task: Set password strategy'
    run_func set_pwd_lifetime 'Task: Set password life time'
    run_func disable_users 'Task: Disable useless system user'
    run_func check_uid0_user 'Task: Check uid=0 users'
    run_func set_login_defs 'Task: Setup login configurations'
    run_func set_history 'Task: Set command history'
    run_func set_password_lock 'Task: Set password lock policy'
    run_func disable_services 'Task: Disable useless services'
    run_func set_cron 'Task: Set cron authorized'
    run_func delete_high_risk_files 'Task: Delete high risk files'
    run_func set_selinux 'Task: Set selinux state'
    run_func set_firewall 'Task: Set firewall state'
    run_func set_performance 'Task: Set performance mode'
    run_func set_sshd 'Task: Configurate sshd'
}


# Scripts Entry
main