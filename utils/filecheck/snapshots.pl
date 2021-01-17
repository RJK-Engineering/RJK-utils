use strict;
use warnings;

use RJK::Filecheck::Snapshots;
use RJK::TotalCmd::Utils;

my %opts = (
    verbose => 1,
    imageHeight => 360,
);

$opts{path} = shift || die "No path specified";
$opts{position} = shift // 30;
$opts{listFile} = $opts{path} if RJK::TotalCmd::Utils->isListFile($opts{path});

RJK::Filecheck::Snapshots->create(\%opts);
