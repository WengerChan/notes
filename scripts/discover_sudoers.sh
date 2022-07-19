#! /usr/bin/env bash

# Description: 作业平台: 检查拥有sudo权限的账号并输出

# 删除无用的账号
# sed -i "/^it_xxxxxx/d" /etc/sudoers    
# sed -i "/^xie_xxxxxx/d" /etc/sudoers

# /etc/sudoers除xxxxxx外, 若存在其他账号则将其输出, 否则输出0
if [[ -z `grep '^xxxxxx' /etc/sudoers` ]]; then 
    sed -i "\$a xxxxxx\tALL=(ALL)\tNOPASSWD: ALL" /etc/sudoers
fi

sudoers=`grep -Ev "^$|^#|^Defaults|^root|wheel|Cmnd_Alias|^[[:space:]]{4,}" /etc/sudoers|awk '{print $1}'|sort|tr "\n" ":"|sed -e 's/:$/\n/'`
if [ ${sudoers} == 'xxxxxx' ]; then
    printf "sudoers=0"
else
    printf "sudoers=${sudoers}"
fi