#!/usr/bin/perl -w
# $Id: repoupdate.pl 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/repoupdate.pl $
#
# repoupdate.pl
# Updates Z-Div Linux repos

use strict;
use Net::Ping;
use File::Path::Tiny;
use XML::Simple;

$ENV{PATH} = "/bin:/usr/bin";    # Ensure a secure PATH
$| = 1;

if ($< != 0) {
	print "This script must be run as root\n";
	exit (0);
}

# Configureable fork options
my $Width     = 8;                    # Maximum number of forkes
my $ForkCount = 0;

my $BASE_DIR = "/var/www/html/software";
my $xmlFile = "/usr/local/etc/sw_src.xml";
my ($list,$distroChoice,$srcChoice);
my $repoChoice = '';
my $LockFile  = "/tmp/repoupdate";
my $lastUrl = '';
my $lastDistro = '';

# determine domain name
my $hostname = `uname -n`;
chomp $hostname;
my $domainname = `host $hostname | cut -d " " -f1`;
chomp $domainname;

# Process user options
my $cnt = 0;
my $argCnt = @ARGV;
$argCnt--;
while ($cnt <= $argCnt) {
	if ($ARGV[$cnt] =~ '-h') {
		&usage;
	} elsif ($ARGV[$cnt] =~ '-l') {
		$list = 1;
	} elsif ($ARGV[$cnt] =~ '-f') {
		$cnt++;
		$xmlFile = $ARGV[$cnt];
		$cnt++;
		next;
	} elsif ($ARGV[$cnt] =~ '-d') {
		$cnt++;
		$distroChoice = $ARGV[$cnt];
		$cnt++;
		next;
	} elsif ($ARGV[$cnt] =~ '-r') {
		$cnt++;
		$repoChoice = $ARGV[$cnt];
		$cnt++;
		next;
	} elsif ($ARGV[$cnt] =~ '-s') {
		$cnt++;
		$srcChoice = $ARGV[$cnt];
		$cnt++;
		next;
	}
	$cnt++;
}
my $sources = XMLin("$xmlFile", ForceArray => 1); 

# Make sure we have internet access. Use EOR if needed.
if (! $list ) {
	&eorTest("mirrors.kernel.org");

	# Gaurd against multiple processes.
	open (LOCK, "> $LockFile") or
		die "Error: Can not write lock file: $!";
}

foreach my $source (@{$sources->{'source'}}) {
	if (defined $srcChoice && $srcChoice eq $source->{'url'} && $source->{'hosts'} =~ /\Q$domainname\E/) {
		foreach my $distro (sort keys %{$source->{'distro'}}) {
			if (defined $distroChoice && $distroChoice eq $distro) {
				if ( $source->{'distro'}->{$distro}->{'updateRepo'} eq '1' ) {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						if ( $source->{'distro'}->{$distro}->{'updateRepo'} eq '1' ) {
							&processRepo($source->{'url'},$repo,$distro);
						}
					}
				} else {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						if ( $source->{'distro'}->{$distro}->{'updateRepo'} eq '1' ) {
							&processRepo($source->{'url'},$repo,$distro);
						}
					}
				}
			} elsif (! defined $distroChoice) {
				if ( $source->{'distro'}->{$distro}->{'updateRepo'} eq '1' ) {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						if ( $source->{'distro'}->{$distro}->{'updateRepo'} eq '1' ) {
							&processRepo($source->{'url'},$repo,$distro);
						}
					}
				}
			}
		}
	} elsif (! defined $srcChoice && $source->{'hosts'} =~ /\Q$domainname\E/) {
		foreach my $distro (sort keys %{$source->{'distro'}}) {
			if (defined $distroChoice && $distroChoice eq $distro) {
				if ( $source->{'distro'}->{$distro}->{'updateRepo'} eq '1' ) {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						&processRepo($source->{'url'},$repo,$distro);
					}
				}
			} elsif (! defined $distroChoice) {
				if ( $source->{'distro'}->{$distro}->{'updateRepo'} eq '1' ) {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						&processRepo($source->{'url'},$repo,$distro);
					}
				}
			}
		}
	}
}

sub processRepo() {
	my $url = shift @_;
	my $repo = shift @_;
	my $distro = shift @_;
	my $dir = "${BASE_DIR}/$repo";
	my $options = "-avrt --stats --no-owner --no-group --delete";
	my $gid = getgrnam('apache');

	if ($repoChoice eq $repo || $repoChoice eq '') {
		if ($list) {
			if ($lastUrl ne $url) {
				print "\t$url\n";
				$lastUrl = $url;
			}
			if ($lastDistro ne $distro) {
				print "\t$distro\n";
				$lastDistro = $distro;
			}
			print "\t\t$repo\n";
		} else {
				if(!File::Path::Tiny::mk("$dir")) {
					&unlock;
					die "Could not make path '$dir': $!";
				}
				chmod 0755, "$dir";
				chown -1, $gid, "$dir";

			my $command = "rsync $options rsync://${url}/${repo}/ $dir";

			print "$command\n";
			open (INPUT, "$command |");
			my @input_array=<INPUT>;
			close(INPUT);
			`chgrp -R apache $dir`;
		}
	}
}
               
sub eorTest() {
	my $src_url = shift @_;
	my $p = Net::Ping->new("tcp", 2);
	$p->port_number('873');
	$p->ping($src_url) || &unlock && die "Use EOR to get internet access first\n";
}

sub usage() {
    print( <<EOF
Usage: repoupdate.pl -h
       repoupdate.pl [-f <xmlFile>] [-s <Source>] [-r <Repo>] [-d <Distro>]
           -d      Process named distro
           -f      Name of XML file with repo definitions
           -h      Display this usage message
           -l      List all repo choices
           -r      Process named repo
           -s      Process named source

EOF
);
	&unlock;
	exit 0;
}

sub unlock() {
	close LOCK;
	if (-f $LockFile) {
		unlink $LockFile;
	}
}

&unlock;
exit;
