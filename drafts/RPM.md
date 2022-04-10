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

表: 工作目录介绍

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


### 2.3 Advanced Topic

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

* 查看 RPM 包中包含的 Sriptlet

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

    * 已安装此包, `ruby` 或 `perl` 被安装/升级时 ( `ruby` 的版本应该大于 2.0, `perl` 的版本应该大于 5.20)

    * 已安装 `ruby` 或 `perl`, 此包被安装/升级时

    | Comparison           | Meaning                                                          |
    | -------------------- | -----------------------------------------------------------------|
    | `package < version`  | A package with a version number less than version                |
    | `package > version`  | A package with a version number greater than version             |
    | `package >= version` | A package with a version number greater than or equal to version |
    | `package <= version` | A package with a version number less than or equal to version    |
    | `package = version`  | A package with a version number equal to version                 |
    | `package`            | A package at any version number                                  |


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


#### 2.3.3 Epoch

`epoch` 定义 RPM 包的额外版本号, 其优先级比 `version` 和 `release` 高

需要注意的是, 如果在 SPEC 中未定义 `epoch` 和在 SPEC 文件中定义 `epoch` 为 0 是不同的, 例如定义 `epoch` 为 0 时, 使用 `rpm` 可以查询到 `${EPOCH}` 值为 0, 而没有定义则查询不到

YUM 进行事务操作时会将未设置 `epoch` 的 RPM 包当作设置了 `epoch` 为 0 来方便比较


