# $Id: $
# $Date: $
#
# Author: Rich O'Hare  <rohare2@gmail.com>
#
# Repo tools and release file
#
%define Name local-release
%define Version 1.4
%define Release 1.redhat7_workstation.x86_64

Name: %{Name}
Version: %{Version}
Release: %{Release}
Source: %{Name}-%{Version}-%{Release}.tgz
License: GPLv2
Group: SystemEnvironment/Base
BuildArch: noarch
URL: https://local-yum
Distribution: redhat7_workstation
Vendor: Lawrence Livermore National Laboratory
Packager: Rich O'Hare <ohare2@llnl.gov
Provides: %{Name}, %{Name}.repo, sw_src.xml
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
/etc/pki/rpm-gpg/RPM-GPG-KEY-GS-FIE
/etc/yum.repos.d/lsi.repo
/etc/yum.repos.d/redhat7_workstation_x86_64.repo
/etc/yum.repos.d/splunk.repo
/etc/yum.repos.d/local.repo
