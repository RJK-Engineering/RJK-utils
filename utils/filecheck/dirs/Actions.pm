package Actions;

use strict;
use warnings;

sub exec {
    my ($action, $opts) = @_;
    my $class = "Actions::$action";
    eval "require $class" or die "$@";
    $class->execute($opts);
}

1;
