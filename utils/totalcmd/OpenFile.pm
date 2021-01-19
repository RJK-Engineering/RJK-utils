package OpenFile;

use strict;
use warnings;

use Cwd ();

use RJK::Util::JSON;
use RJK::Filecheck::NameParser;
use RJK::Filecheck::Site;
use RJK::Win32::ProcessList;

my $opts;
my $sites;
my $browser;

sub execute {
    my $self = shift;
    $opts = shift;
    my $nameParser = getNameParser();
    $sites //= RJK::Util::JSON->read($opts->{sitesConf} =~ s/%(.+)%/$ENV{$1}/gr);

    foreach my $filename (@{$opts->{args}}) {
        my $props = $nameParser->parse($filename);
        my $cmd = getCommand($props);
        print "@$cmd\n" unless $opts->{quiet};
        runCommand($cmd) if @$cmd;
    }
}

sub getNameParser {
    my $nameParser = new RJK::Filecheck::NameParser();

    $opts->{filenamesConfDir} || die "Not defined: filenames.conf.dir";
    opendir my $dh, $opts->{filenamesConfDir} or die "$!: $opts->{filenamesConfDir}";
    while (readdir $dh) {
        next unless /\.json$/;
        my $conf = RJK::Util::JSON->read("$opts->{filenamesConfDir}/$_");
        $nameParser->addConf($conf);
    }
    closedir $dh;

    return $nameParser;
}

sub getCommand {
    my $props = shift;

    my @cmd;
    if ($props->{site}) {
        my $site = new RJK::Filecheck::Site(getSites()->{$props->{site}});
        my $url;
        if ($props->{id}) {
            $url = $site->downloadUrl($props->{id});
        } elsif ($props->{nameWords}) {
            $url = $site->searchUrl($props->{nameWords});
        }
        if ($url) {
            @cmd = (&getBrowser, @{$opts->{browserArgs}}, $url);
        }
    } elsif ($props->{snapshot}) {
        my $cwd = Cwd::getcwd;
        $cwd =~ s|/|\\|g;
        my $file = "$cwd\\$props->{snapshot}{file}";

        if (-e $file) {
            @cmd = (
                "start", "\"$file\"",
                $opts->{mpc}, $file,
                "/startpos", $props->{snapshot}{position},
            );
        } else {
            print "File not found: $file\n" unless $opts->{quiet};
        }
    }
    return \@cmd;
}

sub runCommand {
    my $cmd = shift;
    if ($opts->{open}) {
        system @$cmd;
    }
}

sub getSites {
    return $sites //= RJK::Util::JSON->read($opts->{sitesConf} =~ s/%(.+)%/$ENV{$1}/gr);
}

sub getBrowser {
    return $browser //=
    RJK::Win32::ProcessList->processExists("chrome.exe") && $opts->{chromeBrowser} ||
    RJK::Win32::ProcessList->processExists("firefox.exe") && $opts->{firefoxBrowser} ||
    $opts->{defaultBrowser};
}

1;
