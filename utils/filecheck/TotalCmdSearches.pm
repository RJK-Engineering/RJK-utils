package TotalCmdSearches;

use strict;
use warnings;

use RJK::TotalCmd::Settings::Ini;

sub listSearches {
    my ($class, $opts) = @_;
    my $ini = getTotalCmdIni($opts->{tcmdini});
    my $searches = $ini->getSearches(sub {shift->{name} =~ /^\./});
    foreach (sort keys %$searches) {
        print "$searches->{$_}{name}\t$searches->{$_}{SearchFor}\n";
    }
}

sub getSearch {
    my ($class, $opts) = @_;
    my $search;
    my $ini = getTotalCmdIni($opts->{tcmdini});

    if ($opts->{storedSearchName}) {
        $search = $ini->getSearch($opts->{storedSearchName})
            or die "Search not found: $opts->{storedSearchName}";
    } else {
        $search = $ini->getSearch;
    }

    $search->{SearchIn} = $opts->{searchIn};
    $search->{SearchText} = $opts->{searchText};

    addNameRules($search, $opts);
    addPerlRules($search, $opts);
    return $search;
}

sub addNameRules {
    my ($search, $opts) = @_;

    my $op;
    if ($opts->{exact}) {
        $op = $opts->{ignoreCase} ? '=' : '=(case)';
    } elsif ($opts->{regex}) {
        $op = $opts->{ignoreCase} ? 'regex' : 're.(case)';
    } else {
        $op = $opts->{ignoreCase} ? 'contains' : 'cont.(case)';
    }

    my $prop = $opts->{pathMatch} ? 'path' : $opts->{extMatch} ? 'name' : 'fullname';

    foreach (@ARGV) {
        s/\W//g if $opts->{clean};
        $search->addRule('tc', $prop, $op, $_);
    }

    if ($opts->{parent}) {
        $search->addRule('perl', 'parent', $op, $opts->{parent});
    }
}

sub addPerlRules {
    my ($search, $opts) = @_;

    if ($opts->{binaryTest}) {
        $search->addRule(qw(perl binary = 1));
    } elsif ($opts->{searchText} || $opts->{textTest}) {
        $search->addRule(qw(perl text = 1));
    }
}

sub getTotalCmdIni {
    my $tcmdini = shift;
    my $path = -e $tcmdini ? $tcmdini : undef; # path is taken from env var if it's undef
    return new RJK::TotalCmd::Settings::Ini($path)->read;
}

1;
