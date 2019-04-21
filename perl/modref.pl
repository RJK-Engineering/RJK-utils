use strict;
use warnings;

use RJK::TemplateProcessor;
use RJK::Win32::Browser;

my $pkg = shift || die "USAGE: $0 [package] [site]";
my $site = shift || 'pod';

my %opts = (
    noOpen => 0,
    quiet => 0,
);

my $sites = {
    pod => {
        string => 'https://metacpan.org/pod/{pkg}',
        replace => { pkg => [ [ '-', '::' ] ] },
    },
    metacpan => {
        string => 'https://metacpan.org/release/{pkg}',
        replace => { pkg => [ [ '::', '-' ] ] },
    },
    activestate => {
        string => 'https://code.activestate.com/ppm/{pkg}',
        replace => { pkg => [ [ '::', '-' ] ] },
    }
};

my $tp = new RJK::TemplateProcessor($sites);

#~ my $url = $tp->getString($site, [$pkg]);
my $url = $tp->getString($site, { pkg => $pkg });
print "$url\n" unless $opts{quiet};
RJK::Win32::Browser::OpenUrl($url) unless $opts{noOpen};
