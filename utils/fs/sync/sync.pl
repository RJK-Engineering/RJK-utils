use strict;
use warnings;

use File::Basename;
use lib dirname (__FILE__);

use RJK::LocalConf;
use RJK::Options::Pod;

###############################################################################
=head1 DESCRIPTION

Synchronize directories.

Find moved and/or renamed files in target:
1. in diffent directory (same name, size and modified date)
2. with same size and modified date (can be in different directory)

Create lists of:
1. modified files
2. moved files
3. source files not in target
4. target files not in source

=head1 SYNOPSIS

sync.pl [options] [target directory]

=head1 DISPLAY EXTENDED HELP

sync.pl -h

=for options start

=head1 OPTIONS

=over 4

=item B<-i -refresh-interval [seconds]>

Refresh interval in seconds. Real number, default: .2

=item B<-m -move-files-in-target>

Rename/move files in target.

=item B<-d -dry-run>

Don't copy or move any files.

=item B<-v -verbose>

Be verbose.

=item B<-q -quiet>

Be quiet.

=item B<-debug>

Display debug information.

=back

=head1 POD

=over 4

=item B<-podcheck>

Run podchecker.

=item B<-pod2html -html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<-genpod>

Generate POD for options.

=item B<-writepod>

Write generated POD to script file.
The POD text will be inserted between C<=for options start> and
C<=for options end> tags.
If no C<=for options end> tag is present, the POD text will be
inserted after the C<=for options start> tag and a
C<=for options end> tag will be added.
A backup is created.

=back

=head1 HELP

=over 4

=item B<-h -help -?>

Display program options.

=item B<-hh "-help -help" -??>

Display help options.

=item B<-hhh "-help -help -help" -???>

Display POD options.

=item B<-hhhh "-help -help -help -help" -????>

Display complete help.

=back

=for options end

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("RJK-utils/fs/sync.properties", (
    refreshInterval => .2,
));
RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'i|refresh-interval=f' => \$opts{refreshInterval},
        "Refresh interval in {seconds}. Real number, default: $opts{refreshInterval}",
    #~ 'mds|move-diff-size' => \$opts{moveDifferentSize}, "",
    'm|move-files-in-target' => \$opts{moveFilesInTarget}, "Rename/move files in target.",
    #~ 'c|copy-missing-files' => \$opts{copyMissingFiles}, "Copy files from source to target.",
    #~ 'r|remove-files-in-target' => \$opts{removeFilesInTarget}, "Delete files in target not in source.",
    'simulate' => \$opts{simulate}, "Do not make any changes to the file system.",

    'v|verbose' => \$opts{verbose}, "Be verbose.",
    'q|quiet' => \$opts{quiet}, "Be quiet.",
    'debug' => \$opts{debug}, "Display debug information.",

    ['POD'],
    RJK::Options::Pod::Options,

    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

@ARGV || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

$opts{targetDir} = shift;
$opts{targetDir} =~ s|\/|\\|g;      # replace forward with backward slashes
$opts{targetDir} =~ s|\\+$||;   # remove trailing slashes
if (! -e $opts{targetDir}) {
    die "Target does not exist: $opts{targetDir}";
} elsif (! -d $opts{targetDir}) {
    die "Target is not a directory: $opts{targetDir}";
} elsif (! -r $opts{targetDir}) {
    die "Target dir is not readable: $opts{targetDir}";
}

###############################################################################

use Sync;

Sync->execute(\%opts);
