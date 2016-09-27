#$Id: $
#$Date: $
# repodownload.pl
#
my $DEBUG = 1;
if ($DEBUG) {
	print "DEBUG MODE!\n";
}

my $mntPoint = "/mnt/mobile";
my $dest = "/var/www/html";

print "Transfer disk mount point [${mntPoint}]: ";
my $ans = <STDIN>;
chomp $ans;
if ($ans ne '') {
	$mntPoint = $ans;
}

if ($DEBUG) {
	print "Destination [${dest}]: ";
	my $ans = <STDIN>;
	chomp $ans;
	if ($ans ne '') {
		$dest = $ans;
	}
}

if ($DEBUG) {
	print "Mount: $mntPoint\n"; 
	print "destination: $dest\n";
}

# update software and references
foreach my $dir ('apps','reference','software') {
	if ($DEBUG) {
		print "rsync -av --delete --exclude .htaccess ${mntPoint}/var/www/html/${dir}/ ${dest}/${dir}/\n";
	} else {
		`rsync -av --delete --exclude .htaccess ${mntPoint}/var/www/html/${dir}/ ${dest}/${dir}/`;
	}
}

# update procedures
foreach my $dir ('procedure') {
	print "$dir\n";
	if ($DEBUG) {
		print "rsync -av --delete --exclude .htaccess ${mntPoint}/var/www/html/${dir}/ ${dest}/${dir}/OLN/\n";
	} else {
		`rsync -av --delete --exclude .htaccess ${mntPoint}/var/www/html/${dir}/ ${dest}/${dir}/OLN/`;

	}
}

# update transfer files
if ($DEBUG) {
	print "rsync -av --delete ${mntPoint}/transfer/ /transfer/\n";
} else {
	`rsync -av --delete ${mntPoint}/transfer/ /transfer/`;
};

