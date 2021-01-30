package FileSearch;

use strict;
use warnings;

use Module::Load;

my $fileSearch;
my $fileSearchModule = "DdfSearch";

sub execute {
    my ($class, $view, $tcSearch, $partitions, $opts) = @_;
    if (! $fileSearch) {
        load $fileSearchModule;
        $fileSearch = $fileSearchModule;
    }
    $fileSearch->execute($view, $tcSearch, $partitions, $opts);
}

1;
