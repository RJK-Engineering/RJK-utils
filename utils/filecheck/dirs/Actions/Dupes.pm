package Actions::Dupes;

use strict;
use warnings;

use RJK::Filecheck::DirLists;
use Utils;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;
    my %dirs;
    my $result = 1;
    my $dupes;

    RJK::Filecheck::DirLists->traverse($opts->{list}, sub {
        my $vpath = shift;
        my $names = Utils::getNames($vpath);

        foreach my $name (@$names) {
            push @{$dupes->{$name}}, $vpath;
        }
    });

    foreach my $dirs (sort {$a->[0] cmp $b->[0]} values %$dupes) {
        next if @$dirs == 1;
        next if $opts->{volume} && ! grep { $_ =~ /^$opts->{volume}/i } @$dirs;
        print "--\n";
        foreach (@$dirs) {
            print "$_\n";
        }
    }

    return $result;
}

1;
