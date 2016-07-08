# $Id: spec.template 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/spec.template $
#
# Author: Rich O'Hare  <rohare2@gmail.com>
#
# Repo tools and release file
#
%define Name zdiv-release
%define Version 1.3
%define Release 17.redhat7_workstation.x86_64.jwics

Name: %{Name}
Version: %{Version}
Release: %{Release}
Source: zdiv-release-1.3-17.redhat7_workstation.x86_64.jwics.tgz
License: GPLv2
Group: SystemEnvironment/Base
BuildArch: noarch
URL: https://leeloo.ipa.llnl-doe.ic.gov
Distribution: redhat7_workstation
Vendor: Lawrence Livermore National Laboratory
Packager: Richard O'Hare <oharer@llnl-doe.ic.gov
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
/etc/pki/rpm-gpg/RPM-GPG-KEY-GS-FIE-7
/etc/yum.repos.d/zdiv.repo
/etc/yum.repos.d/lsi.repo
/etc/yum.repos.d/redhat7_workstation_x86_64.repo
/etc/yum.repos.d/splunk.repo
