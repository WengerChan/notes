# RPM Packaging

## 1 工作目录

* 方式一: 安装 rpmdevtools 后执行 `rpmdev-setuptree` 后生成

    ```sh
    ~] yum install rpmdevtools

    ~] useradd rpmbuilder  # 非root用户下进行rpm打包
    ~] su - rpmbuilder

    ~]$ rpmdev-setuptree
    ~]$ tree rpmbuild/
    rpmbuild/
    ├── BUILD
    ├── RPMS
    ├── SOURCES
    ├── SPECS
    └── SRPMS
    ```

* 方式二: 手动创建

    ```sh
    mkdir -p rpmbuild/{BUILD,RPMS,SRPMS,SOURCES,SPECS}
    ```

表1: 工作目录介绍

| Directory | Purpose |
| -- | -- |
| BUILD | When packages are built, various `%buildroot` directories are created here. <br>This is useful for investigating a failed build if the logs output do not provide enough information. |
| RPMS  | Binary RPMs are created here, in subdirectories for different architectures, <br>for example in subdirectories x86_64 and noarch. |
| SOURCES | Here, the packager puts *compressed source code archives* and *patches*. The `rpmbuild` command looks for them here. |
| SPECS   | The packager puts SPEC files here. |
| SRPMS   | When `rpmbuild` is used to build an SRPM instead of a binary RPM, the resulting SRPM is created here. |


## 2 SPEC 文件

SPEC 文件组成部分:

