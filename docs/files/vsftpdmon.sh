#!/bin/bash

# chkconfig: 2345 50 60 
# description: Bring up/down vsftpd monitor.

# v1.0 2022-10-21 
# v1.1 2022-11-25 支持中文文件生成.ok文件
# v1.2 2022-12-07 Bug Fix: 文件名含特殊符号(空格, 逗号等)导致无法生成.ok文件
# v1.3 2023-02-08 Add: 1)上传速率限制; 2)配额限制; 3)延迟1minute生成标志文件

create_ok(){
    if [ "$#" -ne 4 ]; then
        echo "$(date +'%F %H:%M:%S') [Error] Function 'create_ok' Need 4 parameters. $#"
        return 1
    fi
    client_T="$1"
    user_T="$2"
    action_T="$3"
    filename_T="$4"
    COUNT=0
    [ -f "${filename_T}" ] && sleep 60
    if [ -f "${filename_T}" ]; then
        COUNT=1
        md5sum "${filename_T}" | awk '{printf $1}' > "${filename_T}.ok"
        chown ${user_T}:${user_T} "${filename_T}.ok"
        # echo > "${filename_T}.ok"
    fi
    if [ -f "${filename_T}.ok" ]; then
        COUNT=2
        chown ${user}:${user} "${filename_T}.ok"
        chmod 660 "${filename_T}.ok"
    fi
    if [ "${COUNT}" -eq 2 ]; then
        # echo -e "$(date +'%F %H:%M:%S') [$client_T] [$user_T] \033[32m[OK]\033[0m ${action_T} '${filename_T}'" >> /var/log/mon_vsftpd.log
        echo -e "$(date +'%F %H:%M:%S') [$client_T] [$user_T] [OK] ${action_T} '${filename_T}'" >> /var/log/mon_vsftpd.log
    else
        # echo -e "$(date +'%F %H:%M:%S') [$client_T] [$user_T] \033[31m[ERROR]\033[0m ${action_T} '${filename_T}' [Error: ${COUNT}]" >> /var/log/mon_vsftpd.log
        echo -e "$(date +'%F %H:%M:%S') [$client_T] [$user_T] [ERROR] ${action_T} '${filename_T}' [Error: ${COUNT}]" >> /var/log/mon_vsftpd.log
    fi
}

vsftpdmon(){
    tail -f -n0 --pid $$ /var/log/vsftpd.log | while read -r line
    do
        # 忽略连接的日志
        [[ $(echo "${line}" | grep 'CONNECT: Client') ]] && continue

        # read user state action client filename <<< $(echo $line | grep -v 'CONNECT: Client' | awk '{print $6,$7,$8,$10,$11}')
        read user state action client <<< $(echo "$line" | awk -F'[\\[\\]\\" ]+' '{print $8,$9,$10,$12}')
        action=${action%:}
        filename=$(echo "$line" | grep -aPo '(?<=", ").*(?=("$)|",)')
        if [ "${state}" == "OK" ]; then
            case "${action}" in
                'LOGIN'|'DOWNLOAD')
                    : ;;
                'UPLOAD')
                    if [ "$(dirname "${filename}")" == "/upload" ]; then
                        filename="/data/${user}${filename}"
                    else
                        # echo -e "$(date +'%F %H:%M:%S') [$client] [$user] \033[33m[IGNORED]\033[0m ${action} '${filename}'" >> /var/log/mon_vsftpd.log
                        echo -e "$(date +'%F %H:%M:%S') [$client] [$user] [IGNORED] ${action} '${filename}'" >> /var/log/mon_vsftpd.log
                        continue
                    fi
                    bash -c "create_ok '${client}' '${user}' '${action}' '${filename}'" &>>/var/log/mon_vsftpd.error &
                    ;;
                'DELETE')
                    if [ "${user}" == "rpa_user" ]; then
                        filename="/data${filename}"
                    else
                        filename="/data/${user}${filename}"
                    fi
                    if [ ! -f "${filename}" ]; then
                        # if [ -f "${filename}.ok" ]; then
                        #     rm -f "${filename}.ok" 2> /dev/null
                        #     echo -e "$(date +'%F %H:%M:%S') [$client] [$user] \033[32m[OK]\033[0m ${action} '${filename}'" >> /var/log/mon_vsftpd.log
                        # else
                        #     echo -e "$(date +'%F %H:%M:%S') [$client] [$user] \033[32m[OK]\033[0m ${action} '${filename}' [WARNING: 1]" >> /var/log/mon_vsftpd.log
                        # fi

                        # echo -e "$(date +'%F %H:%M:%S') [$client] [$user] \033[32m[OK]\033[0m ${action} '${filename}'" >> /var/log/mon_vsftpd.log
                        echo -e "$(date +'%F %H:%M:%S') [$client] [$user] [OK] ${action} '${filename}'" >> /var/log/mon_vsftpd.log
                    else
                        # echo -e "$(date +'%F %H:%M:%S') [$client] [$user] \033[31m[ERROR]\033[0m ${action} '${filename}' [Error: 2]" >> /var/log/mon_vsftpd.log
                        echo -e "$(date +'%F %H:%M:%S') [$client] [$user] [ERROR] ${action} '${filename}' [Error: 2]" >> /var/log/mon_vsftpd.log
                    fi
                    ;;
                'MKDIR')
                    dirname="/data/${user}${filename}"
                    if [ -d "${dirname}" ]; then
                        rm -rf ${dirname}
                    fi
                    # echo -e "$(date +'%F %H:%M:%S') [$client] [$user] \033[33m[REMOVED]\033[0m ${action} '${dirname}'" >> /var/log/mon_vsftpd.log
                    echo -e "$(date +'%F %H:%M:%S') [$client] [$user] [REMOVED] ${action} '${dirname}'" >> /var/log/mon_vsftpd.log
                    ;;
                *) 
                    : ;;
            esac
        else
            continue # FAIL, CONNECT 等
        fi
    done
}


start(){
    if [ ! -z "${PID}" ]; then
        ps -e | grep -q "${PID}" && return 0
    fi
    echo "$(date +'%F %H:%M:%S') Begin monitor /var/log/vsftpd.log!" >> /var/log/mon_vsftpd.log
    bash -c "vsftpdmon" &>>/var/log/mon_vsftpd.error & PID=$!
    echo ${PID} > /var/run/vsftpdmon.pid
    return 0
}


stop(){
    rm -f /var/run/vsftpdmon.pid
    if [ -z "${PID}" ]; then
        return 0
    else
        ps -e | grep -q "${PID}" || return 0
    fi
    kill -9 ${PID}
    [ $? -eq 0 ] && echo "$(date +'%F %H:%M:%S') Exited!" >> /var/log/mon_vsftpd.log
    return 0
}


status(){
    if [ ! -z "${PID}" ] && [ -d "/proc/${PID}" ]; then
        echo "vsftpdmon (pid $PID) is running..."
    else
        echo "vsftpdmon is stopped"
    fi
}


PID=''
if [ -f '/var/run/vsftpdmon.pid' ] && [ -s '/var/run/vsftpdmon.pid' ]; then
    PID=$(cat /var/run/vsftpdmon.pid)
fi

export -f vsftpdmon
export -f create_ok

case "$1" in
    stop) stop ;;
    start|restart) stop && start ;;
    status) status;;
    *) : ;;
esac
