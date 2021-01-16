use strict;
use warnings;

use RJK::File::Path;
use RJK::File::Sidecar;
use RJK::File::TreeVisitResult;
use RJK::Filecheck::Dirs;
use RJK::Files;
use RJK::SimpleFileVisitor;

my %opts = (
    verbose => 1,
    imageHeight => 360,
);

$opts{sourceDir} = shift;
$opts{position} = shift // 30;

my $visitor = new RJK::SimpleFileVisitor(
    visitFileFailed => sub {
        my ($file, $error) = @_;
        print "$error: $file->{path}\n";
    },
    preVisitDir => sub {
        my ($dir, $stat) = @_;
        print "=> $dir->{path}\n";
        my $p = RJK::Filecheck::Dirs->getProperties($dir->{path});
        return SKIP_FILES if $p->get('no.snapshots');
    },
    visitFile => sub {
        my ($file, $stat) = @_;
        return if ! isVideo($file);
        print "$file\n" if $opts{verbose};
        createSnapshots($file);
    }
);

$opts{sourceDir} || die "No source directory specified";
RJK::Files->traverse($opts{sourceDir}, $visitor);

sub createSnapshots {
    my $videoFile = shift;
    my $first = 1;
    my $existingSnapshots = 0;

    RJK::File::Sidecar->getSidecarFiles($videoFile, sub {
        print "+ $videoFile\n" if $first;
        $first = 0;
        $existingSnapshots ||= handleSidecarFile($videoFile, @_);
    });

    if (! $existingSnapshots) {
        my $timeStr = $opts{position} =~ s/:/./gr;
        $timeStr .= "s" if $timeStr !~ /\./;
        my $snapshot = "$videoFile->{parent}\\$videoFile->{basename}_$timeStr.jpg";
        createSnapshot($videoFile, $opts{position} =~ s/\./:/gr, $snapshot);
    }
}

sub handleSidecarFile {
    return if ! /\.jpg$/i;
    my ($videoFile, $sidecar, $dir, $name, $nameStart) = @_;
    my $existingSnapshot;
    my $sidecarPath = "$dir\\$sidecar";

    if ($sidecar =~ /_(\d\d?s|\d\d?\.\d\d)\.jpg$/i) {
        print "> $sidecar\n";
        handleExistingSnapshot($videoFile, $sidecarPath, $dir, $nameStart, $1);
        $existingSnapshot = 1;
    } elsif ($sidecar =~ /\.\w+_snapshot_(?:(\d\d)\.)?(\d\d)\.(\d\d)_\[\d{4}\.\d\d\.\d\d_\d\d\.\d\d\.\d\d\]\.jpg$/i) {
        print "< $sidecarPath\n";
        handleMpcSnapshot($sidecarPath, $dir, $nameStart, $1, $2, $3);
    } else {
        print "! $sidecar\n";
    }
    return $existingSnapshot;
}

sub handleExistingSnapshot {
    my ($videoFile, $sidecarPath, $dir, $nameStart, $time) = @_;
    my $timeStr = $time;
    $time =~ s/\./:/g;

    my $info = getImageInfo($sidecarPath);
    print "Comment: $info->{comment}\n" if $opts{verbose} && $info->{comment};

    if ($info->{height} == $opts{imageHeight}) {
        print "OK!\n";
    } else {
        unlink $sidecarPath or die "$!: $sidecarPath";
        my $snapshot = "$dir\\${nameStart}_$timeStr.jpg";
        createSnapshot($videoFile, $time, $snapshot);
    }
}

sub handleMpcSnapshot {
    my ($sidecarPath, $dir, $nameStart, $h, $m, $s) = @_;
    $h = int $h if $h;
    $m = int $m;
    $s = int $s;

    my $timeStr = !$h && !$m ? $s."s" : $h ? sprintf("%u.%02u.%02u", $h, $m, $s) : sprintf("%u.%02u", $m, $s);
    my $newName = "$dir\\${nameStart}_$timeStr.jpg";

    if (-e $newName) {
        print "- $sidecarPath\n";
        unlink $sidecarPath;
    } else {
        print "> $newName\n";
        rename $sidecarPath, $newName;
    }
}

sub getImageInfo {
    my ($file) = @_;
    my %info;
    open my $fh, '<:raw', $file or die "$!: $file";
    while (1) {
        read $fh, my $s, 1 or last;
        if (unpack("C", $s) == 0xFF) {
            read $fh, $s, 1 or last;
            if (unpack("C", $s) == 0xFE) {
                read $fh, $s, 2 or last;
                my $length = unpack("n", $s);
                read $fh, $info{comment}, $length-3 or last;
            } elsif (unpack("C", $s) == 0xC0) {
                seek $fh, 3, 1 or last;
                read $fh, $s, 2 or last;
                $info{height} = unpack("n", $s);
                read $fh, $s, 2 or last;
                $info{width} = unpack("n", $s);
                last;
            }
        }
    }
    close $fh;
    return \%info;
}

sub isVideo {
    return $_[0] =~ /\.(mp4|wmv|mpe?g|avi|rm|mkv|webm|flv|rmvb|asf|m4v|divx|mov)$/i;
}

sub createSnapshot {
    my ($videoFilePath, $time, $output) = @_;
    my @cmd = (
        ffmpeg => '-n',
        -i => "\"$videoFilePath\"",
        -ss => $time,
        -vf => "\"scale=-1:$opts{imageHeight}\"",
        -vframes => 1,
        "\"$output\""
    );
    print "@cmd\n" if $opts{verbose};
    `@cmd 2>&1 >NUL`;
}
