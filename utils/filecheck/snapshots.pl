use strict;
use warnings;

use RJK::File::Path;
use RJK::File::Sidecar;
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

sub createSnapshot {
    my ($video, $time, $output) = @_;
    my @cmd = (
        ffmpeg => '-n',
        -i => "\"$video\"",
        -ss => $time,
        -vf => "\"scale=-1:$opts{imageHeight}\"",
        -vframes => 1,
        "\"$output\""
    );
    print "@cmd\n" if $opts{verbose};
    `@cmd 2>&1 >NUL`;
}

sub isVideo {
    return $_[0] =~ /\.(mp4|wmv|mpe?g|avi|rm|mkv|webm|flv|rmvb|asf|m4v|divx|mov)$/i;
}

sub createSnapshots {
    my $path = shift;
    my $first = 1;
    my $existing = 0;
    RJK::File::Sidecar->getSidecarFiles($path, sub {
        return if ! /\.jpg$/i;
        my ($sidecar, $dir, $name, $nameStart) = @_;

        print "+ $path\n+ $name\n" if $first;
        $first = 0;

        if ($sidecar =~ /_(\d\d?s|\d\d?\.\d\d)\.jpg$/i) {
            my $timeStr = $1;
            my $time = $1 =~ s/\./:/r;
            $existing = 1;
            print "> $sidecar\n";

            my $sidecarPath = "$dir\\$sidecar";
            my $info = getImageInfo($sidecarPath);
            print "Comment: $info->{comment}\n" if $opts{verbose} && $info->{comment};

            if ($info->{height} == $opts{imageHeight}) {
                print "OK!\n";
            } else {
                unlink $sidecarPath or die "$!: $sidecarPath";
                my $snapshot = "$dir\\${nameStart}_$timeStr.jpg";
                createSnapshot($path, $time, $snapshot);
            }
        } elsif ($sidecar =~ /\.\w+_snapshot_(?:(\d\d)\.)?(\d\d)\.(\d\d)_\[\d{4}\.\d\d\.\d\d_\d\d\.\d\d\.\d\d\]\.jpg$/i) {
            print "< $sidecar\n";
            my $h = int $1 if $1;
            my $m = int $2;
            my $s = int $3;
            my $timeStr = !$h && !$m ? $s."s" : $h ? sprintf("%u.%02u.%02u", $h, $m, $s) : sprintf("%u.%02u", $m, $s);
            my $newName = "$dir\\${nameStart}_$timeStr.jpg";
            if (-e $newName) {
                print "- $sidecar\n";
                unlink $sidecar;
            } else {
                print "> $newName\n";
                rename $sidecar, $newName;
            }
        } else {
            print "! $sidecar\n";
        }
    });
    if (! $existing) {
        my $snapshot = "$path->{parent}\\$path->{basename}_$opts{position}s.jpg";
        createSnapshot($path, $opts{position}, $snapshot);
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
