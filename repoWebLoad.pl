#!/usr/bin/perl -w
# $Id: $
# $Date: $
#
# repoWebLoad.pl
#
use strict;
use File::Copy;

my $debug = 1;
my $BASE_DIR = "/var/www/html/software";

# RPMS source directory
my $dir = $ARGV[0];
if (not defined $dir) {
	$dir = $ENV{"HOME"} . "/rpmbuild/RPMS";
	print "RPM source directory [$dir]: ";
	my $ans = <STDIN>;
	chomp $ans;
	if ($ans ne "") {
		$dir = $ans;
	}
}

-d $dir or die "rpmbuild directory does not exist";

# Push rpms to web server
my $basedir = $dir;
foreach my $subdir ("i386","x86_64","noarch") {
	$dir = $basedir . "/" . $subdir;
	if (-d $dir) { 
		print "$dir\n";
		opendir(DIR, "$dir") or warn "Can't open $dir";
		while (my $file = readdir(DIR)) {
			my ($net,$distro,$release,$arch,$dest);

			if ($file =~ /\.gs\./) {
				$net = 'gs';
			}
			if ($file =~ /\.hal\./) {
				$net = 'hal';
			}
			if ($file =~ /\.jwics\./) {
				$net = 'jwics';
			}
			defined $net or next;

			if ($file =~ /\.redhat5[_.]/) {
				$distro = 'redhat';
				$release = '5';
			}
			if ($file =~ /\.redhat6[_.]/) {
				$distro = 'redhat';
				$release = '6';
			}
			if ($file =~ /\.redhat7_[xi]/) {
				$distro = 'redhat';
				$release = '7';
			}
			if ($file =~ /\.redhat7\./) {
				$distro = 'redhat';
				$release = '7';
			}
			if ($file =~ /\.redhat7_server/) {
				$distro = 'redhat';
				$release = '7Server';
			}
			if ($file =~ /\.redhat7_workstation/) {
				$distro = 'redhat';
				$release = '7Workstation';
			}
			if ($file =~ /\.centos5[_.]/) {
				$distro = 'centos';
				$release = '5';
			}
			if ($file =~ /\.centos6[_.]/) {
				$distro = 'centos';
				$release = '6';
			}
			if ($file =~ /\.centos7[_.]/) {
				$distro = 'centos';
				$release = '7';
			}

			$file =~ /[_.]x86_64\./ && ($arch = 'x86_64');
			$file =~ /[_.]i386\./ && ($arch = 'i386');
			$file =~ /zdiv-release/ && ($arch = 'noarch');
			defined $arch or ($arch = "noarch");

			if (defined $distro) {
				$dest = $BASE_DIR . "/" . $net . "/" . $distro . "/" . $release . "/" . $arch;
				$debug && print "install -D -m 644 $dir/$file $dest/$file\n";
				`install -D -m 644 $dir/$file $dest/$file`;
			} else {
				print "No distro defined\n";
				print "$dir/$file\n";
			}
		}
		close DIR;
	}
}
