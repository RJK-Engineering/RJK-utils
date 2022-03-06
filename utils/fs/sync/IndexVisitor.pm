package IndexVisitor;
use parent 'RJK::FileVisitor';

use RJK::Path;
use RJK::Paths;
use RJK::Stat;

my ($opts, $display, $baseDir, $left);
my $baseDirRegex;

sub new {
    my $self = bless {}, shift;
    ($opts, $display, $baseDir, $left) = @_;

    $baseDirRegex = quotemeta $baseDir;
    $self->{dirs} = $self->{files} = {};
    return $self;
}

sub dirs { $_[0]{dirs} }
sub files { $_[0]{files} }

sub getFileInfo {
    my ($path, $stat) = @_;
    my $parent = $path->parent =~ s/^$baseDirRegex[\\\/]?//ir;
    return {
        fullPath => $path->path,
        path => RJK::Paths->get($parent, $path->name),
        parent => $parent,
        name => $path->name,
        size => $stat->size,
        modified => $stat->modified
    };
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    $file = getFileInfo($file, $stat);
    $display->stats;

    if ($left) {
        return if delete $left->{files}{$file->{path}};
        push @{$self->{files}{$file->{size}}}, $file;
    } else {
        $self->{files}{$file->{path}} = $file;
    }
}

sub visitFileFailed {
    my ($self, $file, $error) = @_;
    warn "$error: $_";
}

1;
