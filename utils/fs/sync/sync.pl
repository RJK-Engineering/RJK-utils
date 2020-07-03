use strict;
use warnings;

use File::Copy ();
use File::Path ();
use Number::Bytes::Human;
use Time::HiRes ();

use RJK::File::Paths;
use RJK::File::Stat;
use RJK::Files::Stats;
use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::SimpleFileVisitor;
use RJK::Win32::Console;

use File::Basename;
use lib dirname (__FILE__);
use SyncFileVisitor;

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

=head1 Options

=over 4

=item B<-i -refresh-interval [seconds]>

Refresh interval in seconds. Real number, default: 0.2

=item B<-mds -move-diff-size>

=item B<-v -verbose>

Be verbose.

=item B<-q -quiet>

Be quiet.

=item B<-debug>

Display debug information.

=back

=head1 Pod

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

=head1 Help

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

my %opts = RJK::LocalConf::GetOptions("fs/sync.properties", (
    refreshInterval => .2,
));
RJK::Options::Pod::GetOptions(
    ['Options'],
    'i|refresh-interval=f' => \$opts{refreshInterval},
        "Refresh interval in {seconds}. Real number, default: $opts{refreshInterval}",
    #~ 'mds|move-diff-size' => \$opts{moveDifferentSize}, "",
    'm|move-files-in-target' => \$opts{moveFilesInTarget}, "Rename/move files in target.",
    #~ 'c|copy-missing-files' => \$opts{copyMissingFiles}, "Copy files from source to target.",
    #~ 'r|remove-files-in-target' => \$opts{removeFilesInTarget}, "Delete files in target not in source.",
    'd|dry-run' => \$opts{dryRun}, "Don't copy or move any files.",

    'v|verbose' => \$opts{verbose}, "Be verbose.",
    'q|quiet' => \$opts{quiet}, "Be quiet.",
    'debug' => \$opts{debug}, "Display debug information.",

    ['Pod'],
    RJK::Options::Pod::Options,

    ['Help'],
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

sub Ignore { 0 }
opendir my $dh, $opts{targetDir} or die "$!";
my @dirs = grep { -d "$opts{targetDir}\\$_" && ! /^\./ && ! Ignore($_) } readdir $dh;
closedir $dh;

if (! @dirs) {
    die "No dirs in target: $opts{targetDir}";
}

foreach (@dirs) {
    print "Dir: $_\n";
}

my $console = new RJK::Win32::Console();

Synchronize(IndexTarget());

sub IndexTarget {
    my $lastDisplay = 0;

    my $filesInTarget = {
        name => {},
        size => {},
    };

    my $stats = RJK::Files::Stats::CreateStats();
    my $visitor = new RJK::SimpleFileVisitor(
        visitFile => sub {
            my ($file, $stat) = @_;
            my $time = Time::HiRes::gettimeofday;
            if ($lastDisplay < $time - $opts{refreshInterval}) {
                DisplayStats($stats);
                $lastDisplay = $time;
            }
            $file->{stat} = $stat;
            push @{$filesInTarget->{name}{$file->{name}}}, $file;
            push @{$filesInTarget->{size}{$stat->{size}}}, $file;
        },
        visitFileFailed => sub {
            my ($file, $error) = @_;
            die "$error: $file->{path}";
        },
    );

    foreach (@dirs) {
        my $path = "$opts{targetDir}\\$_";
        $console->updateLine("Indexing $path ...\n");
        DisplayStats($stats);
        RJK::Files::Stats::Traverse($path, $visitor, {}, $stats);
    }
    DisplayStats($stats);
    $console->newline;

    return $filesInTarget;
}

sub Synchronize {
    my $filesInTarget = shift;

    my $stats = RJK::Files::Stats::CreateStats();
    my $visitor = new SyncFileVisitor($filesInTarget, \%opts);

    foreach my $dir (@dirs) {
        print "\nSynchronizing $dir ...\n";

        if (! -e $dir) {
            print "Directory does not exist in source: $dir\n";
            next;
        } elsif (! -d $dir) {
            warn "Source is not a directory";
            exit;
        } elsif (! -r $dir) {
            warn "Source directory is not readable";
            exit;
        }

        RJK::Files::Stats::Traverse($dir, $visitor, {}, $stats);
        DisplayStats($stats);
    }
}

sub DisplayStats {
    my $stats = shift;
    $console->updateLine(
        sprintf "%s in %s files",
            Number::Bytes::Human::format_bytes($stats->{size}),
            $stats->{visitFile}
    );
}
