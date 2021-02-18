use strict;
use warnings;

use RJK::LocalConf;

my %opts = RJK::LocalConf::GetOptions("RJK-utils/filecheck/index.json");

$opts{listFile} = shift;

use File::Basename;
use lib dirname (__FILE__);
use Index;

use RJK::Exceptions;
use Try::Tiny;

try {
    Index->execute(\%opts);
} catch {
    if ($opts{verbose}) {
        RJK::Exceptions->handleVerbose;
    } else {
        RJK::Exceptions->handle;
    }
    exit 1;
};
