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


# physical secure settings
# disable usb storage device
disable_usb() {

    cfgfile='/etc/modprobe.d/usb-storage.conf'
    if [ -f $cfgfile ]; then
        if [ $(grep -c '^install usb-storage /bin/true' $cfgfile) -ge 1 ]; then
            echo_ok "task 1: disable usb-storage"
        else
            echo_failure "task 1: disable usb-storage"
        fi   
    else
        echo_failure "task 1: disable usb-storage"
    fi

}



# disable reboot server with control-alt-delete
disable_control_alt_delete() {

    get_os_version

    if [ $version -eq 7 ]; then
        if [ -f "/usr/lib/systemd/system/ctrl-alt-del.target" ]; then
            echo_failure "task 2: disable Control+Alt+Delete reboot server"
        else
            echo_ok "task 2: disable Control+Alt+Delete reboot server"
        fi
    else
        cfgfile='/etc/init/control-alt-delete.conf'

        if [ -f $cfgfile ]; then
            if [ $(grep -c '^#start on control-alt-delete' $cfgfile) -ge 1 ]; then
                echo_ok "task 2: disable Control+Alt+Delete reboot server"
            else
                echo_failure "task 2: disable Control+Alt+Delete reboot server"
            fi   
        else
            echo_failure "task 2: disable Control+Alt+Delete reboot server"
        fi
    fi

}



# password complexity 
pwd_strategy() {

    get_os_version

    if [ $version -eq 7 ]; then
        cfgfile="/etc/security/pwquality.conf"
        cfgfile2="/etc/pam.d/system-auth"
        egrep -q '^minlen = 12' $cfgfile
        setMin=$?
        egrep -q 'password\s+requisite\s+pam_pwquality.so\s+enforce_for_root' $cfgfile2
        setRoot=$?
        #if [ $(egrep -q '^minlen = 12' $cfgfile) -a $(egrep -q 'password\s+requisite\s+pam_pwquality.so\s+enforce_for_root' $cfgfile2) ]; then
        if [[ ($setMin -eq 0) && ($setRoot -eq 0) ]]; then
            echo_ok "task 3: setup password strategy"
        else
            echo_failure "task 3: setup password strategy"
        fi
    else
        cfgfile='/etc/pam.d/system-auth-ac'
        # make copy first
        if [ -f $cfgfile ]; then
            if [ $(egrep -c 'password    required      pam_cracklib.so try_first_pass retry=[0-9]+ minlen=[0-9]+' $cfgfile) -ge 1 ]; then
                echo_ok "task 3: setup password strategy"
            else
                echo_failure "task 3: setup password strategy"
            fi   
        else
            echo_failure "task 3: setup password strategy"
        fi
    
    fi
}



# password validity
pwd_life_time() {

    if [ $(chage -l root | grep -c -w '90') -ge 1 ]; then
        echo_ok "task 4: setup password life time to 90 days"
    else
        echo_failure "task 4: setup password life time to 90 days"
    fi

}



# disable unnecessary users
disable_users() {

    # games, ftp
    if [ $(cat /etc/passwd | egrep "(adm|lp|sync|shutdown|halt|news|uucp|operator|gopher)" | grep -c "bash") -le 0 ]; then
        echo_ok "task 5: disable useless system users"
    else
        echo_failure "task 5: disable useless system users"
    fi
}



# check users with uid=0
check_root_user() {

    if [ $(cat /etc/passwd | egrep -c '^.+:x:0') -le 1 ]; then
        echo_ok "task 6: check uid=0 users"
    else
        echo_failure "task 6: check uid=0 users"
    fi
}



# login secure settings
# do not log information of user not exists when login
# log user last login time
setup_login_defs() {

    cfgfile='/etc/login.defs'
    
    if [ $(grep -c '^LOG_UNKFAIL_ENAB        no' $cfgfile) -ge 1 ] && [ $(grep -c '^LASTLOG_ENAB           yes' $cfgfile) -ge 1 ]; then
        echo_ok "task 7: setup login configurations"
    else
        echo_failure "task 7: setup login configurations"
    fi
}



# profile secure settings
setup_profile() {

    cfgfile='/etc/profile'

    if [ $(grep -c '^export HISTORY_FILE' ${cfgfile}) -ge 1 ] && [ $(grep -c '^export PROMPT_COMMAND' ${cfgfile}) -ge 1 ]; then
        echo_ok "task 8: setup global profile"
    else
        echo_failure "task 8: setup global profile"
    fi
}



# disable unnecessary services
disable_services() {

    if [ $(chkconfig 2>stdin | egrep "(cups|postfix|pcscd|smarted|alsasound|iscsitarget|smb|acpid|telnet)" | grep -c 'on') -le 0 ]; then
        echo_ok "task 9: stop unnecessary services"        
    else
        echo_failure "task 9: stop unnecessary services"
    fi
}



# disable sellinux
set_selinux() {

    #selinux_cfg='/etc/sysconfig/selinux'
    selinux_cfg="/etc/selinux/config"

    if [ $(cat $selinux_cfg | grep -c '^SELINUX=disabled') -ge 1 ]; then
        echo_ok "task 10: setup SELinux"
    else
        echo_failure "task 10: setup SELinux"
    fi
}


# check user without setting password
check_no_passwd() {

    flag=0

    for user in $(awk -F: '($2 == "") {print $1}' /etc/shadow)
    do
        echo_failure "user $user did't setup a password"
        flag=1
    done

    if [ $flag -eq 0 ]; then
        echo_ok "task 11: No user has empty passwd"
    fi
}



