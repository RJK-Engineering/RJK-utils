use strict;
use warnings;

use Win32::Clipboard;

my %opts = (
    pollInterval => 1,
    setClipAfterRead => 0,
    setClipOnExit => 1,
);

my $clip = Win32::Clipboard();
my $text;
my $prevText = "";
my $log = "";
&setText;

$SIG{INT} = "interrupt";

while (1) {
    $text = &getText;
    if ($text) {
        if ($opts{setClipAfterRead}) {
            if ($text ne $log) {
                print "$text\n";
                $log .= "$text\n";
                &setText;
            }
        } else {
            if ($text ne $prevText) {
                print "$text\n";
                $log .= "$text\n";
            }
            $prevText = $text;
        }
    }
    sleep $opts{pollInterval};
}

sub getText {
    my $text = $clip->GetText();
    return $text;
}

sub setText {
    $clip->Set($log);
}

sub interrupt {
    &setText if $opts{setClipOnExit} &&
              ! $opts{setClipAfterRead}; # clipboard already set
    exit;
}
