use strict;
use warnings;

use RJK::Media::EMule::CancelledMet;

=pod

USAGE

tcmd.pl [cancelled.met file] [action] [options]

ACTIONS

list
add [hash]
merge [cancelled.met file] -save [cancelled.met file]

EXAMPLE

tcmd.pl cancelled1.met merge cancelled2.met -save cancelled3.met

=cut

my $cancelledMet = shift;
my $action = shift // '';
my $merge = shift if $action eq 'merge';
my $hash = shift if $action eq 'add';
my %opts = @ARGV;

my $met = new RJK::Media::EMule::CancelledMet($cancelledMet, 1);

if ($action eq 'list') {
    foreach (sort @{$met->hashList}) {
        print "$_\n";
    }
} elsif ($action eq 'add') {
    $hash =~ /^[\da-f]{32}$/i or die "invalid hash: $hash";
    if ($met->addHash($hash)) {
        printf "added hash: %s\n", $hash;
    } else {
        printf "skipped existing hash: %s\n", $hash;
    }
} elsif ($action eq 'merge') {
    my $met2 = new RJK::Media::EMule::CancelledMet($merge, 1);
    printf "%u + %u files\n", $met->count, $met2->count;
    my ($added, $dupes) = $met->merge($met2);
    printf "%u added, %u duplicates\n", $added, $dupes;
    printf "%u files total\n", $met->count;
} else {
    printf "seed: %x\n", $met->seed;
    printf "%u files\n", $met->count;
}

if (defined $opts{-save}) {
    $met->save($opts{-save});
}
