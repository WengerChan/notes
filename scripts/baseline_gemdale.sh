#! /bin/bash
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
#     VERSION: 1.31
#        DATE: 2021-05-21
# DESCRIPTION: 基线配置，适用于RHEL6/7
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#

export LC_ALL=C
VERSION=$(grep -aPo '(?<=release\s)\d' /etc/redhat-release)
REGEX_IP='([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-4])(\.)(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-4])(\.)){2}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-4])'
CHECK_IP="$(ip addr 2>/dev/null | grep -Ewo "${REGEX_IP}" | grep -v '127.0.0.1' | head -n 1)"
CHECK_DATE="$(date +'%Y%m%d')"
CHECK_FILE_PATH="/tmp/${CHECK_IP}_${CHECK_DATE}_set.log"

# 定义文件描述符用于写入
exec 3>>"${CHECK_FILE_PATH}"
echo 'ItemStatus,ItemValue,ItemStatusSet' >"${CHECK_FILE_PATH}" # 初始化文件, 写入标题


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# set: functions

# 1. 主机名设置原则
# => NULL

# 2. 默认软件包选择配置
# => NULL


# 3. 默认软件包选择配置 kdump
SetKdump(){
    if [ "${VERSION}" -lt 7 ]; then
        grep crashkernel /etc/grub.cfg >/dev/null 2>&1 && service kdump start >/dev/null 2>&1
        rc="$?"
    else
        grep crashkernel /etc/grub2.cfg >/dev/null 2>&1 && service kdump start >/dev/null 2>&1
        rc="$?"
    fi

    if [ "${rc}" -eq 0 ]; then
        sys_kdump_status_set="0"  # 配置成功
    else
        sys_kdump_status_set="1"  # 配置失败
    fi
}


# 4. 运行级别： 3
SetRunlevel(){
    rc='0'
    if [ "${VERSION}" -lt 7 ]; then
        sed -i 's/^\(id\:\)[0-9]\(\:initdefault\:\)$/\13\2/' /etc/inittab
        rc=$?
    else
        systemctl set-default multi-user.target &>/dev/null
        rc=$?
    fi

    [ "${rc}" -eq 0 ] && sys_runlevel_status_set='0' || sys_runlevel_status_set='1'
}


# 5. 配置补丁更新服务
# => NULL

# 6. 时区选择
# => NULL


# 7. 时间服务配置 10.36.0.200
SetNtpServer(){
    #if [ -f '/etc/ntp.conf' ]; then
    #    ntp_type='ntp';
    #elif [ -f '/etc/chrony.conf' ]; then 
    #    ntp_type='chrony'; 
    #else
    #    ntp_type=''
    #fi

    if [ -f "/etc/${ntp_type}.conf" ]; then
        grep -q "^server" /etc/${ntp_type}.conf 2>/dev/null \
            && sed -i -e 's/^[[:space:]]*server.*/#&/g' -e '/10.36.0.200/d' /etc/${ntp_type}.conf
        sed -i '$a \server 10.36.0.200' /etc/${ntp_type}.conf
        if [ -f /etc/chrony.conf ]; then
          sed -i 's/\(^server 10.36.0.200\).*/\1 iburst/g' /etc/chrony.conf
        fi

        if [ "${VERSION}" -ge 7 ]; then
            systemctl disable ntpd &>/dev/null
            systemctl stop ntpd &>/dev/null
            systemctl enable chronyd &>/dev/null
        fi
        service ${ntp_type}d restart &>/dev/null
        [ $? -eq 0 ]  && sys_ntp_status_set='0' || sys_ntp_status_set='1'
    else
        sys_ntp_status_set='1'
    fi
}


# 8. 用户的umask安全配置 077
SetUmask(){
    grep -q "^umask" /etc/profile \
        && sed -i 's/^umask\s*[0-9]*/umask 077/' /etc/profile \
        || sed -i '$a \umask 077' /etc/profile
    sys_umask_status_set='0'
}


# 9. 清除其它UID=0的账户
# => NULL

# 10. 清除不必要的系统账户
# => NULL


# 11. 用户的主目录安全管理
SetHomeDirPermission(){
    if [ "${VERSION}" -ge 7 ]; then
        for item in $(awk -F: '($3 >= 1000) { print $6 }' /etc/passwd); do
            item_right=$(stat -c %a "${item}" 2>/dev/null)
            if [ "${item_right}" != "755" ] && [ "${item_right}" != "700" ]; then
                chmod 700 "${item}"
            fi
        done
    else
        for item in $(awk -F: '($3 >= 500) { print $6 }' /etc/passwd); do
            item_right=$(stat -c %a "${item}" 2>/dev/null)
            if [ "${item_right}" != "755" ] && [ "${item_right}" != "700" ]; then
                chmod 700 "${item}"
            fi
        done
    fi
    sys_homedir_right_status_set='0'
}


# 12. root用户环境变量的安全性
# => NULL

# 13. 账号文件权限设置
# /etc/passwd 644
# /etc/shadow 600
# /etc/group  644

SetAccoutFilePerm(){
    chmod 644 /etc/passwd /etc/group
    chmod 600 /etc/shadow
    sys_account_file_perm_status_set='0'
}

# 14. 关闭不必要启动项
# => NULL

# 15. 最小化启动服务
# => NULL


# 16. SELinux设置  permissive
SetSelinux(){
    setenforce 0
    grep -q -E '^SELINUX=(permissive|disabled)' /etc/selinux/config \
        || sed -i 's@\(^SELINUX=\).*@\1permissive@g' /etc/selinux/config
    sys_selinux_status_set='0'
}


# 17. 口令生存期
# /etc/login.defs
#         PASS_MAX_DAYS 90  #新建用户的密码最长使用天数不大于90
#         PASS_MIN_DAYS 10  #新建用户的密码最短使用天数为10
#         PASS_MIN_LEN  10  #新建用户的密码长度不小于10
#         PASS_WARN_AGE 7   #新建用户的密码到期提前提醒天数为7
SetLoginDefs(){
    sed -i 's@\(^PASS_MAX_DAYS\).*@\1\t90@g' /etc/login.defs
    sed -i 's@\(^PASS_MIN_DAYS\).*@\1\t10@g' /etc/login.defs
    sed -i 's@\(^PASS_MIN_LEN\).*@\1\t10@g' /etc/login.defs
    sed -i 's@\(^PASS_WARN_AGE\).*@\1\t7@g' /etc/login.defs
    sys_PASS_value_set='0'
}


# 18. root密码要求
# => NULL


# 19. 口令复杂度策略
SetPwConfig(){
    case ${VERSION} in
    7)
        # /etc/pam.d/system-auth-ac
        grep -q "^password\s*requisite.*pam_pwquality.so" /etc/pam.d/system-auth-ac \
            && sed -i 's@\(^password\s*requisite.*pam_pwquality.so\).*@\1 retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1@g' /etc/pam.d/system-auth-ac \
            || sed -i '/password\s*requisite/i password    requisite     pam_pwquality.so retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1' /etc/pam.d/system-auth-ac
        # /etc/pam.d/password-auth-ac
        grep -q "^password\s*requisite.*pam_pwquality.so" /etc/pam.d/password-auth-ac \
            && sed -i 's@\(^password\s*requisite.*pam_pwquality.so\).*@\1 retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1@g' /etc/pam.d/password-auth-ac \
            || sed -i '/password\s*requisite/i password    requisite     pam_pwquality.so retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1' /etc/pam.d/password-auth-ac
        sys_pw_minlen_status_set='0'
        sys_pw_dcredit_status_set='0'
        sys_pw_lcredit_status_set='0'
        sys_pw_ucredit_status_set='0'
        sys_pw_ocredit_status_set='0'
        ;;
    6)
        # /etc/pam.d/system-auth-ac
        grep -q "^password\s*requisite.*pam_cracklib.so" /etc/pam.d/system-auth-ac \
            && sed -i 's@\(^password\s*requisite.*pam_cracklib.so\).*@\1 retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1@g' /etc/pam.d/system-auth-ac \
            || sed -i '/password\s*requisite/i password    requisite     pam_cracklib.so retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1' /etc/pam.d/system-auth-ac
        # /etc/pam.d/password-auth-ac
        grep -q "^password\s*requisite.*pam_cracklib.so" /etc/pam.d/password-auth-ac \
            && sed -i 's@\(^password\s*requisite.*pam_cracklib.so\).*@\1 retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1@g' /etc/pam.d/password-auth-ac \
            || sed -i '/password\s*requisite/i password    requisite     pam_cracklib.so retry=3 minlen=10 lcredit=1 ucredit=1 dcredit=1 ocredit=1' /etc/pam.d/password-auth-ac
        sys_pw_minlen_status_set='0'
        sys_pw_dcredit_status_set='0'
        sys_pw_lcredit_status_set='0'
        sys_pw_ucredit_status_set='0'
        sys_pw_ocredit_status_set='0'
        ;;
    *)
        sys_pw_minlen_status_set='1'
        sys_pw_dcredit_status_set='1'
        sys_pw_lcredit_status_set='1'
        sys_pw_ucredit_status_set='1'
        sys_pw_ocredit_status_set='1'
        ;;
    esac
}


