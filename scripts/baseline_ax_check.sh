#!/bin/bash

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


#added xukai 20191212
get_os() {
    if [ ! -f '/etc/redhat-release' ]; then
        echo "not redhat or centos, please check"
        exit
    fi
}


get_os_version() {
    
    version=0

    if [ -f '/etc/redhat-release' ]; then
        version=$(cat /etc/redhat-release | sed -r -e 's/^.+ ([0-9]+)\..+$/\1/g')
    fi
}


# run it with root
if [ $(id -u) -ne 0 ]; then
    echo_failure "run it with root only"
    exit 1
fi

# close std output and error
# exec 1>/dev/null
# exec 2>/dev/null


# 4.1    物理安全设置
# 禁止使用usb存储设备
disable_usb() {
    cfgfile='/etc/modprobe.d/usb-storage.conf'

    if [ -f $cfgfile ]; then
        if [ $(grep -c '^install usb-storage /bin/true' $cfgfile) -ge 1 ]; then
            echo_ok "disable usb"
        fi
    else
        echo "install usb-storage /bin/true" >> $cfgfile
    fi
}


# 禁止Control+Alt+Delete直接重启服务器
disable_control_alt_delete() {

    get_os_version
    
    # for Linux 7.x
    if [ $version -eq 7 ]; then
        [ -f "/usr/lib/systemd/system/ctrl-alt-del.target" ] && \rm /usr/lib/systemd/system/ctrl-alt-del.target
    else
        cfgfile='/etc/init/control-alt-delete.conf'
        [ -f $cfgfile ] && sed -i 's/^start on control-alt-delete/#start on control-alt-delete/g' $cfgfile    
    fi
}


# 4.2    口令策略设置
# 口令复杂度
pwd_strategy() {

    get_os_version

    if [ $version -eq 7 ]; then
        # /etc/security/pwquality.conf
        cfgfile='/etc/pam.d/system-auth'
        authconfig --update --passminlen=12 --passminclass=3 --enablereqlower --enablerequpper --enablereqdigit --enablereqother
        sed -i 's/password\s\+requisite\s\+pam_pwquality.so/& enforce_for_root/g' $cfgfile
    else
        cfgfile='/etc/pam.d/system-auth-ac'
        # make copy first
        \cp $cfgfile ${cfgfile}.bak
        sed -i "s/password    requisite     pam_cracklib.so.*/password    required      pam_cracklib.so try_first_pass retry=6 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1 enforce_for_root/g" $cfgfile
    fi
}


# 口令有效期
pwd_life_time() {

    chage -d 0 -m 0 -M 90 -W 14 root
    
    # setup the pwd life time stratege for all users
    cp /etc/login.defs /etc/login.defs.bak$(date +%Y%m%d)
    sed -i '/^PASS_MAX_DAYS/s/99999/90/g' /etc/login.defs
    sed -i '/^PASS_MIN_DAYS/s/0/1/g' /etc/login.defs
    sed -i '/^PASS_MIN_LEN/s/5/12/g' /etc/login.defs
    
}


# 4.3    禁用不必要的系统账户
disable_users() {

    # games, ftp
    for user in $(echo -e "adm\nlp\nsync\nshutdown\nhalt\nnews\nuucp\noperator\ngopher")
    do
        # userdel $user
        id $user >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            chsh -s /sbin/nologin $user >/dev/null 2>&1
            echo_ok "Changed shell to /sbin/nologin for $user"
        fi
    done

}


# 4.4    UID 0用户设置
check_root_user() {

    flag=0

    for user in $(awk -F: '($3 == 0) { print $1 }' /etc/passwd)
    do
        if [ "$user" != "root" ]; then
            echo_failure "user $user can't has UID=0"
            flag=1
        fi
    done

    if [  $flag -eq 0 ]; then
        echo_ok "Only root has uid=0"
    fi
}


# 4.5    系统登录安全设置
# 1、避免记录不存在用户的登录信息，避免用户误输入导致密码泄露
# 2、记录用户上次登录时间，用户登录时给予提示
setup_login_defs() {

    cfgfile='/etc/login.defs'
    
    if [ $(grep -c '^LOG_UNKFAIL_ENAB        no' $cfgfile) -eq 0 ]; then
        echo "LOG_UNKFAIL_ENAB        no" >> $cfgfile
    fi

    if [ $(grep -c '^LASTLOG_ENAB           yes' $cfgfile) -eq 0 ]; then
        echo "LASTLOG_ENAB           yes" >> /etc/login.defs
    fi
}


