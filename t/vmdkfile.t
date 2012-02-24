#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 39;
use Fcntl qw(O_CREAT O_TRUNC O_RDWR SEEK_SET);
use File::Copy;
use File::Path qw(mkpath rmtree);

use constant PROG => 'vmdktool';

my $dir = $ENV{EXES} ? "./$ENV{EXES}" : ".";
my $cmd = "$dir/" . PROG;

my $d = "t/data";
rmtree $d;
mkpath $d;
my $rawfn = "$d/file.raw";
my $vmdkfn = "$d/file.vmdk";
my $sfn = "$d/file.raw-s";
my $rfn = "$d/file.raw-r";

read_non_disk_image: {
    chomp(my $out = `$cmd -dv $vmdkfn $cmd 2>&1`);
    is($?, 0, "Creation of a vmdk from a non-disk image is ok");
    is($out, "Warning: $cmd: Not a bootable filesystem",
	"vmdktool warns that the image isn't recognised");
}

create_raw_file: {
    my $block0 = "block zero! " x 42 . "magic " . chr(0x55) . chr(0xaa);
    my $block127 = "block 12seven!! " x 32;
    sysopen my $fd, $rawfn, O_CREAT | O_TRUNC | O_RDWR or die "$rawfn: $!";
    syswrite $fd, $block0;
    seek $fd, 127 * 512, SEEK_SET;
    syswrite $fd, $block127;
    ok(close $fd, "Wrote a raw disk file");
}

create_vmdk_file: {
    system "$cmd -v $vmdkfn $rawfn";
    is($?, 0, "Created $vmdkfn from $rawfn");
}

check_ddb_info: {
    chomp(my @ddb = `$cmd -i $vmdkfn`);
    is($?, 0, "Got info from $vmdkfn");

    ok(grep(/RDONLY 128 SPARSE/, @ddb), "Created ddb info with 128 blocks");
    ok(grep(/geometry.cylinders = "4"/, @ddb),
	"Created ddb with correct disk geometry");
}

recreate_and_verify_raw_file: {
    system "$cmd -r $rfn $vmdkfn";
    is($?, 0, "Created $rfn from $vmdkfn");

    system "$cmd -s $sfn $vmdkfn";
    is($?, 0, "Created $sfn from $vmdkfn");

    print "# Comparing $rawfn and $rfn\n";
    system "cmp -l $rawfn $rfn";
    is($?, 0, "$rawfn and $rfn are the same");

    print "# Comparing $rawfn and $sfn\n";
    system "cmp -l $rawfn $sfn";
    is($?, 0, "$rawfn and $sfn are the same");
}

increased_capacity: {
    my %size = (
	'128K' => 128 * 1024,
	'524288' => 512 * 1024,
	'3M' => 3 * 1024 * 1024,
	'100M' => 100 * 1024 * 1024,
    );

    while (my ($capacity, $actual) = each %size) {
	my $extrawfn = "$d/$capacity-file.raw";
	my $extvmdkfn = "$d/$capacity-file.vmdk";
	my $extsfn = "$d/$capacity-file.raw-s";
	my $extrfn = "$d/$capacity-file.raw-r";

	system "$cmd -c$capacity -v $extvmdkfn $rawfn";
	is($?, 0, "Created $extvmdkfn from $rawfn");

	system "$cmd -r $extrfn $extvmdkfn";
	is($?, 0, "Created $extrfn from $extvmdkfn");
	is(-s $extrfn, $actual, "The $extrfn file is actually $actual bytes");

	system "$cmd -s $extsfn $extvmdkfn";
	is($?, 0, "Created $extsfn from $extvmdkfn");
	is(-s $extsfn, $actual, "The $extsfn file is actually $actual bytes");

	copy $rawfn, $extrawfn;
	truncate $extrawfn, $actual;

	print "# Comparing $extrawfn and $extrfn\n";
	system "cmp -l $extrawfn $extrfn";
	is($?, 0, "$extrawfn and $extrfn are the same");

	print "# Comparing $extrawfn and $extsfn\n";
	system "cmp -l $extrawfn $extsfn";
	is($?, 0, "$extrawfn and $extsfn are the same");
    }
}
