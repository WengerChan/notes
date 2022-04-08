# RPM macros

> https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/

RPM provides a rich set of macros to make package maintenance simpler and consistent across packages. For example, it includes *a list of default path definitions* which are used by the build system macros, and definitions for RPM package build specific directories. They usually should be used instead of hard-coded directories. It also provides the default set of compiler flags as macros, which should be used when compiling manually and not relying on a build system.

```sh
~]$ rpm --eval "some text printed on %{_arch}"
some text printed on x86_64

~]$ rpm --define 'test Hello, World!' --eval "%{test}"
Hello, World!
```

## 1 宏定义相关的文件

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

## 2 Macros syntax

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



## 3 Macros for paths set and used by build systems

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

## 4 Macros set for the RPM (and SRPM) build process

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

## 5 Macros providing compiler and linker flags

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


## 6 宏定义与修改

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
