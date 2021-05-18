package Actions::FindDupes;

use strict;
use warnings;

use RJK::Filecheck::DirLists;
use Utils;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;
    my %dirs;

    RJK::Filecheck::DirLists->traverse($opts->{list}, sub {
        my $vpath = shift;
        my $names = Utils::getNames($vpath);

        foreach my $name (@$names) {
            my $dir = $opts->{dupesSameVolume} ? $dirs{$vpath->volume}{$name} //= [] : $dirs{$name} //= [];
            if (@$dir) {
                print "--\n$dir->[0]\n" if @$dir == 1;
                print "$vpath\n";
            }
            push @$dir, $vpath->{path};
        }
    });
}

1;
