use strict;
use warnings;

my $file = shift // "lines.txt";
my %lines;
my %dupes;

open my $fh, '<', $file or die "$!: $file";
while (<$fh>) {
    next if /^$/;
    if ($dupes{$_}) {
        next;
    } elsif ($lines{$_}) {
        print;
        $dupes{$_}++;
    } else {
        $lines{$_}++;
    }
}
close $fh;
