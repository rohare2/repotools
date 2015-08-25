#!/usr/bin/perl -w
# $Id: $
# $Date: $
#
# repoWebLoad.pl
#
use strict;
use File::Copy;
use Cwd;
use XML::Simple;
require "repotools.conf";

if ($< != 0) {
	print "This script must be run as root\n";
	exit (0);
}

our ($version,%baseurl,%vendor,%packager,%zdivDistroRepoList,%gsDistroRepoList);

# repo software location
my $BASE_DIR = "/var/www/html/software";
my $xmlFile = "/usr/local/etc/sw_src.xml";
my $sources = XMLin("$xmlFile", ForceArray => 1);

# determine domain name
my $hostname = `uname -n`;
chomp $hostname;
my $domainname = `host $hostname | cut -d " " -f1`;
chomp $domainname;

# determine local host distro
my $systemVersion = `lsb_release -sr`;
chomp $systemVersion;
$systemVersion =~ s/\..*//;

# determine acceptable arguments
my @open = ('gs');
my @high = ('hal','jwics');
my (@all,@good_args);
if ($domainname eq "corbin.llnl.gov" || $domainname eq "slave.llnl.gov") {
	@all = ('gs','hal','jwics');
	@good_args = ('all','gs','hal','high','jwics','open');
} else {
	die "Must be run from a known host";
}

my @net;

($#ARGV >= 0 && grep(/$ARGV[0]/i, @good_args)) || $#ARGV < 0 or
	die "unknown argument\nvalid arguments: @good_args\n";

if ( $#ARGV >= 0 ) {
	if ($ARGV[0] eq 'open') {
		 @net = @open;
	} elsif ($ARGV[0] eq 'high') {
		@net = @high;
	} elsif ($ARGV[0] eq 'all') {
		@net = @all;
	} else {
		@net = @ARGV;
	}
} else {
	die "You must make a network choice.\n";
}

sub evalRelease {
	my $net = shift;
	my $distro = shift;

	my $releaseNo = 2;
	$releaseNo =~ s/:.*//;
	$releaseNo =~ s/M//;
	$releaseNo =~ s/\..*$//g;
	my $release = $releaseNo . '.' . $distro . '.' . $net;

	return $release;
}

sub loadWebServer {
	my $name = shift;
	my $release = shift;
	my $net = shift;
	my $dir = $ENV{"HOME"} . "/rpmbuild/RPMS/noarch";
	my $file = sprintf("%s-%s-%s.noarch.rpm", $name,$version,$release);
	my ($distro,$arch);

	# copy to repo
	my $repoPath = $BASE_DIR . "/" . $net;
	my $dest = $repoPath;
	if ($file =~ /centos5/) {
		$distro = 'centos';
		$arch = '5';
		$dest = $dest . "/" . $distro . "/" . $arch;
	}
	if ($file =~ /centos6/) {
		$distro = 'centos';
		$arch = '6';
		$dest = $dest . "/" . $distro . "/" . $arch;
	}
	if ($file =~ /centos7/) {
		$distro = 'centos';
		$arch = '7';
		$dest = $dest . "/" . $distro . "/" . $arch;
	}
	if ($file =~ /redhat5/) {
		$distro = 'redhat';
		$arch = '5';
		$dest = $dest . "/" . $distro . "/" . $arch;
	}
	if ($file =~ /redhat6/) {
		$distro = 'redhat';
		$arch = '6';
		$dest = $dest . "/" . $distro . "/" . $arch;
	}
	if ($file =~ /redhat7/) {
		$distro = 'redhat';
		$arch = '7';
		$dest = $dest . "/" . $distro . "/" . $arch;
	}

	if ($file =~ /_i386/ || $file =~ /_x86_64/) {
		$file =~ /_i386/ && ($dest = $dest . "/i386");
		$file =~ /_x86_64/ && ($dest = $dest . "/x86_64");
	} else {
		next;
	}

	`install -D -m 660 $dir/$file $dest/$file`;

	# Make a link for this release
	if ($distro eq 'redhat') {
		my $cwd =  getcwd();
		foreach my $version ('Server','Workstation') {
			if ( ! -l "${repoPath}/${distro}/${arch}${version}") {
				chdir "${repoPath}/${distro}";
				system("ln -s $arch ${arch}${version}");
				chdir $cwd;
			}
		}
	}
}

# Push rpms to web server
foreach my $net (sort @net) {
	my ($name,$distroRepoList);

	no strict "refs";
	foreach my $distro (sort keys %{$distroRepoList}) {
		use strict "refs";

		# Only build RHEL5 on RHEL5 host, they SHA method
		my $buildVersion;
		if ($distro =~ /centos5/ || $distro =~ /redhat5/) {
			$buildVersion = '5';
		} elsif ($distro =~ /centos6/ || $distro =~ /redhat6/) {
			$buildVersion = '6';
		} elsif ($distro =~ /centos7/ || $distro =~ /redhat7/) {
			$buildVersion = '7';
		}
		if ($systemVersion == 5 && $buildVersion == 5) {
			print "$distro match\n";
		} elsif ($systemVersion >= 6 && $buildVersion >= 6) {
			print "$distro match\n";
		} else {
			next;
		}

		defined $net && $net ne '' or die "Net not defined: $!";
		my $release = evalRelease($net,$distro);

		loadWebServer($name,$release,$net);
	}
}

