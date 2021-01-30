use strict;
use warnings;

use RJK::Env;
use URI::Encode;

my $file = RJK::Env->subst('%LOCALAPPDATA%/eMule/config/downloads.txt');

open my $fh, '<', $file or die "$!: $file";
while (<$fh>) {
    my @row = split /\|/;
    next if @row <3 ;
    print URI::Encode::uri_decode($row[2] =~ s/.(.)/$1/gr), "\n";
}
close $fh;
