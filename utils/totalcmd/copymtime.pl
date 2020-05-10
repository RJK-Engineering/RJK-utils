use strict;
use warnings;

use RJK::Options::Pod;

###############################################################################
=head1 DESCRIPTION

Copy file modification time.

=head1 SYNOPSIS

copymtime.pl [source path] [target path]

=head1 DISPLAY EXTENDED HELP

copymtime.pl -h

=head1 OPTIONS

=for options start

=over 4

=back

=head2 Pod

=over 4

=item B<-podcheck>

Run podchecker.

=item B<-pod2html -html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<-genpod>

Generate POD for options.

=item B<-savepod>

Save generated POD to script file.
The POD text will be inserted between C<=for options start> and
C<=for options end> tags.
If no C<=for options end> tag is present, the POD text will be
inserted after the C<=for options start> tag and a
C<=for options end> tag will be added.
A backup is created.

=back

=head2 Help

=over 4

=item B<-h -help -?>

Display extended help.

=back

=for options end

=cut
###############################################################################

RJK::Options::Pod::GetOptions(
    ['Pod'],
    RJK::Options::Pod::Options,

    ['Help'],
    RJK::Options::Pod::HelpOptions
);

@ARGV == 2 || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

###############################################################################

my ($source, $target) = @ARGV;
my $atime = time;
my @stat = stat $source or die "$!";
my $mtime = $stat[9];
utime $atime, $mtime, $target or die "$!";
