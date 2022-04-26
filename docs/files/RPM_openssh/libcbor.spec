Name:		libcbor
Version:	0.7.0
Release:	5%{?dist}
Summary:	A CBOR parsing library
Packager:       Wenger Chan <cnwn1111@hotmail.com>

License:	MIT
URL:		http://libcbor.org
Source0:	https://github.com/PJK/%{name}/archive/v%{version}.tar.gz

BuildRequires:	cmake3
BuildRequires:	gcc
BuildRequires:	gcc-c++
BuildRequires:	python-breathe
BuildRequires:	python-sphinx
BuildRequires:	python-sphinx_rtd_theme
BuildRequires:  make
BuildRequires:  doxygen

%description
libcbor is a C library for parsing and generating CBOR.

%package	devel
Summary:	Development files for %{name}
Requires:	%{name}%{?_isa} = %{version}-%{release}

%description devel
The %{name}-devel contains libraries and header files for %{name}.

%prep
%setup -q


%build
%cmake3 -B . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFFIX="/usr" ./
%make_build cbor_shared
cd doc
make man


%install
%make_install
mkdir -p %{buildroot}%{_mandir}/man1
cp doc/build/man/* %{buildroot}%{_mandir}/man1

%ldconfig_scriptlets


%files
%license LICENSE.md
%doc README.md
%{_libdir}/libcbor.so.0*
%{_mandir}/man1/libcbor.1*

%files devel
%{_includedir}/cbor.h
%{_includedir}/cbor/*.h
%{_includedir}/cbor/internal/*.h
%{_libdir}/libcbor.so
%{_libdir}/pkgconfig/libcbor.pc


%changelog
* Sun Apr 24 2022 Wenger Chan <cnwn1111@hotmail.com> - 0.7.0-5
- RPM Packaging from libcbor v0.7.0.tar.gz