* 关于 RPM 包版本号比较

    版本号表示格式为 "`epoch:version-release`", 如: `1:2-3`; 通常情况下 `epoch` 信息不会显示在 RPM 包的名字里:

    ```sh
    ~] rpm -qa vim-enhanced

    vim-enhanced-7.4.629-8.el7_9.x86_64
    ```

    可以通过下面的两种方法命令来查看 `epoch` 的值:

    ```sh
    ~] rpm -q vim-enhanced --queryformat '%{EPOCH}\n' 
    2

    ~] yum list vim-enhanced
    ...
    vim-enhanced.x86_64        2:7.4.629-8.el7_9            @updates
    ```

    版本比对原则:

    > [https://blog.csdn.net/RHEL_admin/article/details/37592971](https://blog.csdn.net/RHEL_admin/article/details/37592971)

    * 1 属性优先级

        先比较 `epoch`, 然后比较 `version`, 最后比较 `release`

        ```text
        1:1-1 > 0:2-2  # 比较 epoch
        0:2-1 > 0:1-3  # 比较 version
        0:1-2 > 0:1-1  # 比较 release
        ```

    * 2 版本号字段列表分隔模式

        除 `epoch` 属性之外, `version` 和 `release` 可能不单单包含数字, 也可能含有字符串, 例如 `1.0alpha1`, `2.0.0+svn12221`

        遇到这种情况时, 版本号字段会被分隔为列表。分隔策略是: *数字与字符串分开, 形成自然分隔边界, 点号/加号/减号/下划线作为分隔符*。
        
        * `1.0alpha1` 会分为 `[ 1, 0, alpha, 1 ]`
        * `2.0.0+svn12221` 会分为 `[ 2, 0, 0, svn, 12221 ]`

        这样子分隔的目的是为了列表相应分段进行比较: 比较的优先级按照列表的下标顺序自然排序, 第一位的优先级最高, 后面依次降低。如果两个列表可比较的分段经过比较后都相等, 那么列表长的比列表短的新, 如果列表长度也一样, 那么这两个版本号字段相等。

        ```text
        1.2.0 > 1.1.9       ( [1, 2, 0]  中第2分段的 "2" > [1, 1, 9] 中第 2 分段的 "1" )
        1.12.1 > 1.9beta2   ( [1, 12, 1] 中第2分段的 "12" > [1, 9, beta, 2] 中第 2 分段的 "9" )
        3.1.0 > 3.1         ( [3, 1, 0] 的列表长度 3 > [3,1] 的列表长度 2 )
        ```

    * 3 列表分段比较算法

        此算法是在 *原则 2* 基础上针对字符串和数字比较的原则

        * 如果是数和数比较, 那么两个串会看作两个整数进行自然数比较, *前导的零会被忽略*: `"12" -> 12`, `"00010" -> 10`
        * 如果是字符串和字符串比较, 那么会进行如同 C 语言 `strcmp()` 函数的逻辑, 按照 ACSII 码顺序得出, *排在后面的为新版本*, *小写字母比大写字母新*
        * 如果是字符串和数比较, 那么 *认定数字比字符串新*

        ```text
        123 > 121
        svn > rc
        alpha > Beta
        0 > beta
        ```


    具体的例子:

    ```text
    1.00010 > 1.9     因为 10 > 9
    2.02 = 2.2        因为 02 = 2
    3.4.0 > 3.4       因为 3.4.0 多出一个列表分段
    5mgc25 = 5.mgc.25 因为分隔后的列表两者相等
    6.0 > 6beta       因为数字比字符串新
    ```


#### 2.3.4 Macros

> Refer to: [RPM Macros](#rpm-macros)


#### 2.3.5 Conditionals

> 条件判断

* Syntax

    ```text
    %if expression
    ...
    %endif
    ```

    or

    ```text
    %if expression
    ...
    %else
    ...
    %endif
    ```

    or `%ifarch`, `%ifnarch`, `%ifos`

* Examples

    ```text
    %if 0%{?rhel} == 8
    sed -i '/AS_FUNCTION_DESCRIBE/ s/^//' configure.in sed -i '/AS_FUNCTION_DESCRIBE/ s/^//' acinclude.m4
    %endif
    ```

    ```text
    %define ruby_archive %{name}-%{ruby_version}
    %if 0%{?milestone:1}%{?revision:1} != 0
    %define ruby_archive %{ruby_archive}-%{?milestone}%{?!milestone:%{?revision:r%{revision}}}
    %endif
    ```


    ```text
    %ifarch i386 sparc  # 当架构为 i386 或者 sparc 时执行
    ...
    %endif

    %ifnarch alpha      # 当架构不为 alpha 时执行
    ...
    %endif

    %ifos linux         # 当系统为 linux 时执行
    ...
    %endif
    ```

### 2.4 SPEC 文件示例


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

## 3 Building

> 编译前, 应该: 将源码包 ( `LICENSE` 文件也在源码包中) 和补丁包都放入 `rpmbuild/SOURCE`, 同时将 `filename.spec` 文件放入 `rpmbuild/SPEC`

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


---

## A. RPM Macros

> https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/

RPM provides a rich set of macros to make package maintenance simpler and consistent across packages. For example, it includes *a list of default path definitions* which are used by the build system macros, and definitions for RPM package build specific directories. They usually should be used instead of hard-coded directories. It also provides the default set of compiler flags as macros, which should be used when compiling manually and not relying on a build system.

```sh
~]$ rpm --eval "some text printed on %{_arch}"
some text printed on x86_64

~]$ rpm --define 'test Hello, World!' --eval "%{test}"
Hello, World!
```

### A.1 宏定义相关的文件

* 1.1 直接定义类

    ```sh
    # 优先级顺序如下
    1. 当前文件中定义: 如spec文件中 %define dist .centos
    2. 命令中定义: rpm --define "_arch my_arch" --eval "%{_arch}"
    3. 用户自定义相关:  ~/.rpmmacros
    4. 系统相关的配置:  /etc/rpm/
    5. 全局扩展配置:   /usr/lib/rpm/macros.d/*
    6. 全局的配置:     /usr/lib/rpm/macros, /usr/lib/rpm/redhat/macros
    ```

* 2.2 通过macrofiles引用类

    ```sh
    /usr/lib/rpm/rpmrc
    /usr/lib/rpm/redhat/rpmrc
    /etc/rpmrc
    ~/.rpmrc

    # rpmrc主要是用来定义一些跟平台特型相关的一些选项: 如optflags引用的是"i686" ，则optflags的值就是: "-O2 -g -march=i686"
    optflags: i386 -O2 -g -march=i386 -mtune=i686
    optflags: i686 -O2 -g -march=i686
    ```

定义macrofiles:

> 注: 需要在编译阶段定义 `MACROFILES`，否则会加载默认的路径

```sh
macrofiles: /usr/lib/rpm/macros:/etc/rpm/macros
```

### A.2 Macros syntax

> [https://rpm-software-management.github.io/rpm/manual/macros.html](https://rpm-software-management.github.io/rpm/manual/macros.html)

* Defining a Macro

    ```text
    %global <name>[(opts)] <body>
    %define <name>[(opts)] <body>
    ```

    * All whitespace surrounding `<body>` is removed.
    * Name may be composed of alphanumeric(`0-9,a-z,A-Z`) characters, and the character "`_`" and must be **at least 3 characters** in length.
    * Inclusion of the (opts) field is optional:
        * `Simple` macros do not contain the `(opts)` field. In this case, only recursive macro expansion is performed. 
        * `Parametrized` macros contain the `(opts)` field. The `opts` string  is passed to `getopt(3)` for `argc/argv` processing at the beginning of a macro invocation.
    * "`–`" can be used to separate options from arguments. While a parameterized macro is being expanded, the following shell-like macros are available:

        ```spec
        %0       the name of the macro being invoked
        %*       all arguments (unlike shell, not including any processed flags)
        %#       the number of arguments
        %{-f}    if present at invocation, the flag f itself
        %{-f*}   if present at invocation, the argument to flag f
        %1, %2   the arguments themselves (after getopt(3) processing)
        ```

    * Within the body of a macro, there are several constructs that permit testing for the presence of optional parameters. 

        * The simplest construct is "`%{-f}`" which expands (literally) to "`-f`" if `-f` was mentioned when the macro was invoked. 
        * There are also provisions for including text if flag was present using "`%{-f:X}`". This macro expands to (the expansion of) `X` if the flag was present. 
        * The negative form, "`%{!-f:Y}`", expanding to (the expansion of) `Y` if `-f` was not present, is also supported.
        * In addition to the "`%{…}`" form, shell expansion can be performed using "`%(shell command)`".

* Builtin Macros

    There are several builtin macros (with reserved names) that are needed to perform useful operations. The current list is:

    ```text
        %trace          toggle print of debugging information before/after expansion
        %dump           print the active (i.e. non-covered) macro table
        %getncpus       return the number of CPUs
        %getconfdir     expand to rpm "home" directory (typically /usr/lib/rpm)
        %dnl            discard to next line (without expanding)
        %verbose        expand to 1 if rpm is in verbose mode, 0 if not
        %{verbose:...}  expand to ... if rpm is in verbose mode, the empty string if not

        %{echo:...}    print ... to stdout
        %{warn:...}    print warning: ... to stderr
        %{error:...}    print error: ... to stderr and return an error
    
        %define ...    define a macro
        %undefine ...  undefine a macro
        %global ...    define a macro whose body is available in global context

        %{macrobody:...}    literal body of a macro

        %{basename:...}   basename(1) macro analogue
        %{dirname:...}    dirname(1) macro analogue
        %{exists:...}     test file existence, expands to 1/0
        %{suffix:...}     expand to suffix part of a file name
        %{url2path:...}   convert url to a local path
        %{getenv:...}     getenv(3) macro analogue
        %{uncompress:...} expand ... to <file> and test to see if <file> is compressed. The expansion is
                    cat <file>        # if not compressed
                    gzip -dc <file>   # if gzip'ed
                    bzip2 -dc <file>  # if bzip'ed

                    e.g. ~]$ rpm --eval "%{uncompress:pello-0.1.1.tar.gz}"
                        /usr/bin/gzip -dc pello-0.1.1.tar.gz

        %{load:...}      load a macro file
        %{lua:...}       expand using the [embedded Lua interpreter](/rpm/manual/lua.html)
        %{expand:...}    like eval, expand ... to <body> and (re-)expand <body>
        %{expr:...}      evaluate an expression
        %{shescape:...}  single quote with escapes for use in shell
        %{shrink:...}    trim leading and trailing whitespace, reduce intermediate whitespace to a single space
        %{quote:...}     quote a parametric macro argument, needed to pass empty strings or strings with whitespace

        %{S:...}   expand ... to <source> file name
        %{P:...}   expand ... to <patch> file name
    ```

* Conditionally Expanded Macros

    Sometimes it is useful to test whether a macro is defined or not. Syntax:

    ```text
        %{?macro_name:value}
        %{?!macro_name:value}
    ```

    can be used for this purpose. `%{?macro_name:value}` is expanded to "*value*" if "*macro_name*" is defined, otherwise it is expanded to the *empty string*. `%{?!macro_name:value}` is the negative variant. It is expanded to "*value*" if "*macro_name*" not is defined, therwise it is expanded to the *empty string*.

    Frequently used conditionally expanded macros are: 

    `e.g.` Define a macro if it is not defined:

    ```text
        %{?!with_python3: %global with_python3 1}
    ```

    A macro that is expanded to 1 if "*with_python3*" is defined and *0* otherwise:

    ```text
        %{?with_python3:1}%{!?with_python3:0}
    ```

    or shortly

    ```text
        0%{!?with_python3:1}
    ```

    "`%{?macro_name}`" is a shortcut for "`%{?macro_name:%macro_name}`".

    For more complex tests, use `expressions` or `Lua`. Note that `%if`, `%ifarch` and the like are not macros, they are spec directives and only usable in that context.

    Note that in `rpm >= 4.17`, conditionals on built-in macros simply test for existence of that built-in, just like with any other macros. In older versions, the behavior of conditionals on built-ins is undefined.

* Example of a Macro

    Here is an example `%patch` definition from `/usr/lib/rpm/macros`:

    ```text
        %patch(b:p:P:REz:) \
        %define patch_file	%{P:%{-P:%{-P*}}%{!-P:%%PATCH0}} \
        %define patch_suffix	%{!-z:%{-b:--suffix %{-b*}}}%{!-b:%{-z:--suffix %{-z*}}}%{!-z:%{!-b: }}%{-z:%{-b:%{error:Can't specify both -z(%{-z*}) and -b(%{-b*})}}} \
            %{uncompress:%patch_file} | patch %{-p:-p%{-p*}} %patch_suffix %{-R} %{-E} \
        ...
    ```

    The first line defines `%patch` with its options. 

    The body of `%patch` is

    ```text
        %{uncompress:%patch_file} | patch %{-p:-p%{-p*}} %patch_suffix %{-R} %{-E}
    ```

    The body contains 7 macros, which expand as follows

    ```test
        %{uncompress:...}   copy uncompressed patch to stdout
        %patch_file       ... the name of the patch file
        %{-p:...}           if "-p N" was present, (re-)generate "-pN" flag
        -p%{-p*}          ... note patch-2.1 insists on contiguous "-pN"
        %patch_suffix       override (default) ".orig" suffix if desired
        %{-R}               supply -R (reversed) flag if desired
        %{-E}               supply -E (delete empty?) flag if desired
    ```

    There are two "`private`" helper macros: (`%define` means local macro.)

    ```text
        %patch_file	the gory details of generating the patch file name
        %patch_suffix	the gory details of overriding the (default) ".orig"
    ```

* Using a Macro

    To use a macro, write:

    ```text
        %<name> ...
    ```
    or

    ```text
        %{<name>}
    ```

    The `%{…}` form allows you to place the expansion adjacent to other text. The `%<name>` form, if a parameterized macro, will do argc/argv processing of the rest of the line as described above. Normally you will likely want to invoke a parameterized macro by using the `%<name>` form so that parameters are expanded properly.

    Example:

    ```text
        %define mymacro() (echo -n "My arg is %1" ; sleep %1 ; echo done.)
    ```

    Usage:

    ```text
        %mymacro 5
    ```

    This expands to:

    ```text
        (echo -n "My arg is 5" ; sleep 5 ; echo done.)
    ```

    This will cause all occurrences of `%1` in the macro definition to be replaced by the first argument to the macro, but only if the macro is invoked as "`%mymacro 5`". Invoking as "`%{mymacro} 5`" will not work as desired in this case, and you should use "`%{mymacro 5}`"

* Shell Expansion

    Shell expansion can be performed using "`%(shell command)`". The expansion of "`%(…)`" is the output of (the expansion of) `…` fed to `/bin/sh`. For example, "`%(date +%%Y%%m%%d)`" expands to the string "`YYYYMMDD`" (final newline is deleted). <sup>WengerChan:Just like executing "`sh -c 'date +%Y%m%d'`".</sup> **Note** the 2nd `%` needed to escape the arguments to `/bin/date`.

    ```sh
    ~] sh -c 'date +%Y%m%d'
    20220210

    ~] rpm --eval "%(date +%%Y%%m%%d)"
    20220210
    ```


* Expression Expansion

    Expression expansion can be performed using "`%[expression]`". An expression consists of terms that can be combined using operators. 

    Rpm supports three kinds of terms, *`numbers` made up from digits*, *`strings` enclosed in double quotes* (eg "somestring") and *`versions` enclosed in double quotes preceded by v* (eg v"3:1.2-1"). Rpm will expand macros when evaluating terms.

    You can use the standard operators to combine terms: *logical operators `&&`, `||`, `!`*, *relational operators `!=`, `==`, `<`, `>` , `<=`, `>=`*, _arithmetic operators `+`, `-`, `/`, `*`_, *the ternary operator<sup>三元运算符</sup> `?` `:`*, and parentheses("`()`"). For example, "`%[ 3 + 4 * (1 + %two) ]`" will expand to "`15`" if "`%two`" expands to "`2`". Version terms are compared using rpm version (`[epoch:]version[-release]`) comparison algorithm, rather than regular string comparison.

    > **Note** that the "`%[expression]`" expansion is different to the "`%{expr:expression}`" macro. With the latter, the macros in the expression are expanded first and then the expression is evaluated (without re-expanding the terms). Thus
    > 
    > ```sh
    > rpm --define 'foo 1 + 2' --eval '%{expr:%foo}'
    > ```
    > 
    > will print "3". Using '`%[%foo]`' instead will result in the error that *"1 + 2" is not a number*.
    > 

    Doing the macro expansion when evaluating the terms has two advantages. 

    &emsp;&emsp;First, it allows rpm to do correct short-circuit<sup>短路</sup> processing when evaluation logical operators.

    &emsp;&emsp;Second, the expansion result does not influence the expression parsing, e.g. '`%["%file"]`' will even work if the "`%file`" macro expands to a string that contains a double quote.

* Command Line Options

    When the command line option "`–define 'macroname value'`" allows the user to specify the value that a macro should have during the build. Note lack of leading `%` for the macro name. We will try to support users who accidentally type the leading `%` but this should not be relied upon.

    Evaluating a macro can be difficult outside of an rpm execution context. If you wish to see the expanded value of a macro, you may use the option

    ```sh
    --eval '<macro expression>'
    ```
    that will read rpm config files and print the macro expansion on stdout.

    > **Note**: This works only macros defined in rpm configuration files, not for macros defined in specfiles. You can use `%{echo: %{your_macro_here}}` if you wish to see the expansion of a macro defined in a spec file.

* Configuration using Macros

    Most rpm configuration is done via macros. There are numerous places from which macros are read, in recent rpm versions the macro path can be seen with `rpm --showrc|grep "^Macro path"`. **If there are multiple definitions of the same macro, the last one wins**. User-level configuration goes to `~/.rpmmacros` which is always the last one in the path.

    The macro file syntax is simply:

    ```text
    %<name>		 <body>
    ```

    … where is a legal macro `name` and `<body>` is the body of the macro. Multiline macros can be defined by shell-like line continuation, ie `\` at end of line.

    Note that the macro file syntax is strictly declarative<sup>严格声明</sup>, no conditionals<sup>条件语句,条件判断</sup> are supported (except of course in the macro body) and no macros are expanded during macro file read<sup>宏文件读取期间不扩展宏</sup>.

* Macro Analogues of Autoconf Variables

    Several macro definitions provided by the default rpm macro set have uses in packaging similar to the autoconf variables that are used in building packages:

    | Macro | Body |
    | -- | -- |
    | `%_prefix`         | `/usr` |
    | `%_exec_prefix`    | `%{_prefix}` |
    | `%_bindir`         | `%{_exec_prefix}/bin` |
    | `%_sbindir`        | `%{_exec_prefix}/sbin` |
    | `%_libexecdir`     | `%{_exec_prefix}/libexec` |
    | `%_datadir`        | `%{_prefix}/share` |
    | `%_sysconfdir`     | `/etc` |
    | `%_sharedstatedir` | `%{_prefix}/com` |
    | `%_localstatedir`  | `%{_prefix}/var` |
    | `%_libdir`         | `%{_exec_prefix}/lib` |
    | `%_includedir`     | `%{_prefix}/include` |
    | `%_oldincludedir`  | `/usr/include` |
    | `%_infodir`        | `%{_datadir}/info` |
    | `%_mandir`         | `%{_datadir}/man` |


### A.3 Macros for paths set and used by build systems

The macros for build system invocations (for example, `%configure`, `%cmake`, or `%meson`) use the values defined by RPM to set installation paths for packages. So, it's usually preferable to not hard-code these paths in spec files either, but use the same macros for consistency.

> The values for these macros can be inspected by looking at `/usr/lib/rpm/platform/*/macros` for the respective platform.

The following table lists macros which are widely used in fedora `.spec` files.

| macro | definition | comment |
| -- | -- | -- |
| `%{_sysconfdir}` | `/etc` |  |
| `%{_prefix}` | `/usr` | can be defined to /app for flatpak builds |
| `%{_exec_prefix}` | `%{_prefix}` | default: `/usr` |
| `%{_includedir}` | `%{_prefix}/include` | default: `/usr/include` |
| `%{_bindir}` | `%{_exec_prefix}/bin` | default: `/usr/bin` |
| `%{_libdir}` | `%{_exec_prefix}/%{_lib}` | default: `/usr/%{_lib}` |
| `%{_libexecdir}` | `%{_exec_prefix}/libexec` | default: `/usr/libexec` |
| `%{_sbindir}` | `%{_exec_prefix}/sbin` | default: `/usr/sbin` |
| `%{_datadir}` | `%{_datarootdir}` | default: `/usr/share` |
| `%{_infodir}` | `%{_datarootdir}/info` | default: `/usr/share/info` |
| `%{_mandir}` | `%{_datarootdir}/man` | default: `/usr/share/man` |
| `%{_docdir}` | `%{_datadir}/doc` | default: `/usr/share/doc` |
| `%{_rundir}` | `/run` |  |
| `%{_localstatedir}` | `/var` |  |
| `%{_sharedstatedir}` | `/var/lib` |  |
| `%{_lib}` | `lib64` | lib on *32bit* platforms |

Some seldomly used macros are listed below for completeness. Old `.spec` files might still use them, and there might be cases where they are still needed.

| macro | definition | comment |
| -- | -- | -- |
| `%{_datarootdir}` | `%{_prefix}/share` | default: `/usr/share` |
| `%{_var}` | `/var` |  |
| `%{_tmppath}` | `%{_var}/tmp` | default: `/var/tmp` |
| `%{_usr}` | `/usr` |  |
| `%{_usrsrc}` | `%{_usr}/src` | default: `/usr/src` |
| `%{_initddir}` | `%{_sysconfdir}/rc.d/init.d` | default: `/etc/rc.d/init.d` |
| `%{_initrddir}` | `%{_initddir}` | old misspelling, provided for compatiblity |

### A.4 Macros set for the RPM (and SRPM) build process

RPM also exposes the locations of several directories that are relevant to the package build process via macros.

The only macro that's widely used in `.spec` files is `%{buildroot}`, which points to the root of the installation target directory. It is used for setting `DESTDIR` in the package's `%install` step.

The other macros are usually only used outside `.spec` files. For example, they are set by `fedpkg` to override the default directories.


| macro | definition | comment |
| -- | -- | -- |
| `%{buildroot}` | `%{_buildrootdir}/%{name}-%{version}-%{release}.%{_arch}` | same as `$BUILDROOT` |
| `%{_topdir}` | `%{getenv:HOME}/rpmbuild` |  |
| `%{_builddir}` | `%{_topdir}/BUILD` |  |
| `%{_rpmdir}` | `%{_topdir}/RPMS` |  |
| `%{_sourcedir}` | `%{_topdir}/SOURCES` |  |
| `%{_specdir}` | `%{_topdir}/SPECS` |  |
| `%{_srcrpmdir}` | `%{_topdir}/SRPMS` |  |
| `%{_buildrootdir}` | `%{_topdir}/BUILDROOT` |  |

### A.5 Macros providing compiler and linker flags

The default build flags for binaries on fedora are also available via macros. They are used by the build system macros to setup the build environment, so it is usually not necessary to use them directly — except, for example, when doing bare bones compilation with `gcc` directly.

The set of flags listed below reflects the current state of fedora 28 on a `x86_64` machine, as defined in the file `/usr/lib/rpm/redhat/macros`.

The `%{optflags}` macro contains flags that determine `CFLAGS`, `CXXFLAGS`, `FFLAGS`, etc. — the `%{__global_cflags}` macro evaluates to the same string.

The current definitions of these values can be found in the `redhat-rpm-macros package`, in the [build flags documentation](https://src.fedoraproject.org/rpms/redhat-rpm-config//blob/rawhide/f/buildflags.md).

```sh
~]$ rpm --eval "%{optflags}"
-O2 -g -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection
```

The value of the `LDFLAGS` environment variable set by build systems is determined by the `%{build_ldflags}` macro:

```sh
~]$ rpm -E "%{build_ldflags}"
-Wl,-z,relro  -Wl,-z,now -specs=/usr/lib/rpm/redhat/redhat-hardened-ld
```

### A.6 `%setup` macro

`%setup` 执行以下操作:

* Ensures that we are working in the correct directory. (确认工作目录正确)

* Removes residues of previous builds. (删除以前编译时残留的文件或目录。)

* Unpacks the source tarball. (解压源码包)

* Sets up some default privileges. (解压完以后设置一些权限)

`%setup` 的典型输出如下( shell 设置了 `set -x` 时):

```text
Executing(%prep): /bin/sh -e /var/tmp/rpm-tmp.DhddsG
```

执行 `rpmbuild` 命令时加上 `--debug` 选项时, 可以查看到 sh 执行的脚本 `/var/tmp/rpm-tmp.DhddsG` 内容:

```sh
cd '/builddir/build/BUILD'
rm -rf 'cello-1.0'
/usr/bin/gzip -dc '/builddir/build/SOURCES/cello-1.0.tar.gz' | /usr/bin/tar -xof -
STATUS=$?
if [ $STATUS -ne 0 ]; then
  exit $STATUS
fi
cd 'cello-1.0'
/usr/bin/chmod -Rf a+rX,u+w,g-w,o-w .
```

* `%setup -q`

    简化输出信息, 仅执行 `tar -xof` 而不是 `tar -xvvof`

    > 关于 `tar -o` 参数: when creating, same as `--old-archive`<sup>same as `--format=v7`, old V7 tar format</sup>; when extracting, same as `--no-same-owner`<sup>extract files as yourself (default for ordinary users)</sup>

* `%setup -n`

    设置/修改解压后目录名称

* `%setup -c`

    新建目录后, 再建压缩包解压到新建的目录中

    ```sh
    /usr/bin/mkdir -p cello-1.0
    cd 'cello-1.0'
    ```

* `%setup -D` and `%setup -T`

    * `-D` 通过禁用以下这行, 不清理同名目录残留的文件或目录. 当需要多次使用 `%setup` 宏时可以添加

        ```sh
        rm -rf 'cello-1.0'
        ```
    
    * `-T` 禁用了以下这行

        ```sh
        /usr/bin/gzip -dc '/builddir/build/SOURCES/cello-1.0.tar.gz' | /usr/bin/tar -xof -
        ```


* `%setup -a` and `%setup -b`

    * 示例 1: `%setup -a 1`

        ```sh
        Source0: https://example.com/%{name}/release/%{name}-%{version}.tar.gz
        Source1: examples.tar.gz
        …
        %prep
        %setup -a 1

        ```
        源码包 `cello-1.0.tar.gz` 解压后包含一个空目录 `examples`, 此时使用 `-a 1` 表示进入 `cello-1.0` 目录后再解压 `Source1: examples.tar.gz` 中的示例文件到 `examples` 目录

    * 示例2: `%setup -b 1`

        ```sh
        Source0: https://example.com/%{name}/release/%{name}-%{version}.tar.gz
        Source1: %{name}-%{version}-examples.tar.gz
        …
        %prep
        %setup -b 1
        ```

        `cello-1.0-examples.tar.gz` 压缩包包含 `cello-1.0/examples` 目录, 此时使用 `-b 1` 先解压 `Source1: %{name}-%{version}-examples.tar.gz`, 然后才进入 `cello-1.0` 目录


### A.7 `%files` macro

Example: `openssh`

```sh
%files
%defattr(-,root,root)
%doc CREDITS ChangeLog INSTALL LICENCE OVERVIEW README* PROTOCOL* TODO
%attr(0755,root,root) %{_bindir}/scp
%attr(0644,root,root) %{_mandir}/man1/scp.1*
%attr(0755,root,root) %dir %{_sysconfdir}/ssh
%attr(0600,root,root) %config(noreplace) %{_sysconfdir}/ssh/moduli
%if ! %{rescue}
%attr(0755,root,root) %{_bindir}/ssh-keygen
%attr(0644,root,root) %{_mandir}/man1/ssh-keygen.1*
%attr(0755,root,root) %dir %{_libexecdir}/openssh
%attr(4711,root,root) %{_libexecdir}/openssh/ssh-keysign
%attr(0755,root,root) %{_libexecdir}/openssh/ssh-pkcs11-helper
%attr(0755,root,root) %{_libexecdir}/openssh/ssh-sk-helper
%attr(0644,root,root) %{_mandir}/man8/ssh-keysign.8*
%attr(0644,root,root) %{_mandir}/man8/ssh-pkcs11-helper.8*
%attr(0644,root,root) %{_mandir}/man8/ssh-sk-helper.8*
%endif
%if %{scard}
%attr(0755,root,root) %dir %{_datadir}/openssh
%attr(0644,root,root) %{_datadir}/openssh/Ssh.bin
%endif
```

* `%license` — RPM 包许可证

    例如许可文件名为 `LICENSE`, 放置在 `rpmbuild/SOURCES`:
    
    ```text
    ...
    %files
    %license LICENSE
    ...
    ```

* `%doc` — RPM 包说明/帮助文档

* `%dir` — RPM 包拥有的目录; 卸载 RPM 包时, 此处指定的目录将被删除

* `%config(noreplace)` — RPM 包的配置文件

    指定路径下的配置文件在安装/升级时不会被替换, 如果新版本 RPM 包中包含的配置文件相较旧版本有变化, 则新版本 RPM 包中的配置文件会被加上 `.rpmnew` 后缀

    ```text
    %config(noreplace) %{_sysconfdir}/ssh/sshd_config
    ```

* `attr`, `defattr` — 设置文件的权限

    Format:

    ```text
    %attr(<mode>, <user>, <group>) file
    %defattr(<file mode>, <user>, <group>, <dir mode>)
    ```

    * `<user>` 和 `<group>` 不能使用数字表示(`uid`, `gid`)
    * 不需要配置的, 可用 "`-`" 占位


### A.8 宏定义与修改


* spec文件里面定义:

    ```spec
    %define macro_name value
    %define macro_name %(data)
    ```

* spec文件中使用方法:

    ```text
    %macro_name
    %macro_name 1 2 3 # 1，2，3为参数传递给宏
    %0                # 宏名字
    %*                # 传递给宏的所有参数
    %#                # 传递给宏的参数个数
    %1                # 参数1
    %2                # 参数2
    ```

* 命令行使用 `--define`
 
    ```sh
    rpm --define "dist my_dist" --eval "%{dist}"
    rpmbuild -bs name.spec --define "dist x86_64"
    ```



---

## B. RPM 信号机制

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


---


## C. 实战 OpenSSH && OpenSSL

```yaml
---
Env:
     OS: CentOS 7.6
OpenSSH: openssh-9.0p1.tar.gz
OpenSSL: openssl-1.1.1n.tar.gz
    gcc: 4.8.5 20150623 (Red Hat 4.8.5-44)
   make: GNU Make 3.82
```

### C.1 准备源码包和工作目录

准备一台 CentOS 7.6 虚拟机， root 身份进入系统

* 用户及工作目录

    ```sh
    ~] useradd rpmbuilder
    ~] su - rpmbuilder
    ~]$ rpmdev-setuptree
    ~]$ tree /home/rpmbuilder/rpmbuild
    /home/rpmbuilder/rpmbuild/
    ├── BUILD
    ├── RPMS
    ├── SOURCES
    ├── SPECS
    └── SRPMS
    ```

* 下载源码包并上传到虚拟机

    OpenSSL：https://www.openssl.org/source/

    OpenSSH：http://www.openssh.com/portable.html

### C.2 对 OpenSSL 打包成 RPM



## 需要注意的几点


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
