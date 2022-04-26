# Do we want SELinux & Audit
%if 0%{?!noselinux:1}
%global WITH_SELINUX 1
%else
%global WITH_SELINUX 0
%endif

%global _hardened_build 1

# OpenSSH privilege separation requires a user & group ID
%global sshd_uid    74
%global sshd_gid    74

# Do we want to disable building of gnome-askpass? (1=yes 0=no)
%global no_gnome_askpass 0

# Do we want to link against a static libcrypto? (1=yes 0=no)
%global static_libcrypto 0

# Use GTK2 instead of GNOME in gnome-ssh-askpass
%global gtk2 1

# Build position-independent executables (requires toolchain support)?
%global pie 1

# Do we want kerberos5 support (1=yes 0=no)
%global kerberos5 1

# Do we want libedit support
%global libedit 1

# Whether to build pam_ssh_agent_auth
%if 0%{?!nopam:1}
%global pam_ssh_agent 1
%else
%global pam_ssh_agent 0
%endif

# Reserve options to override askpass settings with:
# rpm -ba|--rebuild --define 'skip_xxx 1'
%{?skip_gnome_askpass:%global no_gnome_askpass 1}

# Add option to build without GTK2 for older platforms with only GTK+.
# Red Hat Linux <= 7.2 and Red Hat Advanced Server 2.1 are examples.
# rpm -ba|--rebuild --define 'no_gtk2 1'
%{?no_gtk2:%global gtk2 0}

# Options for static OpenSSL link:
# rpm -ba|--rebuild --define "static_openssl 1"
%{?static_openssl:%global static_libcrypto 1}


# Do not forget to bump pam_ssh_agent_auth release if you rewind the main package release to 1
%global openssh_ver 9.0p1
%global openssh_rel 1
%global pam_ssh_agent_ver 0.10.4
%global pam_ssh_agent_rel 4


Summary: An open source implementation of SSH protocol version 2
Name: openssh
Version: %{openssh_ver}
Release: %{openssh_rel}%{?dist}
URL: http://www.openssh.com/portable.html
Packager: Wenger Chan <cnwn1111@hotmail.com>
Source0: openssh-%{version}.tar.gz
Source1: openssh-%{version}.tar.gz.asc
Source2: sshd.pam
Source3: gpgkey-736060BA.gpg
Source4: pam_ssh_agent_auth-%{pam_ssh_agent_ver}.tar.gz
Source5: pam_ssh_agent-rmheaders
Source7: sshd.sysconfig
Source9: sshd@.service
Source10: sshd.socket
Source11: sshd.service
Source12: sshd-keygen@.service
Source13: sshd-keygen
Source15: sshd-keygen.target
Source16: ssh-agent.service

# --- pam_ssh_agent ---
Patch300: pam_ssh_agent_auth-0.9.3-build.patch
Patch301: pam_ssh_agent_auth-0.10.3-seteuid.patch
Patch302: pam_ssh_agent_auth-0.9.2-visibility.patch
Patch305: pam_ssh_agent_auth-0.9.3-agent_structure.patch
Patch306: pam_ssh_agent_auth-0.10.2-compat.patch
Patch307: pam_ssh_agent_auth-0.10.2-dereference.patch

# --- askpass ---
Patch702: openssh-5.1p1-askpass-progress.patch
Patch703: openssh-4.3p2-askpass-grab-info.patch

# --- sshd_config ssh_config ---
Patch707: openssh-9.0p1-modifyconfig.patch

# --- systemd ---
Patch948: openssh-7.4p1-systemd.patch


License: BSD
Group: Applications/Internet
BuildArch: x86_64
Requires: /sbin/nologin

%if ! %{no_gnome_askpass}
%if %{gtk2}
BuildRequires: gtk2-devel
BuildRequires: libX11-devel
%else
BuildRequires: gnome-libs-devel
%endif
%endif

BuildRequires: autoconf, automake, perl-interpreter, perl-generators, zlib-devel
BuildRequires: audit-libs-devel >= 2.0.5
BuildRequires: util-linux, groff
BuildRequires: pam-devel
BuildRequires: openssl-devel >= 0.9.8j
BuildRequires: perl-podlators
BuildRequires: systemd-devel
BuildRequires: systemd-rpm-macros
BuildRequires: gcc make
BuildRequires: p11-kit-devel
BuildRequires: libfido2-devel
Obsoletes: openssh-ldap < 8.3p1-4
Obsoletes: openssh-cavs < 8.4p1-5

