use strict;
use warnings;

use RJK::LocalConf;
use RJK::Options::Pod;

###############################################################################
=head1 DESCRIPTION

Create and search directory collections.

=head1 SYNOPSIS

dirs.pl [options] [arguments]

=head1 DISPLAY EXTENDED HELP

dirs.pl -h

=for options start

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("RJK-utils/filecheck/dirs.properties", (
    newdirName => "[[[[new]]]]",
    tempDir => '%TEMP%',
));

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    #~ 'L|list-file=s' => \$opts{listFile}, "Path to totalcmd list file containing files to resolve dirs for.",
    #~ 'map=s@' => \$opts{map}, "Map volume label to drive name.",
    'l|list=s' => \$opts{list}, "List name.",
    'm|multiple-names' => \$opts{listMultipleNames}, "List dirs with multiple names.",
    'd|dupes' => \$opts{listDupes}, "Find duplicates.",
    'v|volume=s' => \$opts{volume}, "Volume filter.",
    'D|download-list-dir=s' => \$opts{downloadListDir}, "Path to directory containing totalcmd download list files.",
        'dl|download-lists' => \$opts{showDownloadLists}, "Show download lists.",
        'O|open-download-list=s' => \$opts{openDownloadList}, "Open download list.",

    'f|filename-search' => \$opts{filenameSearch}, "Find directories for a file by matching words in its name.",
    'g|get-dirs' => \$opts{getDirs}, "Get dirs.",

    'c|set-clipboard' => \$opts{setClipboard}, "Set clipboard.",
    'a|add-to-download-list' => \$opts{addToDownloadList}, "Add to download list.",
        'o|download-list-operation=s' => \$opts{downloadListOperation}, "Operation added to download list, \"copy\" or \"move\". Default: \"move\".",

    'O|tc-open' => \$opts{tcOpen}, "Open in Total Commander. Default in source window.",
    'a|tc-open-all' => \$opts{tcOpenAll}, "Open all dirs in new tabs in Total Commander. Default in source window.",
    't|tc-open-new-tab' => \$opts{tcOpenNewTab}, "Total Commander command line option /T. Opens the passed dir(s) in new tab(s). Now also works when Total Commander hasn't been open yet. Default in source window.",
    'N|tc-open-new-instance' => \$opts{tcOpenNewInstance}, "Total Commander command line option /N. Opens in any case a new Total Commander window (overrides the settings in the configuration dialog to allow only one copy of Total Commander at a time). Default in source window.",
    'L|tc-set-left-path' => \$opts{tcSetLeftPath}, "Total Commander command line option /L=. Set path in left window. Default in running instance.",
    'R|tc-set-right-path' => \$opts{tcSetRightPath}, "Total Commander command line option /R=. Set path in right window. Default in running instance.",
    'S|tc-set-source-path' => \$opts{tcSetSourcePath}, "Total Commander command line options  /S /L=. Set path in source window. Default in running instance.",
    'T|tc-set-target-path' => \$opts{tcSetTargetPath}, "Total Commander command line options  /S /R=. Set path in target window. Default in running instance.",

    ['POD'],
    RJK::Options::Pod::Options,
    ['Help'],
    RJK::Options::Pod::HelpOptions
);

$opts{downloadListDir} or die "Missing property: download.list.dir";

if ($opts{showDownloadLists}) {
    exit system "dir *.dl", $opts{downloadListDir};
} elsif (defined $opts{openDownloadList}) {
    exit system "$opts{downloadListDir}\\$opts{openDownloadList}.dl";
}

$opts{args} = [@ARGV];
$opts{outputFile} = shift;

$opts{tcOpen} ||=
    $opts{tcOpenNewInstance} ||
    $opts{tcOpenAll} ||
    $opts{tcOpenNewTab} ||
    $opts{tcSetLeftPath} ||
    $opts{tcSetRightPath} ||
    $opts{tcSetSourcePath} ||
    $opts{tcSetTargetPath}
;
$opts{tcSetSourcePath} ||= !(
    $opts{tcSetLeftPath} ||
    $opts{tcSetRightPath} ||
    $opts{tcSetTargetPath}
);

###############################################################################

use File::Basename;
use lib dirname (__FILE__);
use Dirs;

use RJK::Exceptions;
use Try::Tiny;

try {
    Dirs->execute(\%opts);
} catch {
    if ($opts{verbose}) {
        RJK::Exceptions->handleVerbose;
    } else {
        RJK::Exceptions->handle;
    }
    exit 1;
};
