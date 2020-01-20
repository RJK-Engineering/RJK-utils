use strict;
use warnings;

use File::Copy qw(move);
use File::Spec::Functions qw(splitpath);

use Options::Pod;

use RJK::HashToStringFormatter;
use RJK::LocalConf;
use TotalCmd::Log;

###############################################################################
=head1 DESCRIPTION

Manage and search Total Commander log files.

=head1 SYNOPSIS

log.pl [options] [search terms]

=head1 DISPLAY EXTENDED HELP

log.pl -h

=head1 OPTIONS

=for options start

=item B<-a -archives>

Search archives.

=item B<-s -search-source>

Only search sources (search sources and destinations by default).

=item B<-d -search-destination>

Only search destinations (search sources and destinations by default).

=item B<-l -list>

List log files.

=item B<-m -archive-size [n]>

Move log to archive when exceeding [n] mb.

=item B<-F -search-files>

TODO

=item B<-D -search-directories>

TODO

=item B<-b -begin [date]>

Search start date. YYYYMMDD formatted number, does numeric comparison, zero padded on right-hand-side, e.g. for "201": 20100000 < 20100101

=item B<-e -regex>

Use regular expression.

=item B<-o -operation [string]>

Filter by operation matching start of operation name, i.e. 'm' for 'Move'.

=item B<-p -plugin-op>

TODO

=item B<-logfile [string]>

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

Display extended help.

=back

=for options end

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions(
    "totalcmd-log.conf", (
        showPluginOp => 1,
        #~ string => "default",
    )
);

Options::Pod::GetOptions(
    ['OPTIONS'],
    'a|archives' => \$opts{searchArchives},
        "Search archives.",
    's|search-source' => \$opts{searchSource},
        "Only search sources (search sources and destinations by default).",
    'd|search-destination' => \$opts{searchDestination},
        "Only search destinations (search sources and destinations by default).",
    'l|list' => \$opts{list},
        "List log files.",
    'm|archive-size=i' => \$opts{archiveSize},
        "Move log to archive when exceeding [{n}] mb.",
    'F|search-files' => \$opts{searchFiles},
        "TODO",
    'D|search-directories' => \$opts{searchDirectories},
        "TODO",
    'b|begin=s' => \$opts{begin},
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

    ['Formatting'],
    'f|fields:s' => \$opts{fields},
        "Comma separated list of fields to show. Shows available fields if no [{names}] are specified.",
    's|format:s' => \$opts{format},
        "Use formatting. Shows formatting help if no [{format}] is specified.",

    'h|head:i' => \$opts{head},
        "Show first [{n}] results.",
    't|tail:i' => \$opts{tail},
        "Show last [{n}] results.",

    ['POD'],
    Options::Pod::Options,
    ['HELP'],
    Options::Pod::HelpOptions
);

# default values
$opts{head} ||= defined $opts{head} ? 10 : 0;
$opts{tail} ||= defined $opts{tail} ? 10 : 0;

# arguments required
@ARGV ||
defined $opts{fields} ||
$opts{list} ||
$opts{archiveSize} ||
$opts{head} ||
$opts{tail} || Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

###############################################################################

my @searchTerms;
if (@ARGV) {
    @searchTerms = GetTerms(@ARGV);
    die "Invalid search terms" unless @searchTerms;
}

my @fields = split /,/, $opts{fields} if $opts{fields};

###############################################################################

my @results;
my $i;

my $logSize = (-s $opts{logFile}) || 0;
if ($opts{archiveSize} && $logSize > $opts{archiveSize} * 1024**2) {
    if (! -e $opts{archiveDir}) {
        mkdir $opts{archiveDir} or die "$!: $opts{archiveDir}";
    }
    if (! -r $opts{archiveDir}) {
        die "$!: $opts{archiveDir}";
    }

    my (undef, undef, $file) = splitpath($opts{logFile});
    my @d = localtime;
    my $d = sprintf "%04d%02d%02d", $d[5]+1900, $d[4]+1, $d[3];
    $file =~ s/\.log$/-$d.log/;
    $file = "$opts{archiveDir}\\$file";

    if (-e $file) {
        warn "File exists: $file";
    } else {
        move $opts{logFile}, $file or die "$!: $file";
    }
}

my @logfiles = $opts{logFile};
if ($opts{searchArchives}) {
    opendir my $dh, $opts{archiveDir} or die "$!: $opts{archiveDir}";
    foreach (grep { /\.log$/ } readdir $dh) {
        push @logfiles, "$opts{archiveDir}\\$_";
    }
    closedir $dh;
}

if ($opts{begin}) {
    my $l = length $opts{begin};
    $opts{begin} .= "0" x (8 - $l);
}

foreach my $logfile (@logfiles) {
    my (undef, undef, $file) = splitpath($logfile);
    if ($opts{begin}) {
        my ($date) = $file =~ /(\d{8})/;
        if ($date && $date < $opts{begin}) {
            next;
        }
    }

    if ($opts{list}) {
        print "$logfile\n";
        next;
    }
    if ($opts{searchArchives}) {
        print "$logfile\n";
    }
    if (! -e $logfile) {
        warn "Log file does not exist: $logfile";
        next;
    }
    if (! -r $logfile) {
        warn "Log file is not readable: $logfile";
        next;
    }

    TotalCmd::Log->traverse(
        $logfile,
        sub {
            if (match($_)) {
                push @results, $_;
                return 1 if ++$i == $opts{head};
            }
        },
        sub {
            warn "Corrupt line: $_[0]";
            return 0;
        },
    );
}

if ($opts{tail}) {
    my $first = @results - $opts{tail};
    if ($first >= 0) {
        @results = @results[$first .. @results-1];
    }
}

my $formatter = new RJK::HashToStringFormatter($opts{format});

if (defined $opts{fields}) {
    if (@fields) {
        foreach my $r (@results) {
            print $formatter->format($r, @fields), "\n";
        }
    } else {
        print "@TotalCmd::Log::fields\n";
    }
} else {
    foreach (@results) {
        print "$_->{operation} $_->{source}\n";
        if ($_->{destination}) {
            print "  -> $_->{destination}\n";
        }
    }
}

sub match {
    my $entry = shift;

    # no fs plugin operations
    return if !$opts{showPluginOp} &&
        $entry->{fsPluginOp};

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
