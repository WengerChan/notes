# rsyslog, logrotate, split


## rsyslog


### 1 配置文件

```sh
/etc/sysconfig/rsyslogd
/etc/rsyslog.conf
```

配置文件中有很多内容, 但最主要的是 **指定需要记录哪些服务和需要记录什么等级的信息**

```text
# rsyslog configuration file

# For more information see /usr/share/doc/rsyslog-*/rsyslog_conf.html
# If you experience problems, see http://www.rsyslog.com/doc/troubleshoot.html

#### MODULES ####                 <= 加载模块

# The imjournal module bellow is now used as a message source instead of imuxsock.
$ModLoad imuxsock # provides support for local system logging (e.g. via logger command)
$ModLoad imjournal # provides access to the systemd journal
#$ModLoad imklog # reads kernel messages (the same are read from journald)
#$ModLoad immark  # provides --MARK-- message capability

# Provides UDP syslog reception   <= 允许514端口接收使用UDP协议转发过来的日志
#$ModLoad imudp
#$UDPServerRun 514

# Provides TCP syslog reception   <= 允许514端口接收使用TCP协议转发过来的日志
#$ModLoad imtcp
#$InputTCPServerRun 514


#### GLOBAL DIRECTIVES ####       <= 全局配置

# Where to place auxiliary files
$WorkDirectory /var/lib/rsyslog

# Use default timestamp format    <= 日志默认格式
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat

# File syncing capability is disabled by default. This feature is usually not required,
# not useful and an extreme performance hit
#$ActionFileEnableSync on         <= 日志文件同步，默认关闭

# Include all config files in /etc/rsyslog.d/
$IncludeConfig /etc/rsyslog.d/*.conf

# Turn off message reception via local log socket;
# local messages are retrieved through imjournal now.
$OmitLocalLogging on              <= 关闭通过本地日志接口接收消息，现使用imjournal模块作为替代

# File to store the position in the journal  <= 记录journal位置
$IMJournalStateFile imjournal.state


#### RULES ####                   <= 规则设置

# Log all kernel messages to the console.    <= 将内核日志打印到console，默认关闭
# Logging much else clutters up the screen.
#kern.*                                                 /dev/console

# Log anything (except mail) of level info or higher.   <= 记录所有 ≥info 级别的日志(不包括 mail, authpriv, cron 类型的日志)
# Don't log private authentication messages!
*.info;mail.none;authpriv.none;cron.none                /var/log/messages

# The authpriv file has restricted access.
authpriv.*                                              /var/log/secure

# Log all the mail messages in one place.
mail.*                                                  -/var/log/maillog   <= "-" 表示采用异步方式记录

# Log cron stuff
cron.*                                                  /var/log/cron

# Everybody gets emergency messages        <= 将所有 ≥emerg 级别的日志通过 wall 方式发送给当前所有已登录的用户
*.emerg                                                 :omusrmsg:*  <= 也可自定义用户，当他们登录的时候就会收到消息
                                                                        例如 :omusrmsg:root,user1,user2

# Save news errors of level crit and higher in a special file.
uucp,news.crit                                          /var/log/spooler

# Save boot messages also to boot.log
local7.*                                                /var/log/boot.log


# ### begin forwarding rule ###   <= 日志转发规则设置
# The statement between the begin ... end define a SINGLE forwarding
# rule. They belong together, do NOT split them. If you create multiple
# forwarding rules, duplicate the whole block!
# Remote Logging (we use TCP for reliable delivery)
#                                <= 为此操作创建一个磁盘队列。 如果远程主机是down掉，消息缓存到磁盘假脱机文件，并在远程主机up后发送。
# An on-disk queue is created for this action. If the remote host is
# down, messages are spooled to disk and sent when it is up again.
#$ActionQueueFileName fwdRule1 # unique name prefix for spool files         <= 假脱机文件名称前缀
#$ActionQueueMaxDiskSpace 1g   # 1gb space limit (use as much as possible)  <= 最大可占用1G空间
#$ActionQueueSaveOnShutdown on # save messages to disk on shutdown            
#$ActionQueueType LinkedList   # run asynchronously                         <= 队列类型
#$ActionResumeRetryCount -1    # infinite retries if host is down           <= 恢复重试次数
# remote host is: name/ip:port, e.g. 192.168.0.1:514, port optional
#*.* @@remote-host:514        <= @@ 使用TCP协议发送， @表示使用UDP协议发送
# ### end of the forwarding rule ###
```



### 格式

```
日志设备(类型).(连接符号)日志级别   日志处理方式(action)
```

#### 日志设备

可以理解为日志类型

