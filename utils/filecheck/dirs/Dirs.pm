package Dirs;

use strict;
use warnings;

use Actions;

sub execute {
    my ($self, $opts) = @_;

    if ($opts->{getDirs}) {
        Actions::exec('GetDirs', $opts);
    } elsif ($opts->{listMultipleNames}) {
        Actions::exec('ListMultipleNames', $opts);
    } elsif ($opts->{listDupes}) {
        Actions::exec('FindDupes', $opts);
    } elsif ($opts->{filenameSearch}) {
        Actions::exec('FilenameSearch', $opts);
    } else {
        Actions::exec('NameSearch', $opts);
    }
}

1;