# 4.6    系统全局PROFILE安全设置
# 1、记录用户系统操作命令的同时记录命令的时间戳
# 2、配置命令历史记录条数（包括3.4的配置要求）

# for running from curl | bash 
setup_profile() {
    touch /var/log/cmd_audit.log
    chmod 622 /var/log/cmd_audit.log
    cfgfile='/etc/profile'
    if [ $(grep -c '^export HISTFILESIZE' ${cfgfile}) -eq 0 ]; then
        echo "HISTFILESIZE=4000" >> ${cfgfile}
        echo "HISTSIZE=4000" >> ${cfgfile}
        echo "export HISTORY_FILE=/var/log/cmd_audit.log" >> ${cfgfile}
        echo -E """export PROMPT_COMMAND='{ thisHistID=\`history 1|awk \"{print \\\\\$1}\"\`; lastcommand=\`history 1|awk \"{\\\\\$1=\\\"\\\" ;print}\"\`;user=\`id -un\`; pwd=\`pwd\`;who_info=(\`who -u am i\`); login_date=\${who_info[3]}; login_time=\${who_info[4]}; login_pid=\${who_info[5]}; login_ip=\${who_info[6]}; if [ \${thisHistID}x != \${lastHistID}x ];then echo -E [\$(date \"+%Y/%m/%d %H:%M:%S\")] \${login_ip} [sshpid:\${login_pid}] [\${user}@\${pwd}]   \$lastcommand ; lastHistID=\$thisHistID;fi; } >> /var/log/cmd_audit.log'""" >> ${cfgfile}
    fi
    source ${cfgfile}
}


# 3、连续6次输错密码禁用300秒
setPassword_lock() {
    cp /etc/pam.d/system-auth  /etc/pam.d/system-auth.bak$(date +%Y%m%d)
    deny=$(cat /etc/pam.d/system-auth | grep -E "auth|account" | grep pam_tally2.so)
    if [ -z "$deny" ]; then
        sed -ri "/auth.*pam_env.so/a \auth        required      pam_tally2.so onerr=fail deny=6 unlock_time=300 even_deny_root root_unlock_time=300 " /etc/pam.d/system-auth
        sed -ri "/account.*pam_permit.so/a \account     required      pam_tally2.so" /etc/pam.d/system-auth
    else
        sed -ri "/pam_tally2.so/d" /etc/pam.d/system-auth
        sed -ri "/auth.*pam_env.so/a \auth        required      pam_tally2.so onerr=fail deny=6 unlock_time=300 even_deny_root root_unlock_time=300" /etc/pam.d/system-auth
        sed -ri "/account.*pam_permit.so/a \account     required      pam_tally2.so" /etc/pam.d/system-auth
    fi
}


# 4.7    服务的配置
disable_services() {

    for service in $(echo -e "cups\npostfix\npcscd\nsmarted\nalsasound\niscsitarget\nsmb\nacpid\ntelnet")
    do
        service $service stop
        chkconfig $service off
        # add rhel7.x disable services 
        systemctl stop $service
        systemctl disable $service
    done

}


# 4.8    网络客户端IP建议
#ip_limit() {
#    cfgfile1="/etc/hosts.deny"
#    cfgfile2="/etc/hosts.allow"
#    cp ${cfgfile1} ${cfgfile1}.bak$(date +%Y%m%d)
#    cp ${cfgfile2} ${cfgfile2}.bak$(date +%Y%m%d)
#    grep "ALL: ALL" ${cfgfile1} >/dev/null 2>&1
#    if [ $? -ne 0 ];then
#       echo "ALL: ALL" >> ${cfgfile1}
#    fi
#    grep “ALL: 192.168.88.100” ${cfgfile2} >/dev/null 2>&1     ## 修改为实际允许的 ip 
#    if [ $? -ne 0 ];then
#           echo "ALL: 192.168.88.100" >> ${cfgfile2}
#    fi
#}


