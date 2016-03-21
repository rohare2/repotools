#!/bin/sh
# $Id: repodownload.sh 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/repodownload.sh $
#
# repodownload

# Request transfer disk location
read -p "Repo mount location: " src_dir

dest_dir="/var/www/html"

print "rsync -av --delete --exclude /projects/jwics --exclude /projects/hal ${src_dir}/var/www/html/ /var/www/html/\n";
rsync -av --delete --exclude /projects/jwics --exclude /projects/hal ${src_dir}/var/www/html/ /var/www/html/
print "rsync -av --delete ${src_dir}/var/www/cgi-bin/ /var/www/cgi-bin/\n";
rsync -av --delete ${src_dir}/var/www/cgi-bin/ /var/www/cgi-bin/

