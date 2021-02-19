package Actions;

use strict;
use warnings;

use RJK::Exceptions;
use Time::HiRes qw( gettimeofday tv_interval );
use Try::Tiny;

my $console;
my $status;
my $opts;
my $actions = {
    '?' => \&help,
    '`' => \&summary,
    1 => sub {
        &updateStatus;
        foreach ($status->all) {
            $console->printLine(sprintf "%-3.3s %-10.10s %s", $_->{name}, $status->str, $_->{label});
        }
    },
    2 => sub {
        &updateStatus;
        foreach ($status->online) {
            $console->printLine(sprintf "%-3.3s %-10.10s %s", $_->{name}, $status->str, $_->{label});
        }
    },
    toggle => sub {
        my $drive = shift;
        if ($status->toggleActive($drive)) {
            $console->printLine("$drive now active");
        } else {
            $console->printLine("$drive now inactive");
        }
        updateWindowTitle();
    },
};

sub new {
    my $self = bless {}, shift;
    ($console, $status, $opts) = @_;
    return $self;
}

sub can {
    my ($self, $actionName) = @_;
    defined $actions->{$actionName};
}

sub do {
    my ($self, $actionName, $args) = @_;
    $actions->{$actionName}($args && @$args);
}

sub preventSleep {
    my $quiet = shift;
    my @volumes = $status->active;

    $console->write(@volumes ? "Poke" : "No drives active");

    foreach my $vol (@volumes) {
        $console->write(" $vol->{name}");
        my $t = [gettimeofday];
        my $file = "$vol->{path}\\nosleep";

        if (open my $fh, '>', $file) {
            print $fh rand(2**32) if $opts->{writeRandomNumber};
            close $fh;
            unlink $file;
        } else {
            $console->write("($!)");
        }

        my $d = int tv_interval $t, [gettimeofday];
        $console->write("($d)") if $d;
    }

    $console->removeDupeLine();
    $console->newLine();
}

sub updateStatus {
    try {
        $status->update;
    } catch {
        RJK::Exceptions->handle();
    };
}

sub updateWindowTitle {
    my $self = shift;
    my @volumes = map { $_->{name} } $status->active;
    @volumes = '(none)' unless @volumes;
    $console->title("$opts->{windowTitle} | @volumes");
}

sub help {
    $console->printLine("Poke interval: $opts->{pokeInterval} seconds");
    RJK::Options::Pod::pod2usage(
        -exitstatus => 'NOEXIT',
        -sections => "USAGE/Keys",
        -width => $console->columns - 1,
        -indent => 0,
    );
    $console->lineUp();
}

sub quit {
    $console->printLine("Bye") unless $opts->{quiet};
    exit;
}

sub summary {
    my @volumes = map {
        $_->{active} ? "($_->{name})" : $_->{name}
    } $status->online;
    $console->printLine("Online: " . ("@volumes" || '(none)'));
}

1;
