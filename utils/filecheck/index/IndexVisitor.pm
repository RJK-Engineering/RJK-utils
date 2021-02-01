package IndexVisitor;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

use FileVisitResult;
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
    return FileVisitResult::SKIP_SUBTREE if $self->ignore($dir, $stat);
    $self->{dir} = new RJK::Filecheck::Dir($dir);
}

sub postVisitFiles {
    my ($self, $dir, $stat) = @_;
    $self->{dir}->saveProperties;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    return if $self->ignore($file, $stat);
    print "$file->{path}\n";

    my $fileTypes = $conf->getFileTypes($file, $stat);
    return if !@$fileTypes;
    print "File type: @$fileTypes\n";
    $file->{type} = $fileTypes;

    $self->visit($fileTypes, $file, $stat);
}

sub visit {
    my ($self, $fileTypes, $file, $stat) = @_;
    my @v = $conf->getVisitors(["general"]);
    push @v, $conf->getVisitors($fileTypes);

    my $props = $self->{dir}->getFileProperties($file->name) // {};
    foreach my $visitor (@v) {
        $visitor->visitFile($file, $stat, $props);
    }
    $self->{dir}->setFileProperties($file->name, $props);
}

sub ignore {
    my ($self, $file, $stat) = @_;
    local $_ = $file->{name};
    /^[.~]/ || /~$/;
}

1;
