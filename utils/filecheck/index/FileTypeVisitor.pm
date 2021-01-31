package FileTypeVisitor;

use strict;
use warnings;

sub new {
    my $self = bless {}, shift;
    $self->{conf} = shift;
    return $self;
}

sub conf {
    $_[0]{conf};
}

sub visitFile { ... }

1;
