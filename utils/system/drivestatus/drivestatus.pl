use strict;
use warnings;

use Time::HiRes qw( gettimeofday tv_interval );
use Try::Tiny;

use RJK::Win32::Console;
use RJK::Win32::DriveStatus;
use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::Util::JSON;

###############################################################################
=head1 DESCRIPTION

Manage drive availability.

=head1 SYNOPSIS

drivestatus.pl [options]

=head1 EXAMPLE

Start poking and be verbose:

    $ perl drivestatus.pl -sv

=head1 DISPLAY EXTENDED HELP

drivestatus.pl -h

=head1 OPTIONS

=for options start

=over 4

=item B<-l --list>

List drives.

=item B<-s --start>

Start poking.

=item B<-i --poke-interval [integer]>

Seconds between pokes.

=item B<--ignore [string]>

Space-separated list of drives to ignore.

=item B<--status-file [string]>

Path to status file.

=item B<-w --window-title [string]>

Window title.

=item B<-v --verbose>

Be verbose.

=item B<-q --quiet>

Be quiet.

=item B<--debug>

Display debug information.

=back

=head2 Pod

=over 4

=item B<--podcheck>

Run podchecker.

=item B<--pod2html --html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<--genpod>

Generate POD for options.

=item B<--savepod>

Save generated POD to script file.
The POD text will be inserted between C<=for options start> and
C<=for options end> tags.
If no C<=for options end> tag is present, the POD text will be
inserted after the C<=for options start> tag and a
C<=for options end> tag will be added.
A backup is created.

=back

=head2 Help

=over 4

=item B<-h -? --help>

Display extended help.

=back

=for options end

=head1 USAGE

Type a drive letter to toggle between active/inactive.

=head2 Keys

[`]=Summary [1]=List [Tab]=Poke [F1]=[?]=Help [Esc]=Quit

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("system/drivestatus.properties", (
    pokeInterval => 234,
    ignore => "",
    windowTitle => $0,
));
RJK::Options::Pod::GetOptions(
    ['Options'],
    'l|list' => \$opts{list}, "List drives.",
    's|start' => \$opts{start}, "Start poking.",
    'i|poke-interval=i' => \$opts{pokeInterval}, "Seconds between pokes.",
    'ignore=s' => \$opts{ignore}, "Space-separated list of drives to ignore.",
    'status-file=s' => \$opts{statusFile}, "Path to status file.",
    'w|window-title=s' => \$opts{windowTitle}, "Window title.",

    'v|verbose' => \$opts{verbose}, "Be verbose.",
    'q|quiet' => \$opts{quiet}, "Be quiet.",
    'debug' => \$opts{debug}, "Display debug information.",


    ['Pod'],
    RJK::Options::Pod::Options,

    ['Help'],
    RJK::Options::Pod::HelpOptions
);

$opts{start} || $opts{list} || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

$opts{statusFile} || RJK::Options::Pod::pod2usage(
    -sections => "DISPLAY EXTENDED HELP",
    -message => "Path to status file required."
);

my @ignore = split /\s+/, $opts{ignore};
$opts{ignore} = { map { $_ => 1 } @ignore };

###############################################################################

my $statusFile = new RJK::Util::JSON($opts{statusFile});
my $status;
try {
    $statusFile->read;
    $status = new RJK::Win32::DriveStatus(
        ignore => $opts{ignore},
        status => $statusFile->data,
    );
    $status->update;
    $statusFile->write;
} catch {
    if ( $_->isa('Exception') ) {
        printf "%s: %s\n", ref $_, $_->error;
    } else {
        die "$_";
    }
    exit 1;
};

if ($opts{list}) {
    my @cols = qw(type online path label);
    printf "%s\t%s\t%s\t%s\n", @cols;
    $cols[0] = "typeFlag";
    foreach my $drive ($status->all) {
        printf "%s\t%s\t%s\t%s\n", map { $drive->{$_} } @cols;
    }
    exit;
}

my $console = new RJK::Win32::Console();

my $actions = {
    '?' => \&Help,
    '`' => \&Summary,
    1 => sub {
        UpdateStatus();
        my $c = 0;
        foreach ($status->all) {
            my $status =
                ! $_->{online} && "offline" ||
                  $_->{active} && "active"  ||
                                  "inactive";
            $console->updateLine(sprintf "%-3.3s %-10.10s %s\n", $_->{driveLetter}, $status, $_->{label});
            $c++;
        }
        Summary();
    },
    2 => sub {
        my $c = 0;
        foreach ($status->inactive) {
            $console->updateLine(sprintf "%-3.3s %s\n", $_->{driveLetter}, $_->{label});
            $c++;
        }
        $console->updateLine("$c drive(s) inactive\n");
    },
    3 => sub {
        my $c = 0;
        foreach ($status->online) {
            $console->updateLine(sprintf "%-3.3s %s\n", $_->{driveLetter}, $_->{label});
            $c++;
        }
        $console->updateLine("$c drive(s) online\n");
    },
    4 => sub {
        my $c = 0;
        foreach ($status->active) {
            $console->updateLine(sprintf "%-3.3s %s\n", $_->{driveLetter}, $_->{label});
            $c++;
        }
        $console->updateLine("$c drive(s) active\n");
    },
    toggle => sub {
        my $driveLetter = shift;
        UpdateStatus();
        if ($status->toggleActive($driveLetter)) {
            $console->updateLine("$driveLetter now active\n");
        } else {
            $console->updateLine("$driveLetter now inactive\n");
        }
        WriteStatus();
    },
};