# 20. 口令重复次数限制
# /etc/pam.d/system-auth，
#     password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok remember=6
SetPasswdRemember(){
    if [ -L "/etc/pam.d/system-auth" ]; then
        grep '^password\s*sufficient.*pam_unix.so' /etc/pam.d/system-auth-ac | grep -q 'remember' \
            && sed -i 's@\(^password\s*sufficient.*pam_unix.so.*remember\).*$@\1=6@' /etc/pam.d/system-auth-ac \
            || sed -i 's@\(^password\s*sufficient.*pam_unix.so.*\)$@\1 remember=6@' /etc/pam.d/system-auth-ac
    else
        grep '^password\s*sufficient.*pam_unix.so' /etc/pam.d/system-auth | grep -q 'remember' \
            && sed -i 's@\(^password\s*sufficient.*pam_unix.so.*remember\).*$@\1=6@' /etc/pam.d/system-auth \
            || sed -i 's@\(^password\s*sufficient.*pam_unix.so.*\)$@\1 remember=6@' /etc/pam.d/system-auth
    fi
    sys_pw_remember_status_set='0'
}


# 21. 口令锁定策略
# even_deny_root root_unlock_time=60
SetPamtally2(){
    if [ -L "/etc/pam.d/system-auth" ]; then
        grep -q '^auth\s*required\s*pam_tally2.so' /etc/pam.d/system-auth-ac && sed -i '/pam_tally2.so/d' /etc/pam.d/system-auth-ac
        sed -i '/auth\s*required\s*pam_env.so/a auth        required      pam_tally2.so deny=20 onerr=fail no_magic_root unlock_time=180 even_deny_root root_unlock_time=60' /etc/pam.d/system-auth-ac
    else
        grep -q '^auth\s*required\s*pam_tally2.so' /etc/pam.d/system-auth && sed -i '/pam_tally2.so/d' /etc/pam.d/system-auth
        sed -i '/auth\s*required\s*pam_env.so/a auth        required      pam_tally2.so deny=20 onerr=fail no_magic_root unlock_time=180 even_deny_root root_unlock_time=60' /etc/pam.d/system-auth
    fi

    if [ -L "/etc/pam.d/passsword-auth" ]; then
        grep -q '^auth\s*required\s*pam_tally2.so' /etc/pam.d/password-auth-ac && sed -i '/pam_tally2.so/d' /etc/pam.d/password-auth-ac
        sed -i '/auth\s*required\s*pam_env.so/a auth        required      pam_tally2.so deny=20 onerr=fail no_magic_root unlock_time=180 even_deny_root root_unlock_time=60' /etc/pam.d/password-auth-ac
    else
        grep -q '^auth\s*required\s*pam_tally2.so' /etc/pam.d/password-auth && sed -i '/pam_tally2.so/d' /etc/pam.d/password-auth
        sed -i '/auth\s*required\s*pam_env.so/a auth        required      pam_tally2.so deny=20 onerr=fail no_magic_root unlock_time=180 even_deny_root root_unlock_time=60' /etc/pam.d/password-auth
    fi

    sys_pam_tally_status='0'
}


# 22. 用户连接安全管理 TMOUT 900
SetTmout(){
    grep -q '^TMOUT' /etc/profile \
        && sed -i 's@\(^TMOUT\).*@\1=900@g' /etc/profile \
        || sed -i '$a \TMOUT=900' /etc/profile
    sys_tmout_status_set="0"
}


# 23. SSH只允许用户从指定的IP登录 10.33.2.161-166
SetSshdLimit(){
    #AllowUsers root@10.33.2.16?
    grep -q '^[[:space:]]*AllowUsers\s*root@10.33.2.16' /etc/ssh/sshd_config
    if [ "$?" -eq 0 ]; then
        sed -i '/^[[:space:]]*AllowUsers root@10.33.2.16/d' /etc/ssh/sshd_config
    fi
    sed -i '$a \AllowUsers root@10.33.2.161' /etc/ssh/sshd_config
    sed -i '$a \AllowUsers root@10.33.2.162' /etc/ssh/sshd_config
    sed -i '$a \AllowUsers root@10.33.2.163' /etc/ssh/sshd_config
    sed -i '$a \AllowUsers root@10.33.2.164' /etc/ssh/sshd_config
    sed -i '$a \AllowUsers root@10.33.2.165' /etc/ssh/sshd_config
    sed -i '$a \AllowUsers root@10.33.2.166' /etc/ssh/sshd_config
    sys_ssh_limit_status_set='0'
}


# 24. 禁止telnet服务
SetTelnet(){
    rc='0'
    if [ -f '/etc/xinetd.d/telnet' ]; then
        sed 's/\(disable\s*=\s*\).*/\1yes/' /etc/xinetd.d/telnet
        rc="$?"
    fi
    service xinetd restart &>/dev/null
    [ "${rc}" -eq 0 ] && sys_telnet_status_set='0' || sys_telnet_status_set='1'
}


# 25. 限制root用户TELNET远程登录
SetRootTelnet(){
    sed -i "s/^pts/pts/#pts/g" /etc/securetty
    grep -q 'pts' /etc/securetty
    [ $? -eq 0 ] && sys_root_telnet_status_set='0' || sys_root_telnet_status_set='1'
}


# 26. 使用SSH协议进行远程维护
# => NULL


# 27. 修改SSH的Banner警告信息
# 修改/etc/ssh/sshd_config文件，添加如下行：
#     Banner /etc/ssh_banner
SetSshBanner(){
    grep -Ev '^$|^#' /etc/ssh/sshd_config | grep -q 'Banner' \
        && sed -i 's@\(^[[:space:]]*Banner\s*\).*$@\1/etc/ssh_banner@g' /etc/ssh/sshd_config \
        || sed -i '$a \Banner /etc/ssh_banner' /etc/ssh/sshd_config
    echo 'Authorized only. All activity will be monitored and reported.' >/etc/ssh_banner
    sys_ssh_banner_status_set='0'
}


# 28. 修改TELNET的Banner信息
# => NULL

# 29. 检查.forward文件是否存在
# => NULL

# 30. 检查.netrc文件是否存在
# => NULL

# 31. 检查用户的.rhosts文件是否存在
# => NULL


# 32. 安全日志完备性要求
SetLogAuthpriv(){
    grep -Ev '^#|^$' /etc/rsyslog.conf | grep authpriv | grep -q '/var/log/secure'
    if [ $? -ne 0 ]; then
        sed -i '$a \authpriv.*        /var/log/secure' /etc/rsyslog.conf
    fi
    service rsyslog restart &>/dev/null
    [ $? -eq 0 ] && sys_authpriv_status_set='0' || sys_authpriv_status_set='1'
}


# 33. 限制日志文件访问权限 0400
SetSyslogFilePermission(){
    chmod 0400 /etc/rsyslog.conf
    [ $? -eq 0 ] && sys_rsyslog_perm_status_set='0' || sys_rsyslog_perm_status_set='1'
}


