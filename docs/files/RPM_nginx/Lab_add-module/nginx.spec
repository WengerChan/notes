%global  _hardened_build     1
%global  nginx_user          nginx

# Disable strict symbol checks in the link editor.
# See: https://src.fedoraproject.org/rpms/redhat-rpm-config/c/078af19
%undefine _strict_symbol_defs_build

%bcond_with geoip

# nginx gperftools support should be dissabled for RHEL >= 8
# see: https://bugzilla.redhat.com/show_bug.cgi?id=1931402
%if 0%{?rhel} >= 8
%global with_gperftools 0
%else
# gperftools exist only on selected arches
# gperftools *detection* is failing on ppc64*, possibly only configure
# bug, but disable anyway.
%ifnarch s390 s390x ppc64 ppc64le
%global with_gperftools 1
%endif
%endif

%global with_aio 1

%if 0%{?fedora} > 22
%global with_mailcap_mimetypes 1
%endif

# Cf. https://www.nginx.com/blog/creating-installable-packages-dynamic-modules/
%global nginx_abiversion %{version}

%global nginx_moduledir %{_libdir}/nginx/modules
%global nginx_moduleconfdir %{_datadir}/nginx/modules
%global nginx_srcdir %{_usrsrc}/%{name}-%{version}-%{release}

# Do not generate provides/requires from nginx sources
%global __provides_exclude_from ^%{nginx_srcdir}/.*$
%global __requires_exclude_from ^%{nginx_srcdir}/.*$


Name:              nginx
Epoch:             1
Version:           1.20.1
Release:           10%{?dist}

Summary:           A high performance web server and reverse proxy server
# BSD License (two clause)
# http://www.freebsd.org/copyright/freebsd-license.html
License:           BSD
URL:               https://nginx.org

Source0:           nginx-%{version}.tar.gz
Source1:           nginx-%{version}.tar.gz.asc
# Keys are found here: https://nginx.org/en/pgp_keys.html
Source2:           maxim.key
Source3:           mdounin.key
Source4:           sb.key
Source10:          nginx.service
Source11:          nginx.logrotate
Source12:          nginx.conf
Source13:          nginx-upgrade
Source14:          nginx-upgrade.8
Source15:          macros.nginxmods.in
Source16:          nginxmods.attr
Source102:         nginx-logo.png
Source103:         404.html
Source104:         50x.html
Source200:         README.dynamic
Source210:         UPGRADE-NOTES-1.6-to-1.10

# Add module: fancyindex
Source5:           ngx-fancyindex-0.5.2.tar.xz
Source6:           ngx-fancyindex-0.5.2.tar.xz.sig
%global ngx_fancyindex_version 0.5.2

# removes -Werror in upstream build scripts.  -Werror conflicts with
# -D_FORTIFY_SOURCE=2 causing warnings to turn into errors.
Patch0:            0001-remove-Werror-in-upstream-build-scripts.patch

# downstream patch - fix PIDFile race condition (rhbz#1869026)
# rejected upstream: https://trac.nginx.org/nginx/ticket/1897
Patch1:            0002-fix-PIDFile-handling.patch

# Fix for CVE-2021-3618: ALPACA: Application Layer Protocol Confusion - Analyzing and Mitigating Cracks in TLS Authentication
Patch2:            http://hg.nginx.org/nginx/raw-rev/ec1071830799

# Fix for CVE-2022-41741 and CVE-2022-41742: Memory corruption/disclosure in the ngx_http_mp4_module
Patch3:            0001-backport-fix-CVE-2022-41741-and-CVE-2022-41742.patch

BuildRequires:     make
BuildRequires:     gcc
BuildRequires:     gnupg2
%if 0%{?with_gperftools}
BuildRequires:     gperftools-devel
%endif
%if 0%{?fedora} || 0%{?rhel} >= 8
BuildRequires:     openssl-devel
%else
BuildRequires:     openssl11-devel
%endif
BuildRequires:     pcre-devel
BuildRequires:     zlib-devel

