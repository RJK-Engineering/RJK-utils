package Actions::NameSearch;

use strict;
use warnings;

use RJK::Filecheck::DirLists;
use RJK::Paths;

use Utils;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;
    my @terms = getTerms();

    RJK::Filecheck::DirLists->traverse($opts->{list}, sub {
        my $path = RJK::Paths->get(shift);
        my $names = Utils::getNames($path);
        my $match;

        NAME: foreach my $name (@$names) {
            foreach my $term (@terms) {
                next NAME if $name !~ /$term/i
            }
            $match = 1;
            last;
        }
        print join(", ", @$names), "\n" if $match;
        return 0;
    });
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
