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
    timezone=$(timedatectl show --property=Timezone --value)
    [ "${timezone}" == "Asia/Shanghai" ] && return 0 || return 1
}

# 2.5    配置补丁更新服务
# set_yum() {
#     :
# }

# 3      日志
# 3.2    日志配置规范
#        （1）每个 log 文件超过 20M 时进行轮换，保持最后 10 个 log
set_log_rotate() {
    grep -q "^size 20M" /etc/logrotate.conf && \
      grep -q "^rotate 10" /etc/logrotate.conf || \
      return 1
    
    grep -q -E '^\s*(rotate|size)' /etc/logrotate.d/rsyslog && \
      return 1
    
    return 0
}
#        （2）rsyslog 记录的日志类型和级别
# set_log() {
#     :
# }

# 3.3    Linux系统安全审计日志需要发送到日志大数据系统进行集中监控和管理：
# 配置audit
set_auditd() {
    grep -q '^max_log_file = 50' /etc/audit/auditd.conf && \
      grep -q '^num_logs = 4' /etc/audit/auditd.conf && \
      grep -q '^flush = NONE' /etc/audit/auditd.conf || \
      return 1

    [ -f '/etc/rsyslog.d/ignore-systemd-session-slice.conf' ] || return 1

    [ "$(wc -l < /etc/audit/rules.d/audit.rules)" -ge 38 ] || return 1

    return 0
}

# 3.4    History 配置
# 见 4.6

# 3.5    日志文件滚动配置
# 见 3.2

# 4      系统安全设置
# 4.1    物理安全设置
#        1、禁止使用 usb 存储设备
disable_usb() {
    [ -f '/etc/modprobe.d/usb-storage.conf' ] && \
      grep -q 'install usb-storage /bin/true' /etc/modprobe.d/usb-storage.conf && \
      return 0 || return 1
}
#        2、禁止 Control+Alt+Delete 直接重启服务器
disable_ctrl_alt_del() {
    [ ! -f "/etc/systemd/system/ctrl-alt-del.target" ] && \
      [ ! -f "/usr/lib/systemd/system/ctrl-alt-del.target" ] && \
      return 0 || return 1
}

# 4.2    口令策略设置
#        1、口令复杂度规定
set_pwd_strategy() {
    while read key value
    do 
        case ${key} in
            'minlen') [ "${value}" != 12 ] && return 1 ;;
            'dcredit') [ "${value}" != 1 ] && return 1 ;;
            'ucredit') [ "${value}" != 1 ] && return 1 ;;
            'lcredit') [ "${value}" != 1 ] && return 1 ;;
            'ocredit') [ "${value}" != 1 ] && return 1 ;;
        esac
    done <<< $(grep -E '^(minlen|[dluo]credit)' /etc/security/pwquality.conf | awk '{print $1,$3}')

    grep -q '^password\s*requisite.*pam_pwquality.so.*' /etc/pam.d/system-auth || return 1
    grep -q '^password\s*requisite.*pam_pwquality.so.*' /etc/pam.d/password-auth || return 1

    return 0
}
#        2、口令有效期规定
set_pwd_lifetime() {
    while read key value
    do
        case ${key} in
            'PASS_MAX_DAYS') [ "${value}" != 90 ] && return 1 ;;
            'PASS_MIN_DAYS') [ "${value}" != 1  ] && return 1 ;;
            'PASS_MIN_LEN' ) [ "${value}" != 12 ] && return 1 ;;
            'PASS_WARN_AGE') [ "${value}" != 7  ] && return 1 ;;
        esac
    done <<< $(grep -E '^PASS_(MAX_DAYS|MIN_DAYS|MIN_LEN)' /etc/login.defs | awk '{print $1,$2}')

    root_pw_lifetime=$(awk -F: '($1 == "root") { print $(NF-5),$(NF-4),$(NF-3) }' /etc/shadow)
    [ "${root_pw_lifetime}" == "1 90 7" ] || return 1

    return 0
}

