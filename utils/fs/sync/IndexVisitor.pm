package IndexVisitor;
use parent 'RJK::FileVisitor';

use RJK::Path;
use RJK::Stat;

my ($display, $baseDir, $left);

sub new {
    my $self = bless {}, shift;
    ($display, $baseDir, $left) = @_;
    return $self;
}

sub files { $_[0]{files} }

sub visitFile {
    my ($self, $file, $stat) = @_;
    $file->{stat} = $stat;
    $file->{subdirs} = $file->parent =~ s/^\Q$baseDir\E[\\\/]//ir;
    my $subpath = $file->{subdirs} ."\\". $file->{name};
    $display->stats;

    if ($left) {
        return if delete $left->files->{$subpath};
        push @{$self->{files}{$file->{stat}->size}}, $file;
    } else {
        $self->{files}{$subpath} = $file;
    }
}

sub visitFileFailed {
    my ($self, $file, $error) = @_;
    warn "$error: $_";
}

1;
