use strict;
use warnings;

use RJK::Time;
use RJK::TimeFormatter;
use RJK::TimeParser;

my ($t1, $t2) = @ARGV;
$t1 = RJK::TimeParser->parse($t1);
$t2 = RJK::TimeParser->parse($t2);

if ($t1->seconds < $t2->seconds) {
    printf "%s", RJK::TimeFormatter->format($t2->minus($t1));
} else {
    printf "%s", RJK::TimeFormatter->format($t1->minus($t2));
}
