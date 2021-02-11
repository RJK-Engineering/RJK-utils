package Visitors::Store;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

use TBM::Dir;
use TBM::File;
use TBM::Factory::Dir;
use TBM::Factory::File;

sub preVisitDir {
    my ($self, $dir, $stat) = @_;
    $self->{dir} = TBM::Factory::Dir->fetch // TBM::Factory::Dir->create;
    $self->updateDir($dir, $stat);

    $self->{files} = $self->{dir}->getFiles;
    use Data::Dump;
    dd $self->{files};
}

sub postVisitFiles {
    my ($self, $dir) = @_;
    $self->{dir}->save();
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    $self->{file} = $self->{files}{$file->{name}};
    if (! $self->{file}) {
        $self->{file} = TBM::Factory::File->create;
        $self->{files}{$file->{name}} = $self->{file};
    }
    $self->updateFile($file, $stat);
    $self->{file}->save();
}

sub updateDir {
    my ($self, $dir, $stat) = @_;
    #~ $self->{dir}
}

sub updateFile {
    my ($self, $file, $stat) = @_;
    #~ $self->{file}
}

1;