# 34. history命令格式配置
# HISTSIZE=5000
# export HISTTIMEFORMAT="`whoami` [%Y-%m-%d %H:%M:%S] "
SetHistroy(){
    sed -i 's@\(^HISTSIZE\).*@\1=5000@g' /etc/profile
    grep -q "^HISTTIMEFORMAT" /etc/profile \
        && sed -i 's@\(^HISTTIMEFORMAT\).*@\1="`whoami` [%Y-%m-%d %H:%M:%S] "@g' /etc/profile \
        || sed -i '$a \HISTTIMEFORMAT="`whoami` [%Y-%m-%d %H:%M:%S] "' /etc/profile
    sys_histsize_status_set='0'
    sys_histtimeformat_status_set='0'
}


# 35. 记录帐户登录日志
# => # 32

# 36. 配置su命令使用情况记录
# => # 32

# 37. 禁止组合键关机
# 6.x /etc/init/control-alt-delete.conf注释下面这行
#     #exec /sbin/shutdown -r now "Control-Alt-Delete pressed"
# 7.x 删除软链接: /usr/lib/systemd/system/ctrl-alt-del.
SetCtrlAltDel(){
    if [ "${VERSION}" -lt 7 ]; then
        grep -Ev '^$|^#' /etc/init/control-alt-delete.conf 2>/dev/null | grep -q 'Control-Alt-Delete'
        [ $? -eq 0 ] && sed -i 's/^[[:space:]]*exec.*Control-Alt-Delete.*$/#&/g' /etc/init/control-alt-delete.conf
    else
        rm -f '/usr/lib/systemd/system/ctrl-alt-del.target'
    fi
    sys_ctrl_alt_del_status_set='0'
}


# 38. 系统core dump状态
#     1、查看/etc/security/limits.conf文件中是否配置如下内容：
#         * soft  core 0
#         * hard core 0
#     2、查看/etc/profile文件中是否存在如下配置，存在则注释掉：
#         ulimit -S -c 0 > /dev/null 2>&1
SetCoreDump(){
    grep -q "^\*\s*soft\s*core\s*" /etc/security/limits.conf
    if [ $? -ne 0 ]; then
        sed -i '/# End of file/i \*               soft    core            0' /etc/security/limits.conf
    fi
    grep -q "^\*\s*hard\s*core\s*" /etc/security/limits.conf
    if [ $? -ne 0 ]; then
        sed -i '/# End of file/i \*               hard    core            0' /etc/security/limits.conf
    fi
    grep -Ev '^$|^#' /etc/profile | grep -q 'ulimit.*-c'
    if [ $? -ne 0 ]; then
        sed -i '/ulimit.*-c/d' /etc/profile
    fi
    ulimit -S -c 0 > /dev/null 2>&1
    sys_core_dump_status_set='0'
}


# 39. host.conf
#   编辑文件/etc/host.conf，看是否存在如下内容：
#       order hosts，bind
#       multi on
#       nospoof on
SetHostConf(){
    sed -i -e '/order\s/d' -e '/multi\s/d' -e '/nospoof\s/d' /etc/host.conf
    echo -e 'order hosts,bind\nmulti on\nnospoof on' >> /etc/host.conf
    if [ "${VERSION}" -ge 7 ]; then
        sed -i 's/^nospoof.*$/#&/g' /etc/host.conf
    fi
    sys_host_conf_status_set='0'
}


# 40. 文件与目录缺省权限控制
# => # 8

# 41. 重要目录和文件的权限设置
# => NULL


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# check

# 1. 主机名设置原则
## Linux主机名设置原则：
##     1. 主机名允许大小写字母、数字、连字符；不允许以数字和下划线开头，不允许以系统账号命名，不允许连续3次重复的字符命名；
##     2. 采用gem-应用名称+应用角色+节点数字+gemdale.com组合命名主机,如HR系统中的应用系统第一个节点服务器和和HR系统中数据库系统第一个节点服务器，命名如下：
##     gem-hrapp01.gemdale.com
##     gem-hrdb01.gemdale.com
sys_hostname_value="$(hostname)"
sys_hostname_status='1'

echo "${sys_hostname_value}" | grep -q '^gem\-[a-zA-Z0-9]*\.gemdale\.com$'
rc="$?"
[ "${rc}" -eq 0 ] && sys_hostname_status="0" || sys_hostname_status="1"

# 2. 默认软件包选择配置

# 3. 默认软件包选择配置 kdump
sys_kdump_value=""
sys_kdump_status="1"

if [ "${VERSION}" -lt 7 ]; then
    sys_kdump_value=$(service kdump status 2>&1)
    rc="$?"
else
    sys_kdump_value=$(systemctl status kdump 2>&1 | grep -aPo '(?<=Active\: ).*|(.*not be found)')
    rc="$?"
fi

[ ${rc} -eq 0 ] && sys_kdump_status="0" || sys_kdump_status="1"

# 4. 设置系统运行级别
#    3=正常
sys_runlevel_value=''
sys_runlevel_status='0'

# 当前运行级别
sys_runlevel_cur_value=$(runlevel | awk '{print $2}')
if [ -z "${sys_runlevel_cur_value}" ] || [ "${sys_runlevel_cur_value}" != "3" ]; then
    sys_runlevel_status='1'
fi

# 配置的运行级别
sys_runlevel_cfg_value=''
if [ "${VERSION}" -lt 7 ]; then
    sys_runlevel_cfg_value=$(grep -aPo '[0-9](?=:initdefault)' /etc/inittab)
else
    sys_runlevel_cfg_value=$(systemctl get-default)
fi

sys_runlevel_value="${sys_runlevel_cur_value};${sys_runlevel_cfg_value}"
[ -z "${sys_runlevel_value%;}" ] && sys_runlevel_value='NULL'

# 5. 配置补丁更新服务

# 6. 时区选择
## 中国上海，东8区; Asia/Shanghai (CST, +0800)
sys_timezone_value="$(date +'%z')"
sys_timezone_status='1'

[ "${sys_timezone_value}" == "+0800" ] && sys_timezone_status="0" || sys_timezone_status="1"

# 7. 时间服务配置
# 要求服务器具有统一的时间服务器进行同时间同步，内部统一配置时间服务器为10.36.0.200
NTP_SERVER='10.36.0.200'
sys_ntp_value=''
sys_ntp_status='1'
ntp_type="ntp"

if [ "${VERSION}" -ge 7 ]; then
    ntp_type="chrony"
fi

ntp_conf=$(grep -Ev '^$|^[[:space:]]*#' /etc/${ntp_type}.conf 2>/dev/null | grep -aPow '(?<=^server\s)\s*[0-9a-zA-Z.]+' | sed 's/ //g')
if [ -n "${ntp_conf}" ]; then
    if [ "${ntp_conf}" == "${NTP_SERVER}" ]; then sys_ntp_status='0'; fi
    sys_ntp_value="${ntp_type}:$(echo "${ntp_conf}" | sed ':label;N;s/\n/;/g;b label')"
fi

[ -z "${sys_ntp_value%;}" ] && sys_ntp_value='NULL'

# 8. 用户的umask安全配置
sys_umask_value=''
sys_umask_status='1'

for file in "/etc/profile" "/etc/bashrc"; do
    umask_num=$(grep -Ev '^$|^#' ${file} | grep -aPo '(?<=^umask\s)\s*[0-9]+' | sed 's/ //g')
    if [ -z "${umask_num}" ]; then
        continue
    else
        [ "${umask_num}" == "077" ] && sys_umask_status='0'
        sys_umask_value="${file}:${umask_num};${sys_umask_value}"
        umask_num=''
    fi
done
[ -z "${sys_umask_value%;}" ] && sys_umask_value='NULL'

# 9. UID为0的账户
sys_uid0_value="$(awk -F: '($3 == 0) { print $1 }' /etc/passwd | grep -v root | sed ':label;N;s/\n/ /g;b label')"
sys_uid0_status="1"
[ -z "${sys_uid0_value}" ] && sys_uid0_status="0" || sys_uid0_status="1"

