#!/bin/bash
# $Id: $
# $Date: $
#
# reposign.sh
# This script needs to be run on the machines where the RPMs are built. RHEL5 signitures
# do not work on RHEL6 and vise versa.

# Sign rpm files
cd ~/rpmbuild/RPMS/noarch/
rpm --addsign *.rpm