%if %{kerberos5}
BuildRequires: krb5-devel
%endif

%if %{libedit}
BuildRequires: libedit-devel ncurses-devel
%endif

%if %{WITH_SELINUX}
BuildRequires: libselinux-devel >= 2.3-5
BuildRequires: audit-libs >= 1.0.8
Requires: libselinux >= 2.3-5
Requires: audit-libs >= 1.0.8
%endif

BuildRequires: xauth
BuildRequires: gnupg2

%package clients
Summary: An open source SSH client applications
Group: Applications/Internet
Requires: openssh = %{version}-%{release}
#Requires: crypto-policies >= 20200610-1

%package server
Summary: An open source SSH server daemon
Group: System Environment/Daemons
Requires: openssh = %{version}-%{release}
Requires(pre): /usr/sbin/useradd
Requires: pam >= 1.0.1-3
#Requires: crypto-policies >= 20200610-1
%{?systemd_requires}

%package server-sysvinit
Summary: The SysV initscript to manage the OpenSSH server.
Group: System Environment/Daemons
Requires: %{name}-server%{?_isa} = %{version}-%{release}

%package askpass
Summary: A passphrase dialog for OpenSSH and X
Group: Applications/Internet
Requires: openssh = %{version}-%{release}

%package -n pam_ssh_agent_auth
Summary: PAM module for authentication with ssh-agent
Group: System Environment/Base
Version: %{pam_ssh_agent_ver}
Release: %{pam_ssh_agent_rel}.%{openssh_rel}%{?dist}
License: BSD

%description
SSH (Secure SHell) is a program for logging into and executing
commands on a remote machine. SSH is intended to replace rlogin and
rsh, and to provide secure encrypted communications between two
untrusted hosts over an insecure network. X11 connections and
arbitrary TCP/IP ports can also be forwarded over the secure channel.

OpenSSH is OpenBSD's version of the last free version of SSH, bringing
it up to date in terms of security and features.

This package includes the core files necessary for both the OpenSSH
client and server. To make this package useful, you should also
install openssh-clients, openssh-server, or both.

%description clients
OpenSSH is a free version of SSH (Secure SHell), a program for logging
into and executing commands on a remote machine. This package includes
the clients necessary to make encrypted connections to SSH servers.

%description server
OpenSSH is a free version of SSH (Secure SHell), a program for logging
into and executing commands on a remote machine. This package contains
the secure shell daemon (sshd). The sshd daemon allows SSH clients to
securely connect to your SSH server.

%description server-sysvinit
OpenSSH is a free version of SSH (Secure SHell), a program for logging
into and executing commands on a remote machine. This package contains
the SysV init script to manage the OpenSSH server when running a legacy
SysV-compatible init system.

%description askpass
OpenSSH is a free version of SSH (Secure SHell), a program for logging
into and executing commands on a remote machine. This package contains
an X11 passphrase dialog for OpenSSH.

%description -n pam_ssh_agent_auth
This package contains a PAM module which can be used to authenticate
users using ssh keys stored in a ssh-agent. Through the use of the
forwarding of ssh-agent connection it also allows to authenticate with
remote ssh-agent instance.

The module is most useful for su and sudo service stacks.

%prep
gpgv2 --quiet --keyring %{SOURCE3} %{SOURCE1} %{SOURCE0}
%setup -q -a 4

%if %{pam_ssh_agent}
pushd pam_ssh_agent_auth-pam_ssh_agent_auth-%{pam_ssh_agent_ver}
%patch300 -p2 -b .psaa-build
%patch301 -p2 -b .psaa-seteuid
%patch302 -p2 -b .psaa-visibility
%patch306 -p2 -b .psaa-compat
%patch305 -p2 -b .psaa-agent
%patch307 -p2 -b .psaa-deref
# Remove duplicate headers and library files
rm -f $(cat %{SOURCE5})
popd
%endif

%patch702 -p1 -b .progress
%patch703 -p1 -b .grab-info

%patch707 -p1 -b .modifyconfig

