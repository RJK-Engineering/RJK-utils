package Filecheck;

use strict;
use warnings;

use Module::Load;

my $store;
my $storeModule = "Store";

sub retrieveDriveList {
    getStore()->retrieveDriveList();
}

sub retrieveDirList {
    getStore()->retrieveDirList();
}

sub storeDirList {
    my ($class, $list) = @_;
    getStore()->storeDirList($list);
}

sub getStore {
    if (! $store) {
        load $storeModule;
        $store = $storeModule;
    }
    return $store;
}

1;
