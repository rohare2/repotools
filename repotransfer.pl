#!/usr/bin/perl -w
# $Id: repotransfer.pl 184 2014-10-22 20:59:15Z rohare $
# $URL: file:///usr/local/svn/admin/repotools/repotransfer.pl $
#
# repotransfer
#  Copy files from corbin to one-way-transfer disk drive for transfer to high side networks
use strict;

# repo software location
my $softwareDir = "/var/www/html/software";

# determine network
my $hostname = `uname -n`;
chomp $hostname;
my $domainname = `host $hostname | cut -d " " -f1`;
chomp $domainname;
my $net;
if ($domainname eq "www.ohares.us") {
	$net = 'ohares';
} elsif ($domainname eq "corbin.llnl.gov") {
	$net = 'zdiv';
} else {
	die "Must be executed from a valid yum server\n";
}

# Request transfer disk location
print "Copy to transfer disk (Y/n): ";
my $ans = <STDIN>;
chomp $ans;
$ans =~ tr/a-z/A-Z/;
$ans eq 'Y' || exit;

print "Transfer to: ";
my $transferDest = <STDIN>;
chomp $transferDest;

# copy to transfer disk
print "rsync -av --delete $softwareDir/ $transferDest/\n";
`rsync -av --delete $softwareDir/ $transferDest/`;

