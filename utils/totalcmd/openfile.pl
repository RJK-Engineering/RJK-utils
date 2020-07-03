use strict;
use warnings;

use Cwd ();

use RJK::Util::JSON;
#~ use Filecheck::Search;
use RJK::Filecheck::NameParser;
use RJK::Filecheck::Site;
use RJK::LocalConf;
use RJK::Options::Pod;

###############################################################################
=head1 DESCRIPTION

Perform action based on a filename.

=head1 SYNOPSIS

openfile.pl [options] [path]

The directory portion of [path] is discarded.

=head1 DISPLAY EXTENDED HELP

openfile.pl -h

=for options start

=over 4

=item B<-o --open>

Open file.

=item B<-c --conf-file [path]>

Path to configuration file. Default: F<sites.json>.

=item B<-b --browser [path]>

Path to browser executable. Default: F<firefox>.

=item B<-m --mpc [path]>

Path to Media Player Classic executable. Default: F<mpc-hc64>.

=item B<-q --quiet>

Be quiet.

=item B<-h -? --help>

Display extended help.

=back

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("totalcmd/openfile.properties", (
    sitesConf => 'sites.json',
    filenamesConfDir => '',
    browser => 'firefox',
    browserArgs => '',
    mpc => 'mpc',
));
RJK::Options::Pod::GetOptions(
    ['Options'],
    'o|open' => \$opts{open},
    'c|site-conf=s' => \$opts{sitesConf},
    #~ 'f|filenames-conf-dir=s' => \$opts{filenamesConfDir},
    'd|dump' => \$opts{dump},
    'b|browser=s' => \$opts{browser},
    'a|browser-args=s' => \$opts{browserArgs},
    'm|mpc=s' => \$opts{mpc},
    'q|quiet' => \$opts{quiet},

    ['Help'],
    RJK::Options::Pod::HelpOptions
);

@ARGV || RJK::Options::Pod::pod2usage(
    -verbose => 99,
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

my ($name) = @ARGV;
$name =~ s/^.*\\//; # discard directory portion

my $i = 0;
$opts{browserArgs} = [ map { $i++ % 2 ? $_ : split /\s+/ } split /"(.*?)"\s*/, $opts{browserArgs} =~ s/^\s+//r ];

###############################################################################

my $nameParser = getNameParser();
my $props = $nameParser->parse($name);

if ($opts{dump}) {
    use Data::Dump;
    dd $props;
    exit;
}

my $sites = new RJK::Util::JSON($opts{sitesConf})->read->data
    or die "Error loading sites conf";

my @cmd;
if ($props->{site}) {
    my $site = new RJK::Filecheck::Site($sites->{$props->{site}});
    my $url;
    if ($props->{id}) {
        $url = $site->downloadUrl($props->{id});
    } elsif ($props->{nameWords}) {
        $url = $site->searchUrl($props->{nameWords});
    }
    if ($url) {
        @cmd = ($opts{browser}, @{$opts{browserArgs}}, $url);
    }
} elsif ($props->{snapshot}) {
    my $cwd = Cwd::getcwd;
    $cwd =~ s|/|\\|g;
    my $file = "$cwd\\$props->{snapshot}{file}";
    #~ my $search = new Filecheck::Search(
    #~     lstDir => 'c:\data\filecheck\lists'
    #~ );
    #~ my $path = $search->findPath($file);
    if (-e $file) {
        @cmd = (
            "start", "\"$file\"",
            $opts{mpc}, $file,
            "/startpos", $props->{snapshot}{position},
        );
    } else {
        print "File not found: $file\n" unless $opts{quiet};
    }
}

if (@cmd) {
    print "@cmd\n" unless $opts{quiet};
    if ($opts{open}) {
        system @cmd;
    }
}

sub getNameParser {
    my $nameParser = new RJK::Filecheck::NameParser();

    opendir my $dh, $opts{filenamesConfDir} or die "$!";
    while (readdir $dh) {
        next unless /\.json$/;
        my $conf = new RJK::Util::JSON("$opts{filenamesConfDir}/$_")->read->data;
        $nameParser->addConf($conf);
    }
    closedir $dh;

    return $nameParser;
}
