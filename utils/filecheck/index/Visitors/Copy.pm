package Visitors::Copy;
use parent 'FileTypeVisitor';

use strict;
use warnings;

sub visitFile {
    my ($self, $file) = @_;
    print "copy $file $self->{conf}{toDir}\n";
}

1;
