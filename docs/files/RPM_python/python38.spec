%global pybasever 3.8
%global pyshortver 38
%global pyfullver 3.8.13

%global install_dir /usr/local/python-%{pyfullver}

%global debug_package %{nil}

Name: python38
Summary: Interpreter of the Python programming language
URL: https://www.python.org/
Version: %{pyfullver}
Release: 1%{?dist}
License: Python

Source0: Python-%{pyfullver}.tar.xz
Source1: python%{pyshortver}-%{pyfullver}-ldconfig.conf
Source2: python%{pyshortver}-%{pyfullver}-profile.sh

BuildRequires: autoconf
BuildRequires: expat-devel
BuildRequires: libffi-devel
BuildRequires: libGL-devel
BuildRequires: libuuid-devel
BuildRequires: ncurses-devel
BuildRequires: glibc-devel
BuildRequires: libffi-devel
BuildRequires: xz-devel
BuildRequires: zlib-devel
BuildRequires: systemtap-sdt-devel
Conflicts: python3
Conflicts: python34
Conflicts: python36

%description
Python is an accessible, high-level, dynamically typed, interpreted programming
language, designed with an emphasis on code readability.
It includes an extensive standard library, and has a vast ecosystem of
third-party libraries.


%prep
%setup -q -n Python-%{pyfullver}

%build
./configure \
  --prefix=%{install_dir} \
  --enable-ipv6 \
  --enable-shared \
  --with-computed-gotos=no \
  --with-dbmliborder=gdbm:ndbm:bdb \
  --with-system-expat --with-system-ffi \
  --enable-loadable-sqlite-extensions \
  --with-dtrace \
  --with-ssl-default-suites=openssl \
  --without-ensurepip \
  --disable-optimizations


%install
rm -rf %{buildroot}
make -j 8
make DESTDIR=%{buildroot} INSTALL="install -p" install

# Remove tests for python3-tools which was removed in
# https://bugzilla.redhat.com/show_bug.cgi?id=1312030
rm -rf %{buildroot}/%{install_dir}/lib/python%{pybasever}/test/test_tools

# Get rid of DOS batch files:
find %{buildroot} -name \*.bat -exec rm {} \;

# Get rid of backup files:
find %{buildroot}/ -name "*~" -exec rm -f {} \;
find . -name "*~" -exec rm -f {} \;

# Add file to '/etc/ld.so.conf.d/' 
mkdir -p %{buildroot}/etc/ld.so.conf.d/
install -m 644 %{SOURCE1} \
    %{buildroot}/etc/ld.so.conf.d/

# Add file to '/etc/profile.d/' 
mkdir -p %{buildroot}/etc/profile.d/
install -m 644 %{SOURCE2} \
    %{buildroot}/etc/profile.d/

# Fix Error: '#! /usr/local/bin/python'
pushd %{buildroot}/%{install_dir}/lib/python%{pybasever}
sed -i 's@^#! /usr/local/bin/python@#!/usr/bin/env python3@' cgi.py
popd

%post
ldconfig
ln -sf %{install_dir}/share/man/man1/python3.1 /usr/share/man/man1/python3.1 
ln -sf %{install_dir}/share/man/man1/python3.8.1 /usr/share/man/man1/python3.8.1 

%postun
ldconfig
rm -f /usr/share/man/man1/python3.1
rm -f /usr/share/man/man1/python3.8.1

%files
%attr(-,root,root) %dir %{install_dir}
%attr(-,root,root)      %{install_dir}/*
%attr(-,root,root)      /etc/ld.so.conf.d/python%{pyshortver}-%{pyfullver}-ldconfig.conf
%attr(-,root,root)      /etc/profile.d/python%{pyshortver}-%{pyfullver}-profile.sh

%changelog
* Mon Aug 15 2022 Wenger Chan <cnwn1111@hotmail.com> - 3.8.13-1
- RPM Packaging from Python-3.8.13.tar.xz

