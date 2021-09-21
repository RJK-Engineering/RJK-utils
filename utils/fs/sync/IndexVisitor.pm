package IndexVisitor;
use parent 'RJK::FileVisitor';

use RJK::Path;
use RJK::Stat;

my ($opts, $display, $baseDir, $left);
my $baseDirRegex;

sub new {
    my $self = bless {}, shift;
    ($opts, $display, $baseDir, $left) = @_;
    $opts->{minDirNameLength} //= 5;

    $baseDirRegex = quotemeta $baseDir;
    $self->{dirs} = $self->{files} = {};
    return $self;
}

sub dirs { $_[0]{dirs} }
sub files { $_[0]{files} }

sub getRelativePaths {
    my $file = shift;
    $file->{subdirs} = $file->parent =~ s/^$baseDirRegex[\\\/]?//ir;
    $file->{subpath} = $file->{subdirs} ."\\". $file->{name};
}

sub preVisitDir {
    my ($self, $dir, $stat) = @_;
    $opts->{visitDirs} or return;
    if (length $dir->{name} < $opts->{minDirNameLength}) {
        $display->info("Skipping short name: $dir");
    }
    getRelativePaths($dir);

    if ($left) {
        return if delete $left->{dirs}{$dir->{subpath}};
        push @{$self->{dirs}{$dir->{name}}}, $dir;
    } else {
        $self->{dirs}{$dir->{subpath}} = $dir;
    }
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    not $opts->{visitDirs} or return;

    $file->{stat} = $stat;
    getRelativePaths($file);
    $display->stats;

    if ($left) {
        return if delete $left->{files}{$file->{subpath}};
        push @{$self->{files}{$file->{stat}->size}}, $file;
    } else {
        $self->{files}{$file->{subpath}} = $file;
    }
}

sub visitFileFailed {
    my ($self, $file, $error) = @_;
    warn "$error: $_";
}

1;