# 4.9    CRON授权规定
cron_authorized() {
    if [ -s /etc/at.deny ] ; then
        mv /etc/at.deny /etc/at.deny.bak$(date +%Y%m%d)
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ > /etc/at.deny
        cat /etc/at.deny.bak$(date +%Y%m%d) >> /etc/at.deny
    else
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ > /etc/at.deny
    fi
    if [ -s /etc/cron.deny ] ; then
        mv /etc/cron.deny /etc/cron.deny.bak$(date +%Y%m%d)
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ > /etc/cron.deny
        cat /etc/cron.deny.bak$(date +%Y%m%d) >> /etc/cron.deny
    else    
        cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$ > /etc/cron.deny
    fi
}


# 4.10    删除rhost相关高风险文件，系统默认没有这些文件，暂无需运行
delete_high_risk_files() {
    files=("/root/.rhosts" "/root/.shosts" "/etc/hosts.equiv" "/etc/shosts.equiv")
    for i in ${files[*]}; do
        if [ -f ${i} ];then
            rm ${i}
        fi
    done
}


# 4.11    SELinux设置
set_selinux() {

    #selinux_cfg='/etc/sysconfig/selinux'
    selinux_cfg="/etc/selinux/config"

    # make a copy first
    \cp $selinux_cfg ${selinux_cfg}.bak

    sed -i 's/^SELINUX=.\+/SELINUX=disabled/g' $selinux_cfg

    echo_ok "setup SELinux"
}


# check user without setting password
#check_no_passwd() {
#
#   flag=0
#
#    for user in $(awk -F: '($2 == "") {print $1}' /etc/shadow)
#    do
#        echo_failure "user $user did't setup a password"
#       flag=1
#    done
#
#    if [ $flag -eq 0 ]; then
#        echo_ok "No user has empty passwd" >/dev/null 2>&1
#    fi
#}


# disable system firewall service 
#disable_firewalld() {
#    get_os_version
#    
#    # for Linux 7.x
#    if [ $version -eq 7 ]; then
#        systemctl stop firewalld
#        systemctl disable firewalld
#    else
#        service iptables stop
#        chkconfig iptables off
#    fi
#}


# 3.2 日志配置规范（包括3.5的配置要求）
# logrotate config
logrotate() {
    cp /etc/logrotate.conf /etc/logrotate.conf.bak$(date +%Y%m%d)
    sed -i 's/^weekly/#weekly/g' /etc/logrotate.conf 
    sed -i 's/^rotate/#rotate/g' /etc/logrotate.conf
    sed -i '3a\size 20M' /etc/logrotate.conf 
    sed -i '7a\rotate 10' /etc/logrotate.conf 
}


# 3.3 Linux系统安全审计日志需要发送到日志大数据系统进行集中监控和管理：
# auditd config
auditd_set() {
    cp /etc/audit/auditd.conf /etc/audit/auditd.conf.bak$(date +%Y%m%d)
    sed -i 's/^max_log_file = 8/max_log_file = 50/g' /etc/audit/auditd.conf
    sed -i 's/^num_logs = 5/num_logs = 4/g' /etc/audit/auditd.conf
    sed -i 's/^flush = INCREMENTAL_ASYNC/flush = NONE/g' /etc/audit/auditd.conf
    
    rules="""
-c\n
-w /etc/login.defs -p wa -k login\n
-w /etc/securetty -p wa -k login\n
-w /var/log/faillog -p wa -k login\n
-w /var/log/lastlog -p wa -k login\n
-w /var/log/tallylog -p wa -k login\n
-w /etc/group -p wa -k etcgroup\n
-w /etc/passwd -p wa -k etcpasswd\n
-w /etc/gshadow -k etcgroup\n
-w /etc/shadow -k etcpasswd\n
-w /etc/security/opasswd -k opasswd\n
-w /usr/bin/passwd -p x -k passwd_modification\n
-w /usr/sbin/groupadd -p x -k group_modification\n
-w /usr/sbin/groupmod -p x -k group_modification\n
-w /usr/sbin/addgroup -p x -k group_modification\n
-w /usr/sbin/useradd -p x -k user_modification\n
-w /usr/sbin/usermod -p x -k user_modification\n
-w /usr/sbin/adduser -p x -k user_modification\n
-w /etc/issue -p wa -k etcissue \n
-w /etc/issue.net -p wa -k etcissue\n
-w /usr/bin/whoami -p x -k recon\n
-w /etc/issue -p r -k recon\n
-w /etc/hostname -p r -k recon\n
-w /usr/bin/wget -p x -k susp_activity\n
-w /usr/bin/curl -p x -k susp_activity\n
-w /bin/netcat -p x -k susp_activity\n
-w /usr/bin/ssh -p x -k susp_activity\n
-w /usr/bin/nmap -p x -k susp_activity\n
-a always,exit -F arch=b64 -S mount -S umount2 -F auid!=-1 -k mount\n
-a always,exit -F arch=b32 -S mount -S umount -S umount2 -F auid!=-1 -k mount\n
-a exit,always -F arch=b64 -S open -F dir=/usr/bin -F success=0 -k unauthedfileaccess\n
-a exit,always -F arch=b64 -S open -F dir=/usr/sbin -F success=0 -k unauthedfileaccess\n
-a exit,always -F arch=b64 -S open -F dir=/tmp -F success=0 -k unauthedfileaccess\n
-w /etc/pam.d/ -p wa -k pam\n
-w /etc/security/namespace.conf -p wa -k pam\n
-w /etc/ssh/sshd_config -k sshd\n
-w /tmp -p aw -k tmp\n
-w /root//.bash_history  -p a -k history\n
-w /etc/crontab -p wa -k cron\n
""" 
    cp /etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules.bakbak$(date +"%Y%m%d-%s")
    echo -e ${rules} >> /etc/audit/rules.d/audit.rules
    service auditd restart
}


