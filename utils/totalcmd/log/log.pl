use strict;
use warnings;

use Exceptions;
use File::Copy ();
use File::Spec::Functions qw(splitpath);

use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::TotalCmd::Log;

###############################################################################
=head1 DESCRIPTION

Manage and search Total Commander log files.

=head1 SYNOPSIS

log.pl [options] [search terms]

=head1 DISPLAY EXTENDED HELP

log.pl -h

=for options start

=head1 OPTIONS

=over 4

=item B<-a --all>

Search all available archives.

=item B<-S --search-source>

Only search sources (search sources and destinations by default).

=item B<-D --search-destination>

Only search destinations (search sources and destinations by default).

=item B<-l --list>

List log files.

=item B<-m --archive-size [n]>

Move log to archive when exceeding [n] mb.

=item B<-f --search-files>

TODO

=item B<-g --search-directories>

TODO

=item B<-d --start-date [date]>

Search start date. YYYYMMDD formatted number, does numeric comparison, zero padded on right-hand-side, e.g. for "201": 20100000 < 20100101

=item B<-e --regex>

Use regular expression.

=item B<-o --operation [string]>

Filter by operation matching start of operation name, i.e. 'm' for 'Move'.

=item B<-p --plugin-op>

TODO

=item B<--log-file [string]>

Path to Total Commander log file.

=item B<--archive-dir [string]>

TODO

=item B<-h --head [n]>

Show first [n] results.

=back

=head1 POD

=over 4

=item B<--podcheck>

Run podchecker.

=item B<--pod2html --html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<--genpod>

Generate POD for options.

=item B<--writepod>

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

=item B<--help -?>

Display extended help.

=item B<--help-all>

Display all help.

=back

=for options end

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("RJK-utils/totalcmd/log.properties", (
    showPluginOp => 1,
));

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'a|all' => \$opts{all},
        "Search all available archives.",
    'S|search-source' => \$opts{searchSource},
        "Only search sources (search sources and destinations by default).",
    'D|search-destination' => \$opts{searchDestination},
        "Only search destinations (search sources and destinations by default).",
    'l|list' => \$opts{list},
        "List log files.",
    'm|archive-size=i' => \$opts{archiveSize},
        "Move log to archive when exceeding [{n}] mb.",
    'f|search-files' => \$opts{searchFiles},
        "TODO",
    'g|search-directories' => \$opts{searchDirectories},
        "TODO",
    'd|start-date=s' => \$opts{startDate},
        "Search start {date}. YYYYMMDD formatted number, does numeric comparison,".
        " zero padded on right-hand-side, e.g. for \"201\": 20100000 < 20100101",

    'e|regex' => \$opts{regex},
        "Use regular expression.",
    'o|operation=s' => \$opts{operation},
        "Filter by operation matching start of operation name, i.e. 'm' for 'Move'.",
    'p|plugin-op' => \$opts{showPluginOp},
        "TODO",

    'log-file=s' => \$opts{logFile},
        "Path to Total Commander log file.",
    'archive-dir=s' => \$opts{archiveDir},
        "TODO",

    'h|head:i' => \$opts{head},
        "Show first [{n}] results.",

    ['POD'],
    RJK::Options::Pod::Options,
    ['HELP'],
    RJK::Options::Pod::HelpOptions(['help|?'])
);

$opts{head} ||= defined $opts{head} ? 10 : -1;

@ARGV ||
$opts{list} || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

###############################################################################

my @searchTerms;
if (@ARGV) {
    @searchTerms = GetTerms(@ARGV);
    if (! @searchTerms) {
        throw Exception("Invalid search terms");
    }
}

###############################################################################

my @logFiles = getLogFiles();

if ($opts{startDate}) {
    my $l = length $opts{startDate};
    $opts{startDate} .= "0" x (8 - $l);
} else {
    my @date = localtime;
    $opts{startDate} = sprintf "%4u%02u%02u", $date[5]+1900, ++$date[4], $date[3];
    $opts{startDate} -= 10000; # subtract one year
}

