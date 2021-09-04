package Utils;

use strict;
use warnings;

sub getNames {
    my ($path) = @_;
    my $name = $path->name;
    while ($name =~ s/\s*\(.*\)\s*//g) {};
    while ($name =~ s/\s*\[.*\]\s*//g) {};
    while ($name =~ s/\s*\{.*\}\s*//g) {};
    return [ split /\s*\W+\s+/, $name ];
}

1;
