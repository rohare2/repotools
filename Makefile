#$Id: Makefile 187 2014-10-23 03:21:38Z rohare $
#$HeadURL: https://corbin.llnl.gov/repos/admin/repotools/Makefile $
#
Name= zdiv-release
Version= 1.2
Release= 6.redhat7_x86_64.jwics
Distro= redhat7_x86_64
Source= ${Name}-${Version}-${Release}.tgz
BASE= $(shell pwd)

RPMBUILD= ${HOME}/rpmbuild
RPM_BUILD_ROOT= ${RPMBUILD}/BUILDROOT

ETC_DIR= /etc
GPG_DIR= /etc/pki/rpm-gpg
REPO_DIR= /etc/yum.repos.d
USR_ETC_DIR= /usr/local/etc
USR_SBIN_DIR= /usr/local/sbin

ETC_FILES= zdiv-release

GPG_FILES= RPM-GPG-KEY-FIE-6

USR_ETC_FILES= sw_src.xml

USR_SBIN_FILES= repocreate.pl \
	reposyncWrapper.pl \
	repotransfer.pl \
	repoupdate.pl \
	repoWebLoad.pl

rpmbuild: specfile source 
	rpmbuild -bb --buildroot ${RPM_BUILD_ROOT} ${RPMBUILD}/SPECS/${Name}-${Version}-${Release}.spec

specfile: spec
	@cat ./spec > ${RPMBUILD}/SPECS/${Name}-${Version}-${Release}.spec

source:
	if [ ! -d ${RPMBUILD}/SOURCES/${Name} ]; then \
		mkdir ${RPMBUILD}/SOURCES/${Name}; \
	fi
	rsync -av * ${RPMBUILD}/SOURCES/${Name}
	tar czvf ${RPMBUILD}/SOURCES/${Source} --exclude=.git -C ${RPMBUILD}/SOURCES ${Name}
	rm -fr ${RPMBUILD}/SOURCES/${Name}

install: make_path etc gpg repo usr_etc usr_sbin

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

gpg:
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
	@chmod 644 /etc/pki/rpm-gpg/RPM-GPG-KEY-FIE-*
	@chgrp wheel /etc/pki/rpm-gpg/RPM-GPG-KEY-FIE-*
	@for file in ${USR_SBIN_FILES}; do \
		install $$file ${USR_SBIN_DIR}; \
	done;
	@chgrp wheel ${USR_SBIN_DIR}/repo*
	@chmod 770 ${USR_SBIN_DIR}/repo*

