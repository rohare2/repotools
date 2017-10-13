#!/usr/bin/perl -w
# $Id: $
# $Date: $
use strict;
use File::Copy;
use Cwd;
use XML::Simple;
require "repotools.conf";

our ($org,$baseurl,$version,$releaseNo,%vendor,%packager,%RepoList,$repoText);

# repo software location
my $BASE_DIR = "/var/www/html/software";
my $xmlFile = "/usr/local/etc/sw_src.xml";

# determine hostname 
my $hostname = `uname -n`;
chomp $hostname;

# determine local host distro
my $systemVersion = `lsb_release -sr`;
chomp $systemVersion;
$systemVersion =~ s/\..*//;

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
	my $buildVersion = shift;
	my $package = "${org}-release-${version}-${releaseNo}.${buildDistro}.${buildArch}";
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
		foreach my $entry (@{$RepoList{$repolistEntry}}) {
			$list = $list . " " . $entry;
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
	my $buildVersion = shift;
	my $release = "${releaseNo}.${buildDistro}.${buildArch}";
	my $vendor = 'Lawrence Livermore National Laboratory';
	my $packager = 'Rich O\'Hare <ohare2@llnl.gov';

	my $file = 'spec';
	copy("${file}.template","$file") or die "Copy failed: $!";
	open (INPUT,"<$file") or die;
	my @input_array=<INPUT>;
	close(INPUT);
	my $input_scalar=join("",@input_array);

	$input_scalar =~ /^%define Version/m && ($input_scalar =~ s/^%define Version.*$/%define Version ${version}/m);
	$input_scalar =~ /^%define Release/m && ($input_scalar =~ s/^%define Release.*$/%define Release ${release}/m);
	$input_scalar =~ /^BuildArch/m && ($input_scalar =~ s/^BuildArch.*$/BuildArch: noarch/m);
	$input_scalar =~ /^Distribution:/m && ($input_scalar =~ s/^Distribution.*$/Distribution: ${buildDistro}/m);
	$input_scalar =~ /^URL:/m && ($input_scalar =~ s/^URL.*$/URL: https:\/\/$baseurl/gm);
	$input_scalar =~ /^Vendor:/m && ($input_scalar =~ s/^Vendor:.*$/Vendor: ${vendor}/gm);
	$input_scalar =~ /^Packager:/m && ($input_scalar =~ s/^Packager:.*$/Packager: ${packager}/gm);

	open (OUTPUT, "> $file") or die;
	print OUTPUT "$input_scalar";
	close OUTPUT;

	open (OUTPUT, ">> $file") or die;
	foreach my $distroArray ($RepoList{$repolistEntry}) {
		foreach my $repo (@{$distroArray}) {
			print OUTPUT ("/etc/yum.repos.d/${repo}\n");
		}
	}
	if ($repolistEntry =~ /centos/) {
		print OUTPUT ("\n");
		print OUTPUT ("%posttrans\n");
		print OUTPUT ("/usr/bin/yum-config-manager --disable base\n");
		print OUTPUT ("/usr/bin/yum-config-manager --disable updates\n");
		print OUTPUT ("/usr/bin/yum-config-manager --disable extras\n");
		print OUTPUT ("/usr/bin/yum-config-manager --disable centosplus\n");
	}
	close OUTPUT;
}

sub createRepoFile {
	my $file = "${org}.repo";
	open(OUTPUT, "> $file") or die "Can not open $file: $!";
	print OUTPUT "$repoText";
	close OUTPUT;
}

sub fixRepoBaseurl {
	opendir (DIR, ".") or die $!;
	while (my $file = readdir(DIR)) {
		if ($file =~ /.*\.repo/) {
			open (INPUT, "$file") or die;
			my @input_array=<INPUT>;
			my $input_scalar=join("",@input_array);
			close(INPUT);

			$input_scalar =~ s/^# Repo:.*/# Repo: ${org}-release ${version}-${releaseNo}/gm;
			$input_scalar =~ s/^\[local\]/[$org]/m;
			$input_scalar =~ s/^\[local-noarch\]/[$org-noarch]/m;
			$input_scalar =~ s/^baseurl=https?:.*\/software/baseurl=https:\/\/${baseurl}\/software/gm;

			open (OUTPUT, "> $file") or die;
			print OUTPUT "$input_scalar";
			close OUTPUT;
		}
	}
}

sub fixRepoDistro {
	my $distro = shift;
	my $file = "${org}.repo";
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

createRepoFile();
fixRepoBaseurl();

no strict "refs";
foreach my $repolistEntry (sort keys %{RepoList}) {
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

	# Fix the org in repo file
	fixRepoDistro($repolistEntry);

	# Make release file
	my $file = $org ."-release";
	open (OUTPUT, "> $file") or die;
	print OUTPUT ("${org}-release ${version}-${releaseNo}\n");
	close OUTPUT;

	editMakefile($buildDistro,$buildArch,$repolistEntry,$buildVersion);
	editSpecFile($buildDistro,$buildArch,$repolistEntry,$buildVersion);
	system("make rpmbuild");
}

# PGP sign the rpms
print "Sign RPM packages\n";
system("rpm --addsign $ENV{HOME}/rpmbuild/RPMS/noarch/zdiv-release*.rpm");
