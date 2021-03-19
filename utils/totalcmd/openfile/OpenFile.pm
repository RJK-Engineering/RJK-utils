package OpenFile;

use strict;
use warnings;

use Cwd ();

use RJK::Filecheck;
use RJK::Site;
use RJK::Sites;
use RJK::Util::JSON;
use RJK::Win32::ProcessList;

my $opts;
my $browser;

sub execute {
    my $self = shift;
    $opts = shift;
    $opts->{filenamesConfDir} || die "Not defined: filenames.conf.dir";
    my $nameParser = RJK::Filecheck->createNameParser($opts->{filenamesConfDir});

    foreach my $filename (@{$opts->{args}}) {
        my $props = $nameParser->parse($filename);
        my $cmd = getCommand($props);
        print "@$cmd\n" unless $opts->{quiet};
        runCommand($cmd) if @$cmd;
    }
}

sub getCommand {
    my $props = shift;

    my @cmd;
    if ($props->{site}) {
        my $site = RJK::Sites->get($props->{site});
        my $url;
        if ($props->{id}) {
            $url = $site->getDownloadUrl($props->{id});
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

sub getBrowser {
    return $browser //=
    RJK::Win32::ProcessList->processExists("chrome.exe") && $opts->{chromeBrowser} ||
    RJK::Win32::ProcessList->processExists("firefox.exe") && $opts->{firefoxBrowser} ||
    $opts->{defaultBrowser};
}

1;
