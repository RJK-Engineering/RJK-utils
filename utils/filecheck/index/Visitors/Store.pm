package Visitors::Store;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

use RJK::Drives;
use RJK::Stat;
use TBM::Dir;
use TBM::File;
use TBM::Factory;

sub preVisitDir {
    my ($self, $dir, $stat) = @_;
    my $storePath = getPath($dir);

    if (not $self->{dir} = TBM::Factory->Dir->fetch($storePath)) {
        $self->{dir} = TBM::Factory->Dir->create();
        $self->{dir}{path} = $storePath;
    }
    updateDir($self->{dir}, $dir, $stat);
    $self->{files} = $self->{dir}->getFiles;
}

sub getPath {
    my ($diskPath) = @_;
    my $label = RJK::Drives->getLabel($diskPath);
    my $path = RJK::Drives->getPathOnVolume($diskPath) =~ s|\\+|/|gr;
    return "/volumes/$label$path";
}

sub postVisitFiles {
    my ($self, $dir) = @_;
    $self->{dir}->save();
    $self->{dir} = undef;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    my $dbo = $self->{files}{$file->{name}};
    if ($dbo) {
        updateFile($dbo, $file, $stat);
    } else {
        $dbo = TBM::Factory->File->create;
        updateFile($dbo, $file, $stat);
        $self->{dir}->addFile($dbo);
    }
    $dbo->save();
}

sub updateDir {
    my ($dbo, $dir, $stat) = @_;
    $dbo->{name} = $dir->{name};
    $dbo->{created} = $stat->created;
    $dbo->{modified} = $stat->modified;
}

sub updateFile {
    my ($dbo, $file, $stat) = @_;
    $dbo->{name} = $file->{name};
    $dbo->{size} = $file->{size};
    $dbo->{created} = $stat->created;
    $dbo->{modified} = $stat->modified;
    $dbo->{crc} = $file->{crc};
}

1;
