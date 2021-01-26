use strict;
use warnings;

use Number::Bytes::Human qw(format_bytes);

use RJK::Media::EMule::PartMet;
use RJK::Options::Pod;
use RJK::LocalConf;

###############################################################################
=head1 DESCRIPTION

Utility for eMule downloads.

=head1 SYNOPSIS

downloads.pl [options] [.part.met files]

=head1 DISPLAY EXTENDED HELP

eMulePartMet.pl -h

=for options start

=head1 OPTIONS

=over 4

=item B<-d -directory [path]>

Path to directory containing C<.part.met> files.

=item B<-summary>

Display summary.

=item B<-p -check-part-files>

Check existence of part files.

=item B<-f -filter [regular expression]>

Filter by filename using a regular expression (case insensitive). Multiple allowed.

=item B<-s -sort [key]>

Available sort keys: path, ok, filename, size, hash or utf8.

=item B<-r -read-met-files>

Read metadata from C<.part.met> files.

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

my %opts = RJK::LocalConf::GetOptions("RJK-utils/emule/downloads.properties");

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'd|directory=s' => \$opts{directory},
        "{Path} to directory containing C<.part.met> files.",
    'summary' => \$opts{summary},
        "Display summary.",
    'p|check-part-files' => \$opts{checkPartFiles},
        "Check existence of part files.",
    'f|filter=s@' => \$opts{filter},
        "Filter by filename using a {regular expression} (case insensitive). Multiple allowed.",
    's|sort=s' => \$opts{sort},
        "Available sort {key}s: path, ok, filename, size, hash or utf8.",
    'r|read-met-files' => \$opts{readMetFiles},
        "Read metadata from C<.part.met> files.",

    ['POD'],
    RJK::Options::Pod::Options,

    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

$opts{readMetFiles} ||= $opts{checkPartFiles};

@ARGV || $opts{directory} || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

my %stats = (
    totalSize => 0,
    fail => 0,
    $opts{checkPartFiles} ? (
        partSize => 0,
        noPart => 0,
    ) : ()
);

my @met = getFiles([map { glob } @ARGV], $opts{directory});

my @downloads;
MET: foreach my $met (@met) {
    my $dl;
    if ($opts{readMetFiles}) {
        $dl = getData($met);
        foreach (@{$opts{filter}}) {
            next MET if $dl->{filename} !~ /$_/i;
        }
        print "$dl->{path}\n" if $opts{sort};
    } else {
        $dl = { path => $met };
    }
    push @downloads, $dl;

    display($dl) if ! $opts{sort};
    checkPartFiles($dl) if $opts{checkPartFiles};
}

if (my $key = $opts{sort}) {
    foreach my $dl (sort { $a->{$key} <=> $b->{$key} } @downloads) {
        display($dl, $key);
    }
}

$stats{metFiles} = scalar @met;
use Data::Dump;
dd(\%stats);

sub display {
    my ($dl, $key) = @_;
    if (! $dl->{ok}) {
        print "$dl->{path}\n";
    } elsif ($key) {
        if ($key eq 'size') {
            printf "%u %s\n", $dl->{$key}, $dl->{filename};
        } else {
            printf "%s %s\n", $dl->{$key}, $dl->{filename};
        }
    } else {
        printf "%s %s %s\n", $dl->{hash}, format_bytes($dl->{size}), $dl->{filename};
    }
}

sub checkPartFiles {
    my $dl = shift;
    my $file = $dl->{path};
    $file =~ s/\.met$//;
    if (-e $file) {
        my $size = -s $file;
        if ($size) {
            if ($size > $dl->{size}) {
                print format_bytes($size), "\n";
                print format_bytes($dl->{size}), "\n";
                print "$file->{path}\n";
            }
            $stats{partSize} += $size;
        }
    } else {
        $stats{noPart}++;
    }
}

sub getFiles {
    my ($metfiles, $dir) = @_;
    my @files = @$metfiles;

    if (! @files && $dir) {
        opendir (my $dh, $dir) or die "$!";
        push @files, map { "$dir/$_" } grep { /\.part\.met$/ } readdir $dh;
        closedir $dh;
    }

    if (! @files) {
        print "No files found.\n";
        exit;
    } elsif (@files == 1) {
        $opts{readMetFiles} = 1;
    }

    return wantarray ? @files : \@files;
}

sub getData {
    my $metFile = shift;
    binmode(STDOUT, ":utf8");

    my $data = RJK::Media::EMule::PartMet::read($metFile);
    $data->{path} = $metFile;

    $stats{totalSize} += $data->{size};
    if ($data->{ok}) {
        $stats{totalSize} += $data->{size};
    } else {
        $stats{fail}++;
    }
    return $data;
}
