#! /usr/bin/env bash

#====================================================
# Description: 监控nfs挂载目录, 若出现异常发出告警
#              返回值：0=正常, 1=客户端异常, 2=服务端异常
#====================================================

DATE="$(date +'%F %H:%M:%S')"
nfs_check_log_file='/var/log/nfscheck.log'
nfs_server='192.168.1.12'
nfs_mount_point='/mnt'

[ -f "${nfs_check_log_file}" ] || touch ${nfs_check_log_file}

read -t1 < <(stat -t "${nfs_mount_point}")
if [ $? -eq 0 ]; then
    rpcinfo -t ${nfs_server} nfs > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${DATE} Success! " >> ${nfs_check_log_file}
        exit 0
    else
        echo "${DATE} Server Error! " >> ${nfs_check_log_file}
        exit 2
    fi
else
    echo "${DATE} Client Error! " >> ${nfs_check_log_file}
    exit 1
fi
