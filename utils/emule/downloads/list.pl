use strict;
use warnings;

use RJK::Env;
use URI::Encode;

my $file = RJK::Env->subst('%LOCALAPPDATA%/eMule/config/downloads.txt');

open my $fh, '<', $file or die "$!: $file";
while (<$fh>) {
    my @row = split /\|/;
    next if @row <3 ;
    my $partmet = $row[0] =~ s/.(.)/$1/gr =~ s/\s.*//r;
    my $filename = URI::Encode::uri_decode($row[2] =~ s/.(.)/$1/gr);
    print "$partmet $filename\n";
}
close $fh;
