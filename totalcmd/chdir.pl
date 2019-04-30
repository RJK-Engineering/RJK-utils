use strict;
use warnings;

use Win32::Clipboard;

use Options::Pod;
use RJK::Win32::DriveUtils qw(ConnectDrive GetDriveLetter);
use File::PathUtils qw(ExtractPath);
use Interactive qw(ItemFromList Pause);
Interactive::SetClass('Term::ReadKey'); # Allows reading of single characters
use TotalCmd::Utils qw(tc_SetSourceTargetPaths);

###############################################################################
=head1 DESCRIPTION

Set Total Commander source panel path read from clipboard.

=head1 SYNOPSIS

chdir.pl [options]

=head1 DISPLAY EXTENDED HELP

chdir.pl -h

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

my %opts = ();
Options::Pod::GetOptions(
    ['Pod'],
    Options::Pod::Options,

    ['Help'],
    Options::Pod::HelpOptions,
);

#~ $opts{required} //
#~ @ARGV || Options::Pod::pod2usage(
#~     -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
#~ );

###############################################################################

# get clipboard contents
my $clip = Win32::Clipboard();
my $path = $clip->Get();
# split on vertical whitespace characters, remove empty lines
my @lines = grep { $_ } split /\v+/s, $path
    or Exit("No text on clipboard");

my @paths;
my @urls;
foreach (@lines) {
    if (my $url = (/(http.+)/)[0]) {
        push @urls, $url;
    } elsif (my $path = ExtractPath($_)) {
        push @paths, $path;
    }
}

if (@urls) {
    exit system "dl \"$urls[0]\"";
} elsif (@paths == 1) {
    $path = $paths[0];
} elsif (@paths) {
    $path = ItemFromList(\@paths);
} else {
    Exit("No paths found");
}

#~ $path = CompletePath($path);

#~ isdirpath = /[\\\/]/;
#~ if (!isdirpath)
#~     dir,file = split
#~     if (-d dir)
#~         files = readdir
#~         path = match(files, file)


my %map = split /[=\s]+/, $ENV{CHDIR_DRIVE_MAP} || "";
my $skip;
while (my ($a, $b) = each %map) {
    next if $skip->{$a};
    if ($path =~ s/^$a:\\/$b:\\/i) {
        $skip->{$b} = 1;
    }
}

my $drive = GetDriveLetter($path)
    or Exit("No drive found for path: $path");

if (! -e "$drive:\\") {
    print "Connecting drive $drive\n";
    ConnectDrive($drive) or Exit("Drive unavailable: $drive");
}

tc_SetSourceTargetPaths($path);

sub Exit {
    print shift, "\n";
    Pause;
    exit;
}
if (! -e "$drive:\\") {
    print "Connecting drive $drive\n";
    ConnectDrive($drive) or Exit("Drive unavailable: $drive");
}
