use strict;
use warnings;

use RJK::File::PathInfo qw(basename extension);

# https://trac.ffmpeg.org/wiki/Concatenate

my ($listFile, $method, $outputFile) = @ARGV;
die "List file required" if ! $listFile;

my %opts = (
    outputFile => $outputFile,
    run => 1,
    method => $method || "s",
);

if ($opts{method} =~ /^s/) {
    concatStreams($listFile);
} elsif ($opts{method} =~ /^f/) {
    concatFiles($listFile);
} elsif ($opts{method} =~ /^t/) {
    concatTransportStreams($listFile);
} else {
    die "Valid methods (default=s): s(tream) f(ile) t(ransportstream)";
}

sub concatStreams {
    my $listFile = shift;
    my $firstFile;
    my $c = 0;
    my $tempListFile = "$listFile.temp";

    open my $fh, '<', $listFile or die "$!";
    open my $fhTemp, '>', $tempListFile or die "$!";
    while (<$fh>) {
        chomp;
        print $fhTemp "file '$_'\n";
        $firstFile //= $_;
        $c++;
    }
    close $fh;
    close $fhTemp;

    if ($c < 2) {
        die "Less than two files in list";
    }

    runffmpeg(
        -f => "concat",
        -safe => 0,
        -i => $tempListFile,
        -c => "copy",
        getOutputFile($firstFile)
    );

    unlink $tempListFile;
}

sub concatFiles {
    my $listFile = shift;

    my @files = loadFiles($listFile);

    runffmpeg(
        -i => "concat:" . join("|", @files),
        -c => "copy",
        getOutputFile($files[0])
    );
}

sub concatTransportStreams {
    my $listFile = shift;

    my @files = loadFiles($listFile);

    my @intermediateFiles;
    foreach my $file (@files) {
        my $outputFile = "$file.ts";
        runffmpeg(
            -i => $file,
            -c => "copy",
            "-bsf:v" => "h264_mp4toannexb",
            -f => "mpegts",
            $outputFile
        );
        push @intermediateFiles, $outputFile;
    }

    runffmpeg(
        -i => "concat:" . join("|", @intermediateFiles),
        -c => "copy",
        "-bsf:a" => "aac_adtstoasc",
        getOutputFile($files[0])
    );

    foreach my $file (@intermediateFiles) {
        unlink $file;
    }
}

sub loadFiles {
    my $listFile = shift;
    open my $fh, '<', $listFile or die "$!";
    chomp (my @files = <$fh>);
    close $fh;

    if (@files < 2) {
        die "Less than two files in list";
    }
    return @files;
}

sub getOutputFile {
    my $file = shift;
    my $outputFile = $opts{outputFile};
    $outputFile //= basename($file) . "_out." . extension($file);
    return $outputFile;
}

sub runffmpeg {
    if (! $opts{quiet}) {
        my @args = map { /^-/ ? $_ : "\"$_\"" } @_;
        print "ffmpeg @args\n";
    }
    if ($opts{run}) {
        <STDIN>;
        system "ffmpeg", @_;
    }
}
