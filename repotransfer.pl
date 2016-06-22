#!/usr/bin/perl -w
# $Id: repotransfer.pl 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/repotransfer.pl $
#
# repotransfer
#  Copy files from corbin to one-way-transfer disk drive for transfer to high side networks
use strict;

# determine network
my $hostname = `uname -n`;
chomp $hostname;
my $domainname = `host $hostname | cut -d " " -f1`;
chomp $domainname;
my $net;
if ($domainname eq "corbin.llnl.gov") {
	$net = 'zdiv';
} else {
	die "Must be executed from a valid yum server\n";
}

print "Transfer disk mount point: ";
my $mtPoint = <STDIN>;
chomp $mtPoint;

# copy web server files to transfer disk
print "rsync -av --delete --exclude .htaccess /var/www/html/ ${mtPoint}/var/www/html\n";
`rsync -av --delete --exclude .htaccess /var/www/html/ ${mtPoint}/var/www/html`;

# copy transfer files to transfer disk
my $transferDir = "/transfer";
print "rsync -av --delete $transferDir/ ${mtPoint}/transfer\n";
`rsync -av --delete $transferDir/ ${mtPoint}/transfer`;

