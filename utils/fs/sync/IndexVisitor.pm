package IndexVisitor;
use parent 'RJK::FileVisitor';

use RJK::Path;
use RJK::Stat;

my $display;
my $baseDir;
my $index;

sub new {
    my $self = bless {}, shift;
    $display = shift;
    $baseDir = shift;
    $index = {};
    return $self;
}

sub getIndex {
    return $index;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    $file->{stat} = $stat;
    $display->stats;

    push @{$index->{name}{$file->name}}, $file;
    my $dir = $file->parent =~ s/^\Q$baseDir\E//ir;
    push @{$index->{size}{$dir}{$stat->size}}, $file;
}

sub visitFileFailed {
    my ($self, $file, $error) = @_;
    warn "$error: $_";
}

1;
