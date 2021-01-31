package IndexVisitor;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

use RJK::Filecheck::Dir;

my $conf;
my $stats;

sub new {
    my $self = bless {}, shift;
    $conf = shift;
    $stats = shift;
    return $self;
}

sub preVisitDir {
    my ($self, $dir, $stat) = @_;
    $self->{dir} = new RJK::Filecheck::Dir($dir);
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    print "$file->{path}\n";

    my $t = $conf->getFileTypes($file, $stat);
    return if !@$t;

    print "File type: @$t\n";
    my $v = $conf->getVisitors($t);

    my $props = $self->{dir}->getFileProperties($file->name) // {};

    foreach my $visitor (@$v) {
        $visitor->visitFile($file, $stat, $props);
    }
    $self->{dir}->setFileProperties($file->name, $props);
}

1;
