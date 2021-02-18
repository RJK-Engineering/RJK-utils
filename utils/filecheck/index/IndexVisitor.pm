package IndexVisitor;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

use FileVisitResult;
use RJK::Filecheck;
use RJK::Filecheck::Dir;
use RJK::Filecheck::Properties;

my $conf;
my $stats;
my $visitors;

sub new {
    my $self = bless {}, shift;
    $conf = shift;
    $stats = shift;
    $visitors = $conf->getVisitors();
    return $self;
}

sub preVisitDir {
    my ($self, $dir, $stat) = @_;
    print "$dir->{path}\\\n";
    return FileVisitResult::SKIP_SUBTREE if $self->ignore($dir, $stat);

    $self->{dir} = new RJK::Filecheck::Dir($dir);
    $self->{visited} = {};

    $self->{dirProps} = $self->{dir}->getProperties();
    foreach my $visitor (@$visitors) {
        $visitor->preVisitDir($dir, $stat, $self->{dirProps});
    }
}

sub postVisitFiles {
    my ($self, $dir, $stat) = @_;

    foreach my $visitor (@$visitors) {
        $visitor->postVisitFiles($dir, $stat, $self->{dirProps});
    }
    $self->{dir}->setProperties($self->{dirProps});

    foreach (@{$self->{dir}->getFiles}) {
        next if $self->{visited}{$_};
        $self->{dir}->removeFile($_);
        print "Removed file: $_\n";
    }
    $self->{dir}->saveProperties;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    return if $self->ignore($file, $stat);
    $self->{visited}{$file->name} = 1;
    print "$file->{path}\n";

    my $fileTypes = $conf->getFileTypes($file, $stat);
    return if !@$fileTypes;
    print "File type: @$fileTypes\n";
    $file->{type} = $fileTypes;

    $self->visit($fileTypes, $file, $stat);
}

sub visit {
    my ($self, $fileTypes, $file, $stat) = @_;
    my @visitors = @$visitors;
    push @visitors, @{$conf->getFileTypeVisitors($fileTypes)};

    my $props = $self->{dir}->getFileProperties($file->name);
    foreach my $visitor (@visitors) {
        $visitor->visitFile($file, $stat, $props);
    }
    $self->{dir}->setFileProperties($file->name, $props);
}

sub ignore {
    my ($self, $file, $stat) = @_;
    local $_ = $file->{name};
    foreach ('$RECYCLE.BIN', 'System Volume Information') {
        return 1 if $_ eq $file->{name};
    }
    /^[.~]/ || /~$/;
}

1;
