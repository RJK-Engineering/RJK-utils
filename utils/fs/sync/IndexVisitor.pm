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

sub index { $_[0]{index} }
sub equal { $_[0]{equal} }

sub visitFile {
    my ($self, $file, $stat) = @_;
    $file->{stat} = $stat;
    $file->{subdirs} = $file->parent =~ s/^\Q$baseDir\E[\\\/]//ir;
    my $subpath = $file->{subdirs} ."\\". $file->{name};
    $display->stats;

    if ($left) {
        if (my $match = delete $left->{$subpath}) {
            $self->{equal}{$subpath} = $file if $self->{indexEqual};
        } else {
            push @{$self->{index}{$file->{stat}->size}}, $file;
        }
    } else {
        $self->{index}{$subpath} = $file;
    }
}

sub visitFileFailed {
    my ($self, $file, $error) = @_;
    warn "$error: $_";
}

1;