# set performance mode(Maximum cpu frequency)
# GRUB_CMDLINE_LINUX="… intel_idle.max_cstate=0 processor.max_cstate=1 intel_pstate=disable idle=poll"
intel_pstate_check() {
    cpu_mhz_avrg=$(N=0; while (($N<5));do let N+=1; lscpu | grep 'CPU MHz' | awk -F'[: ]' '{print $NF}'; sleep 1; done | awk '{sum+=$1} END {print sum/5}')
    cpu_mhz_curr=$(lscpu | grep 'CPU MHz' | awk -F'[: ]' '{print $NF}')
    cpu_mhz_max=$(lscpu | grep -aPo '[0-9.]*(?=GHz)' | awk '{print $1 * 1000}')

    abs1=$(awk 'BEGIN{printf "%.3f\n", "'${cpu_mhz_curr}'" - "'${cpu_mhz_avrg}'"}' | tr -d -)
    abs2=$(awk 'BEGIN{printf "%.3f\n", "'${cpu_mhz_curr}'" - "'${cpu_mhz_max}'"}' | tr -d -)

    if [ "${no_turbo}" == '0' ]; then
        result=$(awk 'BEGIN{if("'${abs1}'" <= 10  &&  "'${abs2}'" >= 500) {print "0"}else{print "1"}}')
    else
        result=$(awk 'BEGIN{if("'${abs1}'" <= 10  &&  "'${abs2}'" <= 10) {print "0"}else{print "1"}}')
    fi
}


acpi_cpufreq_check() {
    cpu_mhz_avrg=$(N=0; while (($N<5));do let N+=1; lscpu | grep 'CPU MHz' | awk -F'[: ]' '{print $NF}'; sleep 1; done | awk '{sum+=$1} END {print sum/5}')
    cpu_mhz_curr=$(lscpu | grep 'CPU MHz' | awk -F'[: ]' '{print $NF}')
    cpu_mhz_max=$(lscpu | grep 'CPU max MHz' | awk -F'[: ]' '{print $NF}')

    abs1=$(awk 'BEGIN{printf "%.3f\n", "'${cpu_mhz_curr}'" - "'${cpu_mhz_avrg}'"}' | tr -d -)
    abs2=$(awk 'BEGIN{printf "%.3f\n", "'${cpu_mhz_curr}'" - "'${cpu_mhz_max}'"}' | tr -d -)
    result=$(awk 'BEGIN{if("'${abs1}'" <= 10  &&  "'${abs2}'" <= 10) {print "0"}else{print "1"}}')
}


check_performance(){
    LANG=C
    lscpu | grep -q -i -E "CPU max MHz|CPU min MHz"
    if [ $? -ne 0 ];then
        # echo_ok "task 17: max performance setup"
        result=0
    else
        if [ -d '/sys/devices/system/cpu/intel_pstate' ]; then
            cpu_driver=$(cpupower frequency-info -d 2>/dev/null | grep 'driver' | awk -F': ' '{print $NF}')
            if [ "${cpu_driver}" == 'intel_pstate' ]; then
                no_turbo=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
                intel_pstate_check
            else
                acpi_cpufreq_check
            fi
        else
            acpi_cpufreq_check
        fi

        # if [[ "${result}" == "0" ]]; then
        #     echo_ok "task 17: max performance setup"
        # else
        #     echo_failure "task 17: max performance setup"
        # fi
    fi
}