1. `Preamble`: 前言, The *Preamble* part contains a series of *metadata items* that are used in the Body part. [2.1 Preamble Items](#21-preamble-items)

2. `Body`: The *Body* part represents the main part of the instructions. [2.2 Body Items](#22-body-items)

3. `Advanced items`: Such as [2.3.1 Scriptlets](#231-scriptlets) or [2.3.2 Triggers](#232-triggers). 

生成 SPEC 文件:

1. 通过编辑文件创建

2. 使用 `.srpm` 中包含的 `.spec` 文件

3. 使用 tarball 包中包含的 `.spec` 文件

4. 使用 `rpmdev-newspec` 命令生成

    ```sh
    ~]$ rpmdev-newspec cello

    cello.spec created; type minimal, rpm version >= 4.11.
    ```

### 2.1 Preamble Items

| SPEC Directive | Definition |
| -- | :-- |
| `Name` | The base name of the package, **which should match the SPEC file name**.  |
| `Version` | The upstream version number of the software.  |
| `Release` | The number of times this version of the software was released. <br>Normally, set the initial value to `1%{?dist}`, and increment it with each new release of the package.  Reset to 1 when a new Version of the software is built. |
| `Summary` | A brief, one-line summary of the package. |
| `License` | The license of the software being packaged. GPLv2, GPLv3, BSD... |
| `URL`     | The full URL for more information about the program. Most often this is the upstream project website for the software being packaged. |
| `Source0` | Path or URL to the compressed archive of the upstream source code (unpatched, patches are handled elsewhere). <br>This should point to an accessible and reliable storage of the archive, for example, the upstream page and not the packager’s local storage. <br>If needed, more SourceX directives can be added, incrementing the number each time, for example: Source1, Source2, Source3, and so on. |
| `Patch` | The name of the first patch to apply to the source code if necessary. <br><br>The directive can be applied in two ways: with or without numbers at the end of Patch. <br><br>If no number is given, one is assigned to the entry internally. It is also possible to give the numbers explicitly using Patch0, Patch1, Patch2, Patch3, and so on. <br><br>These patches can be applied one by one using the `%patch0`, `%patch1`, `%patch2` macro and so on. <br>The macros are applied within the `%prep` directive in the *Body* section of the RPM SPEC file. <br>Alternatively, you can use the `%autopatch` macro which automatically applies all patches in the order they are given in the SPEC file. |
| `BuildArch` | If the package is not architecture dependent, for example, if written entirely in an interpreted programming language, set this to `BuildArch: noarch`. <br>If not set, the package automatically inherits<sup>继承</sup> the Architecture of the machine on which it is built, for example `x86_64`.
| `BuildRequires` | A comma(,) or whitespace-separated list of packages required for building the program written in a compiled language. <br>There can be multiple entries of `BuildRequires`, **each on its own line** in the SPEC file. |
| `Requires` | A comma-(,) or whitespace-separated list of packages required by the software to run once installed. <br>There can be multiple entries of `Requires`, **each on its own line** in the SPEC file. <br> Use "<=" and ">=", e.g.: `libxxx-devel >= 1.1.1`  |
| `ExcludeArch` | If a piece of software can not operate on a specific processor architecture, you can exclude that architecture here. |
| `Conflicts` | `Conflicts` are inverse to `Requires`. <br>If there is a package matching Conflicts, the package cannot be installed independently on whether the `Conflict` tag is on the package that has <u>already been installed</u> or on a package that is <u>going to be installed</u>. |
| `Obsoletes` | This directive alters the way updates work depending on whether the rpm command is used directly on the command line or the update is performed by an updates or dependency solver. <br>- When used on a command line, RPM removes all packages matching obsoletes of packages being installed. <br>- When using an update or dependency resolver, packages containing matching Obsoletes: are added as updates and replace the matching packages. |
| `Provides` | If `Provides` is added to a package, the package can be referred to by dependencies other than its name. |
|   |    |
| `Vendor` | 打包组织或者人员 |
| `Group` | 软件分组, 如`Applications/System`, `Applications/Internet`等 |
| `BuildRoot` | 这个是安装或编译时使用的临时目录, 即模拟安装完以后生成的文件目录：`BuildRoot: %_topdir/BUILDROOT`; 后面可使用 `$RPM_BUILD_ROOT`, `${buildroot}` 方式引用。 |
| `Prefix: %{_prefix}` | 这个主要是为了解决今后安装rpm包时, 并不一定把软件安装到rpm中打包的目录的情况。这样, 必须在这里定义该标识, 并在编写 `%install` 脚本的时候引用, 才能实现rpm安装时重新指定位置的功能 |
| `Prefix: %{_sysconfdir}` | 这个原因和上面的一样, 但由于 `%{_prefix}` 指 `/usr`, 而对于其他的文件, 例如 /etc 下的配置文件, 则需要用 `%{_sysconfdir}` 标识 |


`Name`, `Version`, 和 `Release` 组成rpm软件包版本信息, 称为 `NAME-VERSION-RELEASE`, `NVR` 或 `N-V-R`

```sh
~]$ rpm -qa bash 
bash-4.2.46-31.el7.x86_64
```

### 2.2 Body Items

| SPEC Directive | Definition |
| -- | :-- |
| `%description` | A full description of the software packaged in the RPM. This description can span multiple lines and can be broken into paragraphs. |
| `%prep` | Command or series of commands to prepare the software to be built, for example, unpacking the archive in `Source0`. <br>This directive can contain a **shell script**. |
| `%build` | Command or series of commands for building the software into **machine code** (for compiled languages) or **byte code** (for some interpreted languages). <br>`configure` + `make` |
| `%install` | Command or series of commands for copying the desired build artifacts from the `%builddir` (*where the build happens*) to the `%buildroot` directory (*which contains the directory structure with the files to be packaged*). <br>This usually means copying files from `~/rpmbuild/BUILD` to `~/rpmbuild/BUILDROOT` and creating the necessary directories in `~/rpmbuild/BUILDROOT`. <br>This is only run when creating a package, not when the end-user installs the package. <br>`make install` |
| `%check` | Command or series of commands to test the software. This normally includes things such as unit tests. |
| `%files` | The list of files that will be installed in the end user’s system. |
| `%changelog` | A record of changes that have happened to the package between different `Version` or `Release` builds. |


### 2.3 Advanced Items

#### 2.3.1 Scriptlets

* Scriptlet 指令

    | Directive | Definition |
    | -- | :-- |
    | `%pre` | Scriptlet that is executed just before installing the package on the target system. |
    | `%post` | Scriptlet that is executed just after the package was installed on the target system. |
    | `%preun` | Scriptlet that is executed just before uninstalling the package from the target system. |
    | `%postun` | Scriptlet that is executed just after the package was uninstalled from the target system. |
    | `%pretrans` | Scriptlet that is executed just before installing or removing *any package*. |
    | `%posttrans` | Scriptlet that is executed at the end of the transaction. |

* 查看 RPM 包中包含的 Sriptlet：

    * 操作系统已安装的 RPM

        ```sh
        ~] rpm -q --scripts openssh-server

        preinstall scriptlet (using /bin/sh):
        getent group sshd >/dev/null || groupadd -g 74 -r sshd || :
        getent passwd sshd >/dev/null || \
        useradd -c "Privilege-separated SSH" -u 74 -g sshd \
        -s /sbin/nologin -r -d /var/empty/sshd sshd 2> /dev/null || :
        postinstall scriptlet (using /bin/sh):

        if [ $1 -eq 1 ] ; then 
                # Initial installation 
                systemctl preset sshd.service sshd.socket >/dev/null 2>&1 || : 
        fi
        preuninstall scriptlet (using /bin/sh):

        if [ $1 -eq 0 ] ; then 
                # Package removal, not upgrade 
                systemctl --no-reload disable sshd.service sshd.socket > /dev/null 2>&1 || : 
                systemctl stop sshd.service sshd.socket > /dev/null 2>&1 || : 
        fi
        postuninstall scriptlet (using /bin/sh):

        systemctl daemon-reload >/dev/null 2>&1 || : 
        if [ $1 -ge 1 ] ; then 
                # Package upgrade, not uninstall 
                systemctl try-restart sshd.service >/dev/null 2>&1 || : 
        fi
        ```

    * 操作系统未安装的 RPM

        ```sh
        ~] rpm -q --scripts -p ./pello-0.1.1-1.el7.noarch.rpm 

        postinstall scriptlet (using /bin/sh):
        echo "hello WengerChan"
        postuninstall scriptlet (using /usr/bin/python2):
        python2 -c "print 'Uninstalled. Goodbye'"
        ```

    ---

    NOTES: 

    1. `preinstall`, `postinstall`, `preuninstall`, `postuninstall` 分别对应 SPEC 文件中的 `%pre`, `%post`, `%preun`, `%postun` 部分

    2. "`(using /bin/sh)`": 表示后续脚本的解释器使用 `/bin/sh` 执行脚本, 这是默认值。也可以使用 `-p` 指定解释器, 如 pello 这个 rpm 包中使用的是 `%postun -p /usr/bin/python2`, 指定解释器为 `/usr/bin/python2`

    3. To turn off the execution of scriptlet： `rpm --noscripts`, `--nopre`, `--nopost`, `--nopreun`, `--nopostun`, `--nopretrans`, `--noposttrans`


* Scriptlet Macros

    Scriptlet 中会使用到各种宏, 比如使用 `systemd` 相关的宏来控制服务重载

    查看系统中定义的宏 (如筛选含 "systemd" 关键字):

    ```sh
    ]$ rpm --showrc | grep systemd

    -14: __transaction_systemd_inhibit      %{__plugindir}/systemd_inhibit.so
    -14: _journalcatalogdir /usr/lib/systemd/catalog
    -14: _presetdir /usr/lib/systemd/system-preset
    -14: _unitdir   /usr/lib/systemd/system
    -14: _userunitdir       /usr/lib/systemd/user
    ...
    -14: systemd_post
    -14: systemd_postun
    -14: systemd_postun_with_restart
    -14: systemd_preun
    -14: systemd_requires
    ...
    -14: systemd_user_post  %{expand:%systemd_post \--global %%{?*}}
    -14: systemd_user_postun        %{nil}
    -14: systemd_user_postun_with_restart   %{nil}
    -14: systemd_user_preun
    ...
    ```

    查看宏的具体定义 (如查看上述含 "systemd" 的几个宏):

    * `systemd_post`
    
        ```sh
        ~]$ rpm --eval %{systemd_post}

        if [ $1 -eq 1 ] ; then 
                # Initial installation 
                systemctl preset  >/dev/null 2>&1 || : 
        fi 
        ```

    * `systemd_postun`
    
        ```sh
        ~]$ rpm --eval %{systemd_postun}

        systemctl daemon-reload >/dev/null 2>&1 || : 
        ```

    * `systemd_preun`

        ```sh
        ~]$ rpm --eval %{systemd_preun}

        if [ $1 -eq 0 ] ; then 
                # Package removal, not upgrade 
                systemctl --no-reload disable  > /dev/null 2>&1 || : 
                systemctl stop  > /dev/null 2>&1 || : 
        fi 
        ```

    *  `systemd_postun_with_restart`

        ```sh
        ~]$ rpm --eval %{systemd_postun_with_restart}

        systemctl daemon-reload >/dev/null 2>&1 || : 
        if [ $1 -ge 1 ] ; then 
                # Package upgrade, not uninstall 
                systemctl try-restart  >/dev/null 2>&1 || : 
        fi 
        ```

#### 2.3.2 Triggers

*Triggers* are RPM directives which provide a method for interaction during package installation and uninstallation. `%triggerprein`, `%triggerin`, `%triggerun`, `%triggerpostun`.

* 示例

    ```sh
    %triggerin -p /usr/bin/perl -- ruby > 2.0, perl > 5.20
    ```

    以下情况触发此段代码：

    * 已安装此包, ruby 或 perl 被安装/升级时

    * 已安装 ruby 或 perl, 此包被安装/升级时


* 触发器执行先后顺序

    ```text
    all-%pretrans
    ...
    any-%triggerprein  (%triggerprein from other packages set off by new install)
    new-%triggerprein
    new-%pre       for new version of package being installed
    ...                (all new files are installed)
    new-%post      for new version of package being installed

    any-%triggerin     (%triggerin from other packages set off by new install)
    new-%triggerin

    old-%triggerun
    any-%triggerun     (%triggerun from other packages set off by old uninstall)

    old-%preun    for old version of package being removed
    ...                (all old files are removed)s
    old-%postun   for old version of package being removed

    old-%triggerpostun
    any-%triggerpostun (%triggerpostun from other packages set off by old uninstall)
    ...
    all-%posttrans
    ```

* 查看 RPM 包中的触发器

    如查看 `tuned` 包的触发器:

    ```sh
    ~] rpm -q --triggers tuned

    triggerun scriptlet (using /bin/sh) -- tuned < 2.0-0
    # remove ktune from old tuned, now part of tuned
    /usr/sbin/service ktune stop &>/dev/null || :
    /usr/sbin/chkconfig --del ktune &>/dev/null || :
    ```

RPM 信号机制:

* `$1`

    The rpm sets `$1` argument with appropriate values to distinguish the number of rpm versions installed. 

    During fresh installation of `projectname-1.0-0`, `%install` and `%post` scripts will be called with `$1` set to `1` indicating that this is the only active version. 

    When upgraded to `projectname-1.0-1`, `%install` and `%post` scripts will be called with `$1` set to `2`. 

    After which, the `%preun` and `%postun` scripts will be called with `$1` set to `1` so as to clean up stuffs of `projectname-1.0-0`. 

    Thus by writing the spec file based on $1 value, we can handle the upgrades effectively.

    ```text
    In Pre/post
    if $1 == 1 initial installation
    if $1 == 2 upgrade

    In preun/postun
    if $1 == 0 uninstall
    if $1 == 1 upgrade
    ```

* `$2`

Inside your trigger scripts, $1, the first command-line argument, holds the number of instances of your package that will remain after the operation has completed. 

The second argument, $2, holds the number of instances of the target package that will remain after the operation. Thus, if $2 is 0, the target package will be removed. 



| Comparison           | Meaning                                                          |
| -------------------- | -----------------------------------------------------------------|
| `package < version`  | A package with a version number less than version                |
| `package > version`  | A package with a version number greater than version             |
| `package >= version` | A package with a version number greater than or equal to version |
| `package <= version` | A package with a version number less than or equal to version    |
| `package = version`  | A package with a version number equal to version                 |
| `package`            | A package at any version number                                  |





/*! \page triggers Trigger scriptlets

Triggers provide a well-defined method for packages to interact with one another at package install and uninstall time. They are an extension of the normal installation scripts (i.e. %pre) which allows one package (the "source" of the trigger package [which I often think of as the "triggered package"]) to execute an action when the installation status of another package (the "target" of the trigger) changes.

\section triggers_example A Simple Example

Say the package "mymailer" needs an /etc/mymailer/mailer symlink which points to the mail transport agent to use. If sendmail is installed, the link should point to /usr/bin/sendmail, but it vmail is installed, the link should instead point to /usr/bin/vmail. If both packages are present, we don't care where the link points (realistically, sendmail and vmail should conflict with one another), while if neither package is installed the link should not exist at all.

This can be accomplished by mymailer providing trigger scripts which move the symlink when any of the following occurs:

\verbatim
        1) sendmail is installed
        2) vmail is installed
        3) sendmail is removed
        4) vmail is removed
\endverbatim

The first two of these scripts would look like this:

\verbatim
        %triggerin -- sendmail
        ln -sf /usr/bin/sendmail /etc/mymailer/mailer

        %triggerin -- vmail
        ln -sf /usr/bin/vmail /etc/mymailer/mailer
\endverbatim

These are two installation triggers, triggered by one of sendmail or vmail.
They are run when:

\verbatim
        1) mymailer is already installed, and sendmail is installed or
           upgraded
        2) mymailer is already installed, and vmail is installed or
           upgraded
        3) sendmail is already installed, and mymailer is installed or
           upgraded
        4) vmail is already installed, and mymailer is installed or
           upgraded
\endverbatim

For the upgrading, the strategy is a little different. Rather then setting the link to point to the trigger, the link is set to point to the *other* mailer (if it exists), as follows:

\verbatim
        %triggerun -- sendmail
        [ $2 = 0 ] || exit 0
        if [ -f /usr/bin/vmail ]; then
                ln -sf /usr/bin/vmail /etc/mymailer/mailer
        else
                rm -f /etc/mymailer/mailer

        fi

        %triggerun -- vmail
        [ $2 = 0 ] || exit 0
        if [ -f /usr/bin/sendmail ]; then
                ln -sf /usr/bin/sendmail /etc/mymailer/mailer
        else
                rm -f /etc/mymailer/mailer

        fi

        %postun
        [ $1 = 0 ] && rm -f /etc/mymailer/mailer
\endverbatim

These trigger scripts get run when:

\verbatim
        1) sendmail is installed, and mymailer is removed
        2) vmail is installed, and mymailer is removed
        3) mymailer is installed, and sendmail gets removed
        4) mymailer is installed, and vmail gets removed
\endverbatim

The %postun insures that /etc/mymailer/mailer is removed when mymailer is removed (triggers get run at the same time as %preun scripts, so  doing this in the %postun is safe). Note that the triggers are testing $2 to see if any action should occur. Recall that the $1 passed to regular scripts contains the number of instances of the package which will be  installed when the operation has completed. $1 for triggers is exactly the same -- it is the number of instances of the source (or triggered) package which will remain when the trigger has completed. Similarly, $2 is the number of instances of the target package which will remain. In this case, if any of the targets will remain after the uninstall, the trigger doesn't do anything (as it's probably being triggered by an upgrade).

\section triggers_syntax Trigger Syntax

Trigger specifications are of the form:

\verbatim
        %trigger{un|in|postun} [[-n] <subpackage>] [-p <program>] -- <trigger>
\endverbatim

The -n and -p arguments are the same as for %post scripts.  The
\<trigger\> portion is syntactically equivalent to a "Requires"
specification (version numbers may be used). If multiple items are
given (comma separated), the trigger is run when *any* of those
conditions becomes true (the , can be read as "or"). For example:

\verbatim
        %triggerin -n package -p /usr/bin/perl -- fileutils > 3.0, perl < 1.2
        print "I'm in my trigger!\n";
\endverbatim

Will put a trigger in package 'package' which runs when the installation
status of either fileutils > 3.0 or perl < 1.2 is changed. The script will
be run through /usr/bin/perl rather then /bin/sh (which is the default).

\section triggers_unusual An Unusual Case

There is one other type of trigger available -- %triggerpostun. These are
triggers that are run after their target package has been removed; they will
never be run when the package containing the trigger is removed. 

While this type of trigger is almost never useful, they allow a package to
fix errors introduced by the %postun of another package (or by an earlier 
version of that package).

\section triggers_order Order of Script Execution

For reference, here's the order in which scripts are executed on a single
package upgrade:

\verbatim
  all-%pretrans
  ...
  any-%triggerprein (%triggerprein from other packages set off by new install)
  new-%triggerprein
  new-%pre      for new version of package being installed
  ...           (all new files are installed)
  new-%post     for new version of package being installed

  any-%triggerin (%triggerin from other packages set off by new install)
  new-%triggerin
  old-%triggerun
  any-%triggerun (%triggerun from other packages set off by old uninstall)

  old-%preun    for old version of package being removed
  ...           (all old files are removed)
  old-%postun   for old version of package being removed

  old-%triggerpostun
  any-%triggerpostun (%triggerpostun from other packages set off by old un
                install)
  ...
  all-%posttrans
\endverbatim
*/




* Epoch


* Macros

> Refer to: [RPM-macros](./Linux-rpm-macros.md)








* `e.g.` An example SPEC file for the bello program written in bash

    * file: `bello`, `LICENSE`

        ```sh
        #!/bin/bash

        printf "Hello World\n"
        ```
    * Package: `bello-0.1.tar.gz`

    * spec file

        ```spec
        Name:           bello
        Version:        0.1
        Release:        1%{?dist}
        Summary:        Hello World example implemented in bash script

        License:        GPLv3+
        URL:            https://www.example.com/%{name}
        Source0:        https://www.example.com/%{name}/releases/%{name}-%{version}.tar.gz

        Requires:       bash

        BuildArch:      noarch

        %description
        The long-tail description for our Hello World Example implemented in
        bash script.

        %prep
        %setup -q

        %build

        %install

        mkdir -p %{buildroot}/%{_bindir}

        install -m 0755 %{name} %{buildroot}/%{_bindir}/%{name}

        %files
        %license LICENSE
        %{_bindir}/%{name}

        %changelog
        * Tue May 31 2016 Adam Miller <maxamillion@fedoraproject.org> - 0.1-1
        - First bello package
        - Example second item in the changelog for version-release 0.1-1
        ```

* `e.g.` An example SPEC file for the pello program written in Python

    * file: `pello.py`, `LICENSE`

        ```python
        #!/usr/bin/python3

        print("Hello World")
        ```

    * Package: `pello-0.1.1.tar.gz`

    * spec file

        ```spec
        Name:           pello
        Version:        0.1.1
        Release:        1%{?dist}
        Summary:        Hello World example implemented in Python

        License:        GPLv3+
        URL:            https://www.example.com/%{name}
        Source0:        https://www.example.com/%{name}/releases/%{name}-%{version}.tar.gz

        BuildRequires:  python
        Requires:       python
        Requires:       bash

        BuildArch:      noarch

        %description
        The long-tail description for our Hello World Example implemented in Python.

        %prep
        %setup -q

        %build

        python -m compileall %{name}.py

        %install

        mkdir -p %{buildroot}/%{_bindir}
        mkdir -p %{buildroot}/usr/lib/%{name}

        cat > %{buildroot}/%{_bindir}/%{name} <<EOF
        #!/bin/bash
        /usr/bin/python /usr/lib/%{name}/%{name}.pyc
        EOF

        chmod 0755 %{buildroot}/%{_bindir}/%{name}

        install -m 0644 %{name}.py* %{buildroot}/usr/lib/%{name}/

        %files
        %license LICENSE
        %dir /usr/lib/%{name}/
        %{_bindir}/%{name}
        /usr/lib/%{name}/%{name}.py*

        %changelog
        * Tue May 31 2016 Adam Miller <maxamillion@fedoraproject.org> - 0.1.1-1
        - First pello package
        ```

* `e.g.` An example SPEC file for the cello program written in C

    * file: `cello.c`, `LICENSE`, `Makefile`

        ```c
        #include <stdio.h>

        int main(void) {
            printf("Hello World\n");
            return 0;
        }
        ```

        ```makefile
        cello:
        	gcc -g -o cello cello.c
        
        clean:
        	rm cello
        
        install:
        	mkdir -p $(DESTDIR)/usr/bin
        	install -m 0755 cello $(DESTDIR)/usr/bin/cello
        ```

    * patch: `cello-output-first-patch.patch`

        ```patch
        --- cello.c.orgi        2022-02-09 09:04:56.986000000 +0800
        +++ cello.c     2022-02-09 09:05:40.672000000 +0800
        @@ -1,6 +1,6 @@
         #include <stdio.h>
         
         int main(void) {
        -    printf("Hello World\n");
        +    printf("Hello World from kvm_centos_7.6\n");
             return 0;
         }
        ```

    * package: `cello-1.0.tar.gz`

    * spec file:

        ```spec
        Name:           cello
        Version:        1.0
        Release:        1%{?dist}
        Summary:        Hello World example implemented in C

        License:        GPLv3+
        URL:            https://www.example.com/%{name}
        Source0:        https://www.example.com/%{name}/releases/%{name}-%{version}.tar.gz

        Patch0:         cello-output-first-patch.patch

        BuildRequires:  gcc
        BuildRequires:  make

        %description
        The long-tail description for our Hello World Example implemented in C.

        %prep
        %setup -q

        %patch0

        %build
        make %{?_smp_mflags}

        %install
        %make_install

        %files
        %license LICENSE
        %{_bindir}/%{name}

        %changelog
        * Tue May 31 2016 Adam Miller <maxamillion@fedoraproject.org> - 1.0-1
        - First cello package
        ```

### 2.2 File

* 将源码包(`LICENSE`文件也在源码包中)和补丁包放入 `rpmbuild/SOURCE`

* 将 `.spec` 文件放入 `rpmbuild/SPEC`

## 3 Building

* Building source RPMs

    ```sh
    cd ~/rpmbuild/SPECS/
    rpmbuild -bs SPECFILE
    ```

* Building binary RPMs

    * Rebuilding a binary RPM from a source RPM(SRPM)

        ```sh
        rpmbuild --rebuild ~/rpmbuild/SRPMS/bello-0.1-1.el8.src.rpm
        ```

    * Building a binary RPM from the SPEC file

        ```sh
        rpmbuild -bb <SPECFILE>
        ```

    * Building RPMs from source RPMs<sup>创建出多个rpms</sup>

        man page: rpmbuild(8), 实际没有过多信息, 此处待补充

* Building RPMs and SRPMS

    ```sh
    rpmbuild -ba <SPECFILE>
    ```

* Checking RPMs for sanity

    使用 `rpmlint`, 可以对 `.rpm`, `.srpm`包和`.spec`文件进行完整性检查, 加上 `-i` 选项可显示错误简介

    When checking binary RPMs, `rpmlint` checks for the following items:

    * Documentation
    * Manual pages
    * Consistent use of the Filesystem Hierarchy Standard

    `rpmlint` 判断比较严格, 根据实际情况可以忽略掉一些提示错误

    ```sh
    ~/rpmbuild/RPMS]$ rpmlint x86_64/cello-1.0-1.el7.x86_64.rpm 
    cello.x86_64: W: invalid-url URL: https://www.example.com/cello <urlopen error [Errno -2] Name or service not known>
    cello.x86_64: W: no-documentation
    cello.x86_64: W: no-manual-page-for-binary cello
    1 packages and 0 specfiles checked; 0 errors, 3 warnings.
    
    ~/rpmbuild/RPMS]$ rpmlint -i x86_64/cello-1.0-1.el7.x86_64.rpm 
    cello.x86_64: W: invalid-url URL: https://www.example.com/cello <urlopen error [Errno -2] Name or service not known>
    The value should be a valid, public HTTP, HTTPS, or FTP URL.

    cello.x86_64: W: no-documentation
    The package contains no documentation (README, doc, etc). You have to include
    documentation files.

    cello.x86_64: W: no-manual-page-for-binary cello
    Each executable in standard binary directories should have a man page.

    1 packages and 0 specfiles checked; 0 errors, 3 warnings.
    ```

## 4 Signing Packages

* **Generate** a gpg

    ```sh
    ]$ gpg --gen-key

    gpg (GnuPG) 2.0.22; Copyright (C) 2013 Free Software Foundation, Inc.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
    
    Please select what kind of key you want:
       (1) RSA and RSA (default)
       (2) DSA and Elgamal
       (3) DSA (sign only)
       (4) RSA (sign only)
    Your selection? 1                                     # <= 1
    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048) 
    Requested keysize is 2048 bits
    Please specify how long the key should be valid.
             0 = key does not expire
          <n>  = key expires in n days
          <n>w = key expires in n weeks
          <n>m = key expires in n months
          <n>y = key expires in n years
    Key is valid for? (0) 0                                # <= 0
    Key does not expire at all
    Is this correct? (y/N) y                               # <= y
    
    GnuPG needs to construct a user ID to identify your key.
    
    Real name: companytest, Inc.                               # <= companytest, Inc.
    Email address: chenwen1@com.cn                             # <= chenwen1@com.cn
    Comment: companytest, Inc. @ XiTongPingTaiShi Signing Keys # <= companytest, Inc. @ XiTongPingTaiShi Signing Keys
    You selected this USER-ID:
        "companytest, Inc. (companytest, Inc. @ XiTongPingTaiShi Signing Keys) <chenwen1@com.cn>"
    
    Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O  # <= O
    You need a Passphrase to protect your secret key.      # <= password
    ....
    gpg: key F426ACE9 marked as ultimately trusted         # Key ID.
    public and secret key created and signed.              # Successfully.
    ...                                                    # Information of new GPG.
    pub   2048R/F426ACE9 2022-02-11
        Key fingerprint = C823 C1F1 3C69 F688 73A1  9895 8E15 0099 F426 ACE9
    uid                  companytest, Inc. (companytest, Inc. @ XiTongPingTaiShi Signing Keys) <chenwen1@com.cn>
    sub   2048R/1970529B 2022-02-11
    ```

* **Export** the Public key and <sup>Optional</sup>secrect Key.  

    > **注:** 如果只是在本机上给rpm包签名, 无需导入公钥和私钥; 导出的公钥和私钥只是为了后续方便在其他服务器上使用

    * Public Key
    
        ```sh
        # 查询
        gpg -k
        gpg --list-keys
        gpg --list-public-keys
        
        # 导出
        gpg -a "<Key-Name|Key-ID>" --export > RPM-GPG-KEY-<NAME>     # "-a"="--armor", 以ASCII而不是默认的二进制的形式输出; "-o"="--output", 指定写入的文件 
        gpg -a -o "<Output-File-Name>" --export "<Key-Name|Key-ID>"  # 只有一个gpg时, "<Key-Name|Key-ID>" 可省略不写

        # e.g.
        gpg -a "companytest, Inc." --export > RPM-GPG-KEY-Essence
        ```

    * Secrect Key

        ```sh
        # 查看
        gpg -K
        gpg --list-secret-keys
        
        # 导出
        gpg -a -o "<Output-File-Name>" --export-secret-keys
        ```

* **Import** the exported public key into `rpm` database as follows: 

    > **注:** 如果只是在本机上给rpm包签名, 无需导入公钥和私钥; 导出的公钥和私钥只是为了后续方便在其他服务器上使用

    ```sh
    ~] rpm --import RPM-GPG-KEY-Essence

    ~] rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'
    gpg-pubkey-f4a80eb5-53a7ff4b --> gpg(CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>)
    gpg-pubkey-f426ace9-6206021b --> gpg(companytest, Inc. (companytest, Inc. @ XiTongPingTaiShi Signing Keys) <chenwen1@com.cn>)
    ```

* Edit the file `~/.rpmmacros` in order to **utilize** the key.

    ```sh
    ~]$ cat ~/.rpmmacros 

    %_signature gpg
    %_gpg_name companytest, Inc.

    %_gpg_path /root/.gnupg
    %_gpgbin /usr/bin/gpg2
    %__gpg_sign_cmd %{__gpg} gpg --force-v3-sigs --batch --verbose --no-armor --passphrase-fd 3 --no-secmem-warning -u "%{_gpg_name}" -sbo %{__signature_filename} --digest-algo sha256 %{__plaintext_filename}'
    ```

    > **注**: 经测试, 配置 `%_signature`和 `%_gpg_name` 两个宏即可正常进行签名; 查询红帽文档 [How to sign rpms with GPG](https://access.redhat.com/articles/3359321), 还提供了 `%_gpg_path`, `%_gpgbin`, `%__gpg_sign_cmd`三个宏设置, 可按情况配置

    如果在签名时, 不想使用`~/.rpmmacros`配置中的 `%_gpg_name`, 可以在 `rpmbuild --define` 定义新的 `%_gpg_name` 以覆盖`~/.rpmmacros`文件的配置


* **Sign** the rpm

    ```sh
    rpm --addsign bello-0.1-1.el7.noarch.rpm  # Add
    rpm --resign bello-0.1-1.el7.noarch.rpm   # Replace (replace all signatures)

    rpm --define "_gpg_name companytest, Inc." --addsign ./RPMS/noarch/bello-0.1-1.el7.noarch.rpm

    rpm --addsign ?ello*.rpm
    rpm --resign ?ello*.rpm
    ```


* Products based on RPM use GPG signing keys. Run the following command to **verify** an RPM package:

    ```sh
    ~] rpm --checksig openssh-7.4p1-16.el7.x86_64.rpm   # --check 等价于 -K
    openssh-7.4p1-16.el7.x86_64.rpm: rsa sha1 (md5) pgp md5 OK  # rpm < 4.1 允许一个rpm有多个签名, 此时检查时出现几个pgp就证明有几个签名

    # Or use:
    ~] rpm -q --qf '%{SIGPGP:pgpsig}\n' -p openssh-7.4p1-16.el7.x86_64.rpm
    RSA/SHA256, Wed 25 Apr 2018 07:32:50 PM CST, Key ID 24c6a8a7f4a80eb5

    # To see a litter more information, use `-v` option
    ~] rpm --checksig -v openssh-7.4p1-16.el7.x86_64.rpm
    openssh-7.4p1-16.el7.x86_64.rpm:
        Header V3 RSA/SHA256 Signature, key ID f4a80eb5: OK               # <= Signing Key ID
        Header SHA1 digest: OK (807e6ff3b67ac16fae28f6881c98b6d2a5392794)
        V3 RSA/SHA256 Signature, key ID f4a80eb5: OK                      # <= Signing Key ID
        MD5 digest: OK (805b1fb17b3b7a41b2df9fd89b75e377)

    # To see much more information, use `-vv` option
    ~] rpm --checksig -vv openssh-7.4p1-16.el7.x86_64.rpm
    ...
    D:  read h#     357 Header SHA1 digest: OK (489efff35e604042709daf46fb78611fe90a75aa)   # 系统总共导入了4个gpg公钥
    D: added key gpg-pubkey-f4a80eb5-53a7ff4b to keyring
    D:  read h#     362 Header SHA1 digest: OK (743138e2ec43551793c2dda50ded34fe0a08ee7a)
    D: added key gpg-pubkey-a8283b2f-6205f2f1 to keyring
    D:  read h#     364 Header SHA1 digest: OK (f66c5b7a40ef3e1ed46fbf4575feab9e00ccd06c)
    D: added key gpg-pubkey-80ca0fd4-6205f738 to keyring
    D:  read h#     366 Header SHA1 digest: OK (5b273b3b11623ee3a4b7c5bb6261d5ddef9c93a9)
    D: added key gpg-pubkey-1eab8f7a-6205faa7 to keyring
    ...                             # 以下信息和 -v 一致
    openssh-7.4p1-16.el7.x86_64.rpm:
        Header V3 RSA/SHA256 Signature, key ID f4a80eb5: OK
        Header SHA1 digest: OK (807e6ff3b67ac16fae28f6881c98b6d2a5392794)
        V3 RSA/SHA256 Signature, key ID f4a80eb5: OK
        MD5 digest: OK (805b1fb17b3b7a41b2df9fd89b75e377)
    ...
    ```

    The output of this command shows whether the package is signed and which key signed it.


## 5 Advancd Topics






需要注意的几点:


* 1. `${SOURCE_PATH}/contrib/redhat/sshd.pam` 中的内容不完整, 替换系统的 `/etc/pam.d/sshd` 后会引起 sshd 不可用, 需要在制作rpm包修改

    ```sh
    install -m644 contrib/redhat/sshd.pam     $RPM_BUILD_ROOT/etc/pam.d/sshd  # <= 注释此行
    # 
    SourceN: sshd.pam        # <= "简介节点" 处添加配置此行配置; N 为具体的数字, 根据实际情况配置
    install -m644 $RPM_SOURCE_DIR/sshd.pam    $RPM_BUILD_ROOT/etc/pam.d/sshd  # 将准备好的sshd pam配置文件放到 "rpmbuild/SOURCES/"
    ```

    ```sh
    CentOS 7.6 ~] cat /etc/pam.d/sshd
    #%PAM-1.0
    auth       required     pam_sepermit.so
    auth       substack     password-auth
    auth       include      postlogin
    # Used with polkit to reauthorize users in remote sessions
    -auth      optional     pam_reauthorize.so prepare
    account    required     pam_nologin.so
    account    include      password-auth
    password   include      password-auth
    # pam_selinux.so close should be the first session rule
    session    required     pam_selinux.so close
    session    required     pam_loginuid.so
    # pam_selinux.so open should only be followed by sessions to be executed in the user context
    session    required     pam_selinux.so open env_params
    session    required     pam_namespace.so
    session    optional     pam_keyinit.so force revoke
    session    include      password-auth
    session    include      postlogin
    # Used with polkit to reauthorize users in remote sessions
    -session   optional     pam_reauthorize.so prepare
    ```

