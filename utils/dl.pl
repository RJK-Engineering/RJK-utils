###############################################################################
=head1 DESCRIPTION

Download.

=head1 SYNOPSIS

dl.pl [options] [url]

=head1 DISPLAY EXTENDED HELP

dl.pl -h

=for options start

=cut
###############################################################################

use strict;
use warnings;

use Data::Dump;
use RJK::Options::Pod;
use RJK::Site;
use RJK::Sites;

my %opts = (
    #~ best => 1,
    #~ listFormats => 1,
    #~ noHistory => 1,
    #~ preferredRequired => 1,
);
RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'b|best' => \$opts{best}, "Best quality.",
    'f|format=s' => \$opts{format}, "Format.",
    'l|list-formats' => \$opts{listFormats}, "List formats, no download.",
    'i|ignore-history' => \$opts{noHistory}, "Ignore history (also not added to history!)",
    'p|preferred-required' => \$opts{preferredRequired}, "Do not download if preferred not available",

    ['POD'],
    RJK::Options::Pod::Options,

    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

###############################################################################

$opts{url} = $ARGV[0] || die;

my $site = getSite();
my $formats = getFormats() || exit;

if ($opts{listFormats}) {
    exit;
}

if (! $site || $opts{best}) {
    print "No site found\n";
    download();
    exit;
}

if ($site->{preferredFormat}) {
    if (my $f = $site->{formats}{$site->{preferredFormat}}) {
        $opts{format} = $f;
    } else {
        $opts{format} = $site->{preferredFormat};
    }
} elsif ($site->{preferredResolution}) {
    dd $formats->{resolutions};
    my @resolutions = sort { $b <=> $a } keys %{$formats->{resolutions}};
    dd \@resolutions;

    if (!@resolutions) {
        die "No resolutions";
    } elsif ($formats->{vvs}) {
        $opts{format} = $formats->{resolutions}{$resolutions[0]};
    } elsif ($formats->{resolutions}{$site->{preferredResolution}}) {
        $opts{format} = $formats->{resolutions}{$site->{preferredResolution}};
    } else {
        die "Preferred resolution not available" if $opts{preferredRequired};
        $opts{format} = $formats->{resolutions}{$resolutions[0]};
    }
}
download();

sub getSite {
    if ($opts{url} =~ /^http/) {
        my $site = RJK::Sites->get($opts{url});
        if ($site && $site->{downloadUrlCleanup}) {
            $opts{url} =~ s/$site->{downloadUrlCleanup}//;
        }
        return $site;
    } else {
        my $site = RJK::Sites->getForId($opts{url}) || die "No site";
        $opts{url} = $site->getDownloadUrl($opts{url});
        return $site;
    }
}

sub getFormats {
    my $formats = {};
    my $cmd = "youtube-dl -F $opts{url} 2>&1";
    my @lines = `$cmd`;

    my $parse = 0;
    foreach (@lines) {
        if (/ERROR.*is (locked|private)/) {
            print;
            return;
        }
        if (/^format\s+code/) {
            $parse = 1;
            next;
        }
        if (! $parse) {
            print;
            next;
        }
        chomp;
        if (/(.*?)\s+(.*?)\s+(.*?)\s+(.*)/) {
            print "$1\t$2\t$3\t$4\n";
            my $code = $1;
            my $format = {
                extension => $2,
                resolution => $3,
                note => $4,
            };
            next if $site && $site->{formatFilterRegex} && ! $code =~ /$site->{formatFilterRegex}/;
            $formats->{$code} = $format;

            if ($format->{resolution} =~ /(\d+)x(\d+)/) {
                $formats->{vvs} = $1 < $2;
                $formats->{resolutions}{$2} = $code;
            }
        } else {
            warn "ERROR: $_";
        }
    }
    return $formats;
}

sub download {
    my @cmd = "youtube-dl";
    if ($opts{noHistory}) {
        push @cmd, "--download-archive", "NUL";
    }
    push @cmd, -f => $opts{format} if $opts{format};
    push @cmd, $opts{url};

    my $cmd = join " ", @cmd;
    print "$cmd\n";
    system($cmd);
}
