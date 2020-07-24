use strict;
use warnings;

use Exception::Class;
use File::Copy ();
use File::Spec::Functions qw(splitpath);

use RJK::HashToStringFormatter;
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

=item B<-a -all>

Search all available archives.

=item B<-S -search-source>

Only search sources (search sources and destinations by default).

=item B<-D -search-destination>

Only search destinations (search sources and destinations by default).

=item B<-l -list>

List log files.

=item B<-m -archive-size [n]>

Move log to archive when exceeding [n] mb.

=item B<-f -search-files>

TODO

=item B<-g -search-directories>

TODO

=item B<-d -start-date [date]>

Search start date. YYYYMMDD formatted number, does numeric comparison, zero padded on right-hand-side, e.g. for "201": 20100000 < 20100101

=item B<-e -regex>

Use regular expression.

=item B<-o -operation [string]>

Filter by operation matching start of operation name, i.e. 'm' for 'Move'.

=item B<-p -plugin-op>

TODO

=item B<-log-file [string]>

Path to Total Commander log file.

=item B<-archive-dir [string]>

TODO

=back

=head1 Formatting

=over 4

=item B<-f -fields [names]>

Comma separated list of fields to show. Shows available fields if no [names] are specified.

=item B<-s -format [format]>

Use formatting. Shows formatting help if no [format] is specified.

=item B<-h -head [n]>

Show first [n] results.

=item B<-t -tail [n]>

Show last [n] results.

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

my %opts = RJK::LocalConf::GetOptions("totalcmd/log.properties", (
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

    ['FORMATTING'],
    'f|fields:s' => \$opts{fields},
        "Comma separated list of fields to show. Shows available fields if no [{names}] are specified.",
    's|format:s' => \$opts{format},
        "Use formatting. Shows formatting help if no [{format}] is specified.",

    'h|head:i' => \$opts{head},
        "Show first [{n}] results.",
    't|tail:i' => \$opts{tail},
        "Show last [{n}] results.",

    ['POD'],
    RJK::Options::Pod::Options,
    ['HELP'],
    RJK::Options::Pod::HelpOptions(undef, 'help')
);

$opts{head} ||= defined $opts{head} ? 10 : 0;
$opts{tail} ||= defined $opts{tail} ? 10 : 0;

@ARGV ||
defined $opts{fields} ||
$opts{list} ||
$opts{head} ||
$opts{tail} || RJK::Options::Pod::pod2usage(
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

my @fields = split /,/, $opts{fields} if $opts{fields};

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

my @results;
foreach (@logFiles) {
    last if processLogfile($_, \@results);
}

if ($opts{tail}) {
    my $first = @results - $opts{tail};
    if ($first >= 0) {
        @results = @results[$first .. @results-1];
    }
}

displayResults(\@results);
logRotate();

###############################################################################

sub processLogfile {
    my ($logfile, $results) = @_;

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
                push @$results, $_;
                return 1 if @$results == $opts{head};
            }
        },
        visitFailed => sub {
            warn "Corrupt line: $_[0]";
            return 0;
        },
    );
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
            if ($searchStr !~ /$_/i) {
                return 0;
            }
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

sub displayResults {
    my $results = shift;
    my $formatter = new RJK::HashToStringFormatter($opts{format});

    if (defined $opts{fields}) {
        if (@fields) {
            foreach my $r (@$results) {
                print $formatter->format($r, @fields), "\n";
            }
        } else {
            print "@RJK::TotalCmd::Log::fields\n";
        }
    } else {
        foreach (@$results) {
            print "$_->{operation} $_->{source}\n";
            if ($_->{destination}) {
                print "  -> $_->{destination}\n";
            }
        }
    }
}

sub logRotate {
    my $logSize = (-s $opts{logFile}) || 0;
    if ($opts{archiveSize} && $logSize > $opts{archiveSize} * 1024**2) {
        if (! -e $opts{archiveDir}) {
            mkdir $opts{archiveDir} or throw Exception("$!: $opts{archiveDir}");
        }
        if (! -r $opts{archiveDir}) {
            throw Exception("$!: $opts{archiveDir}");
        }

        my (undef, undef, $file) = splitpath($opts{logFile});
        my @d = localtime;
        my $d = sprintf "%04d%02d%02d", $d[5]+1900, $d[4]+1, $d[3];
        $file =~ s/\.log$/-$d.log/;
        $file = "$opts{archiveDir}\\$file";

        if (-e $file) {
            throw Exception("File exists: $file");
        } else {
            File::Copy::move($opts{logFile}, $file) or throw Exception("$!: $file");
            if (open my $fh, '>', $opts{logFile}) {
                close $fh;
            } else {
                warn "$!: $opts{logFile}";
            }
        }
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
