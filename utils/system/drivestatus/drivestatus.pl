use strict;
use warnings;

use File::Basename;
use lib dirname (__FILE__);

use RJK::LocalConf;
use RJK::Options::Pod;

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

[`]=Summary [1]=All [2]=Online [Tab]=Poke [?]=Help [Esc]=Quit

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

$opts{statusFile} || RJK::Options::Pod::pod2usage(
    -sections => "DISPLAY EXTENDED HELP",
    -message => "Path to status file required."
);


my @ignore = split /\s+/, $opts{ignore};
$opts{ignore} = { map { $_ => 1 } @ignore };

###############################################################################

use DriveStatus;
use RJK::Exceptions;
use RJK::Util::Env;
use Try::Tiny;

$opts{statusFile} = RJK::Util::Env->subst($opts{statusFile});

try {
    DriveStatus->start(\%opts);
} catch {
    RJK::Exceptions->handle();
    exit 1;
};
