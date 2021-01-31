package Visitors::VideoInfo;
use parent 'FileTypeVisitor';

use strict;
use warnings;

sub visitFile {
    my ($self, $file, $stat, $props) = @_;
    foreach (keys %$props) {
        print "$_=$props->{$_}\n";
    }
}

1;
