use strict;
use warnings;
use utf8;

use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::Media::MPC::MPCMonControl;

###############################################################################
=head1 DESCRIPTION

Monitor Media Player Classic instances (processes), settings (mpc-hc.ini),
playlists (default.mpcpl) and snapshots (directory watch).

=head1 SYNOPSIS

mpcssmon.pl [options]

=head1 DISPLAY EXTENDED HELP

mpcssmon.pl -h

=head1 OPTIONS

=for options start

=over 4

=item B<-snapshot-dir [path]>

Path to snapshot directory.

=item B<-snapshot-bin [path]>

Path to snapshot bin.

=item B<-status-file [path]>

Path to status file.

=item B<-lock-file [path]>

Path to lock file.

=item B<-log-file [path]>

Path to log file.

=item B<-port [number]>

Port to web interface.

=item B<-i -polling-interval [seconds]>

Polling interval in seconds. Default: 1

=item B<-w -window-title [string]>

Window title.

=item B<-c -categories [string]>

Comma separated list of directory names.

=item B<-p -playlist-dir [path]>

Path to playlist directory.

=item B<-x -complete-cmd [string]>

Command to execute to complete F<.part> files.

=item B<-r -run>

Start monitoring. Ctrl+C = stop and exit.

=item B<-s -status>

Show Media Player Classic status.

=item B<-open-status>

Open status file.

=item B<-open-log>

Open log file.

=item B<-v -verbose>

Be verbose.

=item B<-q -quiet>

Be quiet.

=item B<-debug>

Display debug information.

=back

=head2 Pod

=over 4

=item B<-podcheck>

Run podchecker.

=item B<-pod2html -html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<-genpod>

Generate POD for options.

=item B<-savepod>

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

=item B<-h -? -help>

Display extended help.

=back

=for options end

=head1 USAGE

=head2 Keys

&del &move &complete &reset &undo
&list &open &status &pause &help(F1) &quit(Esc)

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("mpcmon/mpcmon.properties", (
    run => 0,
    snapshotDir => '.',
    windowTitle => $0,
    pollingInterval => 5,
));

RJK::Options::Pod::GetOptions(
    ['Options'],
    'snapshot-dir=s' => \$opts{snapshotDir}, "{Path} to snapshot directory.",
    'snapshot-bin=s' => \$opts{snapshotBinDir}, "{Path} to snapshot bin.",
    'settings-file=s' => \$opts{settingsFile}, "{Path} to settings file.",
    'lock-file=s' => \$opts{lockFile}, "{Path} to lock file.",
    'log-file=s' => \$opts{logFile}, "{Path} to log file.",

    'port=i' => \$opts{port}, [ "Port to web interface.", 'number' ],
    'i|polling-interval=i' => \$opts{pollingInterval},
        "Polling interval in {seconds}. Default: $opts{pollingInterval}",

    'w|window-title=s' => \$opts{windowTitle}, "Window title.",
    'c|categories=s' => \$opts{categories}, "Comma separated list of directory names.",
    'p|playlist-dir=s' => \$opts{playlistDir}, "{Path} to playlist directory.",
    'x|complete-cmd=s' => \$opts{completeCommand},
        "Command to execute to complete F<.part> files.",

    'r|run' => \$opts{run}, "Start monitoring. Ctrl+C = stop and exit.",
    's|status' => \$opts{status}, "Show Media Player Classic status.",
    'open-log' => \$opts{openLog}, "Open log file.",
    'e|edit' => \$opts{editSettings}, "Edit settings file.",

    'v|verbose' => \$opts{verbose}, "Be verbose.",
    'q|quiet' => \$opts{quiet}, "Be quiet.",
    'debug' => \$opts{debug}, "Display debug information.",

    ['Pod'],
    RJK::Options::Pod::Options,

    ['Help'],
    RJK::Options::Pod::HelpOptions
);

exit Edit($opts{settingsFile}) if $opts{editSettings};
exit Edit($opts{logFile}) if $opts{openLog};

# required options and/or arguments
$opts{run} ||
$opts{status} || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

# quiet!
$opts{verbose} = 0 if $opts{quiet};

# array of categories
$opts{categories} = [ split /,/, $opts{categories} ];

$opts{snapshotBinDir} //= "$opts{snapshotDir}\\del";

###############################################################################

$SIG{'INT'} = q(Interrupt);

my $control = new RJK::Media::MPC::MPCMonControl(\%opts);
$control->init();
$control->start();

###############################################################################

sub Interrupt {
    my ($signal) = @_;
    exit;
}

END {
    $control->stop;
}

sub Edit {
    my $file = shift;
    return 1 if ! $file;
    return system $ENV{EDITOR} || "edit", $file;
}

sub Help {
    RJK::Options::Pod::pod2usage(
        -exitstatus => 'NOEXIT',
        -verbose => 99,
        -sections => "USAGE/Keys",
        -indent => 0,
        -width => $control->{console}->columns,
    );
    $control->{console}->lineUp;
}
