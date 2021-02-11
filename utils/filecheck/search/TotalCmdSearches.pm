package TotalCmdSearches;

use strict;
use warnings;

use RJK::TotalCmd::Search;
use RJK::TotalCmd::Settings::Ini;

sub listSearches {
    my $ini = getTotalCmdIni();
    my $searches = $ini->getSearches(sub {shift->{name} =~ /^\./});
    foreach (sort keys %$searches) {
        print "$searches->{$_}{name}\t$searches->{$_}{SearchFor}\n";
    }
}

sub getSearch {
    my ($class, $opts) = @_;
    my $search;
    my $ini = getTotalCmdIni();

    if ($opts->{storedSearchName}) {
        $search = $ini->getSearch($opts->{storedSearchName})
            or die "Search not found: $opts->{storedSearchName}";
    } else {
        $search = new RJK::TotalCmd::Search();
    }

    $search->{SearchIn} = $opts->{searchIn};
    $search->{SearchText} = $opts->{searchText};

    my $flags = $search->{flags};
    my %flags = %{$opts->{flags}};
    foreach (keys %flags) {
        $flags->{$_} = $flags{$_} if defined $flags{$_};
    }
    $flags->{directory} = 1 if $opts->{searchDirs};
    $flags->{directory} = 0 if $opts->{searchFiles};

    addNameRules($search, $opts);
    addPerlRules($search, $opts);

    return $search;
}

sub addNameRules {
    my ($search, $opts) = @_;
    my $flags = $search->{flags};

    my $op;
    if ($opts->{exact}) {
        $op = $opts->{ignoreCase} ? '=' : '=(case)';
    } elsif ($flags->{regex}) {
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
    return new RJK::TotalCmd::Settings::Ini()->read;
}

1;
