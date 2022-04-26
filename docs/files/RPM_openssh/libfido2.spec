Name:           libfido2

Version:        1.6.0
Release:        7%{?dist}
Summary:        FIDO2 library
Packager:       Wenger Chan <cnwn1111@hotmail.com>

License:        BSD
URL:            https://github.com/Yubico/%{name}
Source0:        %{name}-%{version}.tar.gz
Source1:        %{name}-%{version}.tar.gz.sig
Source2:        yubico-release-gpgkeys.asc
Patch0002:      libfido2-gcc11.patch

BuildRequires:  cmake3
BuildRequires:  hidapi-devel
BuildRequires:  libcbor-devel
BuildRequires:  libudev-devel
BuildRequires:  openssl-devel
BuildRequires:  gcc
BuildRequires:  gnupg2
BuildRequires:  make
#Requires:       (u2f-hidraw-policy if systemd-udev)

%description
%{name} is an open source library to support the FIDO2 protocol.  FIDO2 is
an open authentication standard that consists of the W3C Web Authentication
specification (WebAuthn API), and the Client to Authentication Protocol
(CTAP).  CTAP is an application layer protocol used for communication
between a client (browser) or a platform (operating system) with an external
authentication device (for example the Yubico Security Key).

################################################################################

%package devel

Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description devel
%{name}-devel contains development libraries and header files for %{name}.

################################################################################

%package -n fido2-tools

Summary:        FIDO2 tools
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description -n fido2-tools
FIDO2 command line tools to access and configure a FIDO2 compliant
authentication device.

################################################################################


%prep
%{gpgverify} --keyring='%{SOURCE2}' --signature='%{SOURCE1}' --data='%{SOURCE0}'
%autosetup -p1 -n %{name}-%{version}


%build
%cmake3
%cmake3_build


%install
%cmake3_install
# Remove static files per packaging guidelines
find %{buildroot} -type f -name "*.a" -delete -print


%files
%doc NEWS README.adoc
%license LICENSE
%{_libdir}/libfido2.so.1
%{_libdir}/libfido2.so.1.*

%files devel
%{_libdir}/pkgconfig/*
%{_libdir}/libfido2.so
%{_includedir}/*
%{_mandir}/man3/*

%files -n fido2-tools
%{_bindir}/*
%{_mandir}/man1/*


%changelog
* Sun Apr 24 2022 Wenger Chan <cnwn1111@hotmail.com> - 1.6.0-7
- RPM Packaging from libfido-1.6.0.tar.gz
