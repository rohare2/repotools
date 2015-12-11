#!/usr/bin/perl -w
# $Id: repocreate.pl 222 2014-10-24 18:18:28Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/repotools/repocreate.pl $
#
# Create repos selected from sw_src.xml

use strict;
use File::Path;
use XML::Simple;
use Errno qw(EAGAIN);
use POSIX "sys_wait_h";

$ENV{PATH} = "/bin:/usr/bin";    # Ensure a secure PATH
$| = 1;

if ($< != 0) {
	print "This script must be run as root\n";
	exit (0);
}

# Configureable options
my $Width = 12;  # Maximum number of forkes
my $LockFile = "/tmp/lockfile";
my $ForkCount = 0;
my $args = '';
my $lastUrl = '';
my $lastDistro = '';

# determine domain name
my $hostname = `uname -n`;
chomp $hostname;
my $domainname = `host $hostname | cut -d " " -f1`;
chomp $domainname;

my $DEST_URL;
if ($domainname =~ /llnl.gov/) {
	$DEST_URL = "https://corbin.llnl.gov/software";
} else {
	die "Unknown domainname\n";
}

my $BASE_DIR = "/var/www/html/software";
my $xmlFile = "/usr/local/etc/sw_src.xml";
my ($list,$distroChoice,$srcChoice);
my $repoChoice = '';

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

if (! $list) {
	# Create lock file
	open (LOCK, "> $LockFile") or
		die "Error: Can not write lock file: $!";
}

sub setArgs {
	my $source = shift @_;
	my $distro = shift @_;

	if (defined $source->{'distro'}->{$distro}->{'args'}) {
		$args = $source->{'distro'}->{$distro}->{'args'};
	} else {
		$args = '';
	}
}

foreach my $source (@{$sources->{'source'}}) {
	if (defined $srcChoice && $srcChoice eq $source->{'url'} && $source->{'hosts'} =~ /\Q$domainname\E/ ) {
		foreach my $distro (sort keys %{$source->{'distro'}}) {
			if (defined $distroChoice && $distroChoice eq $distro) {
				if ( $source->{'distro'}->{$distro}->{'createRepo'} eq '1' ) {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						if ( $source->{'distro'}->{$distro}->{'createRepo'} eq '1' ) {
							&setArgs($source,$distro);
							&processRepo($repo,$args,$source->{'url'},$distro);
						}
					}
				} else {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						if ( $source->{'distro'}->{$distro}->{'createRepo'} eq '1' ) {
							setArgs($source,$distro);
							&processRepo($repo,$args,$source->{'url'},$distro);
						}
					}
				}
			} elsif (! defined $distroChoice) {
				if ( $source->{'distro'}->{$distro}->{'createRepo'} eq '1' ) {
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						if ( $source->{'distro'}->{$distro}->{'createRepo'} eq '1' ) {
							setArgs($source,$distro);
							&processRepo($repo,$args,$source->{'url'},$distro);
						}
					}
				}
			}
		}
	} elsif (! defined $srcChoice && $source->{'hosts'} =~ /\Q$domainname\E/) {
		foreach my $distro (sort keys %{$source->{'distro'}}) {
			if (defined $distroChoice && $distroChoice eq $distro) {
				if ( $source->{'distro'}->{$distro}->{'createRepo'} eq '1' ) {
					setArgs($source,$distro);
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						&processRepo($repo,$args,$source->{'url'},$distro);
					}
				}
			} elsif (! defined $distroChoice) {
				if ( $source->{'distro'}->{$distro}->{'createRepo'} eq '1' ) {
					setArgs($source,$distro);
					foreach my $repo (@{$source->{'distro'}->{$distro}->{'repo'}}) {
						&processRepo($repo,$args,$source->{'url'},$distro);
					}
				}
			}
		}
	}
}

sub processRepo() {
	my $repo = shift @_;
	my $args = shift @_; 
	my $url  = shift @_;
	my $distro  = shift @_;

	if (! -d "${BASE_DIR}/${repo}") {
		warn "Sorry you need add ${BASE_DIR}/${repo} first\n";
		return 0;
	}

	if ($repoChoice eq $repo || $repoChoice eq '') {
		if ($lastUrl ne $url) {
			$list && print "$url\n";
			$lastUrl = $url;
		}
		if ($lastDistro ne $distro) {
			$list && print "\t$distro\n";
			$lastDistro = $distro;
		}
		$list && print "\t\t$repo\n";
		if (! $list) {
			if (my $pid = fork) {
				$ForkCount++;
				($ForkCount < $Width ) || wait;
			} elsif (defined $pid) {
				print "createrepo -q $args --update -c /var/www/cache ${BASE_DIR}/${repo}\n";
				`createrepo -q $args --update -c /var/www/cache ${BASE_DIR}/${repo}`;

				#print "repoview -qu ${DEST_URL}/${repo} ${BASE_DIR}/${repo}\n";
				#`repoview -qu ${DEST_URL}/${repo} ${BASE_DIR}/${repo}`;

				$ForkCount--;
				exit;
			} elsif ($! =~ /No more process/) {
				sleep 5;
				redo &finder;
			} else {
				# weird fork error
				die "Can't fork: $!\n";
			}
		}
	}
}
               

sub usage() {
    print( <<EOF
Usage: check.pl -h
       check.pl [-f <xmlFile>] [-s <Source> [-r <Repo> || -d <Distro>]
           -d      Process named distro
           -f      Name of XML file with repo definitions
           -h      Display this usage message
           -l      List all repo choices
           -r      Process named repo
           -s      Process named source

EOF
);
	exit 0;
}

close LOCK;
if ( -f $LockFile ){
	unlink $LockFile;
}
exit;
