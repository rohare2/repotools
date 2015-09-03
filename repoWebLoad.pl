#!/usr/bin/perl -w
# $Id: $
# $Date: $
#
# repoWebLoad.pl
#
use strict;
use File::Copy;

my $debug = 1;
my @net = ('gs','hal','jwics');
my $BASE_DIR = "/var/www/html/software";

# RPMS source directory
my $dir = $ARGV[0];
if (not defined $dir) {
	$dir = $ENV{"HOME"} . "/rpmbuild/RPMS/noarch";
	print "RPM source directory [$dir]: ";
	my $ans = <STDIN>;
	chomp $ans;
	if ($ans ne "") {
		$dir = $ans;
	}
}

# Push rpms to web server
opendir(DIR, "$dir") or die "Can't open $dir";
foreach my $net (@net) {
	while (my $file = readdir(DIR)) {
		 my ($distro,$release,$arch,$dest);
		 if ($file =~ /^.*\.${net}\./) {
			my $repoPath = ${BASE_DIR} . "/" . $net;
			if ($file =~ /\.redhat5_/) {
				$distro = 'redhat';
				$release = '5';
			}
			if ($file =~ /\.redhat6_/) {
				$distro = 'redhat';
				$release = '6';
			}
			if ($file =~ /\.redhat7_/) {
				$distro = 'redhat';
				$release = '7';
			}
			if ($file =~ /\.centos5_/) {
				$distro = 'centos';
				$release = '5';
			}
			if ($file =~ /\.centos6_/) {
				$distro = 'centos';
				$release = '6';
			}
			if ($file =~ /\.centos7_/) {
				$distro = 'centos';
				$release = '7';
			}
			defined $distro or next;

			$file =~ /_x86_64\./ && ($arch = 'x86_64');
			$file =~ /_i386\./ && ($arch = 'i386');

			$dest = $BASE_DIR . "/" . $net . "/" . $distro . "/" . $release . "/" . $arch;

			$debug && print "install -D -m 644 -o apache -g apache $dir/$file $dest/$file\n";
			`install -D -m 644 -o apache -g apache $dir/$file $dest/$file`;
		} else {
			next;
		}
	}
}
close DIR;
