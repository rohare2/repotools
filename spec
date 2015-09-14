# $Id: spec.template 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/spec.template $
#
# Author: Rich O'Hare  <rohare2@gmail.com>
#
# Repo tools and release file
#
%define Name gs-release
%define Version 1.2
%define Release 7.redhat7_x86_64.gs

Name: %{Name}
Version: %{Version}
Release: %{Release}
Source: %{Name}-%{Version}-%{Release}.tgz
License: GPLv2
Group: SystemEnvironment/Base
BuildArch: noarch
URL: https://corbin.llnl.gov
Distribution: redhat7_x86_64
Vendor: Lawrence Livermore National Laboratory
Packager: Rich O'Hare <ohare2@llnl.gov
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
/etc/pki/rpm-gpg/RPM-GPG-KEY-FIE-6
/etc/yum.repos.d/gs.repo
/etc/yum.repos.d/fedora-epel.repo
/etc/yum.repos.d/lsi.repo
/etc/yum.repos.d/splunk.repo
