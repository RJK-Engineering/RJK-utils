use strict;
use warnings;

use File::Basename;
use lib dirname (__FILE__);

use RJK::LocalConf;
use RJK::Options::Pod;

###############################################################################
=head1 DESCRIPTION

Synchronize directories.

=head1 SYNOPSIS

sync.pl [options] [target directory]

=head1 DISPLAY EXTENDED HELP

sync.pl -h

=for options start

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("RJK-utils/fs/sync.properties", (
    refreshInterval => .2,
    minDirNameLength => 5,
));
RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'i|refresh-interval=f' => \$opts{refreshInterval},
        "Refresh interval in {seconds}. Real number, default: $opts{refreshInterval}",
    'simulate' => \$opts{simulate}, "Do not make any changes to the file system.",
    'dirs' => \$opts{visitDirs}, "Synchronize dirs.",
    'min-dir-name-length' => \$opts{minDirNameLength}, "Minimum required dir name length when matching dirs. Default: $opts{minDirNameLength}",

    ['POD'],
    RJK::Options::Pod::Options,

    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

@ARGV || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

$opts{targetDir} = shift =~ s|\/|\\|gr =~ s|\\+$||r;

###############################################################################

use Sync;
use Try::Tiny;
use RJK::Exceptions;

try {
    Sync->execute(\%opts);
} catch {
    RJK::Exceptions->handle();
    exit 1;
};
