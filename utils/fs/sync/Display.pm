package Display;

use strict;
use warnings;

use RJK::HumanReadable::Size;
use RJK::Win32::Console;

my $console = new RJK::Win32::Console();
my $sizeFormatter = 'RJK::HumanReadable::Size';
my $stats;

sub new {
    return bless {}, shift;
}

sub setStats {
    my $self = shift;
    $stats = shift;
}

sub info {
    my ($self, $message) = @_;
    $console->printLine($message);
}

sub warn {
    my ($self, $message) = @_;
    $console->printLine($message);
}

sub stats {
    my ($self, $myStats) = @_;
    $myStats //= $stats // return;
    $console->updateLine(
        sprintf "%s in %s files",
            $sizeFormatter->get($myStats->{size}),
            $myStats->{visitFile}
    );
}

1;