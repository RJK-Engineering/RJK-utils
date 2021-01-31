package Index;

use strict;
use warnings;

use Conf;
use IndexVisitor;
use RJK::Files;
use RJK::Options::Util;

sub execute {
    my $self = shift;
    my $conf = new Conf(shift);

    my $stats = RJK::Files->createStats();
    my $visitor = new IndexVisitor($conf, $stats);
    RJK::Options::Util->traverseFiles($conf, $visitor, $stats);
}

1;
