package Actions::MultipleNames;

use strict;
use warnings;

use Data::Dump;
use RJK::Filecheck::DirLists;
use Utils;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;
    my @dirs;
    my $results;

    RJK::Filecheck::DirLists->traverse($opts->{list}, sub {
        my $vpath = shift;
        my $names = Utils::getNames($vpath);
        if (@$names > 1) {
            dd \@$names;
            $results++;
        }
        return 0;
    });
    return $results;
}

1;
