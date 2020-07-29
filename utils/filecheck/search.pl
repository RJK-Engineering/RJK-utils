use strict;
use warnings;

use Try::Tiny;

use RJK::Exception;
use RJK::IO::File;
use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::TotalCmd::DiskDirFiles;
use RJK::TotalCmd::Settings::Ini;

use File::Basename;
use lib dirname (__FILE__);
use DdfVisitor;

###############################################################################
=head1 DESCRIPTION

Search for files and directories.

=head1 SYNOPSIS

fcs.pl [options] [search terms]

=head1 DISPLAY EXTENDED HELP

fcs.pl -h

=for options start

=head1 OPTIONS

=over 4

=item B<-n --name [name]>

Total Commander stored search name.

=item B<--in [string]>

Directories separated by C<;>. TODO: default is cwd

=item B<-e --regex>

Search For: Regex.

=item B<--selected>

Only search in selected.

=item B<--archives>

Search archives.

=item B<--depth [integer]>

Search depth.

=item B<-0>

Search depth 0.

=item B<-1>

Search depth 1.

=item B<-2>

Search depth 2.

=item B<-3>

Search depth 3.

=item B<-4>

Search depth 4.

=item B<-5>

Search depth 5.

=item B<-6>

Search depth 6.

=item B<-7>

Search depth 7.

=item B<-8>

Search depth 8.

=item B<-9>

Search depth 9.

=back

=head1 Text

=over 4

=item B<--text [string]>

Text to search for in files.

=item B<--text-word>

Find Text: Whole words only.

=item B<--text-case>

Find Text: Case sensitive.

=item B<--text-ascii>

Find Text: Ascii charset.

=item B<--text-not>

Find Text: NOT containing text.

=item B<--text-unicode>

Find Text: Unicode.

=item B<--text-hex>

Find Text: Hex.

=item B<--text-regex>

Find Text: Regex.

=item B<--text-utf8>

Find Text: UTF8-Search.

=back

=head1 Date

=over 4

=item B<--start [string]>

Date between: Start.

=item B<--end [string]>

Date between: End.

=item B<--time [integer]>

Not older then.

=item B<--time-unit [integer]>

Not older then: Unit. Format: -2=s, -1=m, 0=h, 1=d, 2=w, 3=m, 4=y

=back

=head1 Size

=over 4

=item B<--size-mode [integer]>

File size: Mode. Values: 0=equal, 1=>, 2=<

=item B<--size [integer]>

File size.

=item B<--size-unit [integer]>

File size: Unit. Values: 0=b, 1=kb, 2=mb, 3=gb

=item B<--ms --minsize [string]>

Minumum file size. Format: [number][unit].
[unit] may be b, kb, mb, gb or tb, in which the b may be omitted.

=item B<--xs --maxsize [string]>

Maximum file size. See C<-minsize> for format.

=back

=head1 Attributes

=over 4

=item B<+A -A +archive -archive>

Archive attribute set(+)/cleared(-).

=item B<+R -R +readonly -readonly>

Read-only attribute set(+)/cleared(-).

=item B<+H -H +hidden -hidden>

Hidden attribute set(+)/cleared(-).

=item B<+S -S +system -system>

System attribute set(+)/cleared(-).

=item B<+C -C +compressed -compressed>

Compressed(+)/uncompressed(-).

=item B<+E -E +encrypted -encrypted>

Encrypted(+)/unencrypted(-).

=item B<+D -D +directory -directory>

Directory(+)/not a directory(-).

=item B<-d --dirs>

Search for directories (same as +D)

=item B<-f --files>

Search for files (same as -D)

=back

=head1 Duplicates

=over 4

=item B<--dn --dupe-name>

Find duplicate files: Same content.

=item B<--ds --dupe-size>

Find duplicate files: Same name.

=item B<--dc --dupe-content>

Find duplicate files: Same size.

=back

=head1 Plugin

=over 4

=item B<--plugin [string]>

Plugin arguments.

=back

=head1 Other

=over 4

=item B<--lst-dir [string]>

Path to list directory.

=item B<--status-file [string]>

Path to status file.

=item B<--delimiters [string]>

A string of field delimiter characters.

=item B<--tcmdini [string]>

Path to Total Commander INI file.

=item B<-l --list>

Show list of saved searches.

=item B<-a --all>

Search all partitions. If no C<-a> or C<-p> is specified,
searches partitions previously specified with C<-p>.

=item B<-p --partitions [string]>

Comma separated list of names of partitions to search.
If no C<-p> or C<-a> is specified, searches partitions
previously specified with C<-p>.

=item B<-x --exact>

Do not clean up search terms.

=item B<--names>

Display filenames only.

=item B<--paths>

Display full paths.

