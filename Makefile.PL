#!/usr/bin/perl -w
# $Id: Makefile.PL 187 2014-10-23 03:21:38Z rohare $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/Makefile.PL $
#
use strict;
use File::Copy;
use Cwd;
use XML::Simple;
require "repotools.conf";

our ($version,$releaseNo,%vendor,%packager,%zdivDistroRepoList);

# repo software location
my $BASE_DIR = "/var/www/html/software";
my $xmlFile = "/usr/local/etc/sw_src.xml";
my $sources = XMLin("$xmlFile", ForceArray => 1);
my $baseurl = "zdiv-yum";

# determine hostname 
my $hostname = `uname -n`;
chomp $hostname;

# determine local host distro
my $systemVersion = `lsb_release -sr`;
chomp $systemVersion;
$systemVersion =~ s/\..*//;

# determine acceptable arguments
if ($hostname eq "captive.llnl.gov" ||
		$hostname eq "convict.llnl.gov" ||
		$hostname eq "corbin.llnl.gov" ||
		$hostname eq "serf.llnl.gov" ||
		$hostname eq "slave.llnl.gov") {
} else {
	die "Must be run from a known host";
}


sub evalPackage {
	my $repolistEntry = shift;
	my $buildDistro = $repolistEntry;
	my $buildArch;

	if ($buildDistro =~ /_i386/) {
		$buildDistro =~ s/_i386//;
		$buildArch = "i386";
	} 
	if ($buildDistro =~ /_x86_64/) {
		$buildDistro =~ s/_x86_64//;
		$buildArch = "x86_64";
	} 
	
	return ($buildDistro,$buildArch);
}

sub editMakefile {
	my $buildDistro = shift;
	my $buildArch = shift;
	my $repolistEntry = shift;
	my $distroRepoList = shift;
	my $buildVersion = shift;
	my $package = "zdiv-release-${version}-${releaseNo}.${buildDistro}.${buildArch}";
	my $list = '';
	my $file = 'Makefile';

	open (INPUT,"<$file") or die;
	my @input_array=<INPUT>;
	close(INPUT);
	my $input_scalar=join("",@input_array);
	my ($origStr, $replStr);

	$input_scalar =~ /^Version= /m && ($input_scalar =~ s/^Version=.*$/Version= $version/m);
	$input_scalar =~ /^Package= /m && ($input_scalar =~ s/^Package=.*$/Package= $package/m);

	if ($input_scalar =~ /^REPO_FILES=/m) {
		if ($distroRepoList eq 'zdivDistroRepoList') {
			foreach my $entry (@{$zdivDistroRepoList{$repolistEntry}}) {
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
	my $buildDistro = shift;
	my $buildArch = shift;
	my $repolistEntry = shift;
	my $distroRepoList = shift;
	my $buildVersion = shift;
	my $release = "${releaseNo}.${buildDistro}.${buildArch}.${net}";
	my $source = "zdiv-release-${version}-${release}.tgz";
	my $file = 'spec';
	my $vendor = 'Lawrence Livermore National Laboratory';
	my $packager = 'Rich O\'Hare <ohare2@llnl.gov'

	copy("${file}.template","$file") or die "Copy failed: $!";
	open (INPUT,"<$file") or die;
	my @input_array=<INPUT>;
	close(INPUT);
	my $input_scalar=join("",@input_array);

	$input_scalar =~ /^%define Version/m && ($input_scalar =~ s/^%define Version.*$/%define Version ${version}/m);
	$input_scalar =~ /^%define Release/m && ($input_scalar =~ s/^%define Release.*$/%define Release ${release}/m);
	$input_scalar =~ /^Source:/m && ($input_scalar =~ s/^Source:.*$/Source: ${source}/m);
	$input_scalar =~ /^BuildArch/m && ($input_scalar =~ s/^BuildArch.*$/BuildArch: noarch/m);
	$input_scalar =~ /^Distribution:/m && ($input_scalar =~ s/^Distribution.*$/Distribution: ${buildDistro}/m);
	$input_scalar =~ /^URL:/m && ($input_scalar =~ s/^URL.*$/URL: https:\/\/$baseurl/gm);
	$input_scalar =~ /^Vendor:/m && ($input_scalar =~ s/^Vendor:.*$/Vendor: ${vendor}/gm);
	$input_scalar =~ /^Packager:/m && ($input_scalar =~ s/^Packager:.*$/Packager: ${packager}/gm);

	open (OUTPUT, "> $file") or die;
	print OUTPUT "$input_scalar";
	close OUTPUT;

	open (OUTPUT, ">> $file") or die;
	if ($distroRepoList eq 'zdivDistroRepoList') {
		foreach my $entry (@{$zdivDistroRepoList{$repolistEntry}}) {
			print OUTPUT ("/etc/yum.repos.d/${entry}\n");
		}
		if ($repolistEntry =~ /centos/) {
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

sub fixRepoBaseurl {
	my $url = $baseurl;

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
	my $distro = shift;
	my $file = "zdiv.repo";

	open (INPUT, "$file") or die "Can not open $file: $!";
	my @input_array=<INPUT>;
	my $input_scalar=join("",@input_array);
	close(INPUT);

	$distro =~ 'redhat' && ($input_scalar =~ s/\/centos\//\/redhat\//mg);
	$distro =~ 'centos' && ($input_scalar =~ s/\/redhat\//\/centos\//mg);

	open (OUTPUT, "> $file") or die;
	print OUTPUT "$input_scalar";
	close OUTPUT;
}

my ($name,$distroRepoList);
fixRepoBaseurl();

$name = 'zdiv-release';
$distroRepoList = "zdivDistroRepoList";

no strict "refs";
foreach my $repolistEntry (sort keys %{$distroRepoList}) {
	use strict "refs";

	# Only build RHEL5 on RHEL5 host, they use SHA method
	my $buildVersion;
	if ($repolistEntry =~ /centos5/ || $repolistEntry =~ /redhat5/) {
		$buildVersion = '5';
	} elsif ($repolistEntry =~ /centos6/ || $repolistEntry =~ /redhat6/) {
		$buildVersion = '6';
	} elsif ($repolistEntry =~ /centos7/ || $repolistEntry =~ /redhat7/) {
		$buildVersion = '7';
	}
	if ($systemVersion == 5 && $buildVersion == 5) {
		print "$repolistEntry match\n";
	} elsif ($systemVersion == 6 && $buildVersion == 6) {
		print "$repolistEntry match\n";
	} elsif ($systemVersion == 7 && $buildVersion == 7) {
		print "$repolistEntry match\n";
	} else {
		next;
	}

	my ($buildDistro, $buildArch) = evalPackage($repolistEntry);

	# Fix the baseurl in repo file
	fixRepoDistro($repolistEntry);

	# Make release file
	my $file = "$name";
	open (OUTPUT, "> $file") or die;
	print OUTPUT ("${file} ${version}-${releaseNo}\n");
	close OUTPUT;

	editMakefile($buildDistro,$buildArch,$repolistEntry,$distroRepoList,$buildVersion);
	editSpecFile($buildDistro,$buildArch,$repolistEntry,$distroRepoList,$buildVersion);
	system("make rpmbuild");
}

# PGP sign the rpms
print "Sign RPM packages\n";
system("rpm --addsign $ENV{HOME}/rpmbuild/RPMS/noarch/zdiv-release*.rpm");
