#!/usr/bin/perl -w
# $Id: $
# $Date: $
#
# repotransfer
#  Copy files from corbin to one-way-transfer disk drive for transfer to high side networks
use strict;

print "Transfer disk mount point: ";
my $mntPoint = <STDIN>;
chomp $mntPoint;

# copy web server files to transfer disk
system "rsync", "-av", "--delete", "--exclude", ".htaccess", "/var/www/html/software/", "${mntPoint}/var/www/html/software/";

# copy transfer files to transfer disk
my $transferDir = "/transfer";
system "rsync", "-av", "--delete", "$transferDir/", "${mntPoint}/transfer/";