# 10. 不必要的系统账户
# 'adm|lp|sync|uucp|shutdown|halt|news|operator|games|gopher|ftp'
sys_unused_user_value=$(awk -F':' '($NF != "/sbin/nologin" && $NF != "/bin/false") {print $1":"$NF}' /etc/passwd | sed ':label;N;s/\n/;/g;b label')
sys_unused_user_status='1'
[ -z "${sys_unused_user_value}" ] && sys_unused_user_status="0" || sys_unused_user_status="1"

# 11. 用户的主目录安全管理
# 限制用户主目录权限为755或700，提高用户主目录安全性
sys_homedir_right_value=''
sys_homedir_right_status='0'

if [ "${VERSION}" -ge 7 ]; then
    for item in $(awk -F: '($3 >= 1000) { print $6 }' /etc/passwd); do
        item_right=$(stat -c %a "${item}" 2>/dev/null)
        [ -z "${item_right}" ] && item_right='NULL'
        sys_homedir_right_value="${item}:${item_right};${sys_homedir_right_value}"
        if [ "${item_right}" != "755" ] && [ "${item_right}" != "700" ] && [ "${item_right}" != "NULL" ]; then
            sys_homedir_right_status='1'
        fi
        item_right=''
    done
else
    for item in $(awk -F: '($3 >= 500) { print $6 }' /etc/passwd); do
        item_right=$(stat -c %a "${item}" 2>/dev/null)
        [ -z "${item_right}" ] && item_right='NULL'
        sys_homedir_right_value="${item}:${item_right};${sys_homedir_right_value}"
        if [ "${item_right}" != "755" ] && [ "${item_right}" != "700" ] && [ "${item_right}" != "NULL" ]; then
            sys_homedir_right_status='1'
        fi
        item_right=''
    done
fi

[ -z "${sys_homedir_right_value//;/}" ] && sys_homedir_right_value='NULL'

# 12. root用户环境变量的安全性
# $PATH环境变量中不存在.或者..的路径则合规，否则不合规。
sys_root_PATH_value=''
sys_root_PATH_status='0'

sys_root_PATH_value=${PATH}
echo "${sys_root_PATH_value}" | grep -q -E '(\.\:)|(\.\.(\:)*)' 
[ $? -eq 0 ] && sys_root_PATH_status='1'

# 13. 账号文件权限设置
sys_account_file_perm_value=''
sys_account_file_perm_status='0'
FILE_LIST='/etc/passwd /etc/group /etc/shadow'

passwd_perm="$(stat -c %a /etc/passwd 2>/dev/null)"
shadow_perm="$(stat -c %a /etc/shadow 2>/dev/null)"
group_perm="$(stat -c %a /etc/group 2>/dev/null)"

[ "${passwd_perm}" != "644" ] && sys_account_file_perm_value="/etc/passwd:${passwd_perm}"
[ "${shadow_perm}" != "600" ] && sys_account_file_perm_value="${sys_account_file_perm_value};/etc/shadow:${shadow_perm}"
[ "${group_perm}" != "644" ] && sys_account_file_perm_value="${sys_account_file_perm_value};/etc/group:${group_perm}"

[ -n "${sys_account_file_perm_value}" ] && sys_account_file_perm_status='1' || sys_account_file_perm_value='NULL'

# 14. 关闭不必要启动项
sys_rc_d_value=''
sys_rc_d_status='0'

