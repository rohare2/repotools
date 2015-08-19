#!/bin/bash
# $Id: $
# $Date: $
#
# reposign.sh

# Sign rpm files
cd ~/rpmbuild/RPMS/noarch/
rpm --addsign *.rpm
