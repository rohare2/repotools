#!/usr/bin/perl -w
# $Id: reposyncWrapper.pl 169 2014-10-20 18:42:25Z rohare $
# $URL: file:///usr/local/svn/admin/repotools/reposyncWrapper.pl $
#
# reposyncWrapper
#
# Must be run from a Red Hat system, joined to a satalite server

use strict;

my $distro = `lsb_release -si`;
chomp $distro;
$distro =~ /RedHat/ && ($distro = 'redhat');

my $release = `lsb_release -sr`;
chomp $release;
$release =~ s/\..*//;
my $arch = `uname -i`;
chomp $arch;

my $message = <<END;
The /software directory does not exist.
This could mean you are on the wrong machine,
or it could mean you have not prepared this
system for repo syncronization.

Note, this script should be executed from a
system joined to a Red Hat Satalite and the
/software directory should be NFS mounted 
from your YUM server, or the YUM server it self.
END

my $repoPath = "/var/www/html/software";
! -d "$repoPath" && die $message;

my $dest = "${repoPath}/${distro}/${release}/${arch}";
print "Destination: $dest\n";

if ( ! -d "$dest") {
	system("mkdir -p -m 2750 $dest");
}

# Process repos
my $ret = `yum repolist enabled`;
my @list = split('\n', $ret);
foreach my $line (@list) {
	$line =~ '^Load' && next;
	$line =~ '^[ \t]*:' && next;
	$line =~ '^0' && next;
	$line =~ '^This system' && next;
	$line =~ '^Reading' && next;
	$line =~ '^repo id' && next;
	$line =~ '^repolist' && next;
	my ($repo, $desc) = split(' ', $line);

	# do the repo sync
	if ($repo =~ '^gs' || $repo =~ 'LSI-' || $repo =~ 'splunk') { 
		# Make a link for this releasever
		&mklink;
	} else {
		print "Processing: ${repo}\n";
		system("/usr/bin/reposync -d -n -l --repoid=${repo} --download_path=${dest} > /dev/null");
		# Make a link for this releasever
		&mklink;
	}

}

sub mklink() {
	my $releasever = `rpm -q --qf "%{version}" -f /etc/redhat-release`;
	if ( ! -l "${repoPath}/${distro}/${releasever}") {
		chdir "${repoPath}/${distro}";
		system("ln -s $release $releasever");
		chdir;
	}
}