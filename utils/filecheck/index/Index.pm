package Index;

use strict;
use warnings;

use Conf;
use IndexVisitor;
use DBD::mysql;
use RJK::DbTable;
use RJK::Filecheck::Config;
use RJK::Files;
use RJK::Options::Util;

sub execute {
    my $self = shift;
    my $conf = new Conf(shift);
    $conf->{chdir} = 1;

    my $stats = RJK::Files->createStats();
    my $visitor = new IndexVisitor($conf, $stats);
    dbConnect();

    RJK::Options::Util->traverseFiles($conf, $visitor, $stats);
    RJK::DbTable->commit() unless $conf->{noCommit};
}

sub dbConnect {
    RJK::DbTable->connect(
        host => RJK::Filecheck::Config->get('db.host.name'),
        db   => RJK::Filecheck::Config->get('db.database.name'),
        user => RJK::Filecheck::Config->get('db.user.name'),
        pass => RJK::Filecheck::Config->get('db.password'),
        port => RJK::Filecheck::Config->get('db.port', 3306),
    );
}

1;