set_performance(){

    check_performance

    if [[ "${result}" == "0" ]]; then
        echo_ok "task 15: setup max performance mode (already satisfied)"
        return 0
    fi

    \cp /etc/default/grub /etc/default/grub.bak$(date +'%F-%s')
    \cp /boot/vmlinuz-$(uname -r) /boot/vmlinuz-$(uname -r).bak$(date +"%F-%s")
    \cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak$(date +"%F-%s")

    # 1. cmdline
    cmdline_old=$(grep -aPo '(?<=^GRUB_CMDLINE_LINUX=")[^"]*' /etc/default/grub)
    cmdline_new=$(echo ${cmdline_old} | sed -r 's/intel_idle.max_cstate=[0-9]//;s/processor.max_cstate=[0-9]//;s/intel_pstate=[a-z]*//;s/idle=[a-z]*//;s/\s*$//')
    if [ -d '/sys/devices/system/cpu/intel_pstate' ]; then
        cpu_driver=$(cpupower frequency-info -d 2>/dev/null | grep 'driver' | awk -F': ' '{print $NF}')
        if [ "${cpu_driver}" == 'intel_pstate' ]; then
            # Use intel_pstate.
            cmdline_new="${cmdline_new} intel_idle.max_cstate=0 processor.max_cstate=1 idle=poll"
        else
            # Use system cpufreq or other.
            cmdline_new="${cmdline_new} intel_idle.max_cstate=0 processor.max_cstate=1 intel_pstate=disable idle=poll"
        fi
    elif [ -d '/sys/devices/system/cpu/cpufreq' ]; then
        # Use system cpufreq or other.
        cmdline_new="${cmdline_new} intel_idle.max_cstate=0 processor.max_cstate=1 intel_pstate=disable idle=poll"
    else
        # echo "Check driver failed! Occur some errors."
        echo_failure "task 15: setup max performance mode (unknown driver)"
        return 0
    fi

    sed -i "s#\(^GRUB_CMDLINE_LINUX=\).*#\1\"${cmdline_new}\"#" /etc/default/grub
    [ -d /sys/firmware/efi ] && grub2-mkconfig -o /etc/grub2-efi.cfg || grub2-mkconfig -o /boot/grub2/grub.cfg

    # 2. tuned
    systemctl list-units | grep -q tuned.service
    if [ $? -ne 0 ]; then
        yum -y install tuned &>/dev/null
        if [ $? -ne 0]; then
            echo "Cannot install tuned! Please check yum repository."
            echo_failure "task 15: setup max performance mode (occer errors)"
            return 0
        fi
    fi

    systemctl enable tuned.service &>/dev/null
    systemctl restart tuned.service
    tuned-adm profile throughput-performance
    [ $? -eq 0 ] && echo_ok "task 15: setup max performance mode (finished. need reboot)" || echo_failure "task 15: setup max performance mode (occer errors)"
}


# main function
# exec 1<&0
# exec 2<&0

get_os

disable_usb
echo_ok "task 1: disable usb-storage"

disable_control_alt_delete
echo_ok "task 2: disable Control+Alt+Delete reboot server"

pwd_strategy
echo_ok "task 3: setup password strategy"

pwd_life_time
echo_ok "task 4: setup password life time to 90 days"

disable_users
echo_ok "task 5: disable useless system users"

check_root_user
echo_ok "task 6: check uid=0 users"

setup_login_defs
echo_ok "task 7: setup login configurations"

setup_profile
echo_ok "task 8: setup global profile"

disable_services
echo_ok "task 9: stop unnecessary services"

set_selinux
echo_ok "task 10: setup SELinux"

#check_no_passwd
#echo_ok "task 11: check no passwd"

setPassword_lock
echo_ok "task 11: setup Password lock"

cron_authorized
echo_ok "task 12: cron authorized"

#delete_high_risk_files 
#echo_ok "task 14: delete high-risk files"

logrotate
echo_ok "task 13: setup logrotate"

auditd_set
echo_ok "task 14: setup auditd rules"

# task 15
[ $version -eq 7 ] && set_performance || echo_failure "task 15: setup max performance mode (Only for CentOS 7.x)"

echo "end of task"

