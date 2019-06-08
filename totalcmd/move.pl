# Move files to subdir of current working dir based on properties.
# Usage: move.pl [list file] [format]
# file properties: dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks
# time detail properties: sec min hour mday mon year wday yday isdst
# format example: "{mtime.year}{mtime.mon}{mtime.mday}"
# default format: "{mtime.year}"

use strict;
use warnings;

use File::Copy qw(move);
use File::stat;
use Time::localtime;

my ($filelist, $dirFormat) = @ARGV;
defined $filelist or die "No filelist";
-T $filelist or die "Not a text file: $filelist";

my %opts = ( quiet => 0 );

my $prop = "atime";
$dirFormat //= "{mtime.year}";
#~ my $dirFormat //= "{mtime.year}{mtime.mon}{mtime.mday}";

open my $fh, '<', $filelist or die "$!: $filelist";
while (<$fh>) {
    chomp;
    next if !-f;
    my $st = stat $_ or die "$!: $_";

    my $dirName = $dirFormat;
    $dirName =~ s/\{(\w+)\.?(\w+)?\}/
        my $statField = $1;
        my $dateField = $2;
        if ($dateField) {
            my $t = localtime $st->$statField;
            my $v = $t->$dateField;
            $v += 1900 if $dateField eq 'year';
            $v = sprintf("%2.2u", $v+1) if $dateField eq 'mon';
            $v = sprintf("%2.2u", $v) if $dateField eq 'mday';
            $v;
        } else {
            $st->$statField;
        }
    /ge; #/

    print "$_\n" unless $opts{quiet};
    mkdir $dirName;
    move $_, $dirName or die "$!: $_";
}
