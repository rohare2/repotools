my $release = `lsb_release -sr`;
chomp $release;
$release =~ s/\..*//;

if ($release == '5') {
	`rpm --addsign /var/www/html/software/{gs,jwics,hal}/{centos,redhat}/5/{i386,x86_64}/*.rpm`;
} else {
	`rpm --addsign /var/www/html/software/{gs,jwics,hal}/{centos,redhat}/{6,7}/x86_64/*.rpm`;
}
