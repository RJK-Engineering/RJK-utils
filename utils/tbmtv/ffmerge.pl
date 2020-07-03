use strict;
use warnings;

my ($listFile, @ffargs) = @ARGV;
die "List file required" if ! $listFile;

my %opts = (
    run => 1,
    quiet => 0,
);

mergeStreams();

sub mergeStreams {
    open my $fh, '<', $listFile or die "$!";
    my @in;
    while (<$fh>) {
        chomp;
        push @in, -i => $_;
    }
    close $fh;

    runffmpeg(@in, @ffargs);
}

sub runffmpeg {
    if (! $opts{quiet}) {
        my @args = map { /^-/ ? $_ : "\"$_\"" } @_;
        print "ffmpeg @args\n";
    }
    if ($opts{run}) {
        system "ffmpeg", @_;
    }
}
