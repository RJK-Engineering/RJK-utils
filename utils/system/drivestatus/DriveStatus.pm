package DriveStatus;

use RJK::Win32::Console;
use RJK::Win32::DriveStatus;

use Actions;
use Controller;

my $opts;
my $console;
my $status;
my $actions;
my $controller;

sub start {
    my $self = shift;
    $opts = shift;
    &init;
    &list if $opts->{list};

    $actions->updateWindowTitle();
    $actions->summary();
    $actions->help() unless $opts->{quiet};
    my $pokeTimer = $opts->{pokeInterval};

    while (1) {
        unless ($pokeTimer--) {
            $actions->updateStatus();
            $actions->preventSleep(! $opts->{verbose});
            $pokeTimer = $opts->{pokeInterval};
        }
        $controller->userInput();
        sleep 1;
    }
}

sub init {
    $status = new RJK::Win32::DriveStatus($opts);
    $console = new RJK::Win32::Console();
    $actions = new Actions($console, $status, $opts);
    $controller = new Controller($console, $actions);
    $actions->updateStatus();
}

sub list {
    my @cols = qw(type online path label);
    $console->printLine(sprintf "%s\t%s\t%s\t%s", @cols);
    $cols[0] = "typeFlag";
    foreach my $drive ($status->all) {
        $console->printLine(sprintf "%s\t%s\t%s\t%s", map { $drive->{$_} } @cols);
    }
    exit;
}

1;
