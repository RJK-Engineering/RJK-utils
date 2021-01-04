use strict;
use warnings;

use File::Spec::Functions qw(rel2abs);

my $csv = shift;
my %opts = @ARGV;

my $script = getScript();
open my $fhScript, '>', $script or die "$!: $script";

open my $fhCsv, '<', $csv or die "$!: $csv";
my $video = getVideo();
writeScriptStart();

my ($frameNr, $currFrame, $prevFrame, $inSegm, $startTime, $total);
$opts{frameDuration} || detectFrameDuration();
print "Frame gap: $opts{frameDuration}\n";

while (<$fhCsv>) {
    if (/frame\|key_frame=(\d)\|pkt_pts_time=(\d+.\d+)/) {
        $prevFrame = $currFrame;
        $currFrame = { key_frame => $1, time => $2 * 1_000_000 };
        processFrame();
    }
}
close $fhCsv;
stopSegm() if $inSegm;

writeScriptEnd();
close $fhScript;
print "\nTotal: $total\n";

sub getScript {
    my $script = $csv =~ s/\.\w+$/.py/r;
    print "Script: $script\n";
    return $script;
}

sub getVideo {
    my $video = $csv =~ s/\.\w+$/.mp4/r;
    $video = rel2abs($video);
    $video =~ s|\\|\/|g;
    print "Video: $video\n";
    return $video;
}

sub detectFrameDuration {
    my %gaps;
    $opts{frameDuration} = 1_000_000;
    while (<$fhCsv>) {
        if (/frame\|key_frame=(\d)\|pkt_pts_time=(\d+.\d+)/) {
            $prevFrame = $currFrame;
            $currFrame = $2 * 1_000_000;
            if (defined $prevFrame) {
                my $gap = int($currFrame - $prevFrame + .5);
                $gaps{$gap}++;
            }
        }
    }
    $currFrame = undef;
    seek $fhCsv, 0, 0;

    my @gaps = sort { $gaps{$b} <=> $gaps{$a} } keys %gaps;
    $opts{frameDuration} = $gaps[0];
}

sub processFrame {
    if ($currFrame->{key_frame}) {
        if ($inSegm) {
            if (gap()) {
                stopSegm();
                startSegm();
            }
        } else {
            startSegm();
        }
    } elsif ($inSegm && gap()) {
        stopSegm();
    }
}

sub gap {
    my $gap = interval();
    if ($gap > $opts{frameDuration} * 1.5) {
        print ".";
    }
    return $gap > $opts{frameDuration} * 1.5;
}

sub startSegm {
    $inSegm = 1;
    $startTime = $currFrame->{time};
}

sub writeScriptStart {
    print $fhScript "#PY  <- Needed to identify #\n";
    print $fhScript "#--automatically built--\n\n";
    print $fhScript "adm = Avidemux()\n";
    print $fhScript "adm.loadVideo(\"$video\")\n";
    print $fhScript "adm.clearSegments()\n";
}

sub writeScriptEnd {
    print $fhScript "adm.markerA = 0\n";
    print $fhScript "adm.markerB = $total\n";
    print $fhScript "adm.videoCodec(\"Copy\")\n";
    print $fhScript "adm.audioClearTracks()\n";
    unless ($opts{noaudio}) {
        print $fhScript "adm.audioAddTrack(0)\n";
        print $fhScript "adm.audioCodec(0, \"copy\");\n";
        print $fhScript "adm.audioSetDrc(0, 0)\n";
        print $fhScript "adm.audioSetShift(0, 0,0)\n";
    }
    print $fhScript "adm.setContainer(\"MP4V2\", \"optimize=0\", \"add_itunes_metadata=0\")\n";
}

sub stopSegm {
    $inSegm = 0;
    my $dur;
    if ($opts{discardIncompleteLastFrames}) {
        $dur = int($prevFrame->{time} - $startTime + .5) || return;
    } else {
        $dur = int($prevFrame->{time} - $startTime + $opts{frameDuration} + .5);
    }
    $total += $dur;
    print $fhScript "adm.addSegment(0, $startTime, $dur)\n";
}

sub interval {
    int($currFrame->{time} - $prevFrame->{time})
}
