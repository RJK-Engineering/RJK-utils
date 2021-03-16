package Display;

use strict;
use warnings;

use RJK::HumanReadable::Size;
use RJK::Win32::Console;
use Time::HiRes ();

my $console = new RJK::Win32::Console();
my $sizeFormatter = 'RJK::HumanReadable::Size';
my $opts;
my $stats;
my $progress;
my $lastDisplay = 0;

sub new {
    my $self = bless {}, shift;
    $opts = shift;
    return $self;
}

sub setStats {
    my $self = shift;
    $stats = shift;
}

sub setProgressBar {
    my $self = shift;
    $progress = shift;
}

sub info {
    my ($self, $message) = @_;
    $console->printLine($message);
    $lastDisplay = 0;
}

sub warn {
    my ($self, $message) = @_;
    $console->printLine($message);
    $lastDisplay = 0;
}

sub start {
    $progress->{done} = 0;
    $lastDisplay = 0;
    &_progress;
}

sub progress {
    return if timer();
    &_progress;
}

sub done {
    &_progress;
}

sub _progress {
    $console->updateLine(
        sprintf "%u%% %u of %u",
            $progress->{done} && $progress->{done} / $progress->{total} * 100,
            $progress->{done},
            $progress->{total}
    );
}

sub stats {
    return if timer();
    &_stats;
}

sub totals {
    &_stats;
}

sub _stats {
    $console->updateLine(
        sprintf "%s in %s files",
            $sizeFormatter->get($stats->{size}),
            $stats->{files}
    );
}

sub timer {
    my $time = Time::HiRes::gettimeofday;
    return 1 if $lastDisplay > $time - $opts->{refreshInterval};
    $lastDisplay = $time;
    return 0;
}

1;
