Summary: NFS utilities and supporting clients and daemons for the kernel NFS server
Name: nfs-utils
URL: http://linux-nfs.org/
Version: 2.5.4
Release: 18%{?dist}
Epoch: 1

# group all 32bit related archs
%global all_32bit_archs i386 i486 i586 i686 athlon ppc sparcv9

Source0: https://www.kernel.org/pub/linux/utils/nfs-utils/%{version}/%{name}-%{version}.tar.xz
Source1: id_resolver.conf
Source2: lockd.conf
Source3: 24-nfs-server.conf
Source4: 10-nfsv4.conf

#
# RHEL9.0
#
Patch001: nfs-utils-2.5.4-mount-sloppy.patch
Patch002: nfs-utils-2.5.4-nfsdcltrack-printf.patch
Patch003: nfs-utils-2.5.4-general-memory-fixes.patch
Patch004: nfs-utils-2.5.4-mount-nov2.patch
Patch005: nfs-utils-2.5.4-gssd-debug-msg.patch
Patch006: nfs-utils-2.5.4-rpcctl.patch

#
# RHEL9.1
#
Patch007: nfs-utils-2.5.4-nfsman-maxconnect.patch
Patch008: nfs-utils-2.5.4-rpcpipefs-warn.patch
Patch009: nfs-utils-2.5.4-rpcidmapd-return.patch
Patch010: nfs-utils-2.5.4-mount-ebusy.patch
Patch011: nfs-utils-2.5.4-rpcctl-xprt.patch
Patch012: nfs-utils-2.5.4-systemd-rpcstatd.patch

#
# RHEL9.2
#
Patch013: nfs-utils-2.5.4-nfsd-man-4vers.patch
Patch014: nfs-utils-2.5.4-mount-null-ptr.patch
Patch015: nfs-utils-2.5.4-nfsrahead-cmd.patch
Patch016: nfs-utils-2.5.4-covscan-return-value.patch

Patch100: nfs-utils-1.2.1-statdpath-man.patch
Patch101: nfs-utils-1.2.1-exp-subtree-warn-off.patch
Patch102: nfs-utils-1.2.5-idmap-errmsg.patch
Patch103: nfs-utils-2.3.1-systemd-gssproxy-restart.patch
Patch104: nfs-utils-2.3.3-man-tcpwrappers.patch
Patch105: nfs-utils-2.3.3-nfsconf-usegssproxy.patch
Patch106: nfs-utils-2.4.2-systemd-svcgssd.patch

Provides: exportfs    = %{epoch}:%{version}-%{release}
Provides: nfsstat     = %{epoch}:%{version}-%{release}
Provides: showmount   = %{epoch}:%{version}-%{release}
Provides: rpcdebug    = %{epoch}:%{version}-%{release}
Provides: rpcctl      = %{epoch}:%{version}-%{release}
Provides: rpc.idmapd  = %{epoch}:%{version}-%{release}
Provides: rpc.mountd  = %{epoch}:%{version}-%{release}
Provides: rpc.nfsd    = %{epoch}:%{version}-%{release}
Provides: rpc.statd   = %{epoch}:%{version}-%{release}
Provides: rpc.gssd    = %{epoch}:%{version}-%{release}
Provides: mount.nfs   = %{epoch}:%{version}-%{release}
Provides: mount.nfs4  = %{epoch}:%{version}-%{release}
Provides: umount.nfs  = %{epoch}:%{version}-%{release}
Provides: umount.nfs4 = %{epoch}:%{version}-%{release}
Provides: sm-notify   = %{epoch}:%{version}-%{release}
Provides: start-statd = %{epoch}:%{version}-%{release}