类型|含义
--|--
auth        |pam产生的日志
authpriv    |ssh,ftp等登录信息的验证信息
cron        |时间任务相关
kern        |内核
lpr         |打印
mail        |邮件
mark(syslog)|rsyslog服务内部的信息,时间标识
news        |新闻组
user        |用户程序产生的相关信息
uucp        |unix to unix copy, unix主机之间相关的通讯
local 1~7   |自定义的日志设备

#### 日志级别

类型|含义
--|--
debug   |有调式信息的，日志信息最多
info    |一般信息的日志，最常用
notice  |最具有重要性的普通条件的信息
warning |警告级别
err     |错误级别，阻止某个功能或者模块不能正常工作的信息
crit    |严重级别，阻止整个系统或者整个软件不能正常工作的信息
alert   |需要立刻修改的信息
emerg   |内核崩溃等严重信息
none    |什么都不记录

从上到下，级别从低到高，记录的信息越来越少。详细的可以查看手册: `man 3 syslog`

#### 连接符号

类型|含义
--|--
`.xxx`|表示大于等于`xxx`级别的信息
`.=xxx`|表示等于`xxx`级别的信息
`.!xxx`|表示在`xxx`之外的等级的信息
	
#### 日志处理方式(Actions)

##### (1) 记录到普通文件或设备文件

```
	*.*     /var/log/file.log   # 绝对路径
	*.*     /dev/pts/0
```

测试: 

```
logger -p local3.info 'KadeFor is testing the rsyslog and logger'
```

logger 命令用于产生日志

##### (2) 转发到远程

```
*.* @192.168.0.1            # 使用UDP协议转发到192.168.0.1的514(默认)端口
*.* @@192.168.0.1:10514     # 使用TCP协议转发到192.168.0.1的10514(默认)端口
```

##### (3) 发送给用户(需要在线才能收到)

```
*.*   root
*.*   root,kadefor,up01     # 使用,号分隔多个用户
*.*   *                     # *号表示所有在线用户
```

##### (4) 忽略,丢弃

```
local3.*   ~                # 忽略所有local3类型的所有级别的日志
```

##### (5) 执行脚本

```
local3.*    ^/tmp/a.sh      # ^号后跟可执行脚本或程序的绝对路径

# 日志内容可以作为脚本的第一个参数.
# 可用来触发报警
```

##### (6) -/var/log/mail
	
`-`用于指定目标文件时，代表异步写入


<font size=4 color=red>

注：日志记录的顺序有先后关系!

</font>




## 3. 一个标准的简单的配置文件

```
*.info;mail.none;authpriv.none;cron.none      /var/log/messages
authpriv.*                                    /var/log/secure
mail.*                                        /var/log/maillog
cron.*                                        /var/log/cron
*.emerg                                       *
uucp,news.crit                                /var/log/spooler
local7.*                                      /var/log/boot.log
```


## 4. 实例

### 实例1: 指定日志文件, 或者终端

配置文件添加配置

```sh
vi /etc/rsyslog.conf
	local3.*        /var/log/local3.log
```

重启rsyslog

```sh
rm -rf /var/log/local3.log
/etc/init.d/rsyslog reload
```

测试

```sh
logger -t 'LogTest' -p local3.info 'KadeFor is testing the rsyslog and logger'

#自己实验日志发送给某个终端
cat /var/log/local3.log
	Jun 10 04:55:52 kadefor LogTest: KadeFor is testing the rsyslog and logger
```

### 实例2: 过滤特定的日志到文件, 忽略(丢弃)包含某个字符串的日志

```
# 过滤日志内容, 由:号开头msg/rawmsg

	:msg, contains, "error" /var/log/error.log      # 包含error的日志记录在/var/log/error.log
	:msg, contains, "error"  ~                      # 忽略包含error的日志

# 过滤日志标签

    :programname, contains, "AA" /var/log/AA.log    # 标签为AA的日志记录在/var/log/AA.log
    :programname, contains, "BB" /var/log/BB.log    # 标签为BB的日志记录在/var/log/BB.log

    :syslogtag, contains, "AA" /var/log/AA.log      # 有时候用programname这个属性不是很管用，可以尝试使用syslogtag
    :syslogtag, contains, "BB" /var/log/BB.log

    # logger -t 'LogTest' -p local3.info 'KadeFor is testing the rsyslog and logger'      # -t指定的即为日志标签

# 来之特定服务器的ip写入指定位置

    :fromhost-ip, isequal, "192.168.1.4" /data/log/office/my.log        #指定IP
    :fromhost-ip, startswith, "192.168.1." /data/log/office/my.log      #网段

# 忽略所有日志

	&   ~ 
```