=item B<--gpaths>

Display paths with drive letters replaced by drive labels (default).

=item B<--format [string]>

Printf style display format.

=item B<--dir-format [string]>

Printf style display format for directories.

=item B<--captured>

Display captured substrings when using a regular expression.

=item B<--summary>

Do not display results.

=item B<-c --set-clipboard>

Copy results to clipboard.

=item B<-v --verbose>

Be verbose.

=item B<-q --quiet>

Be quiet.

=item B<--debug>

Display debug information.

=back

=head1 Pod

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

=head1 Help

=over 4

=item B<-h --help -?>

Display extended help.

=item B<--help-all>

Display all help.

=back

=for options end

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("filecheck.properties", (
    #~ recursive => 1,
    delimiters => ",;:.'\\|/[]",
));

my $flags = $opts{flags} = {};

my @searchOpts = (
    ['OPTIONS'],
    'n|name:s' => \$opts{storedSearchName},
        "Total Commander stored search {name}.",
    'in=s' => \$opts{searchIn},
        "Directories separated by C<;>. TODO: default is cwd",

    'e|regex' => \$flags->{regex}, "Search For: Regex.",
    'selected' => \$flags->{selected}, "Only search in selected.",
    'archives' => \$flags->{archives}, "Search archives.",
    'depth=i' => \$flags->{depth}, "Search depth.",
    #~ 'mindepth=i' => \$opts{mindepth}, "TODO Minimum search depth.",
    (map { $_ => \$opts{$_}, "Search depth $_." } 0..9),

    ['Text'],
    'text=s' => \$opts{searchText}, "Text to search for in files.",
    'text-word' => \$flags->{textWord}, "Find Text: Whole words only.",
    'text-case' => \$flags->{textCase}, "Find Text: Case sensitive.",
    'text-ascii' => \$flags->{textAscii}, "Find Text: Ascii charset.",
    'text-not' => \$flags->{textNot}, "Find Text: NOT containing text.",
    'text-unicode' => \$flags->{textUnicode}, "Find Text: Unicode.",
    'text-hex' => \$flags->{textHex}, "Find Text: Hex.",
    'text-regex' => \$flags->{textRegex}, "Find Text: Regex.",
    'text-utf8' => \$flags->{textUtf8}, "Find Text: UTF8-Search.",

    ['Date'],
    'start=s' => \$flags->{start}, "Date between: Start.",
    'end=s' => \$flags->{end}, "Date between: End.",
    'time=i' => \$flags->{time}, "Not older then.",
    'time-unit=i' => \$flags->{timeUnit},
        "Not older then: Unit. Format: -2=s, -1=m, 0=h, 1=d, 2=w, 3=m, 4=y",

    ['Size'],
    'size-mode=i' => \$flags->{sizeMode},
        "File size: Mode. Values: 0=equal, 1=>, 2=<",
    'size=i' => \$flags->{size}, "File size.",
    'size-unit=i' => \$flags->{sizeUnit},
        "File size: Unit. Values: 0=b, 1=kb, 2=mb, 3=gb",
    'ms|minsize=s' => \$opts{minsize},
        "Minumum file size. Format: [number][unit].\n".
        "[unit] may be b, kb, mb, gb or tb, in which the b may be omitted.",
    'xs|maxsize=s' => \$opts{maxsize},
        "Maximum file size. See C<-minsize> for format.",

    ['Attributes'],
    'A|archive:0' => \$flags->{archive},
        [   "Archive attribute set(+)/cleared(-).", "", "+A -A +archive -archive" ],
    'R|readonly:0' => \$flags->{readonly},
        [ "Read-only attribute set(+)/cleared(-).", "", "+R -R +readonly -readonly" ],
    'H|hidden:0' => \$flags->{hidden},
        [    "Hidden attribute set(+)/cleared(-).", "", "+H -H +hidden -hidden" ],
    'S|system:0' => \$flags->{system},
        [    "System attribute set(+)/cleared(-).", "", "+S -S +system -system" ],
    'C|compressed:0' => \$flags->{compressed},
        [         "Compressed(+)/uncompressed(-).", "", "+C -C +compressed -compressed" ],
    'E|encrypted:0' => \$flags->{encrypted},
        [           "Encrypted(+)/unencrypted(-).", "", "+E -E +encrypted -encrypted" ],
    'D|directory:0' => \$flags->{directory},
        [    "Directory(+)/not a directory(-).", "", "+D -D +directory -directory" ],
    #~ 'F|file:0' => \$opts{file},
    #~     [    "Search for files(+)/directories(-).", "", "+F -F +files -files" ],
    'd|dirs' => \$opts{dirs}, "Search for directories (same as +D)",
    'f|files' => \$opts{files}, "Search for files (same as -D)",

    ['Duplicates'],
    #~ 'dupes' => \$flags->{dupes}, "Find duplicate files.",
    'dn|dupe-name' => \$flags->{dupeName}, "Find duplicate files: Same content.",
    'ds|dupe-size' => \$flags->{dupeSize}, "Find duplicate files: Same name.",
    'dc|dupe-content' => \$flags->{dupeContent}, "Find duplicate files: Same size.",
        #~ 'dupes=s' => \$opts{dupes}, "Find duplicate files. TODO string of flags, eg nsc for same name,size and contents, c implies s (nsc = nc)",

    ['Plugin'],
    'plugin=s' => \$flags->{plugin}, "Plugin arguments.",
);

