use strict;
use warnings;

use File::Basename;
use lib dirname (__FILE__);

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

my %opts = RJK::LocalConf::GetOptions("RJK-utils/totalcmd/openfile.properties", (
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
    'b|browser=s' => \$opts{browser},
    'a|browser-args=s' => \$opts{browserArgs},
    'm|mpc=s' => \$opts{mpc},
    'q|quiet' => \$opts{quiet},

    ['Help'],
    RJK::Options::Pod::HelpOptions
);

@ARGV || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP"
);
$opts{args} = \@ARGV;

my $i = 0;
$opts{browserArgs} = [
    map { $i++ % 2 ? $_ : split /\s+/ }
    split /"(.*?)"\s*/, $opts{browserArgs} =~ s/^\s+//r
];

###############################################################################

use OpenFile;
use RJK::Exceptions;
use Try::Tiny;

try {
    OpenFile->execute(\%opts);
} catch {
    RJK::Exceptions->handle;
    exit 1;
};