License: MIT and GPLv2 and GPLv2+ and BSD
BuildRequires: make
BuildRequires: libevent-devel libcap-devel libuuid-devel
BuildRequires: libtirpc-devel libblkid-devel
BuildRequires: krb5-libs >= 1.4 autoconf >= 2.57 openldap-devel >= 2.2
BuildRequires: automake, libtool, gcc, device-mapper-devel
BuildRequires: krb5-devel, libmount-devel, libxml2-devel
BuildRequires: sqlite-devel
BuildRequires: python3-devel
BuildRequires: systemd
BuildRequires: /usr/bin/rpcgen
Requires(pre): shadow-utils >= 4.0.3-25
Requires(pre): util-linux
Requires(pre): coreutils
Requires(preun): coreutils
Requires: libnfsidmap libevent
Requires: libtirpc >= 0.2.3-1 libblkid libcap libmount
Requires: gssproxy => 0.7.0-3
Requires: rpcbind, sed, gawk, grep
Requires: kmod, keyutils, quota, python36-PyYAML
%{?systemd_requires}

%package -n nfs-utils-coreos
Summary: Minimal NFS utilities for supporting clients
Provides: nfsstat     = %{epoch}:%{version}-%{release}
Provides: rpc.statd   = %{epoch}:%{version}-%{release}
Provides: rpc.gssd    = %{epoch}:%{version}-%{release}
Provides: mount.nfs   = %{epoch}:%{version}-%{release}
Provides: mount.nfs4  = %{epoch}:%{version}-%{release}
Provides: umount.nfs  = %{epoch}:%{version}-%{release}
Provides: umount.nfs4 = %{epoch}:%{version}-%{release}
Provides: start-statd = %{epoch}:%{version}-%{release}
Provides: nfsidmap    = %{epoch}:%{version}-%{release}
Provides: showmount   = %{epoch}:%{version}-%{release}
Requires: rpcbind
%{?systemd_requires}

%description -n nfs-utils-coreos
Minimal NFS utilities for supporting clients

%package -n nfs-stats-utils
Summary: NFS utilities for supporting clients
Provides: nfsstat     = %{epoch}:%{version}-%{release}
Provides: mountstats  = %{epoch}:%{version}-%{release}
Provides: nfsiostat   = %{epoch}:%{version}-%{release}

%description -n nfs-stats-utils
Show NFS client Statistics

%package -n nfsv4-client-utils
Summary: NFSv4 utilities for supporting client
Provides: rpc.gssd    = %{epoch}:%{version}-%{release}
Provides: rpcctl      = %{epoch}:%{version}-%{release}
Provides: mount.nfs   = %{epoch}:%{version}-%{release}
Provides: mount.nfs4  = %{epoch}:%{version}-%{release}
Provides: umount.nfs  = %{epoch}:%{version}-%{release}
Provides: umount.nfs4 = %{epoch}:%{version}-%{release}
Provides: nfsidmap    = %{epoch}:%{version}-%{release}
Requires: gssproxy => 0.7.0-3

%description -n nfsv4-client-utils
The nfsv4-client-utils packages provided NFSv4 client support 

%package -n libnfsidmap
Summary: NFSv4 User and Group ID Mapping Library
Provides: libnfsidmap%{?_isa} = %{epoch}:%{version}-%{release}
License: BSD
BuildRequires: pkgconfig, openldap-devel
BuildRequires: automake, libtool
Requires: openldap

%description -n libnfsidmap
Library that handles mapping between names and ids for NFSv4.

%package -n libnfsidmap-devel
Summary: Development files for the libnfsidmap library
Requires: libnfsidmap%{?_isa} = %{epoch}:%{version}-%{release}
Requires: pkgconfig

%description -n libnfsidmap-devel
This package includes header files and libraries necessary for
developing programs which use the libnfsidmap library.


%description
The nfs-utils package provides a daemon for the kernel NFS server and
related tools, which provides a much higher level of performance than the
traditional Linux NFS server used by most users.

This package also contains the showmount program.  Showmount queries the
mount daemon on a remote host for information about the NFS (Network File
System) server on the remote host.  For example, showmount can display the
clients which are mounted on that host.

This package also contains the mount.nfs and umount.nfs program.

%prep
%autosetup -p1

# Remove .orig files
find . -name "*.orig" | xargs rm -f

