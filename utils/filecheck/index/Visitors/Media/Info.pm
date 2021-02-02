package Visitors::Media::Info;
use parent 'FileTypeVisitor';

use strict;
use warnings;

use RJK::Media::Info::FFmpeg;

my $mediaProps = [qw(format duration start bitrate)];
my $streamProps = [qw(format profile codec bitrate note)];
my $audioProps = [@$streamProps, qw(frequency channels language)];
my $videoProps = [@$streamProps, qw(framerate aspect colorspace width height sar dar tbr fps)];
my $chapterProps = [qw(start end title)];
my @ignoreMetadata = qw(compatible_brands encoder major_brand minor_version);

sub visitFile {
    my ($self, $file, $stat, $props) = @_;
    return if $props->{'media.file.format'};

    my $i = RJK::Media::Info::FFmpeg->info($file);

    $props->{"media.file.streams.video"} = scalar @{$i->{video}};
    $props->{"media.file.streams.audio"} = scalar @{$i->{audio}};
    map { $props->{"media.file.$_"} = $i->{$_} } @$mediaProps;

    if ($i->{video}[0]) {
        map { $props->{"media.video.$_"} = $i->{video}[0]{$_} } @$videoProps;
        delete $props->{"media.video.note"} if $props->{"media.video.note"} eq 'default';
    }

    if ($i->{audio}[0]) {
        map { $props->{"media.audio.$_"} = $i->{audio}[0]{$_} } @$audioProps;
    }

    $props->{"media.file.chapters"} = $i->{chapters};

    if ($i->{metadata}) {
        delete $i->{metadata}{$_} for @ignoreMetadata;
        foreach my $key (keys %{$i->{metadata}}) {
            $props->{"media.metadata.$key"} = $i->{metadata}{$key};
        }
    }
    $props->{"media.video.metadata"} = $i->{video}[0]{metadata} if $i->{video}[0]{metadata};
    $props->{"media.audio.metadata"} = $i->{audio}[0]{metadata} if $i->{audio}[0]{metadata};
}

1;
