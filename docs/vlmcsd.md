# KMS - vlmcsd

`vlmcsd` 是一款搭建 KMS 服务器的工具, 可以用来激活 `Windows` 和 `Microsoft Office` 各类产品

Github: [https://github.com/Wind4/vlmcsd](https://github.com/Wind4/vlmcsd)

## 搭建方式

有三种方式：

* 如果当前服务器能够访问外网，可直接使用作者提供的一键安装脚本: [install-rhel.sh](https://github.com/Wind4/vlmcsd/blob/gh-pages/scripts/install-rhel.sh), [install-debain.sh](https://github.com/Wind4/vlmcsd/blob/gh-pages/scripts/install-debian.sh)

* 如果无法访问外网，可选择使用作者编译的 二进制包 或者 编译安装。

下文介绍二进制包搭建 KMS 服务器.

## 二进制包配置 KMS 服务器

1. 下载: [binaries.tar.gz](https://github.com/Wind4/vlmcsd/releases/download/svn1112/binaries.tar.gz)
    
2. 将压缩包上传到服务器, 解压, 将执行文件拷贝至 `/usr/bin`

    > 支持多个系统, 可以在 `Windows`, `Linux`, `Android` 等多种系统上配置; 同时除了 `Intel/AMD x86_64` 架构, 还支持 `arm` 架构的操作系统部署

    ```text
    ~] ls binaries
    Android  DragonFly  FreeBSD  Hurd  iOS  Linux  MacOSX  Minix  NetBSD  OpenBSD  Solaris  Windows
    
    ~] cp binaries/Linux/intel/static/vlmcsd-x64-musl-static /usr/bin/vlmcsd
    ```
    
3. 下载或者编辑 `/etc/init.d/vlmcsd` 文件

    下载: [vlmcsd-rhel](https://wind4.github.io/vlmcsd/scripts/init.d/vlmcsd-rhel)

    编辑: 

    ```sh
    #!/bin/sh
    #
    # VLMCSD - this script starts and stops the KMS Server daemon
    #
    ### BEGIN SERVICE INFO
    # Run level information:
    # chkconfig: 2345 99 99
    # description: KMS Emulator in C
    # processname: vlmcsd
    ### END SERVICE INFO
    
    # Source function library
    source /etc/init.d/functions
    
    # Check that networking is up.
    [ ${NETWORKING} ="yes" ] || exit 0
    
    NAME=vlmcsd
    SCRIPT=/usr/bin/vlmcsd
    RUNAS=
    
    PIDFILE=/var/run/$NAME.pid
    LOGFILE=/var/log/$NAME.log
    
    start() {
      if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE"); then
        echo 'Service already running.'
        return 1
      fi
      echo 'Starting service...'
      local CMD="$SCRIPT -p $PIDFILE -l $LOGFILE -d"
      su -c "$CMD" $RUNAS
      echo 'Service started.'
    }
    
    stop() {
      if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
        echo 'Service not running.'
        return 1
      fi
      echo 'Stopping service...'
      kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
      echo 'Service stopped.'
    }
    
    status() {
      echo "Checking $NAME service..."
      if [ -f "$PIDFILE" ]; then
        local PID=$(cat "$PIDFILE")
        kill -0 $PID
        if [ $? -eq 0 ]; then
          echo "Running, the PID is $PID."
        else
          echo 'The process appears to be dead but pidfile still exists.'
        fi
      else
        echo 'Service not running.'
      fi
    }
    
    case "$1" in
      start)
        start
        ;;
      stop)
        stop
        ;;
      status)
        status
        ;;
      restart)
        stop
        start
        ;;
      *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
    esac
    
    exit 0
    ```

4. 配置文件权限

        ```sh
        chmod 755 /usr/bin/vlmcsd
        chown root.root /usr/bin/vlmcsd
        chmod 755 /etc/init.d/vlmcsd
        chown root.root /etc/init.d/vlmcsd
        ```

5. 启动服务, 并设置自启动

        ```sh
        chkconfig --add vlmcsd
        chkconfig vlmcsd on
        service vlmcsd start
        ```

6. 如果要指定监听 IP, 可使用 `-L`

        ```sh
        ~] vi /etc/init.d/vlmcsd

        ...
        start() {
          ...
          echo 'Starting service...'
          local CMD="$SCRIPT -p $PIDFILE -l $LOGFILE -L 192.168.161.1:1688 -d"  # <= 添加 "-L 192.168.161.1:1688"
          su -c "$CMD" $RUNAS
          ...
        }
        ...
        ```
