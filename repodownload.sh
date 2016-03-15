#!/bin/sh
# $Id: repodownload.sh 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/repodownload.sh $
#
# repodownload

# Request transfer disk location
read -p "Repo mount location: " src_dir

dest_dir="/var/www/html"

rsync -av --delete --exclude=.htaccess ${src_dir}/repos/html/ ${dest_dir}/