# disable system firewall service 
#disable_firewalld() {
#    get_os_version
#    
#    # for Linux 7.x
#    if [ $version -eq 7 ]; then
#        systemctl status firewalld >/dev/null 2>&1    
#        if [ $? -ne 0 ];then
#                    echo_ok "task 12: firewalld is disable"        
#               fi
#    fi    
#}


# 根据实际的 ip 搜索
#ip_limit()  {
#    grep -v ^# /etc/hosts.allow | grep  "192.168.88.100" /etc/hosts.allow >/dev/null 2>&1 && grep -v ^# /etc/hosts.deny >/dev/null 2>&1 | grep "ALL: ALL" /etc/hosts.deny >/dev/null 2>&1
#    if [ $? -eq 0 ];then
#        echo_ok "task 13: ip limit configured"        
#        fi
#}


delete_high_risk_files() {
    files=("/root/.rhosts" "/root/.shosts" "/etc/hosts.equiv" "/etc/shosts.equiv")
#    for i in ${files[*]}; do
        find  $files >/dev/null 2>&1
            if [ $? -ne 0 ];then
        echo_ok "task 12: delete_high_risk_files"
        else
        echo_failure "task 12: delete_high_risk_files"
            fi
#    done
}


cron_authorized() {
    check_cron=$(cat /etc/passwd | grep /bin/bash | awk -F ':' '{print $1}' | grep -v ^root$)
    for i in $check_cron;do
        grep $i /etc/cron.deny >/dev/null 2>&1
        if [ $? -eq 0 ];then
            echo_ok "task 13: cron_authorized"
        else
            echo_failure "task 13: cron authorized configured"
        fi
    done  
    for i in $check_cron;do
        grep $i /etc/at.deny >/dev/null 2>&1
        if [ $? -eq 0 ];then
            echo_ok "task 13: cron_at authorized configured"
        else
            echo_failure "task 13: cron_at authorized configured"
        fi 
    done
}


check_Password_lock() {
cat /etc/pam.d/system-auth|grep -v ^#| grep -E "auth|account" |grep "pam_tally2.so"|grep "deny=6" | grep "onerr=fail" | grep "unlock_time=300" | grep "even_deny_root" | grep "root_unlock_time=300" >/dev/null 2>&1
        if [ $? -eq 0 ];then
                        echo_ok "task 14: Password_lock configured"
                else
                        echo_failure "task 14: Password_lock configured"
                fi

}


# logrotate config
logrotate() {
    cat /etc/logrotate.conf | grep "^size 20M" > /dev/null
    if [ $? -eq 0 ];then
        echo_ok "task 15: logrotate setup"
    else
        echo_failure "task 15: logrotate setup"
    fi
}


auditd_set() {
    grep "max_log_file = 50" /etc/audit/auditd.conf && grep "num_logs = 4" /etc/audit/auditd.conf && grep "flush = NONE"  /etc/audit/auditd.conf > /dev/null
    if [ $? -eq 0 ];then
        echo_ok "task 16: audit setup"
    else
        echo_failure "task 16: audit setup"
    fi

}


#checkperformance mode or not
#checkperformance(){
#    /usr/bin/lscpu|egrep "CPU max MHz|CPU min MHz" >/dev/null
#    if [ $? -eq 0 ];then
#        echo_failure "task 17: max performance setup"
#    else
#        echo_ok "task 17: max performance setup"
#    fi
#}
# check_performance(){
#     lscpu | grep -q -i -E "CPU max MHz|CPU min MHz"
#     if [ $? -ne 0 ];then
#         echo_ok "task 17: max performance setup"
#     else
#         cpu_mhz=$(N=0; while (($N<5));do let N+=1; lscpu | grep 'CPU MHz' | awk -F'[: ]' '{print $NF}'; sleep 1; done | awk '{sum+=$1} END {print sum/5}')
#         cpu_mhz2=$(lscpu | grep 'CPU MHz' | awk -F'[: ]' '{print $NF}')
#         abs=$(awk 'BEGIN{printf "%.3f\n", "'$cpu_mhz2'" - "'$cpu_mhz'"}'|tr -d -)
#         cpu_max_mhz=$(lscpu | grep 'CPU max MHz' | awk -F'[: ]' '{print $NF}')
#         abs2=$(awk 'BEGIN{printf "%.3f\n", "'$cpu_mhz2'" - "'$cpu_max_mhz'"}'|tr -d -)

#         # Condition: |5s_average_value - current_value| < 2 and 5s_average_value is greater(>=) than CPU_MAX_MHZ.
#         # result=$(awk 'BEGIN{if("'${cpu_mhz}'">="'${cpu_max_mhz}'" && "'${abs}'" < 2) {print "0"}else{print "1"}}')
#         result=$(awk 'BEGIN{if("'${abs2}'"<= 5 &&  "'${abs}'" < 30) {print "0"}else{print "1"}}')
#         if [[ "${result}" == "0" ]]; then
#             echo_ok "task 17: max performance setup"
#         else
#             echo_failure "task 17: max performance setup"
#         fi
#     fi
# }


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
        echo_ok "task 17: max performance setup"
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

        if [[ "${result}" == "0" ]]; then
            echo_ok "task 17: max performance setup"
        else
            echo_failure "task 17: max performance setup"
        fi
    fi
}


# main function
# exec 1<&0
# exec 2<&0

disable_usb

disable_control_alt_delete

pwd_strategy

pwd_life_time

disable_users

check_root_user

setup_login_defs

setup_profile

disable_services

set_selinux

check_no_passwd

delete_high_risk_files

cron_authorized

check_Password_lock

logrotate

auditd_set

#checkperformance
check_performance

echo "end of task"