### 实例3: 使用模板来定义日志格式

定义默认的日志格式:

```
# A template that resembles traditional syslogd file output
    $template TraditionalFormat,"%timegenerated% %HOSTNAME% %syslogtag% %msg:::drop-last-lf%\n"

# A template that tells you a little more about the message:
    $template precise,"%syslogpriority%,%syslogfacility%,%timegenerated%,%HOSTNAME%,%syslogtag%,%msg%\n"

# A template for RFC 3164 format:
    $template RFC3164fmt,"<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg%"

# A template for the format traditionally used for user messages:
    $template usermsg," XXXX%syslogtag%%msg%\n\r"

# And a template with the traditional wall-message format:
    $template wallmsg,"\r\n\7Message from syslogd@%HOSTNAME% at %timegenerated%"    #"\7" rings the bell (this is an ASCII value)

# A template that can be used for writing to a database (please note the SQL template option)
    $template MySQLInsert,"insert iut, message, receivedat values ('%iut%', '%msg:::UPPERCASE%', '%timegenerated:::date-mysql%') into systemevents\r\n", SQL
        #NOTE 1: This template is embedded into core application under name StdDBFmt , so you don't need to define it.
        #NOTE 2: You have to have MySQL module installed to use this template.

    $template myFormat,"%rawmsg%\n"
    $ActionFileDefaultTemplate myFormat  
```

如果不要$ActionFileDefaultTemplate myFormat这一行, 就需要像这样来使用模板:

```	
#在指定的日志文件后添加模板名, 并用;号分隔

$template myFormat,"%rawmsg%\n" 

authpriv.*      /var/log/secure;myFormat  
mail.*          /var/log/maillog;myFormat  
cron.*          /var/log/cron;myFormat  
*.emerg         *;myFormat
uucp,news.crit  /var/log/spooler;myFormat  
local7.*        /var/log/boot.log;myFormat  
```

### 实例4: remote log 远程发送与接收:

> 如果要修改为非514的端口, 需要设置selinux

在rsyslog.conf中加入

```
	*.* @192.168.0.10
	*.* @192.168.0.10:10514     # 带端口号
	*.* @@192.168.0.10          # TCP
```

但是没有定义保存在远程的哪一个文件?
其实保存在什么文件, 那是远程日志服务器接收到日志之后它自己的事情了.

例子:
- Client(send):

```
	local3.*                                    @@192.0.2.1:10514
	*.info;mail.none;authpriv.none;cron.none    /var/log/messages
	authpriv.*                                  /var/log/secure
	mail.*                                      /var/log/maillog
	cron.*                                      /var/log/cron
	*.emerg                                     *
	uucp,news.crit                              /var/log/spooler
	local7.*                                    /var/log/boot.log
```

- Server(receive): 

```
	# for TCP use:
	$modload imtcp
	$InputTCPServerRun 10514
	
	# for UDP use:
	$modload imudp
	$UDPServerRun 514
	
	*.info;mail.none;authpriv.none;cron.none    /var/log/messages
	authpriv.*                                  /var/log/secure
	mail.*                                      /var/log/maillog
	cron.*                                      /var/log/cron
	*.emerg                                     *
	uucp,news.crit                              /var/log/spooler
	local7.*                                    /var/log/boot.log
	local3.*                                    /var/log/local3.log     # 测试用
```



# logrotate服务


- logrotate是一个日志管理程序，用来把旧的日志文件删除（备份），并创建新的日志文件，这个过程称为**转储**。  
- 可以根据日志的大小，或者根据其使用的天数来转储。  
- logrotate 的执行由crond服务实现: 在`/etc/cron.daily`目录中，有个shell script文件`logrotate`，用来启动logrotate。即logrotate程序每天由cron在指定的时间启动。  
- 因此，使用ps是无法查看到logrotate的。如果它没有起来，就要查看一下crond服务有没有在运行。  

