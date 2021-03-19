use strict;
use warnings;

###############################################################################
=head1 DESCRIPTION

Copy file modification time.

=head1 SYNOPSIS

copymtime.pl [source path] [target path]

=cut
###############################################################################

use Pod::Usage ();

@ARGV == 2 || Pod::Usage::pod2usage(
    -verbose => 99,
    -sections => "DESCRIPTION|SYNOPSIS"
);

my ($source, $target) = @ARGV;
my $atime = time;
my @stat = stat $source or die "$!";
my $mtime = $stat[9];
utime $atime, $mtime, $target or die "$!";