%patch948 -p1 -b .systemd

autoreconf
pushd pam_ssh_agent_auth-pam_ssh_agent_auth-%{pam_ssh_agent_ver}
autoreconf
popd

%build
# the -fvisibility=hidden is needed for clean build of the pam_ssh_agent_auth
# it is needed for lib(open)ssh build too since it is linked to the pam module too
CFLAGS="$RPM_OPT_FLAGS -fvisibility=hidden"; export CFLAGS
%if %{pie}
%ifarch s390 s390x sparc sparcv9 sparc64
CFLAGS="$CFLAGS -fPIC"
%else
CFLAGS="$CFLAGS -fpic"
%endif
SAVE_LDFLAGS="$LDFLAGS"
LDFLAGS="$LDFLAGS -pie -z relro -z now"

export CFLAGS
export LDFLAGS

%endif
%if %{kerberos5}
if test -r /etc/profile.d/krb5-devel.sh ; then
	source /etc/profile.d/krb5-devel.sh
fi
krb5_prefix=`krb5-config --prefix`
if test "$krb5_prefix" != "%{_prefix}" ; then
	CPPFLAGS="$CPPFLAGS -I${krb5_prefix}/include -I${krb5_prefix}/include/gssapi"; export CPPFLAGS
	CFLAGS="$CFLAGS -I${krb5_prefix}/include -I${krb5_prefix}/include/gssapi"
	LDFLAGS="$LDFLAGS -L${krb5_prefix}/%{_lib}"; export LDFLAGS
else
	krb5_prefix=
	CPPFLAGS="-I%{_includedir}/gssapi"; export CPPFLAGS
	CFLAGS="$CFLAGS -I%{_includedir}/gssapi"
fi
%endif

%configure \
	--sysconfdir=%{_sysconfdir}/ssh \
	--libexecdir=%{_libexecdir}/openssh \
	--datadir=%{_datadir}/openssh \
	--with-default-path=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin \
	--with-superuser-path=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin \
	--with-privsep-path=%{_datadir}/empty.sshd \
	--disable-strip \
	--without-zlib-version-check \
	--with-ssl-engine \
	--with-ipaddr-display \
	--with-pie=no \
	--without-hardening \
	--with-systemd \
	--with-security-key-builtin=yes \
	--with-pam \
%if %{WITH_SELINUX}
	--with-selinux --with-audit=linux \
	--with-sandbox=seccomp_filter \
%endif
%if %{kerberos5}
	--with-kerberos5${krb5_prefix:+=${krb5_prefix}} \
%else
	--without-kerberos5 \
%endif
%if %{libedit}
	--with-libedit
%else
	--without-libedit
%endif

%if %{static_libcrypto}
perl -pi -e "s|-lcrypto|%{_libdir}/libcrypto.a|g" Makefile
%endif

%make_build

# Define a variable to toggle gnome1/gtk2 building.  This is necessary
# because RPM doesn't handle nested %%if statements.
%if %{gtk2}
	gtk2=yes
%else
	gtk2=no
%endif

%if ! %{no_gnome_askpass}
pushd contrib
if [ $gtk2 = yes ] ; then
	CFLAGS="$CFLAGS %{?__global_ldflags}" \
	    make gnome-ssh-askpass2
	mv gnome-ssh-askpass2 gnome-ssh-askpass
else
	CFLAGS="$CFLAGS %{?__global_ldflags}"
	    make gnome-ssh-askpass1
	mv gnome-ssh-askpass1 gnome-ssh-askpass
fi
popd
%endif

%if %{pam_ssh_agent}
pushd pam_ssh_agent_auth-pam_ssh_agent_auth-%{pam_ssh_agent_ver}
LDFLAGS="$SAVE_LDFLAGS"
%configure --with-selinux \
	--libexecdir=/%{_libdir}/security \
	--with-mantype=man \
	--without-openssl-header-check `# The check is broken`
%make_build
popd
%endif

%check
#to run tests use "--with check"
%if %{?_with_check:1}%{!?_with_check:0}
make tests
%endif

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p -m755 $RPM_BUILD_ROOT%{_sysconfdir}/ssh
mkdir -p -m755 $RPM_BUILD_ROOT%{_libexecdir}/openssh
%make_install

