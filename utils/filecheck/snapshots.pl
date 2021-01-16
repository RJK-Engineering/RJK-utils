use strict;
use warnings;

use RJK::Filecheck::Snapshots;

my %opts = (
    verbose => 1,
    imageHeight => 360,
);

$opts{path} = shift || die "No path specified";
$opts{position} = shift // 30;

RJK::Filecheck::Snapshots->create(\%opts);
