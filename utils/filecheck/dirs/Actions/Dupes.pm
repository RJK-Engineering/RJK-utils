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
    my @result;
    my $dupes;

    RJK::Filecheck::DirLists->traverse($opts->{list}, sub {
        my $vpath = shift;
        my $names = Utils::getNames($vpath);

        foreach my $name (@$names) {
            $dupes->{$name}{$vpath} = 1;
        }
    });

    filter($dupes);

    foreach my $paths (sort {(sort keys %$a)[0] cmp (sort keys %$b)[0]} values %$dupes) {
        push @result, "--";
        push @result, $_ for sort keys %$paths;
    }

    return \@result;
}

sub filter {
    my ($dupes) = @_;
    foreach my $name (keys %$dupes) {
        my @paths = keys %{$dupes->{$name}};
        delete $dupes->{$name}
            if @paths == 1
            or not $opts->{volume}
            or not grep { $_ =~ /^$opts->{volume}/i } @paths;
    }
    removeSubsets($dupes);
}

sub removeSubsets {
    my ($dupes) = @_;
    foreach my $a (keys %$dupes) {
        foreach my $b (keys %$dupes) {
            delete $dupes->{$a}
                if $a ne $b
                and isSubsetOf($dupes->{$a}, $dupes->{$b});
        }
    }
}

sub isSubsetOf {
    foreach (keys %{$_[0]}) {
        return if not exists $_[1]{$_};
    }
    return 1;
}

1;
