#! /bin/bash

rm_file_of_safedog() {
    chattr -i /etc/safedog/.sdinfo /etc/safedog/.ins.conf
    rm /etc/safedog -rf
}

/usr/bin/expect <<EOF
spawn /etc/safedog/script/uninstall.py
expect "uninstall"
send "y\n"
expect "isolation"
send "n\n"
expect "logs"
send "n\n"
expect eof
EOF

if [ $? -eq 0 ];then rm_file_of_safedog && echo "Done !!!";fi