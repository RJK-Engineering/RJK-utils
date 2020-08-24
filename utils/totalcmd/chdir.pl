use strict;
use warnings;

use Encode qw(decode);
use Win32;
use Win32::Clipboard;

use RJK::File::PathUtils qw(ExtractPath);
use RJK::Options::Pod;
use RJK::TotalCmd::Utils;
use RJK::Win32::Console;
use RJK::Win32::DriveUtils qw(ConnectDrive GetDriveLetter);

###############################################################################
=head1 DESCRIPTION

Set Total Commander file window paths.

=head1 SYNOPSIS

chdir.pl [options] [paths]

=head1 DISPLAY EXTENDED HELP

chdir.pl -h

=for options start

=head1 OPTIONS

=over 4

=item B<-c -read-clipboard>

Read paths from clipboard

=back

=head1 HELP

=over 4

=item B<-h -help -?>

Display extended help.

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

=for options end

=cut
###############################################################################

my %opts = ( maxTabs => 30 );
RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'c|read-clipboard' => \$opts{clipboard}, "Read paths from clipboard, one per line.",
    'n|new-tab' => \$opts{newTab}, "Open in new tab. (/T)",
    'f|first' => \$opts{first}, "No questions, open first path.",
    'b|both' => \$opts{both}, "No questions, open first path in source, second in target window.",
    'a|all' => \$opts{all}, "No questions, open all in tabs (limited to 30 by default).",
    'm|max-tabs=i' => \$opts{maxTabs}, "Maximum number of tabs to open/paths to choose from. Default: 30",
    't|target' => \$opts{target}, "Open in target window. (/R)",
    'l|left-right' => \$opts{leftRight}, "Interprets paths as left/right instead of source/target. (opposite of /S)",
    ['POD'],
    RJK::Options::Pod::Options,
    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

$opts{clipboard} // @ARGV || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP"
);

###############################################################################

# get clipboard contents
my $clip = Win32::Clipboard();
my $path = decode("UTF16-LE", $clip->GetAs(CF_UNICODETEXT));

# split on vertical whitespace characters, remove empty lines
my @lines = grep { $_ } split /\v+\s*/s, $path
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
    my @fail;
    foreach (@urls) {
        if (system "dl \"$_\"") {
            push @fail, $_;
        }
    }
    if (@fail) {
        print "$_\n" for @fail;
        $clip->Set(join "\n", @fail);
        <STDIN>;
        exit 1;
    }
} elsif (@paths == 1) {
    $path = $paths[0];
} elsif (@paths) {
    my $c = new RJK::Win32::Console();
    $path = $c->itemFromList(\@paths);
} else {
    Exit("No paths found");
}

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

if (! -e $path) {
    # try short name, if there is no short name available the input path is returned
    my $short = Win32::GetShortPathName($path);
    $path = -e $short ? $short :
        # replace non-printable and multi-byte chars with ? wildcards which totalcmd will try to match
        $path =~ s/[^\x20-\xFF]/?/gr;
}

RJK::TotalCmd::Utils::setSourcePath($path);

sub Exit {
    print shift, "\n";
    exit;
}