###############################################################################

my @online = $status->online;
unless (@online) {
    print "No online drives\n";
    #~ exit;
}

my @volumes = map { $_->{driveLetter} } $status->active;
@volumes = '(none)' unless @volumes;
print "Active: @volumes\n";

$console->title("$opts{windowTitle} | @volumes");

if ($opts{verbose}) {
    @volumes = map { $_->{driveLetter} } $status->inactive;
    @volumes = '(none)' unless @volumes;
    print "Inactive: @volumes\n";

    my @volumes = map { $_->{driveLetter} } $status->online;
    @volumes = '(none)' unless @volumes;
    print "Online: @volumes\n";

    @volumes = map { $_->{driveLetter} } $status->offline;
    @volumes = '(none)' unless @volumes;
    print "Offline: @volumes\n";

    print "Ignore: @ignore\n";
}

Help() unless $opts{quiet};

###############################################################################

my $pokeTimer = $opts{pokeInterval};
while (1) {
    $console->updateLine($pokeTimer) if $opts{verbose};
    unless ($pokeTimer--) {
        UpdateStatus();
        PreventSleep(! $opts{verbose});
        $pokeTimer = $opts{pokeInterval};
    }
    UserInput();
    sleep 1;
}

###############################################################################

sub Summary {
    my @volumes = map {
        $_->{active} ? "($_->{driveLetter})" : $_->{driveLetter}
    } $status->online;
    @volumes = '(none)' unless @volumes;
    #~ $console->updateLine("Active: @volumes, ");

    #~ @volumes = map { $_->{driveLetter} } $status->online;
    #~ @volumes = '(none)' unless @volumes;
    $console->write("Online: @volumes\n");
}

sub Help {
    $console->updateLine("Poke interval: $opts{pokeInterval} seconds\n");
    RJK::Options::Pod::pod2usage(
        -exitstatus => 'NOEXIT',
        -sections => "USAGE/Keys",
        -width => $console->columns - 1,
        -indent => 0,
    );
    $console->lineUp();
}

sub Quit {
    $console->printLine("Bye") unless $opts{quiet};
    exit;
}

sub UserInput {
    while ($console->getEvents) {
        my @event = $console->input();
        if (@event && $event[0] == 1 and $event[1]) {
            #~ print "@event\n";
            if ($event[5]) {                    # ASCII
                if ($event[5] == 9) {           # Tab
                    PreventSleep();
                } elsif ($event[5] == 27) {     # Esc
                    Quit();
                } else {
                    my $key = lc chr $event[5];
                    if ($actions->{$key}) {     # action key
                        $actions->{$key}->();
                    } else {                    # drive letter
                        $actions->{toggle}->(uc $key);
                    }
                }
            } elsif ($event[3] == 112) {        # F1
                Help();
            } else {
                next;
            }
            last;
        }
    }
    # empty buffer
    $console->flush();
}

sub PreventSleep {
    my $quiet = shift;

    my @volumes = $status->active;
    my $poked = 0;

    foreach my $vol (@volumes) {
        $console->updateLine("Poke") unless $poked;
        $poked++;
        $console->write(" $vol->{driveLetter}");

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
        $console->write("\n");
    } else {
        $console->updateLine("No drives active\n") unless $quiet;
    }
    return $poked;
}

sub UpdateStatus {
    try {
        $status->update;
        $statusFile->write();
    } catch {
        if ( $_->isa('Exception') ) {
            $console->updateLine(sprintf "%s: %s\n", ref $_, $_->error);
        } else {
            die "$!";
        }
    };
}

sub WriteStatus {
    try {
        $statusFile->write();
        my @volumes = map { $_->{driveLetter} } $status->active;
        @volumes = '(none)' unless @volumes;
        $console->title("$opts{windowTitle} | @volumes");
    } catch {
        if ( $_->isa('Exception') ) {
            $console->updateLine(sprintf "%s: %s\n", ref $_, $_->error);
        } else {
            die "$!";
        }
        exit 1;
    };
}