# 4.3    禁用不必要的系统账户
disable_users() {
    grep -E '^(adm|lp|sync|shutdown|halt|news|uucp|operator|gopher)' /etc/passwd | grep -q bash && \
      return 1 || return 0
}

# 4.4    UID 0用户设置
check_uid0_user() {
    awk -F: '($3 == 0)' /etc/passwd  | grep -q -v '^root' && \
      return 1 || return 0
}

# 4.5    系统登录安全设置
#        1、避免记录不存在用户的登录信息，避免用户误输入导致密码泄露
#        2、记录用户上次登录时间，用户登录时给予提示
set_login_defs() {
    grep -q '^LOG_UNKFAIL_ENAB\s*no' /etc/login.defs || return 1
    grep -q '^LASTLOG_ENAB\s*yes' /etc/login.defs || return 1
    
    return 0
}
#        3、用户初次登录需要修改密码

# 4.6    系统全局PROFILE安全设置
#        1、为安全审计需要，在记录用户系统操作命令的同时记录命令的时间戳
#        2、配置命令历史记录条数为 5000
set_history() {
    [ -f '/var/log/cmd_audit.log' ] && \
      [ "$(stat -c %a /var/log/cmd_audit.log)" == "622" ] || return 1

    grep -q '^export HISTORY_FILE=/var/log/cmd_audit.log' /etc/profile && \
      grep -q '^export PROMPT_COMMAND' /etc/profile || return 1

    grep -q '^export HISTSIZE=5000' /etc/profile && \
      grep -q '^export HISTFILESIZE=5000' /etc/profile || return 1

    return 0
}

#        3、连续 6 次输错密码禁用 300 秒
set_password_lock() {
    grep -q -E \
      '^auth.*pam_faillock.so (preauth|authfail|authsucc) audit deny=6 even_deny_root unlock_time=300 root_unlock_time=300' \
      /etc/pam.d/system-auth || return 1
    grep -q -E \
      '^auth.*pam_faillock.so (preauth|authfail|authsucc) audit deny=6 even_deny_root unlock_time=300 root_unlock_time=300' \
      /etc/pam.d/password-auth  || return 1

    return 0
}
#        4、用户默认的 umask 值为 022，不应修改
# set_umask() {
#     :
# }

# 4.7    服务的配置
disable_services() {
    for service in cups postfix pcscd smartd alsasound iscsitarget smb acpid telnet
    do
        systemctl --quiet is-enabled ${service} &>/dev/null && return 1
    done
    return 0
}

# 4.8    网络客户端IP建议
# ip_limit() {
#     :
# }

# 4.9    CRON授权规定
set_cron() {
    [ -f '/etc/cron.deny' ] && [ -f '/etc/at.deny' ] || return 1

    users=$(cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$)
    for user in ${users}; do
        grep -q ${user} /etc/cron.deny || return 1
        grep -q ${user} /etc/at.deny || return 1
    done  
    
    return 0
}

# 4.10    删除rhost相关高风险文件，系统默认没有这些文件，暂无需运行
delete_high_risk_files() {
    files=("/root/.rhosts" "/root/.shosts" "/etc/hosts.equiv" "/etc/shosts.equiv")
    for file in ${files[*]}; do
        [ -f "${file}" ] && return 1 
    done

    return 0
}

# 4.11    SELinux设置
set_selinux() {
    grep -q '^SELINUX=disabled' /etc/selinux/config && \
      return 0 || return 1
}

# 4.12    防火墙的配置
set_firewall() {
    systemctl --quiet is-enabled firewalld.service && \
      return 1 || return 0
}

# 额外配置
# Performance mode
set_performance() {
    # :
    systemctl --quiet is-enabled tuned.service && 
      return 0 || return 1
}

# sshd_config: 注释掉不支持的配置项, 消除日志中的报错提示
set_sshd() {
    grep -q '^SyslogFacility AUTHPRIV' /etc/ssh/sshd_config || return 1
    grep -q -E '^(RSAAuthentication|RhostsRSAAuthentication)' /etc/ssh/sshd_config && return 1
    
    return 0
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