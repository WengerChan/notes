# Ubuntu

## 安装

虚拟机化环境, 安装后需删除部分不需要的软件:

```sh
apt purge cloud-init
apt purge cloud-guest-utils
apt purge open-vm-tools open-vm-tools-dev
```

## 软件/补丁源

* 本地 ISO 源

    * 清空或者注释 `/etc/apt/sources.list` 内容

    * 挂载 ISO 至 /media/cdrom

        ```sh
        mount /dev/cdrom /media/cdrom
        ```

    * 添加本地目录到软件源

        ```sh
        sudo apt-cdrom -m -d=/media/cdrom add
        apt-get update
        ```

        `apt-cdrom` 命令会在 `/etc/apt/sources.list` 中添加以下行:

        ```text
        deb cdrom:[Ubuntu-Server 16.04.7 LTS _Xenial Xerus_ - Release amd64 (20200810)]/ xenial main restricted
        ```

* 远程软件源

    > 可以在软件/补丁源服务器上, 通过挂载 ISO 或者向 Ubuntu 官方/国内在线源服务器同步等方式搭建

    主要看 `ubuntu/dist` 目录下拥有哪些目录, 就可以配置哪些目录.

    方法一: 使用命令添加

    ```sh
    # ISO
    apt-add-repository "http://192.168.161.1:8800/ubuntu16.04.7 main restricted"
    ```

    方法二: 编辑配置文件

    ```sh
    ~] vi /etc/apt/sources.list

    deb http://192.168.161.1:8800/ubuntu16.04.7 xenial main restricted
    ```

## Server and Desktop Differences

The *Ubuntu Server Edition* and the *Ubuntu Desktop Edition* use the same apt repositories, making it just as easy to install a *server* application on the Desktop Edition as on the Server Edition.

One major difference is that the graphical environment used for the Desktop Edition is not installed for the Server. This includes the graphics server itself, the graphical utilities and applications, and the various user-supporting services needed by desktop users.


## Package Management

### apt

```text
Most used commands:
  list         - list packages based on package names
  search       - search in package descriptions
  show         - show package details
  install      - install packages
  reinstall    - reinstall packages
  remove       - remove packages
  autoremove   - Remove automatically all unused packages
  update       - update list of available packages
  upgrade      - upgrade the system by installing/upgrading packages
  full-upgrade - upgrade the system by removing/installing/upgrading packages
  edit-sources - edit the source information file
  satisfy      - satisfy dependency strings
  purge        - ="remove --purge", 删除软件的同时删除配置文件
```

### dpkg

```text
Usage: dpkg [<option> ...] <command>

Commands:
  -i|--install       <.deb file name>... | -R|--recursive <directory>...
  -r|--remove        <package>... | -a|--pending
  -P|--purge         <package>... | -a|--pending
  -s|--status [<package>...]       Display package status details.
  -p|--print-avail [<package>...]  Display available version details.
  -L|--listfiles <package>...      List files 'owned' by package(s).
  -l|--list [<pattern>...]         List packages concisely.
  -S|--search <pattern>...         Find package(s) owning file(s).

Options:
  --admindir=<directory>     Use <directory> instead of /var/lib/dpkg.
  --root=<directory>         Install on a different root directory.
  --instdir=<directory>      Change installation dir without changing admin dir.
  --path-exclude=<pattern>   Do not install paths which match a shell pattern.
  --path-include=<pattern>   Re-include a pattern after a previous exclusion.
  -O|--selected-only         Skip packages not selected for install/upgrade.
  -E|--skip-same-version     Skip packages whose same version is installed.
  -G|--refuse-downgrade      Skip packages with earlier version than installed.
  -B|--auto-deconfigure      Install even if it would break some other package.
  --[no-]triggers            Skip or force consequential trigger processing.
  --verify-format=<format>   Verify output format (supported: 'rpm').
  --no-debsig                Do not try to verify package signatures.
  --no-act|--dry-run|--simulate
                             Just say what we would do - don't do it.
  --force-...                Override problems (see --force-help).
  --no-force-...|--refuse-...
                             Stop when problems encountered.
  --abort-after <n>          Abort after encountering <n> errors.

Comparison operators for --compare-versions are:
  lt le eq ne ge gt       (treat empty version as earlier than any version);
  lt-nl le-nl ge-nl gt-nl (treat empty version as later than any version);
  < << <= = >= >> >       (only for compatibility with control file syntax).

Use 'apt' or 'aptitude' for user-friendly package management.
```