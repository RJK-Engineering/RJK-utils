use strict;
use warnings;

use File::Copy ();
use File::Path ();
use Number::Bytes::Human;
use Time::HiRes ();

use RJK::File::Paths;
use RJK::File::Stat;
use RJK::Files::Stats;
use RJK::Options::Pod;
use RJK::SimpleFileVisitor;
use RJK::Win32::Console;

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

my %opts = (
    refreshInterval => .2,
);
RJK::Options::Pod::GetOptions(
    ['Options'],
    'i|refresh-interval=f' => \$opts{refreshInterval},
        "Refresh interval in {seconds}. Real number, default: $opts{refreshInterval}",
    'mds|move-diff-size' => \$opts{moveDifferentSize}, "",

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
    die "Target does not exist";
} elsif (! -d $opts{targetDir}) {
    die "Target is not a directory";
} elsif (! -r $opts{targetDir}) {
    die "Target dir is not readable";
}

###############################################################################

sub Ignore { 0 }
opendir my $dh, $opts{targetDir} or die "$!";
my @dirs = grep { -d "$opts{targetDir}\\$_" && ! /^\./ && ! Ignore($_) } readdir $dh;
closedir $dh;

my $filesInTarget = { # index by name and size
    name => {},
    size => {},
};
my $console = new RJK::Win32::Console();
my (@modified, @notInSource, @notInTarget);

IndexTarget();
Synchronize();

sub IndexTarget {
    my $lastDisplay = 0;

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
            print "$error: $file->{path}\n";
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
}

sub Synchronize {
    my $stats = RJK::Files::Stats::CreateStats();
    my $visitor = new RJK::SimpleFileVisitor(
        visitFile => sub { VisitFile(@_) },
    );

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

# find source file in target and move to correct dir
sub VisitFile {
    my ($source, $sourceStat) = @_;

    my $targetDir = RJK::File::Paths::get($opts{targetDir}, $source->{directories})->{path};
    my $targetPath = RJK::File::Paths::get($targetDir, $source->{name})->{path};

    if (-e $targetPath) {
        checkTarget($sourceStat, $targetPath);
        return;
    }

    my $inTarget = findMoved($source->{name}, $sourceStat)
        || findRenamed($sourceStat);

    if (! $inTarget) {
        push @notInTarget, $source;
        return;
    }

    if ($source->{name} eq $inTarget->{name}) {
        moveFile($inTarget->{path}, $targetDir);
    } else {
        moveFile($inTarget->{path}, $targetDir, $targetPath);
    }

    removeFromIndex($source, $sourceStat, $inTarget);
}

sub checkTarget {
    my ($sourceStat, $targetPath) = @_;
    my $targetStat = RJK::File::Stat::get($targetPath);
    if ($sourceStat->{size} != $targetStat->{size}) {
        die "Size mismatch, $sourceStat->{size} != $targetStat->{size}: $targetPath";
    }
    if (! checkDates($sourceStat, $targetStat)) {
        warn "Date mismatch: $targetPath";
    }
}

sub checkDates {
    my ($sourceStat, $targetStat) = @_;
    return $sourceStat->{modified} == $targetStat->{modified};
}

# files in diffent directory (same name, size and modified date)
sub findMoved {
    my ($name, $sourceStat) = @_;
    my $inTarget = $filesInTarget->{name}{$name};

    if (! $inTarget) {
        return;
    }

    if (@$inTarget > 1) {
        printf "%u files with same name: %s\n",
            scalar @$inTarget, $name;
    }

    my @same;
    foreach my $target (@$inTarget) {
        if ($sourceStat->{size} != $target->{stat}{size}) {
            print "Same name, different size: $target->{path}\n";
        } elsif (! checkDates($sourceStat, $target->{stat})) {
            print "Same name, same size, diffent dates: $target->{path}\n";
        } else {
            push @same, $target;
        }
    }

    if (@same > 1) {
        printf "%u duplicate files: %s\n",
            scalar @same, join(" ", map { $_->{path} } @same);
        return;
    }

    return shift @same;
}

# files with same size and modified date (can be in different directory)
sub findRenamed {
    my ($sourceStat) = @_;
    my $inTarget = $filesInTarget->{size}{$sourceStat->{size}};

    if (! $inTarget) {
        return;
    }

    if (@$inTarget > 1) {
        printf "%u files with same size: %u\n",
            scalar @$inTarget, $sourceStat->{size};
    }

    my @same;
    foreach my $target (@$inTarget) {
        if (checkDates($sourceStat, $target->{stat})) {
            push @same, $target;
        }
    }

    if (@same > 1) {
        printf "%u files with same size and dates: %s\n",
            scalar @same, join(" ", map { $_->{path} } @same);
        return;
    }

    return shift @same;
}

sub moveFile {
    my ($sourcePath, $targetDir, $targetPath) = @_;

    if (! -e $targetDir) {
        File::Path::make_path($targetDir) or die "Error creating directory: $targetDir";
    }
    -e $targetDir or die "Target directory does not exist: $targetDir";

    $targetPath //= $targetDir;
    print "<$sourcePath\n";
    print ">$targetPath\n";
    #~ File::Copy::move($targetPath, $targetPath) or die "Error moving file";

    sleep 1 if $opts{verbose};
}

sub removeFromIndex {
    my ($source, $sourceStat, $inTarget) = @_;

    my $it = $filesInTarget->{name}{$source->{name}};
    @$it = grep { $_ != $inTarget } @$it;

    $it = $filesInTarget->{size}{$sourceStat->{size}};
    @$it = grep { $_ != $inTarget } @$it;
}
