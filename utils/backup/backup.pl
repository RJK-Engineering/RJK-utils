###############################################################################
=pod

backup.pl [options] [volume] [directory]

=cut
###############################################################################

use strict;
use warnings;

use File::Basename;
use lib dirname (__FILE__);

use RJK::LocalConf;
use RJK::Options::Pod;

my %opts = RJK::LocalConf::GetOptions("RJK-utils/backup/backup.properties");
@ARGV || RJK::Options::Pod::ShortHelp;

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    "volumes" => \$opts{procVolumes}, "",
    "a|all-backup-dirs" => \$opts{allBackupDirs}, "",
    "b|backup-ok|ok=s" => \$opts{backupOk}, "Mark backup to {volume} as completed.",
    "location=s" => \$opts{location}, "",
    "s|calculate-usage" => \$opts{calculateUsage}, "Traverse directories and calculate size.",

    "c|create" => \$opts{create}, "",
    "u|update" => \$opts{update}, "",

    ['POD'],
    RJK::Options::Pod::Options,
    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

$opts{volume} = shift;
$opts{dir} = shift;

###############################################################################

use Backup;
use Try::Tiny;
use RJK::Exceptions;

try {
    Backup->execute(\%opts);
} catch {
    if ($opts{verbose}) {
        RJK::Exceptions->handleVerbose;
    } else {
        RJK::Exceptions->handle;
    }
    exit 1;
};