install -d $RPM_BUILD_ROOT/etc/pam.d/
install -d $RPM_BUILD_ROOT/etc/sysconfig/
install -d $RPM_BUILD_ROOT/etc/rc.d/init.d
install -d $RPM_BUILD_ROOT%{_libexecdir}/openssh
install -m644 %{SOURCE2} $RPM_BUILD_ROOT/etc/pam.d/sshd
install -m755 %{SOURCE3} $RPM_BUILD_ROOT/etc/rc.d/init.d/sshd
install -m644 %{SOURCE7} $RPM_BUILD_ROOT/etc/sysconfig/sshd
install -d -m755 $RPM_BUILD_ROOT/%{_unitdir}
install -m644 %{SOURCE9} $RPM_BUILD_ROOT/%{_unitdir}/sshd@.service
install -m644 %{SOURCE10} $RPM_BUILD_ROOT/%{_unitdir}/sshd.socket
install -m644 %{SOURCE11} $RPM_BUILD_ROOT/%{_unitdir}/sshd.service
install -m644 %{SOURCE12} $RPM_BUILD_ROOT/%{_unitdir}/sshd-keygen@.service
install -m644 %{SOURCE15} $RPM_BUILD_ROOT/%{_unitdir}/sshd-keygen.target
install -d -m755 $RPM_BUILD_ROOT/%{_userunitdir}
install -m644 %{SOURCE16} $RPM_BUILD_ROOT/%{_userunitdir}/ssh-agent.service
install -m744 %{SOURCE13} $RPM_BUILD_ROOT/%{_libexecdir}/openssh/sshd-keygen
install -m755 contrib/ssh-copy-id $RPM_BUILD_ROOT%{_bindir}/
install contrib/ssh-copy-id.1 $RPM_BUILD_ROOT%{_mandir}/man1/
install -d -m711 ${RPM_BUILD_ROOT}/%{_datadir}/empty.sshd

%if ! %{no_gnome_askpass}
install contrib/gnome-ssh-askpass $RPM_BUILD_ROOT%{_libexecdir}/openssh/gnome-ssh-askpass
%endif

%if ! %{no_gnome_askpass}
ln -s gnome-ssh-askpass $RPM_BUILD_ROOT%{_libexecdir}/openssh/ssh-askpass
install -m 755 -d $RPM_BUILD_ROOT%{_sysconfdir}/profile.d/
install -m 755 contrib/redhat/gnome-ssh-askpass.csh $RPM_BUILD_ROOT%{_sysconfdir}/profile.d/
install -m 755 contrib/redhat/gnome-ssh-askpass.sh $RPM_BUILD_ROOT%{_sysconfdir}/profile.d/
%endif

%if %{no_gnome_askpass}
rm -f $RPM_BUILD_ROOT/etc/profile.d/gnome-ssh-askpass.*
%endif

