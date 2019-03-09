use strict;
use warnings;

use Options::Pod;
use Pod::Usage qw(pod2usage);

use Filecheck::Utils qw(DisconnectDrive);

###############################################################################
=head1 DESCRIPTION

Change drive letter.

=head1 SYNOPSIS

chletter.pl [options] [current] [new]

=head1 DISPLAY EXTENDED HELP

chletter.pl -h

=head1 OPTIONS

=for options start

=over 4

=item B<-t -temp-file [path]>

Path to temp file.

=item B<-d -disconnect-network-drive>

Disconnect network drive if one is connected with drive letter [new].

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

my %opts = (
    tempFile => 'chdl.txt',
);
Options::Pod::Configure("comments_included");
Options::Pod::GetOptions(
    't|temp-file=s' => \$opts{tempFile}, "{Path} to temp file.",
    'd|disconnect-network-drive' => \$opts{disconnectNetworkDrive},
        "Disconnect network drive if one is connected with drive letter [new].",

    #~ ['Messages'],
    #~ 'v|verbose' => \$opts{verbose}, "Be verbose.",
    #~ 'q|quiet' => \$opts{quiet}, "Be quiet.",
    #~ 'debug' => \$opts{debug}, "Display debug information.",

    ['Pod'],
    Options::Pod::Options,

    ['Help'],
    'h|help|?' => sub {
        pod2usage(
            -exitstatus => 0,
            -verbose => 99,
            -sections => "DESCRIPTION|SYNOPSIS|OPTIONS",
        );
    }, "Display extended help.",
)
&& Options::Pod::HandleOptions()
|| pod2usage(
    -verbose => 99,
    -sections => "DISPLAY EXTENDED HELP",
);

@ARGV == 2 || pod2usage(
    -verbose => 99,
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

# quiet!
$opts{verbose} = 0 if $opts{quiet};

###############################################################################

my ($curr, $new) = map {uc} @ARGV;
$curr =~ /^\w$/ || die "Invalid drive letter: $curr";
$new =~ /^\w$/ || die "Invalid drive letter: $new";

if (-e "$new:\\") {
    if ($opts{disconnectNetworkDrive}) {
        print "Disconnecting drive $new\n";
        DisconnectDrive($new)
            or die "Error disconnecting drive $new";
        print "Drive $new disconnected\n";
        sleep 2;
    } else {
        die "Drive $new already mounted";
    }
}

open my $fh, '>', $opts{tempFile}
    or die "Error creating temp file $opts{tempFile}: $!";
print $fh "select volume=$curr\n";
print $fh "assign letter=$new\n";
close $fh;

system "diskpart", "/s", $opts{tempFile}
    and die "Error executing diskpart";
unlink $opts{tempFile}
    or die "Error deleting temp file $opts{tempFile}: $!";