Requires:          nginx-filesystem = %{epoch}:%{version}-%{release}
%if 0%{?el7}
# centos-logos el7 does not provide 'system-indexhtml'
Requires:          system-logos redhat-indexhtml
# need to remove epel7 geoip sub-package, doesn't work anymore
# https://bugzilla.redhat.com/show_bug.cgi?id=1576034
# https://bugzilla.redhat.com/show_bug.cgi?id=1664957
Obsoletes:         nginx-mod-http-geoip <= 1:1.16
%else
Requires:          system-logos-httpd
%endif

Requires:          openssl
Requires:          pcre
Requires(pre):     nginx-filesystem
%if 0%{?with_mailcap_mimetypes}
Requires:          nginx-mimetypes
%endif
Provides:          webserver
%if 0%{?fedora} || 0%{?rhel} >= 8
Recommends:        logrotate
%endif

BuildRequires:     systemd
Requires(post):    systemd
Requires(preun):   systemd
Requires(postun):  systemd
# For external nginx modules
Provides:          nginx(abi) = %{nginx_abiversion}

%description
Nginx is a web server and a reverse proxy server for HTTP, SMTP, POP3 and
IMAP protocols, with a strong focus on high concurrency, performance and low
memory usage.

%package all-modules
Summary:           A meta package that installs all available Nginx modules
BuildArch:         noarch

%if %{with geoip}
Requires:          nginx-mod-http-geoip = %{epoch}:%{version}-%{release}
%endif
Requires:          nginx-mod-http-image-filter = %{epoch}:%{version}-%{release}
Requires:          nginx-mod-http-perl = %{epoch}:%{version}-%{release}
Requires:          nginx-mod-http-xslt-filter = %{epoch}:%{version}-%{release}
Requires:          nginx-mod-mail = %{epoch}:%{version}-%{release}
Requires:          nginx-mod-stream = %{epoch}:%{version}-%{release}
Requires:          nginx-mod-fancyindex = %{epoch}:%{version}-%{release}

%description all-modules
Meta package that installs all available nginx modules.

%package filesystem
Summary:           The basic directory layout for the Nginx server
BuildArch:         noarch
Requires(pre):     shadow-utils

%description filesystem
The nginx-filesystem package contains the basic directory layout
for the Nginx server including the correct permissions for the
directories.

%if %{with geoip}
%package mod-http-geoip
Summary:           Nginx HTTP geoip module
BuildRequires:     GeoIP-devel
Requires:          nginx(abi) = %{nginx_abiversion}
Requires:          GeoIP

%description mod-http-geoip
%{summary}.
%endif

%package mod-http-image-filter
Summary:           Nginx HTTP image filter module
BuildRequires:     gd-devel
Requires:          nginx(abi) = %{nginx_abiversion}
Requires:          gd

%description mod-http-image-filter
%{summary}.

%package mod-http-perl
Summary:           Nginx HTTP perl module
BuildRequires:     perl-devel
%if 0%{?fedora} >= 24 || 0%{?rhel} >= 7
BuildRequires:     perl-generators
%endif
BuildRequires:     perl(ExtUtils::Embed)
Requires:          nginx(abi) = %{nginx_abiversion}
Requires:          perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:          perl(constant)

%description mod-http-perl
%{summary}.

%package mod-http-xslt-filter
Summary:           Nginx XSLT module
BuildRequires:     libxslt-devel
Requires:          nginx(abi) = %{nginx_abiversion}

%description mod-http-xslt-filter
%{summary}.

%package mod-mail
Summary:           Nginx mail modules
Requires:          nginx(abi) = %{nginx_abiversion}

%description mod-mail
%{summary}.

%package mod-stream
Summary:           Nginx stream modules
Requires:          nginx(abi) = %{nginx_abiversion}

%description mod-stream
%{summary}.

