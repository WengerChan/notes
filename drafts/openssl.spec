%define soversion 1.1

%define x86_64

%global _performance_build 1

Summary: Utilities from the general purpose cryptography library with TLS implementation
Name: openssl
Version: 1.1.1n
Release: 1%{?dist}
Epoch: 1
Source: openssl-%{version}.tar.gz
Source1: hobble-openssl
Source2: Makefile.certificate
Source6: make-dummy-cert
Source7: renew-dummy-cert
Source9: opensslconf-new.h
Source10: opensslconf-new-warning.h
Source11: README.FIPS
Source12: ec_curve.c
Source13: ectest.c

Group: System Environment/Libraries
License: OpenSSL and ASL 2.0
URL: http://www.openssl.org/
BuildRequires: gcc
BuildRequires: coreutils, perl-interpreter, sed, zlib-devel, /usr/bin/cmp
BuildRequires: lksctp-tools-devel
BuildRequires: /usr/bin/rename
BuildRequires: /usr/bin/pod2man
BuildRequires: /usr/sbin/sysctl
BuildRequires: perl(Test::Harness), perl(Test::More), perl(Math::BigInt)
BuildRequires: perl(Module::Load::Conditional), perl(File::Temp)
BuildRequires: perl(Time::HiRes)
BuildRequires: perl(FindBin), perl(lib), perl(File::Compare), perl(File::Copy)
Requires: coreutils
Requires: %{name}-libs%{?_isa} = %{epoch}:%{version}-%{release}

%description
The OpenSSL toolkit provides support for secure communications between
machines. OpenSSL includes a certificate management tool and shared
libraries which provide various cryptographic algorithms and
protocols.

%package libs
Summary: A general purpose cryptography library with TLS implementation
Requires: ca-certificates >= 2008-5
Requires: crypto-policies >= 20180730
Recommends: openssl-pkcs11%{?_isa}
# Needed obsoletes due to the base/lib subpackage split
Obsoletes: openssl < 1:1.0.1-0.3.beta3
Obsoletes: openssl-fips < 1:1.0.1e-28
Provides: openssl-fips = %{epoch}:%{version}-%{release}

%description libs
OpenSSL is a toolkit for supporting cryptography. The openssl-libs
package contains the libraries that are used by various applications which
support cryptographic algorithms and protocols.

%package devel
Summary: Files for development of applications which will use OpenSSL
Requires: %{name}-libs%{?_isa} = %{epoch}:%{version}-%{release}
Requires: krb5-devel%{?_isa}, zlib-devel%{?_isa}
Requires: pkgconfig

%description devel
OpenSSL is a toolkit for supporting cryptography. The openssl-devel
package contains include files needed to develop applications which
support various cryptographic algorithms and protocols.

%package static
Summary:  Libraries for static linking of applications which will use OpenSSL
Requires: %{name}-devel%{?_isa} = %{epoch}:%{version}-%{release}

%description static
OpenSSL is a toolkit for supporting cryptography. The openssl-static
package contains static libraries needed for static linking of
applications which support various cryptographic algorithms and
protocols.

%package perl
Summary: Perl scripts provided with OpenSSL
Requires: perl-interpreter
Requires: %{name}%{?_isa} = %{epoch}:%{version}-%{release}

%description perl
OpenSSL is a toolkit for supporting cryptography. The openssl-perl
package provides Perl scripts for converting certificates and keys
from other formats to the formats used by the OpenSSL toolkit.

%prep
%setup -q -n %{name}-%{version}

# The hobble_openssl is called here redundantly, just to be sure.
# The tarball has already the sources removed.
%{SOURCE1} > /dev/null

cp %{SOURCE12} crypto/ec/
cp %{SOURCE13} test/

%build
# Figure out which flags we want to use.
# default
sslarch=%{_os}-%{_target_cpu}
%ifarch x86_64
sslflags=enable-ec_nistp_64_gcc_128
%endif

RPM_OPT_FLAGS="$RPM_OPT_FLAGS -Wa,--noexecstack -Wa,--generate-missing-build-notes=yes -DPURIFY $RPM_LD_FLAGS"

export HASHBANGPERL=/usr/bin/perl

./Configure \
	--prefix=%{_prefix} --openssldir=%{_sysconfdir}/pki/tls ${sslflags} \
	--system-ciphers-file=%{_sysconfdir}/crypto-policies/back-ends/openssl.config \
	zlib enable-camellia enable-seed enable-rfc3779 enable-sctp \
	enable-cms enable-md2 enable-rc5\
	enable-weak-ssl-ciphers \
	no-mdc2 no-ec2m no-sm2 no-sm4 \
	shared  ${sslarch} $RPM_OPT_FLAGS '-DDEVRANDOM="\"/dev/urandom\""'

make all

# Overwrite FIPS README
cp -f %{SOURCE11} .

# Clean up the .pc files
for i in  ; do
  sed -i '/^Libs.private:/{s/-L[^ ]* //;s/-Wl[^ ]* //}' $i
done

%check
# Verify that wlibcrypto.pc libssl.pc openssl.pchat was compiled actually works.