perl -pi -e "s|$RPM_BUILD_ROOT||g" $RPM_BUILD_ROOT%{_mandir}/man*/*

%if %{pam_ssh_agent}
pushd pam_ssh_agent_auth-pam_ssh_agent_auth-%{pam_ssh_agent_ver}
%make_install
popd
%endif
%pre
getent group ssh_keys >/dev/null || groupadd -r ssh_keys || :

%pre server
getent group sshd >/dev/null || groupadd -g %{sshd_uid} -r sshd || :
getent passwd sshd >/dev/null || \
  useradd -c "Privilege-separated SSH" -u %{sshd_uid} -g sshd \
  -s /sbin/nologin -r -d /usr/share/empty.sshd sshd 2> /dev/null || :

%post server
%systemd_post sshd.service sshd.socket
/usr/bin/chmod --silent 0600 /etc/ssh/ssh_host_*_key

%preun server
%systemd_preun sshd.service sshd.socket

%postun server
%systemd_postun_with_restart sshd.service

%post clients
%systemd_user_post ssh-agent.service

%preun clients
%systemd_user_preun ssh-agent.service

%files
%license LICENCE
%doc CREDITS ChangeLog OVERVIEW PROTOCOL* README README.platform README.privsep README.tun README.dns TODO
%attr(0755,root,root) %dir %{_sysconfdir}/ssh
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/ssh/moduli
%attr(0755,root,root) %{_bindir}/ssh-keygen
%attr(0644,root,root) %{_mandir}/man1/ssh-keygen.1*
%attr(0755,root,root) %dir %{_libexecdir}/openssh
%attr(2555,root,ssh_keys) %{_libexecdir}/openssh/ssh-keysign
%attr(0644,root,root) %{_mandir}/man8/ssh-keysign.8*

%files clients
%attr(0755,root,root) %{_bindir}/ssh
%attr(0644,root,root) %{_mandir}/man1/ssh.1*
%attr(0755,root,root) %{_bindir}/scp
%attr(0644,root,root) %{_mandir}/man1/scp.1*
%attr(0644,root,root) %config(noreplace) %{_sysconfdir}/ssh/ssh_config
%attr(0644,root,root) %{_mandir}/man5/ssh_config.5*
%attr(0755,root,root) %{_bindir}/ssh-agent
%attr(0755,root,root) %{_bindir}/ssh-add
%attr(0755,root,root) %{_bindir}/ssh-keyscan
%attr(0755,root,root) %{_bindir}/sftp
%attr(0755,root,root) %{_bindir}/ssh-copy-id
%attr(0755,root,root) %{_libexecdir}/openssh/ssh-pkcs11-helper
%attr(0755,root,root) %{_libexecdir}/openssh/ssh-sk-helper
%attr(0644,root,root) %{_mandir}/man1/ssh-agent.1*
%attr(0644,root,root) %{_mandir}/man1/ssh-add.1*
%attr(0644,root,root) %{_mandir}/man1/ssh-keyscan.1*
%attr(0644,root,root) %{_mandir}/man1/sftp.1*
%attr(0644,root,root) %{_mandir}/man1/ssh-copy-id.1*
%attr(0644,root,root) %{_mandir}/man8/ssh-pkcs11-helper.8*
%attr(0644,root,root) %{_mandir}/man8/ssh-sk-helper.8*
%attr(0644,root,root) %{_userunitdir}/ssh-agent.service

%files server
%dir %attr(0711,root,root) %{_datadir}/empty.sshd
%attr(0755,root,root) %{_sbindir}/sshd
%attr(0755,root,root) %{_libexecdir}/openssh/sftp-server
%attr(0755,root,root) %{_libexecdir}/openssh/sshd-keygen
%attr(0644,root,root) %{_mandir}/man5/sshd_config.5*
%attr(0644,root,root) %{_mandir}/man5/moduli.5*
%attr(0644,root,root) %{_mandir}/man8/sshd.8*
%attr(0644,root,root) %{_mandir}/man8/sftp-server.8*
%attr(0600,root,root) %config(noreplace) %{_sysconfdir}/ssh/sshd_config
%attr(0644,root,root) %config(noreplace) /etc/pam.d/sshd
%attr(0640,root,root) %config(noreplace) /etc/sysconfig/sshd
%attr(0644,root,root) %{_unitdir}/sshd.service
%attr(0644,root,root) %{_unitdir}/sshd@.service
%attr(0644,root,root) %{_unitdir}/sshd.socket
%attr(0644,root,root) %{_unitdir}/sshd-keygen@.service
%attr(0644,root,root) %{_unitdir}/sshd-keygen.target

%files server-sysvinit
%attr(0755,root,root) /etc/rc.d/init.d/sshd

%if ! %{no_gnome_askpass}
%files askpass
%attr(0644,root,root) %{_sysconfdir}/profile.d/gnome-ssh-askpass.*
%attr(0755,root,root) %{_libexecdir}/openssh/gnome-ssh-askpass
%attr(0755,root,root) %{_libexecdir}/openssh/ssh-askpass
%endif

%if %{pam_ssh_agent}
%files -n pam_ssh_agent_auth
%license pam_ssh_agent_auth-pam_ssh_agent_auth-%{pam_ssh_agent_ver}/OPENSSH_LICENSE
%attr(0755,root,root) %{_libdir}/security/pam_ssh_agent_auth.so
%attr(0644,root,root) %{_mandir}/man8/pam_ssh_agent_auth.8*
%endif

%changelog
* Sun Apr 24 2022 Wenger Chan <cnwn1111@hotmail.com> - 9.0p1-1
- RPM Packaging from openssh-9.0p1.tar.gz