%package mod-devel
Summary:           Nginx module development files
Requires:          nginx = %{epoch}:%{version}-%{release}
Requires:          make
Requires:          gcc
Requires:          gd-devel
%if 0%{?with_gperftools}
Requires:          gperftools-devel
%endif
%if %{with geoip}
Requires:          GeoIP-devel
%endif
Requires:          libxslt-devel
%if 0%{?fedora} || 0%{?rhel} >= 8
Requires:          openssl-devel
%else
Requires:          openssl11-devel
%endif
Requires:          pcre-devel
Requires:          perl-devel
Requires:          perl(ExtUtils::Embed)
Requires:          zlib-devel

%description mod-devel
%{summary}.

# Add mod-fancyindex
%package mod-fancyindex
Summary:           Nginx fancyindex modules
Requires:          nginx(abi) = %{nginx_abiversion}

%description mod-fancyindex
%{summary}. INFO: This package is built with "ngx-fancyindex-0.5.2.tar.xz".

%prep
# Combine all keys from upstream into one file
cat %{S:2} %{S:3} %{S:4} > %{_builddir}/%{name}.gpg
%{gpgverify} --keyring='%{_builddir}/%{name}.gpg' --signature='%{SOURCE1}' --data='%{SOURCE0}'
%autosetup -p1
cp %{SOURCE200} %{SOURCE210} %{SOURCE10} %{SOURCE12} .

%if 0%{?rhel} > 0 && 0%{?rhel} < 8
sed -i -e 's#KillMode=.*#KillMode=process#g' nginx.service
sed -i -e 's#PROFILE=SYSTEM#HIGH:!aNULL:!MD5#' nginx.conf
%endif

%if 0%{?rhel} == 7
sed \
  -e 's|\(ngx_feature_path=\)$|\1%{_includedir}/openssl11|' \
  -e 's|\(ngx_feature_libs="\)|\1-L%{_libdir}/openssl11 |' \
  -i auto/lib/openssl/conf
%endif

# Unpack fancyindex module
tar -xof %{SOURCE5} -C .


# Prepare sources for installation
cp -a ../%{name}-%{version} ../%{name}-%{version}-%{release}-src
mv ../%{name}-%{version}-%{release}-src .


%build
# nginx does not utilize a standard configure script.  It has its own
# and the standard configure options cause the nginx configure script
# to error out.  This is is also the reason for the DESTDIR environment
# variable.
export DESTDIR=%{buildroot}
# So the perl module finds its symbols:
nginx_ldopts="$RPM_LD_FLAGS -Wl,-E"
if ! ./configure \
    --prefix=%{_datadir}/nginx \
    --sbin-path=%{_sbindir}/nginx \
    --modules-path=%{nginx_moduledir} \
    --conf-path=%{_sysconfdir}/nginx/nginx.conf \
    --error-log-path=%{_localstatedir}/log/nginx/error.log \
    --http-log-path=%{_localstatedir}/log/nginx/access.log \
    --http-client-body-temp-path=%{_localstatedir}/lib/nginx/tmp/client_body \
    --http-proxy-temp-path=%{_localstatedir}/lib/nginx/tmp/proxy \
    --http-fastcgi-temp-path=%{_localstatedir}/lib/nginx/tmp/fastcgi \
    --http-uwsgi-temp-path=%{_localstatedir}/lib/nginx/tmp/uwsgi \
    --http-scgi-temp-path=%{_localstatedir}/lib/nginx/tmp/scgi \
    --pid-path=/run/nginx.pid \
    --lock-path=/run/lock/subsys/nginx \
    --user=%{nginx_user} \
    --group=%{nginx_user} \
    --with-compat \
    --with-debug \
%if 0%{?with_aio}
    --with-file-aio \
%endif
%if 0%{?with_gperftools}
    --with-google_perftools_module \
%endif
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_degradation_module \
    --with-http_flv_module \
%if %{with geoip}
    --with-http_geoip_module=dynamic \
