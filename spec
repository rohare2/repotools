# $Id: spec 187 2014-10-23 03:21:38Z rohare $
# $URL: file:///usr/local/svn/admin/repotools/spec $
#
# Author: Rich O'Hare  <rohare2@gmail.com>
#
# Repo tools and release file
#
%define Name ohares-release
%define Version 1.0
%define Release 185.centos6_x86_64.ohares

Name: %{Name}
Version: %{Version}
Release: %{Release}
Source: %{Name}-%{Version}-%{Release}.tgz
License: GPLv2
Group: SystemEnvironment/Base
BuildArch: noarch
URL: https://www.ohares.us
Distribution: centos6_x86_64
Vendor: DVCAL
Packager: Rich O'Hare <rohare2@gmail.com
Provides: %{Name}, sw_src.xml
Summary: YUM environment configuration
%define _unpackaged_files_terminate_build 0

%description
Provides YUM repo definition files and release identification file.

%prep
%setup -q -n %{Name}

%build
exit 0

%install
make install
exit 0

%clean
exit 0

%files
%defattr(644, root, root)
/etc/%{Name}
/usr/local/etc/sw_src.xml
/etc/yum.repos.d/ohares.repo