# Change shebangs
find -name \*.py -exec sed -r -i '1s|^#!\s*/usr/bin.*python.*|#!%{__python3}|' {} \;

%build
sh -x autogen.sh
%global _statdpath /var/lib/nfs/statd
%configure \
    CFLAGS="%{build_cflags} -std=gnu99 -D_FILE_OFFSET_BITS=64" \
    LDFLAGS="%{build_ldflags}" \
    --enable-mountconfig \
    --enable-ipv6 \
	--with-statdpath=%{_statdpath} \
	--enable-libmount-mount \
	--with-systemd \
	--without-tcp-wrappers \
	--with-pluginpath=%{_libdir}/libnfsidmap \
	--enable-junction

%make_build all

%install
%global _pkgdir %{_prefix}/lib/systemd

rm -rf $RPM_BUILD_ROOT/*

mkdir -p $RPM_BUILD_ROOT/sbin
mkdir -p $RPM_BUILD_ROOT%{_sbindir}
mkdir -p $RPM_BUILD_ROOT%{_libexecdir}/nfs-utils/
mkdir -p $RPM_BUILD_ROOT%{_pkgdir}/system
mkdir -p $RPM_BUILD_ROOT%{_pkgdir}/system-generators
mkdir -p ${RPM_BUILD_ROOT}%{_mandir}/man8
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/request-key.d
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/modprobe.d/
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/gssproxy

%make_install

install -s -m 755 tools/rpcdebug/rpcdebug $RPM_BUILD_ROOT%{_sbindir}
install -m 644 utils/mount/nfsmount.conf  $RPM_BUILD_ROOT%{_sysconfdir}
install -m 644 nfs.conf $RPM_BUILD_ROOT%{_sysconfdir}
install -m 644 support/nfsidmap/idmapd.conf $RPM_BUILD_ROOT%{_sysconfdir}
install -m 644 %{SOURCE1} $RPM_BUILD_ROOT%{_sysconfdir}/request-key.d

mkdir -p $RPM_BUILD_ROOT/run/sysconfig
install -m 644 %{SOURCE2} $RPM_BUILD_ROOT%{_sysconfdir}/modprobe.d/lockd.conf
install -m 644 %{SOURCE3} $RPM_BUILD_ROOT%{_sysconfdir}/gssproxy

rm -rf $RPM_BUILD_ROOT%{_libdir}/*.{a,la}
rm -rf $RPM_BUILD_ROOT%{_libdir}/libnfsidmap/*.{a,la}

mkdir -p $RPM_BUILD_ROOT%{_sharedstatedir}/nfs/rpc_pipefs

touch $RPM_BUILD_ROOT%{_sharedstatedir}/nfs/rmtab
mv $RPM_BUILD_ROOT%{_sbindir}/rpc.statd $RPM_BUILD_ROOT/sbin

mkdir -p $RPM_BUILD_ROOT%{_sharedstatedir}/nfs/statd/sm
mkdir -p $RPM_BUILD_ROOT%{_sharedstatedir}/nfs/statd/sm.bak
mkdir -p $RPM_BUILD_ROOT%{_sharedstatedir}/nfs/v4recovery
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/exports.d

mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/nfsmount.conf.d
#install -m 644 %{SOURCE4} $RPM_BUILD_ROOT%{_sysconfdir}/nfsmount.conf.d


%pre
# move files so the running service will have this applied as well
for x in gssd idmapd ; do
    if [ -f /var/lock/subsys/rpc.$x ]; then
		mv /var/lock/subsys/rpc.$x /var/lock/subsys/rpc$x
    fi
done

%global rpcuser_uid 29
# Create rpcuser gid as long as it does not already exist
cat /etc/group | cut -d':' -f 1 | grep --quiet rpcuser 2>/dev/null
if [ "$?" -eq 1 ]; then
    /usr/sbin/groupadd -g %{rpcuser_uid} rpcuser >/dev/null 2>&1 || :
fi

# Create rpcuser uid as long as it does not already exist.
cat /etc/passwd | cut -d':' -f 1 | grep --quiet rpcuser 2>/dev/null
if [ "$?" -eq 1 ]; then
    /usr/sbin/useradd -l -c "RPC Service User" -r -g %{rpcuser_uid} \
        -s /sbin/nologin -u %{rpcuser_uid} -d /var/lib/nfs rpcuser >/dev/null 2>&1 || :
else
 /usr/sbin/usermod -u %{rpcuser_uid} -g %{rpcuser_uid} rpcuser >/dev/null 2>&1 || :
fi 

# Using the 16-bit value of -2 for the nfsnobody uid and gid
%global nfsnobody_uid 65534

# Nowadays 'nobody/65534' user/group are included in setup rpm. But on
# systems installed previously, nobody/99 might be present, with user
# 65534 missing. Let's create nfsnobody/65534 in that case.

# Create nfsnobody gid as long as it does not already exist
cat /etc/group | cut -d':' -f 3 | grep --quiet %{nfsnobody_uid} 2>/dev/null
if [ "$?" -eq 1 ]; then
    /usr/sbin/groupadd -g %{nfsnobody_uid} nfsnobody >/dev/null 2>&1 || :
fi

# Create nfsnobody uid as long as it does not already exist.
cat /etc/passwd | cut -d':' -f 3 | grep --quiet %{nfsnobody_uid} 2>/dev/null
if [ $? -eq 1 ]; then
    /usr/sbin/useradd -l -c "Anonymous NFS User" -r -g %{nfsnobody_uid} \
		-s /sbin/nologin -u %{nfsnobody_uid} -d /var/lib/nfs nfsnobody >/dev/null 2>&1 || :
fi

%post
if [ $1 -eq 1 ] ; then
	# Initial installation
	/bin/systemctl enable nfs-client.target >/dev/null 2>&1 || :
	/bin/systemctl start nfs-client.target  >/dev/null 2>&1 || :
fi

%systemd_post nfs-server

# %post -n nfsv4-client-utils
# if [ $1 -eq 1 ] ; then
# 	# Initial installation
# 	/bin/systemctl enable nfs-client.target >/dev/null 2>&1 || :
# 	/bin/systemctl start nfs-client.target  >/dev/null 2>&1 || :
# fi

%preun
if [ $1 -eq 0 ]; then
	%systemd_preun nfs-client.target
	%systemd_preun nfs-server.service
fi

# %preun -n nfsv4-client-utils
# if [ $1 -eq 0 ]; then
# 	%systemd_preun nfs-client.target
#
# 	rm -rf /etc/nfsmount.conf.d
#     rm -rf /var/lib/nfs/v4recovery
# fi

%postun
%systemd_postun_with_restart  nfs-client.target
%systemd_postun_with_restart  nfs-server

# %postun -n nfsv4-client-utils
# %systemd_postun_with_restart  nfs-client.target

/bin/systemctl --system daemon-reload >/dev/null 2>&1 || :

if [ $1 -eq 0 ] ; then
    rm -rf /var/lib/nfs/statd
    rm -rf /var/lib/nfs/v4recovery
fi

%triggerin -- nfs-utils > 1:2.1.1-3
/bin/systemctl try-restart gssproxy || :

%triggerun -- nfs-utils < 1:2.5.4-3
/bin/systemctl disable nfs-convert >/dev/null 2>&1 || :

%files
%config(noreplace) /etc/nfsmount.conf
%dir %{_sysconfdir}/exports.d
%dir %{_sharedstatedir}/nfs/v4recovery
%dir %attr(555, root, root) %{_sharedstatedir}/nfs/rpc_pipefs
%dir %{_sharedstatedir}/nfs
%dir %{_libexecdir}/nfs-utils
%dir %attr(700,rpcuser,rpcuser) %{_sharedstatedir}/nfs/statd
%dir %attr(700,rpcuser,rpcuser) %{_sharedstatedir}/nfs/statd/sm
%dir %attr(700,rpcuser,rpcuser) %{_sharedstatedir}/nfs/statd/sm.bak
%ghost %attr(644,rpcuser,rpcuser) %{_statdpath}/state
%config(noreplace) %{_sharedstatedir}/nfs/etab
%config(noreplace) %{_sharedstatedir}/nfs/rmtab
%config(noreplace) %{_sysconfdir}/request-key.d/id_resolver.conf
%config(noreplace) %{_sysconfdir}/modprobe.d/lockd.conf
%config(noreplace) %{_sysconfdir}/nfs.conf
%attr(0600,root,root) %config(noreplace) %{_sysconfdir}/gssproxy/24-nfs-server.conf
%doc linux-nfs/ChangeLog linux-nfs/KNOWNBUGS linux-nfs/NEW linux-nfs/README
%doc linux-nfs/THANKS linux-nfs/TODO
/sbin/rpc.statd
/sbin/nfsdcltrack
%{_sbindir}/exportfs
%{_sbindir}/nfsstat
%{_sbindir}/rpcdebug
%{_sbindir}/rpcctl
%{_sbindir}/rpc.mountd
%{_sbindir}/rpc.nfsd
%{_sbindir}/showmount
%{_sbindir}/rpc.idmapd
%{_sbindir}/rpc.gssd
%{_sbindir}/sm-notify
%{_sbindir}/start-statd
%{_sbindir}/mountstats
%{_sbindir}/nfsiostat
%{_sbindir}/nfsidmap
%{_sbindir}/blkmapd
%{_sbindir}/nfsconf
%{_sbindir}/nfsref
%{_sbindir}/nfsdcld
%{_sbindir}/nfsdclddb
%{_sbindir}/nfsdclnts
%{_libexecdir}/nfsrahead
%{_udevrulesdir}/99-nfs.rules
%{_mandir}/*/*
%{_pkgdir}/*/*

%attr(4755,root,root)	/sbin/mount.nfs

/sbin/mount.nfs4
/sbin/umount.nfs
/sbin/umount.nfs4

%files -n libnfsidmap
%doc support/nfsidmap/AUTHORS support/nfsidmap/README support/nfsidmap/COPYING
%config(noreplace) %{_sysconfdir}/idmapd.conf
%{_libdir}/libnfsidmap.so.*
%{_libdir}/libnfsidmap/*.so
%{_mandir}/man3/nfs4_uid_to_name.*

%files -n libnfsidmap-devel
%{_libdir}/pkgconfig/libnfsidmap.pc
%{_includedir}/nfsidmap.h
%{_includedir}/nfsidmap_plugin.h
%{_libdir}/libnfsidmap.so

# %files -n nfs-utils-coreos
# %dir %attr(555, root, root) %{_sharedstatedir}/nfs/rpc_pipefs
# %dir %attr(700,rpcuser,rpcuser) %{_sharedstatedir}/nfs/statd
# %dir %attr(700,rpcuser,rpcuser) %{_sharedstatedir}/nfs/statd/sm
# %dir %attr(700,rpcuser,rpcuser) %{_sharedstatedir}/nfs/statd/sm.bak
# %ghost %attr(644,rpcuser,rpcuser) %{_statdpath}/state
# %config(noreplace) %{_sysconfdir}/nfsmount.conf
# %config(noreplace) %{_sysconfdir}/nfs.conf
# %config(noreplace) %{_sysconfdir}/request-key.d/id_resolver.conf
# %{_sbindir}/nfsidmap
# %{_sbindir}/nfsstat
# %{_sbindir}/rpc.gssd
# %{_sbindir}/start-statd
# %{_sbindir}/showmount
# %{_libexecdir}/nfsrahead
# %{_udevrulesdir}/99-nfs.rules
# %attr(4755,root,root) /sbin/mount.nfs
# /sbin/mount.nfs4
# /sbin/rpc.statd
# /sbin/umount.nfs
# /sbin/umount.nfs4
# %{_mandir}/*/nfs.5.gz
# %{_mandir}/*/nfs.conf.5.gz
# %{_mandir}/*/nfsmount.conf.5.gz
# %{_mandir}/*/nfs.systemd.7.gz
# %{_mandir}/*/gssd.8.gz
# %{_mandir}/*/mount.nfs.8.gz
# %{_mandir}/*/nfsconf.8.gz
# %{_mandir}/*/nfsidmap.8.gz
# %{_mandir}/*/nfsstat.8.gz
# %{_mandir}/*/rpc.gssd.8.gz
# %{_mandir}/*/rpc.statd.8.gz
# %{_mandir}/*/showmount.8.gz
# %{_mandir}/*/statd.8.gz
# %{_mandir}/*/umount.nfs.8.gz
# %{_mandir}/*/nfsrahead.5.gz
# %{_pkgdir}/*/rpc-pipefs-generator
# %{_pkgdir}/*/auth-rpcgss-module.service
# %{_pkgdir}/*/nfs-client.target
# %{_pkgdir}/*/rpc-gssd.service
# %{_pkgdir}/*/rpc-statd.service
# %{_pkgdir}/*/rpc_pipefs.target
# %{_pkgdir}/*/var-lib-nfs-rpc_pipefs.mount
# 
# %files -n nfsv4-client-utils
# %config(noreplace) /etc/nfsmount.conf
# %dir %{_sharedstatedir}/nfs/v4recovery
# %dir %attr(555, root, root) %{_sharedstatedir}/nfs/rpc_pipefs
# %dir %{_libexecdir}/nfs-utils
# %config(noreplace) %{_sysconfdir}/request-key.d/id_resolver.conf
# %attr(0600,root,root) %config(noreplace) %{_sysconfdir}/gssproxy/24-nfs-server.conf
# %attr(0600,root,root) %config(noreplace) %{_sysconfdir}/nfsmount.conf.d/10-nfsv4.conf
# %{_sbindir}/rpc.gssd
# %{_sbindir}/rpcctl
# %{_sbindir}/nfsidmap
# %{_sbindir}/nfsstat
# %{_libexecdir}/nfsrahead
# %{_udevrulesdir}/99-nfs.rules
# %attr(4755,root,root) /sbin/mount.nfs
# /sbin/mount.nfs4
# /sbin/umount.nfs
# /sbin/umount.nfs4
# %{_mandir}/*/nfs.5.gz
# %{_mandir}/*/nfs.conf.5.gz
# %{_mandir}/*/nfsmount.conf.5.gz
# %{_mandir}/*/nfsrahead.5.gz
# %{_mandir}/*/gssd.8.gz
# %{_mandir}/*/mount.nfs.8.gz
# %{_mandir}/*/nfsconf.8.gz
# %{_mandir}/*/nfsidmap.8.gz
# %{_mandir}/*/rpc.gssd.8.gz
# %{_mandir}/*/mount.nfs.8.gz
# %{_mandir}/*/umount.nfs.8.gz
# %{_mandir}/*/nfsidmap.8.gz
# %{_mandir}/*/nfsstat.8.gz
# %{_mandir}/*/rpcctl.8.gz
# %{_pkgdir}/*/rpc-pipefs-generator
# %{_pkgdir}/*/auth-rpcgss-module.service
# %{_pkgdir}/*/nfs-client.target
# %{_pkgdir}/*/rpc-gssd.service
# %{_pkgdir}/*/rpc_pipefs.target
# %{_pkgdir}/*/var-lib-nfs-rpc_pipefs.mount
# 
# %files -n nfs-stats-utils
# %{_sbindir}/mountstats
# %{_sbindir}/nfsiostat
# %{_mandir}/*/mountstats.8.gz
# %{_mandir}/*/nfsiostat.8.gz



%changelog
* Mon Jul 24 2023 Wenger Chan <cnwn1111@hotmail.com> - 1.3.3-2
- Build in CentOS 7.6 with Kernel 5.4.249