%endif
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_perl_module=dynamic \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-mail=dynamic \
    --with-mail_ssl_module \
    --with-pcre \
    --with-pcre-jit \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-threads \
    --with-cc-opt="%{optflags} $(pcre-config --cflags)" \
    --with-ld-opt="$nginx_ldopts" \
    --add-dynamic-module=ngx-fancyindex-%{ngx_fancyindex_version}; then
  : configure failed
  cat objs/autoconf.err
  exit 1
fi

%make_build


%install
%make_install INSTALLDIRS=vendor

find %{buildroot} -type f -name .packlist -exec rm -f '{}' \;
find %{buildroot} -type f -name perllocal.pod -exec rm -f '{}' \;
find %{buildroot} -type f -empty -exec rm -f '{}' \;
find %{buildroot} -type f -iname '*.so' -exec chmod 0755 '{}' \;

install -p -D -m 0644 ./nginx.service \
    %{buildroot}%{_unitdir}/nginx.service
install -p -D -m 0644 %{SOURCE11} \
    %{buildroot}%{_sysconfdir}/logrotate.d/nginx

install -p -d -m 0755 %{buildroot}%{_sysconfdir}/systemd/system/nginx.service.d
install -p -d -m 0755 %{buildroot}%{_unitdir}/nginx.service.d

install -p -d -m 0755 %{buildroot}%{_sysconfdir}/nginx/conf.d
install -p -d -m 0755 %{buildroot}%{_sysconfdir}/nginx/default.d

install -p -d -m 0700 %{buildroot}%{_localstatedir}/lib/nginx
install -p -d -m 0700 %{buildroot}%{_localstatedir}/lib/nginx/tmp
install -p -d -m 0700 %{buildroot}%{_localstatedir}/log/nginx

install -p -d -m 0755 %{buildroot}%{_datadir}/nginx/html
install -p -d -m 0755 %{buildroot}%{nginx_moduleconfdir}
install -p -d -m 0755 %{buildroot}%{nginx_moduledir}

install -p -m 0644 ./nginx.conf \
    %{buildroot}%{_sysconfdir}/nginx

rm -f %{buildroot}%{_datadir}/nginx/html/index.html
%if 0%{?el7}
ln -s ../../doc/HTML/index.html \
      %{buildroot}%{_datadir}/nginx/html/index.html
ln -s ../../doc/HTML/img \
      %{buildroot}%{_datadir}/nginx/html/img
ln -s ../../doc/HTML/en-US \
      %{buildroot}%{_datadir}/nginx/html/en-US
%else
ln -s ../../testpage/index.html \
      %{buildroot}%{_datadir}/nginx/html/index.html
%endif
install -p -m 0644 %{SOURCE102} \
    %{buildroot}%{_datadir}/nginx/html
ln -s nginx-logo.png %{buildroot}%{_datadir}/nginx/html/poweredby.png
mkdir -p %{buildroot}%{_datadir}/nginx/html/icons

# Symlink for the powered-by-$DISTRO image:
ln -s ../../../pixmaps/poweredby.png \
      %{buildroot}%{_datadir}/nginx/html/icons/poweredby.png

%if 0%{?rhel} >= 9
ln -s ../../pixmaps/system-noindex-logo.png \
      %{buildroot}%{_datadir}/nginx/html/system_noindex_logo.png
%endif

install -p -m 0644 %{SOURCE103} %{SOURCE104} \
    %{buildroot}%{_datadir}/nginx/html

%if 0%{?with_mailcap_mimetypes}
rm -f %{buildroot}%{_sysconfdir}/nginx/mime.types
%endif

install -p -D -m 0644 %{_builddir}/nginx-%{version}/objs/nginx.8 \
    %{buildroot}%{_mandir}/man8/nginx.8

install -p -D -m 0755 %{SOURCE13} %{buildroot}%{_bindir}/nginx-upgrade
install -p -D -m 0644 %{SOURCE14} %{buildroot}%{_mandir}/man8/nginx-upgrade.8

for i in ftdetect ftplugin indent syntax; do
    install -p -D -m644 contrib/vim/${i}/nginx.vim \
        %{buildroot}%{_datadir}/vim/vimfiles/${i}/nginx.vim
