use strict;
use warnings;

use RJK::Time;
use RJK::TimeFormatter;
use RJK::TimeParser;

my $t1 = RJK::TimeParser->parse(shift);
while (@ARGV) {
    my $op = shift;
    my $t2 = RJK::TimeParser->parse(shift);
    if ($op eq '+') {
        $t1 = $t1->plus($t2);
    } elsif ($op eq '-') {
        $t1 = $t1->minus($t2);
    } else {
        die "Invalid operator: $op";
    }
}
printf "%s", RJK::TimeFormatter->format($t1);

#~ my ($t1, $t2) = @ARGV;
#~ $t1 = RJK::TimeParser->parse($t1);
#~ $t2 = RJK::TimeParser->parse($t2);

#~ if ($t1->seconds < $t2->seconds) {
#~     printf "%s", RJK::TimeFormatter->format($t2->minus($t1));
#~ } else {
#~     printf "%s", RJK::TimeFormatter->format($t1->minus($t2));
#~ }
