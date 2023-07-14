%define _root_libdir    /%{_lib}

Name:			libtirpc
Version:		1.3.3
Release:		2%{?dist}
Summary:		Transport Independent RPC Library
License:		SISSL and BSD
URL:  			http://git.linux-nfs.org/?p=steved/libtirpc.git;a=summary
Source0:		http://downloads.sourceforge.net/libtirpc/libtirpc-%{version}.tar.bz2

# Add libtirpc 0.2.0 .so file
Source1:    libtirpc.so.1.0.10

BuildRequires:		automake, autoconf, libtool, pkgconfig
BuildRequires:		krb5-devel
BuildRequires:		gcc
BuildRequires: make

#
# RHEL9.2
#
Patch001: libtirpc-1.3.3-blacklist-close.patch
Patch002: libtirpc-1.3.3-clnt-raw-ptr.patch

#
# RHEL9.2
#
Patch003: libtirpc-1.3.3-dos-sleep.patch

%description
This package contains SunLib's implementation of transport-independent
RPC (TI-RPC) documentation.  This library forms a piece of the base of 
Open Network Computing (ONC), and is derived directly from the 
Solaris 2.3 source.

TI-RPC is an enhanced version of TS-RPC that requires the UNIX System V 
Transport Layer Interface (TLI) or an equivalent X/Open Transport Interface 
(XTI).  TI-RPC is on-the-wire compatible with the TS-RPC, which is supported 
by almost 70 vendors on all major operating systems.  TS-RPC source code 
(RPCSRC 4.0) remains available from several internet sites.

%package devel
Summary:		Development files for the libtirpc library
Requires:		%{name}%{?_isa} = %{version}-%{release}
Requires:		pkgconfig

%description devel
This package includes header files and libraries necessary for
developing programs which use the tirpc library.


%prep
%autosetup -p1

# Remove .orig files
find . -name "*.orig" | xargs rm -f

%build
sh autogen.sh
autoreconf -fisv
%configure
make all

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/etc
mkdir -p %{buildroot}%{_root_libdir}
mkdir -p %{buildroot}%{_libdir}/pkgconfig
make install DESTDIR=%{buildroot} \
	libdir=%{_root_libdir} pkgconfigdir=%{_libdir}/pkgconfig
# Don't package .a or .la files
rm -f %{buildroot}%{_root_libdir}/*.{a,la}

# Creat the man diretory
mv %{buildroot}%{_mandir}/man3 %{buildroot}%{_mandir}/man3t

# Add libtirpc 0.2.0 .so file
install -m755 %{SOURCE1} \
	%{buildroot}%{_root_libdir}/libtirpc.so.1.0.10
# /usr/bin/fipshmac %{buildroot}%{_root_libdir}/libtirpc.so.1.0.10
pushd %{buildroot}%{_root_libdir}
ln -s -f libtirpc.so.1.0.10 libtirpc.so.1
popd

%files
%doc AUTHORS ChangeLog NEWS README
%{_root_libdir}/libtirpc.so.*
%config(noreplace)%{_sysconfdir}/netconfig
%config(noreplace)%{_sysconfdir}/bindresvport.blacklist

%files devel
%{!?_licensedir:%global license %%doc}
%license COPYING
%dir %{_includedir}/tirpc
%dir %{_includedir}/tirpc/rpc
%dir %{_includedir}/tirpc/rpcsvc
%{_root_libdir}/libtirpc.so
%{_libdir}/pkgconfig/libtirpc.pc
%{_includedir}/tirpc/netconfig.h
%{_includedir}/tirpc/rpc/auth.h
%{_includedir}/tirpc/rpc/auth_des.h
%{_includedir}/tirpc/rpc/auth_gss.h
%{_includedir}/tirpc/rpc/auth_unix.h
%{_includedir}/tirpc/rpc/des.h
%{_includedir}/tirpc/rpc/des_crypt.h
%{_includedir}/tirpc/rpc/rpcsec_gss.h
%{_includedir}/tirpc/rpc/clnt.h
%{_includedir}/tirpc/rpc/clnt_soc.h
%{_includedir}/tirpc/rpc/clnt_stat.h
%{_includedir}/tirpc/rpc/key_prot.h
%{_includedir}/tirpc/rpc/nettype.h
%{_includedir}/tirpc/rpc/pmap_clnt.h
%{_includedir}/tirpc/rpc/pmap_prot.h
%{_includedir}/tirpc/rpc/pmap_rmt.h
%{_includedir}/tirpc/rpc/raw.h
%{_includedir}/tirpc/rpc/rpc.h
%{_includedir}/tirpc/rpc/rpc_com.h
%{_includedir}/tirpc/rpc/rpc_msg.h
%{_includedir}/tirpc/rpc/rpcb_clnt.h
%{_includedir}/tirpc/rpc/rpcb_prot.h
%{_includedir}/tirpc/rpc/rpcb_prot.x
%{_includedir}/tirpc/rpc/rpcent.h
%{_includedir}/tirpc/rpc/svc.h
%{_includedir}/tirpc/rpc/svc_auth.h
%{_includedir}/tirpc/rpc/svc_auth_gss.h
%{_includedir}/tirpc/rpc/svc_dg.h
%{_includedir}/tirpc/rpc/svc_mt.h
%{_includedir}/tirpc/rpc/svc_soc.h
%{_includedir}/tirpc/rpc/types.h
%{_includedir}/tirpc/rpc/xdr.h
%{_includedir}/tirpc/rpcsvc/crypt.h
%{_includedir}/tirpc/rpcsvc/crypt.x
%{_mandir}/*/*

%changelog
* Fri Jul 14 2023 Wenger Chan <cnwn1111@hotmail.com> - 1.3.3-2
- Build in CentOS 7.6 with Kernel 5.4.249 (And add libtirpc 0.2.0-49 .so file)