done

%if %{with geoip}
echo 'load_module "%{nginx_moduledir}/ngx_http_geoip_module.so";' \
    > %{buildroot}%{nginx_moduleconfdir}/mod-http-geoip.conf
%endif
echo 'load_module "%{nginx_moduledir}/ngx_http_image_filter_module.so";' \
    > %{buildroot}%{nginx_moduleconfdir}/mod-http-image-filter.conf
echo 'load_module "%{nginx_moduledir}/ngx_http_perl_module.so";' \
    > %{buildroot}%{nginx_moduleconfdir}/mod-http-perl.conf
echo 'load_module "%{nginx_moduledir}/ngx_http_xslt_filter_module.so";' \
    > %{buildroot}%{nginx_moduleconfdir}/mod-http-xslt-filter.conf
echo 'load_module "%{nginx_moduledir}/ngx_mail_module.so";' \
    > %{buildroot}%{nginx_moduleconfdir}/mod-mail.conf
echo 'load_module "%{nginx_moduledir}/ngx_stream_module.so";' \
    > %{buildroot}%{nginx_moduleconfdir}/mod-stream.conf
echo 'load_module "%{nginx_moduledir}/ngx_http_fancyindex_module.so";' \
    > %{buildroot}%{nginx_moduleconfdir}/mod-fancyindex.conf

# Install files for supporting nginx module builds
## Install source files
mkdir -p %{buildroot}%{_usrsrc}
mv %{name}-%{version}-%{release}-src %{buildroot}%{nginx_srcdir}
## Install rpm macros
mkdir -p %{buildroot}%{_rpmmacrodir}
sed -e "s|@@NGINX_ABIVERSION@@|%{nginx_abiversion}|g" \
    -e "s|@@NGINX_MODDIR@@|%{nginx_moduledir}|g" \
    -e "s|@@NGINX_MODCONFDIR@@|%{nginx_moduleconfdir}|g" \
    -e "s|@@NGINX_SRCDIR@@|%{nginx_srcdir}|g" \
    %{SOURCE15} > %{buildroot}%{_rpmmacrodir}/macros.nginxmods
## Install dependency generator
install -Dpm0644 %{SOURCE16} %{buildroot}%{_fileattrsdir}/nginxmods.attr


%pre filesystem
getent group %{nginx_user} > /dev/null || groupadd -r %{nginx_user}
getent passwd %{nginx_user} > /dev/null || \
    useradd -r -d %{_localstatedir}/lib/nginx -g %{nginx_user} \
    -s /sbin/nologin -c "Nginx web server" %{nginx_user}
exit 0

%post
%systemd_post nginx.service

%if %{with geoip}
%post mod-http-geoip
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi
%endif

%post mod-http-image-filter
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi

%post mod-http-perl
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi

%post mod-http-xslt-filter
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi

%post mod-mail
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi

%post mod-stream
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi

%post mod-fancyindex
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl reload nginx.service >/dev/null 2>&1 || :
fi

%preun
%systemd_preun nginx.service

%postun
%systemd_postun nginx.service
if [ $1 -ge 1 ]; then
    /usr/bin/nginx-upgrade >/dev/null 2>&1 || :
fi

