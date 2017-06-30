#!/usr/bin/perl -w
# $Id: reposyncWrapper.pl 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/reposyncWrapper.pl $
#
# reposyncWrapper
#
# Must be run from a Red Hat system, joined to a satalite server

use strict;

my $id = `lsb_release -si`;
chomp $id;
$id =~ /RedHat/ || die "Not a RedHat system";
$id =~ /RedHatEnterpriseClient/ && ($id = 'Client');
$id =~ /RedHatEnterpriseServer/ && ($id = 'Server');
$id =~ /RedHatEnterpriseWorkstation/ && ($id = 'Workstation');

my $release = `lsb_release -sr`;
chomp $release;
$release =~ s/\..*//;

my $releasever = $release . $id;

my $arch = `uname -i`;
chomp $arch;

my $message = <<END;
The /var/www/html/software directory does not exist.
This could mean you are on the wrong machine,
or it could mean you have not prepared this
system for repo syncronization.

Note, this script should be executed from a
system joined to a Red Hat Satalite and the
software directory should be NFS mounted 
from your YUM server, or the YUM server it self.
END

my $repoPath = "/var/www/html/software/redhat";
! -d "$repoPath" && die $message;

my $dest = "${repoPath}/${releasever}/${release}/${arch}";
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
	$repo =~ s/^!//;
	$repo =~ s/\/x86_64//;

	# do the repo sync
	print "Processing: ${repo}\n";
	system("/usr/bin/reposync -d -n -l --repoid=${repo} --download_path=${dest} > /dev/null");

}

