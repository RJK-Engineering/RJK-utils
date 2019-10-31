use strict;
use warnings;

use Options::Pod;

use DateTime;
use DateTime::Format::Strptime;
use Try::Tiny;

use Media::TimeFormat;
use Media::Humax::Hmt;

###############################################################################
=head1 DESCRIPTION

Display Humax recording metadata from C<.hmt> files.

=head1 SYNOPSIS

hmt.pl [options] [.hmt files]

Wildcards are allowed.

=head1 DISPLAY EXTENDED HELP

hmt.pl -h

=head1 OPTIONS

=for options start

=item B<-p -properties [names]>

Comma separated list of properties to display. Display available properties if [names] is undefined.

=item B<-c -columns [integer]>

Set number of columns for formatting. Default: 65.

=item B<-o -output-file [string]>

Write to file instead of standard out.

=back

=head1 Pod

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

=head1 Help

=over 4

=item B<-h -help -?>

Display extended help.

=back

=for options end

=cut
###############################################################################

my %opts = (
    columns => 65
);
Options::Pod::GetOptions(
    'p|properties:s' => \$opts{props},
        "Comma separated list of properties to display. Display available properties if [{names}] is undefined.",
    'c|columns=i' => \$opts{columns},
        "Set number of columns for formatting. Default: 65.",
    'o|output-file=s' => \$opts{out},
        "Write to file instead of standard out.",

    ['Pod'],
    Options::Pod::Options,

    ['Help'],
    Options::Pod::HelpOptions
);

@ARGV || Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

my @files = map { glob "\"$_\"" } @ARGV;
my @props = split /,/, $opts{props} if $opts{props};

# quiet!
$opts{verbose} = 0 if $opts{quiet};

###############################################################################

my $displayProps = defined $opts{props} && ! $opts{props};
my $dtFormatter;
my $textFormatter;
my $fh = *STDOUT;

Init() unless $displayProps;

for (my $i=0; $i<@files; $i++) {
    print $fh "\n" if $i && @props != 1;
    ProcessFile($files[$i]);
}

sub Init {
    $dtFormatter //= DateTime::Format::Strptime->new(
      pattern => '%d-%m-%y %T',
      on_error => 'croak'
    );

    $textFormatter = sub { return $_[0] };
    if (eval "require Text::Format; 1;") {
        my $text = Text::Format->new;
        $text->columns($opts{columns});
        $text->firstIndent(0);
        $textFormatter = sub { $text->format($_[0]) };
    } else {
        warn 'Text::Format unavailable';
    }

    if (defined $opts{out}) {
        !-e $opts{out} || die "File exists";
        open ($fh, ">", $opts{out}) || die "$!";
    }
}

sub ProcessFile {
    my $file = shift;
    my $info;
    try {
        $info = Media::Humax::Hmt::GetInfo($file);
    } catch {
        if ( $_->isa('Exception') ) {
            printf "%s: %s\n", ref $_, $_->error;
        } else {
            die "$!";
        }
        exit 1;
    };

    if ($displayProps) {
        foreach (keys %$info) {
            print "$_\n";
        }
        return;
    }

    my %display;
    if ($opts{props}) {
        foreach (@props) {
            if (defined $info->{$_}) {
                $display{$_} = 1;
            } else {
                warn "Property not available: $_\n";
            }
        }
    } else {
        %display = map { $_ => 1 } keys %$info;
    }

    my $start = DateTime->from_epoch(epoch => $info->{start}||0);
    my $end = DateTime->from_epoch(epoch => $info->{end}||0);

    print $fh "File: $info->{path}\n" if $display{path};
    print $fh "Title:   $info->{title}\n" if $display{title};

    print $fh "Channel: $info->{channel}\n" if $display{channel};
    print $fh "Service: $info->{service}\n" if $display{service};
    print $fh "Start:   ", $dtFormatter->format_datetime($start), "\n" if $display{start};
    print $fh "End:     ", $dtFormatter->format_datetime($end), "\n" if $display{end};
    if ($display{bookmarks}) {
        printf $fh "Bookmarks: %s\n",
            join " ",
                map { Media::TimeFormat::humanReadableFormat($_) }
                @{$info->{bookmarks}}
                     if @{$info->{bookmarks}};
    }

    if ($display{events}) {
        foreach my $e (@{$info->{events}}) {
            print $fh "\nEvent: $e->{name}\n\n";
            print $fh $textFormatter->("$e->{info}\n");
        }
    }
}
