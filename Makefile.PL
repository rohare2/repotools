#!/usr/bin/perl -w
# $Id: Makefile.PL 187 2014-10-23 03:21:38Z rohare $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/Makefile.PL $
#
use strict;
use File::Copy;
use Cwd;
use XML::Simple;
require "repotools.conf";

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

	my $releaseNo = 1;
	$releaseNo =~ s/:.*//;
	$releaseNo =~ s/M//;
	$releaseNo =~ s/\..*$//g;
	my $release = $releaseNo . '.' . $distro . '.' . $net;

	return $release;
}

sub editMakefile {
	my $name = shift;
	my $repofile = shift;
	my $net = shift;
	my $distro = shift;
	my $release = shift;
	my $distroRepoList = shift;
	my $file = 'Makefile';
	my $list = '';

	open (INPUT,"<$file") or die;
	my @input_array=<INPUT>;
	close(INPUT);
	my $input_scalar=join("",@input_array);
	my ($origStr, $replStr);

	if ($input_scalar =~ /^Name= /m) {
		$input_scalar =~ s/^Name=.*$/Name= $name/m;
	}

	if ($input_scalar =~ /^Version= /m) {
		$input_scalar =~ s/^Version=.*$/Version= $version/m;
	}

	if ($input_scalar =~ /^Distro= /m) {
		my $origStr = '^Distro=.*$';
		my $replStr = "Distro= $distro";
		$input_scalar =~ s/$origStr/$replStr/m;
	}

	if ($input_scalar =~ /^Release= /m) {
		my $origStr = '^Release=.*$';
		my $replStr = "Release= $release";
		$input_scalar =~ s/$origStr/$replStr/m;
	}

	if ($input_scalar =~ /^ETC_FILES= /m) {
		$input_scalar =~ s/^ETC_FILES=.*$/ETC_FILES= $name/m;
	}

	if ($input_scalar =~ /^REPO_FILES=/m) {
		$list = $list . " " . $repofile;
		if ($distroRepoList eq 'gsDistroRepoList') {
			foreach my $entry (@{$gsDistroRepoList{$distro}}) {
				$list = $list . " " . $entry;
			}
		} elsif ($distroRepoList eq 'zdivDistroRepoList') {
			foreach my $entry (@{$zdivDistroRepoList{$distro}}) {
				$list = $list . " " . $entry;
			}
		} else {
			die "no distroRepoList defined";
		}
		$input_scalar =~ s/^REPO_FILES=.*$/REPO_FILES=$list/m;
	}

	open (OUTPUT, "> $file") or die;
	print OUTPUT "$input_scalar";
	close OUTPUT;
}

