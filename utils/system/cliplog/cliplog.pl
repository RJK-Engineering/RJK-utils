use strict;
use warnings;

use Win32::Clipboard;

my %opts = (
    pollInterval => 1,
    chompText => 1,
    logToClipOnExit => 1,
);

my $clip = Win32::Clipboard();
my ($text, $previousText) = (&getText)x2;
my $log = "";

$SIG{INT} = "interrupt";

while (1) {
    if ($text && $text ne $previousText) {
        print "$text\n";
        $previousText = $text;
        $log .= $text . "\n";
    }
    sleep $opts{pollInterval};
    $text = &getText;
}

sub getText {
    my $text = $clip->GetText();
    chomp $text if $opts{chompText};
    return $text;
}

sub interrupt {
    $clip->Set($log) if $opts{logToClipOnExit};
    exit;
}
