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
        'v|same-volume' => \$opts{dupesSameVolume}, "Find duplicates on same volume.",
    'D|download-list-dir=s' => \$opts{downloadListDir}, "Path to directory containing totalcmd download list files.",
        'dl|download-lists' => \$opts{showDownloadLists}, "Show download lists.",
        'O|open-download-list=s' => \$opts{openDownloadList}, "Open download list.",

    'f|filename-search' => \$opts{filenameSearch}, "Find directories for a file by matching words in its name.",
    'g|get-dirs' => \$opts{getDirs}, "Get dirs.",

    't|set-tc-target-dir' => \$opts{setTcTargetDir}, "Set Total Commander target directory.",
    'c|set-clipboard' => \$opts{setClipboard}, "Set clipboard.",
    'a|add-to-download-list' => \$opts{addToDownloadList}, "Add to download list.",
        'o|download-list-operation=s' => \$opts{downloadListOperation}, "Operation added to download list, \"copy\" or \"move\". Default: \"move\".",
    'exit|exit-value=i' => \$opts{exitValue}, "Program exit value on succesfull program execution.",

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

END {
    $? ||= $opts{exitValue} // 0;
}
