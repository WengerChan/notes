#! /usr/bin/env bash

# mkdir -p /var/log/user_audit/
# export HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S][`who am i 2>/dev/null|awk '{print $1}'`][`who am i 2>/dev/null|awk '{print $2}'`][`who am i 2>/dev/null|awk '{print $(NF-1),$NF}'`]"
export HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S][`who am i 2>/dev/null|awk '{print "[" $1 "][" $2 "][" $(NF-1),$NF "]"}'`]"
export PROMPT_COMMAND='\
if [ -z "$OLD_PWD" ]; then
    export OLD_PWD=$PWD; 
fi
if [ ! -z "$LAST_CMD" ] && [ "$(history 1)" != "$LAST_CMD" ]; then
    echo `date "+%b %d %T"` `hostname` `whoami`: "[$OLD_PWD]$(history 1)" >> /var/log/user_audit/user_audit.log
fi
export LAST_CMD="$(history 1)"
export OLD_PWD=$PWD'