sub editSpecFile {
	my $name = shift;
	my $repofile = shift;
	my $net = shift;
	my $distro = shift;
	my $release = shift;
	my $distroRepoList = shift;
	my $file = 'spec';

	copy("${file}.template","$file") or die "Copy failed: $!";
	open (INPUT,"<$file") or die;
	my @input_array=<INPUT>;
	close(INPUT);
	my $input_scalar=join("",@input_array);

	if ($input_scalar =~ /^%define Name /m) {
		$input_scalar =~ s/^%define Name.*$/%define Name $name/m;
	}

	if ($input_scalar =~ /^%define Version/m) {
		$input_scalar =~ s/%define Version.*$/%define Version $version/gm;
	}

	if ($input_scalar =~ /^%define Release/m) {
		$input_scalar =~ s/^%define Release.*$/%define Release $release/gm;
	}

	if ($input_scalar =~ /^Distribution:/m) {
		$input_scalar =~ s/^Distribution.*$/Distribution: $distro/gm;
	}

	if ($input_scalar =~ /^URL:/m) {
		$input_scalar =~ s/^URL.*$/URL: https:\/\/$baseurl{$net}/gm;
	}

	if ($input_scalar =~ /^Vendor:/m) {
		$input_scalar =~ s/^Vendor:.*$/Vendor: $vendor{$net}/gm;
	}

	if ($input_scalar =~ /^Packager:/m) {
		$input_scalar =~ s/^Packager:.*$/Packager: $packager{$net}/gm;
	}

	open (OUTPUT, "> $file") or die;
	print OUTPUT "$input_scalar";
	close OUTPUT;

	open (OUTPUT, ">>$file") or die;
	print OUTPUT ("/etc/yum.repos.d/$repofile\n");
	if ($distroRepoList eq 'gsDistroRepoList') {
		foreach my $entry (@{$gsDistroRepoList{$distro}}) {
			print OUTPUT ("/etc/yum.repos.d/$entry\n");
		}
	} elsif ($distroRepoList eq 'zdivDistroRepoList') {
		foreach my $entry (@{$zdivDistroRepoList{$distro}}) {
			print OUTPUT ("/etc/yum.repos.d/$entry\n");
		}
		if ($distro =~ /centos/) {
			print OUTPUT ("\n");
			print OUTPUT ("%posttrans\n");
			print OUTPUT ("/usr/bin/yum-config-manager --disable base\n");
			print OUTPUT ("/usr/bin/yum-config-manager --disable updates\n");
			print OUTPUT ("/usr/bin/yum-config-manager --disable extras\n");
			print OUTPUT ("/usr/bin/yum-config-manager --disable centosplus\n");
		}
	} else {
		die "no DistroRepoList defined";
	}
	close OUTPUT;
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

sub fixRepoBaseurl {
	my $net = shift;
	my $url = $baseurl{$net};

	opendir (DIR, ".") or die $!;
	while (my $file = readdir(DIR)) {
		if ($file =~ /.*\.repo/) {
			open (INPUT, "$file") or die;
			my @input_array=<INPUT>;
			my $input_scalar=join("",@input_array);
			close(INPUT);

			if ($input_scalar =~ /^baseurl=https?:.*\/software/m) {
				$input_scalar =~ s/^baseurl=https?:.*\/software/baseurl=https:\/\/${url}\/software/gm;
			}

			open (OUTPUT, "> $file") or die;
			print OUTPUT "$input_scalar";
			close OUTPUT;
		}
	}
}

sub fixRepoDistro {
	my $net = shift;
	my $distro = shift;
	my $file = $net . ".repo";

	open (INPUT, "$file") or die "Can not open $file: $!";
	my @input_array=<INPUT>;
	my $input_scalar=join("",@input_array);
	close(INPUT);

	$distro =~ 'redhat' && 
		($input_scalar =~ s/\/centos\//\/redhat\//mg);
	$distro =~ 'centos' && 
		($input_scalar =~ s/\/redhat\//\/centos\//mg);

	open (OUTPUT, "> $file") or die;
	print OUTPUT "$input_scalar";
	close OUTPUT;
}

foreach my $net (sort @net) {
	my ($name,$repofile,$distroRepoList);
	fixRepoBaseurl($net);

	# network definitions
	if ($net eq 'gs') {
		$name = 'gs-release';
		$repofile = 'gs.repo';
		$distroRepoList = "gsDistroRepoList";
	}
	if ($net eq 'hal') {
		$name = 'zdiv-release';
		$repofile = 'hal.repo';
		$distroRepoList = "zdivDistroRepoList";
	}
	if ($net eq 'jwics') {
		$name = 'zdiv-release';
		$repofile = 'jwics.repo';
		$distroRepoList = "zdivDistroRepoList";
	}

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

		# Fix the baseurl in repo file
		fixRepoDistro($net,$distro);

		# Make release file
		my $file = "$name";
		open (OUTPUT, "> $file") or die;
		print OUTPUT ("${file} ${version}-${release}\n");
		close OUTPUT;

		editMakefile($name,$repofile,$net,$distro,$release,$distroRepoList);
		editSpecFile($name,$repofile,$net,$distro,$release,$distroRepoList);
		system("make rpmbuild");
		loadWebServer($name,$release,$net);
	}
}