%files
%license LICENSE
%doc CHANGES README README.dynamic
%if 0%{?rhel} == 7
%doc UPGRADE-NOTES-1.6-to-1.10
%endif
%{_datadir}/nginx/html/*
%{_bindir}/nginx-upgrade
%{_sbindir}/nginx
%{_datadir}/vim/vimfiles/ftdetect/nginx.vim
%{_datadir}/vim/vimfiles/ftplugin/nginx.vim
%{_datadir}/vim/vimfiles/syntax/nginx.vim
%{_datadir}/vim/vimfiles/indent/nginx.vim
%{_mandir}/man3/nginx.3pm*
%{_mandir}/man8/nginx.8*
%{_mandir}/man8/nginx-upgrade.8*
%{_unitdir}/nginx.service
%config(noreplace) %{_sysconfdir}/nginx/fastcgi.conf
%config(noreplace) %{_sysconfdir}/nginx/fastcgi.conf.default
%config(noreplace) %{_sysconfdir}/nginx/fastcgi_params
%config(noreplace) %{_sysconfdir}/nginx/fastcgi_params.default
%config(noreplace) %{_sysconfdir}/nginx/koi-utf
%config(noreplace) %{_sysconfdir}/nginx/koi-win
%if ! 0%{?with_mailcap_mimetypes}
%config(noreplace) %{_sysconfdir}/nginx/mime.types
%endif
%config(noreplace) %{_sysconfdir}/nginx/mime.types.default
%config(noreplace) %{_sysconfdir}/nginx/nginx.conf
%config(noreplace) %{_sysconfdir}/nginx/nginx.conf.default
%config(noreplace) %{_sysconfdir}/nginx/scgi_params
%config(noreplace) %{_sysconfdir}/nginx/scgi_params.default
%config(noreplace) %{_sysconfdir}/nginx/uwsgi_params
%config(noreplace) %{_sysconfdir}/nginx/uwsgi_params.default
%config(noreplace) %{_sysconfdir}/nginx/win-utf
%config(noreplace) %{_sysconfdir}/logrotate.d/nginx
%attr(770,%{nginx_user},root) %dir %{_localstatedir}/lib/nginx
%attr(770,%{nginx_user},root) %dir %{_localstatedir}/lib/nginx/tmp
%attr(711,root,root) %dir %{_localstatedir}/log/nginx
%ghost %attr(640,%{nginx_user},root) %{_localstatedir}/log/nginx/access.log
%ghost %attr(640,%{nginx_user},root) %{_localstatedir}/log/nginx/error.log
%dir %{nginx_moduledir}
%dir %{nginx_moduleconfdir}

%files all-modules

%files filesystem
%dir %{_datadir}/nginx
%dir %{_datadir}/nginx/html
%dir %{_sysconfdir}/nginx
%dir %{_sysconfdir}/nginx/conf.d
%dir %{_sysconfdir}/nginx/default.d
%dir %{_sysconfdir}/systemd/system/nginx.service.d
%dir %{_unitdir}/nginx.service.d

%if %{with geoip}
%files mod-http-geoip
%{nginx_moduleconfdir}/mod-http-geoip.conf
%{nginx_moduledir}/ngx_http_geoip_module.so
%endif

%files mod-http-image-filter
%{nginx_moduleconfdir}/mod-http-image-filter.conf
%{nginx_moduledir}/ngx_http_image_filter_module.so

%files mod-http-perl
%{nginx_moduleconfdir}/mod-http-perl.conf
%{nginx_moduledir}/ngx_http_perl_module.so
%dir %{perl_vendorarch}/auto/nginx
%{perl_vendorarch}/nginx.pm
%{perl_vendorarch}/auto/nginx/nginx.so

%files mod-http-xslt-filter
%{nginx_moduleconfdir}/mod-http-xslt-filter.conf
%{nginx_moduledir}/ngx_http_xslt_filter_module.so

%files mod-mail
%{nginx_moduleconfdir}/mod-mail.conf
%{nginx_moduledir}/ngx_mail_module.so

%files mod-stream
%{nginx_moduleconfdir}/mod-stream.conf
%{nginx_moduledir}/ngx_stream_module.so

%files mod-fancyindex
%{nginx_moduleconfdir}/mod-fancyindex.conf
%{nginx_moduledir}/ngx_http_fancyindex_module.so

%files mod-devel
%{_rpmmacrodir}/macros.nginxmods
%{_fileattrsdir}/nginxmods.attr
%{nginx_srcdir}/


%changelog
* Fri Jun 30 2023 WengerChan <cnwn1111@hotmail.com> - 1:1.20.1-10
- add module aperezdc/ngx-fancyindex:0.5.2 to nginx<based on nginx-1.20.1-10.el7.src.rpm>