RJK::Options::Pod::GetOptions(
    @searchOpts,

    ['Other'],
    'lst-dir=s' => \$opts{lstDir}, "Path to list directory.",
    'status-file=s' => \$opts{statusFile}, "Path to status file.",
    'delimiters=s' => \$opts{delimiters}, "A string of field delimiter characters.",
    'tcmdini=s' => \$opts{tcmdini}, "Path to Total Commander INI file.",

    'l|list' => \$opts{list}, "Show list of saved searches.",

    'a|all' => \$opts{all},
        "Search all partitions. If no C<-a> or C<-p> is specified,\n".
        "searches partitions previously specified with C<-p>.",
    'p|partitions=s' => \$opts{partitions},
        "Comma separated list of names of partitions to search.\n".
        "If no C<-p> or C<-a> is specified, searches partitions\n".
        "previously specified with C<-p>.",

    'x|exact' => \$opts{exact}, "Do not clean up search terms.",

    'names' => \$opts{names}, "Display filenames only.",
    'paths' => \$opts{paths}, "Display full paths.",
    'gpaths' => \$opts{gpaths}, "Display paths with drive letters replaced by drive labels (default).",

    'format=s' => \$opts{format}, "Printf style display format.",
    'dir-format=s' => \$opts{dirFormat}, "Printf style display format for directories.",
    'captured' => \$opts{captured}, "Display captured substrings when using a regular expression.",
    'summary' => \$opts{summary}, "Do not display results.",
    'c|set-clipboard' => \$opts{setClipboard}, "Copy results to clipboard.",

    'v|verbose' => \$opts{verbose}, "Be verbose.",
    'q|quiet' => \$opts{quiet}, "Be quiet.",
    'debug' => \$opts{debug}, "Display debug information.",

    ['Pod'],
    RJK::Options::Pod::Options,

    ['Help'],
    RJK::Options::Pod::HelpOptions
);

try {
    go();
} catch {
    if ($opts{verbose}) {
        RJK::Exception->verbosePrintAndExit;
    } else {
        RJK::Exception->printAndExit;
    }
};

sub go {
    if ($opts{list}) {
        return listSearches();
    }

    my $tcSearch = getSearch();
    if ($tcSearch->{name}) {
        use Data::Dump;
        dd $tcSearch;
        exit;
    }

    my $lstDir = new RJK::IO::File($opts{lstDir});
    my @files = $lstDir->filenames(sub { /\.lst$/i });

    my $visitor = new DdfVisitor($tcSearch);
    foreach (@files) {
        RJK::TotalCmd::DiskDirFiles->traverse("$opts{lstDir}\\$_", $visitor);
        last;
    }
}

sub listSearches {
    my $ini = getTotalCmdIni();
    my $searches = $ini->getSearches(sub {shift->{name} =~ /^\./});
    foreach (sort keys %$searches) {
        print "$searches->{$_}{name}\t$searches->{$_}{SearchFor}\n";
    }
}

sub getSearch {
    my $search;
    my $ini = getTotalCmdIni();

    if ($opts{storedSearchName}) {
        $search = $ini->getSearch($opts{storedSearchName})
            or die "Search not found: $opts{storedSearchName}";
    } else {
        $search = $ini->getSearch;
        foreach (@ARGV) {
            $search->addRule(qw(tc name contains), $_);
        }
    }

    updateSearch($search);
    return $search;
}

sub updateSearch {
    my $search = shift;

    if ($opts{binaryTest}) {
        $search->addRule(qw(perl binary = 1));
    } elsif ($opts{searchText} || $opts{textTest}) {
        $search->addRule(qw(perl text = 1));
    }

    $search->{SearchIn} = $opts{searchIn};
    $search->{SearchText} = $opts{searchText};
}

sub getTotalCmdIni {
    my $path = -e $opts{tcmdini} ? $opts{tcmdini} : undef; # path is taken from env var if it's undef
    return new RJK::TotalCmd::Settings::Ini($path)->read;
}
