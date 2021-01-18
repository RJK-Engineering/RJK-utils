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
        my $c = 0;
        foreach ($status->all) {
            my $status =
                ! $_->{online} && "offline" ||
                  $_->{active} && "active"  ||
                                  "inactive";
            $console->printLine(sprintf "%-3.3s %-10.10s %s", $_->{letter}, $status, $_->{label});
            $c++;
        }
        summary();
    },
    2 => sub {
        my $c = 0;
        foreach ($status->inactive) {
            $console->printLine(sprintf "%-3.3s %s", $_->{letter}, $_->{label});
            $c++;
        }
        $console->printLine("$c drive(s) inactive");
    },
    3 => sub {
        my $c = 0;
        foreach ($status->online) {
            $console->printLine(sprintf "%-3.3s %s", $_->{letter}, $_->{label});
            $c++;
        }
        $console->printLine("$c drive(s) online");
    },
    4 => sub {
        my $c = 0;
        foreach ($status->active) {
            $console->printLine(sprintf "%-3.3s %s", $_->{letter}, $_->{label});
            $c++;
        }
        $console->printLine("$c drive(s) active");
    },
    toggle => sub {
        my $driveLetter = shift;
        &updateStatus;
        if ($status->toggleActive($driveLetter)) {
            $console->printLine("$driveLetter now active");
        } else {
            $console->printLine("$driveLetter now inactive");
        }
        updateWindowTitle();
        writeStatusFile();
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
    my $poked = 0;

    foreach my $vol (@volumes) {
        $console->write("Poke") unless $poked;
        $poked++;
        $console->write(" $vol->{letter}");

        my $t = [gettimeofday];

        my $file = "$vol->{path}\\nosleep";
        if (open my $fh, '>', $file) {
            #~ print $fh rand(2**32);
            close $fh;
            unlink $file;
        } else {
            $console->write("($!)");
        }

        my $d = int tv_interval $t, [gettimeofday];
        $console->write("($d)") if $d;
    }
    if ($poked) {
        $console->newLine();
    } else {
        $console->printLine("No drives active") unless $quiet;
    }
    return $poked;
}

sub updateStatus {
    try {
        writeStatusFile() if $status->update;
    } catch {
        RJK::Exceptions->handle();
    };
}

sub writeStatusFile {
    RJK::Util::JSON->write($opts->{statusFile}, $status->{status});
}

sub updateWindowTitle {
    my $self = shift;
    my @volumes = map { $_->{letter} } $status->active;
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
        $_->{active} ? "($_->{letter})" : $_->{letter}
    } $status->online;
    @volumes = '(none)' unless @volumes;
    #~ $console->printLine("Active: @volumes, ");

    #~ @volumes = map { $_->{letter} } $status->online;
    #~ @volumes = '(none)' unless @volumes;
    $console->printLine("Online: @volumes");
}

1;
