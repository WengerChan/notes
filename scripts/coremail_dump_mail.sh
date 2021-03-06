#! /usr/bin/env bash

# Dump mail info

function getMailMid(){
    /home/coremail/bin/userutil --list-msg songxinming@xxx.com 'from!="宋新明" <songxinming@xxx.com>' | awk -F' ' '{print $2}' | sed 's/\[.*\]//g' > /tmp/songxinming.mid
    /home/coremail/bin/userutil --list-msg wuxiaochen@xxx.com 'from!="吴小辰" <wuxiaochen@xxx.com>' | awk -F' ' '{print $2}' | sed 's/\[.*\]//g' > /tmp/wuxiaochen.mid
}


function getMailInfo01(){
    # 需求 1. 作为 "收件人" 和 "抄送人" 的邮件，分别放入不同文件
    #    * 收件人中含 songxinming，写入 /tmp/songxinming.to.msg
    #    * 抄送人中含 songxinming，写入 /tmp/songxinming.cc.msg
    #    * 其余情况，统一写入 /tmp/songxinming.qunfa.msg
    for i in `cat /tmp/songxinming.mid`;do 
        /home/coremail/bin/userutil --display-msginfo songxinming@xxx.com ${i} | grep 'To:.*songxinming.*' &> /dev/null
        if [ $? -eq 0 ]; then
            /home/coremail/bin/userutil --display-msginfo songxinming@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' | tee -a /tmp/songxinming.to.msg | grep retolist &>/dev/null || echo 'retolist=' >> /tmp/songxinming.to.msg
        else
            /home/coremail/bin/userutil --display-msginfo songxinming@xxx.com ${i} | grep 'retolist=.*songxinming.*' &> /dev/null
            if [ $? -eq 0 ]; then
                /home/coremail/bin/userutil --display-msginfo songxinming@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' >> /tmp/songxinming.cc.msg
            else 
                /home/coremail/bin/userutil --display-msginfo songxinming@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' | tee -a /tmp/songxinming.qunfa.msg | grep retolist &>/dev/null || echo 'retolist=' >> /tmp/songxinming.qunfa.msg
            fi
        fi
    done
    
    for i in `cat /tmp/wuxiaochen.mid`;do 
        /home/coremail/bin/userutil --display-msginfo wuxiaochen@xxx.com ${i} | grep 'To:.*wuxiaochen.*' &> /dev/null
        if [ $? -eq 0 ]; then
            /home/coremail/bin/userutil --display-msginfo wuxiaochen@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' | tee -a /tmp/wuxiaochen.to.msg | grep retolist &>/dev/null || echo 'retolist=' >> /tmp/wuxiaochen.to.msg
        else
            /home/coremail/bin/userutil --display-msginfo wuxiaochen@xxx.com ${i} | grep 'retolist=.*wuxiaochen.*' &> /dev/null
            if [ $? -eq 0 ]; then
                /home/coremail/bin/userutil --display-msginfo wuxiaochen@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' >> /tmp/wuxiaochen.cc.msg
            else 
                /home/coremail/bin/userutil --display-msginfo wuxiaochen@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' | tee -a /tmp/wuxiaochen.qunfa.msg | grep retolist &>/dev/null || echo 'retolist=' >> /tmp/wuxiaochen.qunfa.msg
            fi
        fi
    done
}


function getMailInfo02(){
    # 需求 2. 不区分作为 "收件人" 和 "抄送人"，都放入一个文件
    #    全部写入 /tmp/songxinming.total.msg
    for i in `cat /tmp/songxinming.mid`;do 
            /home/coremail/bin/userutil --display-msginfo songxinming@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' | tee -a /tmp/songxinming.total.msg | grep retolist &>/dev/null || echo 'retolist=' >> /tmp/songxinming.total.msg  
    done

    for i in `cat /tmp/wuxiaochen.mid`;do 
            /home/coremail/bin/userutil --display-msginfo wuxiaochen@xxx.com ${i} | egrep 'MsgID|From|To|Subject|Time|retolist' | tee -a /tmp/wuxiaochen.total.msg | grep retolist &>/dev/null || echo 'retolist=' >> /tmp/wuxiaochen.total.msg  
    done
}


function main(){
    getMailMid
    # getMailInfo01
	getMailInfo02
}

main
