#!/bin/sh
# $Id: repodownload.sh 189 2014-10-24 17:09:56Z rohare $
# $URL: file:///usr/local/svn/admin/repotools/repodownload.sh $
#
# repodownload

# Request transfer disk location
read -p "Repo mount location: " src_dir

dest_dir="/var/www/html/software"

rsync -av --delete --exclude=.htaccess ${src_dir}/repos/software/ ${dest_dir}/

