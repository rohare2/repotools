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
my $mntPoint = <STDIN>;
chomp $mntPoint;

# copy web server files to transfer disk
system "rsync", "-av", "--delete", "--exclude", ".htaccess", "/var/www/html/", "${mntPoint}/var/www/html";

# copy transfer files to transfer disk
my $transferDir = "/transfer";
system "rsync", "-av", "--delete", "$transferDir/", "${mntPoint}/transfer";

my $Dir = "${mntPoint}/transfer/ohare2";
if ( ! -d $Dir ) {
	`mkdir -p -m 0770 $Dir`;
}
`chown -R ohare2:ohare2 $Dir`;

if ( ! -d "${Dir}/corbin" ) {
	`mkdir -p -m 0770 "$Dir/corbin"`;
}
`chown ohare2:ohare2 "$Dir/corbin"`;

if ( ! -d "${Dir}/corbin/git" ) {
	`mkdir -p -m 0770 "$Dir/corbin/git"`;
}
`chown ohare2:ohare2 "$Dir/corbin/git"`;

# dump fie_it database
`/usr/bin/mysqldump --single-transaction --databases fie_it > ${Dir}/corbin/fie_it_dump`;
`chown ohare2:ohare2 ${Dir}/corbin/fie_it_dump`;
`chmod 0440 ${Dir}/corbin/fie_it_dump`;

# copy git repos
system("rsync", "-av", "/opt/git/", "${Dir}/corbin/git/");
`chown ohare2:ohare2 ${Dir}/corbin/git`;