sys_rc_d_value=$(ls /etc/rc2.d/* /etc/rc3.d/* /etc/rc4.d/* /etc/rc5.d/* | grep -E "lp|rpc|snmpdx|keyserv|nscd|Volmgt|uucp|dmi|sendmail|autoinstall" | grep "^S*" | sed ':label;N;s/\n/;/g;b label')
if [ -n "${sys_rc_d_value%;}" ]; then 
    sys_rc_d_status='1'
else
    sys_rc_d_value='NULL'
fi

# 15. 最小化启动服务

# 16. SELinux设置
# 建议设置为permissive
sys_selinux_value=''
sys_selinux_status='1'

sys_selinux_value_1=$(getenforce | tr 'A-Z' 'a-z')
sys_selinux_value_2=$(grep -aPo '(?<=SELINUX=)[a-z]*' /etc/selinux/config)

if [ "${sys_selinux_value_1}" == "permissive" ] || [ "${sys_selinux_value_1}" == "disabled" ]; then
    if [ "${sys_selinux_value_2}" == "permissive" ] || [ "${sys_selinux_value_2}" == "disabled" ]; then
        sys_selinux_status='0'
    fi
fi
sys_selinux_value="${sys_selinux_value_1};${sys_selinux_value_2}"

[ -z "${sys_selinux_value%;}" ] && sys_selinux_value='NULL'

# 17. 口令生存期
# /etc/login.defs
#         PASS_MAX_DAYS 90  #新建用户的密码最长使用天数不大于90
#         PASS_MIN_DAYS 10  #新建用户的密码最短使用天数为10
#         PASS_MIN_LEN  10  #新建用户的密码长度不小于10
#         PASS_WARN_AGE 7   #新建用户的密码到期提前提醒天数为7
PASS_VALUE='90;10;10;7'
sys_PASS_value=''
sys_PASS_status='0'

sys_PASS_MAX_DAYS_value=$(grep -Ev '^$|^#' /etc/login.defs | grep 'PASS_MAX_DAY' | tail -n 1 | awk '{print $NF}')
sys_PASS_MIN_DAYS_value=$(grep -Ev '^$|^#' /etc/login.defs | grep 'PASS_MIN_DAYS' | tail -n 1 | awk '{print $NF}')
sys_PASS_MIN_LEN_value=$(grep -Ev '^$|^#' /etc/login.defs | grep 'PASS_MIN_LEN' | tail -n 1 | awk '{print $NF}')
sys_PASS_WARN_AGE_value=$(grep -Ev '^$|^#' /etc/login.defs | grep 'PASS_WARN_AGE' | tail -n 1 | awk '{print $NF}')
sys_PASS_value="${sys_PASS_MAX_DAYS_value};${sys_PASS_MIN_DAYS_value};${sys_PASS_MIN_LEN_value};${sys_PASS_WARN_AGE_value}"

if [ -z "${sys_PASS_value%;}" ]; then
    sys_PASS_value='NULL'
    sys_PASS_status='1'
elif [ "${sys_PASS_value}" != "${PASS_VALUE}" ]; then
    sys_PASS_status='1'
fi

# 18. root密码要求

# 19. 口令复杂度策略
# 口令的最小长度:10
# 口令中包含的数字个数:1
# 口令中包含的小写字母个数:1
# 口令中包含的大写字母个数:1
# 口令中包含的特殊字符个数:1
pw_config_line="$(grep -E '^password\s*requisite.*(pam_pwquality.so|pam_cracklib.so)' /etc/pam.d/system-auth)"
sys_pw_minlen_value="$(echo "${pw_config_line}" | grep -aPo '(?<=minlen=)-?[0-9]+')"
sys_pw_dcredit_value="$(echo "${pw_config_line}" | grep -aPo '(?<=dcredit=)-?[0-9]+')"
sys_pw_lcredit_value="$(echo "${pw_config_line}" | grep -aPo '(?<=lcredit=)-?[0-9]+')"
sys_pw_ucredit_value="$(echo "${pw_config_line}" | grep -aPo '(?<=ucredit=)-?[0-9]+')"
sys_pw_ocredit_value="$(echo "${pw_config_line}" | grep -aPo '(?<=ocredit=)-?[0-9]+')"

[ "${sys_pw_minlen_value//-/}" -eq 10 ] 2>/dev/null && sys_pw_minlen_status="0" || sys_pw_minlen_status="1"
[ "${sys_pw_dcredit_value//-/}" -eq 1 ] 2>/dev/null && sys_pw_dcredit_status="0" || sys_pw_dcredit_status="1"
[ "${sys_pw_lcredit_value//-/}" -eq 1 ] 2>/dev/null && sys_pw_lcredit_status="0" || sys_pw_lcredit_status="1"
[ "${sys_pw_ucredit_value//-/}" -eq 1 ] 2>/dev/null && sys_pw_ucredit_status="0" || sys_pw_ucredit_status="1"
[ "${sys_pw_ocredit_value//-/}" -eq 1 ] 2>/dev/null && sys_pw_ocredit_status="0" || sys_pw_ocredit_status="1"

# 20. 口令重复次数限制
# /etc/pam.d/system-auth，
#     password    sufficient    pam_unix.so md5 shadow nullok try_first_pass use_authtok remember=6
sys_pw_remember_value=''
sys_pw_remember_status='0'

sys_pw_remember_value=$(grep -Ev '^$|^#' /etc/pam.d/system-auth | grep 'password.*pam_unix.so' | grep -aPo '(?<=remember=)[0-9]*')
if [ -z "${sys_pw_remember_value}" ]; then
    sys_pw_remember_value='NULL'
    sys_pw_remember_status='1'
elif [ "${sys_pw_remember_value}" -lt 6 ]; then
    sys_pw_remember_status='1'
fi

# 21. 口令锁定策略
# /etc/pam.d/system-auth
#         pam_tally2.so deny=20 unlock_time=180 root_unlock_time=60
PAMTALLY_VALUE='20;180;60'
sys_pam_tally_value=''
sys_pam_tally_status='0'

sys_pam_tally_deny_value=$(grep -Ev '^$|^#' /etc/pam.d/system-auth | grep 'auth.*pam_tally' | tail -n 1 | grep -aPo '(?<=deny=)[0-9]*')
sys_pam_tally_user_lock_value=$(grep -Ev '^$|^#' /etc/pam.d/system-auth | grep 'auth.*pam_tally' | tail -n 1 | grep -aPo '(?<= unlock_time=)[0-9]*')
sys_pam_tally_root_lock_value=$(grep -Ev '^$|^#' /etc/pam.d/system-auth | grep 'auth.*pam_tally' | tail -n 1 | grep -aPo '(?<=root_unlock_time=)[0-9]*')
sys_pam_tally_value="${sys_pam_tally_deny_value:=NULL};${sys_pam_tally_user_lock_value:=NULL};${sys_pam_tally_root_lock_value:=NULL}"

if [ -z "${sys_pam_tally_value%;}" ]; then
    sys_pam_tally_value='NULL'
    sys_pam_tally_status='1'
else 
    if [ "${sys_pam_tally_value}" != "${PAMTALLY_VALUE}" ]; then
        sys_pam_tally_status='1'
    fi
fi

# 22. 用户连接安全管理: TMOUT检测
sys_tmout_value="$(grep -Ev '^$|^#' /etc/profile | grep -aPo '(?<=TMOUT=)[0-9]+' | tail -n 1)"
sys_tmout_status='1'
[ "${sys_tmout_value}" == '900' ] && sys_tmout_status="0" || sys_tmout_status="1"

# 23. SSH只允许用户从指定的IP登录
# 只允许堡垒机: 10.33.2.161-166
BL_IP='10.33.2.16[1-6]'
sys_ssh_limit_value=''
sys_ssh_limit_status='0'

sys_ssh_limit_value=$(grep '^[[:space:]]*AllowUsers' /etc/ssh/sshd_config 2>/dev/null | grep -E "${BL_IP}" | sed ':label;N;s/\n/;/g;b label')
if [ -z "${sys_ssh_limit_value}" ]; then
    sys_ssh_limit_value='NULL'
    sys_ssh_limit_status='1'
fi

# 24. 禁止telnet服务
#
sys_telnet_value=''
sys_telnet_status='0'

sys_telnet_value=$(netstat -ntlp | grep xinetd | awk '{print $4}')
if [ -n "${sys_telnet_value}" ]; then
    echo "${sys_telnet_value}" | awk -F':' '{print $NF}' | grep -q '^23$'
    [ $? -eq 0 ] && sys_telnet_status='1'
else
    sys_telnet_value='NULL'
fi

# 25. 禁用root用户telnet远程登陆
# sed -i "/^pts/s/pts/#pts/g" /etc/securetty
sys_root_telnet_value=''
sys_root_telnet_status='0'

sys_root_telnet_value=$(grep 'pts' /etc/securetty | sed ':label;N;s/\n/;/g;b label')
if [ -n "${sys_root_telnet_value%;}" ]; then 
    sys_root_telnet_status='1'
else
    sys_root_telnet_value='NULL'
fi

# 26. 使用SSH协议进行远程维护

# 27. 修改SSH的Banner警告信息
# 修改/etc/ssh/sshd_config文件，添加如下行：
#     Banner /etc/ssh_banner
sys_ssh_banner_value=''
sys_ssh_banner_status='0'

sys_ssh_banner_value=$(grep -Ev '^$|^#' /etc/ssh/sshd_config | grep 'Banner' | tail -n 1 | awk '{print $NF}')
if [ -z "${sys_ssh_banner_value}" ] || [ "${sys_ssh_banner_value}" != '/etc/ssh_banner' ]; then
    sys_ssh_banner_value='NULL'
    sys_ssh_banner_status='1'
else 
    if [ ! -s "${sys_ssh_banner_value}" ]; then
        sys_ssh_banner_status='1'
    elif [ "$(cat ${sys_ssh_banner_value})" != "Authorized only. All activity will be monitored and reported." ]; then
        sys_ssh_banner_status='1'
        sys_ssh_banner_value="${sys_ssh_banner_value}:'$(cat ${sys_ssh_banner_value})'"
    fi
fi

# 28. 修改TELNET的Banner信息

# 29-31
USER_DIR=$(grep -Ev '^(root|halt|sync|shutdown)' /etc/passwd | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }')
#sys_netrc_rhosts_value=''
#sys_netrc_rhosts_status='0'
#
#while read user dir; do
#    if [ -d "$dir" ]; then
#        if { [ ! -h "$dir/.rhosts" ] && [ -f "$dir/.rhosts" ]; } || { [ ! -h "$dir/.forward" ] && [ -f "$dir/.forward" ]; }; then
#            sys_netrc_rhosts_value="${user}:${dir};${sys_netrc_rhosts_value}"
#            sys_netrc_rhosts_status='1'
#        fi
#    fi
#done <<<"$(grep -E -v '^(root|halt|sync|shutdown)' /etc/passwd | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }')"
#
#[ -z "${sys_netrc_rhosts_value%;}" ] && sys_netrc_rhosts_value='NULL'
# 29. 检查.forward文件是否存在
sys_forward_file_value=''
sys_forward_file_status='0'

while read user dir; do
    if [ ! -d "$dir" ]; then
        continue
    else
        if [ ! -h "$dir/.forward" ] && [ -f "$dir/.forward" ]; then
            sys_forward_file_value="$dir/.forward;${sys_forward_file_value}"
        fi
    fi
done <<< "${USER_DIR}"

if [ -z "${sys_forward_file_value}" ]; then
    sys_forward_file_value='NULL'
else
    sys_forward_file_status='1'
fi

# 30. 检查.netrc文件是否存在
sys_netrc_file_value=''
sys_netrc_file_status='0'
while read user dir; do
    if [ ! -d "$dir" ]; then
        continue
    else
        if [ ! -h "$dir/.netrc" ] && [ -f "$dir/.netrc" ]; then
            sys_netrc_file_value="$dir/.netrc;${sys_netrc_file_value}"
        fi
    fi
done <<< "${USER_DIR}"

if [ -z "${sys_netrc_file_value}" ]; then
    sys_netrc_file_value='NULL'
else
    sys_netrc_file_status='1'
fi

# 31. 检查用户的.rhosts文件是否存在
sys_rhosts_file_value=''
sys_rhosts_file_status='0'
while read user dir; do
    if [ ! -d "$dir" ]; then
        continue
    else
        if [ ! -h "$dir/.rhosts" ] && [ -f "$dir/.rhosts" ]; then
            sys_rhosts_file_value="$dir/.rhosts;${sys_rhosts_file_value}"
        fi
    fi
done <<< "${USER_DIR}"

if [ -z "${sys_rhosts_file_value}" ]; then
    sys_rhosts_file_value='NULL'
else
    sys_rhosts_file_status='1'
fi

# 32. 安全日志完备性要求
#  authpriv.*    /var/log/secure
sys_authpriv_value=''
sys_authpriv_status='0'

sys_authpriv_value=$(grep -Ev '^#|^$' /etc/rsyslog.conf | grep authpriv | grep '/var/log/secure' | sed ':label;N;s/\n/;/g;b label')
if [ -z "${sys_authpriv_value%;}" ]; then
    sys_authpriv_status='1'
    sys_authpriv_value='NULL'
fi

# 33. 限制日志文件访问权限
#  权限=400
sys_rsyslog_perm_value=''
sys_rsyslog_perm_status='0'

sys_rsyslog_perm_value=$(stat -c %A /etc/rsyslog.conf 2>/dev/null)
if [ -z "${sys_rsyslog_perm_value}" ]; then
    sys_rsyslog_perm_status='1'
    sys_rsyslog_perm_value='NULL'
elif [ "${sys_rsyslog_perm_value}" != "-r--------" ];then
    sys_rsyslog_perm_status='1'
else
    sys_rsyslog_perm_status='0'
fi

# 34. history命令格式
# HISTSIZE=5000
# export HISTTIMEFORMAT="`whoami` [%Y-%m-%d %H:%M:%S] "

sys_histsize_value=''
sys_histsize_status=''
sys_histtimeformat_value=''
sys_histtimeformat_status=''

sys_histsize_value="$(grep -Ev '^$|^#' /etc/profile | grep -aPo '(?<=HISTSIZE=)[0-9]+' | tail -n 1)"
if [ "${sys_histsize_value}" == '5000' ]; then
    sys_histsize_status="0"
else
    sys_histsize_status="1"
fi

sys_histtimeformat_value="$(grep -Ev '^$|^#' /etc/profile | grep -aPo '(?<=HISTTIMEFORMAT=).+' | tail -n 1)"
if [ -z "${sys_histtimeformat_value}" ]; then
    sys_histtimeformat_status="1"
else
    sys_histtimeformat_status="0"
fi

# 35. 记录帐户登录日志

# 36. 配置su命令使用情况记录

# 37. 禁止组合键关机
# 6.x /etc/init/control-alt-delete.conf注释下面这行
#     #exec /sbin/shutdown -r now "Control-Alt-Delete pressed"
# 7.x 删除软链接: /usr/lib/systemd/system/ctrl-alt-del.target
sys_ctrl_alt_del_value=''
sys_ctrl_alt_del_status='0'

if [ "${VERSION}" -lt 7 ]; then
    sys_ctrl_alt_del_value=$(grep -Ev '^$|^#' /etc/init/control-alt-delete.conf 2>/dev/null | grep 'Control-Alt-Delete')
    [ -n "${sys_ctrl_alt_del_value}" ] && sys_ctrl_alt_del_status='1'
else
    [ -e '/usr/lib/systemd/system/ctrl-alt-del.target' ] && sys_ctrl_alt_del_status='1'
    sys_ctrl_alt_del_value=$(ls -l /usr/lib/systemd/system/ctrl-alt-del.target 2>/dev/null | awk '{print $(NF-2)$(NF-1)$NF}')
fi

# 38. 系统core dump状态
#     1、查看/etc/security/limits.conf文件中是否配置如下内容：
#         * soft  core 0
#         * hard core 0
#     2、查看/etc/profile文件中是否存在如下配置，存在则注释掉：
#         ulimit -S -c 0 > /dev/null 2>&1
sys_core_dump_value=''
sys_core_dump_status='0'

sys_core_dump_soft_value=$(grep -Ev '^$|^#' /etc/security/limits.conf | grep 'soft.*core' | awk '{print $NF}' | sed ':label;N;s/\n/;/g;b label')
sys_core_dump_hard_value=$(grep -Ev '^$|^#' /etc/security/limits.conf | grep 'hard.*core' | awk '{print $NF}' | sed ':label;N;s/\n/;/g;b label')
sys_core_dump_conf_value=$(grep -Ev '^$|^#' /etc/profile | grep 'ulimit.*-c')

if [ "${sys_core_dump_soft_value}" != '0' ] || [ "${sys_core_dump_hard_value}" != '0' ] || [ -n "${sys_core_dump_conf_value}" ]; then
    sys_core_dump_status='1'
    [ -z "${sys_core_dump_soft_value}" ] && sys_core_dump_soft_value='NULL'
    [ -z "${sys_core_dump_hard_value}" ] && sys_core_dump_hard_value='NULL'
fi
[ -z "${sys_core_dump_conf_value}" ] && sys_core_dump_conf_value='NULL'

sys_core_dump_value="soft:${sys_core_dump_soft_value};hard:${sys_core_dump_hard_value};conf:${sys_core_dump_conf_value}"

# 39. host.conf
#   编辑文件/etc/host.conf，看是否存在如下内容：
#       order hosts，bind
#       multi on
#       nospoof on
HOST_CONF='hosts_bind;on;on'
sys_host_conf_value=''
sys_host_conf_status='0'

sys_host_conf_order_value=$(grep -Ev '^$|^#' /etc/host.conf | grep -aPo '(?<=order\s)\s*[a-z\,\ ]*' | sed -e 's/\s//g' -e 's/,/_/g')
sys_host_conf_multi_value=$(grep -Ev '^$|^#' /etc/host.conf | grep -aPo '(?<=multi\s)\s*[a-z]*' | sed 's/\s//g')
sys_host_conf_nospoof_value=$(grep -Ev '^$|^#' /etc/host.conf | grep -aPo '(?<=nospoof\s)\s*[a-z]*' | sed 's/\s//g')
sys_host_conf_value="${sys_host_conf_order_value:=NULL};${sys_host_conf_multi_value:=NULL};${sys_host_conf_nospoof_value:=NULL}"

if [ "${sys_host_conf_value}" != "${HOST_CONF}" ]; then
    sys_host_conf_status='1'
fi

[ -z "${sys_host_conf_value%;}" ] && sys_host_conf_value='NULL'

# 40. 文件与目录缺省权限控制

# 41. 文件系统-重要目录和文件的权限设置
# 执行以下命令检查目录和文件的权限设置情况：
# ls  -l  /etc/
# ls  -l  /etc/rc.d/init.d/
# ls  -l  /tmp
# ls  -l  /etc/inetd.conf
# ls  -l  /etc/passwd
# ls  -l  /etc/shadow
# ls  -l  /etc/group
# ls  -l  /etc/security
# ls  -l  /etc/services
# ls  -l  /etc/rc*.d
# 对于重要目录，建议执行如下类似操作：
# chmod -R 750 /etc/rc.d/init.d/*
# 这样只有root可以读、写和执行这个目录下的脚本
FILE_LIST='/etc /etc/rc.d/init.d /tmp /etc/inetd.conf /etc/passwd /etc/shadow /etc/group /etc/security /etc/services /etc/rc*.d'
sys_file_perm_value=''
sys_file_perm_status='0'

for file in ${FILE_LIST}; do
    if [ -d "${file}" ]; then
        sys_file_perm_value="${file}:$(ls -ld ${file} | awk '{print $1}');${sys_file_perm_value}"
    elif [ -f "${file}" ] || [ -L "${file}" ]; then
        sys_file_perm_value="${file}:$(ls -l ${file} | awk '{print $1}');${sys_file_perm_value}"
    else
        sys_file_perm_value="${file}:NULL;${sys_file_perm_value}"
    fi
done

[ -z "${sys_file_perm_value%;}" ] && sys_file_perm_value='NULL'


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Print

# 1. 主机名设置原则
printf "sys_hostname_status=%s,sys_hostname_value=%s,NULL\n" "${sys_hostname_status}" "${sys_hostname_value}" >&3

# 2. 默认软件包选择配置
# => NULL

# >3. 默认软件包选择配置 kdump
sys_kdump_status_set='NULL'
if [ "${sys_kdump_status}" == "1" ]; then SetKdump; fi
printf "sys_kdump_status=%s,sys_kdump_value=%s,sys_kdump_status_set=%s\n" "${sys_kdump_status}" "${sys_kdump_value}" "${sys_kdump_status_set}" >&3

# >4. 设置系统运行级别
sys_runlevel_status_set='NULL'
if [ "${sys_runlevel_status}" == "1" ]; then SetRunlevel; fi
printf "sys_runlevel_status=%s,sys_runlevel_value=%s,sys_runlevel_status_set=%s\n" "${sys_runlevel_status}" "${sys_runlevel_value%;}" "${sys_runlevel_status_set}" >&3

# 5. 配置补丁更新服务
# => NULL

# 6. 时区选择
printf "sys_timezone_status=%s,sys_timezone_value=%s,NULL\n" "${sys_timezone_status}" "${sys_timezone_value}" >&3

# >7. 时间服务配置
sys_ntp_status_set='NULL'
if [ "${sys_ntp_status}" == "1" ]; then SetNtpServer; fi
printf "sys_ntp_status=%s,sys_ntp_value=%s,sys_ntp_status_set=%s\n" "${sys_ntp_status}" "${sys_ntp_value}" "${sys_ntp_status_set}" >&3

# >8. 用户的umask安全配置
sys_umask_status_set='NULL'
if [ "${sys_umask_status}" == "1" ]; then SetUmask; fi
printf "sys_umask_status=%s,sys_umask_value=%s,sys_umask_status_set=%s\n" "${sys_umask_status}" "${sys_umask_value%;}" "${sys_umask_status_set}" >&3

# 9. 清除其它UID=0的账户
printf "sys_uid0_status=%s,sys_uid0_value=%s,NULL\n" "${sys_uid0_status}" "${sys_uid0_value:=NULL}" >&3

# 10. 清除不必要的系统账户
printf "sys_unused_user_status=%s,sys_unused_user_value=%s,NULL\n" "${sys_unused_user_status}" "${sys_unused_user_value:=NULL}" >&3

# >11. 用户的主目录安全管理
sys_homedir_right_status_set='NULL'
if [ "${sys_homedir_right_status}" == "1" ]; then SetHomeDirPermission; fi
printf 'sys_homedir_right_status=%s,sys_homedir_right_value=%s,sys_homedir_right_status_set=%s\n' "${sys_homedir_right_status}" "${sys_homedir_right_value%;}" "${sys_homedir_right_status_set}" >&3

# 12. root用户环境变量的安全性
printf "sys_root_PATH_status=%s,sys_root_PATH_value=%s,NULL\n" "${sys_root_PATH_status}" "${sys_root_PATH_value}" >&3

# >13. 账号文件权限设置
sys_account_file_perm_status_set='NULL'
if [ "${sys_account_file_perm_status}" == "1" ]; then SetAccoutFilePerm; fi
printf "sys_account_file_perm_status=%s,sys_account_file_perm_value=%s,sys_account_file_perm_status_set=%s\n" "${sys_account_file_perm_status}" "${sys_account_file_perm_value%;}" "${sys_account_file_perm_status_set}" >&3

# 14. 关闭不必要启动项
printf "sys_rc_d_status=%s,sys_rc_d_value=%s,NULL\n" "${sys_rc_d_status}" "${sys_rc_d_value%;}" >&3

# 15. 最小化启动服务
# => NULL

# >16. SELinux设置
sys_selinux_status_set='NULL'
if [ "${sys_selinux_status}" == "1" ]; then SetSelinux; fi
printf "sys_selinux_status=%s,sys_selinux_value=%s,sys_selinux_status_set=%s\n" "${sys_selinux_status}" "${sys_selinux_value}" "${sys_selinux_status_set}" >&3

# >17. 口令生存期
sys_PASS_status_set='NULL'
if [ "${sys_PASS_status}" == "1" ]; then SetLoginDefs; fi
printf "sys_PASS_status=%s,sys_PASS_value=%s,sys_PASS_status_set=%s\n" "${sys_PASS_status}" "${sys_PASS_value}" "${sys_PASS_status_set}" >&3

# 18. root密码要求
# => NULL

# >19. 口令复杂度策略
sys_pw_minlen_status_set='NULL'
sys_pw_dcredit_status_set='NULL'
sys_pw_lcredit_status_set='NULL'
sys_pw_ucredit_status_set='NULL'
sys_pw_ocredit_status_set='NULL'
count=$(expr "${sys_pw_minlen_status}" + "${sys_pw_dcredit_status}" + "${sys_pw_lcredit_status}" + "${sys_pw_ucredit_status}" + "${sys_pw_ocredit_status}")
if [ "${count}" != "0" ]; then SetPwConfig; fi
printf "sys_pw_minlen_status=%s,sys_pw_minlen_value=%s,sys_pw_minlen_status_set=%s\n" "${sys_pw_minlen_status}" "${sys_pw_minlen_value:=NULL}" "${sys_pw_minlen_status_set}" >&3
printf "sys_pw_dcredit_status=%s,sys_pw_dcredit_value=%s,sys_pw_dcredit_status_set=%s\n" "${sys_pw_dcredit_status}" "${sys_pw_dcredit_value:=NULL}" "${sys_pw_dcredit_status_set}" >&3
printf "sys_pw_lcredit_status=%s,sys_pw_lcredit_value=%s,sys_pw_lcredit_status_set=%s\n" "${sys_pw_lcredit_status}" "${sys_pw_lcredit_value:=NULL}" "${sys_pw_lcredit_status_set}" >&3
printf "sys_pw_ucredit_status=%s,sys_pw_ucredit_value=%s,sys_pw_ucredit_status_set=%s\n" "${sys_pw_ucredit_status}" "${sys_pw_ucredit_value:=NULL}" "${sys_pw_ucredit_status_set}" >&3
printf "sys_pw_ocredit_status=%s,sys_pw_ocredit_value=%s,sys_pw_ocredit_status_set=%s\n" "${sys_pw_ocredit_status}" "${sys_pw_ocredit_value:=NULL}" "${sys_pw_ocredit_status_set}" >&3

# >20. 口令重复次数限制
sys_pw_remember_status_set='NULL'
if [ "${sys_pw_remember_status}" == "1" ]; then SetPasswdRemember; fi
printf "sys_pw_remember_status=%s,sys_pw_remember_value=%s,sys_pw_remember_status_set=%s\n" "${sys_pw_remember_status}" "${sys_pw_remember_value}" "${sys_pw_remember_status_set}" >&3

# >21. 口令锁定策略
sys_pam_tally_status_set='NULL'
if [ "${sys_pam_tally_status}" == "1" ]; then SetPamtally2; fi
printf "sys_pam_tally_status=%s,sys_pam_tally_value=%s,sys_pam_tally_status_set=%s\n" "${sys_pam_tally_status}" "${sys_pam_tally_value}" "${sys_pam_tally_status_set}" >&3

# >22. 用户连接安全管理
sys_tmout_status_set='NULL'
if [ "${sys_tmout_status}" == "1" ]; then SetTmout; fi
printf 'sys_tmout_status=%s,sys_tmout_value=%s,sys_tmout_status_set=%s\n' "${sys_tmout_status}" "${sys_tmout_value:=NULL}" "${sys_tmout_status_set}" >&3

# >23. SSH只允许用户从指定的IP登录
sys_ssh_limit_status_set='NULL'
if [ "${sys_ssh_limit_status}" == "1" ]; then SetSshdLimit; fi
printf "sys_ssh_limit_status=%s,sys_ssh_limit_value=%s,sys_ssh_limit_status_set=%s\n" "${sys_ssh_limit_status}" "${sys_ssh_limit_value}" "${sys_ssh_limit_status_set}" >&3

# >24. 禁止telnet服务
sys_telnet_status_set='NULL'
if [ "${sys_telnet_status}" == "1" ]; then SetTelnet; fi
printf "sys_telnet_status=%s,sys_telnet_value=%s,sys_telnet_status_set=%s\n" "${sys_telnet_status}" "${sys_telnet_value}" "${sys_telnet_status_set}" >&3

# >25. 限制root用户TELNET远程登录
sys_root_telnet_status_set='NULL'
if [ "${sys_root_telnet_status}" == "1" ]; then SetRootTelnet; fi
printf "sys_root_telnet_status=%s,sys_root_telnet_value=%s,sys_root_telnet_status_set=%s\n" "${sys_root_telnet_status}" "${sys_root_telnet_value%;}" "${sys_root_telnet_status_set}" >&3

# 26. 使用SSH协议进行远程维护
# => NULL

# >27. 修改SSH的Banner警告信息
sys_ssh_banner_status_set='NULL'
if [ "${sys_ssh_banner_status}" == "1" ]; then SetSshBanner; fi
printf "sys_ssh_banner_status=%s,sys_ssh_banner_value=%s,sys_ssh_banner_status_set=%s\n" "${sys_ssh_banner_status}" "${sys_ssh_banner_value}" "${sys_ssh_banner_status_set}" >&3

# 28. 修改TELNET的Banner信息
# => NULL

# 29. 检查.forward文件是否存在
printf "sys_forward_file_status=%s,sys_forward_file_value=%s,NULL\n" "${sys_forward_file_status}" "${sys_forward_file_value}" >&3

# 30. 检查.netrc文件是否存在
printf "sys_netrc_file_status=%s,sys_netrc_file_value=%s,NULL\n" "${sys_netrc_file_status}" "${sys_netrc_file_value}" >&3

# 31. 检查用户的.rhosts文件是否存在
printf "sys_rhosts_file_status=%s,sys_rhosts_file_value=%s,NULL\n" "${sys_rhosts_file_status}" "${sys_rhosts_file_value}" >&3

# >32. 安全日志完备性要求
sys_authpriv_status_set='NULL'
if [ "${sys_authpriv_status}" == "1" ]; then SetLogAuthpriv; fi
printf "sys_authpriv_status=%s,sys_authpriv_value=%s,sys_authpriv_status_set=%s\n" "${sys_authpriv_status}" "${sys_authpriv_value%;}" "${sys_authpriv_status_set}" >&3

# >33. 限制日志文件访问权限
sys_rsyslog_perm_status_set='NULL'
if [ "${sys_rsyslog_perm_status}" == "1" ]; then SetSyslogFilePermission; fi
printf "sys_rsyslog_perm_status=%s,sys_rsyslog_perm_value=%s,sys_rsyslog_perm_status_set=%s\n" "${sys_rsyslog_perm_status}" "${sys_rsyslog_perm_value}" "${sys_rsyslog_perm_status_set}" >&3

# >34. history命令格式配置
sys_histsize_status_set='NULL'
sys_histtimeformat_status_set='NULL'
if [ "${sys_histsize_status}" == "1" ] || [ "${sys_histtimeformat_status}" == "1" ]; then SetHistroy; fi
printf "sys_histsize_status=%s,sys_histsize_value=%s,sys_histsize_status_set=%s\n" "${sys_histsize_status}" "${sys_histsize_value:=NULL}" "${sys_histsize_status_set}" >&3
printf "sys_histtimeformat_status=%s,sys_histtimeformat_value=%s,sys_histtimeformat_status_set=%s\n" "${sys_histtimeformat_status}" "${sys_histtimeformat_value:=NULL}" "${sys_histtimeformat_status_set}" >&3

# 35. 记录帐户登录日志
# => NULL

# 36. 配置su命令使用情况记录
# => NULL

# >37. 禁止组合键关机
sys_ctrl_alt_del_status_set='NULL'
if [ "${sys_ctrl_alt_del_status}" == "1" ]; then SetCtrlAltDel; fi
printf "sys_ctrl_alt_del_status=%s,sys_ctrl_alt_del_value=%s,sys_ctrl_alt_del_status_set=%s\n" "${sys_ctrl_alt_del_status}" "${sys_ctrl_alt_del_value}" "${sys_ctrl_alt_del_status_set}" >&3

# >38. 系统core dump状态
sys_core_dump_status_set='NULL'
if [ "${sys_core_dump_status}" == "1" ]; then SetCoreDump; fi
printf "sys_core_dump_status=%s,sys_core_dump_value=%s,sys_core_dump_status_set=%s\n" "${sys_core_dump_status}" "${sys_core_dump_value}" "${sys_core_dump_status_set}" >&3

# >39. 更改主机解析地址的顺序
sys_host_conf_status_set='NULL'
if [ "${sys_host_conf_status}" == "1" ]; then SetHostConf; fi
printf "sys_host_conf_status=%s,sys_host_conf_value=%s,sys_host_conf_status_set=%s\n" "${sys_host_conf_status}" "${sys_host_conf_value}" "${sys_host_conf_status_set}" >&3

# 40. 文件与目录缺省权限控制
# => NULL

# 41. 重要目录和文件的权限设置
printf "sys_file_perm_status=%s,sys_file_perm_value=%s,NULL\n" "${sys_file_perm_status}" "${sys_file_perm_value%;}" >&3

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# Scripts END!



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#
# 删除的项

#++++++++++++set++++++++++++#

# # 1. 指定日志服务器    <=日志服务器暂不配置
# # loghost: 10.32.4.73
# # local7.*;*.info;mail.none;authpriv.none;cron.none      @10.32.4.73
# SetLogHost(){
#     grep -Ev '^#|^$' /etc/rsyslog.conf | grep -q -E "@{1,2}10.32.4.73"
#     if [ $? -ne 0 ]; then
#         sed -i '$a \local7.*;*.info;mail.none;authpriv.none;cron.none      @10.32.4.73' /etc/rsyslog.conf
#     fi
#     service rsyslog restart &>/dev/null
#     [ $? -eq 0 ] && sys_loghost_status_set='0' || sys_loghost_status_set='1'
# }

#++++++++++++check++++++++++++#

# # 1. 日志服务器
# # loghost: 10.32.4.73
# LOG_HOST='10.32.4.73'
# sys_loghost_value=''
# sys_loghost_status='0'

# sys_loghost_value=$(grep -Ev '^#|^$' /etc/rsyslog.conf | grep -E "@{1,2}${LOG_HOST}")
# if [ -z "${sys_loghost_value}" ]; then
#     sys_loghost_status='1'
#     sys_loghost_value='NULL'
# fi

# # 2. 限制普通用户使用at/cron服务
# # cron.deny和at.deny文件拒绝某些用户运行crontab和at命令，为安全考虑，可以限制某些用户禁止执行crontab和at命令，只允许管理员有权利运行计划任务。
# # 配置限制用户：
# # vim /etc/cron.deny  #限制user1，user2用户执行crontab命令。
# # vim /etc/at.deny    #限制user1，user2用户执行at命令。"
# sys_at_cron_value=''
# sys_at_cron_status='1'

# [ -s "/etc/cron.deny" ] && [ -s "/etc/at.deny" ] && sys_at_cron_status='0'
# sys_at_value=$(grep -Ev '^$|^#' /etc/at.deny 2>/dev/null | sed ':label;N;s/\n/;/g;b label')
# sys_cron_value=$(grep -Ev '^$|^#' /etc/cron.deny 2>/dev/null | sed ':label;N;s/\n/;/g;b label')
# sys_at_cron_value="${sys_at_value};${sys_cron_value}"

# [ -z "${sys_at_cron_value%;}" ] && sys_at_cron_value='NULL'

#++++++++++++print++++++++++++#

# # 1. 日志服务器
# # sys_loghost_status_set='NULL'
# # if [ "${sys_loghost_status}" == "1" ]; then SetLogHost; fi
# # printf "sys_loghost_status=%s,sys_loghost_value=%s,sys_loghost_status_set=%s\n" "${sys_loghost_status}" "${sys_loghost_value}" "${sys_loghost_status_set}" >&3
# printf "sys_loghost_status=%s,sys_loghost_value=%s,NULL\n" "${sys_loghost_status}" "${sys_loghost_value}" >&3

# # 2. 限制普通用户使用at/cron服务
# printf "sys_at_cron_status=%s,sys_at_cron_value=%s,NULL\n" "${sys_at_cron_status}" "${sys_at_cron_value%;}" >&3

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++#