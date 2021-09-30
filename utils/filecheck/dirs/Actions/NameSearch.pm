package Actions::NameSearch;

use strict;
use warnings;

use RJK::Filecheck::DirLists;
use Utils;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;
    @{$opts->{args}} or throw Exception("No search arguments");

    my @terms = getTerms();
    my @result;

    RJK::Filecheck::DirLists->traverse($opts->{list}, sub {
        my $vpath = shift;
        my $names = Utils::getNames($vpath);
        my $match;
        NAME: foreach my $name (@$names) {
            foreach my $term (@terms) {
                next NAME if $name !~ /$term/i
            }
            $match = 1;
            last;
        }
        push @result, $vpath if $match;
        return 0;
    });

    return [sort @result];
}

sub getTerms {
    my @terms;
    foreach (@{$opts->{args}}) {
        s/\W/ /g;
        s/^\s+//;
        s/\s+$//;
        s/\s+/ /g;
        push @terms, $_;
    }
    return @terms;
}

1;
