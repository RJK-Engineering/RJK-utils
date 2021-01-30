use strict;
use warnings;

use RJK::LocalConf;
use RJK::Options::Pod;

###############################################################################
=head1 DESCRIPTION

Match files.

=head1 SYNOPSIS

match.pl [options] [file] [candidates]
[file]       - File to find matches for.
[candidates] - List of files to match against, directories are visited recursively.

=head1 DISPLAY EXTENDED HELP

match.pl -h

=for options start

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("RJK-utils/filecheck/match.properties");

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'i|stdin' => \$opts{stdin}, "Read paths from standard input.",
    'n=i' => \$opts{numberOfResults}, "Stop after C<n> results.",

    ['POD'],
    RJK::Options::Pod::Options,
    ['MESSAGE'],
    RJK::Options::Pod::MessageOptions,
    ['Help'],
    RJK::Options::Pod::HelpOptions
);

$opts{file} = shift;
$opts{args} = 1 if @ARGV;

use Match;
Match->execute(\%opts);
