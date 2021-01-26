use strict;
use warnings;

use RJK::Filecheck::Snapshots;
use RJK::TotalCmd::Utils;

my %opts = (
    verbose => 1,
    imageHeight => 360,
);

$opts{path} = shift;
$opts{position} = shift // 30;
$opts{listFile} = $opts{path} if RJK::TotalCmd::Utils->isListFile($opts{path});
$opts{maxDepth} = 0 if ! $opts{listFile};

RJK::Filecheck::Snapshots->create(\%opts);
