# $Id: $
#$HeadURL: https://corbin.llnl.gov/repos/admin/repotools/Makefile $
#
Name= ohares-release
Version= 1.4
Package= ohares-release-1.4-1.redhat7_workstation.x86_64
Source= ${Package}.tgz
BASE= $(shell pwd)
REPO= ???

RPMBUILD= ${HOME}/rpmbuild
RPM_BUILD_ROOT= ${RPMBUILD}/BUILDROOT

ETC_DIR= /etc
GPG_DIR= /etc/pki/rpm-gpg
REPO_DIR= /etc/yum.repos.d
USR_ETC_DIR= /usr/local/etc
USR_SBIN_DIR= /usr/local/sbin

ETC_FILES= ohares-release

GPG_FILES= RPM-GPG-KEY-GS-FIE

REPO_FILES= lsi.repo redhat7_workstation_x86_64.repo splunk.repo ohares.repo

USR_ETC_FILES= sw_src.xml

USR_SBIN_FILES= repocreate.pl \
	repodownload.pl \
	reposyncWrapper.pl \
	repotransfer.pl \
	repoupdate.pl \
	repoWebLoad.pl

rpmbuild: specfile source 
	rpmbuild -bb --buildroot ${RPM_BUILD_ROOT} ${RPMBUILD}/SPECS/${Package}.spec

specfile: spec
	@cat ./spec > ${RPMBUILD}/SPECS/${Package}.spec

source:
	if [ ! -d ${RPMBUILD}/SOURCES/${Name} ]; then \
		mkdir ${RPMBUILD}/SOURCES/${Name}; \
	fi
	rsync -av * ${RPMBUILD}/SOURCES/${Name}
	tar czvf ${RPMBUILD}/SOURCES/${Source} --exclude=.git -C ${RPMBUILD}/SOURCES ${Name}
	rm -fr ${RPMBUILD}/SOURCES/${Name}

install: make_path etc gpgfiles repo usr_etc usr_sbin

make_path:
	@if [ ! -d ${RPM_BUILD_ROOT}/${ETC_DIR} ]; then \
		mkdir -m 0755 -p ${RPM_BUILD_ROOT}/${ETC_DIR}; \
	fi;
	@if [ ! -d ${RPM_BUILD_ROOT}/${GPG_DIR} ]; then \
		mkdir -m 0755 -p ${RPM_BUILD_ROOT}/${GPG_DIR}; \
	fi;
	@if [ ! -d ${RPM_BUILD_ROOT}/${REPO_DIR} ]; then \
		mkdir -m 0755 -p ${RPM_BUILD_ROOT}/${REPO_DIR}; \
	fi;
	@if [ ! -d ${RPM_BUILD_ROOT}/${USR_ETC_DIR} ]; then \
		mkdir -m 0755 -p ${RPM_BUILD_ROOT}/${USR_ETC_DIR}; \
	fi;
	@if [ ! -d ${RPM_BUILD_ROOT}/${USR_SBIN_DIR} ]; then \
		mkdir -m 0755 -p ${RPM_BUILD_ROOT}/${USR_SBIN_DIR}; \
	fi;

etc:
	@for file in ${ETC_FILES}; do \
		install -p $$file ${RPM_BUILD_ROOT}/${ETC_DIR}; \
	done;

gpgfiles:
	@for file in ${GPG_FILES}; do \
		install -p $$file ${RPM_BUILD_ROOT}/${GPG_DIR}; \
	done;

repo:
	@for file in ${REPO_FILES}; do \
		install -p $$file ${RPM_BUILD_ROOT}/${REPO_DIR}; \
	done;

usr_etc:
	@for file in ${USR_ETC_FILES}; do \
		install -p $$file ${RPM_BUILD_ROOT}/${USR_ETC_DIR}; \
	done;

usr_sbin:
	@for file in ${USR_SBIN_FILES}; do \
		install -p $$file ${RPM_BUILD_ROOT}/${USR_SBIN_DIR}; \
	done;

clean:
	@rm -f ${RPMBUILD}/SPECS/${Name}-${Version}-${Release}.spec
	@rm -fR ${RPMBUILD}/SOURCES/${Source}
	@rm -fR ${RPMBUILD}/BUILD/${Name}
	@rm -fR ${RPMBUILD}/BUILDROOT/*

localinstall:
	@for file in ${USR_ETC_FILES}; do \
		install $$file ${USR_ETC_DIR}; \
	done;
	@chmod 640 /usr/local/etc/sw_src.xml
	@chgrp wheel /usr/local/etc/sw_src.xml
	@for file in ${GPG_FILES}; do \
		install $$file ${GPG_DIR}; \
	done;
	@chmod 644 /etc/pki/rpm-gpg/RPM-GPG-KEY-GS-FIE
	@chgrp wheel /etc/pki/rpm-gpg/RPM-GPG-KEY-GS-FIE
	@for file in ${USR_SBIN_FILES}; do \
		install $$file ${USR_SBIN_DIR}; \
		install $$file /var/www/html/software/tools; \
	done;
	@chgrp wheel ${USR_SBIN_DIR}/repo*
	@chmod 770 ${USR_SBIN_DIR}/repo*
