#! /usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;
use Fcntl qw(O_CREAT O_TRUNC O_RDWR SEEK_SET);
use File::Copy;
use File::Path qw(mkpath rmtree);

use constant PROG => 'vmdktool';

my $dir = $ENV{EXES} ? "./$ENV{EXES}" : ".";
my $cmd = "$dir/" . PROG;

my $d = "t/data";
rmtree $d;
mkpath $d;
my $rawfn = "$d/uneven.raw";
my $vmdkfn = "$d/uneven.vmdk";
my $sfn = "$d/uneven.raw-s";
my $rfn = "$d/uneven.raw-r";

read_non_disk_image: {
    chomp(my $out = `$cmd -dv $vmdkfn $cmd 2>&1`);
    is($?, 0, "Creation of a vmdk from a non-disk image is ok");
    is($out, "Warning: $cmd: Not a bootable filesystem",
	"vmdktool warns that the image isn't recognised");
}

create_raw_file: {
    my $block0 = "block zero! " x 42 . "magic " . chr(0x55) . chr(0xaa);
    my $block191 = "block 12seven!! " x 32;
    sysopen my $fd, $rawfn, O_CREAT | O_TRUNC | O_RDWR or die "$rawfn: $!";
    syswrite $fd, $block0;
    seek $fd, 191 * 512, SEEK_SET;
    syswrite $fd, $block191;
    ok(close $fd, "Wrote a raw disk file");
}

create_vmdk_file: {
    system "$cmd -v $vmdkfn $rawfn";
    is($?, 0, "Created $vmdkfn from $rawfn");
}

check_ddb_info: {
    chomp(my @ddb = `$cmd -i $vmdkfn`);
    is($?, 0, "Got info from $vmdkfn");

    ok(grep(/RDONLY 192 SPARSE/, @ddb), "Created ddb info with 192 blocks");
    ok(grep(/geometry.cylinders = "6"/, @ddb),
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