参数|参数说明
--|--
`daily` |日志的轮替周期是毎天
`weekly` |日志的轮替周期是每周
`monthly` |日志的轮控周期是每月
`rotate 数字` |保留的日志文件的个数。0指没有备份
`compress` |当进行日志轮替时，对旧的日志进行压缩(`gzip`)
`create mode owner group` |建立新日志，同时指定新日志的权限与所有者和所属组。如`create 0600 root utmp`
`mail address` |当进行日志轮替时.输出内存通过邮件发送到指定的邮件地址
`missingok` |如果日志不存在，则忽略该日志的警告信息
`nolifempty` |如果日志为空文件，则不进行日志轮替
`minsize 大小` |日志轮替的最小值。也就是日志一定要达到这个最小值才会进行轮持，否则就算时间达到也不进行轮替
`size 大小` |日志只有大于指定大小才进行日志轮替，而不是按照时间轮替，如size 100k
`dateext` |使用日期作为日志轮替文件的后缀，如secure-20130605
`dateformat .%s` |                       配合dateext使用，紧跟在下一行出现，定义文件切割后的文件名，必须配合dateext使用，只支持 %Y %m %d %s 这四个参数
`sharedscripts` |在此关键字之后的脚本只执行一次（所有日志轮转完以后统一执行脚本）
`prerotate`/`endscript` |在日志轮替之前执行脚本命令。endscript标识prerotate脚本结束
`postrotate`/`endscript` |在日志轮替之后执行脚本命令。endscripi标识postrotate脚本结束
`su user group` |用指定的用户和组轮转日志
`olddir /path` |指定旧日志存放的目录



在执行logrotate时，需要指定其配置文件`/etc/logrotate.conf`

每个存放在`/etc/logrotate.d`目录里的文件，都有固定格式的配置信息。如果与`logrotate.conf`中的冲突，以`/etc/logrotatate.d/`中的文件定义的为准。

```sh
/usr/sbin/logrotate /etc/logrotate.conf
    #-f 强制rotation
    #-v 显示过程
```

## /etc/logrotate.conf

logrotate配置文件

```
	# see “man logrotate” for details
	# rotate log files weekly
	weekly                              #每周轮转一次
	
	# keep 4 weeks worth of backlogs
	rotate 4                            #保留四个
	
	# create new (empty) log files after rotating old ones
	create                              #rotate后，创建一个新的空文件
	
	# uncomment this if you want your log files compressed
	#compress                           #默认是不压缩的
	
	# RPM packages drop log rotation information into this directory
	include /etc/logrotate.d            #这个目录下面配置文件生效
	
	# no packages own wtmp — we’ll rotate them here
	/var/log/wtmp {                     #定义/var/log/wtmp这个日志文件的rotate
		monthly                         #每月轮转一次，取代了上面的全局设定的每周轮转一次
		minsize 1M                      #定义日志必须要大于1M大小才会去轮转
		create 0664 root utmp           #新的日志文件的权限，属主，属主
		rotate 1                        #保留一个，取代了上面的全局设定的保留四个
	}
	
	/var/log/btmp {
		missingok                       #如果日志丢失, 不报错
		monthly
		create 0600 root utmp
		rotate 1
	}
```

```
# sample logrotate configuration file
compress                # 全局设置, 压缩
	/var/log/messages {
        sharedscripts
		postrotate      # 执行脚本：轮换之后重启syslogd服务
		    /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
		endscript
	}
	
	/var/log/httpd/access.log /var/log/httpd/error.log {   #  指定多个文件, 如果有特殊字符需要用单引号
		rotate 5
		mail www@my.org
		size 100k        # 超过100k后切换日志, 并把老的日志发送邮件给www@my.org
		sharedscripts    # 共享脚本. 下面的postrotate脚本只运行一次.
		postrotate
		/usr/bin/killall -HUP httpd
		endscript
	}
	
	/var/log/news/* {    # 少用通配符, 因会它会包括已经切换过的日志, 要用的话最好在*号后加上扩展名, 如*.log
		monthly
		rotate 2
		olddir /var/log/news/old
		missingok
		postrotate
		kill -HUP 'cat /var/run/inn.pid'
		endscript
		nocompress
	}
```


# split

```
split [-b][-C][-][-l] [要切割的文件] [输出文件名前缀] [-a] [-d]
```

* `-b<字节>`：指定按多少字节进行拆分，也可以指定 K、M、G、T 等单位。
* `-<行数>`或`-l<行数>`：指定每多少行要拆分成一个文件。
* `输出文件名前缀`：设置拆分后的文件的名称前缀，split 会自动在前缀后加上编号，默认从 aa 开始。
* `-a<后缀长度>`：默认的后缀长度是 2，也就是按 aa、ab、ac 这样的格式依次编号。
* `-d` `--numeric-suffixes[=FROM]`: 使用数字后缀，默认从0开始。`FROM`指定起始值。

split 会默认采用 x 字符作为文件前缀，采用类似 aa、ab、ac 的字符串依次作为文件后缀

```bash
split -b 100M file_name new_file_suffix -d -a 2 --verbose
split -l 100 file_name new_file_suffix -d -a 2 --verbose

#eg. split -b 100k /var/log/ip_conf.log.2 -a 2 -d /root/log_ --verbose 
```
