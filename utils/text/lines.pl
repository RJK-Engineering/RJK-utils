use strict;
use warnings;

my %opts;
if (defined $ARGV[1]) {
    $opts{matchNot} = shift || 1;
}
$opts{file} = shift || "lines.txt";

my @filter;
my @lines;
my $readLines;

open my $fh, '<', $opts{file} or die "$!: $opts{file}";
while (<$fh>) {
    if (/^$/) {
        $readLines = 1;
    } elsif ($readLines) {
        push @lines, $_;
    } else {
        chomp;
        push @filter, $_;
    }
}
close $fh;

foreach my $line (@lines) {
    my $match;
    foreach (@filter) {
        next if $line !~ /$_/;
        $match = 1;
        last;
    }
    print $line if $opts{matchNot} xor $match;
}
