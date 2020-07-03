use strict;
use warnings;

use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::Win32::DriveUtils qw(DisconnectDrive);

###############################################################################
=head1 DESCRIPTION

Change drive letter.

=head1 SYNOPSIS

chletter.pl [options] [current] [new]

=head1 DISPLAY EXTENDED HELP

chletter.pl -h

=for options start

=head1 OPTIONS

=over 4

=item B<-t -temp-file [path]>

Path to temp file.

=item B<-d -disconnect-network-drive>

Disconnect network drive if one is connected with drive letter [new].

=back

=head1 POD

=over 4

=item B<-podcheck>

Run podchecker.

=item B<-pod2html -html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<-genpod>

Generate POD for options.

=item B<-writepod>

Write generated POD to script file.
The POD text will be inserted between C<=for options start> and
C<=for options end> tags.
If no C<=for options end> tag is present, the POD text will be
inserted after the C<=for options start> tag and a
C<=for options end> tag will be added.
A backup is created.

=back

=head1 HELP

=over 4

=item B<-h -help -?>

Display program options.

=item B<-hh "-help -help" -??>

Display help options.

=item B<-hhh "-help -help -help" -???>

Display POD options.

=item B<-hhhh "-help -help -help -help" -????>

Display complete help.

=back

=for options end

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("system/chletter.properties", (
    tempFile => 'chdl.txt',
));

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    't|temp-file=s' => \$opts{tempFile}, "{Path} to temp file.",
    'd|disconnect-network-drive' => \$opts{disconnectNetworkDrive},
        "Disconnect network drive if one is connected with drive letter [new].",

    ['POD'],
    RJK::Options::Pod::Options,
    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

@ARGV == 2 || RJK::Options::Pod::pod2usage(
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
