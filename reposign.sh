#!/bin/bash
# $Id: $
# $Date: $
#
# reposign.sh
# This script needs to be run on the machines where the RPMs are built. RHEL5 signitures
# do not work on RHEL6 and vise versa.

# Do not allow root to sign rpms
if [[ $EUID -eq 0 ]]; then
	echo "RPMS should not be signed by root" 1>&2
	exit 1
fi

# Sign rpm files
cd ~/rpmbuild/RPMS/noarch/
rpm --addsign *.rpm