# Hack - either enable SCTP AUTH chunks in kernel or disable sctp for check
(sysctl net.sctp.addip_enable=1 && sysctl net.sctp.auth_enable=1) || \
(echo 'Failed to enable SCTP AUTH chunks, disabling SCTP for tests...' &&
 sed '/"zlib-dynamic" => "default",/a\ \ "sctp" => "default",' configdata.pm > configdata.pm.new && \
 touch -r configdata.pm configdata.pm.new && \
 mv -f configdata.pm.new configdata.pm)

# We must revert patch31 before tests otherwise they will fail
patch -p1 -R < %{PATCH31}

LD_LIBRARY_PATH=`pwd`${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH
crypto/fips/fips_standalone_hmac libcrypto.so.%{soversion} >.libcrypto.so.%{soversion}.hmac
ln -s .libcrypto.so.%{soversion}.hmac .libcrypto.so.hmac
crypto/fips/fips_standalone_hmac libssl.so.%{soversion} >.libssl.so.%{soversion}.hmac
ln -s .libssl.so.%{soversion}.hmac .libssl.so.hmac
OPENSSL_ENABLE_MD5_VERIFY=
export OPENSSL_ENABLE_MD5_VERIFY
OPENSSL_SYSTEM_CIPHERS_OVERRIDE=xyz_nonexistent_file
export OPENSSL_SYSTEM_CIPHERS_OVERRIDE
make test

# Add generation of HMAC checksum of the final stripped library
%define __spec_install_post \
    %{?__debug_package:%{__debug_install_post}} \
    %{__arch_install_post} \
    %{__os_install_post} \
    crypto/fips/fips_standalone_hmac $RPM_BUILD_ROOT%{_libdir}/libcrypto.so.%{version} >$RPM_BUILD_ROOT%{_libdir}/.libcrypto.so.%{version}.hmac \
    ln -sf .libcrypto.so.%{version}.hmac $RPM_BUILD_ROOT%{_libdir}/.libcrypto.so.%{soversion}.hmac \
    crypto/fips/fips_standalone_hmac $RPM_BUILD_ROOT%{_libdir}/libssl.so.%{version} >$RPM_BUILD_ROOT%{_libdir}/.libssl.so.%{version}.hmac \
    ln -sf .libssl.so.%{version}.hmac $RPM_BUILD_ROOT%{_libdir}/.libssl.so.%{soversion}.hmac \
%{nil}

%define __provides_exclude_from %{_libdir}/openssl

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
# Install OpenSSL.
install -d $RPM_BUILD_ROOT{%{_bindir},%{_includedir},%{_libdir},%{_mandir},%{_libdir}/openssl,%{_pkgdocdir}}
make DESTDIR=$RPM_BUILD_ROOT install
rename so.%{soversion} so.%{version} $RPM_BUILD_ROOT%{_libdir}/*.so.%{soversion}
for lib in $RPM_BUILD_ROOT%{_libdir}/*.so.%{version} ; do
	chmod 755 ${lib}
	ln -s -f `basename ${lib}` $RPM_BUILD_ROOT%{_libdir}/`basename ${lib} .%{version}`
	ln -s -f `basename ${lib}` $RPM_BUILD_ROOT%{_libdir}/`basename ${lib} .%{version}`.%{soversion}
done

# Install a makefile for generating keys and self-signed certs, and a script
# for generating them on the fly.
mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/pki/tls/certs
install -m644 %{SOURCE2} $RPM_BUILD_ROOT%{_pkgdocdir}/Makefile.certificate
install -m755 %{SOURCE6} $RPM_BUILD_ROOT%{_bindir}/make-dummy-cert
install -m755 %{SOURCE7} $RPM_BUILD_ROOT%{_bindir}/renew-dummy-cert

# Move runable perl scripts to bindir
mv $RPM_BUILD_ROOT%{_sysconfdir}/pki/tls/misc/*.pl $RPM_BUILD_ROOT%{_bindir}
mv $RPM_BUILD_ROOT%{_sysconfdir}/pki/tls/misc/tsget $RPM_BUILD_ROOT%{_bindir}

# Drop the SSLv3 methods from includes
sed -i '/ifndef OPENSSL_NO_SSL3_METHOD/,+4d' $RPM_BUILD_ROOT%{_includedir}/openssl/ssl.h

# Rename man pages so that they don't conflict with other system man pages.
pushd $RPM_BUILD_ROOT%{_mandir}
ln -s -f config.5 man5/openssl.cnf.5
for manpage in man*/* ; do
	if [ -L ${manpage} ]; then
		TARGET=`ls -l ${manpage} | awk '{ print $NF }'`
		ln -snf ${TARGET}ssl ${manpage}ssl
		rm -f ${manpage}
	else
		mv ${manpage} ${manpage}ssl
	fi
done
for conflict in passwd rand ; do
	rename ${conflict} ssl${conflict} man*/${conflict}*
# Fix dangling symlinks
	manpage=man1/openssl-${conflict}.*
	if [ -L ${manpage} ] ; then
		ln -snf ssl${conflict}.1ssl ${manpage}
	fi
done
popd

mkdir -m755 $RPM_BUILD_ROOT%{_sysconfdir}/pki/CA
mkdir -m700 $RPM_BUILD_ROOT%{_sysconfdir}/pki/CA/private
mkdir -m755 $RPM_BUILD_ROOT%{_sysconfdir}/pki/CA/certs
mkdir -m755 $RPM_BUILD_ROOT%{_sysconfdir}/pki/CA/crl
mkdir -m755 $RPM_BUILD_ROOT%{_sysconfdir}/pki/CA/newcerts

# Ensure the config file timestamps are identical across builds to avoid
# mulitlib conflicts and unnecessary renames on upgrade
touch -r %{SOURCE2} $RPM_BUILD_ROOT%{_sysconfdir}/pki/tls/openssl.cnf
touch -r %{SOURCE2} $RPM_BUILD_ROOT%{_sysconfdir}/pki/tls/ct_log_list.cnf

rm -f $RPM_BUILD_ROOT%{_sysconfdir}/pki/tls/openssl.cnf.dist
rm -f $RPM_BUILD_ROOT%{_sysconfdir}/pki/tls/ct_log_list.cnf.dist

# Determine which arch opensslconf.h is going to try to #include.
basearch=%{_arch}
%ifarch %{ix86}
basearch=i386
%endif
%ifarch sparcv9
basearch=sparc
%endif
%ifarch sparc64
basearch=sparc64
%endif

%ifarch %{multilib_arches}
# Do an opensslconf.h switcheroo to avoid file conflicts on systems where you
# can have both a 32- and 64-bit version of the library, and they each need
# their own correct-but-different versions of opensslconf.h to be usable.
install -m644 %{SOURCE10} \
	$RPM_BUILD_ROOT/%{_prefix}/include/openssl/opensslconf-${basearch}.h
cat $RPM_BUILD_ROOT/%{_prefix}/include/openssl/opensslconf.h >> \
	$RPM_BUILD_ROOT/%{_prefix}/include/openssl/opensslconf-${basearch}.h
install -m644 %{SOURCE9} \
	$RPM_BUILD_ROOT/%{_prefix}/include/openssl/opensslconf.h
%endif
LD_LIBRARY_PATH=`pwd`${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH

%files
%{!?_licensedir:%global license %%doc}
%license LICENSE
%doc FAQ NEWS README README.FIPS
%{_bindir}/make-dummy-cert
%{_bindir}/renew-dummy-cert
%{_bindir}/openssl
%{_mandir}/man1*/*
%{_mandir}/man5*/*
%{_mandir}/man7*/*
%{_pkgdocdir}/Makefile.certificate
%exclude %{_mandir}/man1*/*.pl*
%exclude %{_mandir}/man1*/c_rehash*
%exclude %{_mandir}/man1*/tsget*
%exclude %{_mandir}/man1*/openssl-tsget*

%files libs
%{!?_licensedir:%global license %%doc}
%license LICENSE
%dir %{_sysconfdir}/pki/tls
%dir %{_sysconfdir}/pki/tls/certs
%dir %{_sysconfdir}/pki/tls/misc
%dir %{_sysconfdir}/pki/tls/private
%config(noreplace) %{_sysconfdir}/pki/tls/openssl.cnf
%config(noreplace) %{_sysconfdir}/pki/tls/ct_log_list.cnf
%attr(0755,root,root) %{_libdir}/libcrypto.so.%{version}
%attr(0755,root,root) %{_libdir}/libcrypto.so.%{soversion}
%attr(0755,root,root) %{_libdir}/libssl.so.%{version}
%attr(0755,root,root) %{_libdir}/libssl.so.%{soversion}
%attr(0644,root,root) %{_libdir}/.libcrypto.so.*.hmac
%attr(0644,root,root) %{_libdir}/.libssl.so.*.hmac
%attr(0755,root,root) %{_libdir}/engines-%{soversion}

%files devel
%doc CHANGES doc/dir-locals.example.el doc/openssl-c-indent.el
%{_prefix}/include/openssl
%{_libdir}/*.so
%{_mandir}/man3*/*
%{_libdir}/pkgconfig/*.pc

%files static
%{_libdir}/*.a

%files perl
%{_bindir}/c_rehash
%{_bindir}/*.pl
%{_bindir}/tsget
%{_mandir}/man1*/*.pl*
%{_mandir}/man1*/c_rehash*
%{_mandir}/man1*/tsget*
%{_mandir}/man1*/openssl-tsget*
%dir %{_sysconfdir}/pki/CA
%dir %{_sysconfdir}/pki/CA/private
%dir %{_sysconfdir}/pki/CA/certs
%dir %{_sysconfdir}/pki/CA/crl
%dir %{_sysconfdir}/pki/CA/newcerts

%post libs -p /sbin/ldconfig

%postun libs -p /sbin/ldconfig

%changelog
* Mon Apr 11 2022 Wenger Chan <cnwn1111@hotmail.com> - 1:1.1.1n-1
- RPM Packaging from openssl-1.1.1n.tar.gz