my $results = 0;
foreach (@logFiles) {
    processLogfile($_);
    last if $results == $opts{head};
}

logRotate();

###############################################################################

sub processLogfile {
    my ($logfile) = @_;

    my (undef, undef, $file) = splitpath($logfile);
    if (! $opts{all} && $opts{startDate}) {
        my ($date) = $file =~ /(\d{8})/;
        if ($date && $date < $opts{startDate}) {
            return;
        }
    }

    if ($opts{list}) {
        print "$logfile\n";
        return;
    }

    if (! -e $logfile) {
        throw Exception("Log file does not exist: $logfile");
        return;
    }
    if (! -r $logfile) {
        throw Exception("Log file is not readable: $logfile");
        return;
    }

    print "$logfile\n";

    RJK::TotalCmd::Log->traverse(
        file => $logfile,
        visitEntry => sub {
            if (match($_)) {
                displayResult($_);
                return ++$results != $opts{head};
            }
            return 1;
        },
        visitFailed => sub {
            warn "Corrupt line: $_[0]";
            return 1;
        },
    );
}

sub displayResult {
    my $entry = shift;
    print "$entry->{operation} $entry->{source}\n";
    if ($entry->{destination}) {
        print "  -> $entry->{destination}\n";
    }
}

sub match {
    my $entry = shift;

    # skip fs plugin operations
    return if $entry->{isFsPluginOp} && !$opts{showPluginOp};

    # filter on operation
    return if $opts{operation} &&
        $entry->{operation} !~ /^$opts{operation}/i;

    my $searchStr = $entry->{source};
    if ($opts{searchDestination}) {
        if ($opts{searchSource}) {
            $searchStr .= $entry->{destination} // "";
        } else {
            $searchStr = $entry->{destination} // "";
        }
    } else {
        $searchStr .= $entry->{destination} // "";
    }

    foreach (@searchTerms) {
        if ($opts{regex}) {
            return 0 if $searchStr !~ /$_/i;
        } elsif ($searchStr !~ /\Q$_\E/i) {
            return 0;
        }
    }
    return 1;
}

sub GetTerms {
    my @searchTerms;
    # filter out crap
    foreach (@_) {
        s/\W/ /g;
        s/ +/ /g;
        push @searchTerms, $_ if $_;
    }
    return wantarray ? @searchTerms : \@searchTerms;
}

sub logRotate {
    my $logSize = (-s $opts{logFile}) || 0;
    return if ! $opts{archiveSize} || $logSize < $opts{archiveSize} * 1024**2;

    if (! -e $opts{archiveDir}) {
        mkdir $opts{archiveDir} or throw Exception("$!: $opts{archiveDir}");
    }
    throw Exception("$!: $opts{archiveDir}") if ! -r $opts{archiveDir};

    my (undef, undef, $file) = splitpath($opts{logFile});
    my @d = localtime;
    my $d = sprintf "%04d%02d%02d", $d[5]+1900, $d[4]+1, $d[3];
    $file =~ s/\.log$/-$d.log/;
    $file = "$opts{archiveDir}\\$file";

    throw Exception("File exists: $file") if -e $file;

    File::Copy::move($opts{logFile}, $file) or throw Exception("$!: $file");
    if (open my $fh, '>', $opts{logFile}) {
        close $fh;
    } else {
        warn "$!: $opts{logFile}";
    }
}

sub getLogFiles {
    my @logFiles;
    if ($opts{logFile}) {
        if (! -e $opts{logFile}) {
            warn "Log file does not exist: $opts{logFile}";
        } else {
            @logFiles = $opts{logFile}
        }
    }

    opendir my $dh, $opts{archiveDir} or throw Exception("$!: $opts{archiveDir}");
    foreach (grep { /\.log$/ } readdir $dh) {
        push @logFiles, "$opts{archiveDir}\\$_";
    }
    closedir $dh;

    return @logFiles;
}
