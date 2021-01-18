package IndexFileVisitor;
use parent 'RJK::FileVisitor';

use Time::HiRes ();

my $opts;
my $lastDisplay = 0;
my $filesInTarget = 0;
my $display;

sub new {
    my $self = bless {}, shift;
    $opts = shift;
    $filesInTarget = shift;
    $display = shift;
    return $self;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    my $time = Time::HiRes::gettimeofday;
    if ($lastDisplay < $time - $opts->{refreshInterval}) {
        $display->stats;
        $lastDisplay = $time;
    }
    $file->{stat} = $stat;
    push @{$filesInTarget->{name}{$file->{name}}}, $file;
    push @{$filesInTarget->{size}{$stat->size}}, $file;
}

sub visitFileFailed {
    my ($self, $file, $error) = @_;
    warn "$error: $file->{path}";
}

1;
